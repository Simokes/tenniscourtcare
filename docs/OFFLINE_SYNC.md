# Offline-First Synchronization System

## Overview

The CourtCare application implements a robust **write-local-first** synchronization system that ensures data integrity and optimal user experience, even in poor network conditions.

### Key Principle
```
User Action → Write to Local DB (Drift) → Instant Feedback
                                        ↓
                              Background Sync to Firestore
```

---

## Architecture

### Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    User Action (UI)                         │
├─────────────────────────────────────────────────────────────┤
│ Create/Update/Delete Maintenance, Terrain, StockItem, Event │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
         ┌──────────────────────────┐
         │  Write to Local DB       │
         │  (Drift - Synchronous)   │
         │                          │
         │  ✅ Instant feedback     │
         │  ✅ ACID guarantee       │
         └────────┬─────────────────┘
                  │
                  ▼
    ┌─────────────────────────────┐
    │  Insert into SyncQueue      │
    │  (Deferred Sync Task)       │
    │                             │
    │  - action: create/update... │
    │  - status: pending          │
    │  - retryCount: 0            │
    └────────┬────────────────────┘
             │
             ▼ (Periodic or On-Demand)
  ┌──────────────────────────────┐
  │  FirebaseSyncService.syncAll()
  │                              │
  │  - Deduplication (delete wins)
  │  - Upsert logic (no duplicates)
  │  - Per-entity sync status    │
  └────────┬─────────────────────┘
           │
           ▼
 ┌─────────────────────────────┐
 │  Firestore Update           │
 │  (onConflict: DoUpdate)     │
 │                             │
 │  ✅ Last-write-wins         │
 │  ✅ No UNIQUE errors        │
 │  ✅ Audit logged            │
 └────────┬────────────────────┘
          │
          ▼
   ┌──────────────────────┐
   │ Update syncStatus    │
   │ in Local DB          │
   │                      │
   │ "local" → "synced"   │
   │ or "error"           │
   └──────────────────────┘
```

---

## Components

### 1. **AppDatabase (Drift ORM)**

**File:** `lib/data/database/app_database.dart`

**Responsibility:** Single source of truth for local data

**Key Tables:**
- `terrains` - Court definitions
- `maintenances` - Court maintenance records
- `stock_items` - Inventory management
- `events` - Calendar events
- `users` - User accounts
- `sync_queue` - Pending sync tasks
- `stock_movements` - Audit trail for stock changes

**Sync Columns (all tables):**
```dart
// Schema v17 additions
Column syncStatus;    // local, syncing, synced, error
Column firebaseId;    // Firestore document ID
Column createdBy;     // User who created
Column modifiedBy;    // User who last modified
```

**Key Methods:**
```dart
// Write operations
Future<void> insertMaintenanceWithStockCheck(Maintenance m);
Future<void> updateTerrain(Terrain t);
Future<void> deleteMaintenance(int id);

// Query operations
Stream<List<Terrain>> watchAllTerrains();
Stream<List<Maintenance>> watchMaintenancesInRange(int from, int to);
Stream<List<AppEvent>> watchAllEvents();

// Sync operations
Future<List<T>> getSyncQueue<T>(String entityType);
Future<void> updateSyncStatus(int id, SyncStatus status);
```

---

### 2. **SyncQueue (Deferred Task Management)**

**File:** 

sync_queue.dart



**Purpose:** Track pending sync operations

**Fields:**
```dart
int id;              // Primary key
String entityType;   // 'terrain', 'maintenance', 'stock_item', 'event'
int entityId;        // Reference to entity
String action;       // 'create', 'update', 'delete'
DateTime createdAt;  // When queued
int retryCount;      // Attempts made
DateTime? nextRetryAt; // Exponential backoff
String? error;       // Last error message
```

**Deduplication Logic:**
```
Multiple operations on same entity → Keep only last one
If DELETE exists → Delete all others (delete wins)

Example:
Queue: [CREATE(1), UPDATE(1), DELETE(1)]
Deduplicated: [DELETE(1)]
Result: Only DELETE synced to Firebase
```

---

### 3. **FirebaseSyncService (Orchestrator)**

**File:** 

firebase_sync_service.dart



**Responsibility:** Coordinate sync between Drift and Firestore

**Sync Strategy:**

#### Write Operations
```dart
// 1. Write to local DB (immediate)
await _db.into(_db.terrains).insert(terrain.toCompanion());

// 2. Queue for sync
await _queueManager.enqueue(
  entityType: 'terrain',
  entityId: terrain.id,
  action: 'create',
);

// 3. Trigger background sync (non-blocking)
unawaited(_syncService.syncAll());
```

#### Upsert Logic
```dart
// Prevents UNIQUE constraint errors on retry
await _db.into(_db.terrains).insert(
  terrain.toCompanion(includeId: true),
  onConflict: drift.DoUpdate(
    (old) => TerrainsCompanion(
      syncStatus: drift.Value(SyncStatus.synced.name),
      updatedAt: drift.Value(DateTime.now()),
    ),
  ),
);
```

**Key Methods:**
```dart
Future<void> syncAll();           // Sync all queued items
Future<void> syncTerrains();      // Sync specific entity
Future<void> syncMaintenances();
Future<void> syncStockItems();
Future<void> syncEvents();

