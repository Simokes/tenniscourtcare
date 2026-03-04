import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/club_info.dart';
import '../../domain/repositories/club_info_repository.dart';
import '../../data/repositories/club_info_repository_impl.dart';

final clubInfoRepositoryProvider = Provider<ClubInfoRepository>((ref) {
  return ClubInfoRepositoryImpl();
});

final clubInfoProvider = StreamProvider<ClubInfo?>((ref) {
  return ref.watch(clubInfoRepositoryProvider).watchClubInfo();
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
