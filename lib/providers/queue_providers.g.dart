// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$queueManagerHash() => r'698d666d9b9a1ed581bf670322a01b8a422a2ce5';

/// See also [queueManager].
@ProviderFor(queueManager)
final queueManagerProvider = Provider<QueueManager>.internal(
  queueManager,
  name: r'queueManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$queueManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef QueueManagerRef = ProviderRef<QueueManager>;
String _$pendingQueueCountHash() => r'ec0fb7c4f7d20318dc7c6d0aa1b4e2485a451f09';

/// See also [pendingQueueCount].
@ProviderFor(pendingQueueCount)
final pendingQueueCountProvider = StreamProvider<int>.internal(
  pendingQueueCount,
  name: r'pendingQueueCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingQueueCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingQueueCountRef = StreamProviderRef<int>;
String _$pendingQueueItemsHash() => r'89b9d2cd09043e13905e3d9387ea2efe5555b63f';

/// See also [pendingQueueItems].
@ProviderFor(pendingQueueItems)
final pendingQueueItemsProvider =
    AutoDisposeFutureProvider<List<SyncQueueItem>>.internal(
      pendingQueueItems,
      name: r'pendingQueueItemsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pendingQueueItemsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingQueueItemsRef =
    AutoDisposeFutureProviderRef<List<SyncQueueItem>>;
String _$retryFailedHash() => r'209c973657bbe0fd2eb6eeae13af7acb64dd54b8';

/// See also [retryFailed].
@ProviderFor(retryFailed)
final retryFailedProvider = AutoDisposeFutureProvider<void>.internal(
  retryFailed,
  name: r'retryFailedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$retryFailedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RetryFailedRef = AutoDisposeFutureProviderRef<void>;
String _$queueStatusHash() => r'47d2276bd0b45aa2cca18c993431c43098ac9652';

/// See also [queueStatus].
@ProviderFor(queueStatus)
final queueStatusProvider = FutureProvider<QueueStatus>.internal(
  queueStatus,
  name: r'queueStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$queueStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef QueueStatusRef = FutureProviderRef<QueueStatus>;
String _$queueProgressHash() => r'e41f08d6a8a6e5e56c63a8e837758a38d8c91645';

/// See also [queueProgress].
@ProviderFor(queueProgress)
final queueProgressProvider = FutureProvider<QueueProgress>.internal(
  queueProgress,
  name: r'queueProgressProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$queueProgressHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef QueueProgressRef = FutureProviderRef<QueueProgress>;
String _$queueErrorsHash() => r'8998d54d46f73c1bf3ca7dad6387d7542ee56475';

/// See also [queueErrors].
@ProviderFor(queueErrors)
final queueErrorsProvider = FutureProvider<List<QueueError>>.internal(
  queueErrors,
  name: r'queueErrorsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$queueErrorsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef QueueErrorsRef = FutureProviderRef<List<QueueError>>;
String _$queueWarningsHash() => r'19441345764fdec14b1e249c662f514169e2155f';

/// See also [queueWarnings].
@ProviderFor(queueWarnings)
final queueWarningsProvider = StreamProvider<int>.internal(
  queueWarnings,
  name: r'queueWarningsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$queueWarningsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef QueueWarningsRef = StreamProviderRef<int>;
String _$queueCriticalHash() => r'92eb5c19bb8aad9725c55cec11edc3e5b0db7067';

/// See also [queueCritical].
@ProviderFor(queueCritical)
final queueCriticalProvider = StreamProvider<int>.internal(
  queueCritical,
  name: r'queueCriticalProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$queueCriticalHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef QueueCriticalRef = StreamProviderRef<int>;
String _$scheduleRetryCheckHash() =>
    r'27925ca3b2661d21892d89b5dc342d317c6e42a9';

/// See also [scheduleRetryCheck].
@ProviderFor(scheduleRetryCheck)
final scheduleRetryCheckProvider = Provider<void>.internal(
  scheduleRetryCheck,
  name: r'scheduleRetryCheckProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$scheduleRetryCheckHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ScheduleRetryCheckRef = ProviderRef<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
