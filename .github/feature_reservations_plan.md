# Plan — Gestion des Réservations en Ligne

**Statut :** En attente de validation
**Version :** 1.0
**Date :** 2026-03-10
**Auteur :** Claude (architecte) + discussion avec planc

---

## 1. Contexte

Ajout d'un module de réservation de terrains accessible via l'app mobile et un site web.
Deux types de réservants : les **adhérents** (membres du club) et les **invités/passages** (externes).
Les **secrétaires** sont le pivot central : elles gèrent les réservations, les paiements, et font le lien entre agents de maintenance et profs/adhérents.

---

## 2. Acteurs & Rôles

| Acteur | Rôle DB (nouveau) | Accès | Spécificités |
|--------|------------------|-------|--------------|
| Admin | `admin` (existant) | App | Tout |
| Secrétaire | `secretary` (existant, élargi) | App + Web | Réservations, paiements, planning complet, tarification |
| Adhérent | `member` *(à créer)* | App + Web | 1h/j (2h si double), auto-annulation >24h |
| Invité/Passage | `guest` *(à créer)* | Web uniquement | Auth sociale ou compte invité, paiement en ligne ou au club |
| Agent | `agent` (existant) | App | Inchangé |

### Authentification invités (web)
- Google / Apple / Microsoft (Firebase Auth providers)
- Compte invité créé sur le site (email + mot de passe)
- Paiement : en ligne OU passage au club (choix au moment de la réservation)

---

## 3. Règles Métier

### 3.1 Adhérents
- **Quota** : 1h maximum par jour (2h si réservation en double — 2 joueurs)
- **Modification** : libre, sous réserve de disponibilité du nouveau créneau
- **Annulation** :
  - > 24h avant : annulation libre, remboursement automatique si paiement en ligne
  - < 24h avant : demande d'annulation → validation obligatoire par une secrétaire (qui décide du remboursement)
- **Abonnement** : annuel, de date à date (ex: 01/09/2025 → 31/08/2026), inclut 1h/jour

### 3.2 Invités / Passages
- Pas de quota journalier
- Tarif à l'heure selon le type de surface (voir §5.2)
- Paiement en ligne au moment de la réservation OU règlement manuel au club
- Annulation : même règle 24h que les adhérents
- La secrétaire peut créer une réservation invité (réservation par téléphone, passage direct)

### 3.3 Conflict Detection (disponibilité)
Un créneau est **disponible** si et seulement si :
1. Il est dans les horaires d'ouverture du terrain ce jour-là
2. Aucune autre réservation confirmée sur ce terrain à ce créneau
3. Le terrain n'est pas en fermeture (maintenance, événement, `closureUntil`)

---

## 4. Horaires & Créneaux

### 4.1 Horaires d'ouverture
- Variables selon la **saison** (été = horaires étendus)
- Variables selon le **terrain** (ex : terrain sans éclairage = fermeture plus tôt)
- Modifiables par admin/secrétaire sans redéploiement

### 4.2 Modèle de données — `ClubSchedules` (nouvelle table)
```
terrainId (nullable — null = horaire global du club)
seasonName (TEXT) — ex: "été", "hiver", "intersaison"
validFrom (DATE)
validUntil (DATE)
mondayOpen / mondayClose (TIME HH:mm)
tuesdayOpen / tuesdayClose
...
sundayOpen / sundayClose
```

> Si `terrainId` est null → horaire par défaut du club.
> Si `terrainId` est renseigné → override pour ce terrain uniquement.

### 4.3 Durée des créneaux
- Créneaux fixes de **1h** (durée standard)
- Réservation double = 2 joueurs sur 1 créneau de 1h (pas 2h) — quota comptabilisé 2h côté adhérent uniquement

---

## 5. Tarification

### 5.1 Abonnements (adhérents)
- Formule unique : **annuel**, de date à date
- Inclut 1h/jour sur la durée de l'abonnement
- Géré et suivi par la secrétaire (pas de paiement en ligne pour les abonnements — trésor public)

