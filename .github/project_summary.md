## 1. Project Overview

**Produit:** Tennis Court Care - Système de gestion intégré pour clubs de tennis

**Objectif:** Centraliser la gestion opérationnelle des courts de tennis (réservations, maintenance, inventaire, météo, événements) avec synchronisation temps réel entre base locale et cloud.

**Public cible:** 
- Administrateurs de clubs de tennis
- Responsables de maintenance
- Gestionnaires d'inventaire
- Réceptionnistes

**Problème résolu:**
- Absence de synchronisation entre données locales et cloud
- Gestion fragmentée de la maintenance préventive/corrective
- Visibilité insuffisante sur l'état des stocks
- Impossibilité de fonctionner hors ligne avec sync automatique
- Pas de traçabilité des opérations sensibles

---

## 2. Core Features

### Existantes (MVP - Production)

**Gestion des courts (Terrains)**
- Création/édition/suppression de courts
- Assignation de type/surface
- Historique de maintenance par court
- Géolocalisation avec coordonnées GPS (format: latitude/longitude decimals)

**Réservations & Événements**
- Calendrier des réservations
- Créations/éditions d'événements
- Visualisation par court et par date

**Inventaire (Stock)**
- CRUD articles (fixes + custom)
- Catégorisation: matériaux | produits_entretien | fournitures_maintenance | autres
- Seuils d'alerte configurables
- Historique des mouvements (types: IN, OUT, ADJUSTMENT, RETURN)
- Filtres et recherche

**Maintenance**
- Planification interventions
- Historique complet par court
- Recommandations de réapprovisionnement
- Suivi des coûts

**Météo**
- Intégration API (OpenWeather/Meteoblue)
- Affichage cartes journalières
- Alertes conditions extrêmes
- Fallback: Cached data + "stale data" warning si API indisponible (TTL: 24h)

**Dashboard**
- Vue synthétique état clubs
- Statistiques maintenance
- Alertes stocks critiques
- Prochains événements

**Gestion Utilisateurs & Admin**
- Authentification Firebase (email/password)
- Rôles: admin | agent | secretary (voir section 2.3)
- Permissions par rôle (voir section 2.3)
- Logs d'audit (toutes mutations)
- Rate limiting: 10 login attempts/15min par user (app-side, Drift table login_attempts)
- OTP (PBKDF2) pour: opérations admin sensibles (user creation, deletion, permission changes) - **optionnel en MVP**

### 2.3 Rôles & Permissions

| Rôle | Accès Lectures | Accès Écritures | Restrictions |
|------|---|---|---|
| **admin** | Tous les domaines | Tous | Aucune |
| **agent** | Terrains, Maintenance, Stock | Terrain view, Maintenance CRUD, Stock movements | Pas accès Users, Admin |
| **secretary** | Terrains, Events, Stock view | Events CRUD | Pas mutation terrain, pas maintenance |

**Implémentation:** `lib/domain/enums/role.dart` + `PermissionResolver` (lib/domain/logic/permission_resolver.dart)

### En cours / Partiellement implémentées

- Premium features (feature flags système - non-implémenté)
- Synchronisation queue avancée: retry logic incomplete (voir section 7)
- Export CSV rapports
- Filtres multi-critères avancés

---

## 3. Technical Stack

| Couche | Technology | Détails |
|--------|-----------|---------|
| **Framework** | Flutter 3.x | iOS/Android |
| **Language** | Dart 3.x | Null safety, records |
| **State Mgmt** | Riverpod 2.4.x | Provider, FutureProvider, StreamProvider (deprecation: .stream → .future en v3.0) |
| **Local DB** | Drift 2.13.x | SQLite avec typage fort, migrations auto (current: v23) |
| **Cloud DB** | Firestore | Real-time sync, security rules (rules exist but untested - see section 7) |
| **Auth** | Firebase Auth 4.15.x | Email/password |
| **Auth Supplement** | Custom TokenService | JWT management (refresh logic: **À DOCUMENTER**) |
| **Routing** | GoRouter 10.x | Navigation déclarative avec redirect logic conditionnelle |
| **HTTP** | Dio 5.x | Interceptors, retry logic, request/response logging |
| **Code Gen** | build_runner | Drift, Riverpod, Freezed |
| **Validation** | Custom validators | Auth exceptions, security checks (lib/core/security/) |
| **Weather API** | OpenWeather/Meteoblue | API REST intégrée, fallback caching 24h |
| **Storage Local** | SharedPreferences | User settings, tokens (token refresh: needs clarification) |
| **Analytics** | Firebase Analytics | Event tracking (optionnel) |
| **Logs** | Custom logger | Audit logs en DB + console (lib/services/listener_monitor.dart) |

