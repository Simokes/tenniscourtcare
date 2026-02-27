# Offline Sync Testing Guide

## Overview

This document provides comprehensive testing strategies for the offline-first synchronization system.

---

## Unit Tests

### 1. QueueManager Tests

**File:** `test/services/queue_manager_advanced_test.dart`

```dart
test('Deduplication: Delete action wins', () async {
  // Arrange
  final items = [
    QueueItem(id: 1, action: 'create'),
    QueueItem(id: 1, action: 'update'),
    QueueItem(id: 1, action: 'delete'),
  ];
  
  // Act
  final deduped = queueManager.deduplicateQueue(items);
  
  // Assert
  expect(deduped.length, 1);
  expect(deduped.first.action, 'delete');
});

test('Exponential backoff calculation', () {
  // Retry 1: 1s
  expect(calculateBackoff(1), Duration(seconds: 1));
  
  // Retry 2: 2s
  expect(calculateBackoff(2), Duration(seconds: 2));
  
  // Retry 3: 4s
  expect(calculateBackoff(3), Duration(seconds: 4));
  
  // Retry 4+: capped at 8s
  expect(calculateBackoff(4), Duration(seconds: 8));
});

test('Queue size alerting', () async {
  // Add 500+ items to queue
  for (int i = 0; i < 501; i++) {
    await queueManager.enqueue(...);
  }
  
  // Assert: Critical alert triggered
  expect(await queueManager.isCritical(), true);
});
```

### 2. Mapper Tests

**File:** 

event_mapper_test.dart



```dart
test('EventRow.toDomain() converts all fields', () {
  // Arrange
  final eventRow = EventRow(
    id: 1,
    title: 'Tournament',
    startTime: DateTime(2024, 1, 15),
    // ... all fields
  );
  
  // Act
  final appEvent = eventRow.toDomain();
  
  // Assert
  expect(appEvent.id, 1);
  expect(appEvent.title, 'Tournament');
  expect(appEvent.startTime, DateTime(2024, 1, 15));
});

test('AppEvent.toCompanion() for database insert', () {
  // Arrange
  final appEvent = AppEvent(
    id: 1,
    title: 'Tournament',
    syncStatus: SyncStatus.local,
    // ...
  );
  
  // Act
  final companion = appEvent.toCompanion();
  
  // Assert
  expect(companion.title.value, 'Tournament');
  expect(companion.syncStatus.value, 'local');
});
```

---

## Integration Tests

### 1. Offline to Online Sync Flow

**File:** `test/integration/offline_sync_test.dart`

```dart
testWidgets('Create offline → Sync online flow', 
    (WidgetTester tester) async {
  // Arrange: App in offline mode (Airplane mode)
  await NetworkStub.setOffline();
  await tester.pumpWidget(const CourtCareApp());
  
  // Act: Create maintenance
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byType(TextField),
    'Court maintenance',
  );
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
  
  // Assert: Data appears immediately
  expect(find.text('Court maintenance'), findsOneWidget);
  
  // Verify: syncStatus = local
  final db = ProviderContainer().read(databaseProvider);
  final maintenance = await db.getMaintenanceById(1);
  expect(maintenance.syncStatus, SyncStatus.local);
  
  // Act: Turn on network
  await NetworkStub.setOnline();
  await Future.delayed(const Duration(seconds: 2));
  
  // Assert: Sync triggered, status updated
  expect(maintenance.syncStatus, SyncStatus.synced);
  
  // Verify: Data in Firestore
  final fsDoc = await FirebaseFirestore.instance
      .collection('maintenances')
      .doc(maintenance.firebaseId)
      .get();
  expect(fsDoc.exists, true);
});
```

### 2. Network Flakiness Handling

```dart
testWidgets('Retry with exponential backoff on network failure',
    (WidgetTester tester) async {
  // Arrange
  await NetworkStub.setFlaky(
    failureRate: 0.7, // 70% failure rate
  );
  
  // Act: Create maintenance
  await createMaintenance(tester);
  
  // Assert: Sync retried with increasing delays
  final retries = await syncService.getRetryHistory();
  expect(retries.length, greaterThan(1));
  
  // Verify: Exponential delays
  final delays = [
    retries[1].timestamp - retries[0].timestamp,
    retries[2].timestamp - retries[1].timestamp,
  ];
  
  expect(delays[0].inSeconds, 1); // 1s
  expect(delays[1].inSeconds, 2); // 2s
});
```

