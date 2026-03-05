import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/domain/entities/user_entity.dart';
import 'package:tenniscourtcare/domain/enums/role.dart';
import 'package:tenniscourtcare/domain/models/setup_status.dart';
import 'package:tenniscourtcare/features/auth/providers/auth_providers.dart';
import 'package:tenniscourtcare/core/providers/core_providers.dart';
import 'package:tenniscourtcare/features/auth/providers/setup_providers.dart' as setup;
import 'package:tenniscourtcare/domain/repositories/auth_repository.dart';

// Manual Mock for AppDatabase
class MockAppDatabase extends Mock implements AppDatabase {
  @override
  Future<int> countUsersByRole(Role? role) {
    return super.noSuchMethod(
      Invocation.method(#countUsersByRole, [role]),
      returnValue: Future.value(0),
      returnValueForMissingStub: Future.value(0),
    );
  }
}

// Dummy repo for constructor
class MockAuthRepository extends Mock implements AuthRepository {
  // Stub hasAnyUser to avoid constructor errors in AuthNotifier
  @override
  Future<bool> hasAnyUser() {
    return super.noSuchMethod(
      Invocation.method(#hasAnyUser, []),
      returnValue: Future.value(false),
      returnValueForMissingStub: Future.value(false),
    );
  }
}

// Mock AuthNotifier extending the real one to satisfy type check.
class MockAuthNotifier extends AuthNotifier {
  // Pass a dummy repo since we mock the methods anyway
  MockAuthNotifier() : super(MockAuthRepository(), FakeRef());

  // We override internal implementation to control state for tests

  void setState(AsyncValue<AuthState> newState) {
    state = newState;
  }

  @override
  Future<void> registerAdmin(String email, String name, String password) async {}

  @override
  Future<void> signIn(String email, String password) async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  late MockAppDatabase mockDb;
  late MockAuthNotifier mockAuthNotifier;

  setUp(() {
    mockDb = MockAppDatabase();
    mockAuthNotifier = MockAuthNotifier();
  });

  ProviderContainer createContainer({bool adminExists = true}) {
    return ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(mockDb),
        // Override with a function that returns the mock notifier
        authStateProvider.overrideWith((ref) => mockAuthNotifier),
        setup.adminExistsProvider.overrideWith((ref) async => adminExists), // Added override to avoid Firebase call
      ],
    );
  }

  group('setupStatusProvider', () {
    test('returns needsAdminSetup if admin check fails (false)', () async {
      // Auth state shouldn't matter here
      mockAuthNotifier.setState(const AsyncValue.loading());

      final container = createContainer(adminExists: false);
      final result = await container.read(setup.setupStatusProvider.future);

      expect(result, SetupStatus.needsAdminSetup);
    });

    test('returns loading if admin exists but auth is loading', () async {
      // Auth: Loading
      mockAuthNotifier.setState(const AsyncValue.loading());

      final container = createContainer();
      final result = await container.read(setup.setupStatusProvider.future);

      expect(result, SetupStatus.loading);
    });

    test('returns needsLogin if admin exists and no user logged in', () async {
      // Auth: Data, no user
      mockAuthNotifier.setState(
        const AsyncValue.data(AuthState(user: null, isSetupRequired: false)),
      );

      final container = createContainer();
      final result = await container.read(setup.setupStatusProvider.future);

      expect(result, SetupStatus.needsLogin);
    });

    test('returns authenticated if admin exists and user logged in', () async {

      // Auth: Data, with user
      final user = UserEntity(
        id: 1,
        email: 'test@test.com',
        name: 'Test',
        role: Role.admin,
      );
      mockAuthNotifier.setState(
        AsyncValue.data(AuthState(user: user, isSetupRequired: false)),
      );

      final container = createContainer();
      final result = await container.read(setup.setupStatusProvider.future);

      expect(result, SetupStatus.authenticated);
    });

    test('returns error if auth provider throws error', () async {
      // Auth: Error
      mockAuthNotifier.setState(
       const AsyncValue.error('Auth Failed', StackTrace.empty),
      );

      final container = createContainer();
      final result = await container.read(setup.setupStatusProvider.future);

      expect(result, SetupStatus.error);
    });
  });

  group('Derived Providers', () {

    test('currentSetupUserProvider returns user when authenticated', () async {
      final user = UserEntity(
        id: 1,
        email: 'test@test.com',
        name: 'Test',
        role: Role.admin,
      );
      mockAuthNotifier.setState(
        AsyncValue.data(AuthState(user: user, isSetupRequired: false)),
      );

      final container = createContainer();
      final result = await container.read(setup.currentSetupUserProvider.future);

      expect(result, user);
    });

    test('currentSetupUserProvider returns null when not authenticated', () async {
      mockAuthNotifier.setState(
        const AsyncValue.data(AuthState(user: null, isSetupRequired: false)),
      );

      final container = createContainer();
      final result = await container.read(setup.currentSetupUserProvider.future);

      expect(result, isNull);
    });
  });
}


class FakeRef extends Mock implements Ref<Object?> {
  @override
  T read<T>(ProviderListenable<T> provider) => throw UnimplementedError();
}