**Architecture Pattern:** Clean Architecture + MVVM (Riverpod providers = ViewModels)

---

## 4. Architecture Overview

### Layer Organization

```
lib/
├── core/
│   ├── config/          # App config (API keys, URLs, feature flags)
│   ├── providers/
│   ├── router/          # GoRouter setup + redirect logic (conditional: admin setup → login → home)
│   ├── security/        # Auth validators, rate limiter (LoginAttempts table), token service, auth exceptions
│   ├── theme/           # Material theme + extensions
│   └── utils/
├── data/
│   ├── database/        # Drift SQLite (app_database.dart + 11 tables at v20)
│   │   └── tables/      # UsersTable, TerrainTable, StockItemsTable, StockMovementsTable, MaintenancesTable, ReservationsTable, EventsTable, AuditLogsTable, SyncQueueTable, LoginAttemptsTable, OtpRecordsTable
│   ├── mappers/         # Entity ↔ DTO conversions (UserMapper, StockItemMapper, etc)
│   ├── repositories/    # Implementations (local Drift + Firestore)
│   │   └── firestore/   # Firestore-specific repos (optional for read-heavy queries)
│   └── services/        # Firebase services (FirebaseSyncService, FirebaseStockService, etc)
├── domain/
│   ├── entities/        # Pure data classes (User, StockItem, Terrain, Maintenance, Reservation, Event, AuditLog, SyncQueue, OtpRecord, LoginAttempt)
│   ├── enums/           # Role (admin|agent|secretary), Permission (CREATE_USER|DELETE_USER|etc), FeatureFlag
│   ├── logic/
│   ├── models/
│   ├── repositories/    # Abstract interfaces (UserRepository, StockRepository, TerrainRepository, EventRepository, MaintenanceRepository, AuditRepository)
│   └── services/        # Business logic (WeatherRules, PermissionResolver)
├── features/
│   ├── admin/
│   │   ├── presentation/pages/sections/
│   │   ├── presentation/screens/
│   │   └── providers/
│   ├── auth/
│   │   ├── presentation/pages/
│   │   └── providers/
│   ├── calendar/
│   │   ├── presentation/screens/
│   │   └── providers/
│   ├── home/            # Dashboard module
│   │   ├── presentation/screens/
│   │   ├── presentation/widgets/
│   │   └── providers/
│   ├── inventory/       # Stock management module
│   │   ├── models/      # stock_filter.dart (enum: all|lowStock|fixed|custom)
│   │   ├── presentation/screens/
│   │   ├── presentation/widgets/
│   │   └── providers/
│   ├── maintenance/
│   │   ├── presentation/screens/
│   │   ├── presentation/widgets/
│   │   └── providers/
│   ├── settings/
│   │   ├── presentation/screens/
│   │   ├── presentation/widgets/
│   │   └── providers/
│   ├── stats/
│   │   ├── presentation/screens/
│   │   ├── presentation/widgets/
│   │   └── providers/
│   ├── terrain/
│   │   ├── presentation/screens/
│   │   ├── presentation/widgets/
│   │   └── providers/
│   └── weather/         # Weather display module
│       ├── infrastructure/
│       ├── presentation/screens/
│       ├── presentation/widgets/
│       └── providers/
└── shared/
    ├── services/
    └── widgets/
        ├── access_control/
        ├── common/
        └── premium/
```

*Note: `lib/presentation/` fully migrated to `lib/features/`*

### Layer Responsibilities

**Domain:**
- Business rules + entity definitions
- Abstract repository interfaces
- Permission/weather logic
- NO database imports, NO Firebase imports

**Data:**
- Drift: Cache local lecture seule, auto-migrations (v23)
- Firestore: Source de vérité, real-time listeners via FirebaseCacheService
- Repositories: Reads depuis Drift, Writes vers Firestore uniquement
- Mappers: Convert between entities and DTOs
- Services: firebase_cache_service.dart (CORE — seul composant autorisé à écrire dans Drift)

**Presentation:**
- Riverpod providers: State management (StreamProvider pour Drift streams, AsyncNotifier pour mutations)
- UI screens & widgets: Flutter code
- Form validation: Input validation (domain validators injected)
- Navigation: GoRouter declarative routing + conditional redirects via setupStatusProvider

