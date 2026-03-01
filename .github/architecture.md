# ARCHITECTURE.md

## 1. Architecture Pattern

**Pattern:** Clean Architecture + MVVM (via Riverpod) + Offline-First Cache

**Layers:**
- **Domain:** Business logic, entities, abstract repositories
- **Data:** Database (Drift/SQLite cache), Cloud (Firestore source of truth), repositories, mappers, cache service
- **Presentation:** UI (screens, widgets), state management (Riverpod providers), navigation (GoRouter)
- **Infrastructure:** External service adapters (image picker, share service, weather service)

**Dependency flow:** Presentation → Domain ← Data (unidirectional, no reverse dependencies)

---

## 2. Core Architectural Decision: Firebase as Source of Truth

> ⚠️ **CRITICAL RULE** — Read before any implementation.

```
Firebase (Firestore) = Source of Truth
Drift (SQLite)       = Read cache only
```

**Principles:**
1. **Writes** always go to Firestore first
2. **Drift** is updated ONLY by `FirebaseCacheService` via Firestore listeners
3. **UI** reads ONLY from Drift (via StreamProvider)
4. **No bidirectional sync** — no queue, no conflict resolution, no SyncStatus per entity
5. **Drift never written** by repositories, providers, or UI directly

**Data flow:**
```
WRITE:
UI action → Repository.create/update/delete() → Firestore → listener → Drift → UI rebuilt

READ:
UI → ref.watch(xxxProvider) → Drift stream → StreamProvider → UI
```

---

## 3. Layer Organization

### 3.1 Domain Layer (domain)

**Responsibility:** Pure business logic, NO framework dependencies

**Composition:**
```
domain/
├── entities/          # @immutable data classes (StockItem, User, Terrain, etc)
├── repositories/      # Abstract interfaces (StockRepository, AuthRepository, etc)
├── enums/            # Role, Permission, FeatureFlag
├── logic/            # Business services (PermissionResolver, StockCategorizer)
├── models/           # Domain-specific models (SetupStatus)
└── services/         # Domain services (WeatherRules)
```

**Rules:**
- Entities: `@immutable`, `copyWith()`, `==`, `hashCode`, `toString()`
- Repositories: Abstract classes only (NO implementation)
- No imports of: Drift, Firestore, Flutter, Riverpod
- Entities have: `id` (local int?), `firebaseId` (String?, Firestore doc ID), `createdAt`, `updatedAt`
- NO `syncStatus` field on entities (removed — Firestore is source of truth)

**Key entity pattern:**
```dart
@immutable
class StockItem {
  const StockItem({
    this.id,
    this.firebaseId,
    required this.name,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;            // Local Drift ID (auto-increment)
  final String? firebaseId; // Firestore doc ID (null until first listener sync)
  final String name;
  final int quantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  StockItem copyWith({...}) { }
  @override bool operator ==(Object other) { }
  @override int get hashCode { }
}
```

**Enums:**
```dart
// REMOVED: SyncStatus enum (no longer needed)

enum SetupStatus {
  loading,
  needsAdminSetup,
  needsLogin,
  authenticated,
  error,
  noNetworkFirstLaunch, // No internet + no local admin
}
```

---

### 3.2 Data Layer (data)

**Responsibility:** Data persistence (cache), cloud writes, data transformation

**Composition:**
```
data/
├── database/              # Drift/SQLite (read cache)
│   ├── app_database.dart  # @DriftDatabase with all tables
│   ├── tables/            # Table definitions (NO syncStatus column)
│   │   └── [name]_table.dart
│   └── queries/           # Custom queries, watch methods (streams only)
│
├── firestore/             # Cloud schema models
│   └── models/            # FirebaseStockModel, FirebaseTerrainModel, etc
│
├── repositories/          # Repository implementations
│   └── [entity]_repository_impl.dart
│
└── services/
    ├── firebase_cache_service.dart  # CORE: Firestore listeners → Drift updates
    └── firebase_auth_service.dart
```

