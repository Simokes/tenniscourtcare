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
- Rôles: admin | manager | user (voir section 2.3)
- Permissions par rôle (voir section 2.3)
- Logs d'audit (toutes mutations)
- Rate limiting: 10 login attempts/15min par user (app-side, Drift table login_attempts)
- OTP (PBKDF2) pour: opérations admin sensibles (user creation, deletion, permission changes) - **optionnel en MVP**

### 2.3 Rôles & Permissions

| Rôle | Accès Lectures | Accès Écritures | Restrictions |
|------|---|---|---|
| **admin** | Tous les domaines | Tous (users, rôles, configurations) | Aucune |
| **manager** | Terrains, Maintenance, Stock, Events | Terrain CRUD, Maintenance CRUD, Stock adjustments | Pas accès Users, Audit logs |
| **user** | Terrains, Maintenance, Stock | Stock movements (read-only views) | Pas création terrain, pas mutation user |

**Implémentation:** `lib/domain/enums/role.dart` + `PermissionResolver` (lib/domain/logic/permission_resolver.dart)

### En cours / Partiellement implémentées

- Premium features (feature flags système - non-implémenté)
- Synchronisation queue avancée: retry logic incomplete (voir section 7)
- Export CSV rapports
- Filtres multi-critères avancés
- Admin setup auto-detection (setupStatusProvider) - **À IMPLÉMENTER EN PRIORITÉ**

---

## 3. Technical Stack