---

## 5. Domain Model Summary

### 5.1 Entités principales

| Entity | Attributes clés | Type PK | Relations |
|--------|-----------------|---------|-----------|
| **User** | id, email, fullName, role, hashedPassword, createdAt, updatedAt | String (Firebase UID) | 1→n AuditLog, 1→n LoginAttempt, 1→n StockMovement |
| **Terrain** | id, name, surface, type, coordinates (lat/long decimals), status, lastMaintenance, updatedAt | String | 1→n Maintenance, 1→n Reservation, 1→n Event |
| **StockItem** | id, name, quantity, minThreshold, unit, category (enum), isCustom (bool), sortOrder, updatedAt | int (auto) | 1→n StockMovement |
| **StockMovement** | id, itemId, quantity, type (enum: IN\|OUT\|ADJUSTMENT\|RETURN), timestamp, userId, reason (nullable), updatedAt | int (auto) | n→1 StockItem, n→1 User |
| **Maintenance** | id, terrainId, type, description, scheduledDate, completedDate (nullable), cost, notes, updatedAt | int (auto) | n→1 Terrain, n→1 User |
| **Reservation** | id, terrainId, startTime, endTime, userName, status (enum: PENDING\|CONFIRMED\|CANCELLED), updatedAt | int (auto) | n→1 Terrain |
| **Event** | id, terrainId, title, description (nullable), startTime, endTime, updatedAt | int (auto) | n→1 Terrain |
| **AuditLog** | id, userId, action (enum: CREATE\|UPDATE\|DELETE\|LOGIN\|LOGOUT), resource (table name), resourceId (nullable), timestamp, details (JSON string) | int (auto) | n→1 User |
| **SyncQueue** | id, operation (enum: CREATE\|UPDATE\|DELETE), entity (table name), entityId (String or int), status (enum: PENDING\|IN_PROGRESS\|FAILED\|SUCCESS), timestamp, retries (int), lastError (nullable), updatedAt | int (auto) | None (orphan records) |
| **LoginAttempt** | id, userId, email, success (bool), timestamp, ipAddress (nullable) | int (auto) | n→1 User (soft link) |
| **OtpRecord** | id, userId, code (hashed), type (enum: ADMIN_ACTION\|PASSWORD_RESET), createdAt, expiresAt, used (bool) | int (auto) | n→1 User (soft link) |

### 5.2 Relations critiques

- **Terrain** = agrégat root pour Maintenance, Reservation, Event
- **StockItem** ↔ **StockMovement** = historique immuable (append-only pattern)
- **User.role** détermine accès via PermissionResolver (domain service)
- **SyncQueue** gère offline-first: captures mutations locales → async push to Firestore
- **LoginAttempt** rate-limiting: 10 failed attempts/15min par user
- **OtpRecord** pour operaciones sensibles (admin-only): user creation, deletion, role changes

### 5.3 Enums

**Role** (lib/domain/enums/role.dart):
```
admin     → Tous les domaines
agent     → Terrain view, Maintenance CRUD, Stock movements
secretary → Events CRUD
```

**StockMovement.type**:
```
IN          → Stock arrival
OUT         → Stock usage
ADJUSTMENT  → Manual correction
RETURN      → Stock return
```

**SyncQueue.operation**:
```
CREATE  → Entity insertion to Firestore
UPDATE  → Entity field update to Firestore
DELETE  → Entity removal from Firestore
```

**SyncQueue.status**:
```
PENDING      → Waiting for sync
IN_PROGRESS  → Currently syncing (Firestore write in progress)
FAILED       → Last sync failed, retry queued
SUCCESS      → Synced successfully
```

---

## 6. Non-Functional Constraints

### 6.1 Performance

- Local queries (Drift): < 100ms (target for indexed queries)
- Firestore reads: < 500ms (network-dependent)
- Sync batch size: max 500 documents/batch (Firestore transaction limit)
- UI responsiveness: 60fps minimal (Flutter best practices)
- Cold startup: < 3s (app launch → home screen)
- Database size: < 100MB (SQLite file size limit consideration)

### 6.2 Offline Support

**Scope:** Full read access + mutation queuing

- SQLite full replica locale: All data synced at last online session
- SyncQueue captures all mutations: CREATE, UPDATE, DELETE queued locally
- Auto-retry avec exponential backoff: **Strategy defined below**
- Conflict resolution: **Last-write-wins (see section 6.4 for implications)**
- No API calls when offline: All requests cached or queued

