import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/enums/role.dart';
import '../../domain/models/setup_status.dart';
import 'auth_providers.dart';
import 'database_provider.dart';

// PART 1: adminExistsProvider

/// Checks if an admin user exists (Cloud-First with Local Fallback).
///
/// Returns [true] if at least one admin exists, [false] otherwise.
/// Throws a [SocketException] if network is unavailable AND no local admin exists.
///
/// This provider is NOT auto-disposed as it represents a core app state check.
final adminExistsProvider = FutureProvider<bool>((ref) async {
  try {
    // 1. Priorité Cloud (Firebase) avec timeout de 5 secondes
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get()
        .timeout(const Duration(seconds: 5));

    return querySnapshot.docs.isNotEmpty;
  } catch (e) {
    // 2. Fallback Réseau
    final isNetworkError = e is SocketException ||
                           e is TimeoutException ||
                           (e is FirebaseException && e.code == 'unavailable');

    if (isNetworkError) {
      debugPrint('⚠️ Erreur réseau détectée, basculement sur la base locale Drift. Erreur: $e');

      final db = ref.watch(databaseProvider);
      try {
        final count = await db.countUsersByRole(Role.admin);

        if (count == 0) {
           // 3. Cas d'Erreur Critique
           debugPrint('❌ Aucun réseau et aucun admin local trouvé.');
           throw const SocketException('No network and no local admin found');
        }

        return count > 0;
      } catch (localError) {
         debugPrint('❌ Erreur lors du fallback local: $localError');
         // Si la base locale échoue aussi, on relance l'erreur critique réseau (ou l'erreur locale)
         throw const SocketException('No network and no local admin found');
      }
    }

    // Autres types d'erreurs (permissions, etc.)
    debugPrint('❌ adminExistsProvider erreur inattendue: $e');
    return false;
  }
});

// PART 2: setupStatusProvider (MAIN COORDINATOR)

/// Orchestrates the application setup flow by determining the current [SetupStatus].
///
/// Logic:
/// 1. Checks if an admin exists using [adminExistsProvider].
/// 2. If no admin -> [SetupStatus.needsAdminSetup].
/// 3. If admin exists, checks [authStateProvider].
/// 4. If no user logged in -> [SetupStatus.needsLogin].
/// 5. If user logged in -> [SetupStatus.authenticated].
///
/// Handles loading and error states from dependencies.
final setupStatusProvider = FutureProvider<SetupStatus>((ref) async {
  try {
    // Step 1: Check admin existence (Cloud-First)
    final adminExists = await ref.watch(adminExistsProvider.future);

    if (!adminExists) {
      return SetupStatus.needsAdminSetup;
    }

    // Step 2: Check auth state
    final authStateAsync = ref.watch(authStateProvider);

    return authStateAsync.when(
      data: (authState) {
        if (authState.user != null) {
          return SetupStatus.authenticated;
        } else {
          return SetupStatus.needsLogin;
        }
      },
      loading: () => SetupStatus.loading,
      error: (err, stack) {
         debugPrint('❌ setupStatusProvider auth error: $err');
         return SetupStatus.error;
      },
    );

  } catch (e, st) {
    if (e is SocketException) {
      debugPrint('❌ Erreur critique réseau interceptée par setupStatusProvider: $e');
      // Pour l'instant, on retourne error, mais l'enum pourrait s'enrichir de noNetwork
      return SetupStatus.error;
    }
    debugPrint('❌ setupStatusProvider erreur inattendue: $e\n$st');
    return SetupStatus.error;
  }
});

// PART 3: setupStatusStreamProvider (FOR ROUTER)

/// Provides a stream of [SetupStatus] for the router to listen to.
///
/// Used by GoRouter's `refreshListenable`.
/// It emits the status from [setupStatusProvider] and keeps the stream alive.
final setupStatusStreamProvider = StreamProvider<SetupStatus>((ref) async* {
  try {
    // Watch the future provider. Triggers rebuild on change.
    final status = await ref.watch(setupStatusProvider.future);
    yield status;
  } catch (e) {
    yield SetupStatus.error;
  }

  // Keep stream alive to prevent closure, allowing Riverpod to manage updates via rebuilds
  await Future<void>.delayed(const Duration(days: 365));
});

// PART 4: Derived providers

/// Returns true if the user is fully authenticated and setup is complete.
final isAuthenticatedProvider = FutureProvider<bool>((ref) async {
  final status = await ref.watch(setupStatusProvider.future);
  return status == SetupStatus.authenticated;
});

/// Returns the current user if authenticated, or null otherwise.
final currentSetupUserProvider = FutureProvider<UserEntity?>((ref) async {
  final status = await ref.watch(setupStatusProvider.future);
  if (status == SetupStatus.authenticated) {
    // We can use currentUserProvider which derives from authStateProvider
    return ref.watch(currentUserProvider);
  }
  return null;
});
