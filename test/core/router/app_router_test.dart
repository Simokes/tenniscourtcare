import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mockito/mockito.dart';
import 'package:tenniscourtcare/core/router/app_router.dart';
import 'package:tenniscourtcare/domain/entities/user_entity.dart';
import 'package:tenniscourtcare/domain/enums/role.dart';
import 'package:tenniscourtcare/domain/models/setup_status.dart';
import 'package:tenniscourtcare/presentation/providers/auth_providers.dart';
import 'package:tenniscourtcare/presentation/providers/setup_providers.dart';
import 'package:tenniscourtcare/domain/entities/sync_status.dart';
import 'package:tenniscourtcare/domain/repositories/auth_repository.dart';

// HttpOverrides to mock network requests
class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient();
  }
}

class MockHttpClient extends Mock implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return MockHttpClientRequest();
  }
}

class MockHttpClientRequest extends Mock implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse();
  }
}

class MockHttpClientResponse extends Mock implements HttpClientResponse {
  @override
  int get statusCode => 404;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return const Stream<List<int>>.empty().listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  // Implement drain to throw, allowing NetworkImage to catch the error gracefully
  @override
  Future<E> drain<E>([E? futureValue]) async {
    throw const SocketException('Mock Network Failure during drain');
  }
}

// Helper to remove Timer from setupStatusStreamProvider
Stream<SetupStatus> safeSetupStream(Ref ref) async* {
  yield await ref.watch(setupStatusProvider.future);
}

// Mock Auth Repository
class MockAuthRepository extends Mock implements AuthRepository {
  @override
  Future<bool> hasAnyUser() async => false;
}

