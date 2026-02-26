# FEATURE_WORKFLOW.md

## Purpose

Définir le processus obligatoire pour développer une nouvelle feature.
Aucune feature ne doit être implémentée hors de ce workflow.

---

# 1. Feature Definition

## 1.1 Feature Description
- Description fonctionnelle claire
- Problème utilisateur résolu
- Résultat attendu

## 1.2 Scope
- Ce qui est inclus
- Ce qui est explicitement exclu

## 1.3 Acceptance Criteria
- Liste précise et testable
- Conditions de validation

---

# 2. Architecture Validation (Claude - Lead Engineer)

## 2.1 Inputs
- PROJECT_SUMMARY.md
- ARCHITECTURE.md
- Description de la feature

## 2.2 Required Output
Claude doit fournir :

1. Impact sur layers (presentation / domain / data)
2. Nouveaux fichiers nécessaires
3. Modifications fichiers existants
4. Nouveaux providers Riverpod
5. Domain entities impactées
6. Risques techniques
7. Dette technique potentielle

## 2.3 Validation Rule
- Aucune génération de code avant validation humaine
- L’architecture doit être approuvée explicitement

---

# 3. Implementation Plan

## 3.1 Breakdown
- Liste des tâches techniques ordonnées
- Chaque tâche doit être atomique
- Estimation de complexité (Low / Medium / High)

## 3.2 Dependencies
- Dépendances techniques internes
- Dépendances externes

---

# 4. Code Generation (Jules CLI)

## 4.1 Rules
- Respect strict de ARCHITECTURE.md
- Respect strict de CODING_RULES.md
- Aucun changement structurel non validé
- Fichiers générés un par un si complexe

## 4.2 Format
- Fournir fichiers complets
- Pas de pseudo-code
- Pas d’explication inutile

---

# 5. Code Review (Claude)

## 5.1 Review Scope
- Respect architecture
- Respect règles de dépendance
- Gestion correcte des erreurs
- Pas de logique métier dans UI
- Cohérence naming

## 5.2 Output
- Liste d’erreurs
- Liste d’améliorations
- Validation ou refus

---

# 6. UX Review (Gemini)

## 6.1 Scope
- Flow utilisateur
- Lisibilité
- États loading / error / empty
- Cohérence visuelle
- Micro-interactions

## 6.2 Output
- Suggestions UX
- Pas de modification technique

---

# 7. Final Validation

Checklist obligatoire :

- [ ] Architecture validée
- [ ] Code review passée
- [ ] UX review effectuée
- [ ] Aucun TODO critique restant
- [ ] Tests ajoutés si nécessaire

---

# 8. Documentation Update

Après merge :

- Mettre à jour PROJECT_SUMMARY.md si nécessaire
- Mettre à jour ARCHITECTURE.md si impact structurel
- Ajouter décision dans /ai_log/decisions.md