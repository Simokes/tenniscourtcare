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
import 'package:go_router/go_router.dart';
import 'package:tenniscourtcare/features/auth/providers/auth_providers.dart';
import 'package:tenniscourtcare/features/auth/providers/setup_providers.dart';
import 'package:tenniscourtcare/core/providers/core_providers.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:tenniscourtcare/domain/repositories/auth_repository.dart';
import 'package:tenniscourtcare/features/terrain/providers/terrain_provider.dart';
import 'package:tenniscourtcare/features/inventory/providers/stock_provider.dart';
import 'package:tenniscourtcare/features/maintenance/providers/maintenance_provider.dart';

import 'package:tenniscourtcare/data/services/firebase_cache_service.dart';
import 'package:tenniscourtcare/features/maintenance/providers/maintenance_scheduler_provider.dart';

class FakeFirebaseCacheService extends Mock implements FirebaseCacheService {}

// HttpOverrides to mock network requests

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
  @override
  HttpHeaders get headers => MockHttpHeaders();
}

class MockHttpHeaders extends Mock implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void remove(String name, Object value) {}
  @override
  void removeAll(String name) {}
  @override
  void clear() {}
  @override
  void forEach(void Function(String name, List<String> values) action) {}
  @override
  List<String>? operator [](String name) => null;
  @override
  String? value(String name) => null;
  @override
  bool get chunkedTransferEncoding => false;
  @override
  set chunkedTransferEncoding(bool value) {}
  @override
  int get contentLength => 0;
  @override
  set contentLength(int value) {}
  @override
  ContentType? get contentType => null;
  @override
  set contentType(ContentType? value) {}
  @override
  DateTime? get date => null;
  @override
  set date(DateTime? value) {}
  @override
  DateTime? get expires => null;
  @override
  set expires(DateTime? value) {}
  @override
  String? get host => null;
  @override
  set host(String? value) {}
  @override
  DateTime? get ifModifiedSince => null;
  @override
  set ifModifiedSince(DateTime? value) {}
  @override
  int? get port => null;
  @override
  set port(int? value) {}
}

class MockHttpClientResponse extends Mock implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => imagePixels.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.value(imagePixels).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Future<E> drain<E>([E? futureValue]) async {
    return futureValue as E;
  }

  @override
  Future<HttpClientResponse> redirect(
      [String? method, Uri? url, bool? followLoops]) async {
    return this;
  }
}

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient();
    
  }
}

// 1x1 transparent PNG
const List<int> imagePixels = [
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4, 0x89, 0x00, 0x00, 0x00,
  0x0a, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9c, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0d, 0x0a, 0x2d, 0xb4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82
];

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
  MockAuthNotifier() : super(MockAuthRepository(), FakeRef());


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

