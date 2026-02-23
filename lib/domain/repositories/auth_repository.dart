import '../entities/user_entity.dart';
import '../enums/role.dart';

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

  /// Vérifie s'il existe au moins un utilisateur en base (pour le premier lancement).
  Future<bool> hasAnyUser();

  /// Crée le premier utilisateur Administrateur.
  Future<void> registerAdmin(String email, String name, String password);

  /// Crée un nouvel utilisateur (Agent ou Admin) avec hashage sécurisé.
  Future<void> createUser({
    required String email,
    required String name,
    required String password,
    required Role role,
  });

  /// Supprime un utilisateur par son ID.
  Future<void> deleteUser(int userId);

  /// Met à jour le mot de passe d'un utilisateur (reset).
  Future<void> updateUserPassword(int userId, String newPassword);

  /// Récupère la liste de tous les utilisateurs.
  Future<List<UserEntity>> getAllUsers();
}
