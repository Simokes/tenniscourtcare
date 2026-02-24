import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
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
  })  : _auth = auth ?? firebase.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

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
          return const SecurityException('Trop de tentatives. Veuillez réessayer plus tard.');
        case 'email-already-in-use':
          return const ValidationException('Cet email est déjà utilisé.');
        case 'weak-password':
          return const PasswordValidationException('Le mot de passe est trop faible.');
        case 'invalid-email':
          return const ValidationException('Format d\'email invalide.');
        default:
          return AuthException('Erreur d\'authentification: ${e.message}', code: e.code);
      }
    } else if (e is FirebaseFunctionsException) {
       switch (e.code) {
        case 'permission-denied':
          return const UnauthorizedException(message: 'Permission refusée.');
        case 'invalid-argument':
           return ValidationException(e.message ?? 'Arguments invalides.');
        case 'failed-precondition':
           return ValidationException(e.message ?? 'Condition préalable échouée.');
        default:
           return AuthException('Erreur serveur: ${e.message}', code: e.code);
       }
    }
    return SecurityException('Erreur inconnue: $e', originalError: e);
  }

  Future<UserEntity> _syncUser(firebase.User fUser) async {
    final localUser = await _db.getUserByEmail(fUser.email!);

    // Refresh token to get latest claims
    final token = await fUser.getIdTokenResult(true);
    final roleStr = token.claims?['role'] as String?;
    final userRole = roleStr != null
        ? Role.values.firstWhere((r) => r.name == roleStr, orElse: () => Role.agent)
        : Role.agent;

    if (localUser != null) {
      if (localUser.role != userRole) {
          await _db.updateUserRole(localUser.id, userRole);
          return localUser.copyWith(role: userRole);
      }
      return localUser;
    } else {
      final id = await _db.insertUser(UsersCompanion(
        email: drift.Value(fUser.email!),
        name: drift.Value(fUser.displayName ?? 'Utilisateur'),
        passwordHash: const drift.Value('FIREBASE_AUTH'),
        role: drift.Value(userRole),
        createdAt: drift.Value(DateTime.now()),
      ));
      return UserEntity(
          id: id,
          email: fUser.email!,
          name: fUser.displayName ?? 'Utilisateur',
          role: userRole
      );
    }
  }

  @override
  Future<UserEntity?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
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
      // Fallback or handle sync error (e.g. database locked)
      // For now, return null to force re-login if sync fails significantly?
      // Or just map what we have?
      // Better to return null if we can't verify/sync the user.
      return null;
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
      await callable.call({
        'email': email,
        'name': name,
        'password': password,
        'role': role.name,
      });

      // Sync local DB
      // Check if user exists first to avoid unique constraint error
      final existing = await _db.getUserByEmail(email);
      if (existing == null) {
        await _db.insertUser(UsersCompanion(
            email: drift.Value(email),
            name: drift.Value(name),
            passwordHash: const drift.Value('FIREBASE_AUTH'),
            role: drift.Value(role),
            createdAt: drift.Value(DateTime.now()),
        ));
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

        // We need the Firebase UID to delete via Cloud Function?
        // Wait, the Cloud Function 'deleteUser' takes 'userId' which is the UID.
        // We only have Int ID here.
        // We need to look up the UID from Firestore using the email?
        // Or we should store UID in local DB.

        // Problem: We don't have UID stored locally.
        // Solution: Query Firestore by email to get UID.
        final query = await _firestore.collection('users').where('email', isEqualTo: localUser.email).get();
        if (query.docs.isEmpty) {
             // User not in Firestore? Just delete locally.
             await _db.deleteUser(userId);
             return;
        }
        final uid = query.docs.first.id;

        final callable = _functions.httpsCallable('deleteUser');
        await callable.call({'userId': uid});

        await _db.deleteUser(userId);
    } catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<void> updateUserPassword(int userId, String newPassword) async {
     try {
        final localUser = await _db.getUserById(userId);
        if (localUser == null) throw const UserNotFoundException();

        final query = await _firestore.collection('users').where('email', isEqualTo: localUser.email).get();
        if (query.docs.isEmpty) throw const UserNotFoundException();
        final uid = query.docs.first.id;

        final callable = _functions.httpsCallable('resetUserPassword');
        await callable.call({
            'userId': uid,
            'newPassword': newPassword
        });

        // No local update needed as we don't store real hash
    } catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<List<UserEntity>> getAllUsers() {
    return _db.getAllUsers();
  }

  @override
  Future<void> registerAdmin(String email, String name, String password) async {
      // This is usually for first launch.
      // We can use createUser callable? But that requires Admin.
      // So this method is likely creating the FIRST user.
      // Firebase allows creating users without auth if enabled, but usually we use Console.
      // Or we can just use createUser normally if we are authenticated?
      // If no users exist, we can't be authenticated as admin.
      // So this method might be redundant for Firebase setup where we create first admin via Console/Script.
      // I'll throw Unimplemented or implement a check.
      // Prompt said: "Fresh Firebase Auth setup... Phase 1... Créer premier admin via Cloud Function".
      // But Cloud Function is callable. Who calls it?
      // Admin should be created via Console as per prompt instructions.
      // So registerAdmin might not be needed.
      throw UnimplementedError("L'administrateur initial doit être créé via la console Firebase.");
  }

  @override
  Future<bool> hasAnyUser() async {
    return true;
  }

  @override
  Future<void> requestOtp(String email) async {
    throw UnimplementedError("OTP non supporté dans cette version.");
  }

  @override
  Future<bool> verifyOtp(String email, String code) async {
    throw UnimplementedError("OTP non supporté dans cette version.");
  }
}
