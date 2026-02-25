// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$queueManagerHash() => r'1cc1af9191bf78c9c891205b14b6bbf024bfcc04';

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
String _$pendingQueueCountHash() => r'b2006eb2a0c7247ac4a6ec85c7ff9c4db71f33bd';

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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
