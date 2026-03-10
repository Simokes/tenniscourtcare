# Plan d'Action — Rôle Prof & Gestion des Cours
**Statut :** EN ATTENTE DE VALIDATION — Ne pas lancer Jules avant approbation humaine
**Rédigé par :** Claude (Architecte)
**Date :** 2026-03-10
**Version :** 1.1
**Schema cible :** v24 → v25
**Note :** v24 pre-emptee par la feature "Terrain Closure" (closureReason + closureUntil sur terrains, mergee avant ce plan).

---

## 0. Résumé Exécutif

Ajout d'un rôle `prof` permettant aux enseignants de tennis de gérer leur planning
de cours sur les terrains, avec récurrence hebdomadaire et statistiques mensuelles.
La secrétaire obtient une vue de disponibilité agrégée des terrains (Reservations + CoursSessions).

**Scope :**
- Nouveau rôle `prof` dans l'enum Role
- Nouvelle entité `CourseSession` avec récurrence
- Dashboard adaptatif selon le rôle (HomeScreen unique, sections conditionnelles)
- Vue disponibilité terrains pour la secrétaire
- Stats mensuelles par prof (sessions par type)

**Hors scope :**
- Gestion des élèves / inscriptions
- Paiements / facturation
- Notifications push
- Export CSV stats (déjà dans la roadmap globale)

---

## 1. Analyse Critique — Points Bloquants à Résoudre Avant Lancement

### 1.1 🔴 AMBIGUITÉ CRITIQUE — Multi-terrain par session

L'exemple fourni : *"tous les lundi de 17h à 18h30 sur les terrains 1 ET 2"*

Deux interprétations possibles, avec des schémas incompatibles :

**Option A — Session unique sur 2 courts simultanément (Stage / Collectif large)**
```
CourseSession
  └── terrainIds: List<int>  (relation n-n → table de liaison course_session_terrains)
```
- Complexité : élevée (table de liaison, requêtes plus lourdes)
- Use case : stage qui occupe 2 courts en même temps

**Option B — 2 sessions distinctes générées par la récurrence**
```
CourseSession (instance 1) → terrain 1, lundi 17h-18h30
CourseSession (instance 2) → terrain 2, lundi 17h-18h30
```
- Complexité : faible (1 terrain par session, schéma simple)
- Use case : 2 groupes différents qui tournent sur 2 courts

**⚠️ Décision requise avant toute implémentation.** Le choix impacte le schéma DB,
les providers, la détection de conflits et l'UI.
Recommandation Claude : **Option B** — plus simple, couvre 95% des cas réels,
extensible vers Option A si besoin ultérieur.

---

### 1.2 🔴 AMBIGUITÉ — Récurrence et gestion des exceptions

La récurrence ("tous les lundis") soulève des cas non spécifiés :

