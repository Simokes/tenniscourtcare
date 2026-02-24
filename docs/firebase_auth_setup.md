# Firebase Authentication Setup

Ce document détaille la configuration de l'authentification Firebase pour l'application Tennis Court Care.

## 1. Vue d'ensemble

L'authentification utilise **Firebase Authentication** comme source de vérité pour les identités utilisateurs, tout en synchronisant les utilisateurs vers une base de données locale **SQLite** (Drift) pour maintenir les relations de clés étrangères existantes (Maintenances, Stocks, etc.).

### Architecture
- **Firebase Auth**: Gestion des emails, mots de passe, et sessions.
- **Firestore**: Stockage des métadonnées utilisateurs et déclenchement des rôles.
- **Cloud Functions**: Gestion backend sécurisée (création utilisateurs, suppression, gestion des rôles via Custom Claims).
- **SQLite (Local)**: Cache des utilisateurs pour le fonctionnement hors-ligne et l'intégrité référentielle.

## 2. Configuration Requise

### Firebase Console
1. Activer **Authentication**.
2. Activer le provider **Email/Password**.
3. Activer **Firestore Database**.
4. Activer **Functions**.

### Environnement Local
- Node.js 20+
- Firebase CLI (`npm install -g firebase-tools`)
- Flutter SDK

## 3. Déploiement des Cloud Functions

Les fonctions backend se trouvent dans le dossier `functions/`.

1. Initialiser l'environnement :
   ```bash
   cd functions
   npm install
   ```

2. Déployer vers Firebase :
   ```bash
   firebase deploy --only functions
   ```

### Liste des Fonctions
- `createUser` (Callable): Création d'utilisateur par un administrateur.
- `deleteUser` (Callable): Suppression d'utilisateur.
- `resetUserPassword` (Callable): Réinitialisation de mot de passe.
- `updateUserRole` (Callable): Modification de rôle.
- `onCreateUser` (Trigger): Crée le document Firestore lors de l'inscription (si nécessaire).
- `onUpdateUser` (Trigger): Met à jour les Custom Claims Firebase lorsque le rôle change dans Firestore.

## 4. Fonctionnement de l'Application

### Synchronisation Local ↔ Cloud (CRITIQUE)

La synchronisation entre Firebase et Drift (SQLite) repose sur une colonne `firestore_uid` dans la table `users`.

- **Identifiant Unique (UID)** : Généré par Firebase Auth.
- **Clé Primaire Locale (`id`)** : Entier auto-incrémenté généré par SQLite.
- **Mapping** : Chaque utilisateur local stocke son UID Firebase dans la colonne `firestore_uid`.

**Règle d'Or : Synchroniser TOUJOURS par UID, JAMAIS par email.**

Exemple de flux :
1. Firebase Auth crée un utilisateur → `uid = 'abc123xyz'`
2. Firestore créé un document avec le même ID → `doc('users/abc123xyz')`
3. L'application mobile (Drift) cherche l'utilisateur : `WHERE firestore_uid = 'abc123xyz'`

Si on synchronisait par email, un changement d'email ou une suppression/récréation de compte briserait le lien avec les données locales existantes.

### Rôles et Permissions
Les rôles sont gérés via des **Custom Claims** dans le token JWT de Firebase.
- `admin`: Accès complet.
- `agent`: Maintenance et stocks.
- `secretary`: Planning (lecture seule sur stocks).

Le rôle est défini dans Firestore (`users/{uid}/role`) et propagé vers le token Auth par la fonction `onUpdateUser`.

### Création du Premier Administrateur
Puisque la fonction `createUser` nécessite d'être déjà authentifié en tant qu'administrateur, le premier administrateur doit être créé manuellement :

1. Créer un utilisateur dans la **Firebase Console** (Auth).
2. Créer le document correspondant dans **Firestore** :
   - Collection: `users`
   - Document ID: `<UID de l'utilisateur>`
   - Champs:
     - `uid`: `<UID>`
     - `email`: `<Email>`
     - `role`: `admin`
     - `name`: `Admin Initial`
3. La fonction `onUpdateUser` se déclenchera et attribuera le claim `admin`.
4. Connectez-vous dans l'application avec cet utilisateur.

## 5. Tests d'Intégration

Un test d'intégration est disponible dans `integration_test/firebase_auth_integration_test.dart`.
Il utilise les émulateurs Firebase pour valider le cycle complet sans affecter la production.

Lancer les émulateurs :
```bash
firebase emulators:start
```

Lancer le test :
```bash
flutter test integration_test/firebase_auth_integration_test.dart
```
