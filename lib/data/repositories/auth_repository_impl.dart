import 'dart:convert';
import 'package:crypto/crypto.dart';
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

  AuthRepositoryImpl(this._db, this._storage);

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  @override
  Future<void> seedDefaultAdmin() async {
    final count = await _db.countUsers();
    if (count == 0) {
      // Seed default admin
      await _db.insertUser(
        UsersCompanion(
          email: const drift.Value('admin@courtcare.com'),
          name: const drift.Value('Super Admin'),
          passwordHash: drift.Value(_hashPassword('admin123')),
          role: const drift.Value(Role.admin),
          createdAt: drift.Value(DateTime.now()),
        ),
      );
      // Seed an Agent
      await _db.insertUser(
        UsersCompanion(
          email: const drift.Value('agent@courtcare.com'),
          name: const drift.Value('Maintenance Agent'),
          passwordHash: drift.Value(_hashPassword('agent123')),
          role: const drift.Value(Role.agent),
          createdAt: drift.Value(DateTime.now()),
        ),
      );
       // Seed a Secretary
      await _db.insertUser(
        UsersCompanion(
          email: const drift.Value('secretariat@courtcare.com'),
          name: const drift.Value('Secrétaire'),
          passwordHash: drift.Value(_hashPassword('secret123')),
          role: const drift.Value(Role.secretary),
          createdAt: drift.Value(DateTime.now()),
        ),
      );
    }
  }

  @override
  Future<UserEntity?> signIn(String email, String password) async {
    final userRow = await _db.getUserRowByEmail(email);
    if (userRow == null) return null;

    final inputHash = _hashPassword(password);
    if (userRow.passwordHash == inputHash) {
      // Success
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
    return code == '1234'; // Mock
  }
}
