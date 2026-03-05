import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/club_info.dart';
import '../../domain/repositories/club_info_repository.dart';
import '../../data/repositories/club_info_repository_impl.dart';
import '../../data/services/nominatim_service.dart';
import 'app_settings_provider.dart' show ClubLocation;

final nominatimServiceProvider = Provider<NominatimService>((ref) {
  return NominatimService();
});

final clubInfoRepositoryProvider = Provider<ClubInfoRepository>((ref) {
  final nominatimService = ref.watch(nominatimServiceProvider);
  return ClubInfoRepositoryImpl(nominatimService: nominatimService);
});

final clubInfoProvider = StreamProvider<ClubInfo?>((ref) {
  return ref.watch(clubInfoRepositoryProvider).watchClubInfo();
});

final clubLocationFromInfoProvider = Provider<ClubLocation?>((ref) {
  return ref.watch(clubInfoProvider).maybeWhen(
    data: (info) {
      if (info?.latitude != null && info?.longitude != null) {
        return ClubLocation(
          latitude: info!.latitude!,
          longitude: info.longitude!,
        );
      }
      return null;
    },
    orElse: () => null,
  );
});

class ClubInfoNotifier extends AsyncNotifier<void> {
  late ClubInfoRepository _repo;

  @override
  FutureOr<void> build() {
    _repo = ref.watch(clubInfoRepositoryProvider);
  }

  Future<void> saveClubInfo(ClubInfo info) async {
    try {
      state = const AsyncValue.loading();
      await _repo.saveClubInfo(info);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final clubInfoNotifierProvider =
    AsyncNotifierProvider<ClubInfoNotifier, void>(() {
      return ClubInfoNotifier();
    });
