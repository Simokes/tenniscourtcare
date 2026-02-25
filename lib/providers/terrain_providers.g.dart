// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'terrain_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$terrainsStreamHash() => r'3a3c78b90d3c65ca5653f2ae4218d30638fc47ac';

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
String _$refreshTerrainsHash() => r'66627e998a8cd18cd903b251ad3e6349500a2222';

/// See also [refreshTerrains].
@ProviderFor(refreshTerrains)
final refreshTerrainsProvider = AutoDisposeFutureProvider<void>.internal(
  refreshTerrains,
  name: r'refreshTerrainsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$refreshTerrainsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RefreshTerrainsRef = AutoDisposeFutureProviderRef<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
