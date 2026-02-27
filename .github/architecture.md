
# ARCHITECTURE.md

## 1. Architecture Pattern

**Pattern:** Clean Architecture + MVVM (via Riverpod) + Offline-First

**Layers:**
- **Domain:** Business logic, entities, abstract repositories
- **Data:** Database (Drift/SQLite), Cloud (Firestore), repositories implementation, mappers, sync services
- **Presentation:** UI (screens, widgets), state management (Riverpod providers), navigation (GoRouter)
- **Infrastructure:** External service adapters (image picker, share service, weather service)

**Dependency flow:** Presentation → Domain ← Data (unidirectional, no reverse dependencies)

---

## 2. Layer Organization

### 2.1 Domain Layer (domain)

**Responsibility:** Pure business logic, NO framework dependencies

**Composition:**
```
domain/
├── entities/          # @immutable data classes (StockItem, User, Terrain, etc)
├── repositories/      # Abstract interfaces (StockRepository, AuthRepository, etc)
├── enums/            # Role, Permission, FeatureFlag, SyncStatus
├── logic/            # Business services (PermissionResolver, StockCategorizer)
├── models/           # Domain-specific models (QueueStatus, QueueError, QueueProgress, SetupStatus)
└── services/         # Domain services (WeatherRules)
```

**Rules:**
- Entities: `@immutable`, `copyWith()`, `==`, `hashCode`, `toString()`
- Repositories: Abstract classes only (NO implementation)
- No imports of: Drift, Firestore, Flutter, Riverpod
- All entities MUST have: `id`, `remoteId` (String?, for Firestore mapping), `createdAt`, `updatedAt`, `syncStatus` fields

**Key entities with sync support:**
```dart
@immutable
class StockItem {
  final int? id;                          // Local DB ID (auto-increment)
  final String? remoteId;                 // Firestore doc ID (nullable until synced)
  final String name;
  final int quantity;
  final SyncStatus syncStatus;            // local | syncing | synced | error
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastModifiedBy;           // For conflict resolution
  
  StockItem copyWith({...}) { }
  @override bool operator ==(Object other) { }
  @override int get hashCode { }
}
```

**Enums:**
```dart
enum SyncStatus { local, syncing, synced, error }
enum SetupStatus { loading, needsAdminSetup, needsLogin, authenticated, error }
```

---

### 2.2 Data Layer (data)

**Responsibility:** Data persistence, cloud sync, data transformation

**Composition:**
```
data/
├── database/              # Drift/SQLite (local source of truth)
│   ├── app_database.dart  # @DriftDatabase with all tables (v14)
│   ├── tables/            # Table definitions (UsersTable, StockItemsTable, etc)
│   │   └── [name]_table.dart
│   └── queries/           # Custom queries, extensions, watch methods
│
├── firestore/             # Cloud schema models
│   └── models/            # FirebaseStockModel, FirebaseTerrainModel, etc
│
├── repositories/          # Repository implementations
│   ├── [entity]_repository_impl.dart
│   └── firestore/         # Firestore-specific repos (optional)
│
├── services/              # Firebase services (sync, batch ops, auth)
│   ├── firebase_sync_service.dart      # NEW: Handles Drift ↔ Firestore sync
│   ├── firebase_[entity]_service.dart
│   └── firebase_auth_service.dart
│
└── mappers/              # Entity ↔ Model ↔ DTO conversions
    ├── [entity]_mapper.dart
    └── Extensions with toCompanion() for Drift operations
```

**Rules:**
- Repositories: Implement domain interfaces, never export them directly
- Drift: Single instance (singleton via databaseProvider in Presentation layer)
- Mappers: Convert domain entities ↔ local models ↔ Firestore models
  - Include `toCompanion()` extension for Drift INSERT/UPDATE
  - Map `remoteId` ↔ Firestore docId
- Services: Handle Firebase operations (sync, batch writes, auth)
- Sync: Unidirectional (Drift → Firestore), with upsert on conflict
- NO UI imports (Flutter, Riverpod)

**FirebaseSyncService pattern:**
```dart
class FirebaseSyncService {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;
  
  // Per-entity sync status (BehaviorSubject)
  final _syncStatus = BehaviorSubject<Map<String, SyncStatus>>();
  
  Future<void> syncAll() async {
    await Future.wait([
      syncUsers(),           // NEW: Admin user creation, password sync
      syncTerrains(),
      syncMaintenances(),
      syncStock(),
      syncEvents(),
    ]);
  }
  
  // Each entity method:
  // 1. Get pending local changes
  // 2. Upsert to Firestore (with onConflict: DoUpdate)
  // 3. Update local syncStatus
  // 4. Emit status change
}
```

**Example repository:**
```dart
class StockRepositoryImpl implements StockRepository {
  final AppDatabase _db;
  final FirebaseSyncService _syncService;

  @override
  Future<List<StockItem>> getAllStockItems() async {
    return _db.watchAllStockItems().first;  // Always read from local DB
  }
  
  @override
  Future<void> addStockItem(StockItem item) async {
    // 1. Insert to Drift (optimistic)
    await _db.into(_db.stockItems).insert(item.toCompanion());
    
    // 2. Trigger sync (async, no await)
    _syncService.syncStock();
  }
}
```

---

### 2.3 Presentation Layer (presentation)

**Responsibility:** UI, state management, navigation, routing logic

