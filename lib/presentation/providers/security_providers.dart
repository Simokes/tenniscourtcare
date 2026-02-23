import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/security/token_service.dart';
import '../../core/security/rate_limiter.dart';
import '../../data/repositories/audit_repository.dart';
import 'core_providers.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final tokenServiceProvider = Provider<TokenService>((ref) {
  return TokenService(ref.watch(secureStorageProvider));
});

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return AuditRepository(ref.watch(databaseProvider));
});

final rateLimiterProvider = Provider<RateLimiter>((ref) {
  return RateLimiter(ref.watch(auditRepositoryProvider));
});
