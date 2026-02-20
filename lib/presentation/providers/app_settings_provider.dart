// lib/presentation/providers/app_settings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared_prefs_provider.dart';

class ClubLocation {
  final double latitude;
  final double longitude;
  const ClubLocation({required this.latitude, required this.longitude});

  ClubLocation copyWith({double? latitude, double? longitude}) =>
      ClubLocation(latitude: latitude ?? this.latitude, longitude: longitude ?? this.longitude);

  @override
  String toString() => 'ClubLocation(lat: $latitude, lon: $longitude)';
}

class AppSettingsNotifier extends StateNotifier<AsyncValue<ClubLocation?>> {
  AppSettingsNotifier(this.ref) : super(const AsyncLoading()) {
    _load();
  }

  static const _kLat = 'club_latitude';
  static const _kLon = 'club_longitude';

  /// En Riverpod 2.x, on passe un `Ref` au notifier
  final Ref ref;

  Future<void> _load() async {
    try {
      // On récupère l'instance via le FutureProvider
      final SharedPreferences prefs = await ref.read(sharedPrefsProvider.future);
      final lat = prefs.getDouble(_kLat);
      final lon = prefs.getDouble(_kLon);
      if (lat != null && lon != null) {
        state = AsyncValue.data(ClubLocation(latitude: lat, longitude: lon));
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setClubLocation(ClubLocation? loc) async {
    try {
      final SharedPreferences prefs = await ref.read(sharedPrefsProvider.future);
      if (loc == null) {
        await prefs.remove(_kLat);
        await prefs.remove(_kLon);
        state = const AsyncValue.data(null);
      } else {
        await prefs.setDouble(_kLat, loc.latitude);
        await prefs.setDouble(_kLon, loc.longitude);
        state = AsyncValue.data(loc);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> refresh() => _load();
}

final appSettingsProvider =
StateNotifierProvider<AppSettingsNotifier, AsyncValue<ClubLocation?>>(
      (ref) => AppSettingsNotifier(ref),
);