# FEATURE_WORKFLOW.md

**Version:** 2.0
**Last Updated:** 2025
**Review cycle:** Chaque phase majeure du projet ou trimestriel

---

## Purpose

Définir le processus obligatoire pour développer une nouvelle feature.
Aucune feature ne doit être implémentée hors de ce workflow.

---

## Vue d'ensemble du Flux

```
Humain (Demande)
     ↓
Claude (Analyse & Planification)
     ↓
Humain (Validation Architecture)
     ↓
Jules (Implémentation + Doc + Tests)
     ↓
Claude (Code Review)
     ↓
Humain (Review Finale & Merge)
     ↓
Claude (AI Log)
     ↓
Jules (Cleanup branche)
```

---

## Étape 1 — Feature Definition (Humain)

### 1.1 Feature Description
- Description fonctionnelle claire
- Problème utilisateur résolu
- Résultat attendu

### 1.2 Scope
- Ce qui est inclus ✅
- Ce qui est explicitement exclu ❌

### 1.3 Acceptance Criteria
- Liste précise et testable
- Conditions de validation mesurables

---

## Étape 2 — Architecture Validation (Claude)

### 2.1 Inputs requis
- PROJECT_SUMMARY.md
- ARCHITECTURE.md
- CODING_RULES.md
- Description de la feature (Étape 1)

### 2.2 Checklist d'Analyse Obligatoire

```
☐ Impact Schéma : Faut-il bumper la version DB Drift ?
☐ Impact Layers : presentation / domain / data impactés ?
☐ Impact Doc : ARCHITECTURE.md devient-il obsolète ?
☐ Impact Doc : PROJECT_SUMMARY.md devient-il obsolète ?
☐ Nouvelles tables/entités → à documenter
☐ Nouveaux providers → à documenter
☐ Nouveaux flows → à documenter
☐ Risques techniques identifiés
☐ Dette technique potentielle évaluée
```

### 2.3 Output Obligatoire de Claude

Claude doit fournir **avant toute ligne de code** :

1. **Impact sur les layers** (presentation / domain / data)
2. **Nouveaux fichiers** à créer (avec chemins complets)
3. **Fichiers existants** à modifier
4. **Nouveaux providers Riverpod** nécessaires
5. **Domain entities** impactées
6. **Contenu exact** des mises à jour ARCHITECTURE.md (si requis)
7. **Contenu exact** des mises à jour PROJECT_SUMMARY.md (si requis)
8. **Risques techniques** et mitigations
9. **Dette technique** potentielle

### 2.4 Règle de Validation
```
❌ Aucune génération de code avant validation humaine
❌ Aucune modification de schema Drift sans bump de version
✅ L'architecture doit être approuvée EXPLICITEMENT par l'humain
```

---

## Étape 3 — Validation Humaine

### 3.1 Checklist de Validation

```
☐ Plan aligné avec les besoins métier
☐ Changements architecture acceptables
☐ Scope clairement défini
☐ Dépendances identifiées correctement
☐ Évaluation des risques réaliste
☐ Contenu doc à mettre à jour approuvé
```

### 3.2 Décision

```
PROCEED  → Jules peut commencer l'implémentation
REVISE   → Claude doit revoir le plan (retour Étape 2)
REJECT   → Feature annulée ou reportée
```

---

## Étape 4 — Implémentation (Jules)

### 4.1 Règles Strictes

```
✅ Respecter ARCHITECTURE.md strictement
✅ Respecter CODING_RULES.md strictement
✅ Mettre à jour les fichiers .md AVANT de coder (si requis)
✅ Inclure les tests unitaires pour chaque entité/repository créé
✅ Inclure doc comments (///) sur toutes les APIs publiques
✅ Error handling : try/catch + rethrow sur toutes les fonctions async
✅ Aucun changement structurel non validé par Claude
```

### 4.2 Ordre d'Exécution Obligatoire

```
1. Mettre à jour ARCHITECTURE.md (contenu fourni par Claude)
2. Mettre à jour PROJECT_SUMMARY.md (contenu fourni par Claude)
3. Implémenter les entités domain
4. Implémenter les repositories (interface + impl)
5. Implémenter les mappers
6. Implémenter les providers Riverpod
7. Implémenter les screens et widgets
8. Générer les tests unitaires (entités, repositories, providers)
9. Exécuter build_runner si Drift modifié
10. Exécuter flutter analyze → 0 erreurs
11. Exécuter flutter test → 0 failures
12. Ouvrir la PR
```

### 4.3 Format de Commit

```
feat: [description feature]

- impl: [fichiers code créés/modifiés]
- doc: [fichiers .md mis à jour]
- tests: [tests ajoutés/mis à jour]
```

### 4.4 Format de PR

```
## Feature
[Nom de la feature]

## Changements
- [Liste des fichiers créés]
- [Liste des fichiers modifiés]

## Documentation mise à jour
- [ ] ARCHITECTURE.md
- [ ] PROJECT_SUMMARY.md

## Tests
- [ ] Tests unitaires ajoutés
- [ ] flutter analyze → 0 erreurs
- [ ] flutter test → 0 failures

## Acceptance Criteria
- [ ] Critère 1
- [ ] Critère 2
```

### 4.5 Interdictions

```
❌ Aucune décision d'architecture
❌ Aucun changement structurel non validé
❌ Aucune modification de schema Drift sans validation
❌ Pas de pseudo-code dans les fichiers livrés
❌ Pas de TODO critique non résolu
❌ Code et doc NE PEUVENT PAS être dans des PR séparées
```

---

## Étape 5 — Code Review (Claude)

