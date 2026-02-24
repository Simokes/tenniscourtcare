import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firestore/models/reservation_firestore_model.dart';

class FirestoreReservationRepository {
  final FirebaseFirestore _firestore;

  FirestoreReservationRepository(this._firestore);

  CollectionReference get _reservations => _firestore.collection('reservations');

  Future<void> saveReservation(ReservationFirestoreModel reservation) async {
    await _reservations.doc(reservation.id).set(reservation.toFirestore());
  }

  Future<ReservationFirestoreModel?> getReservation(String id) async {
    final doc = await _reservations.doc(id).get();
    if (doc.exists) {
      return ReservationFirestoreModel.fromFirestore(doc);
    }
    return null;
  }

  Stream<List<ReservationFirestoreModel>> watchReservations({DateTime? start, DateTime? end}) {
    Query query = _reservations.orderBy('date');
    if (start != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start));
    }
    if (end != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(end));
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ReservationFirestoreModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> deleteReservation(String id) async {
    await _reservations.doc(id).delete();
  }
}