**Composition:**
```
presentation/
├── providers/           # Riverpod state management
│   ├── core_providers.dart              # databaseProvider, repositoryProviders
│   ├── auth_providers.dart              # authStateProvider, currentUserProvider
│   ├── setup_status_provider.dart       # NEW: setupStatusProvider (combines auth + adminExists)
│   ├── [domain]_provider.dart           # stockProvider, terrainProvider, etc
│   ├── [domain]_fusion_provider.dart    # NEW: Merged local + remote data
│   ├── database_provider.dart           # Singleton Drift instance
│   ├── sync_status_provider.dart        # syncStatusProvider (watch sync progress)
│   └── [domain]_provider.dart
│
├── pages/              # Top-level pages (full-screen, root routes)
│   ├── auth/
│   │   ├── login_page.dart
│   │   └── admin_setup_page.dart        # NEW: First-launch admin creation
│   ├── admin/
│   │   └── admin_dashboard_page.dart
│   └── error/
│       └── access_denied_page.dart
│
├── screens/            # Secondary screens (nested routes)
│   ├── maintenance_screen.dart
│   ├── stats_screen.dart
│   └── ...
│
├── widgets/           # Reusable UI components
│   ├── sync_status_indicator.dart
│   ├── queue_status_widget.dart        # NEW: Shows queue progress + retry UI
│   ├── access_control/
│   │   ├── permission_visibility.dart
│   │   ├── role_visibility.dart
│   │   └── feature_flag_visibility.dart
│   └── [domain]/
│       └── [component]_widget.dart
│
└── utils/            # Helpers (formatters, validators)
    └── date_utils.dart
```

**Rules:**
- Providers: Use Riverpod only (no GetX, BLoC, Provider package)
- Pages vs Screens: Pages are root routes, Screens are nested
- Widgets: NO business logic, pure presentation
- Access control: Use `PermissionVisibility`, `RoleVisibility` wrappers
- Error handling: AsyncValue.when() for loading/error/data states
- NEW: setupStatusProvider gates all routing (setup → login → home flow)

---

### 2.4 Features Layer (features)

**Responsibility:** Feature-specific screens, widgets, models

**Composition:**
```
features/
├── [feature]/
│   ├── presentation/
│   │   ├── screens/
│   │   │   └── [feature]_screen.dart
│   │   └── widgets/
│   │       └── [feature]_widget.dart
│   │
│   ├── models/
│   │   └── [feature]_filter.dart
│   │
│   └── infrastructure/  # (optional) Feature-specific services
│       └── [feature]_service.dart
```

**Examples:**
- `features/inventory/` - Stock screens, widgets
- `features/home/` - Dashboard screens, widgets
- `features/weather/` - Weather screens, widgets

**Rules:**
- Feature code is self-contained (imports from presentation/, domain/, data/)
- Feature models are NOT domain entities (e.g., StockFilter, TerrainType)
- Providers are in `presentation/providers/`, not in features/
- Feature-specific providers follow naming: `[feature]Provider`, `[feature]ItemProvider`, etc

---

### 2.5 Core Layer (core)

**Responsibility:** Shared infrastructure, configuration, routing, security

**Composition:**
```
core/
├── config/
│   ├── app_config.dart       # API keys, URLs, constants
│   └── queue_config.dart     # Sync/queue settings (retry count, backoff)
│
├── router/
│   ├── app_router.dart       # GoRouter setup + redirect logic (NEW: setupStatusProvider gate)
│   └── go_router_refresh_stream.dart
│
├── security/
│   ├── auth_validator.dart
│   ├── rate_limiter.dart
│   ├── token_service.dart
│   └── auth_exceptions.dart
│
└── theme/
    └── app_theme.dart
```

**Rules:**
- NO domain/data imports in core (unidirectional)
- Exceptions: Define custom exceptions here
- Theme: Material theme only (no dark theme variants in config)
- Router: NEW gateway pattern (setupStatusProvider redirects)

---

## 3. Dependency Rules

### 3.1 Import Rules (Strict)

**Domain** (most restricted):
```dart
❌ NEVER: import 'package:flutter/';
❌ NEVER: import 'package:flutter_riverpod/';
❌ NEVER: import 'package:drift/';
❌ NEVER: import 'package:cloud_firestore/';
✅ ONLY: import 'domain/';
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

### 3.2 Provider Dependency Chain

```
setupStatusProvider (FutureProvider<SetupStatus>)
  ├─ adminExistsProvider (FutureProvider<bool>)
  │   ↓ queries Drift users table
  └─ authStateProvider (StateNotifierProvider)
      ↓ watches Firebase Auth state
      ↓ depends on
authRepositoryProvider (Provider<AuthRepository>)
  ↓ depends on
databaseProvider (Provider - singleton)
  ↓ depends on