**REMOVED from data layer:**
```
❌ firebase_sync_service.dart    (replaced by firebase_cache_service.dart)
❌ SyncQueue table               (no queue needed)
❌ syncStatus columns            (removed from all tables)
❌ pendingSync columns           (removed)
❌ lastSyncedAt columns          (removed)
```

**Repository pattern:**
```dart
class StockRepositoryImpl implements StockRepository {
  final AppDatabase _db;           // For reads only
  final FirebaseFirestore _fs;     // For writes only

  // READ: Always from Drift cache (kept fresh by FirebaseCacheService)
  @override
  Stream<List<StockItem>> watchAll() {
    return _db.watchStockItems().map(
      (rows) => rows.map(StockItemMapper.toDomain).toList(),
    );
  }

  // WRITE: Always to Firestore (Drift updated automatically via listener)
  @override
  Future<void> create(StockItem item) async {
    try {
      await _fs
          .collection('stock')
          .add(StockItemMapper.toFirestore(item));
      // ✅ Done. FirebaseCacheService listener handles Drift update.
    } on FirebaseException catch (e) {
      throw RepositoryException('Failed to create stock item: ${e.message}');
    }
  }

  @override
  Future<void> update(StockItem item) async {
    try {
      await _fs
          .collection('stock')
          .doc(item.firebaseId)
          .update(StockItemMapper.toFirestore(item));
    } on FirebaseException catch (e) {
      throw RepositoryException('Failed to update stock item: ${e.message}');
    }
  }

  @override
  Future<void> delete(String firebaseId) async {
    try {
      await _fs.collection('stock').doc(firebaseId).delete();
    } on FirebaseException catch (e) {
      throw RepositoryException('Failed to delete stock item: ${e.message}');
    }
  }
}
```

**FirebaseCacheService (CORE component):**
```dart
/// SOLE component authorized to write into Drift.
/// Listens to all Firestore collections and updates Drift cache.
/// Started on login, stopped on logout.
class FirebaseCacheService {
  final AppDatabase _db;
  final FirebaseFirestore _fs;
  final List<StreamSubscription> _subscriptions = [];

  /// Start all Firestore listeners. Call after authentication.
  void startListening() {
    _subscriptions.addAll([
      _listenStock(),
      _listenTerrains(),
      _listenMaintenances(),
      _listenEvents(),
    ]);
    debugPrint('🔥 CacheService: All listeners started');
  }

  /// Stop all listeners. Call on logout.
  void stopListening() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    debugPrint('🔥 CacheService: All listeners stopped');
  }

  StreamSubscription _listenStock() {
    return _fs.collection('stock').snapshots().listen(
      (snapshot) async {
        for (final change in snapshot.docChanges) {
          switch (change.type) {
            case DocumentChangeType.added:
            case DocumentChangeType.modified:
              await _db.upsertStockItem(
                StockItemMapper.toCompanion(change.doc),
              );
              break;
            case DocumentChangeType.removed:
              await _db.deleteStockItemByFirebaseId(change.doc.id);
              break;
          }
        }
      },
      onError: (Object e) =>
          debugPrint('❌ CacheService: Stock listener error: $e'),
    );
  }

  // Same pattern for _listenTerrains(), _listenMaintenances(), _listenEvents()
}
```

**Rules:**
- `FirebaseCacheService` is the ONLY component that writes to Drift
- Repositories write to Firestore ONLY
- Repositories read from Drift ONLY
- NO UI imports (Flutter, Riverpod) in data layer

---

### 3.3 Presentation Layer (presentation)

**Responsibility:** UI, state management, navigation, routing logic

