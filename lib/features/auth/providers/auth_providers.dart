import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenniscourtcare/data/repositories/firebase_auth_repository.dart';
import '../../../core/providers/connectivity_providers.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'dart:async';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/enums/role.dart';
import '../../../core/providers/core_providers.dart';

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
      final user = await _repo.createAdminUser(
        email: email,
        name: name,
        password: password,
      );

      state = AsyncValue.data(AuthState(user: user, isSetupRequired: false));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUp(
    String email,
    String name,
    String password,
    Role role,
  ) async {
    state = const AsyncValue.loading();
    try {
      await _repo.signUp(
        email: email,
        name: name,
        password: password,
        role: role,
      );
      // Stay on login page after signup, user is inactive
      state = const AsyncValue.data(
        AuthState(user: null, isSetupRequired: false),
      );
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

        // ✅ Start connectivity monitoring for listener resilience
        final connectivityStream = ref.read(isOnlineStatusProvider.stream);
        cacheService.startConnectivityMonitoring(connectivityStream);

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

final pendingUsersProvider = StreamProvider<List<UserEntity>>((ref) {
  return ref.read(databaseProvider).watchPendingUsers();
});

final pendingCountProvider = Provider<int>((ref) {
  return ref
      .watch(pendingUsersProvider)
      .maybeWhen(data: (users) => users.length, orElse: () => 0);
});

class UserApprovalNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state
  }

  Future<void> approveUser(String userId) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.approveUser(userId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> rejectUser(String userId) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.rejectUser(userId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final userApprovalNotifierProvider =
    AsyncNotifierProvider<UserApprovalNotifier, void>(UserApprovalNotifier.new);
