import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/models/setup_status.dart';
import 'auth_providers.dart';

// PART 1: adminExistsProvider

/// Checks if an admin user exists in the Firestore database.
///
/// Returns [true] if at least one admin exists, [false] otherwise.
/// Returns [false] on error to force a safe fallback (likely setup required).
///
/// This provider is NOT auto-disposed as it represents a core app state check.
final adminExistsProvider = FutureProvider<bool>((ref) async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  } catch (e, st) {
    debugPrint('❌ adminExistsProvider error: $e\n$st');
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
    // Step 1: Check admin existence
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
    debugPrint('❌ setupStatusProvider error: $e\n$st');
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
