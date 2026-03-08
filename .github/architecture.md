# ARCHITECTURE.md

*Last updated: schema v23*

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
UI action → Repository.addX/updateX/deleteX() → Firestore → listener → Drift → UI rebuilt

READ:
UI → ref.watch(xxxProvider) → Drift stream → StreamProvider → UI
```

> ⚡ **EXCEPTION RULE (firebaseId persistence):**
> After calling `addX()`, Firestore returns the generated `docRef.id`. The Notifier (`XNotifier`) MUST immediately call `upsertX(item.copyWith(firebaseId: docRef.id))` to persist the ID locally without waiting for the CacheService listener. This is the **ONLY** authorized exception to the "CacheService is the only writer to Drift" rule. The CacheService listener will confirm this write later idempotently.

> ℹ️ **EXCEPTION RULE (ClubInfo):**
> `ClubInfo` is an intentional exception to the Drift caching rule. It is stored ONLY in Firestore, as the data is rarely modified and does not require an offline read cache. It bypasses Drift entirely.

---

## 3. Layer Organization

### 3.1 Domain Layer (domain)

**Responsibility:** Pure business logic, NO framework dependencies

**Composition:**
```
domain/
├── entities/          # @immutable data classes (StockItem, UserEntity, Terrain, ClubInfo, etc)
├── repositories/      # Abstract interfaces (StockRepository, AuthRepository, ClubInfoRepository, etc)
├── enums/            # Role, Permission, FeatureFlag, UserStatus
├── logic/            # Business services (PermissionResolver, StockCategorizer)
├── models/           # Domain-specific models (SetupStatus, DailyForecast)
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

enum UserStatus {
  active,
  inactive,
  rejected
}
```

**WeatherRules & Domain Services:**
The `WeatherRules` domain service defines threshold conditions for tennis playability based on `DailyForecast` data (precipitation, tempMax, windSpeed):
- **frozen:** `temp <= 0°C` → 'Terrain gelé' (blue)
- **unplayable + rain:** → 'Terrain impraticable' (red)
- **windyStrong:** `windSpeed >= 40 km/h` → 'Conditions dégradées' (orange)
- **windyModerate:** `windSpeed >= 25 km/h` → 'Vent modéré' (amber)
- **normal:** → 'Conditions optimales' (green)

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
    ├── firebase_auth_service.dart
    └── nominatim_service.dart       # API integration for geocoding ClubInfo addresses
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
  Future<String> addStockItem(StockItem item) async {
    try {
      final docRef = await _fs
          .collection('stocks')
          .add(StockItemMapper.toFirestore(item));
      // ✅ Returns ID to Notifier so it can immediately persist to Drift.
      return docRef.id;
    } on FirebaseException catch (e) {
      throw RepositoryException('Failed to create stock item: ${e.message}');
    }
  }

  @override
  Future<void> updateStockItem(StockItem item) async {
    try {
      await _fs
          .collection('stocks')
          .doc(item.firebaseId)
          .update(StockItemMapper.toFirestore(item));
    } on FirebaseException catch (e) {
      throw RepositoryException('Failed to update stock item: ${e.message}');
    }
  }

  @override
  Future<void> deleteStockItem(String firebaseId) async {
    try {
      await _fs.collection('stocks').doc(firebaseId).delete();
    } on FirebaseException catch (e) {
      throw RepositoryException('Failed to delete stock item: ${e.message}');
    }
  }
}
```

