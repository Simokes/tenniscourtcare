# CLAUDE.md

**Version:** 2.0
**Last Updated:** 2025
**Target:** Claude 3.5 Sonnet & Jules Agent (jules.google.com)

---

## 🛑 MANDATORY — Read Before Any Task

Before performing **any** task, you **MUST** read and strictly adhere to these documents in order:

| Priority | Document | Purpose |
|----------|----------|---------|
| 1 | `AI_RULES.md` | Roles, autorisation, workflow Claude ↔ Jules |
| 2 | `ARCHITECTURE.md` | Schema v22, layer boundaries, patterns |
| 3 | `CODING_RULES.md` | Naming, widget structure, forbidden patterns |
| 4 | `PROJECT_SUMMARY.md` | Roadmap, priorités critiques, dette technique |
| 5 | `FEATURE_WORKFLOW.md` | Processus feature complète (analyse → merge) |

**Conflict resolution:**
```
AI_RULES.md > ARCHITECTURE.md > CODING_RULES.md
```

---

## 1. Project Commands

```bash
# Install dependencies
flutter pub get

# Code generation (Drift/Riverpod) — MANDATORY after schema/provider changes
flutter pub run build_runner build --delete-conflicting-outputs

# Analysis
flutter analyze

# Tests
flutter test
flutter test test/path/to/test_file.dart

# Run app
flutter run
```

> ⚠️ **Never manually edit `*.g.dart` files** — always regenerate with `build_runner`.

---

## 2. Architecture & Data Flow (v22)

### 2.1 Règle Critique

```
Firebase (Firestore) = Source de Vérité  →  WRITE only
Drift (SQLite)       = Cache local       →  READ only
```

### 2.2 Write Flow

```
UI
 ↓ action utilisateur
AsyncNotifier
 ↓ appel métier
Repository
 ↓ écriture
Firestore
 ↓ listener temps réel
FirebaseCacheService
 ↓ upsert local
Drift
 ↓ stream réactif
UI rebuilt ✅
```

### 2.3 Read Flow

```
UI
 ↓ ref.watch(xxxProvider)
StreamProvider<T>
 ↓ watch Drift stream
Drift
 ↓ emit List<Entity>
UI rebuilt ✅
```

### 2.4 Exception — firebaseId Persistence

Après chaque écriture Firestore, l'`AsyncNotifier` doit **immédiatement** persister le `firebaseId` dans Drift **sans attendre** le listener :

```dart
// ✅ Pattern obligatoire après addDocument()
final docRef = await _fs.collection('items').add(data);
await _db.upsertItem(
  item.copyWith(firebaseId: docRef.id).toCompanion(),
);
```

> **Pourquoi :** Le listener `FirebaseCacheService` peut avoir un délai.
> L'ID doit être disponible localement immédiatement.

### 2.5 FirebaseCacheService

```
✅ Seul composant autorisé à écrire dans le cache Drift
✅ Écoute les snapshots Firestore en temps réel
✅ Applique upsert/delete sur Drift selon DocumentChangeType
❌ Jamais bypasser FirebaseCacheService pour les lectures sync
```

---

## 3. Layer Dependency Rules

```
┌─────────────────────────────────────────┐
│  Presentation (features/)               │
│  ✅ Peut importer: Domain + Data        │
│  ❌ Pas de: imports circulaires         │
│           features importent features   │
└────────────────┬────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│  Data (data/)                           │
│  ✅ Peut importer: Domain               │
│  ❌ Pas de: Flutter, Riverpod           │
└────────────────┬────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│  Domain (domain/)                       │
│  ✅ Dart pur uniquement                 │
│  ❌ Pas de: Flutter, Riverpod,          │
│            Drift, Firestore             │
└─────────────────────────────────────────┘

Shared (shared/):
  ✅ Peut être importé par tous les layers
  ❌ Ne peut pas importer depuis lib/features/
```

---

## 4. Technical Patterns

### 4.1 Riverpod Providers

| Usage | Provider Type | Exemple |
|-------|---------------|---------|
| Lecture Drift (réactive) | `StreamProvider<T>` | `terrainsProvider` |
| Mutations async | `AsyncNotifierProvider` | `maintenanceNotifierProvider` |
| État UI local | `StateProvider<T>` | `selectedTabProvider` |
| Auth / Setup gate | `FutureProvider<SetupStatus>` | `setupStatusProvider` |