**Retry Strategy:**
```
Retry attempt:    1    2    3    4    5
Wait time (sec):  2    4    8   16   32
After 5 failures: Manual user intervention required (UI prompt)
Max queue size:   1000 items (breach → user notification + oldest purged)
```

**Offline Duration Limits:**
- Recommended: < 24 hours (cache freshness degrades)
- Hard limit: None (data persists indefinitely locally)
- User warning: Shown if offline > 1 hour

### 6.3 Sécurité

**Authentication & Authorization:**
- Firebase Auth (email/password) - handles JWT
- TokenService: Manages local JWT storage + refresh (see section 7 - **refresh logic TO BE DOCUMENTED**)
- OTP (PBKDF2) für admin-only operations: user CRUD, role changes - **Currently optional, not enforced**
- Password hashing (Drift): PBKDF2 (2^16 iterations) for password validation

**Request Security:**
- Rate limiting: 10 failed login attempts/15min per user (LoginAttempts table, app-side enforcement)
- Audit logs: All mutations logged (user, action, timestamp, details JSON)
- Firestore rules: Collection-level + document-level access control (see section 7 - **rules untested**)
- CORS: Enforced server-side (Firestore rules)
- HTTPS: Enforced (Dio + Firestore default)

**Data Protection:**
- User passwords: PBKDF2 hashed before storage
- Sensitive fields (email, phone): Indexed for search, not exposed in audit logs
- Tokens: Stored in SharedPreferences (device-encrypted on Android/iOS)

### 6.4 Scalabilité

- Database schema versionned: Current v14 (migration path documented in schema migration file)
- Drift migrations: Auto-applied on app launch (schema_v[N].dart files)
- Firestore collections: Flat structure (denormalization applied where necessary for read perf)
- Sharding: Possible par userId (not implemented, Firestore handles auto-scaling)
- No hard limits per user: Cloud scalable (Firestore pricing-bound)
- Expected scale: < 1000 users per club, < 100 courts

---

## 7. Current Technical Challenges

### 7.1 RÉSOLUS depuis v23

| Challenge | Ancien statut | Statut actuel |
|-----------|--------------|---------------|
| SyncQueue retry logic | Incomplete | Supprimé — remplacé par FirebaseCacheService |
| Admin setup auto-detection | Missing | Implémenté (setupStatusProvider + setupStatusStreamProvider) |
| Concurrent writes | Not handled | Non applicable — Firebase est source de vérité |
| Stream migration | Partial | Tous les providers de données sont StreamProvider |
| FirebaseCacheService resilience | Missing | Auto-restart + backoff exponentiel + reconnexion réseau |

### 7.2 En cours / À faire

| Challenge | Status | Priority |
|-----------|--------|----------|
| Firestore security rules validation | No tests | HIGH |
| Token refresh strategy documentation | Undefined | MEDIUM |
| Weather API fallback | Partial | MEDIUM |
| Null safety audit complet | Partiel | MEDIUM |
| Premium features (feature flags) | Non-implémenté | LOW |
| Export CSV | Non-implémenté | LOW |
| Firebase Emulator setup (CI) | Non-configuré | HIGH |

### 7.3 Refactors Prévus (Checklist mise à jour)

- [x] Implement setupStatusProvider + GoRouter conditional routing — FAIT
- [x] Complete SyncQueue retry logic — Supprimé (FirebaseCacheService)
- [x] Migrate providers — tous en StreamProvider
- [ ] [HIGH] Document + test Firestore security rules (Emulator)
- [ ] [HIGH] Document TokenService JWT refresh strategy
- [ ] [MEDIUM] Implement Weather API fallback with TTL caching
- [ ] [MEDIUM] Null safety audit + strict-casts enabled
- [ ] [LOW] Premium features (feature flags) system design
- [ ] [LOW] Export CSV rapports

---

## 8. Database Schema Overview

### 8.1 Current Version: v24

### Changelog
- **v24:** Terrains — colonnes closureReason (TEXT nullable) et closureUntil (DATETIME nullable). Permet la fermeture manuelle par un agent depuis le dashboard (raison + duree estimee).
- **v23:** Performance : index non-unique sur firebaseId (maintenances, terrains, stock_items, events) et firestoreUid (users). Accélère tous les upserts FirebaseCacheService.
- **v22:** Suppression SyncQueue table, syncStatus columns, pendingSync columns, lastSyncedAt columns. Firebase devient source de vérité.
- **v20:** users.status (active|inactive|rejected), users.approvedAt, users.approvedBy.