**AppDatabase Upsert Pattern:**
```dart
/// Example AppDatabase method to upsert an item safely using firebaseId
Future<void> upsertStockItem(StockItemsCompanion companion) async {
  if (companion.firebaseId.present && companion.firebaseId.value != null) {
    // 1. Lookup existing record by firebaseId
    final existing = await (select(stockItems)
          ..where((t) => t.firebaseId.equals(companion.firebaseId.value!)))
        .getSingleOrNull();

    if (existing != null) {
      // 2. UPDATE if found, keeping the local integer ID
      await update(stockItems).replace(
        companion.copyWith(id: Value(existing.id)),
      );
    } else {
      // 3. INSERT if not found
      await into(stockItems).insert(companion);
    }
  } else {
    // 4. INSERT directly if no firebaseId
    await into(stockItems).insert(companion);
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
    return _fs.collection('stocks').snapshots().listen(
      (snapshot) async {
        for (final change in snapshot.docChanges) {
          switch (change.type) {
            case DocumentChangeType.added:
            case DocumentChangeType.modified:
              await _db.upsertStockItem(
                StockItemMapper.toCompanion(
                  change.doc.id,
                  change.doc.data(),
                ),
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

### Résilience du Cache (v3.1+)

FirebaseCacheService implémente deux mécanismes de récupération :

1. Auto-restart sur erreur listener
   - Chaque onError callback appelle `_scheduleRestart()`
   - Backoff exponentiel : 3s → 6s → 12s → 24s → 30s (cap)
   - Respecte `_shouldListen` pour ne pas redémarrer après `signOut()`

2. Restart sur reconnexion réseau
   - `startConnectivityMonitoring(Stream<bool>)` appelé depuis `AuthNotifier.signIn()`
   - Redémarre les listeners si `isOnline=true && _shouldListen && !isListening`
   - Reset du compteur backoff à chaque reconnexion manuelle

**Rules:**
- `FirebaseCacheService` is the ONLY component that writes to Drift
- Repositories write to Firestore ONLY
- Repositories read from Drift ONLY
- NO UI imports (Flutter, Riverpod) in data layer

---

### 3.3 Presentation Layer

**Responsibility:** UI, state management, navigation, routing logic

> ℹ️ **NOTE:** The presentation layer is now fully integrated into each feature under `lib/features/`. The `lib/presentation/` folder has been removed.

Each feature folder now encapsulates its own presentation logic:

```
features/[feature]/
├── presentation/
│   ├── screens/   # Full pages
│   ├── pages/     # If applicable (auth, admin)
│   └── widgets/   # Feature-specific widgets
└── providers/     # All Riverpod providers for this feature
```

**Weather Location Priority:**
The `weatherForClubProvider` dynamically determines which location coordinates to query based on this priority order:
1. `clubLocationFromInfoProvider`: Coordinates strictly geocoded from the `ClubInfo` (via NominatimService).
2. `AppSettings.location`: Saved settings fallback (SharedPreferences).
3. `null`: Safe failure → `AsyncValue.data(null)` yielding no weather.

**REMOVED from presentation layer:**
```
❌ lib/presentation/                (folder deleted, migrated to features)
❌ firebase_sync_provider.dart      (replaced by FirebaseCacheService)
❌ SyncStatusModel                  (no longer needed)
❌ manualSyncProvider               (no manual sync)
❌ firebaseSyncStreamProvider       (replaced by listener)
```

**Provider/Notifier pattern (Reads and Writes):**
```dart
// Reads Drift stream — always fresh via FirebaseCacheService listener
final stockProvider = StreamProvider<List<StockItem>>((ref) {
  final repo = ref.watch(stockRepositoryProvider);
  return repo.watchAll(); // Drift stream
});

// Writes and Mutations via AsyncNotifier
class StockNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addStockItem(StockItem item) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(stockRepositoryProvider);
      final db = ref.read(databaseProvider);

      // 1. Write to Firestore and get the generated ID
      final docId = await repo.addStockItem(item);

      // 2. Exception Rule: Persist ID to Drift immediately
      await db.upsertStockItem(
        StockItemMapper.toCompanion(docId, item.toFirestore()),
      );
    });
  }

  Future<void> updateStockItem(StockItem item) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(stockRepositoryProvider);
      await repo.updateStockItem(item);
    });
  }

  Future<void> deleteStockItem(String firebaseId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(stockRepositoryProvider);
      await repo.deleteStockItem(firebaseId);
    });
  }
}

final stockNotifierProvider = AsyncNotifierProvider<StockNotifier, void>(
  StockNotifier.new,
);
```

**Rules:**
- Providers READ: Use `StreamProvider` (Drift streams, always fresh)
- Providers WRITE: Use `AsyncNotifier` (handles mutations and loading state)
- NO fragmented action providers (`Provider<Future<void> Function(...)>`)
- NO `ref.invalidate()` on StreamProviders (auto-reactive via Drift stream)
- NO `firebaseSyncProvider` dependency in data providers

---

### 3.4 Features Layer (features)

**Responsibility:** Feature-specific UI, state management, and specific models/infrastructure

```
features/
├── admin/
│   ├── presentation/
│   │   ├── pages/
│   │   │   └── sections/
│   │   └── screens/
│   └── providers/
│
├── auth/
│   ├── presentation/
│   │   └── pages/
│   └── providers/
│
├── calendar/
│   ├── presentation/
│   │   └── screens/
│   └── providers/
│
├── home/
│   ├── presentation/
│   │   ├── screens/
│   │   └── widgets/
│   └── providers/
│
├── inventory/
│   ├── models/
│   ├── presentation/
│   │   ├── screens/
│   │   └── widgets/
│   └── providers/
│
├── maintenance/
│   ├── presentation/
│   │   ├── screens/
│   │   └── widgets/
│   └── providers/
│
├── settings/
│   ├── presentation/
│   │   ├── screens/
│   │   └── widgets/
│   └── providers/
│
├── stats/
│   ├── presentation/
│   │   ├── screens/
│   │   └── widgets/
│   └── providers/
│
├── terrain/
│   ├── presentation/
│   │   ├── screens/
│   │   └── widgets/
│   └── providers/
│
└── weather/
    ├── infrastructure/   # weather_service.dart
    ├── presentation/
    │   ├── screens/
    │   └── widgets/
    └── providers/
