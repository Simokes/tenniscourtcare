// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$stockStreamHash() => r'd2e052e711af67e0af0c4dc405a9889b10a3c71b';

/// See also [stockStream].
@ProviderFor(stockStream)
final stockStreamProvider = StreamProvider<List<dom.StockItem>>.internal(
  stockStream,
  name: r'stockStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$stockStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StockStreamRef = StreamProviderRef<List<dom.StockItem>>;
String _$lowStockCountHash() => r'595a460beb4647871b43f47ceba547a51147f7e2';

/// See also [lowStockCount].
@ProviderFor(lowStockCount)
final lowStockCountProvider = AutoDisposeStreamProvider<int>.internal(
  lowStockCount,
  name: r'lowStockCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$lowStockCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LowStockCountRef = AutoDisposeStreamProviderRef<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
