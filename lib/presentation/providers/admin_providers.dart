import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/enums/role.dart';
import '../../data/database/app_database.dart';
import 'auth_providers.dart';
import 'security_providers.dart';

// Provider pour la liste des utilisateurs (vue Admin)
final adminUsersProvider = FutureProvider.autoDispose<List<UserEntity>>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getAllUsers();
});

// Provider pour les logs de sécurité
final securityLogsProvider = FutureProvider.autoDispose<List<AuditLog>>((ref) async {
  final auditRepo = ref.watch(auditRepositoryProvider);
  return auditRepo.getRecentAuditLogs();
});

// Contrôleur pour les actions d'administration des utilisateurs
class UserManagementController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  UserManagementController(this._ref) : super(const AsyncValue.data(null));

  Future<void> createUser({
    required String email,
    required String name,
    required String password,
    required Role role,
  }) async {
    state = const AsyncValue.loading();
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      await authRepo.createUser(email: email, name: name, password: password, role: role);

      // Rafraîchir la liste
      _ref.invalidate(adminUsersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteUser(int userId) async {
    state = const AsyncValue.loading();
    try {
       final authRepo = _ref.read(authRepositoryProvider);
       await authRepo.deleteUser(userId);

       _ref.invalidate(adminUsersProvider);
       state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> resetPassword(int userId, String newPassword) async {
    state = const AsyncValue.loading();
    try {
       final authRepo = _ref.read(authRepositoryProvider);
       await authRepo.updateUserPassword(userId, newPassword);
       state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final userManagementControllerProvider = StateNotifierProvider.autoDispose<UserManagementController, AsyncValue<void>>((ref) {
  return UserManagementController(ref);
});