### 5.2 Tarifs passage (invités)
- Prix fixe à l'heure, **par type de surface** :

| Surface | Exemples |
|---------|----------|
| Terre battue | Prix A |
| Béton poreux | Prix B |
| Gazon synthétique | Prix C |

- Les prix sont configurables par admin/secrétaire
- Pas de tarification peak/off-peak dans un premier temps

### 5.3 Méthode de paiement
- **En ligne** : à définir (trésor public — contraintes spécifiques, aucun choix arrêté)
- **Manuel au club** : enregistrement par la secrétaire (mode, montant, date)
- **Abonnements** : gestion manuelle uniquement (hors ligne)

> ⚠️ L'intégration de paiement en ligne est reportée à une phase ultérieure, après choix de la solution compatible trésor public.

---

## 6. Interface Secrétaire (élargie)

La secrétaire devient le pivot central de l'application :

| Fonctionnalité | Description |
|----------------|-------------|
| Vue planning complet | Grille terrain × créneaux (jour / semaine) |
| Création réservation | Pour adhérent, invité, prof, téléphone |
| Validation annulations | File des demandes <24h |
| Enregistrement paiement | Mode (cash/carte/virement), montant, date |
| Gestion tarification | Prix par surface, config horaires |
| Suivi abonnements | Liste adhérents, dates, quota restant du jour |
| Vision planning maintenance | Lecture seule — éviter conflits terrain |

---

## 7. Schéma Base de Données — Changements v25

### 7.1 Table `reservations` — Refonte complète
Colonnes actuelles à **supprimer** (legacy architecture pre-v22) :
- `syncedAt`, `isSyncPending`, `remoteId`

Colonnes à **ajouter** :
```
firebaseId (TEXT nullable)         — standard architecture v24
createdBy (TEXT nullable)          — UID Firebase créateur
modifiedBy (TEXT nullable)         — UID Firebase dernier modificateur

guestFirebaseUid (TEXT nullable)   — UID Firebase Auth pour invités
guestName (TEXT nullable)          — si invité non inscrit en DB
guestEmail (TEXT nullable)
guestPhone (TEXT nullable)

bookingType (TEXT)                 — "single" | "double"
cancellationStatus (TEXT nullable) — null | "requested" | "approved" | "rejected"
cancellationRequestedAt (DATETIME nullable)
cancellationReason (TEXT nullable)

paymentStatus (TEXT)               — "pending" | "paid" | "manual_pending" | "refunded"
paymentMethod (TEXT nullable)      — "online" | "cash" | "card" | "transfer"
paymentAmount (REAL nullable)
paymentReference (TEXT nullable)   — référence paiement en ligne (future)

bookedBySecretaryId (TEXT nullable) — si créée par secrétaire
```

### 7.2 Nouvelle table `club_schedules`
Voir §4.2 ci-dessus.

### 7.3 Nouvelle table `pricing_rules`
```
id (int autoincrement)
firebaseId (TEXT nullable)
surfaceType (TEXT)         — "clay" | "hard" | "synthetic_grass" | ...
pricePerHour (REAL)
validFrom (DATE nullable)
validUntil (DATE nullable)
createdAt, updatedAt, createdBy, modifiedBy
```

### 7.4 Migration : v24 → v25
- Recréation table `reservations` (drop + recreate pour supprimer colonnes legacy)
- Création `club_schedules`
- Création `pricing_rules`

---

## 8. Nouveau Rôle `member` dans `Role` enum

```dart
member(label: 'Adhérent', description: 'Membre du club, accès réservations en ligne')
guest(label: 'Invité', description: 'Passage externe, réservation ponctuelle')
```

> `guest` peut rester hors du `Role` enum si les invités ne sont jamais des utilisateurs internes — à décider à l'implémentation.

---

## 9. Flux de Données (Architecture)

Conforme à l'architecture existante (Firebase = source de vérité, Drift = cache lecture) :

