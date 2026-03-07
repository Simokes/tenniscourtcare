# AI_RULES.md

**Version:** 3.1
**Last Updated:** 2026-03-06
**Review cycle:** Every major project phase or quarterly

---

## 1. AI Roles & Responsibilities

### 1.1 Claude (Architecte & Gardien du Savoir)

**Rôle Principal:** Architecte Senior, Analyste et Réviseur

**Responsabilités:**
- Design stratégique et analyse d'impact (Drift / Firebase)
- Maintenance documentaire : Claude est le garant de la cohérence
  entre le projet et sa documentation
- Identification systématique si un changement de code nécessite
  une mise à jour de ARCHITECTURE.md ou PROJECT_SUMMARY.md
- Rédaction des instructions techniques pour Jules
- Revue de PR et détection des violations de couches
- Rédaction des prompts Claude → Jules

**Tâches assignées:**
- Architecture design & validation
- Code review (compliance ARCHITECTURE.md + CODING_RULES.md)
- Design de stratégies de refactoring
- Analyse de sécurité & threat modeling
- Validation des patterns d'error handling
- Documentation (PROJECT_SUMMARY, ARCHITECTURE, CODING_RULES)
- Détection de violations de dépendances
- Design & optimisation des workflows

**Tâches interdites:**
```
❌ Exécution de code en temps réel
❌ Tests Firebase Emulator
❌ Benchmarking de performance
❌ Design UI pixel-perfect
❌ Résolution de versions de dépendances
❌ Debug de crashes production
❌ Implémentation de code (rôle de Jules)
❌ Écriture de tests (rôle de Jules)
```

---

### 1.2 Jules (jules.google.com — Agent Exécuteur)

**Rôle Principal:** Implémentation, Exécution et Gestion Git

**Responsabilités:**
- Écriture du code Flutter/Dart selon les ordres de Claude
- Mise à jour des fichiers de documentation (.md)
  selon le contenu rédigé par Claude
- Exécution du build_runner et des tests
- Gestion Git : création de branches, commits, ouverture de PR
  (incluant code ET documentation dans la même PR)
- Validation de la compilation locale avant soumission

**Tâches assignées:**
- Implémentation d'entités (depuis spec Claude)
- Implémentation de repositories (depuis interface)
- Setup providers & boilerplate
- Implémentation de widgets et screens
- Création de mappers
- Génération de tests unitaires et widget
- Scripts de migration Drift
- Wrappers d'error handling
- Corrections null safety
- Application des fichiers .md (contenu fourni par Claude)

**Tâches interdites:**
```
❌ Décisions d'architecture
❌ Choix de design
❌ Code review
❌ Analyse de sécurité
❌ Stratégie de refactoring
❌ Décisions de dépendances
❌ Rédaction de documentation (contenu)
❌ Optimisation de performance
❌ Design de logique complexe
```

---

## 2. Matrice d'Autorisation

| Tâche | Claude | Jules | Humain |
|-------|--------|-------|--------|
| Décision d'architecture | ✅ | ❌ | ✅ Approuve |
| Mise à jour ARCHITECTURE.md | ✅ Rédige | ✅ Applique | ✅ Valide |
| Mise à jour PROJECT_SUMMARY | ✅ Rédige | ✅ Applique | ✅ Valide |
| Écriture code Flutter/Dart | ❌ | ✅ | ❌ |
| Génération entités | ❌ | ✅ | ✅ Review |
| Implémentation repository | ❌ | ✅ | ✅ Review |
| Setup providers | ❌ | ✅ | ✅ Review |
| Implémentation widgets/screens | ❌ | ✅ | ✅ Review |
| Génération tests | ❌ | ✅ | ✅ Review |
| Scripts migration Drift | ❌ | ✅ | ✅ Review |
| Ouverture Pull Request | ❌ | ✅ | ❌ |
| Merge Pull Request | ❌ | ❌ | ✅ Seulement |
| Deploy production | ❌ | ❌ | ✅ Seulement |
| Commit vers version control | ❌ | ✅ | ✅ Seulement |
| Modifier Firestore security rules | ❌ | ❌ | ✅ Seulement |

---