**Composition:**
```
presentation/
├── providers/
│   ├── core_providers.dart              # databaseProvider, firebaseCacheServiceProvider
│   ├── auth_providers.dart              # authStateProvider, currentUserProvider
│   ├── setup_providers.dart             # setupStatusProvider (network-aware)
│   ├── [domain]_provider.dart           # stockProvider, terrainProvider (read Drift streams)
│   └── database_provider.dart           # Singleton Drift instance
│
├── pages/
│   ├── auth/
│   │   ├── login_page.dart              # With offline banner
│   │   └── admin_setup_page.dart
│   └── error/
│       ├── access_denied_page.dart
│       └── no_network_first_launch_page.dart
│
├── screens/
│   ├── maintenance_screen.dart
│   └── ...
│
└── widgets/
    ├── sync_status_indicator.dart       # Shows listener connection state
    └── access_control/
        ├── permission_visibility.dart
        ├── role_visibility.dart
        └── feature_flag_visibility.dart
```

**REMOVED from presentation layer:**
```
❌ firebase_sync_provider.dart      (replaced by FirebaseCacheService)
❌ SyncStatusModel                  (no longer needed)
❌ manualSyncProvider               (no manual sync)
❌ firebaseSyncStreamProvider       (replaced by listener)
```

**Provider pattern for reads:**
```dart
// Reads Drift stream — always fresh via FirebaseCacheService listener
final stockProvider = StreamProvider<List<StockItem>>((ref) {
  final repo = ref.watch(stockRepositoryProvider);
  return repo.watchAll(); // Drift stream
});
```

**Rules:**
- Providers READ: Use `StreamProvider` (Drift streams, always fresh)
- Providers WRITE: Call repository methods (Firestore)
- NO `firebaseSyncProvider` dependency in data providers
- NO `await syncAll()` before reading

---

### 3.4 Features Layer (features)

**Responsibility:** Feature-specific screens, widgets, models

```
features/
├── [feature]/
│   ├── presentation/
│   │   ├── screens/
│   │   └── widgets/
│   ├── models/
│   └── infrastructure/
```

**Rules:**
- Feature code is self-contained
- Feature models are NOT domain entities
- Providers in `presentation/providers/` only

---

### 3.5 Core Layer (core)

**Responsibility:** Shared infrastructure, configuration, routing, security

```
core/
├── config/
│   └── app_config.dart
├── router/
│   ├── app_router.dart        # GoRouter + setupStatusProvider gate
│   └── go_router_refresh_stream.dart
├── security/
│   ├── auth_validator.dart
│   ├── rate_limiter.dart
│   ├── token_service.dart
│   └── auth_exceptions.dart
└── theme/
    └── app_theme.dart
```

---

## 4. Dependency Rules

### 4.1 Import Rules (Strict)

**Domain** (most restricted):
```dart
❌ NEVER: import 'package:flutter/';
❌ NEVER: import 'package:flutter_riverpod/';
❌ NEVER: import 'package:drift/';
❌ NEVER: import 'package:cloud_firestore/';
✅ ONLY:  import 'domain/';
```

**Data** (can import domain):
```dart
✅ import 'package:drift/';
✅ import 'package:cloud_firestore/';
✅ import '../domain/';
❌ NEVER: import 'package:flutter_riverpod/';
❌ NEVER: import 'presentation/';
```

**Presentation** (can import domain + data):
```dart
✅ import 'package:flutter/';
✅ import 'package:flutter_riverpod/';
✅ import '../domain/';
✅ import '../data/';
❌ NEVER: import '../presentation/' (circular imports)
```

### 4.2 Provider Dependency Chain

```
setupStatusProvider (FutureProvider<SetupStatus>)
  ├─ adminExistsProvider (FutureProvider<bool>)
  │   ├─ [online]  → queries Firestore for admin
  │   └─ [offline] → queries Drift users table
  └─ authStateProvider (StateNotifierProvider)
      └─ watches Firebase Auth state

firebaseCacheServiceProvider (Provider<FirebaseCacheService>)
  └─ started in AuthNotifier.signIn()
  └─ stopped in AuthNotifier.signOut()

stockProvider (StreamProvider<List<StockItem>>)
  └─ reads Drift stream (kept fresh by FirebaseCacheService)
  // NO dependency on firebaseSyncProvider (removed)
```