| Couche | Technology | Détails |
|--------|-----------|---------|
| **Framework** | Flutter 3.x | iOS/Android |
| **Language** | Dart 3.x | Null safety, records |
| **State Mgmt** | Riverpod 2.4.x | Provider, FutureProvider, StreamProvider (deprecation: .stream → .future en v3.0) |
| **Local DB** | Drift 2.13.x | SQLite avec typage fort, migrations auto (current: v14) |
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
│   ├── router/          # GoRouter setup + redirect logic (conditional: admin setup → login → home)
│   ├── security/        # Auth validators, rate limiter (LoginAttempts table), token service, auth exceptions
│   └── theme/           # Material theme + extensions
│
├── domain/
│   ├── entities/        # Pure data classes (User, StockItem, Terrain, Maintenance, Reservation, Event, AuditLog, SyncQueue, OtpRecord, LoginAttempt)
│   ├── repositories/    # Abstract interfaces (UserRepository, StockRepository, TerrainRepository, EventRepository, MaintenanceRepository, AuditRepository)
│   ├── services/        # Business logic (WeatherRules, PermissionResolver)
│   └── enums/           # Role (admin|manager|user), Permission (CREATE_USER|DELETE_USER|etc), FeatureFlag
│
├── data/
│   ├── database/        # Drift SQLite (app_database.dart + 11 tables at v14)
│   │   └── tables/      # UsersTable, TerrainTable, StockItemsTable, StockMovementsTable, MaintenancesTable, ReservationsTable, EventsTable, AuditLogsTable, SyncQueueTable, LoginAttemptsTable, OtpRecordsTable
│   ├── firestore/       # Cloud models (sync targets)
│   │   └── models/      # FirebaseUserModel, FirebaseStockModel, FirebaseTerrainModel, etc
│   ├── repositories/    # Implementations (local Drift + Firestore)
│   │   ├── [entity]_repository_impl.dart
│   │   └── firestore/   # Firestore-specific repos (optional for read-heavy queries)
│   ├── services/        # Firebase services (FirebaseSyncService, FirebaseStockService, etc)
│   │   └── firebase_sync_service.dart (SyncQueue orchestrator)
│   └── mappers/         # Entity ↔ DTO conversions (UserMapper, StockItemMapper, etc)
│
├── features/
│   ├── home/            # Dashboard module
│   │   └── presentation/screens + widgets
│   ├── inventory/       # Stock management module
│   │   ├── models/      # stock_filter.dart (enum: all|lowStock|fixed|custom)
│   │   └── presentation/screens (stock_screen, add_edit_stock_item_sheet)
│   ├── weather/         # Weather display module
│   │   └── presentation
│   └── [autres modules]
│
├── presentation/
│   ├── pages/           # Top-level pages (admin_setup_page, login_page, admin_dashboard_page)
│   ├── providers/       # Riverpod providers (auth, stock, terrain, sync, admin, etc)
│   ├── screens/         # Secondary screens (maintenance, settings, stats, calendar)
│   ├── widgets/         # Reusable components (terrain_card, sync_status_indicator, etc)
│   └── utils/           # Helpers (date_utils, csv_export, etc)
│
├── services/            # Cross-cutting services
│   ├── queue/           # QueueManager (v14 schema - retry logic incomplete)
│   └── sync/            # SyncService (offline-first orchestration)
│
├── infrastructure/      # External service adapters
│   └── services/        # ImagePickerService, ShareReportService, WeatherService
│
└── main.dart            # Entry point + ProviderScope + GoRouter setup
```

### Layer Responsibilities

**Domain:**
- Business rules + entity definitions
- Abstract repository interfaces
- Permission/weather logic
- NO database imports, NO Firebase imports

**Data:**
- Drift: Local persistence, auto-migrations (v14)
- Firestore: Cloud sync targets, real-time listeners
- Repositories: Implement domain interfaces
- Mappers: Convert between entities and DTOs
- Services: Firebase-specific orchestration (sync, batch ops)

**Presentation:**
- Riverpod providers: State management (FutureProvider for async data, StreamProvider deprecated)
- UI screens & widgets: Flutter code
- Form validation: Input validation (domain validators injected)
- Navigation: GoRouter declarative routing + conditional redirects

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
admin    → All permissions
manager  → Terrain, Maintenance, Stock mutations
user     → Read-only + StockMovement logging
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

### 7.1 CRITICAL - Sync & Queue Architecture

**Problem:** SyncQueue + retry logic incomplete for production

| Aspect | Status | Detail | Risk |
|--------|--------|--------|------|
| **SyncQueue table** | ✅ Exists (v14) | Stores: operation, entity, entityId, status, retries, lastError | Low |
| **Retry logic** | ❌ Incomplete | Exponential backoff implemented, but NO handling for: Firestore rate limits, network timeout edge cases | **HIGH** |
| **Concurrent writes** | ❌ Not handled | If 2 devices modify same item offline → last-write-wins, prior write **data lost** | **CRITICAL** |
| **Offline persistence** | ⚠️ Partial | Local delete + cloud update = conflict (no resolution strategy) | **HIGH** |
| **Batch limits** | ⚠️ Acknowledged | Firestore max 500 writes/transaction, SyncQueue batching = **hardcoded, not parameterized** | Medium |

**Workarounds (non-optimal):**
- Manual retry via UI button
- Users trained to avoid concurrent edits
- Pending: Implement optimistic locking (version field per entity)

**Fix timeline:** Priority 1 for next release

---

### 7.2 Auth Flow - Admin Setup Missing

**Problem:** First-time setup not automated

| Step | Current | Desired |
|------|---------|---------|
| 1. App start | Shows login screen | Check: admin exists? |
| 2. No admin | Manual redirect to AdminSetupPage | Auto-route to AdminSetupScreen |
| 3. Admin exists | Shows login | Auto-route to LoginScreen |
| 4. User logged in | Shows home | Auto-route to HomeScreen |

**Provider needed:** `setupStatusProvider` (StreamProvider)
```dart
enum SetupStatus { loading, needsAdminSetup, needsLogin, authenticated, error }

