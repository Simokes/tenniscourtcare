import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenniscourtcare/presentation/widgets/sync_status_indicator.dart';
import 'package:tenniscourtcare/domain/models/sync_status_model.dart';

void main() {
  testWidgets('Displays Syncing state', (tester) async {
    final model = SyncStatusModel(
      isSyncing: true,
      hasError: false,
      lastSyncTime: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSyncStatusProvider.overrideWith((ref) => Stream.value(model)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SyncStatusIndicator(mode: SyncIndicatorMode.compact),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Syncing...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Displays Success state', (tester) async {
    final now = DateTime.now();
    final model = SyncStatusModel(
      isSyncing: false,
      hasError: false,
      lastSyncTime: now.subtract(const Duration(minutes: 5)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSyncStatusProvider.overrideWith((ref) => Stream.value(model)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SyncStatusIndicator(mode: SyncIndicatorMode.compact),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Synced 5m ago'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets('Displays Error state', (tester) async {
    final model = SyncStatusModel(
      isSyncing: false,
      hasError: true,
      errorMessage: 'Network Error',
      lastSyncTime: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSyncStatusProvider.overrideWith((ref) => Stream.value(model)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SyncStatusIndicator(mode: SyncIndicatorMode.compact),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Error'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('Displays Detailed mode', (tester) async {
    final now = DateTime.now();
    final model = SyncStatusModel(
      isSyncing: false,
      hasError: false,
      lastSyncTime: now.subtract(const Duration(hours: 1)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSyncStatusProvider.overrideWith((ref) => Stream.value(model)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SyncStatusIndicator(mode: SyncIndicatorMode.detailed),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Data Synced'), findsOneWidget);
    expect(find.text('Last update: 1h ago'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