### 5.1 Scope de la Review

```
☐ Respect de ARCHITECTURE.md
☐ Respect des règles de dépendance (pas de circulaires)
☐ Domain sans imports Flutter/Riverpod
☐ Gestion correcte des erreurs (try/catch + rethrow)
☐ Pas de logique métier dans les widgets
☐ Cohérence naming (CODING_RULES.md)
☐ Tests unitaires présents pour entités/repositories
☐ Documentation .md cohérente avec le code
☐ Pas de magic numbers
☐ Pas de print() (debugPrint uniquement)
☐ Pas de .then() chains (async/await uniquement)
```

### 5.2 Décision

**Si APPROVED ✅:**
```
Claude signale: "APPROVED — Prêt pour review humaine"
→ Passer à l'Étape 6
```

**Si NEEDS_REVISION ❌:**
```
Claude fournit un rapport structuré:

RAPPORT DE RÉVISION
═══════════════════
Fichier: [chemin/fichier.dart]
Ligne: [X]
Type: [ARCHITECTURE | CODING_RULES | TESTS | DOC]
Problème: [description précise]
Correction attendue: [ce que Jules doit faire]

→ Jules doit corriger sur la même branche (nouveau commit)
→ Repasser par l'Étape 5 après correction
```

### 5.3 Règle de Refus

Claude refuse la PR si :
```
❌ Code modifié mais ARCHITECTURE.md non mis à jour
❌ Nouvelle table Drift non documentée
❌ Nouveau flow non documenté
❌ Version DB bumpée sans entrée migration
❌ Tests manquants pour entités/repositories
❌ flutter analyze → erreurs présentes
❌ flutter test → failures présents
❌ Logique métier dans les widgets
❌ Imports interdits dans domain/
```

---

## Étape 6 — UX Review (Gemini — Optionnel)

### 6.1 Scope
- Flow utilisateur
- Lisibilité et accessibilité
- États loading / error / empty correctement gérés
- Cohérence visuelle avec le design system
- Micro-interactions et feedback utilisateur

### 6.2 Output
- Suggestions UX uniquement
- Pas de modification technique directe
- Si changements nécessaires → retour à Jules (Étape 4)

---

## Étape 7 — Review Finale & Merge (Humain)

### 7.1 Checklist Finale

```
☐ Code compile sans erreurs
☐ Tests passants (flutter test → 0 failures)
☐ Fonctionnalité correcte (acceptance criteria validés)
☐ Documentation cohérente avec le code
☐ Pas de régression sur les features existantes
☐ UX acceptable
☐ Pas de credentials ou données sensibles
```

### 7.2 Décision

```
MERGE  → Humain merge la PR
REJECT → Retour à Jules avec commentaires (Étape 4)
```

### 7.3 Règle Absolue
```
❌ Jules NE PEUT PAS merger lui-même
❌ Claude NE PEUT PAS merger lui-même
✅ Le merge est EXCLUSIVEMENT effectué par l'humain
```

---

## Étape 8 — Closing the Loop (Claude + Jules)

### 8.1 AI Log (Claude)

Après merge, Claude rédige l'entrée pour `/ai_log/decisions.md` :

```markdown
## [Date] — [Nom de la Feature]

**Décision:** [Description de la décision architecturale]
**Contexte:** [Pourquoi cette approche a été choisie]
**Alternatives rejetées:** [Ce qui a été considéré mais écarté]
**Impact:** [Layers / fichiers impactés]
**Dette technique:** [Si applicable]
```

### 8.2 Cleanup (Jules)

Après merge confirmé par l'humain :
```
✅ Supprimer la branche locale
✅ Supprimer la branche remote (si non auto-deleted)
✅ Confirmer la suppression dans le thread
```

---

## Résumé des Responsabilités

| Étape | Responsable | Action |
|-------|-------------|--------|
| 1. Feature Definition | Humain | Définir le besoin |
| 2. Architecture Validation | Claude | Analyser + planifier |
| 3. Validation Humaine | Humain | Approuver le plan |
| 4. Implémentation | Jules | Coder + doc + tests |
| 5. Code Review | Claude | Valider ou rejeter |
| 6. UX Review | Gemini | Suggestions UX |
| 7. Review Finale & Merge | Humain | Merger la PR |
| 8. AI Log + Cleanup | Claude + Jules | Documenter + nettoyer |

---

## Checklist Compliance Avant Merge

```
ARCHITECTURE:
☐ Clean Architecture respectée (domain → data ← presentation)
☐ Dépendances unidirectionnelles
☐ Domain sans imports Flutter/Riverpod
☐ Firebase = source de vérité (écritures Firestore uniquement)
☐ Drift = cache local uniquement

CODE:
☐ CODING_RULES.md respectées
☐ Pas de logique métier dans les widgets
☐ Error handling présent (try/catch + rethrow)
☐ Pas de print() (debugPrint uniquement)
☐ Pas de .then() chains
☐ Pas de magic numbers

DOCUMENTATION:
☐ ARCHITECTURE.md mis à jour (même PR)
☐ PROJECT_SUMMARY.md mis à jour (même PR)
☐ /ai_log/decisions.md mis à jour (post-merge)

TESTS:
☐ Tests unitaires pour entités/repositories
☐ flutter analyze → 0 erreurs
☐ flutter test → 0 failures

GIT:
☐ Format de commit respecté
☐ PR description complète
☐ Branche nettoyée post-merge
```

---

**Last Updated:** 2025
**Valid for:** Claude 3.5+, Jules (jules.google.com), Gemini
**Review cycle:** Chaque phase majeure du projet ou trimestriel
```