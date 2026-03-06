import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/club_info.dart';
import '../../domain/repositories/club_info_repository.dart';
import '../../domain/models/repository_exception.dart';
import '../services/nominatim_service.dart';

class ClubInfoRepositoryImpl implements ClubInfoRepository {
  final FirebaseFirestore _firestore;
  final NominatimService _nominatimService;

  static const String _collectionPath = 'infoClub';
  static const String _documentId = 'main';

  ClubInfoRepositoryImpl({
    FirebaseFirestore? firestore,
    required NominatimService nominatimService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _nominatimService = nominatimService;

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
        street: data['street'] as String?,
        postalCode: data['postalCode'] as String?,
        city: data['city'] as String?,
        latitude: (data['latitude'] as num?)?.toDouble(),
        longitude: (data['longitude'] as num?)?.toDouble(),
        phone: data['phone'] as String?,
        email: data['email'] as String?,
        openingHour: data['openingHour'] as int?,
        closingHour: data['closingHour'] as int?,
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        updatedBy: data['updatedBy'] as String?,
      );
    });
  }

  @override
  Future<void> saveClubInfo(ClubInfo info) async {
    try {
      ClubInfo updatedInfo = info;
      if (info.street != null &&
          info.street!.isNotEmpty &&
          info.postalCode != null &&
          info.postalCode!.isNotEmpty &&
          info.city != null &&
          info.city!.isNotEmpty) {
        final location = await _nominatimService.geocode(
          street: info.street!,
          postalCode: info.postalCode!,
          city: info.city!,
        );

        if (location != null) {
          updatedInfo = updatedInfo.copyWith(
            latitude: location.latitude,
            longitude: location.longitude,
          );
        } else {
          debugPrint('⚠️ Géocodage échoué — coordonnées existantes conservées');
        }
      }

      await _firestore
          .collection(_collectionPath)
          .doc(_documentId)
          .set({
            'name': updatedInfo.name,
            'street': updatedInfo.street,
            'postalCode': updatedInfo.postalCode,
            'city': updatedInfo.city,
            'latitude': updatedInfo.latitude,
            'longitude': updatedInfo.longitude,
            'phone': updatedInfo.phone,
            'email': updatedInfo.email,
            'openingHour': updatedInfo.openingHour,
            'closingHour': updatedInfo.closingHour,
            'updatedAt': Timestamp.fromDate(updatedInfo.updatedAt),
            'updatedBy': updatedInfo.updatedBy,
          }, SetOptions(merge: true));
    } catch (e) {
      if (e is RepositoryException) {
        rethrow;
      }
      throw RepositoryException('Failed to save club info: $e');
    }
  }
}