**Rule:** Providers declare dependencies via `ref.watch()` only

---

## 5. Riverpod Provider Rules

### 5.1 Provider Types

| Type | Use case | Lifespan |
|------|----------|----------|
| `Provider<T>` | Synchronous, immutable | App lifetime |
| `FutureProvider<T>` | Async, single-shot | Until invalidated |
| `StreamProvider<T>` | Real-time Drift streams | Until invalidated |
| `StateProvider<T>` | Mutable UI state (filter, search) | Until invalidated |
| `StateNotifierProvider<N, T>` | Complex state + mutations | App lifetime |

**Rules:**
- Drift data: `StreamProvider` (continuous updates from listener)
- Auth state: `StateNotifierProvider`
- Setup status: `FutureProvider`
- UI state: `StateProvider`
- NEVER: `FutureProvider` for Drift data (use `StreamProvider`)

---

### 5.2 Provider Naming Convention

```dart
// Data providers (Drift streams — fresh via FirebaseCacheService)
final stockProvider = StreamProvider<List<StockItem>>(...);
final terrainProvider = StreamProvider<List<Terrain>>(...);

// Filtered/computed providers
final filteredStockItemsProvider = StreamProvider<List<StockItem>>(...);
final lowStockItemsProvider = StreamProvider.autoDispose<List<StockItem>>(...);

// State providers (mutable UI)
final stockFilterProvider = StateProvider<StockFilter>(...);
final stockSearchQueryProvider = StateProvider<String>(...);

// Action providers
final addStockItemProvider = Provider<Future<void> Function(StockItem)>(...);
final updateStockItemProvider = Provider<Future<void> Function(StockItem)>(...);

// Auth + setup
final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthState>>(...);
final setupStatusProvider = FutureProvider<SetupStatus>(...);

// Singleton services
final databaseProvider = Provider<AppDatabase>(...);
final firebaseCacheServiceProvider = Provider<FirebaseCacheService>(...);

// Derived
final isAuthenticatedProvider = Provider<bool>(...);
final currentUserProvider = Provider<UserEntity?>(...);
```

**REMOVED naming conventions:**
```
❌ firebaseSyncProvider       (removed)
❌ firebaseSyncStreamProvider (removed)
❌ manualSyncProvider         (removed)
❌ syncStatusProvider         (removed)
❌ fusionProvider             (removed)
```

---

### 5.3 Provider Scope

**Global scope (app lifetime):**
```dart
final databaseProvider = Provider<AppDatabase>(...);
final authRepositoryProvider = Provider<AuthRepository>(...);
final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthState>>(...);
final setupStatusProvider = FutureProvider<SetupStatus>(...);
final firebaseCacheServiceProvider = Provider<FirebaseCacheService>(...);
```

**Auto-dispose:**
```dart
final lowStockItemsProvider = StreamProvider.autoDispose<List<StockItem>>(...);
```

**Rules:**
- Singleton services: NO autoDispose
- Data streams: NO autoDispose (watched continuously)
- Derived/filtered: autoDispose if created on-demand
- Auth/setup: NO autoDispose (critical state)

---

### 5.4 Provider Invalidation

**When to invalidate:**
```dart
// After admin creation
ref.invalidate(setupStatusProvider);

// After logout
ref.invalidate(setupStatusProvider);

// NEVER needed for data providers:
// ❌ ref.invalidate(stockProvider)   ← Drift stream auto-updates via listener
// ❌ ref.invalidate(terrainProvider) ← Same
```

**Rules:**
- Data providers: NEVER manually invalidated (stream auto-updates)
- Setup/auth providers: Invalidate on auth state change
- NEVER invalidate StateProviders (use `.state =` instead)

---

### 5.5 Error Handling in Providers

