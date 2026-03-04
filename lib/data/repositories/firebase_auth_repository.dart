import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:drift/drift.dart' as drift;
import 'package:tenniscourtcare/core/security/auth_exceptions.dart';
import 'package:tenniscourtcare/core/security/security_exceptions.dart';
import 'package:tenniscourtcare/data/database/app_database.dart';
import 'package:tenniscourtcare/domain/entities/user_entity.dart';
import 'package:tenniscourtcare/domain/enums/role.dart';
import 'package:tenniscourtcare/domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final firebase.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final AppDatabase _db;

  FirebaseAuthRepository(
    this._db, {
    firebase.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _auth = auth ?? firebase.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  Exception _mapFirebaseException(dynamic e) {
    if (e is firebase.FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return const InvalidCredentialsException();
        case 'user-disabled':
          return const AccountLockedException('Le compte a été désactivé.');
        case 'too-many-requests':
          return const SecurityException(
            'Trop de tentatives. Veuillez réessayer plus tard.',
          );
        case 'email-already-in-use':
          return const ValidationException('Cet email est déjà utilisé.');
        case 'weak-password':
          return const PasswordValidationException(
            'Le mot de passe est trop faible.',
          );
        case 'invalid-email':
          return const ValidationException('Format d\'email invalide.');
        default:
          return GenericAuthException(
            'Erreur d\'authentification: ${e.message}',
            code: e.code,
          );
      }
    } else if (e is FirebaseFunctionsException) {
      switch (e.code) {
        case 'permission-denied':
          return const UnauthorizedException(message: 'Permission refusée.');
        case 'invalid-argument':
          return ValidationException(e.message ?? 'Arguments invalides.');
        case 'failed-precondition':
          return ValidationException(
            e.message ?? 'Condition préalable échouée.',
          );
        default:
          return GenericAuthException(
            'Erreur serveur: ${e.message}',
            code: e.code,
          );
      }
    }
    return SecurityException('Erreur inconnue: $e', originalError: e);
  }

  Future<UserEntity> _syncUser(firebase.User fUser) async {
    // Check if the user is inactive before syncing/returning
    final doc = await _firestore.collection('users').doc(fUser.uid).get();
    if (doc.exists) {
      final status = doc.data()?['status'] as String?;
      if (status == 'inactive') {
        throw const PendingApprovalException();
      } else if (status == 'rejected') {
        throw const AccountRejectedException();
      }
    }

    // CRITICAL FIX: Query by firestore_uid, not email
    final localUser = await _db.getUserByFirestoreUid(fUser.uid);

    // Refresh token to get latest claims
    final token = await fUser.getIdTokenResult(true);
    final roleStr = token.claims?['role'] as String?;
    final userRole = roleStr != null
        ? Role.values.firstWhere(
            (r) => r.name == roleStr,
            orElse: () => Role.agent,
          )
        : Role.agent;

    if (localUser != null) {
      bool needsUpdate = false;
      if (localUser.role != userRole) {
        await _db.updateUserRole(localUser.id, userRole);
        needsUpdate = true;
      }
      // Ensure email is up to date if changed in Firebase
      if (localUser.email != fUser.email) {
        // Note: Email update in local DB not directly supported by current DAO but should be.
        // For now we assume email matches or we update it if we had a method.
      }

      return needsUpdate ? localUser.copyWith(role: userRole) : localUser;
    } else {
      // Create new local user with firestore_uid
      final now = DateTime.now();
      final id = await _db.insertUser(
        UsersCompanion(
          email: drift.Value(fUser.email!),
          firestoreUid: drift.Value(fUser.uid), // CRITICAL: Save firestore_uid
          name: drift.Value(fUser.displayName ?? 'Utilisateur'),
          passwordHash: const drift.Value('FIREBASE_AUTH'),
          role: drift.Value(userRole),
          createdAt: drift.Value(now),
        ),
      );
      return UserEntity(
        id: id,
        email: fUser.email!,
        name: fUser.displayName ?? 'Utilisateur',
        role: userRole,
        createdAt: now,
        updatedAt: now,
        firebaseId: fUser.uid,
      );
    }
  }

  @override
  Future<UserEntity?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (cred.user == null) return null;
      return _syncUser(cred.user!);
    } catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final fUser = _auth.currentUser;
    if (fUser == null) return null;
    try {
      return await _syncUser(fUser);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> signUp({
    required String email,
    required String name,
    required String password,
    required Role role,
  }) async {
    try {
      if (role == Role.admin) {
        throw const ValidationException('Impossible de s\'inscrire en tant qu\'administrateur.');
      }

      // 1. Firebase Auth createUserWithEmailAndPassword
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw const SecurityException('Erreur lors de la création de l\'utilisateur.');
      }

      // Update displayName
      await user.updateDisplayName(name);

      // 2. Write Firestore doc in 'users' collection
      final uid = user.uid;
      final now = DateTime.now();
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'name': name,
        'role': role.name,
        'status': 'inactive',
        'createdAt': FieldValue.serverTimestamp(),
        'approvedAt': null,
        'approvedBy': null,
        'uid': uid,
      });

      // 3. Write Drift local user row (status: inactive)
      await _db.into(_db.users).insert(
        UsersCompanion.insert(
          email: email,
          name: name,
          passwordHash: 'FIREBASE_AUTH',
          role: role,
          status: const drift.Value('inactive'),
          firestoreUid: drift.Value(uid),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      // 4. Sign out immediately after signup
      await _auth.signOut();
    } catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<void> approveUser(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw const UnauthorizedException();
      }

      await _firestore.collection('users').doc(userId).update({
        'status': 'active',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': currentUser.email,
      });
      // Drift local row update will be handled by FirebaseCacheService listener
    } catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<void> rejectUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': 'rejected',
      });
      // Local row and user logic handled via sync / Cloud function isn't needed per instructions
    } catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<void> createUser({
    required String email,
    required String name,
    required String password,
    required Role role,
  }) async {
    try {
      final callable = _functions.httpsCallable('createUser');
      final result = await callable.call({
        'email': email,
        'name': name,
        'password': password,
        'role': role.name,
      });

      // CRITICAL: Get UID from response
      if (result.data is! Map) {
        throw const ValidationException(
          'Erreur serveur: Réponse invalide (format incorrect).',
        );
      }

      // Cast to map to access fields safely
      final data = result.data as Map;
      final uid = data['uid'] as String?;

      if (uid == null || uid.isEmpty) {
        throw const ValidationException(
          'Erreur serveur: UID manquant dans la réponse.',
        );
      }

      // Sync local DB
      // Check if user exists first (by firestore_uid)
      final existingByUid = await _db.getUserByFirestoreUid(uid);

      if (existingByUid == null) {
        await _db.insertUser(
          UsersCompanion(
            email: drift.Value(email),
            firestoreUid: drift.Value(uid), // CRITICAL: Save firestore_uid
            name: drift.Value(name),
            passwordHash: const drift.Value('FIREBASE_AUTH'),
            role: drift.Value(role),
            createdAt: drift.Value(DateTime.now()),
          ),
        );
      }
    } catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<void> deleteUser(int userId) async {
    try {
      final localUser = await _db.getUserById(userId);
      if (localUser == null) throw const UserNotFoundException();

      // Use direct query to get firestoreUid from the row (UserEntity doesn't expose it yet)
      final userRow = await (_db.select(
        _db.users,
      )..where((u) => u.id.equals(userId))).getSingleOrNull();
      String? uid = userRow?.firestoreUid;

      if (uid == null) {
        // Fallback to Firestore lookup by email for legacy users or sync issues
        final query = await _firestore
            .collection('users')
            .where('email', isEqualTo: localUser.email)
            .get();
        if (query.docs.isNotEmpty) {
          uid = query.docs.first.id;
        }
      }

      if (uid != null) {
        final callable = _functions.httpsCallable('deleteUser');
        await callable.call({'userId': uid});
      }

      await _db.deleteUser(userId);
    } catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<void> updateUserRole(int userId, Role newRole) async {
    try {
      final localUser = await _db.getUserById(userId);
      if (localUser == null) throw const UserNotFoundException();

      // Use direct query to get firestoreUid from the row
      final userRow = await (_db.select(
        _db.users,
      )..where((u) => u.id.equals(userId))).getSingleOrNull();
      String? uid = userRow?.firestoreUid;

      if (uid == null) {
        final query = await _firestore
            .collection('users')
            .where('email', isEqualTo: localUser.email)
            .get();
        if (query.docs.isNotEmpty) {
          uid = query.docs.first.id;
        }
      }

      if (uid == null) throw const UserNotFoundException();

      final callable = _functions.httpsCallable('updateUserRole');
      await callable.call({'userId': uid, 'newRole': newRole.name});

      // Update local DB
      await _db.updateUserRole(userId, newRole);
    } catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<void> updateUserPassword(int userId, String newPassword) async {
    try {
      final localUser = await _db.getUserById(userId);
      if (localUser == null) throw const UserNotFoundException();

      // Use direct query to get firestoreUid from the row
      final userRow = await (_db.select(
        _db.users,
      )..where((u) => u.id.equals(userId))).getSingleOrNull();
      String? uid = userRow?.firestoreUid;

      if (uid == null) {
        final query = await _firestore
            .collection('users')
            .where('email', isEqualTo: localUser.email)
            .get();
        if (query.docs.isNotEmpty) {
          uid = query.docs.first.id;
        }
      }

      if (uid == null) throw const UserNotFoundException();

      final callable = _functions.httpsCallable('resetUserPassword');
      await callable.call({'userId': uid, 'newPassword': newPassword});
    } catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<List<UserEntity>> getAllUsers() {
    return _db.getAllUsers();
  }

  @override
  Future<UserEntity> createAdminUser({
    required String email,
    required String name,
    required String password,
  }) async {
    try {
      // 1. Créer l'utilisateur dans Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // 2. Créer le document admin dans Firestore
      final now = DateTime.now();
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'firstName': name,
        'lastName': '',
        'role': 'admin',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'uid': uid,
      });

      // 3. Sauvegarder dans la base de données locale (Drift)
      final id = await _db.insertUser(
        UsersCompanion(
          email: drift.Value(email),
          firestoreUid: drift.Value(uid),
          name: drift.Value(name),
          passwordHash: const drift.Value('FIREBASE_AUTH'),
          role: const drift.Value(Role.admin),
          createdAt: drift.Value(now),
        ),
      );

      return UserEntity(
        id: id,
        email: email,
        name: name,
        role: Role.admin,
        createdAt: now,
        updatedAt: now,
        firebaseId: uid,
      );
    } catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<bool> hasAnyUser() async {
    // CRITICAL: Check actual DB count
    try {
      final count = await _db.countUsers();
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> requestOtp(String email) async {
    throw UnimplementedError('OTP non supporté dans cette version.');
  }

  @override
  Future<bool> verifyOtp(String email, String code) async {
    throw UnimplementedError('OTP non supporté dans cette version.');
  }
}
