import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenniscourtcare/data/repositories/firebase_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import 'core_providers.dart';

class AuthState {
  final UserEntity? user;
  final bool isSetupRequired;

  const AuthState({this.user, this.isSetupRequired = false});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.user == user &&
        other.isSetupRequired == isSetupRequired;
  }

  @override
  int get hashCode => Object.hash(user, isSetupRequired);
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return FirebaseAuthRepository(db);
});

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AuthState>>((ref) {
      return AuthNotifier(ref.watch(authRepositoryProvider), ref);
    });

class AuthNotifier extends StateNotifier<AsyncValue<AuthState>> {
  final AuthRepository _repo;
  final Ref ref;

  AuthNotifier(this._repo, this.ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final hasUsers = await _repo.hasAnyUser();

      if (!hasUsers) {
        state = const AsyncValue.data(
          AuthState(user: null, isSetupRequired: true),
        );
        return;
      }

      final user = await _repo.getCurrentUser();
      state = AsyncValue.data(AuthState(user: user, isSetupRequired: false));
    } catch (e, st) {
    // ✅ Émettre error state pour que setupStatusProvider peut réagir
    state = AsyncValue.error(e, st);
  }
  }

  Future<void> registerAdmin(String email, String name, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.createAdminUser(email: email, name: name, password: password);

      state = AsyncValue.data(AuthState(user: user, isSetupRequired: false));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signIn(email, password);
      if (user != null) {
        // ✅ Start FirebaseCacheService
        final cacheService = ref.read(firebaseCacheServiceProvider);
        cacheService.startListening();
        debugPrint('🔥 AuthNotifier: Cache listeners started');

        state = AsyncValue.data(AuthState(user: user, isSetupRequired: false));
      } else {
        state = AsyncValue.error('Identifiants invalides', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    // ✅ Stop FirebaseCacheService
    final cacheService = ref.read(firebaseCacheServiceProvider);
    cacheService.stopListening();
    debugPrint('🔥 AuthNotifier: Cache listeners stopped');

    await _repo.signOut();

    state = const AsyncValue.data(
      AuthState(user: null, isSetupRequired: false),
    );
  }
}

final currentUserProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authStateProvider).value?.user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

final isSetupRequiredProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).value?.isSetupRequired ?? false;
});
