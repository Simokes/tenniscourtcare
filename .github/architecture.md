# ARCHITECTURE.md

## 1. Architecture Pattern

**Pattern:** Clean Architecture + MVVM (via Riverpod)

**Layers:**
- **Domain:** Business logic, entities, abstract repositories
- **Data:** Database (Drift/SQLite), Cloud (Firestore), repositories implementation, mappers
- **Presentation:** UI (screens, widgets), state management (Riverpod providers), navigation (GoRouter)
- **Infrastructure:** External service adapters (image picker, share service, weather service)

**Dependency flow:** Presentation → Domain ← Data (unidirectional, no reverse dependencies)

---

## 2. Layer Organization

### 2.1 Domain Layer (

domain

)

**Responsibility:** Pure business logic, NO framework dependencies

**Composition:**
```
domain/
├── entities/          # @immutable data classes (StockItem, User, Terrain, etc)
├── repositories/      # Abstract interfaces (StockRepository, AuthRepository, etc)
├── enums/            # Role, Permission, FeatureFlag
├── logic/            # Business services (PermissionResolver, StockCategorizer)
├── models/           # Domain-specific models (QueueStatus, QueueError, QueueProgress)
└── services/         # Domain services (WeatherRules)
```

**Rules:**
- Entities: `@immutable`, `copyWith()`, `==`, `hashCode`, `toString()`
- Repositories: Abstract classes only (NO implementation)
- No imports of: Drift, Firestore, Flutter, Riverpod
- All entities must have `id`, `createdAt`, `updatedAt` fields (for sync)

**Example entity:**
```dart
@immutable
class StockItem {
  final int? id;
  final String name;
  final int quantity;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  // ...
  StockItem copyWith({...}) { }
  @override bool operator ==(Object other) { }
  @override int get hashCode { }
}
```

---

### 2.2 Data Layer (

data

)

**Responsibility:** Data persistence, cloud sync, data transformation

**Composition:**
```
data/
├── database/              # Drift/SQLite (local source of truth)
│   ├── app_database.dart  # @DriftDatabase with all tables
│   ├── tables/            # Table definitions (UsersTable, StockItemsTable, etc)
│   └── queries/           # Custom queries, extensions
│
├── firestore/             # Cloud schema models (Firestore targets)
│   └── models/            # FirebaseStockModel, FirebaseTerrainModel, etc
│
├── repositories/          # Repository implementations
│   ├── [entity]_repository_impl.dart
│   └── firestore/         # Firestore-specific repos (optional)
│
├── services/              # Firebase services (sync, batch ops)
│   └── firebase_sync_service.dart
│
└── mappers/              # Entity ↔ Model ↔ DTO conversions
    └── [entity]_mapper.dart
```

**Rules:**
- Repositories: Implement domain interfaces, never export them directly
- Drift: Single instance (singleton via databaseProvider in Presentation layer)
- Mappers: Convert domain entities ↔ local models ↔ Firestore models
- Services: Handle Firebase operations (sync, batch writes, auth)
- NO UI imports (Flutter, Riverpod)

**Example repository:**
```dart
class StockRepositoryImpl implements StockRepository {
  final AppDatabase _db;

  @override
  Future<List<StockItem>> getAllStockItems() async {
    return _db.watchAllStockItems().first;
  }
}
```

---

### 2.3 Presentation Layer (

presentation

)

**Responsibility:** UI, state management, navigation

**Composition:**
```
presentation/
├── providers/           # Riverpod state management
│   ├── auth_providers.dart
│   ├── stock_provider.dart
│   ├── terrain_provider.dart
│   ├── database_provider.dart  # Singleton Drift instance
│   └── [domain]_provider.dart
│
├── pages/              # Top-level pages (full-screen)
│   ├── auth/
│   │   ├── login_page.dart
│   │   └── admin_setup_page.dart
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
│   ├── queue_status_widget.dart
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

---

### 2.4 Features Layer (

features

)

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

### 2.5 Core Layer (

core

)

**Responsibility:** Shared infrastructure, configuration

**Composition:**
```
core/
├── config/
│   ├── app_config.dart       # API keys, URLs, constants
│   └── queue_config.dart     # Sync/queue settings
│
├── router/
│   ├── app_router.dart       # GoRouter setup + redirect logic
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
authStateProvider (StateNotifierProvider)
  ↓ depends on
