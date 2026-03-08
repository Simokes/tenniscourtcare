# CLAUDE.md

**Version:** 2.2
**Last Updated:** 2026-03-08
**Target:** Claude Sonnet 4.6 & Jules Agent (jules.google.com)

---

## 0. Lecture Contextuelle — Optimisation Tokens

MEMORY.md est chargé automatiquement à chaque session. Il contient les règles essentielles.
Lire les fichiers de référence uniquement si la tâche le requiert :

| Type de tâche | Fichiers à lire |
|---------------|-----------------|
| Review PR (refactor UI, tokens) | Aucun — MEMORY.md suffit |
| Review PR (logique métier, architecture) | `.github/ai_rules.md` §3-4 + `.github/architecture.md` |
| Nouvelle feature | `.github/ai_rules.md` + `.github/architecture.md` + `.github/coding_rules.md` |
| Bug fix simple | Aucun — lire uniquement les fichiers impactés |
| Bug fix architectural | `.github/architecture.md` + `.github/coding_rules.md` |
| Refactoring / audit UI | Aucun — MEMORY.md suffit |
| Planification / roadmap | `.github/project_summary.md` + `.github/feature_workflow.md` |

**Règle :** Ne lire un fichier de référence que si une question spécifique à son contenu se pose.
**Conflit :** AI_RULES.md > ARCHITECTURE.md > CODING_RULES.md

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

## 2. Architecture & Data Flow — Résumé

```
Firebase = WRITE only (source de vérité)
Drift    = READ only  (cache local, alimenté par FirebaseCacheService)

WRITE : UI → AsyncNotifier → Repository → Firestore → FirebaseCacheService → Drift → UI
READ  : UI → StreamProvider → Drift stream → UI
```

Après écriture Firestore : persister `firebaseId` dans Drift immédiatement (pas d'attente listener).
Détail complet : `.github/architecture.md`

---

## 3. Layer Rules (résumé)

```
Presentation → Domain + Data   (pas d'imports circulaires)
Data         → Domain only     (pas de Flutter/Riverpod)
Domain       → Dart pur        (pas de Flutter/Riverpod/Drift/Firestore)
Shared       → importable partout (ne peut pas importer features/)
```

---

## 4. Key Reference Files

| Responsibility | Path |
|----------------|------|
| Router & Navigation Gates | `lib/core/router/app_router.dart` |
| Database Schema | `lib/data/database/app_database.dart` |
| Firebase Cache Service | `lib/data/services/firebase_cache_service.dart` |
| Theme / Design tokens | `lib/core/theme/app_theme.dart` + `dashboard_theme_extension.dart` |
| Auth Logic & Providers | `lib/features/auth/providers/` |
| Feature Roadmap | `.github/project_summary.md` |
| Architecture détaillée | `.github/architecture.md` |
| Coding rules détaillées | `.github/coding_rules.md` |

---

## 5. Forbidden Patterns (mémo rapide)

```dart
❌ print()              → debugPrint()
❌ .then() chains       → async/await
❌ magic numbers        → const nommées
❌ logique dans widget  → providers uniquement
❌ Flutter dans domain  → Dart pur uniquement
❌ écriture Drift directe → FirebaseCacheService (sauf firebaseId post-write)
❌ modifier *.g.dart    → build_runner uniquement
❌ params positionnels  → named parameters obligatoires
❌ force-unwrap (!)     → safe cast avec ?? fallback
```

---

## 6. Checklist Commit

```
☐ flutter analyze → 0 erreurs
☐ flutter test    → 0 failures
☐ build_runner    → si schema/provider modifié
☐ ARCHITECTURE.md → si logique métier changée
☐ PROJECT_SUMMARY.md → si feature ajoutée
```

---

**Last Updated:** 2026-03-08
**Version:** 2.2
**Target:** Claude Sonnet 4.6 & Jules Agent
**Schema Version:** v23
``