**Tables:**

| Table | Rows (estimate) | Key | Notes |
|-------|-----------------|-----|-------|
| users | 10-100 | id (String PK) | Firebase UID sync |
| terrains | 5-50 | id (int PK auto) | firebaseId indexé |
| stock_items | 50-500 | id (int PK auto) | firebaseId indexé |
| stock_movements | 1000+ | id (int PK auto) | Append-only history |
| maintenances | 500+ | id (int PK auto) | firebaseId indexé |
| reservations | 10000+ | id (int PK auto) | Calendar data |
| events | 100+ | id (int PK auto) | firebaseId indexé |
| audit_logs | 5000+ | id (int PK auto) | Immutable (no deletes) |
| login_attempts | 10000+ | id (int PK auto) | Rate limiting |
| otp_records | 100+ | id (int PK auto) | Admin security |

Colonnes supprimées depuis v22 : syncStatus, pendingSync, lastSyncedAt, lastModifiedBy — supprimés de toutes les tables
Table supprimée depuis v22 : SyncQueueTable — supprimée (remplacée par FirebaseCacheService)

**Constraints:**
- Foreign keys: **ENABLED** (integrity enforced)
- CASCADE delete: Terrain → Maintenances, Terrain → Reservations, Terrain → Events, User → AuditLogs
- ON CONFLICT strategy:
  - REPLACE: SyncQueue (idempotent upserts)
  - FAIL: Validations (referential integrity)
  - IGNORE: LoginAttempts (logging non-critical)

**Data integrity:**
- Email unique (users table)
- Terrain name unique (per club - TODO: verify club context)
- Foreign key constraints enforced (Drift default)
- Timestamps: ISO 8601 format (Dart DateTime serialized)

---

## 9. Firestore Schema

### 9.1 Collections & Sync Strategy

**Overall strategy:** Firebase (Firestore) = Source de vérité. Drift = Cache local lecture seule, alimenté par FirebaseCacheService via listeners temps réel.

| Collection | Document path | Document structure | Sync source | Sync direction |
|------------|---|---|---|---|
| **users** | users/{userId} | {id, email, fullName, role, createdAt, updatedAt} | Drift (local source) | **Drift → Firestore (push-only)** |
| **terrains** | terrains/{terrainId} | {id, name, surface, type, coordinates, status, lastMaintenance, updatedAt} | Drift | **Drift ↔ Firestore (bidirectional)** |
| **stock** | stock/{itemId} | {id, name, quantity, minThreshold, unit, category, isCustom, sortOrder, updatedAt} | Drift | **Drift → Firestore (push-only, Drift is master)** |
| **stock_movements** | stock/{itemId}/movements/{movementId} | {id, itemId, quantity, type, timestamp, userId, reason, updatedAt} | Drift | **Append-only (Drift → Firestore)** |
| **maintenances** | maintenances/{maintenanceId} | {id, terrainId, type, description, scheduledDate, completedDate, cost, notes, updatedAt} | Drift | **Drift ↔ Firestore (bidirectional)** |
| **reservations** | reservations/{reservationId} | {id, terrainId, startTime, endTime, userName, status, updatedAt} | Drift | **Drift ↔ Firestore (bidirectional)** |
| **events** | events/{eventId} | {id, terrainId, title, description, startTime, endTime, updatedAt} | Drift | **Drift ↔ Firestore (bidirectional)** |
| **audit_logs** | audit_logs/{logId} | {id, userId, action, resource, resourceId, timestamp, details (JSON), createdAt} | Drift | **Append-only (Drift → Firestore, immutable)** |

### 9.2 Sync Mechanism (v23)

**Write flow:**
UI action -> AsyncNotifier -> Repository.addX/updateX/deleteX() -> Firestore -> listener FirebaseCacheService -> Drift -> UI rebuilt

**Read flow:**
UI -> ref.watch(xxxProvider) -> StreamProvider -> Drift stream -> UI

**FirebaseCacheService:**
- Seul composant autorisé à écrire dans Drift
- Démarre dans AuthNotifier.signIn() via cacheService.startListening()
- S'arrête dans AuthNotifier.signOut() via cacheService.stopListening()
- Resilience : auto-restart avec backoff exponentiel (3s->6s->12s->24s->30s cap)
- Reconnexion réseau : startConnectivityMonitoring() appelé à la connexion