authRepositoryProvider (Provider)
  ↓ depends on
databaseProvider (Provider - singleton)
  ↓ depends on
AppDatabase (Drift)
```

**Rule:** Providers must declare dependencies via `ref.watch()` (not direct instantiation)

---

## 4. Riverpod Provider Rules

### 4.1 Provider Types

| Type | Use case | Lifespan |
|------|----------|----------|
| `Provider<T>` | Synchronous, immutable | App lifetime |
| `FutureProvider<T>` | Async, single-shot (no state) | Until invalidated |
| `StateProvider<T>` | Mutable UI state (filter, search) | Until invalidated |
| `StateNotifierProvider<N, T>` | Complex state + mutations | App lifetime |
| `StreamProvider<T>` | Real-time data (deprecated, migrate to FutureProvider + listener) | Until invalidated |

**Rules:**
- Default: `FutureProvider` for async data
- Use `StateNotifierProvider` only for: Auth state, Cart/form state
- NEVER: `Provider` for async operations (use `FutureProvider`)
- NEVER: Mix `StreamProvider` and `FutureProvider` for same data

---

### 4.2 Provider Naming Convention

```dart
// Data providers
final stockProvider = FutureProvider<List<StockItem>>(...);
final terrainProvider = FutureProvider<List<Terrain>>(...);

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
final stockNotifierProvider = StateNotifierProvider<StockNotifier, AsyncValue<List<StockItem>>>(...);

// Singleton services
final databaseProvider = Provider<AppDatabase>(...);
final firebaseSyncServiceProvider = Provider<FirebaseSyncService>(...);

// Derived providers
final isAuthenticatedProvider = Provider<bool>(...);
final currentUserProvider = Provider<UserEntity?>(...);
```

**Rules:**
- Plural: `stockProvider` (returns List)
- Singular: `currentUserProvider` (returns single entity)
- Suffix: `_notifier` for StateNotifierProvider
- Suffix: `_service` for service singletons
- Suffix: `_filter`, `_search`, `_query` for state providers

---

### 4.3 Provider Scope

**Global scope (app lifetime):**
```dart
final databaseProvider = Provider<AppDatabase>(...);
final authRepositoryProvider = Provider<AuthRepository>(...);
final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthState>>(...);
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

---

### 4.4 Provider Invalidation

**When to invalidate:**
```dart
// After mutation success
ref.invalidate(stockProvider);              // Refresh list
ref.invalidate(filteredStockItemsProvider); // Refresh filtered view

// Cascade invalidation
ref.invalidate(lowStockItemsProvider);      // Auto-refreshes if dependent

// Exception: Never invalidate state providers
// ❌ ref.invalidate(stockFilterProvider);  // NO - breaks UI state
```

**Rules:**
- Invalidate parent providers after mutations
- Dependent providers auto-invalidate
- NEVER invalidate StateProviders manually (use .state = instead)
- Always invalidate in try/catch, not just on success

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

**File:** 

app_router.dart



**Pattern:**
```dart
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(ref.read(authStateProvider.notifier).stream),
    redirect: (context, state) {
      final authState = ref.read(authStateProvider).value;
      // Conditional routing logic
    },
    routes: [
      GoRoute(path: '/login', builder: ...),
      GoRoute(path: '/', builder: ..., routes: [
        GoRoute(path: 'nested', builder: ...),
      ]),
    ],
  );
});
```

**Rules:**
- Single GoRouter instance (via provider)
- Redirect logic: Check auth state, role, setup status
- refreshListenable: Watch auth state changes
- Routes: Declarative, hierarchical