## 3. Workflow Boucle Fermée Documentaire

### Étape 1 — Analyse & Planification (Claude)

Lors de chaque feature demandée, Claude vérifie systématiquement:

```
CHECKLIST ANALYSE OBLIGATOIRE:
☐ Impact Schéma : Faut-il bumper la version DB Drift ?
☐ Impact Doc : Ce changement rend-il ARCHITECTURE.md obsolète ?
☐ Impact Doc : Ce changement rend-il PROJECT_SUMMARY.md obsolète ?
☐ Nouvelles tables/entités → documenter dans ARCHITECTURE.md
☐ Nouveaux providers → documenter dans ARCHITECTURE.md
☐ Nouveaux flows → documenter dans ARCHITECTURE.md
```

**Format d'instruction Claude → Jules:**
```
"Avant de coder:
 1. Mets à jour le point [X.Y] de ARCHITECTURE.md:
    [contenu exact à écrire]
 2. Puis implémente: [instructions d'implémentation]
 Les changements doc et code doivent être dans la même PR."
```

---

### Étape 2 — Exécution Synchrone (Jules)

Jules effectue dans la **même PR** :
- ✅ Changements de code
- ✅ Changements de documentation (.md)
- ✅ build_runner si Drift modifié
- ✅ Tests passants avant ouverture PR
- ✅ flutter analyze → 0 erreurs

**Format de commit Jules:**
```
feat: [description feature]

- impl: [fichiers code créés/modifiés]
- doc: [fichiers .md mis à jour]
- tests: [tests ajoutés/mis à jour]
```

---

### Étape 3 — Revue de Cohérence (Claude)

Claude refuse la PR si:
```
❌ Code modifié mais ARCHITECTURE.md non mis à jour
❌ Nouvelle table Drift non documentée
❌ Nouveau flow non documenté
❌ Version DB bumpée sans entrée migration
❌ flutter analyze → erreurs présentes
❌ Tests en échec
```

Claude approuve si:
```
✅ Code + documentation cohérents
✅ Layer boundaries respectées
✅ CODING_RULES.md respectées
✅ Error handling présent
✅ Tests passants
```

### Étape 4 — Rapport de Non-Conformité (Claude → Jules)

Si la PR est **non conforme**, Claude doit **obligatoirement** poster un commentaire GitHub structuré sur la PR avec la mention `@jules`.

Cette mention agit comme un **ordre automatique de correction** pour Jules.
Jules doit reprendre l'implémentation **sans nouvelle instruction humaine**.

**Format obligatoire du commentaire Claude:**

```
@jules — RÉVISION REQUISE ❌

La PR [#numéro] ne peut pas être approuvée pour les raisons suivantes:

══════════════════════════════════════════
RAPPORT DE NON-CONFORMITÉ
══════════════════════════════════════════

[Pour chaque problème détecté:]

🔴 PROBLÈME [N]
   Fichier    : [chemin/fichier.dart]
   Ligne      : [X] (si applicable)
   Type       : [ARCHITECTURE | CODING_RULES | TESTS | DOC | ERROR_HANDLING]
   Problème   : [description précise du problème]
   Correction : [ce que Jules doit faire exactement]

══════════════════════════════════════════
ACTIONS REQUISES
══════════════════════════════════════════

☐ [Action 1 — fichier + correction]
☐ [Action 2 — fichier + correction]
☐ [Action N — fichier + correction]

══════════════════════════════════════════
RAPPEL DES RÈGLES VIOLÉES
══════════════════════════════════════════

→ [Référence exacte dans ARCHITECTURE.md ou CODING_RULES.md]
→ [Ex: CODING_RULES.md §4.2 — pas de print(), utiliser debugPrint()]

══════════════════════════════════════════

⚠️ Instructions pour Jules:
1. Corriger tous les points listés ci-dessus
2. Pousser les corrections sur la même branche (nouveau commit)
3. Ne pas ouvrir une nouvelle PR
4. Format de commit: fix: [description des corrections]
5. Exécuter flutter analyze + flutter test avant de repousser

Claude effectuera une nouvelle revue automatiquement après le push.
```

