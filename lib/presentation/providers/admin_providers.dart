import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/enums/role.dart';
import '../../data/database/app_database.dart';
import '../../core/security/security_exceptions.dart';
import '../../core/security/auth_exceptions.dart';
import 'auth_providers.dart';
import 'security_providers.dart';

// Provider pour la liste des utilisateurs (vue Admin)
final adminUsersProvider = FutureProvider.autoDispose<List<UserEntity>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);

  // 1. Permission Check
  if (currentUser == null || currentUser.role != Role.admin) {
    throw const UnauthorizedException(message: 'Accès refusé: Réservé aux administrateurs.');
  }

  final authRepo = ref.watch(authRepositoryProvider);
  final users = await authRepo.getAllUsers();

  // 2. Audit Logging
  final auditRepo = ref.watch(auditRepositoryProvider);
  await auditRepo.logEvent(
    action: 'USERS_LIST_VIEWED',
    email: currentUser.email,
    userId: currentUser.id,
  );

  return users;
});

// Provider pour les logs de sécurité
final securityLogsProvider = FutureProvider.autoDispose<List<AuditLog>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);

  // 1. Permission Check
  if (currentUser == null || currentUser.role != Role.admin) {
    throw const UnauthorizedException(message: 'Accès refusé: Réservé aux administrateurs.');
  }

  final auditRepo = ref.watch(auditRepositoryProvider);
  final logs = await auditRepo.getRecentAuditLogs();

  // 2. Audit Logging
  await auditRepo.logEvent(
    action: 'AUDIT_LOGS_VIEWED',
    email: currentUser.email,
    userId: currentUser.id,
  );

  return logs;
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
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null || currentUser.role != Role.admin) {
        throw const UnauthorizedException(message: 'Seul un administrateur peut créer des utilisateurs.');
      }

      final authRepo = _ref.read(authRepositoryProvider);

      // La méthode du repository inclut déjà la validation et l'audit logging
      // Mais on ajoute un double check ici pour la sécurité
      await authRepo.createUser(email: email, name: name, password: password, role: role);

      // Rafraîchir la liste
      _ref.invalidate(adminUsersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      _handleException(e, st);
    }
  }

  Future<void> deleteUser(int userId) async {
    state = const AsyncValue.loading();
    try {
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null || currentUser.role != Role.admin) {
        throw const UnauthorizedException(message: 'Seul un administrateur peut supprimer des utilisateurs.');
      }

       final authRepo = _ref.read(authRepositoryProvider);
       // La méthode du repository inclut la validation (self-delete, last-admin) et audit
       await authRepo.deleteUser(userId);

       _ref.invalidate(adminUsersProvider);
       state = const AsyncValue.data(null);
    } catch (e, st) {
      _handleException(e, st);
    }
  }

  Future<void> resetPassword(int userId, String newPassword) async {
    state = const AsyncValue.loading();
    try {
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null || currentUser.role != Role.admin) {
        throw const UnauthorizedException(message: 'Seul un administrateur peut modifier les mots de passe.');
      }

       final authRepo = _ref.read(authRepositoryProvider);
       // La méthode du repository inclut la validation et audit
       await authRepo.updateUserPassword(userId, newPassword);
       state = const AsyncValue.data(null);
    } catch (e, st) {
      _handleException(e, st);
    }
  }

  void _handleException(Object e, StackTrace st) {
    if (e is ValidationException) {
      state = AsyncValue.error('Erreur de validation: ${e.message}', st);
    } else if (e is UnauthorizedException) {
      state = AsyncValue.error('Non autorisé: ${e.message}', st);
    } else if (e is UserNotFoundException) {
      state = AsyncValue.error('Utilisateur introuvable', st);
    } else {
      state = AsyncValue.error('Erreur inattendue: $e', st);
    }
  }
}

final userManagementControllerProvider = StateNotifierProvider.autoDispose<UserManagementController, AsyncValue<void>>((ref) {
  return UserManagementController(ref);
});