---

### 7.2 Routing Rules

**Conditional routing (redirect):**
```dart
redirect: (context, state) {
  final isSetupRequired = authState.isSetupRequired;
  final isLoggedIn = authState.user != null;
  
  // Priority 1: Setup required
  if (isSetupRequired) {
    return state.uri.path == '/admin-setup' ? null : '/admin-setup';
  }
  
  // Priority 2: Not logged in
  if (!isLoggedIn) {
    return state.uri.path == '/login' ? null : '/login';
  }
  
  // Priority 3: Logged in, prevent re-login
  if (state.uri.path == '/login') {
    return '/';
  }
  
  return null; // No redirect
}
```

**Rules:**
- Redirect priorities: setup > login > role checks > data availability
- Prevent loop redirects (check current path before redirecting)
- Return null = no redirect, or return new path

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
│   ├── router/           # Navigation
│   ├── security/         # Auth, exceptions
│   └── theme/            # UI theme
│
├── domain/
│   ├── entities/         # Data models (@immutable)
│   ├── repositories/     # Abstract interfaces
│   ├── enums/           # Role, Permission
│   ├── logic/           # Domain services
│   └── models/          # Domain-specific models
│
├── data/
│   ├── database/        # Drift/SQLite
│   │   └── tables/
│   ├── firestore/       # Cloud models
│   │   └── models/
│   ├── repositories/    # Implementations
│   ├── mappers/         # Entity converters
│   └── services/        # Firebase services
│
├── features/
│   ├── [feature]/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   ├── models/      # Feature-specific models
│   │   └── infrastructure/ # Feature services
│   └── [feature]/...
│
├── presentation/
│   ├── providers/       # Riverpod state
│   ├── pages/          # Full-screen pages
│   ├── screens/        # Nested screens
│   ├── widgets/        # Reusable components
│   └── utils/          # Helpers
│
├── services/
│   ├── queue/          # Queue management
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
| Entity | `[name].dart` | 

stock_item.dart

 |
| Repository (interface) | `[name]_repository.dart` | `stock_repository.dart` |
| Repository (impl) | `[name]_repository_impl.dart` | 

stock_repository_impl.dart

 |
| Provider | `[name]_provider.dart` | 

stock_provider.dart

 |
| Screen | `[name]_screen.dart` | `stock_screen.dart` |
| Widget | `[name]_widget.dart` | `stock_item_tile.dart` |
| Page | `[name]_page.dart` | `login_page.dart` |
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

**Rule:** Drift (local SQLite) is primary source, Firestore is backup

**Flow:**
1. User mutation → Write to Drift immediately
2. SyncQueue entry created (operation: CREATE/UPDATE/DELETE)
3. On network available → Push to Firestore
4. Firestore write success → Update SyncQueue status: SUCCESS

**Rules:**
- Writes: Always to Drift first (optimistic)
- Reads: Always from Drift
- Sync: Drift → Firestore (unidirectional, currently)
- No pull from Firestore yet (planned)

---

### 10.2 SyncQueue Management

**Trigger sync:**
```dart
final syncStockProvider = FutureProvider<void>((ref) async {
  final syncService = ref.watch(firebaseSyncServiceProvider);
  await syncService.syncStock();
});

// In UI:
ElevatedButton(
  onPressed: () => ref.refresh(syncStockProvider),
  child: Text('Sync now'),
);
```

**Rules:**
- Manual sync: Via provider invalidation
- Auto sync: Timer in 

main.dart

 (every 5 min)
- Network change: Trigger sync on connectivity change
- Invalidate data providers after sync success

---

### 10.3 Offline Behavior

**Offline scenario:**
- Writes: Queued in SyncQueue (status: PENDING)
- Reads: Served from Drift (stale data warning optional)
- Sync: Retried on network restore (exponential backoff)

**Rules:**
- No error shown to user (seamless offline)
- SyncQueue backup visible (via QueueStatusBanner)
- Max queue size: 1000 items (user alerted if exceeded)

