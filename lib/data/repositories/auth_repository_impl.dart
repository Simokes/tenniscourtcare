import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:math';

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

  /// Génère un OTP à 6 chiffres sécurisé
  String _generateSecureOtp() {
    final random = Random.secure();
    String otp = '';
    for (int i = 0; i < 6; i++) {
      otp += random.nextInt(10).toString();
    }
    return otp;
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
    // 1. Validation
    AuthValidator.validateEmail(email);

    // 2. Rate Limiting pour OTP
    await _rateLimiter.checkOtpLimit(email);

    // 3. Génération OTP
    final otp = _generateSecureOtp();
    final hashedOtp = await _hashPassword(otp);

    // 4. Stockage (Expiration 5 minutes)
    final expiresAt = DateTime.now().add(const Duration(minutes: 5));

    // Récupérer userId si existe (optionnel)
    final user = await _db.getUserRowByEmail(email);

    await _db.insertOtp(
      OtpRecordsCompanion(
        email: drift.Value(email),
        hashedOtp: drift.Value(hashedOtp),
        expiresAt: drift.Value(expiresAt),
        userId: drift.Value(user?.id),
        createdAt: drift.Value(DateTime.now()),
      ),
    );

    // Update rate limiter memory
    _rateLimiter.recordOtpRequest(email);

    // 5. Audit
    await _auditRepository.logEvent(
      action: 'OTP_REQUESTED',
      email: email,
      userId: user?.id,
    );

    // TODO: Envoyer l'email réel
    if (kDebugMode) {
      print('OTP pour $email: $otp');
    }
  }

  @override
  Future<bool> verifyOtp(String email, String code) async {
    // 1. Récupérer le dernier OTP valide
    final otpRecord = await _db.getLatestValidOtp(email);

    if (otpRecord == null) {
      // Pas d'OTP valide trouvé (expiré ou inexistant)
      // Log failed attempt via RateLimiter?
      // Maybe simple log for now.
      await _auditRepository.logEvent(action: 'OTP_VERIFY_FAILED', email: email);
      return false;
    }

    // 2. Vérifier le hash
    final isValid = await _verifyPassword(code, otpRecord.hashedOtp);

    if (isValid) {
      // 3. Consommer l'OTP
      await _db.deleteOtp(otpRecord.id);

      await _auditRepository.logEvent(action: 'OTP_VERIFY_SUCCESS', email: email);
      return true;
    } else {
      await _auditRepository.logEvent(action: 'OTP_VERIFY_FAILED', email: email);
      return false;
    }
  }
}