```dart
final stockProvider = StreamProvider<List<StockItem>>((ref) {
  try {
    final repo = ref.watch(stockRepositoryProvider);
    return repo.watchAll(); // Drift stream
  } catch (e, st) {
    debugPrint('❌ Error loading stock: $e');
    rethrow;
  }
});
```

---

## 6. Error Management

### 6.1 Exception Hierarchy

```
Exception (base)
├── AuthException
│   ├── InvalidCredentialsException
│   ├── UserAlreadyExistsException
│   └── SessionExpiredException
│
├── SecurityException
│   ├── PermissionDeniedException
│   ├── RateLimitException
│   └── TokenExpiredException
│
├── RepositoryException        # NEW: Wraps Firestore write errors
│   ├── NetworkUnavailableException
│   └── WriteFailedException
│
└── CacheException             # NEW: Drift cache errors (rare)
    └── CacheReadException
```

**REMOVED exceptions:**
```
❌ SyncException       (no sync system)
❌ ConflictException   (no conflict resolution)
❌ SyncTimeoutException (no sync queue)
```

---

### 6.2 Error Handling Pattern

**Repository (write to Firestore):**
```dart
Future<void> create(StockItem item) async {
  try {
    await _fs.collection('stock').add(item.toFirestore());
  } on FirebaseException catch (e) {
    throw RepositoryException('Failed to create: ${e.message}');
  }
}
```

**Offline write error:**
```dart
// User attempts write without internet
try {
  await repository.create(item);
} on FirebaseException catch (e) {
  if (e.code == 'unavailable') {
    // Show: "Action impossible hors-ligne"
    // Drift NOT modified (no stale data)
  }
}
```

**UI:**
```dart
ref.watch(stockProvider).when(
  data: (items) => StockList(items),
  loading: () => LoadingIndicator(),
  error: (error, st) => ErrorWidget(error: error),
);
```

**Rules:**
- Write errors: Show message to user, do NOT modify Drift
- Read errors: Drift keeps last known value (stale but visible)
- Listener errors: Log only, UI continues with cache
- NEVER try/catch in UI widgets

---

## 7. Navigation

### 7.1 Router Setup

```dart
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      ref.read(setupStatusProvider.stream),
    ),
    redirect: (context, state) {
      final setupStatus = ref.read(setupStatusProvider).value;

      switch (setupStatus) {
        case SetupStatus.noNetworkFirstLaunch:
          return state.uri.path == '/no-network' ? null : '/no-network';
        case SetupStatus.needsAdminSetup:
          return state.uri.path == '/admin-setup' ? null : '/admin-setup';
        case SetupStatus.needsLogin:
          return state.uri.path == '/login' ? null : '/login';
        case SetupStatus.authenticated:
          if (state.uri.path == '/login' ||
              state.uri.path == '/admin-setup' ||
              state.uri.path == '/no-network') {
            return '/';
          }
          return null;
        default:
          return null;
      }
    },
    routes: [
      GoRoute(path: '/no-network', builder: ...),
      GoRoute(path: '/admin-setup', builder: ...),
      GoRoute(path: '/login', builder: ...),
      GoRoute(path: '/', builder: ..., routes: [
        GoRoute(path: 'stock', builder: ...),
        GoRoute(path: 'maintenance', builder: ...),
      ]),
    ],
  );
});
```

---

### 7.2 Setup Flow (Network-Aware)

```
App Start
  ↓
networkStatusProvider (connectivity_plus)
  │
  ├─ ONLINE:
  │   adminExistsProvider → checks Firestore
  │   ├─ admin exists     → needsLogin
  │   └─ no admin         → needsAdminSetup
  │
  └─ OFFLINE:
      adminExistsProvider → checks Drift
      ├─ admin in Drift   → needsLogin (offline banner on login page)
      └─ no admin         → noNetworkFirstLaunch

Login Page (offline mode):
  └─ signIn() tries Firebase Auth
      └─ network error → signInOffline() (checks Drift credentials hash)
          └─ success → authenticated (offline session)
          └─ on reconnect → FirebaseCacheService.startListening()
```

