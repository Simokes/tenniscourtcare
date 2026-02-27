# Troubleshooting Guide

## Common Issues & Solutions

---

## Sync Issues

### Issue 1: Sync Stuck in "SYNCING" State

**Symptoms:**
- Sync indicator never disappears
- Status frozen as "syncing" for > 5 minutes
- No data synced to Firestore

**Root Causes:**
1. Sync service crashed
2. Network hung (not timeout, just frozen)
3. Database lock contention
4. Large batch operation (1000+ items)

**Diagnosis:**
```dart
// Check sync service status
final syncService = ref.read(firebaseSyncServiceProvider);
final status = await syncService.watchSyncStatus().first;
debugPrint('Sync status: $status');

// Check database lock
final isLocked = await db.transaction(() async {
  return true; // If this completes, DB is responsive
});

// Check queue size
final queueSize = await db.select(db.syncQueue).get().length;
debugPrint('Queue size: $queueSize');
```

**Solutions:**

**Solution A: Force Retry**
```dart
// Invalidate provider to restart
ref.invalidate(syncStatusProvider);
ref.invalidate(firebaseSyncServiceProvider);

// Manually trigger sync
await ref.read(firebaseSyncServiceProvider).syncAll();
```

**Solution B: Clear Stuck Queue Items**
```dart
// Mark items as error (if truly stuck for > 30 mins)
await db.update(db.syncQueue).replace(
  QueueItemCompanion(
    status: drift.Value('error'),
    error: drift.Value('Manual clearance: stuck for 30+ minutes'),
  ),
);
```

**Solution C: Restart App**
```
1. Force close app
2. Reopen
3. Sync should restart automatically
4. If issue persists, clear app cache:
   Settings → Apps → CourtCare → Storage → Clear Cache
```

---

### Issue 2: Duplicate Records in Firestore

**Symptoms:**
- Same record appears 2-3 times in Firestore
- IDs partially overlap (id_1, id_1, id_1_2)
- Manual deduplication needed in Firebase Console

**Root Cause:**
Sync retry without proper upsert handling → Multiple inserts instead of updates

**Solution:**
```dart
// Verify upsert logic in FirebaseSyncService
await _db.into(_db.terrains).insert(
  terrain.toCompanion(includeId: true),
  onConflict: drift.DoUpdate(  // ← Must have this
    (old) => TerrainsCompanion(
      syncStatus: drift.Value(SyncStatus.synced.name),
      updatedAt: drift.Value(DateTime.now()),
    ),
  ),
);

// Or use merge instead of set
await FirebaseFirestore.instance
    .collection('terrains')
    .doc(terrain.firebaseId)
    .set(terrainData, SetOptions(merge: true));  // ← merge: true
```

---

### Issue 3: Data Loss on Sync

**Symptoms:**
- Local data appears, then disappears after sync
- Firestore data different from local
- User reports missing records

**Root Causes:**
1. Conflict resolution overwriting with old data
2. Delete action accidentally applied
3. Transaction rollback due to error

**Solution:**

**Step 1: Check audit trail**
```dart
// Review stock_movements (audit log)
final movements = await db.select(db.stockMovements).get();
for (final m in movements) {
  debugPrint('''
    Type: ${m.type} (add/subtract/delete)
    Item: ${m.itemId}
    Quantity: ${m.quantity}
    Timestamp: ${m.createdAt}
  ''');
}
```

**Step 2: Check sync queue**
```dart
// Look for DELETE actions
final deletes = await (db.select(db.syncQueue)
    ..where((q) => q.action.equals('delete')))
    .get();
    
for (final d in deletes) {
  debugPrint('Unexpected delete: ${d.entityType} #${d.entityId}');
}
```

**Step 3: Restore from backup**
```
Firebase Console → Firestore → Backups
- Create on-demand backup
- Restore to point-in-time before data loss
- Notify users of temporary inconsistency
```

---

## Network Issues

### Issue 4: Network Timeout Loops

**Symptoms:**
- Constant retry messages in logs
- Battery drains quickly
- Network usage spikes

**Root Cause:**
Server timeout (> 30s) being treated as network error → Infinite retries

**Solution:**

**Increase timeout threshold:**
```dart
// In QueueManager
static const networkTimeout = Duration(seconds: 60); // Increase from 30s

// Apply to Firestore calls
final futures = Future.wait([
  _firestore.collection('terrains').add(data)
      .timeout(networkTimeout),
  // ...
], eagerError: true);
```

