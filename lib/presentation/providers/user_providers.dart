import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/enums/role.dart';
import 'core_providers.dart';
import 'auth_providers.dart';

// Fetch all users
final allUsersProvider = FutureProvider<List<UserEntity>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllUsers();
});

class UserManagementController extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;
  final Ref _ref;

  UserManagementController(this._db, this._ref)
    : super(const AsyncValue.data(null));

  Future<void> updateUserRole(int userId, Role newRole) async {
    state = const AsyncValue.loading();
    try {
      await _db.updateUserRole(userId, newRole);
      _ref.invalidate(allUsersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteUser(int userId, String? firebaseId) async {
    state = const AsyncValue.loading();
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      await authRepo.deleteUserAndData(userId, firebaseId);

      _ref.invalidate(allUsersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final userManagementControllerProvider =
    StateNotifierProvider<UserManagementController, AsyncValue<void>>((ref) {
      return UserManagementController(ref.watch(databaseProvider), ref);
    });