---

## Manual Testing

### Pre-Deployment Checklist

#### Network Conditions
- [ ] Test with WiFi disconnected (Airplane mode)
- [ ] Test with WiFi weak signal (-80 dBm)
- [ ] Test with 4G/5G network
- [ ] Test with throttled network (Chrome DevTools)

#### User Workflows
- [ ] Create 10 terrains offline
- [ ] Create 20 maintenances with stock usage
- [ ] Edit 5 events while syncing
- [ ] Delete 3 records during network failure

#### Data Integrity
- [ ] Verify no duplicate records in Firestore
- [ ] Verify no missing records in Firestore
- [ ] Verify no UNIQUE constraint errors
- [ ] Verify stock quantities accurate

#### UI/UX
- [ ] Verify sync indicator appears
- [ ] Verify sync indicator disappears after completion
- [ ] Verify error messages clear
- [ ] Verify no UI freezing during sync

---

## Performance Benchmarks

### Target Metrics

| Metric | Target | Current |
|--------|--------|---------|
| Local write latency | < 100ms | - |
| Sync start latency | < 5s | - |
| Sync rate | > 100 items/min | - |
| Memory overhead | < 50MB | - |
| Battery drain | < 5% per hour | - |

### Measuring Performance

```dart
// Local write latency
final sw = Stopwatch()..start();
await db.insertTerrain(terrain);
sw.stop();
print('Insert latency: ${sw.elapsedMilliseconds}ms');

// Sync throughput
final beforeCount = await db.getSyncQueue().length;
final sw2 = Stopwatch()..start();
await syncService.syncAll();
sw2.stop();
final synced = beforeCount - await db.getSyncQueue().length;
print('Sync rate: ${(synced / sw2.elapsedSeconds).toStringAsFixed(2)} items/s');
```

---

## Test Coverage

### Required Coverage
- [ ] 80%+ for `data/` layer (mappers, database, services)
- [ ] 70%+ for `domain/` layer (entities, repositories)
- [ ] 60%+ for `presentation/` layer (providers, screens)

### Critical Paths (must be 100%)
- [ ] FirebaseSyncService.syncAll()
- [ ] QueueManager deduplication
- [ ] Mappers (toDomain, toCompanion)
- [ ] Database transactions
- [ ] Error handling & retry logic

---

## CI/CD Integration

### GitHub Actions

```yaml
# filepath: .github/workflows/test.yml
name: Test & Analyze

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      
      - name: Get packages
        run: flutter pub get
      
      - name: Run tests
        run: flutter test
      
      - name: Run analysis
        run: flutter analyze
      
      - name: Check coverage
        run: |
          flutter test --coverage
          lcov --summary coverage/lcov.info
```

---

## Debugging Tips

### Enable Verbose Sync Logging

```dart
// In main.dart
if (kDebugMode) {
  FirebaseSyncService.enableVerboseLogging = true;
}

// Output example:
// 🔄 FirebaseSyncService: Sync started
// 🏳️ Processing 5 terrain items...
// ✅ Terrain #1 synced
// ✅ Terrain #2 synced
// 🔄 Processing 3 maintenance items...
// ❌ Maintenance #5: Network timeout
// 🔄 Retrying in 2 seconds...
```

### Inspect SyncQueue

```dart
// Check all queued items
final queue = await db.select(db.syncQueue).get();
for (final item in queue) {
  print('''
    ID: ${item.id}
    Entity: ${item.entityType}
    Action: ${item.action}
    Retries: ${item.retryCount}
    Error: ${item.error}
  ''');
}
```

### Simulate Network Failure

```dart
// In test
await NetworkStub.setOffline();
await syncService.syncAll();
// Verify: Errors logged, queue unchanged
```

---

## References

- Testing Guide: `/TESTING.md`
- Test Files: 

test


- Sync Implementation: 

firebase_sync_service.dart


```

---

## 📝 3. DEPLOYMENT.md

```markdown
# Deployment & Release Guide

## Overview

This document outlines the process for deploying CourtCare offline-first synchronization feature to staging and production environments.

---

## Pre-Deployment Checklist

### Code Quality
```
☐ flutter analyze → 0 ERRORS
☐ flutter test → All tests pass
☐ Code review approved by 2+ team members
☐ No TODO/FIXME comments in critical files
☐ Commit messages clear & descriptive
```