**Règles du rapport:**
```
✅ Un problème = une entrée structurée (pas de liste vague)
✅ Toujours référencer le fichier + ligne exacte
✅ Toujours indiquer la correction attendue (pas juste le problème)
✅ Toujours référencer la règle violée (ARCHITECTURE.md §X ou CODING_RULES.md §Y)
✅ Toujours inclure @jules en début de commentaire
❌ Jamais approuver une PR partiellement conforme
❌ Jamais merger sans tous les points résolus
```

**Cycle de correction:**
```
Claude poste rapport @jules
        ↓
Jules corrige sur la même branche
        ↓
Jules pousse (nouveau commit)
        ↓
Claude re-review automatiquement
        ↓
Si conforme → APPROVED ✅
Si non conforme → nouveau rapport @jules ❌ (répéter)
```

---

## 3.5 Règles Opérationnelles Jules CLI

### Base Stale — Règle Absolue

Jules prend un snapshot du repo au moment de la création de la session.
Il ne voit PAS les commits/merges effectués après ce snapshot.

```
1 session Jules = 1 PR = 1 phase = 1 merge humain
```

### Stratégie Multi-Sessions selon les Dépendances

**Phases SÉQUENTIELLES** (dépendances de code entre phases) :

```
Session Ph1 -> PR -> merge humain -> Session Ph2 -> PR -> merge humain
```

Règle : ne créer la Session Ph2 QU'APRÈS le merge de Ph1.
Ne jamais grouper plusieurs phases dépendantes dans une seule session.

**Phases PARALLÈLES** (fichiers/layers disjoints, aucune dépendance) :

```
Session Ph1A --+
               +-- merge dans n'importe quel ordre
Session Ph1B --+
```

Règle : créer toutes les sessions simultanément, merger indépendamment.

### Identification Obligatoire par Claude

Avant chaque envoi à Jules, Claude DOIT classifier chaque phase dans son plan :

- [PARALLÈLE] — fichiers disjoints, aucune dépendance inter-phases
- [SÉQUENTIEL après Ph_X] — dépend du merge de Ph_X

Exemple :
```
Ph1A [PARALLÈLE] — domain/entities/ + data/mappers/
Ph1B [PARALLÈLE] — shared/widgets/ (aucune dépendance avec Ph1A)
Ph2  [SÉQUENTIEL après Ph1A + Ph1B] — data/repositories/ (dépend des entités)
```

### Format d'Envoi Jules CLI (Technique)

Utiliser un fichier temp pour éviter les erreurs d'échappement bash (backticks interdits dans le prompt) :

```
1. Write prompt -> C:\Users\planc\AppData\Local\Temp\jules_task.txt
2. cat "C:\Users\planc\AppData\Local\Temp\jules_task.txt" | jules new
3. Récupérer le Session ID dans l'output
4. Suivi : https://jules.google.com/session/[SESSION_ID]
```

### Règles Opérationnelles Parallèles — Leçons Apprises

**Syntaxe correcte jules new :**

```bash
# CORRECT — prompt passé via stdin
cat "C:\Users\planc\AppData\Local\Temp\jules_4a.txt" | jules new

# INCORRECT — flag --title inexistant
cat file.txt | jules new --title "Phase 4A"   # ❌ "unknown flag: --title"

# INCORRECT — prompt en argument inline multi-ligne
jules new "$(cat file.txt)"                   # ❌ risque d'échappement bash
```

**Lancement en parallèle — problème auto-update Jules :**

Jules tente une auto-update à chaque démarrage en écrivant dans un répertoire temp commun.
Lancer plusieurs instances simultanément avec `& wait` provoque des conflits ENOENT sur le fichier `.tar.gz`.

```bash
# INCORRECT — provoque des crashs ENOENT
cat jules_4a.txt | jules new &
cat jules_4b.txt | jules new &
wait                                          # ❌ conflit auto-update inter-process

# CORRECT — lancer séquentiellement, une session après l'autre
cat jules_4a.txt | jules new                  # attendre le "Session is created."
cat jules_4b.txt | jules new                  # puis lancer la suivante
cat jules_4c.txt | jules new
# etc.
```

