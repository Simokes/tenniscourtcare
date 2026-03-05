import 'package:cloud_firestore/cloud_firestore.dart';
import './user_firestore_model.dart';

class FirestoreUserRepository {
  final FirebaseFirestore _firestore;

  FirestoreUserRepository(this._firestore);

  CollectionReference get _users => _firestore.collection('users');

  Future<void> createUser(UserFirestoreModel user) async {
    await _users.doc(user.uid).set(user.toFirestore());
  }

  Future<UserFirestoreModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (doc.exists) {
      return UserFirestoreModel.fromFirestore(doc);
    }
    return null;
  }

  Future<void> updateUser(UserFirestoreModel user) async {
    await _users.doc(user.uid).update(user.toFirestore());
  }

  Future<void> deleteUser(String uid) async {
    await _users.doc(uid).delete();
  }
}