**Exception firebaseId :**
Après chaque addX(), l'AsyncNotifier persiste immédiatement le firebaseId dans Drift sans attendre le listener.

### 9.3 Conflict Resolution

**Stratégie actuelle :** Non applicable.
Firebase est source de vérité unique. Les conflits entre devices sont gérés nativement par Firestore. Drift reçoit toujours la version Firestore via FirebaseCacheService — pas de résolution locale nécessaire.

---

## 10. Key Providers (Riverpod State Management)

### 10.1 Auth & Setup

| Provider | Type | Status | Purpose |
|----------|------|--------|---------|
| authStateProvider | StateNotifierProvider | OK | Auth state + signIn/signOut lifecycle |
| currentUserProvider | Provider<UserEntity?> | OK | Utilisateur connecté courant |
| isAuthenticatedProvider | Provider<bool> | OK | Booléen auth rapide |
| adminExistsProvider | FutureProvider<bool> | OK | Vérifie si admin existe (Firestore + fallback Drift) |
| setupStatusProvider | FutureProvider<SetupStatus> | OK | Statut setup (needsAdminSetup/needsLogin/authenticated/error/loading) |
| setupStatusStreamProvider | StreamProvider<SetupStatus> | OK | Stream continu de setupStatus pour GoRouter |
| pendingUsersProvider | StreamProvider<List<UserEntity>> | OK | Utilisateurs inactifs en attente |
| pendingCountProvider | Provider<int> | OK | Nombre d'utilisateurs en attente |
| userApprovalNotifierProvider | AsyncNotifierProvider | OK | approveUser/rejectUser |

---

### 10.2 Domain Data

| Provider | Type | Status | Purpose |
|----------|------|--------|---------|
| databaseProvider | Provider<AppDatabase> | OK | Singleton Drift |
| stockItemsProvider / stockProvider | StreamProvider<List<StockItem>> | OK | Stream Drift stock items |
| filteredStockItemsProvider | StreamProvider<List<StockItem>> | OK | Stock avec filtres |
| lowStockItemsProvider | StreamProvider<List<StockItem>> | OK | Items quantity < minThreshold |
| terrainsProvider | StreamProvider<List<Terrain>> | OK | Stream Drift terrains |
| eventsProvider | StreamProvider<List<AppEvent>> | OK | Stream Drift events |
| maintenancesProvider | StreamProvider | OK | Maintenances depuis Drift |
| clubInfoProvider | StreamProvider<ClubInfo?> | OK | Info club depuis Firestore |
| clubLocationFromInfoProvider | Provider<ClubLocation?> | OK | Coordonnées GPS club |
| weatherForClubProvider | FutureProvider.family | OK | Météo selon localisation |
| firebaseCacheServiceProvider | Provider<FirebaseCacheService> | OK | Singleton cache service |

---

### 10.3 Services

| Provider | Type | Status | Purpose |
|----------|------|--------|---------|
| firebaseCacheServiceProvider | Provider<FirebaseCacheService> | OK | Singleton — listeners Firestore -> Drift |
| isOnlineStatusProvider | StreamProvider<bool> | OK | Connectivité réseau (connectivity_plus) |

SUPPRIMÉS depuis v22 :
- firebaseSyncServiceProvider — remplacé par FirebaseCacheService
- syncStockProvider — plus de sync manuelle
- syncStatusProvider — plus de SyncQueue
- queueStatusProvider — plus de SyncQueue

---

### 10.4 Admin & Security

| Provider | Type | Status | Purpose | Access |
|----------|------|--------|---------|--------|
| `permissionProvider` | Provider | ✅ | Derive user permissions from role + resource | currentUserProvider (cached) |
| `auditLogsProvider` | FutureProvider | ✅ | Fetch audit logs (admin-only) | Requires currentUserProvider.role = 'admin' |
| `adminProvidersXXX` | Various | ⚠️ | Admin dashboard state (user list, stats, configs) | In progress |

---

### 10.5 UI State

| Provider | Type | Status | Purpose | Notes |
|----------|------|--------|---------|-------|
| `stockFilterProvider` | StateProvider | ✅ | Current filter (all\|lowStock\|fixed\|custom) | Mutable state |
| `stockSearchQueryProvider` | StateProvider | ✅ | Current search string | Mutable state |
| `appSettingsProvider` | StateProvider | ✅ | App preferences (theme, language, etc) | Persisted to SharedPreferences |