**Monitor timeout patterns:**
```dart
// Log timeouts for analysis
try {
  await operation().timeout(Duration(seconds: 30));
} on TimeoutException catch (e) {
  debugPrint('⏱️ Timeout detected: Operation took > 30s');
  // Increase timeout intelligently
  if (queueManager.queueSize > 500) {
    // Large queue = expect slow operations
    networkTimeout = Duration(seconds: 120);
  }
}
```

---

### Issue 5: Sync Fails in Specific Network

**Symptoms:**
- Works on WiFi, fails on 4G
- Works at home, fails at office
- Works in some countries, not others

**Root Causes:**
1. Firewall blocking Firebase ports
2. Corporate VPN interference
3. Regional CDN issues
4. DNS resolution problems

**Diagnosis:**
```bash
# Test Firebase connectivity
adb shell ping firebase.google.com
# Should get responses

# Test Firestore connection
adb shell netstat | grep firestore
# Should see established connections

# Check DNS resolution
adb shell getprop | grep net.dns
# Should resolve to real IPs
```

**Solutions:**

**Solution A: Allow Firebase Ports**
```
Firewall rules to allow:
- *.firebaseio.com:443 (Firestore)
- *.googleapis.com:443 (Google APIs)
- *.firebase.google.com:443 (Firebase services)
```

**Solution B: Use Firebase Emulator**
```bash
# For testing in restricted networks
firebase emulators:start --import ./data.json
```

**Solution C: Implement VPN Bypass**
```dart
// For users in restricted networks
Future<void> configureFirebase() async {
  if (isInRestrictedNetwork()) {
    // Use alternative sync mechanism
    // (Requires backend support)
    enableCloudMessagingFallback();
  }
}
```

---

## Database Issues

### Issue 6: Database Locked Error

**Symptoms:**
- "database is locked" error in logs
- Writes fail intermittently
- Reads timeout

**Root Cause:**
Concurrent write operations or long-running transaction blocking

**Solution:**

**Reduce transaction scope:**
```dart
// ❌ BAD: Long transaction
await db.transaction(() async {
  for (final item in largeList) {  // 1000+ items
    await db.into(db.terrains).insert(item.toCompanion());
  }
});

// ✅ GOOD: Batch insert
await db.batch((batch) {
  for (final item in largeList) {
    batch.insertAll(db.terrains, [item.toCompanion()]);
  }
});
```

**Enable WAL (Write-Ahead Logging):**
```dart
// In app_database.dart
@override
Future<void> open() async {
  return super.open()
      .then((db) => db.customStatement('PRAGMA journal_mode = WAL'));
}
```

---

### Issue 7: SyncQueue Growing Unbounded

**Symptoms:**
- SyncQueue table has 1000+ items
- App gets slow
- Sync never catches up

**Root Causes:**
1. Persistent sync failures
2. Sync service not running
3. Deduplication not working

**Solution:**

**Step 1: Diagnose sync health**
```dart
// Check if sync service is active
final lastSync = await db
    .select(db.syncQueue)
    .get()
    .then((items) => items
        .map((i) => i.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b));

final age = DateTime.now().difference(lastSync);
if (age.inHours > 4) {
  debugPrint('⚠️ Sync inactive for ${age.inHours} hours');
  // Trigger manual sync
  await syncService.syncAll();
}
```

**Step 2: Check for persistent errors**
```dart
// Find items failing repeatedly
final failedItems = await (db.select(db.syncQueue)
    ..where((q) => q.retryCount.isBiggerThanValue(3)))
    .get();

for (final item in failedItems) {
  debugPrint('''
    Entity: ${item.entityType} #${item.entityId}
    Error: ${item.error}
    Retries: ${item.retryCount}
  ''');
}
```

**Step 3: Prune problematic items**
```dart
// If error is unrecoverable, remove from queue
await (db.delete(db.syncQueue)
    ..where((q) => q.id.equals(problematicItemId)))
    .go();

// User will need to manually re-create if needed
showUserDialog(
  title: 'Sync Error',
  message: 'Unable to sync court data. Please try creating it again.',
);
```

---

## UI/UX Issues

### Issue 8: Sync Indicator Stuck