AppDatabase (Drift)
```

**Rule:** Providers must declare dependencies via `ref.watch()` (not direct instantiation)

---

## 4. Riverpod Provider Rules

### 4.1 Provider Types

| Type | Use case | Lifespan | New Pattern |
|------|----------|----------|-------------|
| `Provider<T>` | Synchronous, immutable | App lifetime | Service singletons |
| `FutureProvider<T>` | Async, single-shot (no state) | Until invalidated | Data providers |
| `StateProvider<T>` | Mutable UI state (filter, search) | Until invalidated | UI state only |
| `StateNotifierProvider<N, T>` | Complex state + mutations | App lifetime | Auth state, forms |
| `StreamProvider<T>` | Real-time data | Until invalidated | (DEPRECATED, use FutureProvider) |
| `FusionProvider` | Merged local + remote | Until invalidated | NEW: Offline-first pattern |

**Rules:**
- Default: `FutureProvider` for async data
- Use `StateNotifierProvider` only for: Auth state, Cart/form state
- NEVER: `Provider` for async operations (use `FutureProvider`)
- NEVER: Mix `StreamProvider` and `FutureProvider` for same data
- NEW: Use `FusionProvider` pattern for offline-first (merge Drift + Firestore)

---

### 4.2 Provider Naming Convention

```dart
// Data providers (Drift local)
final stockProvider = FutureProvider<List<StockItem>>(...);
final terrainProvider = FutureProvider<List<Terrain>>(...);

// Fusion providers (merged local + remote) - NEW
final stockFusionProvider = FutureProvider<List<StockItem>>(...); // Merges local + Firestore

// Filtered/computed providers
final filteredStockItemsProvider = FutureProvider<List<StockItem>>(...);
final lowStockItemsProvider = FutureProvider.autoDispose<List<StockItem>>(...);

// State providers (mutable)
final stockFilterProvider = StateProvider<StockFilter>(...);
final stockSearchQueryProvider = StateProvider<String>(...);

// Action providers (functions that mutate + sync)
final addStockItemProvider = Provider<Future<void> Function(StockItem)>(...);
final updateStockItemProvider = Provider<Future<void> Function(StockItem)>(...);

// Notifier providers (complex state)
final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthState>>(...);
final setupStatusProvider = FutureProvider<SetupStatus>(...);  // NEW: Setup flow gate

// Singleton services
final databaseProvider = Provider<AppDatabase>(...);
final firebaseSyncServiceProvider = Provider<FirebaseSyncService>(...);

// Derived providers
final isAuthenticatedProvider = Provider<bool>(...);
final currentUserProvider = Provider<UserEntity?>(...);

// Sync status
final syncStatusProvider = StreamProvider<Map<String, SyncStatus>>(...);  // NEW: Per-entity sync
```

**Rules:**
- Plural: `stockProvider` (returns List)
- Singular: `currentUserProvider` (returns single entity)
- Suffix: `_notifier` for StateNotifierProvider
- Suffix: `_service` for service singletons
- Suffix: `_filter`, `_search`, `_query` for state providers
- Suffix: `_fusion` for merged local + remote data (NEW)
- Suffix: `_status` for sync/state status (NEW)

---

### 4.3 Provider Scope

**Global scope (app lifetime):**
```dart
final databaseProvider = Provider<AppDatabase>(...);
final authRepositoryProvider = Provider<AuthRepository>(...);
final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthState>>(...);
final setupStatusProvider = FutureProvider<SetupStatus>(...);  // NEW: Not auto-dispose
```

**Auto-dispose (memory efficient):**
```dart
final lowStockItemsProvider = FutureProvider.autoDispose<List<StockItem>>(...);
final filteredStockItemsProvider = FutureProvider<List<StockItem>>(...); // NO autoDispose if watched continuously
```

**Rules:**
- Singleton services: NO autoDispose
- Data lists: NO autoDispose (watched by UI continuously)
- Derived/filtered data: autoDispose if created on-demand
- Rarely-watched providers: autoDispose
- Setup/auth: NO autoDispose (critical app state)

---

### 4.4 Provider Invalidation

**When to invalidate:**
```dart
// After mutation success
ref.invalidate(stockProvider);              // Refresh list
ref.invalidate(filteredStockItemsProvider); // Refresh filtered view

// Cascade invalidation
ref.invalidate(lowStockItemsProvider);      // Auto-refreshes if dependent

// NEW: After setup completion
ref.invalidate(setupStatusProvider);        // Trigger re-check (admin created → login needed)

// Exception: Never invalidate state providers
// ❌ ref.invalidate(stockFilterProvider);  // NO - breaks UI state
```

**Rules:**
- Invalidate parent providers after mutations
- Dependent providers auto-invalidate
- NEVER invalidate StateProviders manually (use .state = instead)
- Always invalidate in try/catch, not just on success
- NEW: Invalidate setupStatusProvider after admin creation

---

### 4.5 Error Handling in Providers

**Pattern:**
```dart
final stockProvider = FutureProvider<List<StockItem>>((ref) async {
  try {
    final repo = ref.watch(stockRepositoryProvider);
    return await repo.getAllStockItems();
  } catch (e, st) {
    // Error propagates to AsyncValue.error
    debugPrint('❌ Error loading stock: $e');
    rethrow; // Caller handles via AsyncValue.when()
  }
});
```

**Rules:**
- Catch at repository level (emit domain exceptions)
- Catch at provider level (log, rethrow)
- Handle AsyncValue.error in UI widgets
- NEVER swallow exceptions silently

---

## 5. Error Management

### 5.1 Exception Hierarchy

```
Exception (base)
├── AuthException (auth_exceptions.dart)
│   ├── InvalidCredentialsException
│   ├── UserAlreadyExistsException
│   └── SessionExpiredException
│
├── SecurityException (security_exceptions.dart)
│   ├── PermissionDeniedException
│   ├── RateLimitException
│   └── TokenExpiredException
│
├── SyncException (NEW - data layer)
│   ├── OfflineException
│   ├── ConflictException
│   └── SyncTimeoutException
│
└── Domain-specific exceptions (per domain)
    └── (defined in domain/repositories/)