### Testing
```
☐ Manual offline sync testing (4+ scenarios)
☐ Performance benchmarks met
☐ No regressions in existing features
☐ Accessibility testing completed
☐ Internationalization strings updated
```

### Documentation
```
☐ OFFLINE_SYNC.md reviewed
☐ TESTING.md scenarios validated
☐ 

README.md

 updated
☐ Release notes drafted
☐ API documentation updated
```

### Deployment Readiness
```
☐ Database migrations tested
☐ Firebase Firestore rules reviewed
☐ Firebase Auth rules reviewed
☐ CloudFunctions deployed (if any)
☐ Monitoring configured
```

---

## Staging Deployment

### 1. Build APK/IPA

```bash
# Android
flutter build apk --release
# Output: build/app/outputs/flutter-app.apk

# iOS (requires macOS)
flutter build ios --release
# Output: build/ios/Runner.xcarchive
```

### 2. Upload to Firebase App Distribution

```bash
# Prerequisites
firebase init
firebase apps:list

# Upload to staging track
firebase app:distribute \
  build/app/outputs/flutter-app.apk \
  --app=STAGING_APP_ID \
  --release-notes="Offline-first sync implementation" \
  --testers-file=staging-testers.txt
```

### 3. Staging Testing Duration

**Timeline:** 48-72 hours

**Testers:** 10-15 internal team members + 5-10 beta users

**Test Scenarios:**

```
Day 1: Basic Functionality
├─ Create offline → Sync online
├─ Edit while syncing
├─ Delete with conflict resolution
└─ Stock management with atomicity

Day 2: Network Conditions
├─ WiFi disable/enable cycle
├─ Network flakiness simulation
├─ Mobile hotspot switching
└─ Airplane mode toggle

Day 3: Edge Cases
├─ Power loss during sync
├─ Concurrent edits (multiple users)
├─ Large batch operations (100+ items)
└─ Quota exceeded handling
```

### 4. Monitor Staging

```bash
# Check Firebase Console
firebase functions:log --follow

# Monitor Firestore
firebase firestore:inspect-schema

# Check Analytics
firebase analytics:view
```

### 5. Staging Sign-Off

**Approval Required From:**
- [ ] QA Lead
- [ ] Product Manager
- [ ] Tech Lead
- [ ] Security Officer

---

## Production Deployment

### 1. Version Bump

```bash
# Update version in pubspec.yaml
version: 2.1.0+120

# Commit version bump
git add pubspec.yaml
git commit -m "chore: Bump version to 2.1.0"

# Create release tag
git tag v2.1.0
git push origin v2.1.0
```

### 2. Build Release Bundle

```bash
# Android App Bundle for Play Store
flutter build appbundle --release

# iOS Archive for App Store
flutter build ios --release --no-codesign
```

### 3. Deploy to App Store

#### Google Play Store

```bash
# Prerequisites
# - fastlane setup
# - Google Play Console credentials

# Upload to internal testing
fastlane supply --apk build/app/outputs/app-release.aab \
  --track internal

# Approve for internal testing
# Promote to staging (wait 2-3 days)
# Promote to production (wait 1 day before wider rollout)

# Full rollout
fastlane supply --rollout 1.0
```

#### Apple App Store

```bash
# Prerequisites
# - Xcode command line tools
# - Apple Developer account

# Export IPA
xcodebuild -exportArchive \
  -archivePath build/ios/Runner.xcarchive \
  -exportOptionsPlist build/ios/ExportOptions.plist \
  -exportPath build/ios/Release

# Upload with Transporter or fastlane
fastlane pilot upload --apple_id YOUR_APPLE_ID \
  -i build/ios/Release/CourtCare.ipa
```

### 4. Gradual Rollout Strategy

**Phase 1: 5% (Internal Testing)**
- Duration: 1 day
- Target: Internal team + beta users
- Monitor: Crash rate, ANR rate, sync errors

**Phase 2: 10% (Early Adopters)**
- Duration: 2-3 days
- Target: Regions with strong support
- Monitor: Crash rate, user engagement

**Phase 3: 50% (Standard Rollout)**
- Duration: 3-5 days
- Target: All regions
- Monitor: All metrics

**Phase 4: 100% (Full Release)**
- Duration: Final push
- Target: All users
- Monitor: All metrics

### 5. Rollback Plan