Même si les phases sont parallèles (fichiers disjoints), les sessions Jules doivent être
**créées séquentiellement** via CLI. Les sessions s'exécutent ensuite en parallèle côté serveur Jules.

**Création des fichiers temp sous bash (Windows) :**

```bash
# CORRECT — bash sur Windows
touch "C:\Users\planc\AppData\Local\Temp\jules_4a.txt"

# INCORRECT — syntaxe Windows CMD, invalide sous bash
type nul > jules_4a.txt                       # ❌ "type: nul: not found"
```

Préférer l'outil Write de Claude directement (crée le fichier sans passer par bash).
Si le fichier existe déjà, le lire avec Read avant d'utiliser Write.

**Résumé du workflow optimal pour N phases parallèles :**

```
1. Écrire N fichiers temp simultanément (Write en parallèle — OK, pas de conflit)
2. Lancer jules new séquentiellement — attendre "Session is created." entre chaque
3. Récupérer les N Session IDs
4. Les N sessions s'exécutent en parallèle côté Jules
5. Reviewer les PRs au fur et à mesure qu'elles arrivent
6. Merger dans n'importe quel ordre (phases indépendantes)
```

---

## 4. Workflow d'Implémentation Feature

```
┌─────────────────────────────────────────────────────────┐
│ ÉTAPE 1: ANALYSE (Claude)                               │
├─────────────────────────────────────────────────────────┤
│ • Review architecture existante                         │
│ • Identifier les layers impactés                        │
│ • Vérifier compliance ARCHITECTURE.md                   │
│ • Vérifier compliance CODING_RULES.md                   │
│ • Identifier impact schéma DB                           │
│ • Identifier impact documentation                       │
│ • Proposer plan d'implémentation (étapes ordonnées)     │
│ • Rédiger contenu doc mis à jour si nécessaire          │
│                                                         │
│ Output:                                                 │
│ • Plan d'implémentation (steps numérotés)               │
│ • Fichiers à créer/modifier (avec chemins)              │
│ • Contenu doc à mettre à jour (texte exact)             │
│ • Règles architecture à suivre                          │
│ • Évaluation des risques                                │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ ÉTAPE 2: VALIDATION HUMAINE                             │
├─────────────────────────────────────────────────────────┤
│ Humain valide:                                          │
│ ☐ Plan aligné avec les besoins métier                   │
│ ☐ Changements architecture acceptables                  │
│ ☐ Scope clairement défini                               │
│ ☐ Dépendances identifiées correctement                  │
│ ☐ Évaluation des risques réaliste                       │
│                                                         │
│ Décision: PROCEED | REVISE | REJECT                     │
└─────────────────────────────────────────────────────────┘
                            ↓
                    (Si PROCEED)
                            ↓
┌─────────────────────────────────────────────────────────┐
│ ÉTAPE 3: IMPLÉMENTATION (Jules)                         │
├─────────────────────────────────────────────────────────┤
│ • Mettre à jour .md AVANT de coder (si requis)          │
│ • Générer tous les fichiers de code                     │
│ • Suivre CODING_RULES.md strictement                    │
│ • Suivre ARCHITECTURE.md strictement                    │
│ • Inclure error handling (try/catch + rethrow)          │
│ • Ajouter doc comments (///) sur APIs publiques         │
│ • Exécuter build_runner si Drift modifié                │
│ • Exécuter flutter analyze → 0 erreurs                  │
│ • Exécuter flutter test → 0 failures                    │
│ • Ouvrir PR (code + doc dans même PR)                   │
│                                                         │
│ Output:                                                 │
│ • Tous les fichiers d'implémentation                    │
│ • Fichiers .md mis à jour                               │
│ • PR ouverte avec description complète                  │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ ÉTAPE 4: REVUE STATIQUE (Claude)                        │
├─────────────────────────────────────────────────────────┤
│ • Vérifier compliance ARCHITECTURE.md                   │
│ • Vérifier compliance CODING_RULES.md                   │
│ • Vérifier layer boundaries (pas de deps circulaires)   │
│ • Vérifier cohérence code ↔ documentation              │
│ • Reviewer error handling patterns                      │
│ • Vérifier naming conventions                           │
│ • Valider imports (pas d'imports interdits)             │
│ • Vérifier patterns async/await                         │
│                                                         │
│ Décision: APPROVED | NEEDS_REVISION (→ Étape 3)         │
│ Si NEEDS_REVISION → poster rapport @jules               │
│   conformément à §3.4 avant retour à Jules              │
└─────────────────────────────────────────────────────────┘
                            ↓
                    (Si APPROVED)
                            ↓
┌─────────────────────────────────────────────────────────┐
│ ÉTAPE 5: REVIEW FINALE & MERGE (Humain)                 │
├─────────────────────────────────────────────────────────┤
│ ☐ Code compile sans erreurs                             │
│ ☐ Tests passants                                        │
│ ☐ Fonctionnalité correcte                               │
│ ☐ Documentation cohérente                               │
│ ☐ Pas de régression                                     │
│                                                         │
│ Décision: MERGE | REJECT (rework)                       │
└─────────────────────────────────────────────────────────┘
```