```

### 3.4.1 Home Feature - Dashboard Layout

Le dashboard home est l apres la refonte v2 (2026-03). Il est optimise pour les agents de terrain.

Layout HomeScreen (CustomScrollView, ordre des slivers) :
1. DashboardHeaderEnriched (SliverAppBar, pinned) - header + meteo inline
2. AlertStrip - bandeau alertes fusionne (overdue maintenances + offline)
3. KpiStrip - 3 indicateurs inline 48px (courts, maintenances, stock)
4. Bandeau evenement en cours (conditionnel, inline)
5. Section header "Courts"
6. CourtListSliver - liste des courts avec actions directes
7. ProchainsCreneaux - 2 prochains creneaux du jour
8. StockAlertCard - alerte stock (conditionnel)

Widgets home/ supprimes lors de la refonte v2 :
- DashboardHeader remplace par DashboardHeaderEnriched
- StatsCarousel remplace par KpiStrip
- CurrentEventsBanner integre inline dans home_screen
- DayTimeline supprime (redondant)
- UpcomingEventsList deplace vers CalendarScreen
- SpeedDial remplace par FloatingActionButton.extended contextuel

Widgets home/ actifs apres refonte v2 :
- DashboardHeaderEnriched : SliverAppBar + meteo compacte depuis weatherForClubProvider
- AlertStrip : bandeau unique (overdueCountProvider + connectivite)
- KpiStrip : chips inline (operationalTerrainsStatsProvider, todayMaintenanceCountProvider, lowStockCountProvider)
- ProchainsCreneaux : max 2 items (todayPlannedMaintenancesProvider + todayUpcomingEventsProvider)
- CourtListSliver : liste courts avec actions (inchange)
- StockAlertCard : alerte stock conditionnelle (inchangee)

### 3.4.2 Maintenance Feature - MaintenanceScreen Layout

Le MaintenanceScreen apres la refonte v2 (2026-03) utilise un layout scroll unique
sans tabs, avec hierarchie temporelle des maintenances planifiees.

Layout MaintenanceScreen (CustomScrollView, ordre des slivers) :
1. SliverAppBar compact (titre "Maintenances" + SyncIndicatorMode.compact)
2. KpiStrip maintenance (3 chips : en retard / a venir / effectuees ce mois)
3. Section "En retard" avec _MaintenanceActionCard (conditionnel, fond dangerColor)
4. Section "Aujourd hui" avec _MaintenanceActionCard (boutons Completer + Reporter)
5. Section "Cette semaine" avec _MaintenancePlannedCard (tap to edit)
6. Section "Plus tard" avec _MaintenancePlannedCard (tap to edit)
7. Etat vide si aucune maintenance planifiee
8. Lien "Voir l historique" vers MaintenanceHistoryScreen
9. SizedBox(height: 80) padding FAB

Widgets prives dans maintenance_screen.dart :
- _MaintenanceSectionHeader : titre de section + compteur + couleur optionnelle
- _MaintenanceActionCard : card avec boutons Completer (forceCompleteMode) et Reporter (rescheduleMode)
- _MaintenancePlannedCard : card compacte tap-to-edit (mode edition normale)

Supprime lors de la refonte v2 :
- TabController / SingleTickerProviderStateMixin
- TabBar avec tabs "A venir" et "Historique"
- _HistoryTab (renderait MaintenanceHistoryScreen en tant que tab)
- _UpcomingMaintenancesTab (remplace par le nouveau layout)
FAB conserve : FloatingActionButton.extended (icon: add, label: "Nouvelle maintenance")

### 3.4.3 Settings Feature - SettingsScreen Layout

Le SettingsScreen apres la refonte v2 (2026-03) utilise un layout scroll unique
sans sections GPS ni Notifications (supprimees car placeholder).

Layout SettingsScreen (SingleChildScrollView, ordre des sections) :
1. ProfileCard avec avatar initiales (pas de photo), bouton "Modifier le profil"
2. Section "Preferences" : Mode sombre uniquement (Langue et GPS supprimes)
3. Section "Administration" (conditionnel hasPermissionProvider(canAccessAdminDashboard)) :
   - Banniere utilisateurs en attente si pendingCount > 0
   - Tile "Tableau de bord admin" -> /admin
   - Tile "Utilisateurs en attente" -> /admin/pending-users (Badge pendingCount)
   - Tile "Journal de securite" -> /security-log
4. Section "Securite" : Tile "Changer le mot de passe" -> ChangePasswordSheet
5. LogoutButton
6. Footer version (conserve)

Widgets prives dans settings_components.dart :
- ProfileCard v2 : avatar initiales colore (primaryContainer), bouton "Modifier le profil"
- SectionHeader v2 : barre 3px verticale + titre uppercase (style coherent avec maintenance screen)
- SettingsContainer, PreferenceTile, SwitchTile, LogoutButton : conserves

Nouveaux fichiers crees :
- lib/features/settings/presentation/widgets/profile_edit_sheet.dart
- lib/features/settings/presentation/widgets/change_password_sheet.dart

Supprime lors de la refonte v2 :
- Tile GPS (redondant avec adresse club via Nominatim)
- Tile Langue (placeholder uniquement)
- Section Notifications entiere (valeurs dummy, non implemente)
- Tile Exporter les donnees (renvoie vers Stats screen, pas pertinent ici)
- Tile Reinitialiser les donnees (dangereux sans logique reelle)
- role == Role.admin check (remplace par hasPermissionProvider)

**Rules:**
- Feature code is self-contained.
- `presentation/` folder contains UI logic specific to the feature.
  - `screens/` (for full pages).
  - `pages/` (for specialized routing pages like in auth or admin).
  - `widgets/` (for feature-specific visual components).
- `providers/` folder inside each feature contains all Riverpod providers for that feature.
- Feature models are NOT domain entities.

---

### 3.5 Shared Layer (shared)

**Responsibility:** Cross-feature widgets and common application services

```
shared/
├── services/             # Cross-cutting services (image_picker, share_report, listener_monitor)
└── widgets/
    ├── access_control/   # Role/permission/feature_flag visibility wrappers
    ├── common/           # Reusable UI components (sync_status, image_viewer, quantity_selector)
    └── premium/          # Premium UI components (premium_button, premium_card, premium_text_field)