```
Réservation adhérent/invité (web/app)
  → Repository → Firestore [reservations/{id}]
  → FirebaseCacheService listener → Drift
  → StreamProvider → UI secrétaire / adhérent

Validation annulation (secrétaire)
  → Repository → Firestore update (status: cancelled)
  → FirebaseCacheService → Drift
  → Notification push/email à l'adhérent (Phase 5)
```

**Conflict detection** : côté Firestore via Cloud Function (transaction atomique) ou règles Firestore — à décider à l'implémentation pour éviter les race conditions.

---

## 10. Accès Web (Flutter Web)

- Migration **Drift WASM** requise (remplacement de `_openConnection()` dans `app_database.dart`)
- Firebase Auth : activation des providers Google / Apple / Microsoft dans la console Firebase
- Les invités utilisent uniquement le site web (pas l'app mobile)
- Les adhérents utilisent l'app mobile ET/OU le site web

---

## 11. Phases d'Implémentation

```
Ph1 — Foundation
  ├── Migration DB v24→v25 (refonte Reservations + nouvelles tables)
  ├── Nouveaux rôles member + guest
  ├── Entité domain Reservation enrichie
  ├── Règles métier : quota 1h/j, conflict detection
  └── FirebaseCacheService étendu aux réservations

Ph2A — Interface Secrétaire [SÉQUENTIEL après Ph1]
  ├── Vue planning grille terrain × créneaux
  ├── Création réservation manuelle (adhérent / invité / téléphone)
  ├── Validation demandes d'annulation
  ├── Enregistrement paiement manuel
  └── Config tarification + horaires

Ph2B — Portail Adhérent App [PARALLÈLE avec Ph2A]
  ├── Écran "Mes réservations"
  ├── Nouvelle réservation (quota vérifié)
  ├── Modification terrain/heure
  └── Annulation libre >24h / demande <24h

Ph3 — Flutter Web + Portail Invité [SÉQUENTIEL après Ph2A]
  ├── Migration Drift WASM
  ├── Firebase Auth (Google / Apple / Microsoft / email)
  ├── Page publique : sélecteur créneaux disponibles
  └── Choix paiement : en ligne (TBD) ou au club

Ph4 — Paiement en Ligne [SÉQUENTIEL après Ph3 — solution TBD]
  ├── Intégration solution paiement compatible trésor public
  ├── Workflow paiement réservation invité
  └── Remboursements automatiques (annulation >24h)

Ph5 — Automatisation [PARALLÈLE après Ph4]
  ├── Notifications push + email
  │     (confirmation, rappel J-1, annulation approuvée)
  ├── Auto-libération créneau non payé après X min (Cloud Function)
  └── Tableau de bord financier secrétaire (CA, paiements en attente)
```

### Dépendances
```
Ph1 → Ph2A → Ph3 → Ph4 → Ph5
Ph1 → Ph2B (indépendant de Ph2A)
```

---

## 12. Points en Suspens (à décider avant implémentation)

| # | Question | Impact |
|---|----------|--------|
| 1 | Solution paiement en ligne compatible trésor public | Ph4 — bloque paiement en ligne |
| 2 | Durée créneaux : uniquement 1h ou aussi 30min ? | Modèle de données |
| 3 | Les invités ont-ils un historique inter-sessions ? | Besoin d'un vrai compte vs session anonyme |
| 4 | Les profs ont-ils un rôle distinct ou sont-ils des `member` ? | Role enum |
| 5 | Nombre de terrains / types de surface du club | Données de config initiale |
| 6 | Politique de remboursement annulation (<24h) | Règles métier secrétaire |

---

## 13. Ce Qui N'est PAS Dans Ce Plan (hors scope v1)

- Liste d'attente automatique sur créneaux libérés
- Réservation récurrente (même créneau chaque semaine)
- Application mobile dédiée invités (web only pour eux)
- Statistiques avancées d'occupation des terrains
- Intégration agenda Google/Outlook

---

*Document de référence — aucune implémentation engagée à ce stade.*
*À valider avec le responsable projet avant de démarrer Ph1.*
