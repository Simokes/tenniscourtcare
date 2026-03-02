// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userReservationsStreamHash() =>
    r'bbce58e881a54e140003863534ed20f783a9c235';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [userReservationsStream].
@ProviderFor(userReservationsStream)
const userReservationsStreamProvider = UserReservationsStreamFamily();

/// See also [userReservationsStream].
class UserReservationsStreamFamily
    extends Family<AsyncValue<List<Reservation>>> {
  /// See also [userReservationsStream].
  const UserReservationsStreamFamily();

  /// See also [userReservationsStream].
  UserReservationsStreamProvider call(String userId) {
    return UserReservationsStreamProvider(userId);
  }

  @override
  UserReservationsStreamProvider getProviderOverride(
    covariant UserReservationsStreamProvider provider,
  ) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userReservationsStreamProvider';
}

/// See also [userReservationsStream].
class UserReservationsStreamProvider extends StreamProvider<List<Reservation>> {
  /// See also [userReservationsStream].
  UserReservationsStreamProvider(String userId)
    : this._internal(
        (ref) =>
            userReservationsStream(ref as UserReservationsStreamRef, userId),
        from: userReservationsStreamProvider,
        name: r'userReservationsStreamProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$userReservationsStreamHash,
        dependencies: UserReservationsStreamFamily._dependencies,
        allTransitiveDependencies:
            UserReservationsStreamFamily._allTransitiveDependencies,
        userId: userId,
      );

  UserReservationsStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    Stream<List<Reservation>> Function(UserReservationsStreamRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserReservationsStreamProvider._internal(
        (ref) => create(ref as UserReservationsStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  StreamProviderElement<List<Reservation>> createElement() {
    return _UserReservationsStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserReservationsStreamProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserReservationsStreamRef on StreamProviderRef<List<Reservation>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserReservationsStreamProviderElement
    extends StreamProviderElement<List<Reservation>>
    with UserReservationsStreamRef {
  _UserReservationsStreamProviderElement(super.provider);

  @override
  String get userId => (origin as UserReservationsStreamProvider).userId;
}

String _$allReservationsStreamHash() =>
    r'7d755c40879d3c7adde2d24e94adbea258f11b7b';

/// See also [allReservationsStream].
@ProviderFor(allReservationsStream)
final allReservationsStreamProvider =
    StreamProvider<List<Reservation>>.internal(
      allReservationsStream,
      name: r'allReservationsStreamProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$allReservationsStreamHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllReservationsStreamRef = StreamProviderRef<List<Reservation>>;
String _$refreshReservationsHash() =>
    r'3fc34f29cbb222db7ef9c5c79d43dd4492f2e1ee';

/// See also [refreshReservations].
@ProviderFor(refreshReservations)
final refreshReservationsProvider = AutoDisposeFutureProvider<void>.internal(
  refreshReservations,
  name: r'refreshReservationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$refreshReservationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RefreshReservationsRef = AutoDisposeFutureProviderRef<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
