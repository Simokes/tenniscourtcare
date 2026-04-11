# Règles Projet — CourtCare (Flutter / Firebase / Drift)

## Architecture — Flux obligatoires

WRITE : UI -> AsyncNotifier -> Repository -> Firestore -> FirebaseCacheService -> Drift -> UI
READ  : UI -> StreamProvider -> Drift stream -> UI

Après écriture Firestore : persister firebaseId dans Drift immédiatement (pas d'attente listener).
FirebaseCacheService est le SEUL composant autorisé à écrire dans Drift.

## Providers Riverpod

- Lecture Drift    : StreamProvider<T>
- Mutations        : AsyncNotifierProvider
- État UI local    : StateProvider<T>
- Auth/Setup       : FutureProvider<SetupStatus>

## Schéma DB — v24

Toutes les tables ont : id (int?), firebaseId (String?), createdAt, updatedAt
Colonnes SUPPRIMÉES (ne pas réintroduire) : syncStatus, pendingSync, lastSyncedAt
Terrains : +closureReason (TEXT nullable), +closureUntil (DATETIME nullable)

## Layers

Presentation → Domain + Data   (pas d'imports circulaires)
Data         → Domain only     (pas de Flutter/Riverpod)
Domain       → Dart pur        (pas de Flutter/Riverpod/Drift/Firestore)
Shared       → importable partout (ne peut pas importer features/)

## Vérification obligatoire avant push

1. flutter analyze  — 0 erreurs
2. flutter test     — 0 failures
3. flutter pub run build_runner build --delete-conflicting-outputs  — si schema/provider modifié