```

**Rules:**
- Custom exceptions: Extend Exception or specific Exception subclass
- Exceptions in: `lib/core/security/exceptions.dart`
- Never throw generic `Exception('message')`
- Include context in exception message (user action, affected resource)

---

### 5.2 Error Handling Pattern

**Repository level (Data layer):**
```dart
Future<List<StockItem>> getAllStockItems() async {
  try {
    return await _db.watchAllStockItems().first;
  } on DriftException catch (e) {
    throw DatabaseException('Failed to load stock items: ${e.message}');
  } catch (e) {
    throw UnknownException('Unexpected error: $e');
  }
}
```

**Provider level (Presentation layer):**
```dart
final stockProvider = FutureProvider<List<StockItem>>((ref) async {
  try {
    final repo = ref.watch(stockRepositoryProvider);
    return await repo.getAllStockItems();
  } catch (e) {
    debugPrint('❌ Error: $e');
    rethrow; // AsyncValue.error handles it
  }
});
```

**UI level (Widget):**
```dart
ref.watch(stockProvider).when(
  data: (items) => StockList(items),
  loading: () => LoadingIndicator(),
  error: (error, st) => ErrorWidget(error: error),
);
```

**Rules:**
- Repository: Catch framework exceptions, throw domain exceptions
- Provider: Log, rethrow (no transformation)
- UI: Use AsyncValue.when() for error display
- NEVER use try/catch in UI widgets

---

## 6. State Management

### 6.1 Loading States

**Pattern (AsyncValue):**
```dart
AsyncValue<List<StockItem>>.when(
  data: (items) { /* render data */ },
  loading: () { /* show spinner */ },
  error: (error, st) { /* show error */ },
);
```

**Rules:**
- ALWAYS use AsyncValue for async operations (no bool isLoading)
- loading: Show spinner, disable interactions
- error: Show error message, allow retry
- data: Show content, enable interactions

**Example widget:**
```dart
class StockListView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockAsync = ref.watch(stockProvider);
    
    return stockAsync.when(
      data: (items) => ListView(children: items.map(StockTile.new).toList()),
      loading: () => CircularProgressIndicator(),
      error: (error, st) => ErrorBanner(error: error.toString()),
    );
  }
}
```

---

### 6.2 Empty States

**Pattern:**
```dart
final stockProvider = FutureProvider<List<StockItem>>((ref) async {
  final items = await repo.getAllStockItems();
  // Provider returns empty list, UI handles empty state
  return items;
});

// In UI:
stockAsync.when(
  data: (items) => items.isEmpty 
    ? EmptyStateWidget() 
    : StockList(items),
  loading: () => LoadingIndicator(),
  error: (e, st) => ErrorWidget(e),
);
```

**Rules:**
- Empty state: Handled in UI (check list.isEmpty)
- Provider: Returns empty list (not null, not error)
- Message: "No items found. Create one to get started."

---

### 6.3 Mutable State

**Pattern (StateProvider):**
```dart
// Define state
final stockFilterProvider = StateProvider<StockFilter>((ref) => StockFilter.all);
final stockSearchQueryProvider = StateProvider<String>((ref) => '');

// Update state in widget
ref.read(stockFilterProvider.notifier).state = StockFilter.lowStock;

// Listen for changes
ref.listen(stockFilterProvider, (prev, next) {
  debugPrint('Filter changed: $prev -> $next');
});

// Use in computed provider
final filteredStockProvider = FutureProvider<List<StockItem>>((ref) async {
  final filter = ref.watch(stockFilterProvider);
  final search = ref.watch(stockSearchQueryProvider);
  // Apply filtering
});
```

**Rules:**
- Simple UI state: StateProvider
- Complex state: StateNotifierProvider
- NEVER use StateProvider for data (use FutureProvider)
- NEVER use StateNotifier for simple toggles (use StateProvider)

---

## 7. Navigation

### 7.1 Router Setup

**File:** `app_router.dart`

**Pattern:**
```dart
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      ref.read(setupStatusProvider.notifier).stream  // NEW: Watch setup status
    ),
    redirect: (context, state) {
      final setupStatus = ref.read(setupStatusProvider).value;
      
      // NEW: Setup gate - priority 1
      if (setupStatus == SetupStatus.needsAdminSetup) {
        return state.uri.path == '/admin-setup' ? null : '/admin-setup';
      }
      
      // Priority 2: Login required
      if (setupStatus == SetupStatus.needsLogin) {
        return state.uri.path == '/login' ? null : '/login';
      }
      
      // Priority 3: Authenticated - prevent re-login
      if (setupStatus == SetupStatus.authenticated) {
        if (state.uri.path == '/login' || state.uri.path == '/admin-setup') {
          return '/';
        }
      }
      
      return null;
    },
    routes: [
      GoRoute(path: '/admin-setup', builder: ...),  // NEW: Admin creation
      GoRoute(path: '/login', builder: ...),
      GoRoute(path: '/', builder: ..., routes: [
        GoRoute(path: 'stock', builder: ...),
      ]),
    ],
  );
});
```

**Rules:**
- Single GoRouter instance (via provider)
- Redirect logic: Check setup status → auth → role → data availability
- refreshListenable: Watch setupStatusProvider (NEW: instead of just authState)
- Routes: Declarative, hierarchical

---

### 7.2 Setup Flow Routing (NEW)

**Priority order:**
1. **Setup Required** → `/admin-setup` (no admin in DB)
2. **Login Required** → `/login` (admin exists, user not logged in)
3. **Authenticated** → `/` (home)

**Flow:**
```
App Start (no data)
  ↓
