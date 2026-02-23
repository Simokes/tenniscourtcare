import 'dart:convert';
import 'dart:math';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_exceptions.dart';

class TokenService {
  final FlutterSecureStorage _storage;
  static const _jwtSecretKey = 'jwt_secret_key';

  // Cache the secret in memory after loading
  SecretKey? _secretKey;

  TokenService(this._storage);

  /// Initializes the service by loading or generating the secret key.
  Future<void> init() async {
    String? secret = await _storage.read(key: _jwtSecretKey);

    if (secret == null) {
      // Generate a strong random secret (32 bytes / 256 bits)
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      secret = base64Url.encode(values);
      await _storage.write(key: _jwtSecretKey, value: secret);
    }

    _secretKey = SecretKey(secret);
  }

  /// Creates a signed JWT for the user.
  /// Expiry is set to 1 hour by default.
  Future<String> createToken({
    required int userId,
    required String email,
    required String role,
    Duration expiresIn = const Duration(hours: 1),
  }) async {
    if (_secretKey == null) await init();

    final jwt = JWT(
      {
        'id': userId,
        'email': email,
        'role': role,
      },
      issuer: 'TennisCourtCare',
    );

    return jwt.sign(_secretKey!, expiresIn: expiresIn);
  }

  /// Verifies the token signature and expiration.
  /// Returns the payload as a Map if valid.
  /// Throws [SessionExpiredException] or [SecurityException] if invalid.
  Future<Map<String, dynamic>> verifyToken(String token) async {
    if (_secretKey == null) await init();

    try {
      final jwt = JWT.verify(token, _secretKey!);
      return jwt.payload as Map<String, dynamic>;
    } on JWTExpiredException {
      throw const SessionExpiredException();
    } on JWTException catch (e) {
      throw SecurityException('Token invalide: ${e.message}');
    } catch (e) {
      throw SecurityException('Erreur de validation du token', originalError: e);
    }
  }
}
