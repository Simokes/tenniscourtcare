# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Run code generation (Drift tables, Riverpod providers) — required after any schema/provider change
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Run all tests
flutter test

# Run a single test file
flutter test test/path/to/test_file.dart

# Lint
flutter analyze
```

**Never manually edit `*.g.dart` files** — always regenerate with `build_runner`.

---

## Architecture

**Pattern:** Clean Architecture + MVVM via Riverpod, feature-first folder structure.

### Critical Rule: Firebase is Source of Truth

```
Firebase (Firestore) = Source of Truth
Drift (SQLite)       = Read cache only
```

**Data flow:**
- **WRITE:** UI action → `AsyncNotifier` → `Repository.addX/updateX/deleteX()` → Firestore → `FirebaseCacheService` listener → Drift → UI rebuilt
- **READ:** UI → `ref.watch(xxxProvider)` → Drift `StreamProvider` → UI

**`FirebaseCacheService`** (`lib/data/services/firebase_cache_service.dart`) is the **sole** component authorized to write to Drift. It listens to all Firestore collections and upserts/deletes records in Drift.

**Exception — firebaseId persistence:** After `addX()`, the repository returns `docRef.id`. The `AsyncNotifier` **must** immediately call `db.upsertX(item.copyWith(firebaseId: docRef.id))` to persist the ID locally without waiting for the listener. This is the only authorized exception.

**Exception — ClubInfo:** Stored only in Firestore, not cached in Drift.

---

### Folder Structure

```
lib/
├── core/            # Config, routing (GoRouter), security, theme, utils
├── data/
│   ├── database/    # Drift/SQLite: app_database.dart + tables/ + queries/
│   ├── firestore/   # Cloud schema models (FirebaseXxxModel)
│   ├── mappers/     # Entity <-> DTO conversions (XxxMapper)
│   ├── repositories/# Implementations: read Drift, write Firestore
│   └── services/    # firebase_cache_service.dart, firebase_auth_service.dart
├── domain/
│   ├── entities/    # @immutable data classes (id, firebaseId, createdAt, updatedAt)
│   ├── repositories/# Abstract interfaces only
│   ├── enums/       # Role, Permission, FeatureFlag, UserStatus
│   ├── logic/       # PermissionResolver, StockCategorizer
│   └── services/    # WeatherRules
├── features/        # Feature modules (admin, auth, calendar, home, inventory,
│                    #   maintenance, settings, stats, terrain, weather)
│   └── [feature]/
│       ├── presentation/screens/  # Full pages
│       ├── presentation/widgets/  # Feature-specific widgets
│       └── providers/             # All Riverpod providers for this feature
└── shared/
    ├── services/    # image_picker, share_report, listener_monitor
    └── widgets/     # access_control/, common/, premium/