---

## 11. External Dependencies

### 11.1 Critical (App won't run without)

```yaml
flutter_riverpod:    ^2.4.0    # State management
drift:               ^2.13.0   # Local database (Moor fork)
firebase_core:       ^2.24.0   # Firebase SDK init
firebase_auth:       ^4.15.0   # Authentication
cloud_firestore:     ^4.13.0   # Cloud Firestore
go_router:           ^10.0.0   # Declarative routing
google_fonts:        ^6.0.0    # Typography
```

### 11.2 Important (Functional features)

```yaml
dio:                 ^5.3.0    # HTTP client
freezed:             ^2.4.0    # Code generation (data classes)
json_serializable:   ^6.7.0    # JSON codecs
http:                ^1.1.0    # Additional HTTP utilities
intl:                ^0.19.0   # Internationalization
flutter_localizations: (from SDK)  # Locale support
```

### 11.3 Optional (UX/Polish)

```yaml
google_maps_flutter: ^2.5.0    # Maps (conditionally used - not in all features)
charts_flutter:      ^0.12.0   # Charts for stats
table_calendar:       ^3.0.0    # Calendar widget
share_plus:          ^7.0.0    # Share functionality
```

### 11.4 Development Dependencies

```yaml
build_runner:        ^2.x      # Code generation runner
drift_dev:           ^2.x      # Drift code gen
riverpod_generator:  ^2.x      # Riverpod code gen
```

---

## 12. Build & Deployment

### 12.1 Build Configurations

| Mode | Settings | Use case |
|------|----------|----------|
| **debug** | Logs enabled, JIT, no obfuscation | Development, hot reload |
| **profile** | Performance monitoring, no obfuscation, optimization | Performance testing |
| **release** | No logs, obfuscation enabled, maximum optimization | Production deployment |

### 12.2 CI/CD

**Current state:** Minimal automation

| Tool | Status | Role |
|------|--------|------|
| GitHub Actions | ⚠️ Basic | update-context.yml only (not deployment) |
| Firebase Emulator | ❌ Not configured | Auth + Firestore testing |
| Unit tests | ❌ Minimal | Validators, permission logic only |
| Widget tests | ❌ None | No UI tests |
| Integration tests | ❌ None | No end-to-end tests |

**Manual process:**
1. Developer builds: `flutter build apk/aab`
2. Manual Firebase deployment (credentials required)
3. Manual App Store / Play Store submission

### 12.3 Version Management

| Component | Strategy | Owner |
|-----------|----------|-------|
| **App version** | Manual in 

pubspec.yaml

 | Developer |
| **Database schema** | Auto via Drift migrations (v13 → v14) | Drift code gen |
| **API version** | Firebase config (feature flags) | Backend team (Firebase Console) |
| **Dependencies** | 

pubspec.yaml

 (semantic versioning) | Developer |

---

## 13. Known Limitations & Workarounds

| Limitation | Scope | Severity | Current workaround | Status |
|-----------|-------|----------|-------------------|--------|
| **Concurrent writes** | Multi-device sync | 🔴 CRITICAL | last-write-wins (data loss) | Planned: optimistic locking |
| **SyncQueue retry** | Offline failures | 🔴 CRITICAL | Manual retry via UI button | Planned: auto-retry v2 |
| **Admin setup UX** | First-time onboarding | 🟠 HIGH | Manual page navigation | Planned: setupStatusProvider |
| **Weather API downtime** | Feature availability | 🟡 MEDIUM | Cached data + warning | Partial: TTL caching 24h |
| **Firestore rules** | Security | 🟠 HIGH | Untested rules (risky) | Planned: Emulator tests |
| **Token refresh** | Auth persistence | 🟡 MEDIUM | **Undefined** (see section 7.7) | Pending documentation |
| **Offline queue overflow** | SyncQueue > 1000 items | 🟡 MEDIUM | Manual intervention | Alert user, oldest items purged |
| **Firestore rate limit** | Peak usage (10k+ writes/sec) | 🟡 MEDIUM | Exponential backoff | Backoff strategy hardcoded (see section 7.1) |
| **Stock merge complexity** | Multi-location inventory | 🟡 MEDIUM | Drift master + last-write-wins | Acceptable for MVP |

---

## 14. Testing Status

