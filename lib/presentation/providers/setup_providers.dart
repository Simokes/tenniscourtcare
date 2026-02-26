import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/setup_status.dart';
import '../../domain/enums/role.dart';
import 'database_provider.dart';
import 'auth_providers.dart';

// Checks if an admin exists in the local database
final adminExistsProvider = FutureProvider.autoDispose<bool>((ref) async {
  final db = ref.watch(databaseProvider);
  final count = await db.countUsersByRole(Role.admin);
  return count > 0;
});

// Main coordinator for setup status
final setupStatusProvider = StreamProvider.autoDispose<SetupStatus>((ref) async* {
  yield SetupStatus.loading;

  try {
    // 1. Check if admin exists
    final adminExistsAsync = await ref.watch(adminExistsProvider.future);

    if (!adminExistsAsync) {
      yield SetupStatus.needsAdminSetup;
      return;
    }

    // 2. Watch Auth State
    final authStateAsync = ref.watch(authStateProvider);

    if (authStateAsync.isLoading) {
      yield SetupStatus.loading;
    } else if (authStateAsync.hasError) {
      yield SetupStatus.error;
    } else if (authStateAsync.hasValue) {
      final authState = authStateAsync.value;
      if (authState?.user != null) {
        yield SetupStatus.authenticated;
      } else {
        yield SetupStatus.needsLogin;
      }
    }
  } catch (e) {
    yield SetupStatus.error;
  }
});