setupStatusProvider checks:
  ├─ adminExistsProvider (query Drift users table for any admin)
  └─ authStateProvider (Firebase Auth state)
  ↓
SetupStatus emitted:
  ├─ needsAdminSetup   → Redirect to /admin-setup
  ├─ needsLogin        → Redirect to /login
  ├─ authenticated     → Stay at / or destination
  └─ error             → Show error page
  ↓
AdminSetupPage:
  1. User enters email + password + confirm password
  2. On submit: FirebaseAuthRepository.createAdminUser()
     a. Firebase Auth: createUserWithEmailAndPassword()
     b. Drift: INSERT user (role: 'admin')
  3. ref.invalidate(setupStatusProvider) → Re-check
  4. Router detects adminExists → Redirects to /login
  ↓
LoginPage:
  1. User enters credentials
  2. On submit: FirebaseAuthRepository.signIn()
  3. Router detects authenticated → Redirects to /
```

---

### 7.3 Route Hierarchy

```dart
GoRoute(
  path: '/',
  builder: (context, state) => HomeScreen(),
  routes: [
    GoRoute(
      path: 'stock',
      builder: (context, state) => StockScreen(),
    ),
    GoRoute(
      path: 'terrain/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return TerrainDetailScreen(id: id);
      },
    ),
  ],
);
```

**Rules:**
- Root routes: `/`, `/login`, `/admin-setup`, `/admin`
- Nested routes: `path: 'stock'` (not `/stock`)
- Parameters: `:id` in path, access via `state.pathParameters['id']`
- Query params: `state.uri.queryParameters['key']`

---

### 7.4 Role-Based Access

**Pattern:**
```dart
GoRoute(
  path: '/admin',
  builder: (context, state) => AdminDashboard(),
  redirect: (context, state) {
    final user = ref.read(currentUserProvider);
    if (user?.role != Role.admin) {
      return '/access-denied';
    }
    return null;
  },
);
```

**Rules:**
- Access checks: In route redirect callback
- Denied: Redirect to `/access-denied`
- Permissions: Check via `PermissionResolver` (domain service)
- UI enforcement: ALSO use `PermissionVisibility`, `RoleVisibility` widgets

---

## 8. Folder Organization

### 8.1 Directory Structure

```
lib/
├── core/
│   ├── config/           # Constants, app config
│   ├── router/           # Navigation (NEW: setupStatusProvider gate)
│   ├── security/         # Auth, exceptions
│   └── theme/            # UI theme
│
├── domain/
│   ├── entities/         # Data models (@immutable)
│   ├── repositories/     # Abstract interfaces
│   ├── enums/           # Role, Permission, SyncStatus, SetupStatus
│   ├── logic/           # Domain services
│   └── models/          # Domain-specific models (QueueStatus, SetupStatus)
│
├── data/
│   ├── database/        # Drift/SQLite (v14)
│   │   └── tables/
│   ├── firestore/       # Cloud models
│   │   └── models/
│   ├── repositories/    # Implementations
│   ├── mappers/         # Entity converters (with toCompanion())
│   └── services/        # Firebase services (NEW: firebase_sync_service.dart)
│
├── features/
│   ├── [feature]/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   ├── models/      # Feature-specific models
│   │   └── infrastructure/
│   └── [feature]/...
│
├── presentation/
│   ├── providers/       # Riverpod state (NEW: setup_status_provider.dart)
│   ├── pages/          # Full-screen pages (NEW: admin_setup_page.dart)
│   ├── screens/        # Nested screens
│   ├── widgets/        # Reusable components (NEW: queue_status_widget.dart)
│   └── utils/          # Helpers
│
├── services/
│   ├── queue/          # Queue management (NEW: exponential backoff, deduplication)
│   └── sync/           # Sync orchestration
│
├── infrastructure/     # External adapters
│   └── services/
│
└── main.dart          # Entry point
```

### 8.2 File Naming

| Category | Pattern | Example |
|----------|---------|---------|
| Entity | `[name].dart` | `stock_item.dart` |
| Repository (interface) | `[name]_repository.dart` | `stock_repository.dart` |
| Repository (impl) | `[name]_repository_impl.dart` | `stock_repository_impl.dart` |
| Provider | `[name]_provider.dart` | `stock_provider.dart` |
| Setup Provider (NEW) | `setup_status_provider.dart` | `setup_status_provider.dart` |
| Sync Service (NEW) | `firebase_sync_service.dart` | `firebase_sync_service.dart` |
| Screen | `[name]_screen.dart` | `stock_screen.dart` |
| Widget | `[name]_widget.dart` | `stock_item_tile.dart` |
| Page | `[name]_page.dart` | `admin_setup_page.dart` |
| Service | `[name]_service.dart` | `firebase_sync_service.dart` |
| Mapper | `[name]_mapper.dart` | `stock_item_mapper.dart` |
| Model | `[name]_model.dart` | `stock_item_model.dart` |
| Table | `[name]_table.dart` | `stock_items_table.dart` |

**Rules:**
- snake_case for filenames
- Pattern: `[entity]_[type].dart`
- NO generic names (`utils.dart`, `helpers.dart` - be specific)

---

## 9. Linting & Code Quality

### 9.1 Lint Rules (analysis_options.yaml)

**Enforced rules:**
```yaml
linter:
  rules:
    - always_declare_return_types: true
    - avoid_print: true
    - prefer_single_quotes: true
    - prefer_final_locals: true
    - prefer_const_constructors: true
    - prefer_const_constructors_in_immutables: true
    - sort_child_properties_last: true
    - use_key_in_widget_constructors: true
    - sized_box_for_whitespace: true
