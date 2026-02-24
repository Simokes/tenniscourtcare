import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    // Note: Verify these ports match your firebase.json configuration
    const host = 'localhost'; // Use 10.0.2.2 for Android Emulator if not using reverse proxy
    try {
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
    } catch (e) {
      print('Emulators might already be configured or failed to connect: $e');
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

  testWidgets('Full Authentication Cycle Integration Test', (tester) async {
    const email = 'test_integration_v1@example.com';
    const password = 'StrongPassword123!';

    // 1. Create User in Firebase (Simulating Console creation)
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code != 'email-already-in-use') rethrow;
      // If user exists, we continue to test SignIn
    }

    // 2. Sign In via Repository
    // This should trigger the synchronization with the local SQLite database
    final user = await repository.signIn(email, password);

    expect(user, isNotNull);
    expect(user!.email, email);

    // By default, no claims set via Client SDK creation, so Role should be Agent (default)
    expect(user.role, Role.agent);

    // 3. Verify Local Database State
    final localUser = await db.getUserByEmail(email);
    expect(localUser, isNotNull);
    expect(localUser!.email, email);
    expect(localUser.role, Role.agent);

    // 4. Verify ID persistence
    // The ID in UserEntity should match the ID in the local database
    expect(user.id, localUser.id);
  });
}