---

### 7.3 Auth Lifecycle + Cache Service

```dart
class AuthNotifier extends StateNotifier<AsyncValue<AuthState>> {
  final FirebaseCacheService _cacheService;

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _authRepo.signIn(email: email, password: password);
      
      // Start Firestore listeners → Drift stays fresh
      _cacheService.startListening();
      
      state = AsyncValue.data(AuthState.authenticated(...));
      ref.invalidate(setupStatusProvider);
    } catch (e, st) {
      // Try offline login if network unavailable
      await _signInOffline(email: email, password: password);
    }
  }

  Future<void> signOut() async {
    // Stop listeners before logout
    _cacheService.stopListening();
    
    await _authRepo.signOut();
    state = AsyncValue.data(AuthState.unauthenticated());
    ref.invalidate(setupStatusProvider);
  }
}
```

---

## 8. Folder Structure

```
lib/
├── core/
│   ├── config/
│   ├── router/
│   ├── security/
│   └── theme/
│
├── domain/
│   ├── entities/         # NO syncStatus field
│   ├── repositories/
│   ├── enums/            # Role, Permission (NO SyncStatus)
│   ├── logic/
│   └── models/           # SetupStatus
│
├── data/
│   ├── database/         # Drift (cache only, NO syncStatus columns)
│   │   └── tables/
│   ├── firestore/
│   │   └── models/
│   ├── repositories/     # Reads Drift, writes Firestore
│   ├── mappers/
│   └── services/
│       ├── firebase_cache_service.dart  # ← CORE: replaces sync service
│       └── firebase_auth_service.dart
│
├── features/
│   └── [feature]/
│       ├── presentation/
│       └── models/
│
├── presentation/
│   ├── providers/
│   ├── pages/
│   ├── screens/
│   └── widgets/
│
└── main.dart
```

---

## 9. Database Schema

### 9.1 Schema Rules

**Columns REMOVED from all tables:**
```
❌ syncStatus      (was: local|syncing|synced|error)
❌ pendingSync     (was: bool)
❌ lastSyncedAt    (was: DateTime?)
❌ lastModifiedBy  (was: String?)
```

**Columns KEPT on all tables:**
```
✅ id          (int, auto-increment, local PK)
✅ firebaseId  (String?, Firestore doc ID)
✅ createdAt   (DateTime)
✅ updatedAt   (DateTime)
```

**REMOVED tables:**
```
❌ SyncQueueTable  (no queue needed)
```

### 9.2 Schema Version

**Rule:** Bump schema version when:
- Adding/removing columns
- Adding/removing tables
- Changing column types

**Migration pattern:**
```dart
@DriftDatabase(version: 15)  // Bump from 14 → 15
class AppDatabase extends _$AppDatabase {
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 15) {
        // Remove sync columns
        // (Drift: drop table + recreate, or add nullable replacements)
        await m.recreateAllViews();
      }
    },
  );
}
```

---

## 10. Offline Strategy

### 10.1 Read Offline

```
User is offline:
└─ Drift cache has last known data (from last listener sync)
└─ UI shows data normally
└─ No error shown
└─ Optional: "Mode hors-ligne" indicator
```

### 10.2 Write Offline

```
User attempts write without internet:
└─ Repository calls Firestore → FirebaseException (unavailable)
└─ Error shown to user: "Action impossible hors-ligne"
└─ Drift NOT modified (prevents stale data)
└─ User must retry when online
```

**Rules:**
- NO offline write queue
- NO optimistic local write
- Show clear error on write failure
- Acceptable for SaaS v1 (admin solo usage)

### 10.3 Reconnection

```
Network restored:
└─ connectivity_plus detects change
└─ networkStatusProvider emits true
└─ If authenticated: FirebaseCacheService listeners reconnect automatically
└─ Drift updated with any changes made on other devices
└─ UI refreshes via stream
```

