# Jules CLI — Workflow Boucle Fermée

**Version :** 1.1
**Dernière mise à jour :** 2026-03-09
**Référence :** `.github/ai_rules.md` v3.1

---

## Rôles (extrait ai_rules.md §1 + §2)

| Acteur | Rôle | Merge PR |
|--------|------|----------|
| Claude | Architecte : analyse, prompt, review | ❌ Interdit |
| Jules | Implémenteur : code, commits, PR | ❌ Interdit |
| Humain | Validation finale, merge | ✅ Seulement |

> ⚠️ Le merge de PR est **exclusivement humain** (ai_rules.md §2, §7).
> Claude ne merge jamais, même si la review est approuvée.

---

## Vue d'ensemble

```
Analyse → Prompt → Envoi → Poll session → Review
                                           ↓             ↓
                                        APPROUVÉ    RÉVISION
                                           ↓             ↓
                                     Notifier      comment @jules sur PR
                                      humain            ↓
                                       (merge)    Poll PR (nouveau commit)
                                                        ↓
                                                    Re-review
                                                   ↓         ↓
                                               APPROUVÉ  RÉVISION → (boucle)
```

---

## Étape 1 — Analyse (Claude)

Lire **tous** les fichiers impactés avant de rédiger quoi que ce soit.

Checklist obligatoire (ai_rules.md §3.1) :
```
☐ Impact Schéma : bumper version DB Drift ?
☐ Impact Doc : ARCHITECTURE.md devient obsolète ?
☐ Impact Doc : PROJECT_SUMMARY.md devient obsolète ?
☐ Nouvelles tables/entités → documenter dans ARCHITECTURE.md
☐ Nouveaux providers → documenter dans ARCHITECTURE.md
☐ Nouveaux flows → documenter dans ARCHITECTURE.md
```

---

## Étape 2 — Rédaction du prompt Jules

Écrire dans `C:\Users\planc\AppData\Local\Temp\jules_task.txt` via le **Write tool** (jamais echo/heredoc).
Lire le fichier avec Read avant d'écrire si il existe déjà.

### Structure obligatoire

```
Tâche : [description courte]

Lis d'abord ces fichiers avant de modifier quoi que ce soit :
- [fichier1]
- [fichier2]

== SECTION N — Nom ==

Fichier : [chemin/fichier.dart]

---
AVANT :
[code exact]
APRES :
[code exact]
---

== FORMAT DE COMMIT OBLIGATOIRE ==
[type]: [description]
- impl/fix/doc: [détail]

== FORMAT DE PR ==
## Feature
## Changements
## Tests
- [ ] flutter analyze -> 0 erreurs
- [ ] flutter test -> 0 failures
```

### Règles de rédaction