Stream<SyncStatus> watchSyncStatus(); // UI updates
```

---

### 4. **QueueManager (Deduplication & Retry)**

**File:** `lib/services/queue/queue_manager_advanced.dart`

**Responsibility:** Manage sync queue with smart deduplication and retry logic

**Features:**

#### Deduplication
```dart
// Delete action "wins" over create/update
List<QueueItem> _deduplicateQueue(List<QueueItem> items) {
  final grouped = groupBy(items, (item) => item.entityId);
  
  return grouped.entries.map((entry) {
    final itemsForEntity = entry.value;
    
    // If DELETE exists, keep only DELETE
    final deleteItem = itemsForEntity
        .firstWhereOrNull((i) => i.action == 'delete');
    
    if (deleteItem != null) {
      return [deleteItem];
    }
    
    // Otherwise keep LAST (most recent) action
    return [itemsForEntity.last];
  }).expand((x) => x).toList();
}
```

#### Exponential Backoff
```dart
// Retry delays: 1s, 2s, 4s, 8s (max)
DateTime _calculateNextRetryAt(int retryCount) {
  final delaySeconds = math.min(
    math.pow(2, retryCount - 1).toInt(),
    QueueConfig.maxBackoff.inSeconds,
  );
  return DateTime.now().add(Duration(seconds: delaySeconds));
}
```

**Configuration:**
```dart
class QueueConfig {
  static const maxRetries = 3;
  static const maxBackoff = Duration(seconds: 8);
  static const maxQueueSize = 1000;
  static const largeQueueWarningThreshold = 100;
  static const largeQueueCriticalThreshold = 500;
}
```

---

### 5. **Mappers (Domain Conversions)**

**Files:**
- 

terrain_mapper.dart


- 

maintenance_mapper.dart


- 

stock_item_mapper.dart


- 

event_mapper.dart



**Pattern: Three-way conversion**

```dart
// 1. Model → Domain Entity
class EventMapper {
  static AppEvent toDomain(AppEventModel model) { ... }
}

// 2. Domain Entity → Database Companion
extension AppEventMapperX on AppEvent {
  EventsCompanion toCompanion({bool includeId = true}) { ... }
}

// 3. Database Entity → Domain Entity
extension EventRowMapperX on EventRow {
  AppEvent toDomain() { ... }
}
```

---

### 6. **Connectivity Listener (Auto-Sync)**

**File:** 

main.dart



**Implementation:**
```dart
// Listen for network changes
Connectivity().onConnectivityChanged.listen((result) {
  if (result != ConnectivityResult.none) {
    // Network restored → Auto-sync
    debugPrint('🌐 Network restored, triggering sync...');
    unawaited(syncService.syncAll());
  }
});

// Periodic sync (every 5 minutes)
Timer.periodic(const Duration(minutes: 5), (_) {
  unawaited(syncService.syncAll());
});
```

---

## Sync Status Lifecycle

```
┌─────────┐
│  LOCAL  │  Entity created/updated locally
│         │  Not yet sent to Firestore
└────┬────┘
     │
     ▼
┌─────────┐
│ SYNCING │  Queued for upload
│         │  Background sync in progress
└────┬────┘
     │
  ┌──┴──────────────┐
  │                 │
  ▼                 ▼
┌────────┐      ┌───────┐
│ SYNCED │      │ ERROR │
│        │      │       │
│Success!│      │Retry? │
└────────┘      └───┬───┘
                    │
              Exponential Backoff
              (1s, 2s, 4s, 8s)
                    │
              If retry_count < 3
                    │
                    ▼
              Back to SYNCING
                    │
              If retry_count >= 3
                    │
                    ▼
              User notified
              Manual retry option
```

---

## Conflict Resolution Strategy

### Last-Write-Wins

When same entity updated locally and remotely:
```
Local:  Terrain(id=1, name="Court A", updatedAt=2024-01-01T10:00)
Remote: Terrain(id=1, name="Court B", updatedAt=2024-01-01T11:00)

Result: Remote wins (newer timestamp)
        Local DB updated with "Court B"
```

### Business Logic Overrides

**Example: Double-Booking Prevention**

```dart
if (isDoubleBooking) {
  // Don't apply conflict resolution
  // Instead: Notify user, keep in queue for manual intervention
  return false; // Retry later
}
```

---

## Error Handling

### Network Errors
```
❌ Network timeout/unreachable
→ Item stays in queue
→ Exponential backoff retry
→ Auto-retry when network restored
```

### Data Validation Errors
```
❌ Invalid stock quantity (negative)
→ Item rejected at local insertion
→ Error shown to user
→ Never queued for sync
```

### Firestore Errors
```
❌ Permission denied
❌ Quota exceeded
❌ Invalid data type