// Checks: adminExistsProvider → then authState changes
// Emits: SetupStatus based on (admin exists?, user logged in?)
// Used by: GoRouter.redirect() for conditional routing
```

**Implementation missing:** Routes + provider logic in GoRouter

**Impact:** First-time UX clunky, requires manual navigation

---

### 7.3 Stream Deprecation (Riverpod 3.0)

**Problem:** `.stream` deprecated in Riverpod 3.0, app uses it

| File | Deprecated usage | Replacement | Status |
|------|------------------|-------------|--------|
| `event_provider.dart:33` | `.stream` | `.watch()` or `.future` | 🔄 Pending |
| `maintenance_provider.dart:35` | `.stream` | `.future` | 🔄 Pending |
| `terrain_provider.dart:49` | `.stream` | `.future` | 🔄 Pending |
| `stock_provider.dart:47, 257, 274, 286` | `.stream` (4x) | `.future` | 🔄 Pending |

**Lint warnings:** ~6 info-level warnings currently suppressed

**Action:** Migrate before Riverpod 3.0 release

---

### 7.4 Firestore Security Rules - Untested

**Problem:** Rules exist but no unit tests

**File:** 

firestore.rules

 (root project)

**Coverage:** Collection-level + document-level checks mentioned, but specific rules NOT documented

**Risks:**
- Collections potentially open to unauthorized read/write
- No validation of document structure
- No user ownership checks validated

**Required actions:**
- [ ] Document rules (at least 2-3 examples in PROJECT_SUMMARY)
- [ ] Test with Firebase Emulator
- [ ] Add validation rules (required fields, type checks)

**Example rule structure (TO BE VERIFIED):**
```
match /stock/{itemId} {
  allow read: if request.auth.uid != null;  // Any user
  allow write: if request.auth.uid != null && checkUserRole('manager');  // Manager+ only
}
```

---

### 7.5 Weather API - No Fallback Specified

**Problem:** API downtime → feature breaks

| Scenario | Current behavior | Expected behavior |
|----------|-----------------|-------------------|
| API available | Shows live data | ✅ Works |
| API timeout | Unknown | Cache + "Stale data (24h)" warning |
| API rate limit | Unknown | Cache + "Data offline" banner |
| No cache | First launch offline | Error message (no fallback) |

**Fallback mechanism:**
- Cache: Last successful API call (TTL: 24 hours)
- UI feedback: "⚠️ Last update: 20 hours ago" badge
- **Current code:** WeatherService (lib/features/weather/infrastructure/weather_service.dart) - **implementation details missing**

---

### 7.6 Null Safety - Unsafe Widget Access

**File:** `refill_recommendation_card.dart:32` - `unchecked_use_of_nullable_value`

**Issue:** Potential NPE at runtime if item.minThreshold is null

**Fix:** Null-check before comparison (see section 4: Data Layer responsibility)

---

### 7.7 Token Management - Refresh Logic Undefined

**Provider:** `TokenService` (lib/core/security/token_service.dart)

**Issues:**
- JWT refresh endpoint: **Where is it?** (Firebase? Custom backend?)
- Refresh timing: On expiry? Or proactive before expiry?
- Storage: SharedPreferences (but encryption level?)
- Fallback: If refresh fails, force re-login?

**Impact:** Token expiry could cause silent auth failures

**Required documentation:** Specify Firebase JWT refresh strategy

---

### 7.8 Dette technique identifiée (Résumé)

| Challenge | Status | Priority | Est. effort |
|-----------|--------|----------|------------|
| SyncQueue retry edge cases | ❌ Incomplete | 🔴 CRITICAL | 3-5 days |
| Admin setup auto-detection | ❌ Missing | 🔴 CRITICAL | 1-2 days |
| Concurrent writes conflict | ❌ Not handled | 🔴 CRITICAL | 2-3 days |
| Firestore rules validation | ❌ No tests | 🟠 HIGH | 1-2 days |
| Stream → Future migration | 🔄 Partial | 🟠 HIGH | 1 day |
| Token refresh strategy | ❌ Undefined | 🟡 MEDIUM | 0.5 days |
| Weather API fallback | ⚠️ Partial | 🟡 MEDIUM | 0.5 days |
| Null safety audit | ⚠️ 1 known issue | 🟡 MEDIUM | 0.5 days |

### 7.9 Refactors Prévus (Checklist)

- [ ] **[CRITICAL]** Implement setupStatusProvider + GoRouter conditional routing
- [ ] **[CRITICAL]** Complete SyncQueue retry logic (exponential backoff, rate limit handling, concurrent write detection)
- [ ] **[CRITICAL]** Add optimistic locking (version field on entities)
- [ ] **[HIGH]** Migrate StreamProviders → FutureProviders + listeners
- [ ] **[HIGH]** Document + test Firestore security rules (Emulator)
- [ ] **[HIGH]** Document TokenService JWT refresh strategy
- [ ] **[MEDIUM]** Parameterize retry strategy (backoff multiplier, max attempts)
- [ ] **[MEDIUM]** Add circuit breaker for Firestore failures
- [ ] **[MEDIUM]** Implement Weather API fallback with TTL caching
- [ ] **[MEDIUM]** Null safety audit + strict-casts enabled in 

analysis_options.yaml


- [ ] **[LOW]** Premium features (feature flags) system design

---

## 8. Database Schema Overview

### 8.1 Current Version: v14

**Changelog (v13 → v14):**
- Added: `SyncQueue` table (operations queueing for offline)
- Modified: Added `updatedAt` field to all tables (sync tracking)
- Modified: `StockMovement.reason` nullable (optional movement reason)
- See: `lib/data/database/migrations/` for full schema_v14.dart

**Tables (11 total):**

| Table | Rows (estimate) | Key | Indexes | Notes |
|-------|-----------------|-----|---------|-------|
| **users** | 10-100 | id (String PK) | email (unique), role | Firebase UID sync |
| **terrains** | 5-50 | id (String PK) | name (unique), status | Geo-enabled |
| **stock_items** | 50-500 | id (int PK auto) | name, category, isCustom | No soft-delete |
| **stock_movements** | 1000+ | id (int PK auto) | itemId (FK), timestamp, type | Append-only history |
| **maintenances** | 500+ | id (int PK auto) | terrainId (FK), scheduledDate, status | Soft-delete capable |
| **reservations** | 10000+ | id (int PK auto) | terrainId (FK), startTime, status | Conflict detection possible |
| **events** | 100+ | id (int PK auto) | terrainId (FK), startTime | Calendar data |
| **audit_logs** | 5000+ | id (int PK auto) | userId (FK), timestamp, action | Immutable (no deletes) |
| **sync_queue** | 0-1000 | id (int PK auto) | status, entityId, entity | Offline queue |
| **login_attempts** | 10000+ | id (int PK auto) | userId (soft), timestamp | Rate limiting |
| **otp_records** | 100+ | id (int PK auto) | userId (soft), expiresAt | Admin security |

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

### 9.2 Sync Mechanism

**Overall strategy:** Drift is **primary source of truth** (offline-first), Firestore is **reporting/backup**

**Sync flow:**
1. **Local mutation** (user action in app)
   - Written to Drift immediately (optimistic update)
   - Entry added to SyncQueue (operation: CREATE/UPDATE/DELETE, status: PENDING)
   
2. **Sync trigger** (automatic, on network change or timer)
   - FirebaseSyncService reads SyncQueue (status = PENDING)
   - Batches operations (max 500/batch per Firestore limits)
   - Calls Firestore write operation
   - Updates SyncQueue entry: status = SUCCESS (or FAILED if error)
   
3. **Pull-on-demand** (periodic or user-initiated)
   - App checks Firestore for updates from other devices (not implemented yet)
   - Merges remote updates into Drift (conflict resolution: see section 6.4)

**Push timing:**
- Automatic: On network state change (WiFi/cellular detected)
- Periodic: Background sync every 15 minutes (when app in foreground)
- Manual: User-triggered "Sync now" button

**Pull timing:** (Currently not implemented - Firestore is **write-only** currently)

### 9.3 Conflict Resolution Strategy

**Current:** Last-write-wins (simple, data-loss risk)

**Implementation:** `updatedAt` timestamp compared, highest timestamp wins
- If local.updatedAt > remote.updatedAt → keep local, push to cloud
- If remote.updatedAt > local.updatedAt → keep local (Drift is master, don't pull)

**Limitation:** Multi-device edits → prior write lost (not acceptable for production)

**Planned fix:** Optimistic locking (add `version` field, increment on mutations)

---

## 10. Key Providers (Riverpod State Management)

### 10.1 Auth & Setup

| Provider | Type | Status | Purpose | Dependencies |
|----------|------|--------|---------|--------------|
| `authStateProvider` | StreamProvider | ✅ Exists | Watch Firebase Auth state changes | FirebaseAuth.authStateChanges() |
| `currentUserProvider` | FutureProvider | ✅ Exists | Fetch logged-in user from Drift | authStateProvider + databaseProvider |
| `adminExistsProvider` | FutureProvider | ✅ Exists | Check if admin role exists in users table | databaseProvider |
| `setupStatusProvider` | StreamProvider | ❌ **MISSING** | Emit SetupStatus (needsAdminSetup\|needsLogin\|authenticated) | adminExistsProvider + authStateProvider |

**setupStatusProvider (TO IMPLEMENT):**
```dart
enum SetupStatus { loading, needsAdminSetup, needsLogin, authenticated, error }

