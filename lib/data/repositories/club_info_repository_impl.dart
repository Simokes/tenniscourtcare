import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/club_info.dart';
import '../../domain/repositories/club_info_repository.dart';
import '../../domain/models/repository_exception.dart';

class ClubInfoRepositoryImpl implements ClubInfoRepository {
  final FirebaseFirestore _firestore;

  static const String _collectionPath = 'infoClub';
  static const String _documentId = 'main';

  ClubInfoRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<ClubInfo?> watchClubInfo() {
    return _firestore
        .collection(_collectionPath)
        .doc(_documentId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;

      final data = snapshot.data();
      if (data == null) return null;

      return ClubInfo(
        id: snapshot.id,
        name: data['name'] as String,
        address: data['address'] as String?,
        phone: data['phone'] as String?,
        email: data['email'] as String?,
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        updatedBy: data['updatedBy'] as String?,
      );
    });
  }

  @override
  Future<void> saveClubInfo(ClubInfo info) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(_documentId)
          .set({
            'name': info.name,
            'address': info.address,
            'phone': info.phone,
            'email': info.email,
            'updatedAt': Timestamp.fromDate(info.updatedAt),
            'updatedBy': info.updatedBy,
          }, SetOptions(merge: true));
    } catch (e) {
      throw RepositoryException('Failed to save club info: $e');
    }
  }
}