List<Override> baseOverrides() => [
  terrainsProvider.overrideWith((ref) => Stream.value([])),
  stockProvider.overrideWith((ref) => Stream.value([])),
  maintenancesProvider.overrideWith((ref) => Stream.value([])),
   // null.overrideWith((ref) => Stream.value([])),
  firebaseCacheServiceProvider.overrideWithValue(FakeFirebaseCacheService()),
  authStateProvider.overrideWith((ref) => MockAuthNotifier()),
  maintenanceSchedulerProvider.overrideWith((ref) {}),
];

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  group('AppRouter Redirect Logic', () {
    testWidgets('redirects to /admin-setup when status is needsAdminSetup', (tester) async {
      await mockNetworkImagesFor(() async {
        late GoRouter router;
        tester.view.physicalSize = const Size(3000, 4000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...baseOverrides(),
              setupStatusProvider.overrideWith((ref) => Future.value(SetupStatus.needsAdminSetup)),
              setupStatusStreamProvider.overrideWith((ref) => Stream.value(SetupStatus.needsAdminSetup)),
            ],
            child: Consumer(builder: (context, ref, _) {
              router = ref.watch(goRouterProvider);
              return Directionality(textDirection: TextDirection.ltr, child: MaterialApp.router(routerConfig: router));
            }),
          ),
        );
        await tester.pumpAndSettle(const Duration(seconds: 1));
        expect(router.routerDelegate.currentConfiguration.uri.toString(), '/admin-setup');
      });
    });

    testWidgets('redirects to /login when status is needsLogin', (tester) async {
      await mockNetworkImagesFor(() async {
        late GoRouter router;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...baseOverrides(),
              setupStatusProvider.overrideWith((ref) => Future.value(SetupStatus.needsLogin)),
              setupStatusStreamProvider.overrideWith((ref) => Stream.value(SetupStatus.needsLogin)),
            ],
            child: Consumer(builder: (context, ref, _) {
              router = ref.watch(goRouterProvider);
              return Directionality(textDirection: TextDirection.ltr, child: MaterialApp.router(routerConfig: router));
            }),
          ),
        );
        await tester.pumpAndSettle(const Duration(seconds: 1));
        expect(router.routerDelegate.currentConfiguration.uri.toString(), '/login');
      });
    });

    testWidgets('redirects to / (home) when status is authenticated and on login page', (tester) async {
      await mockNetworkImagesFor(() async {
        late GoRouter router;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...baseOverrides(),
              setupStatusProvider.overrideWith((ref) => Future.value(SetupStatus.authenticated)),
              setupStatusStreamProvider.overrideWith((ref) => Stream.value(SetupStatus.authenticated)),
              currentUserProvider.overrideWith((ref) => UserEntity(
                id: 1, email: 'test@test.com', name: 'Test', role: Role.agent,
              )),
            ],
            child: Consumer(builder: (context, ref, _) {
              router = ref.watch(goRouterProvider);
              return Directionality(textDirection: TextDirection.ltr, child: MaterialApp.router(routerConfig: router));
            }),
          ),
        );
        await tester.pump();

        // Try to navigate to login
        router.go('/login');
        await tester.pump();
        expect(router.routerDelegate.currentConfiguration.uri.toString(), '/');
      });
    });

    testWidgets('redirects to /access-denied when status is error', (tester) async {
      late GoRouter router;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            setupStatusProvider.overrideWith((ref) => Future.error(Exception('error'))),
            setupStatusStreamProvider.overrideWith((ref) => Stream.error(Exception('error'))),
          ],
          child: Consumer(builder: (context, ref, _) {
            router = ref.watch(goRouterProvider);
            return MaterialApp.router(routerConfig: router);
          }),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(router.routerDelegate.currentConfiguration.uri.toString(), '/access-denied');
    });

    testWidgets('stays on /admin-setup when status is needsAdminSetup', (tester) async {
      await mockNetworkImagesFor(() async {
        late GoRouter router;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...baseOverrides(),
              setupStatusProvider.overrideWith((ref) => Future.value(SetupStatus.needsAdminSetup)),
              setupStatusStreamProvider.overrideWith((ref) => Stream.value(SetupStatus.needsAdminSetup)),
            ],
            child: Consumer(builder: (context, ref, _) {
              router = ref.watch(goRouterProvider);
              return MaterialApp.router(routerConfig: router);
            }),
          ),
        );
        await tester.pumpAndSettle(const Duration(seconds: 1));
        expect(router.routerDelegate.currentConfiguration.uri.toString(), '/admin-setup');
      });
    });
  });

  group('Role-Based Access Control', () {
    testWidgets('redirects to /access-denied if non-admin tries to access /admin', (tester) async {
      await mockNetworkImagesFor(() async {
        late GoRouter router;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...baseOverrides(),
              setupStatusProvider.overrideWith((ref) => Future.value(SetupStatus.authenticated)),
              setupStatusStreamProvider.overrideWith((ref) => Stream.value(SetupStatus.authenticated)),
              currentUserProvider.overrideWith((ref) => UserEntity(
                id: 1, email: 'user@test.com', name: 'User', role: Role.agent,
              )),
            ],
            child: Consumer(builder: (context, ref, _) {
              router = ref.watch(goRouterProvider);
              return MaterialApp.router(routerConfig: router);
            }),
          ),
        );
        await tester.pump();

        router.go('/admin');
        await tester.pump();
        expect(router.routerDelegate.currentConfiguration.uri.toString(), '/access-denied');
      });
    });

    testWidgets('allows access to /admin if user is admin', (tester) async {
      await mockNetworkImagesFor(() async {
        late GoRouter router;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...baseOverrides(),
              setupStatusProvider.overrideWith((ref) => Future.value(SetupStatus.authenticated)),
              setupStatusStreamProvider.overrideWith((ref) => Stream.value(SetupStatus.authenticated)),
              currentUserProvider.overrideWith((ref) => UserEntity(
                id: 1, email: 'admin@test.com', name: 'Admin', role: Role.admin,

              )),
            ],
            child: Consumer(builder: (context, ref, _) {
              router = ref.watch(goRouterProvider);
              return MaterialApp.router(routerConfig: router);
            }),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        router.go('/admin');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(router.routerDelegate.currentConfiguration.uri.toString(), '/admin');
      });
    });
  });

  group('Route Existence', () {
    testWidgets('can navigate to stock screen', (tester) async {
      await mockNetworkImagesFor(() async {
        tester.view.physicalSize = const Size(3000, 4000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        late GoRouter router;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...baseOverrides(),
              setupStatusProvider.overrideWith((ref) => Future.value(SetupStatus.authenticated)),
              setupStatusStreamProvider.overrideWith((ref) => Stream.value(SetupStatus.authenticated)),
              currentUserProvider.overrideWith((ref) => UserEntity(
                id: 1, email: 'a', name: 'a', role: Role.agent,
              )),
            ],
            child: Consumer(builder: (context, ref, _) {
              router = ref.watch(goRouterProvider);
              return Directionality(textDirection: TextDirection.ltr, child: MaterialApp.router(routerConfig: router));
            }),
          ),
        );
        await tester.pump();

        router.go('/stock');
        await tester.pump();
        expect(router.routerDelegate.currentConfiguration.uri.toString(), '/stock');
      });
    });

    testWidgets('can navigate to maintenance screen', (tester) async {
      await mockNetworkImagesFor(() async {
        tester.view.physicalSize = const Size(3000, 4000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        late GoRouter router;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...baseOverrides(),
              setupStatusProvider.overrideWith((ref) => Future.value(SetupStatus.authenticated)),
              setupStatusStreamProvider.overrideWith((ref) => Stream.value(SetupStatus.authenticated)),
              currentUserProvider.overrideWith((ref) => UserEntity(
                id: 1, email: 'a', name: 'a', role: Role.agent,
              )),
            ],
            child: Consumer(builder: (context, ref, _) {
              router = ref.watch(goRouterProvider);
              return Directionality(textDirection: TextDirection.ltr, child: MaterialApp.router(routerConfig: router));
            }),
          ),
        );
        await tester.pump();

        router.go('/maintenance');
        await tester.pump();
        expect(router.routerDelegate.currentConfiguration.uri.toString(), '/maintenance');
      });
    });
  });
}


class FakeRef extends Mock implements Ref<Object?> {
  @override
  T read<T>(ProviderListenable<T> provider) => throw UnimplementedError();
}
