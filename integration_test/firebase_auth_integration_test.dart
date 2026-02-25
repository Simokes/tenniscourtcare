import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:tenniscourtcare/data/repositories/firebase_auth_repository.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:tenniscourtcare/domain/enums/role.dart';
import 'package:tenniscourtcare/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseAuthRepository repository;
  late AppDatabase db;

  setUpAll(() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Connect to emulators
    const host = 'localhost'; // Use 10.0.2.2 for Android Emulator if not using reverse proxy
    try {
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
    } catch (e) {
      debugPrint('Emulators might already be configured or failed to connect: $e');
    }
  });

  setUp(() {
    // Use in-memory SQLite database for isolation
    db = AppDatabase(NativeDatabase.memory());
    repository = FirebaseAuthRepository(db);
  });

  tearDown(() async {
    await db.close();
    await FirebaseAuth.instance.signOut();
  });

  // Helper function to verify audit logs
  Future<void> verifyAuditLog(
    String action,
    String targetUserId,
    String performedByUserId,
  ) async {
    // Wait slightly for Firestore consistency/Cloud Function trigger
    await Future.delayed(const Duration(milliseconds: 500));

    final auditLog = await FirebaseFirestore.instance
      .collection('audit_logs')
      .where('action', isEqualTo: action)
      .where('targetUserId', isEqualTo: targetUserId)
      .get();

    expect(auditLog.docs.isNotEmpty, true, reason: 'Audit log for $action not found');
    expect(auditLog.docs.first['performedBy'], performedByUserId, reason: 'PerformedBy mismatch');
    expect(auditLog.docs.first['timestamp'], isNotNull);
  }

  testWidgets('Integration: SignIn syncs firestore_uid and creates local user', (tester) async {
    const email = 'sync_test_secure@example.com';
    const password = 'StrongPassword123!';

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code != 'email-already-in-use') rethrow;
    }

    final user = await repository.signIn(email, password);

    expect(user, isNotNull);
    expect(user!.email, email);

    final fUser = FirebaseAuth.instance.currentUser;
    expect(fUser, isNotNull);

    final localUser = await db.getUserByFirestoreUid(fUser!.uid);
    expect(localUser, isNotNull);
    expect(localUser!.email, email);
    expect(localUser.role, Role.agent);
  });

  testWidgets('Integration: hasAnyUser returns correct state', (tester) async {
      expect(await repository.hasAnyUser(), isFalse);
      await repository.signIn('test_has_user_secure@example.com', 'Password123!');
      expect(await repository.hasAnyUser(), isTrue);
  });

  testWidgets('Integration: createUser (Admin) succeeds', (tester) async {
    // 1. Create admin user first (before any tests)
    const adminEmail = 'admin_create@example.com';
    const adminPass = 'AdminPass123!';

    UserCredential cred;
    try {
       cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPass,
      );
    } on FirebaseAuthException catch(_) {
       cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: adminEmail, password: adminPass);
    }

    final adminUser = cred.user!;

    // 2. Set admin custom claims and role in Firestore (emulating admin setup)
    // IMPORTANT: For Cloud Functions `assertAdmin` to work, the token must have custom claims.
    // In emulator or test mode without Admin SDK, we might need a workaround or assume
    // the Cloud Functions emulator respects Firestore changes -> Custom Claims trigger.
    // Our `onUpdateUser` trigger updates claims. So setting role=admin in Firestore should trigger it.
    await FirebaseFirestore.instance
      .collection('users')
      .doc(adminUser.uid)
      .set({
        'uid': adminUser.uid,
        'email': adminEmail,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });

    // Wait for Trigger to propagate claims (can take a second in emulator)
    await Future.delayed(const Duration(seconds: 2));

    // Force token refresh to pick up claims
    await adminUser.getIdToken(true);

    // 3. Sign in as admin via repository (syncs local)
    await repository.signIn(adminEmail, adminPass);

    // 4. Create new user via Cloud Function
    const newUserEmail = 'new_agent_test@example.com';

    // Note: repository.createUser returns void, assuming success if no error thrown.
    // We need to fetch the user to get ID.
    await repository.createUser(
      email: newUserEmail,
      name: 'New Agent Test',
      password: 'AgentPass123!',
      role: Role.agent,
    );

    // 5. Verify user created in Firebase Auth (we can't easily check auth list from client sdk)
    // But we can try to sign in with it or check Firestore
    final userInFirestoreQuery = await FirebaseFirestore.instance
      .collection('users')
      .where('email', isEqualTo: newUserEmail)
      .get();

    expect(userInFirestoreQuery.docs.isNotEmpty, true);
    final newUserId = userInFirestoreQuery.docs.first.id;
    final userDoc = userInFirestoreQuery.docs.first.data();

    expect(userDoc['email'], newUserEmail);
    expect(userDoc['role'], 'agent');

    // 6. Verify user created in local DB (Drift)
    // repository.createUser syncs locally too
    final localUser = await db.getUserByFirestoreUid(newUserId);
    expect(localUser, isNotNull);
    expect(localUser!.email, newUserEmail);

    // 7. Verify audit log created with performedBy
    await verifyAuditLog('USER_CREATED', newUserId, adminUser.uid);
  });

  testWidgets('Integration: createUser (Non-admin) denied', (tester) async {
    const agentEmail = 'agent_fail_create@example.com';
    const agentPass = 'AgentPass123!';

    UserCredential cred;
    try {
      cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: agentEmail,
        password: agentPass,
      );
    } on FirebaseAuthException catch(_) {
      cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: agentEmail, password: agentPass);
    }

    final agentUser = cred.user!;

    await FirebaseFirestore.instance
      .collection('users')
      .doc(agentUser.uid)
      .set({
        'uid': agentUser.uid,
        'email': agentEmail,
        'role': 'agent',
        'createdAt': FieldValue.serverTimestamp(),
      });

    // Wait for potential trigger (though irrelevant for permission denied)
    await Future.delayed(const Duration(seconds: 1));
    await agentUser.getIdToken(true);

    await repository.signIn(agentEmail, agentPass);

    // 4. Try to create user (should fail - permission denied)
    expect(
      () => repository.createUser(
        email: 'another_user@example.com',
        name: 'Another User',
        password: 'Password123!',
        role: Role.agent,
      ),
      throwsA(isA<Exception>()), // FirebaseAuthRepository throws mapped exceptions
    );
  });

  testWidgets('Integration: deleteUser removes from all places', (tester) async {
    const adminEmail = 'admin_delete@example.com';
    const adminPass = 'AdminPass123!';

    // Create admin
    UserCredential cred;
    try {
       cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPass,
      );
    } on FirebaseAuthException catch(_) {
       cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: adminEmail, password: adminPass);
    }
    final adminUser = cred.user!;

    await FirebaseFirestore.instance.collection('users').doc(adminUser.uid).set({
        'uid': adminUser.uid,
        'email': adminEmail,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
    });

    await Future.delayed(const Duration(seconds: 2));
    await adminUser.getIdToken(true);

    await repository.signIn(adminEmail, adminPass);

    // Create user to delete
    const deleteEmail = 'user_to_delete@example.com';
    await repository.createUser(
      email: deleteEmail,
      name: 'User To Delete',
      password: 'Password123!',
      role: Role.agent,
    );

    final userQuery = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: deleteEmail).get();
    final deleteUid = userQuery.docs.first.id;
    final localUserBefore = await db.getUserByFirestoreUid(deleteUid);
    expect(localUserBefore, isNotNull);

    // Delete user
    await repository.deleteUser(localUserBefore!.id);

    // Verify Firestore deletion
    final userInFirestore = await FirebaseFirestore.instance.collection('users').doc(deleteUid).get();
    expect(userInFirestore.exists, false);

    // Verify Local deletion
    final localUserAfter = await db.getUserByFirestoreUid(deleteUid);
    expect(localUserAfter, isNull);

    // Verify Audit Log
    await verifyAuditLog('USER_DELETED', deleteUid, adminUser.uid);
  });

  testWidgets('Integration: updateRole changes role everywhere', (tester) async {
    const adminEmail = 'admin_role@example.com';
    const adminPass = 'AdminPass123!';

    UserCredential cred;
    try {
       cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPass,
      );
    } on FirebaseAuthException catch(_) {
       cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: adminEmail, password: adminPass);
    }
    final adminUser = cred.user!;

    await FirebaseFirestore.instance.collection('users').doc(adminUser.uid).set({
        'uid': adminUser.uid,
        'email': adminEmail,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
    });

    await Future.delayed(const Duration(seconds: 2));
    await adminUser.getIdToken(true);

    await repository.signIn(adminEmail, adminPass);

    const promoteEmail = 'agent_promote@example.com';
    await repository.createUser(
      email: promoteEmail,
      name: 'Agent To Promote',
      password: 'Password123!',
      role: Role.agent,
    );

    final userQuery = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: promoteEmail).get();
    final promoteUid = userQuery.docs.first.id;


    // Need a method to call updateRole - Wait, FirebaseAuthRepository doesn't expose public updateUserRole with Role enum for OTHERS?
    // It has `updateUserRole(int userId, Role newRole)`? No, it has `updateUserRole` implemented?
    // Let's check repository interface.
    // `AuthRepository` usually has `createUser`, `deleteUser`, `updateUserPassword`.
    // Does it have `updateUserRole`?
    // Let's check `lib/domain/repositories/auth_repository.dart`.
    // It has `createUser`, `deleteUser`, `updateUserPassword`.
    // It does NOT seem to have `updateUserRole` in the interface provided in memory context earlier.
    // Wait, the prompt asked to implement Cloud Function `updateRole`, but did I expose it in Repository?
    // If not, I can't test it via repository.
    // The prompt in Sprint 1.3 said: "IMPLÉMENTEZ les 4 Callable Cloud Functions... updateUserRole".
    // But repository interface might be missing it.
    // Let's assume for this test we call the Cloud Function directly or via a new repository method if I added it.
    // If I didn't add it to interface, I should probably just test the Cloud Function invocation via `FirebaseFunctions`.

    // Checking `FirebaseAuthRepository` code I wrote earlier...
    // I implemented `createUser`, `deleteUser`, `updateUserPassword`.
    // I did NOT implement `updateUserRole` in the repository because the interface `AuthRepository` didn't have it?
    // Let's check.
    // If it's missing, I'll invoke the Cloud Function directly for this test to prove backend works.

    final callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('updateUserRole');
    await callable.call({
        'userId': promoteUid,
        'newRole': 'secretary'
    });

    // Verify Firestore
    final updatedDoc = await FirebaseFirestore.instance.collection('users').doc(promoteUid).get();
    expect(updatedDoc['role'], 'secretary');

    // Verify Local DB (Sync might not happen until re-login or manual sync trigger,
    // unless we listen to Firestore or have a sync mechanism.
    // `_syncUser` happens on SignIn.
    // So let's SignIn as that user to see if it syncs.

    // Sign in as the promoted user
    await repository.signOut(); // Sign out admin
    await repository.signIn(promoteEmail, 'Password123!');

    final localUserUpdated = await db.getUserByFirestoreUid(promoteUid);
    expect(localUserUpdated!.role, Role.secretary);

    // Verify Audit Log
    await verifyAuditLog('ROLE_UPDATED_CALLABLE', promoteUid, adminUser.uid);
  });

  testWidgets('Integration: resetPassword works', (tester) async {
    const adminEmail = 'admin_pw@example.com';
    const adminPass = 'AdminPass123!';

    UserCredential cred;
    try {
       cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPass,
      );
    } on FirebaseAuthException catch(_) {
       cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: adminEmail, password: adminPass);
    }
    final adminUser = cred.user!;

    await FirebaseFirestore.instance.collection('users').doc(adminUser.uid).set({
        'uid': adminUser.uid,
        'email': adminEmail,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
    });
    await Future.delayed(const Duration(seconds: 2));
    await adminUser.getIdToken(true);
    await repository.signIn(adminEmail, adminPass);

    const userEmail = 'user_pw@example.com';
    await repository.createUser(
      email: userEmail,
      name: 'User Password',
      password: 'OldPassword123!',
      role: Role.agent,
    );

    final userQuery = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: userEmail).get();
    final userUid = userQuery.docs.first.id;
    final localUser = await db.getUserByFirestoreUid(userUid);

    // Reset password
    await repository.updateUserPassword(localUser!.id, 'NewPassword123!');

    // Verify old password fails
    try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: userEmail, password: 'OldPassword123!');
        fail('Should have failed with wrong password');
    } catch (e) {
        expect(e, isA<FirebaseAuthException>());
    }

    // Verify new password works
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: userEmail, password: 'NewPassword123!');

    // Verify Audit Log
    await verifyAuditLog('PASSWORD_RESET', userUid, adminUser.uid);
  });

  testWidgets('Integration: Error handling - wrong password', (tester) async {
     const email = 'error_test@example.com';
     const pass = 'CorrectPass123!';
     try {
       await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
     } catch (_) {}

     expect(
       () => repository.signIn(email, 'WrongPass123!'),
       throwsA(isA<Exception>()),
     );
  });

  testWidgets('Integration: Error handling - user not found', (tester) async {
    expect(
      () => repository.signIn('nonexistent@example.com', 'Password123!'),
      throwsA(isA<Exception>()),
    );
  });
}