---

## 11. Testing Requirements

### 11.1 Unit Tests

**Coverage required:**
- Domain: Business logic, validators, permission resolver, SetupStatus logic
- Repositories: Firestore write calls, read from Drift, error handling
- Cache service: Listener logic, upsert/delete on Drift
- Auth: signIn, signInOffline, signOut lifecycle

**Pattern:**
```dart
test('StockRepositoryImpl.create() writes to Firestore only', () async {
  final mockFs = MockFirebaseFirestore();
  final repo = StockRepositoryImpl(db: mockDb, fs: mockFs);
  
  await repo.create(testItem);
  
  verify(mockFs.collection('stock').add(any)).called(1);
  verifyNever(mockDb.upsertStockItem(any)); // Drift NOT touched by repo
});

test('FirebaseCacheService updates Drift on Firestore snapshot', () async {
  // Simulate Firestore snapshot
  // Verify Drift upsertStockItem called
});
```

### 11.2 Widget Tests

**Coverage required:**
- Login page: Online/offline states, offline banner
- NoNetworkFirstLaunchScreen: Error message, retry button
- StockScreen: Loading, error, data states
- Retry button: Triggers provider invalidation

### 11.3 Provider Tests

```dart
test('stockProvider emits from Drift stream', () async {
  final container = ProviderContainer(
    overrides: [
      stockRepositoryProvider.overrideWith((ref) => mockRepo),
    ],
  );
  // Verify stream from Drift
});

test('setupStatusProvider returns noNetworkFirstLaunch when offline + no local admin', () async {
  final container = ProviderContainer(
    overrides: [
      isOnlineStatusProvider.overrideWith((ref) => Stream.value(false)),
      adminExistsProvider.overrideWith((ref) async => false),
    ],
  );
  expect(
    await container.read(setupStatusProvider.future),
    SetupStatus.noNetworkFirstLaunch,
  );
});
```

---

## 12. Security & Auth

### 12.1 Authentication Flow

```
First Launch (no admin):
  setupStatusProvider → needsAdminSetup → /admin-setup
  AdminSetupPage:
    1. Enter email + password
    2. FirebaseAuthRepository.createAdminUser()
       a. Firebase Auth: createUserWithEmailAndPassword()
       b. Store passwordHash in Drift (for offline login)
    3. ref.invalidate(setupStatusProvider)
    4. Router → needsLogin → /login

Login (online):
  LoginPage → signIn() → Firebase Auth → startListening() → authenticated → /

Login (offline):
  LoginPage → signIn() → FirebaseException → signInOffline()
    → Compare hash against Drift → authenticated (offline) → /
    → On reconnect → startListening() triggers

Logout:
  signOut() → stopListening() → clearSession() → needsLogin → /login
```

### 12.2 Authorization

```dart
enum Role { admin, manager, user }

class PermissionResolver {
  bool canManageUsers(UserEntity user) => user.role == Role.admin;
  bool canEditTerrain(UserEntity user) =>
      user.role == Role.admin || user.role == Role.manager;
  bool canViewStats(UserEntity user) => true;
}
```

---

## 13. Checklist for New Features

When implementing a new domain entity:

- [ ] Create domain entity (`domain/entities/[name].dart`)
  - `@immutable`, `copyWith`, `==`, `hashCode`, `toString`
  - Fields: `id` (int?), `firebaseId` (String?), `createdAt`, `updatedAt`
  - NO `syncStatus` field

- [ ] Create repository interface (`domain/repositories/[name]_repository.dart`)
  - `Stream<List<T>> watchAll()` — reads Drift
  - `Future<void> create(T item)` — writes Firestore
  - `Future<void> update(T item)` — writes Firestore
  - `Future<void> delete(String firebaseId)` — writes Firestore

- [ ] Create Drift table (`data/database/tables/[name]_table.dart`)
  - NO `syncStatus`, `pendingSync`, `lastSyncedAt` columns
  - Include `firebaseId` (TextColumn, nullable)