```

**Rules:**
- Shared widgets and services can be imported by any feature, but `shared/` must never import from `lib/features/`.

---

### 3.6 Core Layer (core)

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
    ├── app_theme.dart              # ThemeData light/dark + classe AppColors (tokens centralisés)
    └── dashboard_theme_extension.dart  # ThemeExtension : couleurs métier, sémantiques, terrains
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
❌ NEVER: import 'features/';
```

**Presentation** (can import domain + data):
```dart
✅ import 'package:flutter/';
✅ import 'package:flutter_riverpod/';
✅ import '../domain/';
✅ import '../data/';
❌ NEVER: import '../features/' (circular imports)
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
final operationalTerrainsStatsProvider = Provider<({int playable, int total})>(...);

// State providers (mutable UI)
final stockFilterProvider = StateProvider<StockFilter>(...);
final stockSearchQueryProvider = StateProvider<String>(...);

// Action/Mutation providers (AsyncNotifier)
final stockNotifierProvider = AsyncNotifierProvider<StockNotifier, void>(...);

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

**AuthExceptionType Enum:**
Alongside the hierarchy, `AuthExceptionType` is used strictly for user-facing UI feedback:
```dart
enum AuthExceptionType {
  invalidCredentials,
  pendingApproval,   // Renders orange warning on LoginPage
  rejected,          // Renders red warning on LoginPage
  emailAlreadyInUse,
  unknown
}
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
Future<String> addStockItem(StockItem item) async {
  try {
    final docRef = await _fs.collection('stocks').add(item.toFirestore());
    return docRef.id;
  } on FirebaseException catch (e) {
    throw RepositoryException('Failed to create: ${e.message}');
  }
}
```

**Offline write error:**
```dart
// User attempts write without internet
try {
  await repository.addStockItem(item);
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
      GoRoute(path: '/signup', builder: ...), // Public (no auth guard)
      GoRoute(path: '/', builder: ..., routes: [
        GoRoute(path: 'stock', builder: ...),
        GoRoute(path: 'maintenance', builder: ...),
        GoRoute(path: 'admin/pending-users', builder: ...), // Guarded (Role.admin only)
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

> ℹ️ **NOTE:** `lib/presentation/` removed — fully migrated to features/

```
lib/
├── core/
│   ├── config/
│   ├── providers/        # connectivity, core providers
│   ├── router/
│   ├── security/
│   ├── theme/
│   └── utils/            # date_utils, csv_export
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
├── domain/
│   ├── entities/         # NO syncStatus field
│   ├── repositories/
│   ├── enums/            # Role, Permission (NO SyncStatus)
│   ├── logic/
│   └── models/           # SetupStatus
│
├── features/
│   ├── admin/
│   ├── auth/
│   ├── calendar/
│   ├── home/
│   ├── inventory/
│   ├── maintenance/
│   ├── settings/
│   ├── stats/
│   ├── terrain/
│   └── weather/
│
├── shared/
│   ├── services/         # image_picker, share_report, listener_monitor
│   └── widgets/
│       ├── access_control/
│       ├── common/
│       └── premium/
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

**Current schema version:** 23
- v23: Performance : index non-unique sur firebaseId (maintenances, terrains, stock_items, events) et firestoreUid (users). Accélère tous les upserts FirebaseCacheService.
- v20: Added `users.status`, `users.approvedAt`, `users.approvedBy`.

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
test('StockRepositoryImpl.addStockItem() writes to Firestore only', () async {
  final mockFs = MockFirebaseFirestore();
  final repo = StockRepositoryImpl(db: mockDb, fs: mockFs);
  
  await repo.addStockItem(testItem);
  
  verify(mockFs.collection('stocks').add(any)).called(1);
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

Signup Flow (Normal User):
  SignupPage → signUp() (Role.admin forbidden)
    1. Firebase Auth: createUserWithEmailAndPassword()
    2. Sets displayName in Firebase Auth
    3. Writes Firestore document with status: 'inactive'
    4. Writes Drift row with firestoreUid immediately
    5. Signs out immediately after signup
    6. Router → Dialog success → /login

Admin Approval Lifecycle:
  Admin views PendingUsersPage (reads from pendingUsersProvider)
  → approveUser(userId): Updates Firestore status to 'active', adds approvedAt/approvedBy
  → rejectUser(userId): Updates Firestore status to 'rejected'
  → FirebaseCacheService._listenUsers() synchronizes status back to Drift

Login (online):
  LoginPage → signIn() → Firebase Auth
    1. Reads user document from Firestore (NOT Custom Claims)
    2. Checks status:
       a. If 'inactive' → PendingApprovalException (Orange UI warning)
       b. If 'rejected' → AccountRejectedException (Red UI warning)
       c. If 'active'   → Proceed
    3. startListening() → authenticated → /

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
  - `Future<String> addX(T item)` — writes Firestore, returns `docRef.id`
  - `Future<void> updateX(T item)` — writes Firestore
  - `Future<void> deleteX(String firebaseId)` — writes Firestore

- [ ] Create Drift table (`data/database/tables/[name]_table.dart`)
  - NO `syncStatus`, `pendingSync`, `lastSyncedAt` columns
  - Include `firebaseId` (TextColumn, nullable)

- [ ] Create repository impl (`data/repositories/[name]_repository_impl.dart`)
  - `watchAll()` → Drift stream
  - `addX/updateX/deleteX()` → Firestore only
  - NO Drift writes (handled by FirebaseCacheService + Notifier on add)

- [ ] Add listener in `FirebaseCacheService`
  - Add `_listen[Entity]()` method
  - Handle `added`, `modified`, `removed` change types
  - Call `startListening()` in `_subscriptions`

- [ ] Create mapper (`data/mappers/[name]_mapper.dart`)
  - `toDomain()` — Drift row → Entity
  - `toFirestore()` — Entity → Firestore map
  - `toCompanion()` — Firestore snapshot → Drift companion (for cache upsert)

- [ ] Create provider/notifier (`features/[feature]/providers/[name]_provider.dart`)
  - `StreamProvider` for reading (Drift stream)
  - `AsyncNotifier` for actions/mutations (`addX`, `updateX`, `deleteX`)
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
├─ lib/features/core/providers/firebase_sync_provider.dart
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

**Last updated:** schema v23 (Firebase as Source of Truth, Drift as cache)
**Valid for:** Flutter 3.x, Dart 3.x, Riverpod 2.4.x, Drift 2.13.x, Firebase 4.x
**Architecture version:** 2.0 (simplified from bidirectional sync)