→ Item marked as ERROR
→ Error message stored in queue
→ User notified
→ Manual retry option provided
```

---

## Monitoring & Debugging

### Debug Logging Format

```dart
🔄 SyncService: Starting sync...          // Start
🏳️ Syncing terrain #123...                // In progress
✅ Terrain #123 synced                     // Success
❌ Error syncing maintenance #45: $error   // Error
🔄 Queue processed: 12 items synced
```

### Queue Monitoring

```dart
// Check queue size
final queueSize = await _db.getSyncQueue().length;

// Watch sync status
ref.watch(syncStatusProvider).whenData((status) {
  debugPrint('Sync status: $status');
});

// Monitor critical queue size
if (queueSize >= QueueConfig.largeQueueCriticalThreshold) {
  // Alert user: "Large sync backlog detected"
  // Trigger manual sync
}
```

---

## Best Practices

### For Developers

✅ **Always use transactions for multi-step operations**
```dart
await _db.transaction(() async {
  await checkAndDecrementStock();
  await insertMaintenance();
  // All-or-nothing
});
```

✅ **Check syncStatus in UI**
```dart
ref.watch(syncStatusProvider).whenData((status) {
  if (status == SyncStatus.syncing) {
    showSyncingIndicator();
  }
});
```

✅ **Never bypass local DB**
```dart
// ❌ DON'T: Upload directly to Firestore
await firestore.collection('terrains').add(data);

// ✅ DO: Write to Drift first
await db.insertTerrain(terrain);
// Sync happens automatically
```

### For Users

✅ **Feature still works offline**
- Create, edit, delete operations work immediately
- No network dependency

✅ **Automatic sync when online**
- No manual "sync" button needed
- Happens automatically in background

✅ **Transparent conflict resolution**
- Last-write-wins ensures no data loss
- Conflicts logged for admin review

---

## Testing Offline Sync

### Manual Test Scenarios

#### Scenario 1: Basic Offline Operation
```
1. Start app in offline mode (Airplane mode ON)
2. Create a maintenance record
3. Observe: Data appears immediately in local list
4. Check: syncStatus = "local"
5. Turn on WiFi
6. Observe: Sync indicator appears briefly
7. Check: syncStatus = "synced"
8. Verify: Data appears in Firestore console
```

#### Scenario 2: Network Flakiness
```
1. Create record online
2. Turn to Airplane mode DURING sync
3. Observe: Sync paused, retry scheduled
4. Turn off Airplane mode
5. Observe: Auto-sync triggered
6. Verify: Record synced successfully
```

#### Scenario 3: Deduplication
```
1. Create maintenance (queue: [CREATE])
2. Update maintenance (queue: [CREATE, UPDATE])
3. Delete maintenance (queue: [CREATE, UPDATE, DELETE])
4. Observe: Only DELETE sent to Firestore
5. Verify: Firestore shows deletion
6. Verify: No "create then update then delete" chain
```

#### Scenario 4: Stock Atomicity
```
1. Create maintenance with stock usage
2. Check: Stock decremented atomically
3. Check: stock_movements audit trail created
4. Simulate sync failure mid-process
5. Verify: Stock restored (rolled back)
6. Verify: No partial updates
```

---

## Troubleshooting

### Sync Stuck in "SYNCING" State

**Symptoms:** Status never changes to "synced" or "error"

**Root Cause:** Sync service crashed or network hung

**Solution:**
```dart
// Force retry by invalidating provider
ref.invalidate(syncStatusProvider);

// Or restart sync
await ref.read(firebaseSyncServiceProvider).syncAll();
```

### UNIQUE Constraint Errors

**Symptoms:** Sync fails with "UNIQUE constraint failed"

**Root Cause:** Entity with same ID already exists

**Solution:**
```dart
// Upsert pattern handles this automatically
onConflict: drift.DoUpdate((old) => ...)

// If persists: Check for duplicate IDs in local + remote
```

### Queue Growing Unbounded

**Symptoms:** SyncQueue table grows, never decreases

**Root Cause:** Sync service not running or persistent error

**Solution:**
```dart
// Check if sync service is active
final status = ref.watch(syncStatusProvider);
if (status == SyncStatus.error) {
  // Manual sync trigger needed
  await syncService.syncAll();
}

// Monitor queue size
final count = await db.getSyncQueue().length;
if (count > 100) {
  // Alert admin
}
```

---

## Future Improvements

- [ ] Implement selective sync (only changed fields)
- [ ] Add conflict resolution UI for critical conflicts
- [ ] Implement local encryption for sensitive data
- [ ] Add bandwidth throttling for mobile networks
- [ ] Implement bidirectional sync (remote → local pull)
- [ ] Add analytics for sync performance metrics

---

## References

- Architecture: `/architecture.md`
- Code Style: `/coding_rules.md`
- AI Rules: `/ai_rules.md`
- Database Schema: 

app_database.dart


- Sync Service: 

firebase_sync_service.dart

