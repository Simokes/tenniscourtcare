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

import '../../core/security/auth_exceptions.dart';
import '../../core/security/auth_validator.dart';
import '../../core/security/token_service.dart';
import '../../core/security/rate_limiter.dart';
import '../../data/repositories/audit_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AppDatabase _db;
  final FlutterSecureStorage _storage;
  final TokenService _tokenService;
  final AuditRepository _auditRepository;
  final RateLimiter _rateLimiter;

  static const _authTokenKey = 'auth_token';

  // Configuration PBKDF2
  static const _pbkdf2Iterations = 100000;
  static const _hashLengthInBytes = 32; // 256 bits

  AuthRepositoryImpl(
    this._db,
    this._storage,
    this._tokenService,
    this._auditRepository,
    this._rateLimiter,
  );

  /// Génère un hash PBKDF2 sécurisé : $pbkdf2$iterations$salt(base64)$hash(base64)
  Future<String> _hashPassword(String password) async {
    final algorithm = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _pbkdf2Iterations,
      bits: _hashLengthInBytes * 8,
    );

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

    try {
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

      return _constantTimeEquals(actualHash, expectedHash);
    } catch (e) {
      // En cas d'erreur de décodage base64 ou autre, on retourne false
      return false;
    }
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  @override
  Future<bool> hasAnyUser() async {
    final count = await _db.countUsers();
    return count > 0;
  }

  @override
  Future<void> registerAdmin(String email, String name, String password) async {
    // 1. Validation des entrées
    AuthValidator.validateEmail(email);
    AuthValidator.validateName(name);
    AuthValidator.validatePassword(password);

    final hasUsers = await hasAnyUser();
    if (hasUsers) {
      throw SecurityException("L'initialisation de l'administrateur a déjà été effectuée.");
    }

    final passwordHash = await _hashPassword(password);

    final userId = await _db.insertUser(
      UsersCompanion(
        email: drift.Value(email),
        name: drift.Value(name),
        passwordHash: drift.Value(passwordHash),
        role: const drift.Value(Role.admin),
        createdAt: drift.Value(DateTime.now()),
      ),
    );

    await _auditRepository.logEvent(
      action: 'ADMIN_REGISTERED',
      email: email,
      userId: userId,
      details: {'name': name},
    );
  }

  @override
  Future<UserEntity?> signIn(String email, String password) async {
    // 1. Validation de base
    try {
      AuthValidator.validateEmail(email);
    } catch (e) {
      throw const InvalidCredentialsException();
    }

    // 2. Vérification Rate Limiting (Tier 1 & Tier 2)
    await _rateLimiter.checkLimit(email);

    try {
      // 3. Récupération utilisateur
      final userRow = await _db.getUserRowByEmail(email);

      if (userRow == null) {
        // Enregistre l'échec pour le rate limiting (sans révéler que l'email n'existe pas)
        await _rateLimiter.recordAttempt(email: email, success: false);
        throw const InvalidCredentialsException();
      }

      // 4. Vérification mot de passe
      final isValid = await _verifyPassword(password, userRow.passwordHash);

      if (!isValid) {
        await _rateLimiter.recordAttempt(email: email, success: false);
        throw const InvalidCredentialsException();
      }

      // 5. Succès
      await _rateLimiter.recordAttempt(email: email, success: true);

      // Génération Token JWT
      final token = await _tokenService.createToken(
        userId: userRow.id,
        email: userRow.email,
        role: userRow.role.name, // Enum name
      );

      // Stockage sécurisé du token
      await _storage.write(key: _authTokenKey, value: token);

      // Mise à jour dernière connexion
      await _db.updateLastLogin(userRow.id);

      // Log Audit
      await _auditRepository.logEvent(
        action: 'LOGIN_SUCCESS',
        email: email,
        userId: userRow.id,
      );

      return userRow.toDomain();

    } catch (e) {
      // Si c'est déjà une AuthException, on la propage
      if (e is AuthException) rethrow;
      // Sinon on masque l'erreur interne
      throw const InvalidCredentialsException();
    }
  }

  @override
  Future<void> signOut() async {
    final user = await getCurrentUser();
    if (user != null) {
      await _auditRepository.logEvent(
        action: 'LOGOUT',
        email: user.email,
        userId: user.id,
      );
    }
    await _storage.delete(key: _authTokenKey);
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final token = await _storage.read(key: _authTokenKey);
      if (token == null) return null;

      final payload = await _tokenService.verifyToken(token);
      final email = payload['email'] as String;

      final user = await _db.getUserByEmail(email);
      if (user == null) {
        // Utilisateur supprimé ou invalide
        await signOut();
        return null;
      }
      return user;

    } on SessionExpiredException {
      await signOut();
      throw const SessionExpiredException(); // UI should handle redirect
    } catch (e) {
      // Token invalide ou autre erreur
      await signOut();
      return null;
    }
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