```dart
// ✅ Read — StreamProvider
final terrainsProvider = StreamProvider<List<Terrain>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllTerrains();
});

// ✅ Mutation — AsyncNotifier
class MaintenanceNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addMaintenance(Maintenance m) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(maintenanceRepositoryProvider).addMaintenance(m);
    });
  }
}
```

### 4.2 Drift Upsert Pattern

```dart
// ✅ Pattern obligatoire pour tous les upserts Drift
Future<void> upsertItem(ItemsCompanion companion) async {
  final existing = await (select(items)
    ..where((t) => t.firebaseId.equals(companion.firebaseId.value!)))
    .getSingleOrNull();

  if (existing != null) {
    await update(items).replace(
      companion.copyWith(id: Value(existing.id)),
    );
  } else {
    await into(items).insert(companion);
  }
}
```

### 4.3 Error Handling Pattern

```dart
// ✅ Obligatoire sur toutes les fonctions async de repository
Future<void> doSomething() async {
  try {
    await _fs.collection('items').add(data);
  } on FirebaseException catch (e) {
    debugPrint('❌ Repository: Failed: ${e.message}');
    throw RepositoryException('Failed: ${e.message}', cause: e);
  }
}
```

### 4.4 Domain Entity Pattern

```dart
// ✅ Toutes les entités domain doivent respecter ce pattern
@immutable
class Terrain {
  const Terrain({
    required this.id,
    required this.nom,
    required this.status,
  });

  final int? id;
  final String nom;
  final TerrainStatus status;

  Terrain copyWith({int? id, String? nom, TerrainStatus? status}) =>
    Terrain(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      status: status ?? this.status,
    );

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Terrain && id == other.id && nom == other.nom;

  @override
  int get hashCode => id.hashCode ^ nom.hashCode;

  @override
  String toString() => 'Terrain{id: $id, nom: $nom, status: $status}';
}
```

---

## 5. Key Reference Files

| Responsibility | Path |
|----------------|------|
| Router & Navigation Gates | 

app_router.dart

 |
| Database Schema (v22) | 

app_database.dart

 |
| Firebase Cache Service | 

firebase_cache_service.dart

 |
| Auth Logic & Providers | 

providers

 |
| AI Decisions Log | `/ai_log/decisions.md` |
| Feature Roadmap | `PROJECT_SUMMARY.md` |

---

## 6. Forbidden Patterns

```dart
❌ print()                    // → utiliser debugPrint()
❌ .then() chains             // → utiliser async/await
❌ magic numbers              // → utiliser const nommées
❌ logique métier dans widget // → providers uniquement
❌ import Flutter dans domain // → Dart pur uniquement
❌ écriture Drift directe     // → passer par FirebaseCacheService
   (sauf exception firebaseId, cf. §2.4)
❌ modifier *.g.dart          // → build_runner uniquement
❌ paramètres positionnels    // → named parameters obligatoires
   dans les APIs publiques
```

---

## 7. Checklist Avant Tout Commit

```
☐ flutter analyze → 0 erreurs
☐ flutter test    → 0 failures
☐ build_runner    → exécuté si schema/provider modifié
☐ ARCHITECTURE.md → mis à jour si logique métier changée
☐ PROJECT_SUMMARY.md → mis à jour si feature ajoutée
☐ Pas de credentials ou données sensibles dans le code
☐ Error handling présent (try/catch + RepositoryException)
☐ Tests unitaires ajoutés pour entités/repositories nouveaux
```

---

## 8. Project Structure (Feature-First)

```
lib/
├── core/
│   ├── router/          # app_router.dart — navigation gates
│   ├── providers/       # core providers (db, auth...)
│   └── theme/           # design system
├── domain/
│   ├── entities/        # @immutable classes, Dart pur
│   ├── repositories/    # interfaces abstraites
│   └── logic/           # business logic pure (no Flutter)
├── data/
│   ├── database/        # Drift schema + DAOs
│   ├── repositories/    # implementations
│   ├── mappers/         # Firestore ↔ Domain ↔ Drift
│   └── services/        # firebase_cache_service.dart
├── features/
│   ├── auth/
│   ├── home/
│   ├── maintenance/
│   ├── terrain/
│   ├── inventory/
│   ├── calendar/
│   └── settings/
└── shared/
    ├── widgets/         # widgets réutilisables
    └── extensions/      # Dart extensions
```

---

**Last Updated:** 2025
**Target:** Claude 3.5 Sonnet & Jules Agent
**Schema Version:** v22
```