```

**Rules:**
- NO `print()` (use `debugPrint()`)
- Single quotes for strings (except multiline)
- ALL return types declared
- const constructors preferred
- final locals required

### 9.2 Generated Code

**Excluded from linting:**
```yaml
analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
```

**Rules:**
- Generated code: Never modify
- Regenerate after entity changes: `flutter pub run build_runner build`
- CI: Verify generated code is committed

---

## 10. Sync & Offline Strategy

### 10.1 Drift as Source of Truth

**Rule:** Drift (local SQLite) is primary source of truth, Firestore is backup/sync target

**Write Flow:**
1. User mutation → Write to Drift immediately (optimistic)
2. Drift transaction commits
3. Entity syncStatus: `local`
4. FirebaseSyncService triggered (async, no await)
5. If network available → Push to Firestore
6. Firestore write success → Update entity syncStatus: `synced`
7. If network down → Entity stays syncStatus: `local`
8. On network restore → Auto-retry with exponential backoff

**Read Flow:**
1. Always read from Drift (local DB)
2. Get latest data (up-to-date, even offline)
3. Display syncStatus indicator for unsync data
4. Optional: Show "syncing..." for pending operations

**Rules:**
- Writes: Always to Drift first (optimistic update, no await for Firestore)
- Reads: Always from Drift (source of truth)
- Sync: Drift → Firestore (one-directional, for now)
- No pull from Firestore yet (planned for multi-device sync)
- Upsert: Use `onConflict: DoUpdate` to prevent UNIQUE errors

---

### 10.2 FirebaseSyncService (NEW)

**Architecture:**
```dart
class FirebaseSyncService {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;
  
  // Stream per-entity sync status
  final _syncStatus = BehaviorSubject<Map<String, SyncStatus>>();
  
  // Main sync entry point
  Future<void> syncAll() async {
    // Sync in parallel
    await Future.wait([
      syncUsers(),           // NEW: Admin user sync
      syncTerrains(),
      syncMaintenances(),
      syncStock(),
      syncEvents(),
    ]);
  }
  
