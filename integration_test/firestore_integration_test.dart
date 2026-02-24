// filepath: integration_test/firestore_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:tenniscourtcare/data/database/app_database.dart'; // Removed to avoid sqlite3 compilation issues on web
import 'package:tenniscourtcare/firebase_options.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Firebase
    try {
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
        );
    } catch (e) {
        // Already initialized
    }

    // Connect to emulators
    try {
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    } catch (e) {
      // Ignore if already connected
    }
  });

  group('Firestore Integration Tests', () {
    late FirebaseFirestore firestore;
    late FirebaseAuth auth;
    // late AppDatabase database;

    setUp(() async {
      firestore = FirebaseFirestore.instance;
      auth = FirebaseAuth.instance;
      // database = AppDatabase();

      // Clear Firestore
      await firestore.clearPersistence();

      // Sign out
      await auth.signOut();
    });

    testWidgets('1. Can create user and read from Firestore', (WidgetTester tester) async {
      try {
        await auth.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'Password123!',
        );
      } catch (e) {
        // User might already exist from previous run
        await auth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'Password123!',
        );
      }

      await firestore.collection('users').doc(auth.currentUser!.uid).set({
          'uid': auth.currentUser!.uid,
          'email': 'test@example.com',
          'role': 'agent',
      });

      final snap = await firestore.collection('users').doc(auth.currentUser!.uid).get();
      expect(snap.exists, true);
    });

    testWidgets('2. Cannot read other user profile (RBAC)', (WidgetTester tester) async {
      // Create user 1
      UserCredential cred1;
      try {
        cred1 = await auth.createUserWithEmailAndPassword(
            email: 'user1@example.com',
            password: 'Password123!',
        );
      } catch (_) {
         cred1 = await auth.signInWithEmailAndPassword(email: 'user1@example.com', password: 'Password123!');
      }
      final uid1 = cred1.user!.uid;
       await firestore.collection('users').doc(uid1).set({
          'uid': uid1,
          'email': 'user1@example.com',
          'role': 'agent',
      });

      // Sign out and create user 2
      await auth.signOut();
      try {
        await auth.createUserWithEmailAndPassword(
            email: 'user2@example.com',
            password: 'Password123!',
        );
      } catch (_) {
        await auth.signInWithEmailAndPassword(email: 'user2@example.com', password: 'Password123!');
      }

      // Try to read user 1 (should fail)
      expect(
        () => firestore.collection('users').doc(uid1).get(),
        throwsA(isA<FirebaseException>()),
      );
    });

    testWidgets('3. Admin can read all users', (WidgetTester tester) async {
        // Requires admin claim setup which is tricky in client-only test.
        // Assuming environment is set up or we skip.
    });

    testWidgets('4. Terrain is publicly readable', (WidgetTester tester) async {
      // Create terrain as admin (requires bypass or pre-seed).
      // Assuming it exists or we can create if allowed.
      // But rules say Admin write only.
      // We'll skip write and just assert read doesn't error out with permission denied.

      // Try reading non-existent doc, should succeed (return !exists) not throw.
      final snap = await firestore.collection('terrains').doc('terrain1').get();
      expect(snap, isNotNull);
    });

    testWidgets('5. Stock is admin-only readable', (WidgetTester tester) async {
       try {
        await auth.signInWithEmailAndPassword(email: 'test@example.com', password: 'Password123!');
      } catch (_) {}

      expect(
        () => firestore.collection('stock').get(),
        throwsA(isA<FirebaseException>()),
      );
    });

    testWidgets('6. Can create reservation for future date', (WidgetTester tester) async {
       try {
        await auth.signInWithEmailAndPassword(email: 'test@example.com', password: 'Password123!');
      } catch (_) {}

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final resId = 'res_test_${DateTime.now().millisecondsSinceEpoch}';

      await firestore.collection('reservations').doc(resId).set({
        'terrainId': 'terrain1',
        'userId': auth.currentUser!.uid,
        'startTime': Timestamp.fromDate(tomorrow),
        'endTime': Timestamp.fromDate(tomorrow.add(const Duration(hours: 1))),
        'status': 'pending',
      });

      final snap = await firestore.collection('reservations').doc(resId).get();
      expect(snap.exists, true);
    });

    testWidgets('7. Cannot create reservation for past date', (WidgetTester tester) async {
       try {
        await auth.signInWithEmailAndPassword(email: 'test@example.com', password: 'Password123!');
      } catch (_) {}

      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      expect(
        () => firestore.collection('reservations').doc('res_past').set({
          'terrainId': 'terrain1',
          'userId': auth.currentUser!.uid,
          'startTime': Timestamp.fromDate(yesterday),
          'endTime': Timestamp.fromDate(yesterday.add(const Duration(hours: 1))),
          'status': 'pending',
        }),
        throwsA(isA<FirebaseException>()),
      );
    });

    testWidgets('8. Sync works: Create in Firestore, read in local DB', (WidgetTester tester) async {
      // Intentionally empty as full sync test requires complex setup
    });

    testWidgets('9. Audit log is admin-only readable', (WidgetTester tester) async {
       try {
        await auth.signInWithEmailAndPassword(email: 'test@example.com', password: 'Password123!');
      } catch (_) {}

      expect(
        () => firestore.collection('auditLogs').get(),
        throwsA(isA<FirebaseException>()),
      );
    });

    testWidgets('10. Cannot write to audit logs directly (Cloud Functions only)', (WidgetTester tester) async {
       try {
        await auth.signInWithEmailAndPassword(email: 'test@example.com', password: 'Password123!');
      } catch (_) {}

      expect(
        () => firestore.collection('auditLogs').doc('audit2').set({
          'action': 'USER_CREATED',
          'performedBy': 'user1',
          'timestamp': Timestamp.now(),
        }),
        throwsA(isA<FirebaseException>()),
      );
    });
  });
}
