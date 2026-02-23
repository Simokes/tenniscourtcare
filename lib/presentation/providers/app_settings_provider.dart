// lib/presentation/providers/app_settings_provider.dart
import 'package:flutter/material.dart';
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

class AppSettings {
  final ClubLocation? location;
  final ThemeMode themeMode;

  const AppSettings({
    this.location,
    this.themeMode = ThemeMode.system,
  });

  AppSettings copyWith({
    ClubLocation? location,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      location: location ?? this.location,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  AppSettingsNotifier(this.ref) : super(const AsyncLoading()) {
    _load();
  }

  static const _kLat = 'club_latitude';
  static const _kLon = 'club_longitude';
  static const _kThemeMode = 'app_theme_mode'; // 0=system, 1=light, 2=dark

  /// En Riverpod 2.x, on passe un `Ref` au notifier
  final Ref ref;

  Future<void> _load() async {
    try {
      // On récupère l'instance via le FutureProvider
      final SharedPreferences prefs = await ref.read(sharedPrefsProvider.future);

      // Load Location
      final lat = prefs.getDouble(_kLat);
      final lon = prefs.getDouble(_kLon);
      ClubLocation? location;
      if (lat != null && lon != null) {
        location = ClubLocation(latitude: lat, longitude: lon);
      }

      // Load Theme
      final themeIndex = prefs.getInt(_kThemeMode);
      ThemeMode themeMode = ThemeMode.system;
      if (themeIndex != null) {
        themeMode = ThemeMode.values.firstWhere(
          (e) => e.index == themeIndex,
          orElse: () => ThemeMode.system,
        );
      }

      state = AsyncValue.data(AppSettings(location: location, themeMode: themeMode));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setClubLocation(ClubLocation? loc) async {
    try {
      final SharedPreferences prefs = await ref.read(sharedPrefsProvider.future);
      final currentSettings = state.valueOrNull ?? const AppSettings();

      if (loc == null) {
        await prefs.remove(_kLat);
        await prefs.remove(_kLon);
        // Create new settings with null location, preserving current theme
        state = AsyncValue.data(AppSettings(location: null, themeMode: currentSettings.themeMode));
      } else {
        await prefs.setDouble(_kLat, loc.latitude);
        await prefs.setDouble(_kLon, loc.longitude);
        state = AsyncValue.data(currentSettings.copyWith(location: loc));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> setCoordinates(double lat, double lon) async {
    await setClubLocation(ClubLocation(latitude: lat, longitude: lon));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      final SharedPreferences prefs = await ref.read(sharedPrefsProvider.future);
      final currentSettings = state.valueOrNull ?? const AppSettings();

      await prefs.setInt(_kThemeMode, mode.index);

      state = AsyncValue.data(currentSettings.copyWith(themeMode: mode));
    } catch (e, st) {
       state = AsyncValue.error(e, st);
       rethrow;
    }
  }

  Future<void> refresh() => _load();
}

final appSettingsProvider =
StateNotifierProvider<AppSettingsNotifier, AsyncValue<AppSettings>>(
      (ref) => AppSettingsNotifier(ref),
);
