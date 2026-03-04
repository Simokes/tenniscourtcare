import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/models/setup_status.dart';
import '../../domain/enums/role.dart';
import 'auth_providers.dart';
import 'core_providers.dart';

// PART 1: adminExistsProvider
final adminExistsProvider = FutureProvider<bool>((ref) async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get()
        .timeout(const Duration(seconds: 5));

    return querySnapshot.docs.isNotEmpty;
  } catch (e) {
    final isNetworkError = e is SocketException ||
        e is TimeoutException ||
        (e is FirebaseException && e.code == 'unavailable');

    if (isNetworkError) {
      debugPrint('⚠️ Réseau indisponible, fallback Drift. Erreur: $e');
      try {
        final db = ref.watch(databaseProvider);
        final count = await db.countUsersByRole(Role.admin);

        if (count == 0) {
          // ✅ FIX: fail-open — Drift vide ≠ pas d'admin
          // Première install ou DB effacée → laisser authState décider
          debugPrint('⚠️ Drift vide + réseau ko → assume admin exists');
          return true;
        }
        return count > 0;
      } catch (localError) {
        debugPrint('❌ Fallback Drift échoué: $localError');
        // ✅ FIX: fail-open plutôt que bloquer l'app
        return true;
      }
    }

    debugPrint('❌ adminExistsProvider erreur inattendue: $e');
    return true; // ✅ fail-open: laisser authState décider
  }
});

// PART 2: setupStatusProvider

final setupStatusProvider = FutureProvider<SetupStatus>((ref) async {
  try {
    final adminExists = await ref.watch(adminExistsProvider.future);

    if (!adminExists) {
      return SetupStatus.needsAdminSetup;
    }

    final authStateAsync = ref.watch(authStateProvider);

    // ✅ Guard explicite avant .when():
    if (authStateAsync.hasError) {
      debugPrint('❌ setupStatusProvider auth error: ${authStateAsync.error}');
      return SetupStatus.error;
    }

    return authStateAsync.when(
      data: (authState) => authState.user != null
          ? SetupStatus.authenticated
          : SetupStatus.needsLogin,
      loading: () => SetupStatus.loading,
      error: (err, _) {
        debugPrint('❌ setupStatusProvider auth error: $err');
        return SetupStatus.error;
      },
    );
  } catch (e, st) {
    if (e is SocketException) {
      debugPrint('❌ Erreur réseau: $e');
      return SetupStatus.error;
    }
    debugPrint('❌ setupStatusProvider erreur inattendue: $e\n$st');
    return SetupStatus.error;
  }
});

// PART 3: setupStatusStreamProvider ✅ FIXED — Stream continu
final setupStatusStreamProvider = StreamProvider<SetupStatus>((ref) {
  final controller = StreamController<SetupStatus>();

  // ✅ ref.listen → réagit à CHAQUE changement de setupStatusProvider:
  final sub = ref.listen<AsyncValue<SetupStatus>>(
    setupStatusProvider,
    (previous, next) {
      if (controller.isClosed) return;
      next.when(
        data: (status) => controller.add(status),
        loading: () {}, // ne pas émettre pendant loading
        error: (_, _) => controller.add(SetupStatus.error),
      );
    },
    fireImmediately: true, // ✅ émet la valeur courante au démarrage
  );

  ref.onDispose(() {
    sub.close();
    controller.close();
  });

  return controller.stream;
});

// PART 4: Derived providers

/// Returns the current user if authenticated, or null otherwise.
final currentSetupUserProvider = FutureProvider<UserEntity?>((ref) async {
  final status = await ref.watch(setupStatusProvider.future);
  if (status == SetupStatus.authenticated) {
    return ref.watch(currentUserProvider);
  }
  return null;
});