| Level | Type | Status | Coverage |
|-------|------|--------|----------|
| **Unit** | Validators, PermissionResolver, StockCategorizer | ⚠️ Minimal | ~10% |
| **Widget** | UI components (buttons, forms, cards) | ❌ None | 0% |
| **Integration** | End-to-end flows (login → stock CRUD) | ❌ None | 0% |
| **Firebase** | Firestore rules, Auth emulation | ❌ Not configured | 0% |
| **Manual** | Ad-hoc testing by developers | ✅ Ongoing | Varies |

**Required for production:**
- [ ] Firebase Emulator setup (auth + Firestore)
- [ ] Widget tests for critical UI (login, stock screen)
- [ ] Integration tests for sync flow
- [ ] Firestore rules validation tests

---

## 15. Metrics & Monitoring

### 15.1 Currently Collected

- Firebase Analytics: Event tracking (optionnal, not critical)
- Audit logs: All mutations (user, action, timestamp, resource)
- Sync metrics: Success/failure rates (logs only, not dashboarded)

### 15.2 Not Implemented

- Crashlytics: Error tracking
- Performance Monitoring: Latency, frame drops
- Custom Analytics Dashboard: Sync stats, user activity
- Error Reporting: Sentry or equivalent

---

## 16. Contact Points & Ownership

| Domain | Owner | Status | Last update |
|--------|-------|--------|------------|
| **Auth & Security** | Firebase + TokenService | ⚠️ Stable (refresh logic undefined) | TBD |
| **Stock Management** | Drift + Firestore (async) | ✅ MVP complete (edge cases pending) | 2024-01-XX |
| **Maintenance Tracking** | Drift CRUD + history | ✅ MVP complete | 2024-01-XX |
| **Terrain Management** | Drift + geocoordinates | ✅ MVP complete | 2024-01-XX |
| **Reservations** | Drift calendar view | ✅ MVP complete (conflict detection: TBD) | 2024-01-XX |
| **Weather Integration** | OpenWeather/Meteoblue API | ⚠️ Stable (no fallback spec) | 2024-01-XX |
| **Admin Dashboard** | Riverpod providers | 🔄 In progress | 2024-01-XX |
| **Sync Infrastructure** | SyncQueue + FirebaseSyncService | ⚠️ v14 schema (retry logic incomplete) | 2024-01-XX |

---

## 17. Appendix: Clarifications & Definitions

### 17.1 Terminology

- **Offline-first:** App functions locally, syncs to cloud when connection available
- **Last-write-wins:** Conflict resolution: latest timestamp overrides earlier timestamp
- **Optimistic locking:** Version field incremented per mutation, prevents concurrent overwrites
- **Soft-delete:** Logical delete (flag), data retained for audit
- **Append-only:** Historical table never modified/deleted (audit trail)
- **Idempotent:** Same operation repeated = same result
- **Exponential backoff:** Retry delays grow (2s, 4s, 8s, 16s, 32s)

### 17.2 Key Files Reference

| Responsibility | File path | Status |
|---|---|---|
| Auth flow | lib/features/auth/providers/auth_providers.dart | OK |
| Auth pages | lib/features/auth/presentation/pages/ | OK |
| Setup detection | lib/features/auth/providers/setup_providers.dart | OK |
| Admin dashboard | lib/features/admin/presentation/pages/ | OK |
| Router | lib/core/router/app_router.dart | OK |
| Firebase Cache Service | lib/data/services/firebase_cache_service.dart | OK |
| Database | lib/data/database/app_database.dart | OK v23 |
| Stock screen | lib/features/inventory/presentation/screens/ | OK |
| Permission logic | lib/domain/logic/permission_resolver.dart | OK |
| Token service | lib/core/security/token_service.dart | WARN: Refresh logic à documenter |
| Firestore rules | firestore.rules (root) | NOK: Non testées |
| Settings screen | lib/features/settings/presentation/screens/ | OK |
| Weather screen | lib/features/weather/presentation/screens/ | OK |
| Club info repository | lib/data/repositories/club_info_repository_impl.dart | OK |
| Nominatim service | lib/data/services/nominatim_service.dart | OK |
| Club info provider | lib/features/admin/providers/club_info_provider.dart | OK |
| Shared widgets | lib/shared/widgets/ | OK |
| Theme | lib/core/theme/app_theme.dart + dashboard_theme_extension.dart | OK |

---

**Document généré:** 2024 - Valid pour Riverpod 2.4.x, Drift 2.13.x, Flutter 3.x
**Last reviewed:** [DATE]
**Next review:** [AFTER CRITICAL FIXES COMPLETED]
```