```bash
# If critical issues detected
# Within first 24 hours:

# Option 1: Pause rollout
# Google Play Console → Settings → Manage Rollout
# Set rollout percentage to 0%

# Option 2: Release previous version
firebase app:distribute \
  build/app/outputs/flutter-app-v2.0.9.apk \
  --app=PRODUCTION_APP_ID \
  --release-notes="Hotfix: Reverting to v2.0.9 due to critical sync issue"

# Option 3: Deploy hotfix
git revert <commit-sha>
# Follow deployment steps again with hotfix version 2.1.1
```

---

## Post-Deployment Monitoring

### Metrics to Monitor

| Metric | Threshold | Action |
|--------|-----------|--------|
| Crash Rate | > 1% | Pause rollout |
| ANR Rate | > 0.5% | Investigate |
| Sync Success Rate | < 95% | Disable feature |
| User Retention | < 90% | Monitor closely |
| Session Duration | < 80% of baseline | Investigate |

### Real-Time Monitoring

```bash
# Firebase Console
# → Performance
# → Crash Reports
# → Network Metrics

# Google Play Console
# → Vitals
# → Crashes & ANRs
# → User Feedback

# Firestore Console
# → Database Stats
# → Realtime Database Rules
```

### Daily Check-In

**First 7 days after release:**

```
Day 1-3: Hourly reviews
├─ Crash reports
├─ Error logs
├─ User feedback
└─ Sync error patterns

Day 4-7: Daily reviews
├─ Cumulative metrics
├─ Performance trends
├─ User engagement
└─ Competitive analysis
```

---

## Communication Plan

### Internal Communication

**Before Release:**
```
Team Slack Channel: #release-offline-sync
- Announce release timeline
- Share rollout strategy
- Provide on-call contact
```

**During Release:**
```
Slack Updates every 2 hours:
- Rollout percentage
- Crash rate
- Key issues (if any)
```

**After Release:**
```
Weekly Sync Meetings:
- Metrics review
- User feedback synthesis
- Optimization opportunities
```

### External Communication

**App Store Description:**
```
What's New in v2.1.0:

✨ Offline-First Synchronization
- Create, edit, and delete records even when offline
- Automatic sync when connection restored
- Intelligent conflict resolution
- Zero data loss guarantee

🚀 Performance Improvements
- Faster database queries
- Optimized sync algorithm
- Reduced battery drain

🐛 Bug Fixes
- Fixed double-booking in event creation
- Improved error messages
- Enhanced accessibility
```

**Release Notes:**
```
CourtCare v2.1.0 - Offline-First Release
Released: January 15, 2024

✨ New Features
- Full offline support for all operations
- Automatic sync with smart deduplication
- Real-time sync status indicators

🔧 Improvements
- 30% faster database operations
- 50% reduction in network requests
- Intelligent retry logic with exponential backoff

📖 Documentation
- New offline sync guide
- Updated testing procedures
- Deployment best practices
```

---

## Hotfix Process

If critical issues detected post-release:

### Immediate Response (< 1 hour)

```
1. Identify root cause
2. Prepare hotfix commit
3. Test hotfix locally
4. Pause rollout (if needed)
5. Communicate to team
```

### Hotfix Release (< 4 hours)

```bash
# Create hotfix branch
git checkout -b hotfix/sync-critical-bug

# Make fix
# ... edit files ...

# Test
flutter test
flutter analyze

# Commit and tag
git add .
git commit -m "fix: Critical sync deadlock issue"
git tag v2.1.1

# Build and deploy
flutter build appbundle --release
# Follow deployment steps for hotfix version
```

### Communication

```
🚨 HOTFIX RELEASED: v2.1.1
   Issue: Sync deadlock with 1000+ items
   Fix: Improved queue processing
   Rollout: 100% immediate
   Timeline: Expect availability in 2-4 hours
```

---

## Success Metrics

### Technical Metrics

- [ ] 99.9% sync success rate
- [ ] < 100ms median sync latency
- [ ] < 500MB database size
- [ ] < 5% battery drain per hour during sync

### User Metrics

- [ ] 95%+ user retention (week 1)
- [ ] 90%+ task completion rate
- [ ] < 1% bug report rate
- [ ] 4.5+ stars in app stores

---

## References

- Offline Sync Guide: `/docs/OFFLINE_SYNC.md`
- Testing Guide: `/docs/TESTING.md`
- Architecture: `/architecture.md`
- Release Checklist: `/DEPLOYMENT.md`
```
