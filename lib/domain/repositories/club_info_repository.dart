import '../entities/club_info.dart';

abstract class ClubInfoRepository {
  Stream<ClubInfo?> watchClubInfo();
  Future<void> saveClubInfo(ClubInfo info);
}