**Symptoms:**
- Loading spinner never stops
- UI feels frozen
- But data actually synced

**Root Cause:**
Provider not being invalidated after sync completion

**Solution:**
```dart
// In FirebaseSyncService
Future<void> syncAll() async {
  _updateStatus(SyncStatus.syncing);
  
  try {
    // ... sync operations ...
    _updateStatus(SyncStatus.synced);
  } catch (e) {
    _updateStatus(SyncStatus.error);
  } finally {
    // ← Ensure status always updated
    ref.invalidate(syncStatusProvider);  // Force UI update
  }
}
```

---

### Issue 9: Error Messages Not Showing

**Symptoms:**
- Sync fails silently
- No error feedback to user
- Logs show errors, but UI doesn't

**Solution:**
```dart
// Show error snackbar
ref.listen(syncStatusProvider, (prev, next) {
  if (next is SyncStatus.error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sync failed: ${next.error}'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => syncService.syncAll(),
        ),
      ),
    );
  }
});
```

---

## Performance Issues

### Issue 10: App Freezes During Sync

**Symptoms:**
- Main thread blocked for 5-10 seconds
- UI unresponsive during sync
- Jank/stuttering in UI

**Root Cause:**
Sync operations on main thread instead of background

**Solution:**
```dart
// Ensure sync is non-blocking
// ❌ DON'T do this:
await syncService.syncAll();

// ✅ DO this:
unawaited(syncService.syncAll());

// For UI that needs to wait:
ref.watch(syncStatusProvider).whenData((status) {
  if (status == SyncStatus.synced) {
    // Data ready, show it
  }
});
```

---

## Getting Help

### Debug Information to Collect

Before contacting support:

```dart
// Gather diagnostic data
final diagnostics = {
  'appVersion': packageInfo.version,
  'osVersion': Platform.operatingSystemVersion,
  'dbSize': await db.customSelect('SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size();').get(),
  'queueSize': await db.select(db.syncQueue).get().length,
  'lastSyncTime': await getLastSyncTime(),
  'syncErrors': await getSyncErrors(last24Hours: true),
  'networkStatus': await Connectivity().checkConnectivity(),
};

// Share with support team
exportDiagnostics(diagnostics);
```

### Contact Support

**For Sync Issues:**
- Email: support-sync@courcare.app
- Include: Diagnostics above + Logs (Firebase Console)

**For Database Issues:**
- Email: support-db@courcare.app
- Include: Database backup + Error logs

**For Network Issues:**
- Email: support-network@courcare.app
- Include: Network diagnostics + Firewall config

---

## References

- Offline Sync Guide: `/docs/OFFLINE_SYNC.md`
- Architecture: `/architecture.md`
- Firestore Docs: https://firebase.google.com/docs/firestore
- Drift Docs: https://drift.simonbinder.eu/
```

---

## 📝 5. Commit Final Documentation

```bash
git add docs/OFFLINE_SYNC.md
git add docs/TESTING.md
git add docs/DEPLOYMENT.md
git add docs/TROUBLESHOOTING.md

git commit -m "docs: Complete offline-first synchronization documentation

Add comprehensive guides:
- OFFLINE_SYNC.md: Architecture, components, sync lifecycle
- TESTING.md: Unit tests, integration tests, manual testing
- DEPLOYMENT.md: Staging, production, rollout strategy
- TROUBLESHOOTING.md: Common issues, diagnosis, solutions

Covers:
✅ Write-local-first pattern explanation
✅ Exponential backoff retry logic
✅ Queue deduplication strategy
✅ Conflict resolution (last-write-wins)
✅ Network handling & auto-sync
✅ Testing scenarios & benchmarks
✅ Deployment phases & rollout
✅ Monitoring & debugging
✅ Common issues & fixes

For developers, QA, DevOps, and support teams."

git push origin feat/firebase-sync-service-finalize-9602175045496429827
```

---

## ✅ DOCUMENTATION COMPLETE

Tous les guides sont maintenant en place :

| Document | Purpose | Audience |
|----------|---------|----------|
| **OFFLINE_SYNC.md** | How sync works | Developers, Architects |
| **TESTING.md** | How to test | QA Engineers, Developers |
| **DEPLOYMENT.md** | How to release | DevOps, Release Managers |
| **TROUBLESHOOTING.md** | How to fix issues | Support, Developers |

**Ready for production deployment!** 🚀