- **Férié ou terrain indisponible un lundi** → la session est-elle annulée ? reportée ?
- **Modification d'une occurrence** → modifie-t-on TOUTES les futures occurrences
  ou UNIQUEMENT cette occurrence (pattern Google Calendar : "cet événement" / "cet
  événement et les suivants" / "tous les événements") ?
- **Date de fin de récurrence** → infinie ou avec une date de fin ?
- **Pause saisonnière** → comment gérer l'hiver si le club ferme ?

**⚠️ Décision requise.** Sans réponse, Jules devra faire des choix arbitraires.
Recommandation Claude : commencer par la récurrence simple (pattern + date_fin nullable),
sans gestion d'exceptions pour le MVP. Ajouter l'annulation d'occurrence en v2.

---

### 1.3 🟠 PROBLÈME — Détection de conflits multi-tables

Les profs ne peuvent pas réserver un créneau déjà en `Reservation`.
Mais les profs ne voient pas la table `Reservation` directement (rôle limité).

Cela signifie que la vérification de conflit doit opérer sur **deux tables** :
- `reservations` (créneaux existants)
- `course_sessions` (cours des autres profs)

Ce n'est pas de la logique de widget ni de provider — c'est un **service domain** :
`ConflictCheckerService` (Dart pur, aucun import Flutter/Firestore).

Sans ce service explicitement planifié, Jules risque de mettre la logique
de conflit dans le repository ou pire dans un widget.

---

### 1.4 🟠 PROBLÈME — Stats "nombre de sessions par type, tous les mois"

Ambiguité : que compte-t-on ?
- **Sessions planifiées** (récurrences générées) ou **sessions réellement tenues** ?
- Si un cours est annulé (future feature), est-il compté dans les stats ?
- Le mois courant est-il inclus (en cours) ou uniquement les mois terminés ?

Sans un champ `status` sur CourseSession, impossible de distinguer planifié / tenu /
annulé. Les stats ne seront que des comptages bruts.

Recommandation : ajouter `status` dès le départ même si annulation n'est pas
encore implémentée (valeur par défaut `planned` pour toutes les instances).
Coût faible maintenant, évite une migration future.

---

### 1.5 🟡 PROBLÈME — Création des comptes prof

Qui crée un compte prof ? L'admin uniquement ?
Le flow actuel (admin setup → login) ne prévoit pas de rôle intermédiaire
pour la création de comptes. La secrétaire peut-elle créer un prof ?

Selon la matrice de permissions actuelle, seul l'admin peut créer des users.
À confirmer que ce comportement est correct pour le rôle prof.

---

### 1.6 🟡 PROBLÈME — Vue disponibilité secrétaire : quelle granularité ?

La secrétaire voit "la disponibilité des terrains". Mais à quel niveau ?
- Vue journalière (créneaux libres/occupés pour aujourd'hui) ?
- Vue hebdomadaire (planning de la semaine) ?
- Vue mensuelle (calendrier) ?

Ces trois vues sont des implémentations très différentes en termes d'UI.
Le `table_calendar` déjà en dépendance peut couvrir les 3 modes.

Recommandation : vue hebdomadaire en priorité (la plus utile opérationnellement),
avec navigation semaine précédente / semaine suivante.

---

## 2. Suggestions & Améliorations

### 2.1 Schema CourseSession — Champs supplémentaires recommandés

En plus des champs fonctionnels de base, recommander d'ajouter dès v24 :

```
status        String   (enum: planned | completed | cancelled) — valeur défaut: planned
maxStudents   int?     (pour collectif, stage, école — utile pour stats futures)
notes         String?  (remarques du prof sur la session)
color         String?  (couleur hex pour différencier sur le calendrier — UX)
```

Coût : quasi nul à l'implémentation initiale.
Bénéfice : évite une migration v25 dès que la prochaine feature arrive.

### 2.2 Schéma RecurringPattern — Entité séparée vs. inline

**Option inline (simple) :**
```
course_sessions
  recurrenceDayOfWeek   int?      (1=lundi, 7=dimanche — null si ponctuel)
  recurrenceEndDate     DateTime? (null = infinie)
  parentSessionId       int?      (null = session maître, non-null = instance générée)
```

**Option entité séparée (extensible) :**
```
recurring_patterns
  id, dayOfWeek, startTime, endTime, endDate, profId, terrainId, type...

course_sessions
  recurringPatternId  int?  (FK → recurring_patterns.id)
```

Recommandation Claude : **Option inline pour MVP**, entité séparée si les patterns
deviennent complexes (ex: bihebdomadaire, plusieurs jours par semaine).

### 2.3 ConflictCheckerService — Interface domain claire

```dart
abstract class ConflictCheckerService {
  Future<bool> hasConflict({
    required int terrainId,
    required DateTime startTime,
    required DateTime endTime,
    int? excludeSessionId,  // pour l'édition
  });
}
```

L'implémentation dans `data/` interroge à la fois `reservations` et `course_sessions`.
Ce service est injecté dans le `CourseSessionNotifier` avant chaque write Firestore.

### 2.4 TerrainAvailabilityAggregator — Modèle de vue agrégé

Pour la vue secrétaire, créer un modèle `TerrainSlot` en domain :

```dart
@immutable
class TerrainSlot {
  final int terrainId;
  final String terrainName;
  final DateTime startTime;
  final DateTime endTime;
  final TerrainSlotType type;  // enum: reservation | courseIndividual | courseCollectif | courseStage | courseEcole
  final String? label;         // nom du prof ou description réservation
  final bool isOccupied;
}
```

Le `terrainAvailabilityProvider` fusionne les deux streams (reservations + course_sessions)
et produit une `List<TerrainSlot>` pour l'UI. Ce mapping se fait dans un provider
calculé, pas dans le widget.

### 2.5 Dashboard HomeScreen — Sections selon rôle

Architecture recommandée pour éviter que HomeScreen devienne un monstre conditionnel :

```dart
// providers/home_sections_provider.dart
final homeSectionsProvider = Provider<List<HomeSectionType>>((ref) {
  final role = ref.watch(currentUserProvider)?.role;
  return switch (role) {
    Role.admin     => [header, alerts, kpi, currentEvent, courts, schedule, stock],
    Role.agent     => [header, alerts, kpiMaintenance, courts, schedule],
    Role.secretary => [header, kpiEvents, terrainAvailability, currentEvent, schedule],
    Role.prof      => [header, myCoursesToday, myWeekSchedule, terrainMiniView],
    _              => [header],
  };
});
```

HomeScreen itère simplement `homeSectionsProvider` et render le widget correspondant.
Zéro logique conditionnelle dans le widget — tout dans le provider.

### 2.6 UI Prof — Planning hebdomadaire

Le `table_calendar` (déjà en dépendance) supporte le mode `CalendarFormat.week`.
L'écran de planning du prof devrait utiliser ce composant plutôt qu'une liste.

Vue hebdomadaire : terrains en colonnes, heures en lignes (style Google Calendar).
C'est plus complexe que `table_calendar` seul — à évaluer si custom grid ou librairie.

Alternative simple pour MVP : liste des cours de la semaine groupée par jour
(même pattern que MaintenanceScreen : sections En retard / Aujourd'hui / Cette semaine).

Recommandation : **liste groupée pour MVP**, vue calendrier en v2.

### 2.7 Stats prof — Structure du provider

```dart
// Modèle
@immutable
class ProfMonthlyStats {
  final int year;
  final int month;
  final Map<CourseType, int> sessionsByType;  // ex: {individual: 8, collectif: 12}
  final int totalSessions;
  final Duration totalDuration;
}

// Provider
final profStatsProvider = StreamProvider.family<List<ProfMonthlyStats>, String>(
  (ref, profId) => ...,  // stream Drift groupé par mois
);
```

---

## 3. Architecture Technique — Plan Complet

### 3.1 Schema DB v24

**Nouvelle table : `course_sessions`**

| Colonne | Type | Notes |
|---------|------|-------|
| id | int? | PK auto |
| firebaseId | String? | Index non-unique |
| profId | String | FK → users.firestoreUid |
| terrainId | int | FK → terrains.id |
| type | String | enum CourseType |
| title | String | Libellé du cours |
| startTime | DateTime | Début de la session |
| endTime | DateTime | Fin de la session |
| status | String | planned / completed / cancelled |
| maxStudents | int? | Capacité max |
| notes | String? | Remarques |
| color | String? | Couleur hex UI |
| recurrenceDayOfWeek | int? | 1-7, null si ponctuel |
| recurrenceEndDate | DateTime? | Fin de récurrence |
| parentSessionId | int? | FK → course_sessions.id (instance maître) |
| createdAt | DateTime | |
| updatedAt | DateTime | |

**Migration v25 :**
- `CREATE TABLE course_sessions (...)` avec index sur `firebaseId`, `profId`, `terrainId`
- Pas de suppression de tables existantes
- Cascade delete : `terrains` → `course_sessions`

**Nouvelle collection Firestore : `course_sessions`**
- Structure miroir de la table Drift
- Listeners via FirebaseCacheService

---

### 3.2 Enum mis à jour

```
// lib/domain/enums/role.dart
enum Role { admin, agent, secretary, prof }  // ajout: prof

// lib/domain/enums/course_type.dart  (NOUVEAU)
enum CourseType { individual, collectif, stage, ecoleTennis }

// lib/domain/enums/course_status.dart  (NOUVEAU)
enum CourseStatus { planned, completed, cancelled }

// lib/domain/enums/terrain_slot_type.dart  (NOUVEAU)
enum TerrainSlotType { reservation, courseIndividual, courseCollectif, courseStage, courseEcole }
```

---

### 3.3 Permissions mises à jour

| Rôle | Terrains | Maintenance | Stock | Events | CourseSession | Users |
|------|----------|-------------|-------|--------|---------------|-------|
| admin | CRUD | CRUD | CRUD | CRUD | CRUD | ✅ |
| agent | view | CRUD | movements | — | view | ❌ |
| secretary | view | view ❌ pas d'action | view | CRUD | view (tous) | ❌ |
| prof | view | — | — | — | own CRUD | ❌ |

Règle prof CRUD : `profId == currentUser.firestoreUid` vérifié côté domain service.

---

### 3.4 Fichiers à créer

**Domain (Dart pur)**
```
lib/domain/enums/course_type.dart                      NOUVEAU
lib/domain/enums/course_status.dart                    NOUVEAU
lib/domain/enums/terrain_slot_type.dart                NOUVEAU
lib/domain/entities/course_session.dart                NOUVEAU
lib/domain/entities/terrain_slot.dart                  NOUVEAU (modèle agrégé)
lib/domain/models/prof_monthly_stats.dart              NOUVEAU
lib/domain/repositories/course_session_repository.dart NOUVEAU (interface)
lib/domain/services/conflict_checker_service.dart      NOUVEAU (interface)
lib/domain/enums/role.dart                             MODIFIER (ajout prof)
lib/domain/logic/permission_resolver.dart              MODIFIER (règles prof)
```

**Data**
```
lib/data/database/tables/course_sessions_table.dart    NOUVEAU
lib/data/database/app_database.dart                    MODIFIER (table + migration v24)
lib/data/mappers/course_session_mapper.dart            NOUVEAU
lib/data/repositories/course_session_repository_impl.dart NOUVEAU
lib/data/services/conflict_checker_service_impl.dart   NOUVEAU
lib/data/services/firebase_cache_service.dart          MODIFIER (listener course_sessions)
```

**Features — Cours (nouveau module)**
```
lib/features/cours/
  providers/cours_provider.dart                        NOUVEAU
  presentation/screens/cours_screen.dart               NOUVEAU
  presentation/screens/add_edit_cours_screen.dart      NOUVEAU
  presentation/screens/prof_stats_screen.dart          NOUVEAU
  presentation/widgets/cours_card.dart                 NOUVEAU
  presentation/widgets/recurrence_picker_widget.dart   NOUVEAU
```

**Features — Home (modifications)**
```
lib/features/home/providers/home_sections_provider.dart  NOUVEAU
lib/features/home/presentation/screens/home_screen.dart  MODIFIER
lib/features/home/presentation/widgets/prochains_cours_section.dart  NOUVEAU
lib/features/home/presentation/widgets/terrain_disponibilite_section.dart  NOUVEAU
```

**Features — Secretary (nouveau module ou dans calendar)**
```
lib/features/terrain_availability/
  providers/terrain_availability_provider.dart         NOUVEAU
  presentation/screens/terrain_availability_screen.dart NOUVEAU
  presentation/widgets/terrain_slot_tile.dart          NOUVEAU
```

**Core**
```
lib/core/router/app_router.dart                        MODIFIER (routes /cours, /add-edit-cours, /prof-stats, /terrain-disponibilite)
```

---

### 3.5 Nouveaux Providers Riverpod

```dart
// Lecture — StreamProvider<T>
courseSessionsProvider              // tous les cours (admin view)
profCourseSessionsProvider          // cours du prof connecté (filtré profId)
courseSessionsByTerrainProvider     // cours par terrain (vue dispo)
weeklyProfScheduleProvider          // cours de la semaine sélectionnée
terrainAvailabilityProvider         // List<TerrainSlot> fusionné reservations + cours

// Stats — StreamProvider.family
profMonthlyStatsProvider            // StreamProvider.family<List<ProfMonthlyStats>, String>

// Mutations — AsyncNotifierProvider
courseSessionNotifierProvider       // add / update / delete + conflict check

// UI State — StateProvider<T>
selectedWeekProvider                // StateProvider<DateTime>
courseTypeFilterProvider            // StateProvider<CourseType?>
selectedProfFilterProvider          // StateProvider<String?> (admin peut filtrer par prof)
```

---

## 4. Plan de Phases Jules

```
Ph1A [PARALLÈLE]
  Domain uniquement — aucune dépendance avec Ph1B
  Fichiers :
  - role.dart (+ prof)
  - course_type.dart, course_status.dart, terrain_slot_type.dart (nouveaux enums)
  - course_session.dart (entity : @immutable, copyWith, ==, hashCode, toString)
  - terrain_slot.dart (modèle agrégé)
  - prof_monthly_stats.dart
  - course_session_repository.dart (interface)
  - conflict_checker_service.dart (interface domain)
  - permission_resolver.dart (règles prof)

Ph1B [PARALLÈLE avec Ph1A]
  Documentation uniquement — fichiers disjoints
  Fichiers :
  - ARCHITECTURE.md (§3.4.x nouveau : cours feature, terrain availability)
  - PROJECT_SUMMARY.md (§2 : rôle prof, CourseSession entity, nouvelles tables)

Ph2 [SÉQUENTIEL après merge Ph1A]
  Data layer — dépend des entités domain de Ph1A
  Fichiers :
  - course_sessions_table.dart (Drift table)
  - app_database.dart (migration v24→v25, ajout CourseSessionsTable)
  - course_session_mapper.dart
  - course_session_repository_impl.dart (CRUD + filtres profId, terrainId, période)
  - conflict_checker_service_impl.dart (query overlap reservations + course_sessions)
  - firebase_cache_service.dart (listener collection course_sessions)
  Commande : flutter pub run build_runner build --delete-conflicting-outputs

Ph3 [SÉQUENTIEL après merge Ph2]
  Providers + Router — dépend du repository impl de Ph2
  Fichiers :
  - cours_provider.dart (tous les providers listés en §3.5)
  - home_sections_provider.dart
  - terrain_availability_provider.dart
  - app_router.dart (routes /cours, /add-edit-cours, /prof-stats, /terrain-disponibilite)

Ph4A [PARALLÈLE après merge Ph3]
  HomeScreen adaptatif — dépend de home_sections_provider (Ph3)
  Fichiers :
  - home_screen.dart (itération homeSectionsProvider)
  - prochains_cours_section.dart (widget prof)
  - terrain_disponibilite_section.dart (widget secretary)

Ph4B [PARALLÈLE après merge Ph3]
  Écrans Prof — dépend de cours_provider (Ph3)
  Fichiers :
  - cours_screen.dart (liste des cours du prof, groupée par jour)
  - add_edit_cours_screen.dart (formulaire + recurrence_picker_widget)
  - cours_card.dart
  - recurrence_picker_widget.dart

Ph4C [PARALLÈLE après merge Ph3]
  Écrans Secretary — dépend de terrain_availability_provider (Ph3)
  Fichiers :
  - terrain_availability_screen.dart (vue hebdomadaire)
  - terrain_slot_tile.dart

Ph4D [PARALLÈLE après merge Ph3]
  Stats Prof — dépend de profMonthlyStatsProvider (Ph3)
  Fichiers :
  - prof_stats_screen.dart (graphique par type, par mois)
```

---

## 5. Risques & Mitigations

| Risque | Sévérité | Mitigation |
|--------|----------|------------|
| Collision prof / reservation non détectée | 🔴 | ConflictCheckerService mandatory avant write. Test unitaire de l'overlap. |
| Récurrence infinie sans date de fin → explosion DB | 🟠 | Limiter la génération à 52 semaines max si recurrenceEndDate est null. |
| HomeScreen trop complexe avec 4 rôles | 🟡 | homeSectionsProvider isole toute la logique conditionnelle. Widget reste dumb. |
| parentSessionId crée une dépendance cyclique Drift | 🟡 | Self-referencing FK autorisée dans Drift (nullable + deferred constraint). |
| Migration v24 bloquante sur données existantes | 🟡 | Table nouvelle, pas de modification de tables existantes. Migration safe. |
| Jules génère les instances récurrentes côté client | 🔴 | Décision à documenter : les instances sont générées au moment de la création dans le repository, pas dans le widget ni le provider. |
| Filtrage profId incorrect → prof voit les cours d'un autre | 🔴 | profCourseSessionsProvider filtre sur currentUser.firestoreUid. Test unitaire obligatoire. |

---

## 6. Questions à Valider Avant Lancement Jules

```
☐ 1. Multi-terrain : Option A (session unique sur N courts) ou Option B (N sessions distinctes) ?
     → Recommandation Claude : Option B

☐ 2. Récurrence : gestion des exceptions (annulation d'une occurrence) dès MVP ou v2 ?
     → Recommandation Claude : v2

☐ 3. Récurrence : durée max si pas de date de fin (52 semaines ? 1 an ? infini ?) ?
     → Recommandation Claude : 52 semaines

☐ 4. Modification d'une récurrence : "cet événement" / "cet événement et les suivants" / "tous" ?
     → Recommandation Claude : "tous" uniquement pour MVP

☐ 5. Création de comptes prof : admin uniquement ou la secrétaire peut aussi créer un prof ?
     → Recommandation Claude : admin uniquement (cohérent avec permissions actuelles)

☐ 6. Vue dispo secrétaire : journalière, hebdomadaire ou mensuelle en priorité ?
     → Recommandation Claude : hebdomadaire

☐ 7. Stats prof : sessions planifiées ou sessions "completed" uniquement ?
     → Recommandation Claude : tous les statuts avec filtre, défaut = planned + completed
```

---

## 7. Acceptance Criteria (à valider lors du lancement)

**Rôle Prof :**
- [ ] Un prof peut créer un cours (individuel, collectif, stage, école de tennis) sur un terrain
- [ ] Un prof ne peut pas créer un cours sur un créneau déjà réservé (Reservation existante)
- [ ] Un prof voit les créneaux des autres profs (lecture seule)
- [ ] Un prof peut définir une récurrence hebdomadaire avec date de fin optionnelle
- [ ] Un prof n'a pas accès au stock, à la maintenance, ni aux utilisateurs
- [ ] Un prof voit ses cours du jour et de la semaine sur son dashboard
- [ ] Les stats mensuelles affichent le nombre de sessions par type (individual, collectif, stage, école)

**Secrétaire :**
- [ ] La secrétaire voit la disponibilité des terrains (Reservations + CoursSessions fusionnées)
- [ ] La secrétaire ne peut pas modifier une maintenance depuis le dashboard
- [ ] La vue de disponibilité affiche le nom du prof et le type de cours

**Admin :**
- [ ] L'admin voit tous les cours de tous les profs
- [ ] L'admin peut modifier ou supprimer un cours (surcharge admin)

**Technique :**
- [ ] flutter analyze → 0 erreurs
- [ ] flutter test → 0 failures
- [ ] build_runner → génération propre (migration v24 sans erreur)
- [ ] ConflictCheckerService testé unitairement (overlap start/end, cas limites)
- [ ] profCourseSessionsProvider filtré sur profId testé unitairement

---

## 8. Mises à Jour Documentation Requises (contenu à rédiger par Claude lors du lancement)

- `ARCHITECTURE.md` → §3.4.x : CourseSession feature, TerrainAvailability view, ConflictCheckerService
- `ARCHITECTURE.md` → §2 : CourseSessionsTable dans la liste des tables v24
- `PROJECT_SUMMARY.md` → §2 : rôle prof dans les features MVP
- `PROJECT_SUMMARY.md` → §5 : CourseSession dans les entités principales
- `PROJECT_SUMMARY.md` → §8 : schema v24 changelog

---

**Statut :** En attente de réponses aux 7 questions (§6) + validation humaine du plan global
**Prochaine action :** Humain valide → Claude rédige les prompts Jules pour chaque phase
**Durée estimée d'implémentation Jules :** 8 phases (2 parallèles max simultanées)