---

## 11. Testing Requirements

### 11.1 Unit Tests

**Where:** 

test

 directory (mirror lib structure)

**Coverage required:**
- Domain: Business logic, validators, permission resolver
- Repositories: Drift queries, error handling
- Providers: State transitions, invalidation

**Pattern:**
```dart
test('StockItem.isLowOnStock returns true when quantity <= minThreshold', () {
  final item = StockItem(quantity: 5, minThreshold: 10, ...);
  expect(item.isLowOnStock, isTrue);
});
```

**Rules:**
- Test: Domain logic, repository contracts, provider logic
- Mock: Drift (use in-memory), Firestore (mock service)
- Assert: Single assertion per test (when possible)

### 11.2 Widget Tests

**Where:** 

test

 directory

**Coverage required:**
- Critical screens: StockScreen, LoginPage, AdminDashboard
- Error states: AsyncValue.error handling
- Permissions: Access control widgets

**Pattern:**
```dart
testWidgets('StockScreen shows error on load failure', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [stockProvider.overrideWithValue(AsyncValue.error(exception, st))],
      child: StockScreen(),
    ),
  );
  expect(find.byType(ErrorWidget), findsOneWidget);
});
```

---

## 12. Database Transactions & Migrations

### 12.1 Schema Versioning

**Current version:** v14

**Migration path:**
```dart
// In app_database.dart
@DriftDatabase(
  version: 14,
  // All tables declared
)
```

**Rules:**
- Version incremented on schema change
- Migrations auto-applied on app launch
- Migrations: Create migration file for v14+

### 12.2 Sync Queue Transactions

**Pattern:**
```dart
Future<void> syncStock() async {
  final batch = firestore.batch();
  
  // Get pending operations
  final queue = await _db.getSyncQueueByStatus(SyncQueueStatus.pending);
  
  // Add to batch (max 500)
  for (final op in queue.take(500)) {
    // batch.set(...) or batch.update(...)
  }
  
  // Commit transaction
  await batch.commit();
  
  // Update SyncQueue status
  await _db.updateSyncQueueStatus(op.id, SyncQueueStatus.success);
}
```

**Rules:**
- Transactions: Max 500 operations per batch
- Atomicity: All-or-nothing per batch
- Status tracking: Update SyncQueue before/after

---

## 13. Checklist for New Features

When implementing new domain entity:

- [ ] Create domain entity (`domain/entities/[name].dart`)
  - @immutable, copyWith, ==, hashCode, toString
  - id, createdAt, updatedAt fields
  
- [ ] Create repository interface (`domain/repositories/[name]_repository.dart`)
  - Abstract methods (CRUD)
  
- [ ] Create Drift table (`data/database/tables/[name]_table.dart`)
  - All fields mapped
  
- [ ] Create repository impl (`data/repositories/[name]_repository_impl.dart`)
  - Implement interface
  - Handle Drift queries
  
- [ ] Create mapper (`data/mappers/[name]_mapper.dart`)
  - Entity ↔ local model ↔ Firestore model
  
- [ ] Create provider (`presentation/providers/[name]_provider.dart`)
  - FutureProvider for reading
  - Provider<Function> for actions
  - StateProvider for filters (if applicable)
  - Invalidation logic
  
- [ ] Create screen (`features/[feature]/presentation/screens/[name]_screen.dart`)
  - Use AsyncValue.when()
  - Access control widget wrap
  
- [ ] Create widgets (`features/[feature]/presentation/widgets/[name]_widget.dart`)
  - Pure presentation
  - NO business logic
  
- [ ] Add routing (`core/router/app_router.dart`)
  - New route
  - Access checks
  
- [ ] Add tests (`test/...`)
  - Repository tests
  - Provider tests
  - Widget tests (critical screens)

---

**Last updated:** 2024
**Valid for:** Flutter 3.x, Dart 3.x, Riverpod 2.4.x, Drift 2.13.x