final setupStatusProvider = StreamProvider<SetupStatus>((ref) async* {
  final adminExists = await ref.watch(adminExistsProvider.future);
  if (!adminExists) {
    yield SetupStatus.needsAdminSetup;
    return;  // Stop here, don't watch auth
  }
  // Admin exists, watch auth state
  final user = await ref.watch(authStateProvider.future);
  yield user == null ? SetupStatus.needsLogin : SetupStatus.authenticated;
});
```

**Used by:** GoRouter.redirect() for conditional routing

---

### 10.2 Domain Data

| Provider | Type | Status | Purpose | Notes |
|----------|------|--------|---------|-------|
| `databaseProvider` | Provider | ✅ | Singleton Drift instance | Initialized in main() |
| `stockProvider` | FutureProvider | ✅ | All stock items from Drift | Refreshes on mutation |
| `filteredStockItemsProvider` | FutureProvider | ✅ | Stock with filters (category, search, lowStock) | Depends on: stockProvider, stockFilterProvider, stockSearchQueryProvider |
| `lowStockItemsProvider` | FutureProvider | ✅ | Items with quantity < minThreshold | Depends on: stockProvider |
| `criticalStockItemsProvider` | FutureProvider | ✅ | Items with quantity ≤ 5 | Depends on: lowStockItemsProvider |
| `terrainProvider` | FutureProvider | ⚠️ Partial | All terrains from Drift | .stream deprecated (to migrate) |
| `maintenanceProvider` | FutureProvider | ⚠️ Partial | All maintenances from Drift | .stream deprecated (to migrate) |
| `eventProvider` | FutureProvider | ⚠️ Partial | All events from Drift | .stream deprecated (to migrate) |

---

### 10.3 Sync & Services

| Provider | Type | Status | Purpose | Trigger |
|----------|------|--------|---------|---------|
| `firebaseSyncServiceProvider` | Provider | ✅ | Singleton FirebaseSyncService instance | On app init |
| `syncStockProvider` | FutureProvider | ✅ | Manually trigger stock sync to Firestore | User "Sync now" button |
| `syncStatusProvider` | StreamProvider | ⚠️ | Real-time sync status (idle\|in-progress\|queued) | Watches SyncQueue.status changes |
| `queueStatusProvider` | StreamProvider | ⚠️ | SyncQueue statistics (pending count, last sync time) | Watches SyncQueue table |

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
| Auth flow | 

auth_providers.dart

 | ✅ |
| Setup detection | lib/presentation/providers/admin_setup_provider.dart | ❌ TO CREATE |
| Router | 

app_router.dart

 | ⚠️ Needs setupStatusProvider |
| Sync service | 

firebase_sync_service.dart

 | ⚠️ Retry incomplete |
| Database | 

app_database.dart

 | ✅ v14 |
| Stock screen | 

stock_screen.dart

 | ✅ |
| Permission logic | 

permission_resolver.dart

 | ✅ |
| Token service | 

token_service.dart

 | ❌ Refresh logic undefined |
| Firestore rules | 

firestore.rules

 (root) | ❌ Untested |

---

**Document généré:** 2024 - Valid pour Riverpod 2.4.x, Drift 2.13.x, Flutter 3.x
**Last reviewed:** [DATE]
**Next review:** [AFTER CRITICAL FIXES COMPLETED]
```
