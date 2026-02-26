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
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Connect to emulators
    const host =
        'localhost'; // Use 10.0.2.2 for Android Emulator if not using reverse proxy
    try {
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
    } catch (e) {
      debugPrint(
        'Emulators might already be configured or failed to connect: $e',
      );
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

    expect(
      auditLog.docs.isNotEmpty,
      true,
      reason: 'Audit log for $action not found',
    );
    expect(
      auditLog.docs.first['performedBy'],
      performedByUserId,
      reason: 'PerformedBy mismatch',
    );
    expect(auditLog.docs.first['timestamp'], isNotNull);
  }

  testWidgets(
    'Integration: SignIn syncs firestore_uid and creates local user',
    (tester) async {
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
    },
  );

  testWidgets('Integration: hasAnyUser returns correct state', (tester) async {
    expect(await repository.hasAnyUser(), isFalse);
    await repository.signIn('test_has_user_secure@example.com', 'Password123!');
    expect(await repository.hasAnyUser(), isTrue);
  });

  testWidgets('Integration: createAdminUser creates admin + syncs', (
    tester,
  ) async {
    // Verify no admin exists initially
    expect(await repository.hasAnyUser(), isFalse);

    // Create admin via repository
    const adminEmail = 'fresh_admin@example.com';
    const adminName = 'Fresh Admin';
    const adminPass = 'AdminPass123!';

    final adminUser = await repository.createAdminUser(
      email: adminEmail,
      name: adminName,
      password: adminPass,
    );

    // Verify user created with admin role
    expect(adminUser.email, adminEmail);
    expect(adminUser.role, Role.admin);

    // Verify Firebase Auth user created
    final fbUser = FirebaseAuth.instance.currentUser;
    expect(fbUser, isNotNull);
    expect(fbUser!.email, adminEmail);

    // Verify Firestore document created
    final fsDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(fbUser!.uid)
        .get();
    expect(fsDoc.exists, true);
    expect(fsDoc['role'], 'admin');

    // Verify local DB synced
    final localAdmin = await db.getUserByFirestoreUid(fbUser.uid);
    expect(localAdmin, isNotNull);
    expect(localAdmin!.role, Role.admin);

    // Verify hasAnyUser now returns true
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
    } on FirebaseAuthException catch (_) {
      cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPass,
      );
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
    } on FirebaseAuthException catch (_) {
      cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: agentEmail,
        password: agentPass,
      );
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
    // We expect an exception that wraps the Cloud Function error (likely 'permission-denied')
    // FirebaseAuthRepository maps this to UnauthorizedException or similar.
    // For now, we assert it's an Exception, but ideally we'd check for specific type.
    // Since we don't have easy access to custom exceptions in test context without import,
    // we'll check if the string representation contains something meaningful or just stick to Exception for now,
    // but the intention is to be specific.
    // Let's at least ensure it fails.
    try {
      await repository.createUser(
        email: 'another_user@example.com',
        name: 'Another User',
        password: 'Password123!',
        role: Role.agent,
      );
      fail('Should have failed with permission denied');
    } catch (e) {
      // Confirm it's the expected error
      expect(e, isA<Exception>());
      // Optionally check for 'Permission refusée' if we import the exceptions
      // expect(e.toString(), contains('Permission refusée'));
    }
  });

  testWidgets('Integration: deleteUser removes from all places', (
    tester,
  ) async {
    const adminEmail = 'admin_delete@example.com';
    const adminPass = 'AdminPass123!';

    // Create admin
    UserCredential cred;
    try {
      cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPass,
      );
    } on FirebaseAuthException catch (_) {
      cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPass,
      );
    }
    final adminUser = cred.user!;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(adminUser.uid)
        .set({
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

    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: deleteEmail)
        .get();
    final deleteUid = userQuery.docs.first.id;
    final localUserBefore = await db.getUserByFirestoreUid(deleteUid);
    expect(localUserBefore, isNotNull);

    // Delete user
    await repository.deleteUser(localUserBefore!.id);

    // Verify Firestore deletion
    final userInFirestore = await FirebaseFirestore.instance
        .collection('users')
        .doc(deleteUid)
        .get();
    expect(userInFirestore.exists, false);

    // Verify Local deletion
    final localUserAfter = await db.getUserByFirestoreUid(deleteUid);
    expect(localUserAfter, isNull);

    // Verify Audit Log
    await verifyAuditLog('USER_DELETED', deleteUid, adminUser.uid);
  });

  testWidgets('Integration: updateRole changes role everywhere', (
    tester,
  ) async {
    const adminEmail = 'admin_role@example.com';
    const adminPass = 'AdminPass123!';

    UserCredential cred;
    try {
      cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPass,
      );
    } on FirebaseAuthException catch (_) {
      cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPass,
      );
    }
    final adminUser = cred.user!;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(adminUser.uid)
        .set({
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

    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: promoteEmail)
        .get();
    final promoteUid = userQuery.docs.first.id;

    // Fetch local user to get ID
    final localUserBefore = await db.getUserByFirestoreUid(promoteUid);
    expect(localUserBefore, isNotNull);

    // Call updateRole via repository
    await repository.updateUserRole(localUserBefore!.id, Role.secretary);

    // Verify Firestore with retry logic
    int retries = 5;
    DocumentSnapshot? updatedDoc;
    while (retries > 0) {
      updatedDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(promoteUid)
          .get();

      if (updatedDoc['role'] == 'secretary') break;

      await Future.delayed(const Duration(milliseconds: 500));
      retries--;
    }
    expect(
      updatedDoc!['role'],
      'secretary',
      reason: 'Firestore role not updated after retries',
    );

    // Verify Local DB (should be updated immediately by repository method)
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
    } on FirebaseAuthException catch (_) {
      cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPass,
      );
    }
    final adminUser = cred.user!;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(adminUser.uid)
        .set({
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

    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: userEmail)
        .get();
    final userUid = userQuery.docs.first.id;
    final localUser = await db.getUserByFirestoreUid(userUid);

    // Reset password
    await repository.updateUserPassword(localUser!.id, 'NewPassword123!');

    // Verify old password fails
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: userEmail,
        password: 'OldPassword123!',
      );
      fail('Should have failed with wrong password');
    } catch (e) {
      expect(e, isA<FirebaseAuthException>());
    }

    // Verify new password works
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: userEmail,
      password: 'NewPassword123!',
    );

    // Verify Audit Log
    await verifyAuditLog('PASSWORD_RESET', userUid, adminUser.uid);
  });

  testWidgets('Integration: Error handling - wrong password', (tester) async {
    const email = 'error_test@example.com';
    const pass = 'CorrectPass123!';
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );
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