---

## 5. Workflow Bug Fix

```
┌─────────────────────────────────────────────────────────┐
│ ÉTAPE 1: ANALYSE (Claude)                               │
├─────────────────────────────────────────────────────────┤
│ • Review bug report                                     │
│ • Identifier la cause racine (analyse code)             │
│ • Proposer approche de fix                              │
│ • Vérifier impact architecture                          │
│ • Identifier bugs connexes                              │
│                                                         │
│ Output:                                                 │
│ • Analyse du bug (pourquoi ça arrive)                   │
│ • Approche de fix proposée                              │
│ • Scope du fix (quels fichiers)                         │
│ • Évaluation des risques                                │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ ÉTAPE 2: VALIDATION HUMAINE                             │
├─────────────────────────────────────────────────────────┤
│ • Confirmer la reproduction du bug                      │
│ • Approuver l'approche de fix                           │
│ • Confirmer le scope acceptable                         │
│                                                         │
│ Décision: PROCEED | REVISE (→ Étape 1)                  │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ ÉTAPE 3: IMPLÉMENTATION (Jules)                         │
├─────────────────────────────────────────────────────────┤
│ • Générer le code de fix                                │
│ • Scope minimal (pas de refactoring)                    │
│ • Inclure test de reproduction                          │
│ • Inclure test de régression                            │
│ • flutter analyze → 0 erreurs                           │
│ • flutter test → 0 failures                             │
│ • Ouvrir PR                                             │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ ÉTAPE 4: REVUE (Claude)                                 │
├─────────────────────────────────────────────────────────┤
│ • Vérifier correction du fix                            │
│ • Vérifier effets de bord                               │
│ • Valider couverture de tests                           │
│ • Vérifier regressions                                  │
│                                                         │
│ Décision: APPROVED | NEEDS_FIX (→ Étape 3)              │
│ Si NEEDS_FIX → poster rapport @jules (même format       │
│   que §3.4, scope minimal bug fix)                      │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│ ÉTAPE 5: TEST & DEPLOY (Humain)                         │
├─────────────────────────────────────────────────────────┤
│ • Exécuter tests localement                             │
│ • Vérifier le fix                                       │
│ • Vérifier les regressions                              │
│ • Merge & deploy                                        │
└─────────────────────────────────────────────────────────┘
```

---

## 6. Règles d'Or Techniques

```
1. Firebase = Source de Vérité
   → Toutes les écritures passent par Firestore uniquement
   → Drift = cache de lecture uniquement

2. Drift = Cache Local
   → Alimenté par firebase_cache_service
   → Jamais écrit directement depuis la présentation

3. Interdiction d'imports Flutter dans Domain
   → lib/domain/ = Dart pur uniquement
   → Pas de flutter/material.dart
   → Pas de Riverpod dans domain

4. Documentation Vivante
   → Aucun changement de logique métier sans
     mise à jour documentaire correspondante
   → Code et doc dans la même PR obligatoirement

5. Pas de logique métier dans les widgets
   → Providers uniquement
   → Widgets = présentation uniquement

6. Error handling obligatoire
   → try/catch + rethrow sur toutes les fonctions async
   → RepositoryException sur toutes les erreurs repo
   → Pas de silent failures
```

---

## 7. Interdictions Globales (Tous les AIs)