- [ ] Create repository impl (`data/repositories/[name]_repository_impl.dart`)
  - `watchAll()` → Drift stream
  - `create/update/delete()` → Firestore only
  - NO Drift writes (handled by FirebaseCacheService)

- [ ] Add listener in `FirebaseCacheService`
  - Add `_listen[Entity]()` method
  - Handle `added`, `modified`, `removed` change types
  - Call `startListening()` in `_subscriptions`

- [ ] Create mapper (`data/mappers/[name]_mapper.dart`)
  - `toDomain()` — Drift row → Entity
  - `toFirestore()` — Entity → Firestore map
  - `toCompanion()` — Firestore snapshot → Drift companion (for cache upsert)

- [ ] Create provider (`presentation/providers/[name]_provider.dart`)
  - `StreamProvider` for reading (Drift stream)
  - `Provider<Function>` for actions (Firestore writes)
  - `StateProvider` for filters
  - NO dependency on `firebaseSyncProvider`

- [ ] Create screen + widgets
- [ ] Update Firestore security rules
- [ ] Add route in `app_router.dart`
- [ ] Add tests (repository, cache service, provider, widget)

---

## 14. Migration from Previous Architecture

### 14.1 Components to Remove

```
REMOVE COMPLETELY:
├─ lib/data/services/firebase_sync_service.dart
├─ lib/presentation/providers/firebase_sync_provider.dart
│  └─ SyncResult class
│  └─ firebaseSyncProvider
│  └─ firebaseSyncStreamProvider
│  └─ manualSyncProvider
├─ domain/enums/sync_status.dart
├─ SyncQueue Drift table
└─ All sync columns (syncStatus, pendingSync, lastSyncedAt, lastModifiedBy)

SIMPLIFY:
├─ auth_providers.dart
│  └─ Replace ref.invalidate(firebaseSyncProvider) with cacheService.startListening()
├─ stock_provider.dart
│  └─ Remove await ref.watch(firebaseSyncProvider.future)
│  └─ Change FutureProvider → StreamProvider
└─ All data providers
   └─ Change FutureProvider → StreamProvider (Drift streams)
```

### 14.2 Incremental Migration Plan

```
PHASE A: Add FirebaseCacheService (no breaking changes)
  └─ Create firebase_cache_service.dart
  └─ Add listeners (parallel to existing sync)
  └─ Verify Drift updated via listeners

PHASE B: Simplify writes
  └─ Remove syncStatus from repository writes
  └─ Repositories write Firestore only
  └─ Remove syncAll() calls

PHASE C: Remove old sync
  └─ Delete firebase_sync_service.dart
  └─ Delete firebase_sync_provider.dart
  └─ Remove SyncStatus enum
  └─ Drift schema: remove sync columns (bump version → 15)

PHASE D: Switch providers to StreamProvider
  └─ FutureProvider → StreamProvider for all data
  └─ Remove firebaseSyncProvider dependency
  └─ flutter analyze → 0 errors

TOTAL: ~1 week
RISK: Low (incremental, parallel before remove)
```

---

## 15. Known Limitations & Future Work

### 15.1 Current Limitations (v1)

- **Offline writes:** Not supported (show error, no queue)
- **Multi-device sync:** Handled by Firestore listeners automatically
- **Conflict resolution:** Not needed (Firestore is source of truth)

### 15.2 Planned for v2

- [ ] Offline write queue (if business requires)
- [ ] Custom conflict resolution UI
- [ ] Background sync service
- [ ] Firestore pagination for large collections

---

**Last updated:** 2024 (v15 schema — Firebase as Source of Truth, Drift as cache)
**Valid for:** Flutter 3.x, Dart 3.x, Riverpod 2.4.x, Drift 2.13.x, Firebase 4.x
**Architecture version:** 2.0 (simplified from bidirectional sync)