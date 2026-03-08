import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenniscourtcare/features/admin/providers/admin_providers.dart';
import 'package:tenniscourtcare/features/auth/providers/auth_providers.dart';
import 'package:tenniscourtcare/features/auth/providers/security_providers.dart';
import 'package:tenniscourtcare/domain/repositories/auth_repository.dart';
import 'package:tenniscourtcare/data/repositories/audit_repository.dart';
import 'package:tenniscourtcare/domain/entities/user_entity.dart';
import 'package:tenniscourtcare/domain/enums/role.dart';
import 'package:tenniscourtcare/core/security/auth_exceptions.dart'; // Added
import 'package:tenniscourtcare/data/database/app_database.dart';

// Manual Fake for AuthRepository
class FakeAuthRepository implements AuthRepository {
  @override
  Future<List<UserEntity>> getAllUsers() async {
    return [];
  }

  @override
  Future<void> createUser({
    required String email,
    required String name,
    required String password,
    required Role role,
  }) async {
    // No-op for test
  }

  @override
  Future<void> deleteUser(int userId) async {
    // No-op for test
  }

  @override
  Future<void> updateUserPassword(int userId, String newPassword) async {
    // No-op for test
  }

  @override
  Future<void> updateUserRole(int userId, Role newRole) async {
    // No-op for test
  }

  // Other methods required by interface but not used in this specific test scope
  @override
  Future<UserEntity?> getCurrentUser() async => null;
  @override
  Future<bool> hasAnyUser() async => true;

  Future<void> registerAdmin(
    String email,
    String name,
    String password,
  ) async {}

  @override
  Future<UserEntity> createAdminUser({
    required String email,
    required String name,
    required String password,
  }) async {
    // No-op for test - return a fake user
    return UserEntity(id: 1, email: email, name: name, role: Role.admin);
  }

  @override
  Future<void> signUp({
    required String email,
    required String name,
    required String password,
    required Role role,
  }) async {}

  @override
  Future<void> approveUser(String userId) async {}

  @override
  Future<void> rejectUser(String userId) async {}
  @override
  Future<void> requestOtp(String email) async {}
  @override
  Future<UserEntity?> signIn(String email, String password) async => null;
  @override
  Future<void> signOut() async {}
  @override
  Future<bool> verifyOtp(String email, String code) async => false;
  @override
  Future<void> deleteUserAndData(int localId, String? firebaseId) async {}
  @override
  Future<void> updateDisplayName(String name) async {}
  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {}
}

// Manual Fake for AuditRepository
class FakeAuditRepository implements AuditRepository {
  @override
  Future<List<AuditLog>> getRecentAuditLogs({int limit = 100}) async {
    return [];
  }

  @override
  Future<void> logEvent({
    required String action,
    String? email,
    int? userId,
    String? ipAddress,
    String? deviceInfo,
    Map<String, dynamic>? details,
  }) async {
    // No-op
  }

  @override
  Future<void> cleanOldAttempts(DateTime cutoff) async {}
  @override
  Future<int> countRecentOtps(String email, DateTime since) async => 0;
  @override
  Future<List<LoginAttempt>> getRecentAttempts(
    String email,
    DateTime since,
  ) async => [];
  @override
  Future<void> logLoginAttempt({
    required String email,
    required bool success,
    String? ipAddress,
  }) async {}
}

void main() {
  late FakeAuthRepository fakeAuthRepo;
  late FakeAuditRepository fakeAuditRepo;

  setUp(() {
    fakeAuthRepo = FakeAuthRepository();
    fakeAuditRepo = FakeAuditRepository();
  });

  // Helper to create container with overrides
  ProviderContainer createContainer({UserEntity? currentUser}) {
    return ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        auditRepositoryProvider.overrideWithValue(fakeAuditRepo),
        currentUserProvider.overrideWithValue(currentUser),
      ],
    );
  }

  group('Admin Providers Security', () {
    test(
      'adminUsersProvider throws UnauthorizedException if user is not admin',
      () async {
        final user = UserEntity(
          id: 1,
          email: 'agent@test.com',
          name: 'Agent',
          role: Role.agent,
        );
        final container = createContainer(currentUser: user);

        expect(
          () => container.read(adminUsersProvider.future),
          throwsA(isA<UnauthorizedException>()),
        );
      },
    );

    test(
      'adminUsersProvider throws UnauthorizedException if user is null',
      () async {
        final container = createContainer(currentUser: null);

        expect(
          () => container.read(adminUsersProvider.future),
          throwsA(isA<UnauthorizedException>()),
        );
      },
    );

    test(
      'securityLogsProvider throws UnauthorizedException if user is not admin',
      () async {
        final user = UserEntity(
          id: 1,
          email: 'agent@test.com',
          name: 'Agent',
          role: Role.agent,
        );
        final container = createContainer(currentUser: user);

        expect(
          () => container.read(securityLogsProvider.future),
          throwsA(isA<UnauthorizedException>()),
        );
      },
    );
  });

  group('UserManagementController Security', () {
    test(
      'createUser throws UnauthorizedException if user is not admin',
      () async {
        final user = UserEntity(
          id: 1,
          email: 'agent@test.com',
          name: 'Agent',
          role: Role.agent,
        );
        final container = createContainer(currentUser: user);

        final subscription = container.listen(
          userManagementControllerProvider,
          (p, n) {},
        );
        final controller = container.read(
          userManagementControllerProvider.notifier,
        );

        await controller.createUser(
          email: 'new@test.com',
          name: 'New',
          password: 'password',
          role: Role.agent,
        );

        final state = container.read(userManagementControllerProvider);

        // AsyncError is wrapped
        expect(state, isA<AsyncError>());
        // Check message content
        expect(state.asError?.error.toString(), contains('Non autorisé'));

        subscription.close();
      },
    );

    test(
      'deleteUser throws UnauthorizedException if user is not admin',
      () async {
        final user = UserEntity(
          id: 1,
          email: 'agent@test.com',
          name: 'Agent',
          role: Role.agent,
        );
        final container = createContainer(currentUser: user);

        final subscription = container.listen(
          userManagementControllerProvider,
          (p, n) {},
        );
        final controller = container.read(
          userManagementControllerProvider.notifier,
        );

        await controller.deleteUser(2);

        final state = container.read(userManagementControllerProvider);

        expect(state, isA<AsyncError>());
        expect(state.asError?.error.toString(), contains('Non autorisé'));

        subscription.close();
      },
    );
  });
}