  // Per-entity method pattern:
  Future<void> syncStock() async {
    _updateStatus('stock', SyncStatus.syncing);
    try {
      // 1. Get local items with syncStatus != synced
      final pendingItems = await _db.getUnsyncedStockItems();
      
      // 2. Upsert to Firestore
      final batch = _firestore.batch();
      for (final item in pendingItems) {
        final docRef = item.remoteId != null
          ? _firestore.collection('stock').doc(item.remoteId)
          : _firestore.collection('stock').doc();  // Auto-ID if new
        
        batch.set(
          docRef,
          item.toFirebaseModel().toJson(),
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      
      // 3. Update local syncStatus
      for (final item in pendingItems) {
        await _db.update(item.copyWith(syncStatus: SyncStatus.synced));
      }
      
      _updateStatus('stock', SyncStatus.synced);
    } catch (e, st) {
      debugPrint('❌ FirebaseSyncService: Sync Error: $e\n$st');
      _updateStatus('stock', SyncStatus.error);
      rethrow;
    }
  }
}
```

**Triggers:**
- Automatic: Timer (every 5 minutes)
- Network change: Connectivity+ plugin
- Manual: User taps "Sync now" button

---

### 10.3 Offline Behavior

**Offline scenario (no network):**
- Writes: Queued in Drift with syncStatus: `local`
- Reads: Served from Drift (no lag)
- Sync: Waits for network restore
- UI: Shows "Offline" indicator (QueueStatusBanner)
- User experience: Seamless (no errors shown)

**On network restore:**
- Auto-detect: Connectivity+ plugin
- Trigger sync: FirebaseSyncService.syncAll()
- Retry logic: Exponential backoff (1s, 2s, 4s, 8s... max 30s)
- Max retries: 3 per batch
- On success: Update syncStatus, notify UI
- On failure: Mark as error, show retry button

**Queue Management:**
- Max items: 1000 (alert user if exceeded)
- Deduplication: Skip if same operation pending
- Ordering: FIFO per entity type
- Cleanup: Remove on success, mark as error on failure

**Rules:**
- No error shown to user for sync failures (seamless)
- SyncQueue status visible in QueueStatusBanner
- Max queue size: 1000 items
- User alerted if exceeded

---

### 10.4 Conflict Resolution

**Scenario:**
```
Local:   Terrain(id=1, name="Court A", updatedAt=2024-01-01T10:00)
Remote:  Terrain(id=1, name="Court B", updatedAt=2024-01-01T11:00)
```

**Strategy: LAST-WRITE-WINS**
- Compare `updatedAt` timestamps
- Remote wins if newer (11:00 > 10:00)
- Local data overwritten

**Implementation (in mapper):**
```dart
Terrain _mergeTerrainData(Terrain remote, Terrain? local) {
  if (local == null) return remote;
  
  if (remote.updatedAt.isAfter(local.updatedAt)) {
    return remote;  // Remote wins
  }
  return local;     // Local wins
}
```

**Upsert with conflict resolution:**
```dart
await _db.into(_db.terrains).insert(
  terrain.toCompanion(includeId: true),
  onConflict: drift.DoUpdate(
    (old) {
      // Merge logic: keep local if newer
      return old.updatedAt.isAfter(terrain.updatedAt)
        ? const Partial()  // Keep old (local)
        : TerrainsCompanion(
            name: Value(terrain.name),
            syncStatus: Value(SyncStatus.synced.name),
            updatedAt: Value(DateTime.now()),
          );
    },
  ),
);
```

**Rules:**
- Strategy: LAST-WRITE-WINS (timestamp-based)
- Manual resolution: Not implemented yet (future)
- Test conflicts: Unit tests required

---

## 11. Testing Requirements

### 11.1 Unit Tests

**Where:** 

test

 directory (mirror lib structure)

**Coverage required:**
- Domain: Business logic, validators, permission resolver, SetupStatus logic
- Repositories: Drift queries, Firestore conversions, error handling
- Providers: State transitions, invalidation, setup status flow
- Sync service: Upsert logic, conflict resolution, retry logic

**Pattern:**
```dart
test('StockItem.isLowOnStock returns true when quantity <= minThreshold', () {
  final item = StockItem(quantity: 5, minThreshold: 10, ...);
  expect(item.isLowOnStock, isTrue);
});

test('SetupStatus is needsAdminSetup when no admin exists', () async {
  // Mock adminExistsProvider to return false
  final result = await ref.read(setupStatusProvider.future);
  expect(result, SetupStatus.needsAdminSetup);
});

test('FirebaseSyncService upserts stock with onConflict', () async {
  // Mock Firestore, Drift
  await syncService.syncStock();
  // Verify batch.set called with SetOptions(merge: true)
});
```

**Rules:**
- Test: Domain logic, repository contracts, provider logic, sync logic
- Mock: Drift (use in-memory), Firestore (mock service)
- Assert: Single assertion per test (when possible)

### 11.2 Widget Tests

**Where:** 

test

 directory

**Coverage required:**
- Critical screens: AdminSetupPage, LoginPage, AdminDashboard, StockScreen
- Error states: AsyncValue.error handling
- Permissions: Access control widgets
- Setup flow: Router redirects

**Pattern:**
```dart
testWidgets('AdminSetupPage shows confirm password field', (tester) async {
  await tester.pumpWidget(
    ProviderScope(child: AdminSetupPage()),
  );
  expect(find.byType(PremiumTextField), findsWidgets);
  expect(find.byKey(Key('confirmPasswordField')), findsOneWidget);
});

testWidgets('LoginPage redirects to home on success', (tester) async {
  // Override authStateProvider
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWithValue(
          AsyncValue.data(AuthState(user: testUser, isSetupRequired: false))
        ),
      ],
      child: MyApp(),
    ),
  );
  // Verify router navigates to /
});
```

---

### 11.3 Integration Tests

**Where:** 

integration_test

 directory

**Coverage required:**
- Full app flow: Splash → AdminSetup → Login → Home
- Sync flow: Offline → Online → Sync
- Error recovery: Network timeout → Retry

---

## 12. Database Transactions & Migrations

### 12.1 Schema Versioning

**Current version:** v14

**Recent changes (v13→v14):**
- Added `remoteId` (String?) to all entity tables (for Firestore sync)
- Added `syncStatus` (String, enum: local|syncing|synced|error) to all entity tables
- Added `lastModifiedBy` (String?) for conflict resolution

**Migration path:**
```dart
// In app_database.dart
@DriftDatabase(
  version: 14,
  tables: [
    UsersTable,
    TerrainsTable,
    MaintenancesTable,
    StockItemsTable,
    EventsTable,
    ReservationsTable,
    StockMovementsTable,
    AuditLogsTable,
    LoginAttemptsTable,
    OtpRecordsTable,
    SyncQueueTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  @override
  int get schemaVersion => 14;
  
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 14) {
        // Add remoteId, syncStatus, lastModifiedBy columns
        await m.addColumn(terrains, terrains.remoteId);
        await m.addColumn(terrains, terrains.syncStatus);
        await m.addColumn(terrains, terrains.lastModifiedBy);
        // ... repeat for all tables
      }
    },
  );
}
```

**Rules:**
- Version incremented on schema change
- Migrations auto-applied on app launch
- Backwards compatible (nullable columns for new fields)

### 12.2 Sync Queue Transactions

**Pattern (batch max 500 ops):**
```dart
Future<void> syncWithBatching() async {
  const batchSize = 500;
  final allOps = await _db.getAllPendingSyncOps();
  
  for (int i = 0; i < allOps.length; i += batchSize) {
    final batch = _firestore.batch();
    final ops = allOps.sublist(i, min(i + batchSize, allOps.length));
    
    for (final op in ops) {
      // batch.set(...) or batch.update(...)
    }
    
    await batch.commit();
    
    // Update status after successful commit
    for (final op in ops) {
      await _db.updateSyncStatus(op.id, SyncStatus.synced);
    }
  }
}
```

**Rules:**
- Transactions: Max 500 operations per batch
- Atomicity: All-or-nothing per batch
- Status tracking: Update SyncQueue after successful commit
- Retry: Failed batches marked as error, retried on next sync

---

## 13. Security & Auth

### 13.1 Authentication Flow (NEW: Firebase + Admin Setup)

**Flow:**
```
First Launch (no admin):
  ↓
