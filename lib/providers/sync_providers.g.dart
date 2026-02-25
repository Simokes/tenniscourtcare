// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$syncServiceHash() => r'78569ba0c5320acad3290fd63e4ca2762a3244d5';

/// See also [syncService].
@ProviderFor(syncService)
final syncServiceProvider = Provider<SyncService>.internal(
  syncService,
  name: r'syncServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$syncServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SyncServiceRef = ProviderRef<SyncService>;
String _$isOnlineStatusHash() => r'98c821b51da4084a80d7650bdcd8cd194c31cb74';

/// See also [isOnlineStatus].
@ProviderFor(isOnlineStatus)
final isOnlineStatusProvider = StreamProvider<bool>.internal(
  isOnlineStatus,
  name: r'isOnlineStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isOnlineStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsOnlineStatusRef = StreamProviderRef<bool>;
String _$pendingChangesCountHash() =>
    r'ca3cb082c057b8a132f9fb5b2eca0b2d84beb68d';

/// See also [pendingChangesCount].
@ProviderFor(pendingChangesCount)
final pendingChangesCountProvider = AutoDisposeStreamProvider<int>.internal(
  pendingChangesCount,
  name: r'pendingChangesCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingChangesCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingChangesCountRef = AutoDisposeStreamProviderRef<int>;
String _$terrainsStreamHash() => r'8b542a6104c6baed216fcba445d2e80336d1aeb6';

/// See also [terrainsStream].
@ProviderFor(terrainsStream)
final terrainsStreamProvider = StreamProvider<List<dom.Terrain>>.internal(
  terrainsStream,
  name: r'terrainsStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$terrainsStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TerrainsStreamRef = StreamProviderRef<List<dom.Terrain>>;
String _$reservationsStreamHash() =>
    r'902f02ac147b4df7053987edbafb2ee1ad64719e';

/// See also [reservationsStream].
@ProviderFor(reservationsStream)
final reservationsStreamProvider = StreamProvider<List<Reservation>>.internal(
  reservationsStream,
  name: r'reservationsStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$reservationsStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReservationsStreamRef = StreamProviderRef<List<Reservation>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
