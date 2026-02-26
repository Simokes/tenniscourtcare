import 'package:cloud_firestore/cloud_firestore.dart';

class TerrainFirestoreModel {
  final String id;
  final String name;
  final String surface;
  final String? location;
  final int? capacity;
  final double? pricePerHour;
  final bool available;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? syncedAt;
  final String? imageUrl;

  TerrainFirestoreModel({
    required this.id,
    required this.name,
    required this.surface,
    this.location,
    this.capacity,
    this.pricePerHour,
    this.available = true,
    required this.createdAt,
    this.updatedAt,
    this.syncedAt,
    this.imageUrl,
  });

  factory TerrainFirestoreModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TerrainFirestoreModel(
      id: doc.id,
      name: data['name'] ?? '',
      surface: data['surface'] ?? 'clay',
      location: data['location'],
      capacity: data['capacity'],
      pricePerHour: (data['pricePerHour'] as num?)?.toDouble(),
      available: data['available'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      syncedAt: (data['syncedAt'] as Timestamp?)?.toDate(),
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'surface': surface,
      'location': location,
      'capacity': capacity,
      'pricePerHour': pricePerHour,
      'available': available,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
      'syncedAt': syncedAt != null ? Timestamp.fromDate(syncedAt!) : null,
      'imageUrl': imageUrl,
    };
  }
}