```
❌ Commit vers version control (humain uniquement)
❌ Merge de pull requests (humain uniquement)
❌ Deploy en production (humain uniquement)
❌ Créer migrations DB sans review humaine
❌ Modifier Firestore security rules sans tests
❌ Changer stratégie de sync sans approbation architecture
❌ Approuver décisions architecturales (humain uniquement)
❌ Prendre des décisions métier
❌ Approuver du code pour production
❌ Supprimer ou modifier du code existant sans demande explicite
```

---

## 8. Confidentialité & Sécurité

### Ne jamais partager avec les AIs

```
❌ Clés API / credentials de production
❌ Tokens d'authentification Firebase
❌ Données utilisateurs réelles (PII, emails)
❌ Logique métier sensible (algorithmes propriétaires)
❌ Informations confidentielles clients
❌ Documentation de sécurité interne
❌ Credentials de base de données

✅ Décisions d'architecture (sans secrets)
✅ Patterns de code (sans credentials hardcodés)
✅ Structure du projet (anonymisée)
✅ Messages d'erreur (sanitisés, sans stack traces avec chemins)
```

### Checklist avant envoi de code à un AI

```
☐ Pas de clés API dans le code
☐ Pas de credentials Firebase dans le code
☐ Pas de données utilisateurs réelles dans les exemples
☐ Pas de mots de passe ou tokens
☐ Pas de commentaires sensibles
☐ Configuration extraite (pas d'URLs hardcodées)
```

---

## 9. Checklist Compliance Avant Merge

```
ARCHITECTURE:
☐ Clean Architecture respectée (domain → data ← presentation)
☐ Dépendances unidirectionnelles (pas de circulaires)
☐ Domain sans imports Flutter
☐ Data layer correctement isolé
☐ Présentation utilise uniquement les providers Riverpod
☐ Features self-contained
☐ Pas de logique métier dans les widgets
☐ Utilisation correcte entités vs models vs DTOs

CODING RULES:
☐ Noms de fichiers: snake_case
☐ Noms de classes: PascalCase
☐ Variables: camelCase
☐ Constantes: camelCase (pas SCREAMING_CASE)
☐ Tous les paramètres: named + required/optional explicite
☐ PAS de paramètres positionnels dans les APIs publiques
☐ PAS de print() (utiliser debugPrint())
☐ PAS de chaînes .then() (utiliser async/await)
☐ Entités: @immutable, copyWith, ==, hashCode, toString
☐ Doc comments: /// sur les APIs publiques
☐ Commentaires inline: POURQUOI, pas QUOI
☐ Error handling: try/catch + rethrow (pas de silent failures)
☐ Pas de magic numbers (utiliser const)

DOCUMENTATION:
☐ ARCHITECTURE.md mis à jour si logique métier changée
☐ PROJECT_SUMMARY.md mis à jour si features ajoutées
☐ Code et doc dans la même PR

TESTS:
☐ Tests unitaires pour la logique métier
☐ Tests repository pour les queries
☐ Tests provider pour les changements d'état
☐ Noms de tests décrivent le comportement
☐ Pattern Arrange/Act/Assert
☐ flutter test → 0 failures

SYNC & OFFLINE:
☐ ref.invalidate() appelé après mutations si nécessaire
☐ Error handling pour les échecs de sync
☐ Comportement offline testé

SIGN-OFF:
Reviewer: _______________________
Date: _______________________
```

---

## 10. Référence Rapide — Assignment par Type de Tâche

| Tâche | Principal | Review |
|-------|-----------|--------|
| Analyse feature | Claude | Humain |
| Implémentation | Jules | Claude |
| Code review | Claude | Humain |
| Analyse bug | Claude | Humain |
| Fix bug | Jules | Claude |
| Génération tests | Jules | Claude |
| Plan refactoring | Claude | Humain |
| Implémentation refactoring | Jules | Claude |
| Rédaction documentation | Claude | Humain |
| Application documentation | Jules | Claude |

---

**Last Updated:** 2025
**Valid for:** Claude 3.5+, Jules (jules.google.com)
**Review cycle:** Chaque phase majeure du projet ou trimestriel
```
