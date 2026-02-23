import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:drift/drift.dart' as drift;

import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/enums/role.dart';
import '../database/app_database.dart';
import '../mappers/user_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AppDatabase _db;
  final FlutterSecureStorage _storage;

  static const _sessionKey = 'current_user_email';

  // Configuration PBKDF2
  static const _pbkdf2Iterations = 100000;
  static const _hashLengthInBytes = 32; // 256 bits

  AuthRepositoryImpl(this._db, this._storage);

  /// Génère un hash PBKDF2 sécurisé : $pbkdf2$iterations$salt(base64)$hash(base64)
  Future<String> _hashPassword(String password) async {
    final algorithm = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _pbkdf2Iterations,
      bits: _hashLengthInBytes * 8,
    );

    // Générer un sel aléatoire de 16 octets
    // Note: cryptography package uses SecretKey for generic key material
    // We can use a simpler approach for random bytes if needed, but this works.
    // Or just use Dart's Random.secure() but let's stick to the package if convenient.
    // Actually, `SecretKeyData.random` is part of `cryptography`.
    final nonce = SecretKeyData.random(length: 16);
    final salt = await nonce.extractBytes();

    final secretKey = await algorithm.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    final secretKeyBytes = await secretKey.extractBytes();

    final saltB64 = base64.encode(salt);
    final hashB64 = base64.encode(secretKeyBytes);

    return '\$pbkdf2\$$_pbkdf2Iterations\$$saltB64\$$hashB64';
  }

  /// Vérifie le mot de passe en recalculant le hash avec les paramètres extraits
  Future<bool> _verifyPassword(String password, String storedHash) async {
    // Format attendu: $pbkdf2$iterations$salt$hash
    if (!storedHash.startsWith('\$pbkdf2\$')) return false;

    final parts = storedHash.split('\$');
    if (parts.length != 5) return false;

    final iterations = int.tryParse(parts[2]);
    final saltB64 = parts[3];
    final hashB64 = parts[4];

    if (iterations == null) return false;

    final salt = base64.decode(saltB64);
    final expectedHash = base64.decode(hashB64);

    final algorithm = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: expectedHash.length * 8,
    );

    final secretKey = await algorithm.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    final actualHash = await secretKey.extractBytes();

    // Comparaison basique (pourrait être améliorée en temps constant)
    if (actualHash.length != expectedHash.length) return false;
    for (var i = 0; i < actualHash.length; i++) {
      if (actualHash[i] != expectedHash[i]) return false;
    }
    return true;
  }

  @override
  Future<bool> hasAnyUser() async {
    final count = await _db.countUsers();
    return count > 0;
  }

  @override
  Future<void> registerAdmin(String email, String name, String password) async {
    final hasUsers = await hasAnyUser();
    if (hasUsers) {
      throw Exception("L'initialisation de l'administrateur a déjà été effectuée.");
    }

    final passwordHash = await _hashPassword(password);

    await _db.insertUser(
      UsersCompanion(
        email: drift.Value(email),
        name: drift.Value(name),
        passwordHash: drift.Value(passwordHash),
        role: const drift.Value(Role.admin),
        createdAt: drift.Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<UserEntity?> signIn(String email, String password) async {
    final userRow = await _db.getUserRowByEmail(email);
    if (userRow == null) return null;

    final isValid = await _verifyPassword(password, userRow.passwordHash);

    if (isValid) {
      // Succès
      await _storage.write(key: _sessionKey, value: email);
      await _db.updateLastLogin(userRow.id);
      return userRow.toDomain();
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    await _storage.delete(key: _sessionKey);
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final email = await _storage.read(key: _sessionKey);
    if (email != null) {
      return _db.getUserByEmail(email);
    }
    return null;
  }

  @override
  Future<void> requestOtp(String email) async {
    // TODO: implement real OTP
    // Mock implementation
  }

  @override
  Future<bool> verifyOtp(String email, String code) async {
    // Isolé avec kDebugMode pour la sécurité en production
    if (kDebugMode) {
      return code == '1234';
    }
    return false;
  }
}