setupStatusProvider → adminExistsProvider queries Drift
  → No admin found
  → SetupStatus: needsAdminSetup
  → Router redirect to /admin-setup
  ↓
AdminSetupPage:
  1. User enters: email, password, confirm password
  2. Validation: passwords match, email valid
  3. Submit:
     a. FirebaseAuthRepository.createAdminUser(email, password)
     b. Firebase Auth: createUserWithEmailAndPassword()
     c. Drift: INSERT user with role='admin'
     d. Return UserEntity
  4. Success: ref.invalidate(setupStatusProvider)
  5. Router detects: adminExists=true → SetupStatus: needsLogin
  6. Auto-redirect to /login
  ↓
LoginPage:
  1. User enters: email, password
  2. Submit: FirebaseAuthRepository.signIn(email, password)
  3. Firebase Auth: signInWithEmailAndPassword()
  4. authStateProvider emits: user != null
  5. setupStatusProvider: authenticated
  6. Router redirect to /home
```

**Auth Architecture:**
- Firebase Auth: Primary auth (email/password)
- Drift users table: Local profile + role
- JWT tokens: Stored in SecureStorage (for offline validation)
- Rate limiting: LoginAttempts table + RateLimiter service

**Rules:**
- Admin creation: Only on first launch (no admin in DB)
- Email: Unique (enforced by Firebase Auth)
- Password: Min 8 chars, validated before submit
- Session: Firebase token, refreshed on app resume
- Logout: Clears Drift user, revokes Firebase token

---

### 13.2 Authorization & Permissions

**Role-based access control:**
```dart
enum Role { admin, manager, user }

// Permission resolver
class PermissionResolver {
  bool canManageUsers(UserEntity user) => user.role == Role.admin;
  bool canEditTerrain(UserEntity user) => user.role == Role.admin || user.role == Role.manager;
  bool canViewStats(UserEntity user) => true;  // All roles
}

// Usage in router
GoRoute(
  path: '/admin',
  redirect: (context, state) {
    final user = ref.read(currentUserProvider);
    if (!PermissionResolver().canManageUsers(user)) {
      return '/access-denied';
    }
    return null;
  },
);

// Usage in UI
PermissionVisibility(
  permission: Permission.manageUsers,
  child: AdminButton(),
);
```

---

## 14. Checklist for New Features

When implementing new domain entity:

- [ ] Create domain entity (`domain/entities/[name].dart`)
  - @immutable, copyWith, ==, hashCode, toString
  - id, remoteId, syncStatus, createdAt, updatedAt fields
  
- [ ] Create repository interface (`domain/repositories/[name]_repository.dart`)
  - Abstract methods (CRUD)
  
- [ ] Create Drift table (`data/database/tables/[name]_table.dart`)
  - All fields mapped, including remoteId, syncStatus
  
- [ ] Create repository impl (`data/repositories/[name]_repository_impl.dart`)
  - Implement interface
  - Handle Drift queries
  - Trigger sync after mutations
  
- [ ] Create mapper (`data/mappers/[name]_mapper.dart`)
  - Entity ↔ local model ↔ Firestore model
  - Include `toCompanion()` extension for Drift INSERT/UPDATE
  - Map `remoteId` ↔ Firestore docId
  
- [ ] Create provider (`presentation/providers/[name]_provider.dart`)
  - FutureProvider for reading (from Drift)
  - Provider<Function> for actions (mutation + sync)
  - StateProvider for filters (if applicable)
  - Invalidation logic
  - NEW: Fusion provider (merged local + remote) if multi-device sync planned
  
- [ ] Create screen (`features/[feature]/presentation/screens/[name]_screen.dart`)
  - Use AsyncValue.when()
  - Access control widget wrap
  
- [ ] Create widgets (`features/[feature]/presentation/widgets/[name]_widget.dart`)
  - Pure presentation
  - NO business logic
  
- [ ] Update Firestore security rules (`firestore.rules`)
  - Define read/write permissions for collection
  
- [ ] Add routing (`core/router/app_router.dart`)
  - New route
  - Access checks
  
- [ ] Add FirebaseSyncService support (`data/services/firebase_sync_service.dart`)
  - Add sync[Entity]() method
  - Add to syncAll()
  
- [ ] Add tests (`test/...`)
  - Repository tests (Drift + sync)
  - Provider tests
  - Widget tests (critical screens)

---

## 15. Known Issues & Future Work

### 15.1 Current Limitations

- **Pull from Firestore:** Not yet implemented (one-way sync only)
- **Manual conflict resolution:** Uses LAST-WRITE-WINS only
- **Multi-device sync:** Not yet supported
- **Offline search:** Limited (local data only)

### 15.2 Planned Improvements

- [ ] Bi-directional sync (Drift ↔ Firestore)
- [ ] Custom conflict resolution UI
- [ ] Multi-device sync support
- [ ] Firestore real-time listeners (StreamProvider)
- [ ] Background sync service

---

**Last updated:** 2024 (v14 schema, Firebase sync, Admin setup flow)
**Valid for:** Flutter 3.x, Dart 3.x, Riverpod 2.4.x, Drift 2.13.x, Firebase 4.x
```

