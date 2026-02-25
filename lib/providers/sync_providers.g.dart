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
String _$isOnlineStatusHash() => r'97202c1a06493f199b9aedf830dcabb118de4e51';

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
String _$backgroundTerrainsSyncHash() =>
    r'100015ffc39f3a13da45b8e994bfbd779709a736';

/// See also [backgroundTerrainsSync].
@ProviderFor(backgroundTerrainsSync)
final backgroundTerrainsSyncProvider = StreamProvider<void>.internal(
  backgroundTerrainsSync,
  name: r'backgroundTerrainsSyncProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$backgroundTerrainsSyncHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BackgroundTerrainsSyncRef = StreamProviderRef<void>;
String _$backgroundReservationsSyncHash() =>
    r'209b9d8116d6266a03333a35e733a2134dbf2061';

/// See also [backgroundReservationsSync].
@ProviderFor(backgroundReservationsSync)
final backgroundReservationsSyncProvider = StreamProvider<void>.internal(
  backgroundReservationsSync,
  name: r'backgroundReservationsSyncProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$backgroundReservationsSyncHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BackgroundReservationsSyncRef = StreamProviderRef<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
