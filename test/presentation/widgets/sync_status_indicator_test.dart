import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenniscourtcare/presentation/widgets/sync_status_indicator.dart';
import 'package:tenniscourtcare/presentation/providers/connectivity_providers.dart';

void main() {
  testWidgets('Displays Online state (compact)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isOnlineStatusProvider.overrideWith((ref) => Stream.value(true)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ConnectionStatusIndicator(mode: SyncIndicatorMode.compact),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Online'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_done), findsOneWidget);
  });

  testWidgets('Displays Offline state (compact)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isOnlineStatusProvider.overrideWith((ref) => Stream.value(false)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ConnectionStatusIndicator(mode: SyncIndicatorMode.compact),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Offline'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
  });

  testWidgets('Displays Online state (detailed)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isOnlineStatusProvider.overrideWith((ref) => Stream.value(true)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ConnectionStatusIndicator(mode: SyncIndicatorMode.detailed),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Receiving real-time updates'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_done), findsOneWidget);
  });
}