// Mock AuthNotifier
class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier() : super(MockAuthRepository());


  void setAuthState(AsyncValue<AuthState> newState) {
    state = newState;
  }

  @override
  Future<void> registerAdmin(String email, String name, String password) async {}

  @override
  Future<void> signIn(String email, String password) async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  group('AppRouter Redirect Logic', () {
    testWidgets('redirects to /admin-setup when status is needsAdminSetup', (tester) async {
      final container = ProviderContainer(
        overrides: [
          setupStatusProvider.overrideWith((ref) => SetupStatus.needsAdminSetup),
          setupStatusStreamProvider.overrideWith((ref) => Stream.value(SetupStatus.needsAdminSetup)),
        ],
      );

      // Keep alive
      container.listen(setupStatusProvider, (_, _) {});

      final router = container.read(goRouterProvider);
      await container.read(setupStatusProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.toString(), '/admin-setup');
    });

    testWidgets('redirects to /login when status is needsLogin', (tester) async {
      final container = ProviderContainer(
        overrides: [
          setupStatusProvider.overrideWith((ref) => SetupStatus.needsLogin),
          setupStatusStreamProvider.overrideWith((ref) => Stream.value(SetupStatus.needsLogin)),
        ],
      );

      container.listen(setupStatusProvider, (_, _) {});

      final router = container.read(goRouterProvider);
      await container.read(setupStatusProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.toString(), '/login');
    });

    testWidgets('redirects to / (home) when status is authenticated and on login page', (tester) async {
      final container = ProviderContainer(
        overrides: [
          setupStatusProvider.overrideWith((ref) => SetupStatus.authenticated),
          setupStatusStreamProvider.overrideWith((ref) => Stream.value(SetupStatus.authenticated)),
          currentUserProvider.overrideWith((ref) => UserEntity(
            id: 1,
            email: 'test@test.com',
            name: 'Test',
            role: Role.agent,
            syncStatus: SyncStatus.local
          )),
        ],
      );

      container.listen(setupStatusProvider, (_, _) {});

      final router = container.read(goRouterProvider);
      await container.read(setupStatusProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Try to navigate to login
      router.go('/login');
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.toString(), '/');
    });

    testWidgets('redirects to /access-denied when status is error', (tester) async {
      final container = ProviderContainer(
        overrides: [
          setupStatusProvider.overrideWith((ref) => SetupStatus.error),
          setupStatusStreamProvider.overrideWith((ref) => Stream.value(SetupStatus.error)),
        ],
      );

      container.listen(setupStatusProvider, (_, _) {});

      final router = container.read(goRouterProvider);
      await container.read(setupStatusProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.toString(), '/access-denied');
    });

    testWidgets('stays on /admin-setup when status is needsAdminSetup', (tester) async {
       final container = ProviderContainer(
        overrides: [
          setupStatusProvider.overrideWith((ref) => SetupStatus.needsAdminSetup),
          setupStatusStreamProvider.overrideWith((ref) => Stream.value(SetupStatus.needsAdminSetup)),
        ],
      );

      container.listen(setupStatusProvider, (_, _) {});

      final router = container.read(goRouterProvider);
      await container.read(setupStatusProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.toString(), '/admin-setup');
    });
  });

  group('Role-Based Access Control', () {
    testWidgets('redirects to /access-denied if non-admin tries to access /admin', (tester) async {
      final container = ProviderContainer(
        overrides: [
          setupStatusProvider.overrideWith((ref) => SetupStatus.authenticated),
          setupStatusStreamProvider.overrideWith((ref) => Stream.value(SetupStatus.authenticated)),
          currentUserProvider.overrideWith((ref) => UserEntity(
            id: 1,
            email: 'user@test.com',
            name: 'User',
            role: Role.agent, // Not admin
            syncStatus: SyncStatus.local
          )),
        ],
      );

      container.listen(setupStatusProvider, (_, _) {});

      final router = container.read(goRouterProvider);
      await container.read(setupStatusProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/admin');
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.toString(), '/access-denied');
    });

    testWidgets('allows access to /admin if user is admin', (tester) async {
      final container = ProviderContainer(
        overrides: [
          setupStatusProvider.overrideWith((ref) => SetupStatus.authenticated),
          setupStatusStreamProvider.overrideWith((ref) => Stream.value(SetupStatus.authenticated)),
          currentUserProvider.overrideWith((ref) => UserEntity(
            id: 1,
            email: 'admin@test.com',
            name: 'Admin',
            role: Role.admin, // Is admin
            syncStatus: SyncStatus.local
          )),
        ],
      );

      container.listen(setupStatusProvider, (_, _) {});

      final router = container.read(goRouterProvider);
      await container.read(setupStatusProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/admin');
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.toString(), '/admin');
    });
  });

  group('Route Existence', () {
    testWidgets('can navigate to stock screen', (tester) async {
      tester.view.physicalSize = const Size(3000, 4000); // Massive size to avoid overflows
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [
          // Override setupStatusProvider directly to authenticated
          setupStatusProvider.overrideWith((ref) => SetupStatus.authenticated),
          setupStatusStreamProvider.overrideWith((ref) => Stream.value(SetupStatus.authenticated)),
          // Override currentUserProvider just in case UI needs it
          currentUserProvider.overrideWith((ref) => UserEntity(id: 1, email: 'a', name: 'a', role: Role.agent, syncStatus: SyncStatus.local)),
        ],
      );

      container.listen(setupStatusProvider, (_, _) {});

      final router = container.read(goRouterProvider);
      await container.read(setupStatusProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/stock');
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(), '/stock');
    });

    testWidgets('can navigate to maintenance screen', (tester) async {
      tester.view.physicalSize = const Size(3000, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [
          setupStatusProvider.overrideWith((ref) => SetupStatus.authenticated),
          setupStatusStreamProvider.overrideWith((ref) => Stream.value(SetupStatus.authenticated)),
          currentUserProvider.overrideWith((ref) => UserEntity(id: 1, email: 'a', name: 'a', role: Role.agent, syncStatus: SyncStatus.local)),
        ],
      );

      container.listen(setupStatusProvider, (_, _) {});

      final router = container.read(goRouterProvider);
      await container.read(setupStatusProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();

      router.go('/maintenance');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(router.routerDelegate.currentConfiguration.uri.toString(), '/maintenance');
    });
  });
}
