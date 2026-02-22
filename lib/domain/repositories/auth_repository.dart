import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Connecte un utilisateur avec email et mot de passe.
  /// Retourne l'utilisateur si succès, sinon null (ou throws).
  Future<UserEntity?> signIn(String email, String password);

  /// Déconnecte l'utilisateur courant.
  Future<void> signOut();

  /// Récupère l'utilisateur actuellement connecté (via session persistée).
  Future<UserEntity?> getCurrentUser();

  /// (Optionnel) Demande un code OTP.
  Future<void> requestOtp(String email);

  /// (Optionnel) Vérifie un code OTP.
  Future<bool> verifyOtp(String email, String code);

  /// Initialise la base avec un admin par défaut si aucun utilisateur n'existe.
  Future<void> seedDefaultAdmin();
}
