import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenniscourtcare/domain/models/setup_status.dart';
import 'package:tenniscourtcare/presentation/providers/setup_providers.dart';
import 'package:tenniscourtcare/presentation/providers/auth_providers.dart';
import 'package:tenniscourtcare/domain/entities/user_entity.dart';
import 'package:tenniscourtcare/domain/enums/role.dart';
import 'package:tenniscourtcare/domain/entities/sync_status.dart';
import 'package:tenniscourtcare/domain/repositories/auth_repository.dart';

class StalledAuthRepository implements AuthRepository {
  @override
  Future<bool> hasAnyUser() => Completer<bool>().future;

  @override
  Future<UserEntity?> getCurrentUser() => Completer<UserEntity?>().future;

  @override
  Future<UserEntity> createAdminUser({required String email, required String name, required String password}) => throw UnimplementedError();

  @override
  Future<void> createUser({required String email, required String name, required String password, required Role role}) => throw UnimplementedError();

  @override
  Future<void> deleteUser(int userId) => throw UnimplementedError();

  @override
  Future<List<UserEntity>> getAllUsers() => throw UnimplementedError();

  @override
  Future<void> requestOtp(String email) => throw UnimplementedError();

  @override
  Future<UserEntity?> signIn(String email, String password) => throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();

  @override
  Future<void> updateUserPassword(int userId, String newPassword) => throw UnimplementedError();

  @override
  Future<bool> verifyOtp(String email, String code) => throw UnimplementedError();
}

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier(AsyncValue<AuthState> initialState) : super(StalledAuthRepository()) {
    state = initialState;
  }
}

void main() {
  group('setupStatusProvider', () {
    test('emits loading then needsAdminSetup when admin does not exist', () async {
      final container = ProviderContainer(
        overrides: [
          adminExistsProvider.overrideWith((ref) => Future.value(false)),
        ],
      );

      final stream = container.read(setupStatusProvider.stream);

      expect(
        stream,
        emitsInOrder([
          SetupStatus.loading,
          SetupStatus.needsAdminSetup,
        ]),
      );
    });

    test('emits loading then needsLogin when admin exists but user is null', () async {
      final container = ProviderContainer(
        overrides: [
          adminExistsProvider.overrideWith((ref) => Future.value(true)),
          authStateProvider.overrideWith((ref) => MockAuthNotifier(
            const AsyncValue.data(AuthState(user: null))
          )),
        ],
      );

      final stream = container.read(setupStatusProvider.stream);

      expect(
        stream,
        emitsInOrder([
          SetupStatus.loading,
          SetupStatus.needsLogin,
        ]),
      );
    });

    test('emits loading then authenticated when admin exists and user is logged in', () async {
      final user = UserEntity(
        id: 1,
        email: 'test@test.com',
        name: 'Test',
        role: Role.admin,
        syncStatus: SyncStatus.local,
      );

      final container = ProviderContainer(
        overrides: [
          adminExistsProvider.overrideWith((ref) => Future.value(true)),
          authStateProvider.overrideWith((ref) => MockAuthNotifier(
            AsyncValue.data(AuthState(user: user))
          )),
        ],
      );

      final stream = container.read(setupStatusProvider.stream);

      expect(
        stream,
        emitsInOrder([
          SetupStatus.loading,
          SetupStatus.authenticated,
        ]),
      );
    });

    test('emits loading then error if admin check fails', () async {
      final container = ProviderContainer(
        overrides: [
          adminExistsProvider.overrideWith((ref) => Future.error('DB Error')),
        ],
      );

      final stream = container.read(setupStatusProvider.stream);

      expect(
        stream,
        emitsInOrder([
          SetupStatus.loading,
          SetupStatus.error,
        ]),
      );
    });
  });
}