```

### Layer Dependency Rules

- **Domain:** No imports of Flutter, Riverpod, Drift, or Firestore.
- **Data:** Can import domain. No Flutter or Riverpod imports.
- **Features/Presentation:** Can import domain and data. No circular imports between features.
- **Shared:** Can be imported by any feature, but must never import from `lib/features/`.

---

### Riverpod Provider Patterns

| Use case | Provider type |
|---|---|
| Drift data streams (reads) | `StreamProvider<T>` |
| Mutations (add/update/delete) | `AsyncNotifier` via `AsyncNotifierProvider` |
| Mutable UI state (filter, search) | `StateProvider<T>` |
| Auth state | `StateNotifierProvider` |
| Setup/admin detection | `FutureProvider<SetupStatus>` |
| Singleton services | `Provider<T>` (no autoDispose) |

**Rules:**
- Never use `FutureProvider` for Drift data — use `StreamProvider` (auto-reactive via Drift stream).
- Never manually invalidate data `StreamProvider`s — they auto-update via the `FirebaseCacheService` listener.
- Only invalidate `setupStatusProvider` on auth state changes.
- No `ref.invalidate()` on data providers.
- No fragmented action providers (`Provider<Future<void> Function(...)>`).

**Auth lifecycle:** `FirebaseCacheService.startListening()` is called in `AuthNotifier.signIn()`, and `stopListening()` in `signOut()`.

---

### Router & Setup Flow

`GoRouter` uses `setupStatusProvider` (a `FutureProvider<SetupStatus>`) as a `refreshListenable` to gate navigation:

```
SetupStatus.noNetworkFirstLaunch → /no-network
SetupStatus.needsAdminSetup      → /admin-setup
SetupStatus.needsLogin           → /login
SetupStatus.authenticated        → /  (home)
```

Offline login: Firebase Auth fails → `signInOffline()` checks PBKDF2 password hash in Drift.

---

### Database Schema

**Current version: 22** — bump `schemaVersion` in `app_database.dart` whenever adding/removing columns or tables.

All tables include: `id` (int, auto-increment, local PK), `firebaseId` (String?, nullable), `createdAt`, `updatedAt`.

Tables **do not** have `syncStatus`, `pendingSync`, or `lastSyncedAt` columns.

Use `upsertX()` in `AppDatabase` for all cache writes — it looks up by `firebaseId`, updates if found, inserts otherwise.

**Upsert pattern:**
```dart
Future<void> upsertStockItem(StockItemsCompanion companion) async {
  final existing = await (select(stockItems)
        ..where((t) => t.firebaseId.equals(companion.firebaseId.value!)))
      .getSingleOrNull();
  if (existing != null) {
    await update(stockItems).replace(companion.copyWith(id: Value(existing.id)));
  } else {
    await into(stockItems).insert(companion);
  }
}
```

---

## Coding Rules

### Naming

- Files: `snake_case.dart`, pattern `[domain]_[type].dart` (e.g., `stock_repository_impl.dart`).
- Classes: `PascalCase`. Implementations use `Impl` suffix (not `_concrete`). No "Widget" suffix — use descriptive names (`StockItemTile` not `StockItemWidget`).
- Variables/constants: `camelCase` (no `SCREAMING_SNAKE_CASE`).
- All public function parameters: named + explicit `required`/optional. No positional parameters in public APIs.
- Private fields/methods: `_underscore` prefix. Public getters: no underscore.

### Widgets

- Prefer `ConsumerWidget` for provider access. Use `StatefulWidget` only for local UI state (forms, animations).
- Always use `.when()` for `AsyncValue` in `build()`.
- No business logic in widgets — delegate to providers.
- No `try/catch` in UI widgets — handle errors in providers, display via `.when(error: ...)`.
- Extract private helper widgets (`_BodyWidget`) rather than deeply nesting.
- `const` constructors required. All widget parameters `final`. Max build() ~50 lines.

### Async

- Always use `async/await`, never `.then()` chains.
- All async functions wrapped in `try/catch (e, st)` with `debugPrint` and `rethrow`.
- Use `debugPrint()`, never `print()`.

### Error handling

- Write errors (Firestore unavailable): show message to user, do **not** modify Drift.
- Read errors: Drift keeps last known value; listener errors are logged only.
- Exception hierarchy: `RepositoryException` wraps Firestore write errors; `AuthException` for auth flows.

### File size limits

```
Entity:          < 200 lines
Provider:        < 300 lines
Widget:          < 300 lines
Screen:          < 500 lines
Repository impl: < 400 lines
```

### Checklist for new domain entities

1. Domain entity (`domain/entities/`) — `@immutable`, `copyWith`, `==`, `hashCode`, `toString`, no `syncStatus`.
2. Repository interface (`domain/repositories/`) — `watchAll()` returns Drift stream, `addX()` returns `Future<String>` (docRef.id).
3. Drift table (`data/database/tables/`) — include `firebaseId` (nullable Text), no sync columns.
4. Repository impl (`data/repositories/`) — reads Drift, writes Firestore only.
5. Mapper (`data/mappers/`) — `toDomain()`, `toFirestore()`, `toCompanion()`.
6. Add listener in `FirebaseCacheService` — handle `added`, `modified`, `removed`.
7. Provider + Notifier (`features/[feature]/providers/`) — `StreamProvider` for reads, `AsyncNotifier` for mutations.
8. Screen + widgets, route in `app_router.dart`, Firestore security rules.
9. Regenerate with `build_runner`.

---

## Key Reference Files

| Responsibility | Path |
|---|---|
| App entry | `lib/main.dart` |
| Router + redirect logic | `lib/core/router/app_router.dart` |
| Database (schema v22) | `lib/data/database/app_database.dart` |
| Cache service (sole Drift writer) | `lib/data/services/firebase_cache_service.dart` |
| Auth notifier | `lib/features/auth/providers/` |
| Permission logic | `lib/domain/logic/permission_resolver.dart` |
| Weather service | `lib/features/weather/infrastructure/weather_service.dart` |
| Club info provider | `lib/features/admin/providers/club_info_provider.dart` |
| Shared widgets | `lib/shared/widgets/` |
| Security | `lib/core/security/` |