- **Pas de backticks** (`) dans le texte → cause EOF bash error
- Délimiteurs `---` pour les blocs de code (pas de fences markdown)
- Être exhaustif et littéral : Jules applique exactement, sans interprétation
- Inclure systématiquement : quoi lire en premier, quoi modifier, format commit, format PR
- Si ARCHITECTURE.md doit être mis à jour : inclure le contenu exact dans le prompt (Jules applique, Claude rédige)

---

## Étape 3 — Envoi à Jules

```bash
cd C:\Users\planc\Documents\CourtCare\tenniscourtcare
cat "C:\Users\planc\AppData\Local\Temp\jules_task.txt" | jules new
# → noter le SESSION_ID dans l'output
```

> ⚠️ Ne jamais lancer plusieurs `jules new` en parallèle avec `& wait` → conflit auto-update ENOENT.
> Lancer séquentiellement (attendre "Session is created." entre chaque), les sessions s'exécutent en parallèle côté serveur Jules.

---

## Étape 4 — Poll session (CronCreate toutes les 2 min)

```bash
jules remote list --session 2>/dev/null | grep SESSION_ID
# Statut attendu : "Completed" (pas "Done")
```

Si pas encore Completed → attendre le prochain cycle.

---

## Étape 5 — Review (quand Completed)

```bash
jules remote pull --session SESSION_ID
```

Analyser le diff section par section (ai_rules.md §3.3) :

```
✅ Chaque AVANT/APRES de la tâche appliqué exactement
✅ Layer boundaries respectées (domain = Dart pur, pas de Flutter/Riverpod)
✅ Firebase-first respecté (Drift = lecture seule, écriture via FirebaseCacheService)
✅ Forbidden patterns absents (print, .then, logique dans widget, params positionnels)
✅ Error handling présent (try/catch + rethrow, RepositoryException)
✅ ARCHITECTURE.md mis à jour si logique métier changée
✅ flutter analyze → 0 erreurs
✅ flutter test → 0 failures
```

---

## Étape 6a — Review approuvée ✅

```bash
# Trouver le numéro de PR
gh pr list --repo Simokes/tenniscourtcare --state open --json number,title,createdAt --limit 5
```

→ CronDelete le job de poll
→ **Notifier l'humain** : "PR #N approuvée ✅ — prête à merger"
→ L'humain merge (Claude ne merge jamais)

---

## Étape 6b — Révision nécessaire ❌ (ai_rules.md §3.4)

Jules reçoit un commentaire @jules et **pousse un nouveau commit sur la même branche/PR** (pas de nouvelle session, pas de nouvelle PR).

### 1. Trouver la PR

```bash
gh pr list --repo Simokes/tenniscourtcare --state open --json number,title,createdAt --limit 5
```

### 2. Snapshot du nombre de commits avant le commentaire

```bash
gh pr view PR_NUMBER --json commits --jq '.commits | length'
# → noter ce nombre comme référence
```

### 3. Poster le rapport au format obligatoire (ai_rules.md §3.4)

```bash
gh pr comment PR_NUMBER --body "@jules — RÉVISION REQUISE ❌

La PR #N ne peut pas être approuvée pour les raisons suivantes:

══════════════════════════════════════════
RAPPORT DE NON-CONFORMITÉ
══════════════════════════════════════════

🔴 PROBLÈME [N]
   Fichier    : [chemin/fichier.dart]
   Ligne      : [X]
   Type       : [ARCHITECTURE | CODING_RULES | TESTS | DOC | ERROR_HANDLING]
   Problème   : [description précise]
   Correction : [ce que Jules doit faire exactement]

══════════════════════════════════════════
ACTIONS REQUISES
══════════════════════════════════════════

☐ [Action 1 — fichier + correction]
☐ [Action N — fichier + correction]

══════════════════════════════════════════
RAPPEL DES RÈGLES VIOLÉES
══════════════════════════════════════════

→ [Référence ARCHITECTURE.md §X ou CODING_RULES.md §Y]

══════════════════════════════════════════

⚠️ Instructions pour Jules:
1. Corriger tous les points listés ci-dessus
2. Pousser les corrections sur la même branche (nouveau commit)
3. Ne pas ouvrir une nouvelle PR
4. Format de commit: fix: [description]
5. flutter analyze + flutter test avant de repousser

Claude effectuera une nouvelle revue automatiquement après le push."
```

### 4. Switcher en poll PR (CronCreate toutes les 2 min)

```bash
# Surveiller les nouveaux commits
gh pr view PR_NUMBER --json commits --jq '.commits | length'
# Si count > snapshot → Jules a poussé → re-review (retour Étape 5)
```

→ CronDelete l'ancien job session
→ CronCreate nouveau job poll PR avec le count de référence

---

## Résumé des deux modes de poll

| Phase | Surveiller | Commande |
|-------|-----------|----------|
| Après `jules new` | Session status | `jules remote list --session \| grep ID` |
| Après commentaire @jules | Nouveaux commits PR | `gh pr view N --json commits --jq '.commits \| length'` |

---

## Commandes Jules CLI disponibles

```bash
jules new "prompt"                        # Créer session (depuis le répertoire projet)
cat file.txt | jules new                  # Créer session depuis fichier (méthode recommandée)
jules remote list --session               # Lister toutes les sessions
jules remote pull --session SESSION_ID    # Récupérer le diff
jules teleport SESSION_ID                 # Cloner repo + checkout branche + appliquer patch
jules --help                              # Aide complète
```

---

## Stratégie multi-sessions (ai_rules.md §3.5)

### Séquentiel (phases dépendantes)

```
Session Ph1 → PR → merge humain → Session Ph2 → PR → merge humain
```

Règle : créer Session Ph2 **uniquement après** le merge de Ph1.
Jules travaille sur un snapshot stale — il ne voit pas les merges postérieurs.

### Parallèle (phases indépendantes, fichiers disjoints)

```
# Créer séquentiellement (attendre "Session is created." entre chaque)
cat jules_ph1a.txt | jules new   # → Session ID A
cat jules_ph1b.txt | jules new   # → Session ID B
# Les sessions s'exécutent en parallèle côté serveur Jules
# Merger dans n'importe quel ordre
```

Identification obligatoire par Claude avant envoi :
- `[PARALLÈLE]` — fichiers disjoints, aucune dépendance inter-phases
- `[SÉQUENTIEL après Ph_X]` — dépend du merge de Ph_X

---

## Points critiques

| Point | Détail |
|-------|--------|
| Merge = humain uniquement | Claude ne merge jamais (ai_rules.md §2 + §7) |
| Révision = même PR | Jules pousse sur la même branche, jamais nouvelle PR |
| Statut Jules | `"Completed"` (pas `"Done"`) |
| Backticks interdits | Dans le texte du prompt Jules → EOF bash error |
| Sessions parallèles | Créer séquentiellement via CLI, exécution parallèle côté serveur |
| CronCreate session-only | Disparaît si Claude quitte la session |
| Base stale | Jules ne voit pas les merges postérieurs à la création de la session |
