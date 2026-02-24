import 'package:cloud_firestore/cloud_firestore.dart';

class StockFirestoreModel {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final int minQuantity;
  final double? unitPrice;
  final String? lastModifiedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? syncedAt;

  StockFirestoreModel({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    this.minQuantity = 0,
    this.unitPrice,
    this.lastModifiedBy,
    required this.createdAt,
    this.updatedAt,
    this.syncedAt,
  });

  factory StockFirestoreModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockFirestoreModel(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      quantity: data['quantity'] ?? 0,
      minQuantity: data['minQuantity'] ?? 0,
      unitPrice: (data['unitPrice'] as num?)?.toDouble(),
      lastModifiedBy: data['lastModifiedBy'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      syncedAt: (data['syncedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'unitPrice': unitPrice,
      'lastModifiedBy': lastModifiedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      'syncedAt': syncedAt != null ? Timestamp.fromDate(syncedAt!) : null,
    };
  }
}
