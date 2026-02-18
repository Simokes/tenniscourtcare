# Checklist de validation - Court Care

## ✅ Architecture

- [x] Structure domain/data/presentation respectée
- [x] Pas d'aplatissement de l'architecture
- [x] Pas de logique métier dans l'UI
- [x] Mapping Drift <-> Domaine propre (pas de types Drift dans /domain)

## ✅ Base de données (Drift)

- [x] Tables créées (Terrains, Maintenances)
- [x] Watchers implémentés (`watchSacsTotals`, `watchDailySeries`, etc.)
- [x] Agrégations via `watch()` uniquement
- [x] Epoch ms pour BETWEEN
- [x] Multi-terrains via `IN (...)`
- [x] Clés `.family` stables (startOfDay, endOfDay, etc.)
- [x] Migrations configurées (`schemaVersion` + `MigrationStrategy`)
- [x] `databaseProvider` unique et stable avec `close()` onDispose

## ✅ Providers Riverpod

- [x] `databaseProvider` - Provider<AppDatabase> (unique, stable)
- [x] `terrainsProvider` - FutureProvider<List<Terrain>>
- [x] `maintenancesByTerrainProvider` - FutureProvider.family
- [x] `maintenanceCountProvider` - FutureProvider.family
- [x] `sacsTotalsProvider` - StreamProvider.family
- [x] `monthlyTotalsByTerrainProvider` - StreamProvider.family
- [x] `monthlyTotalsAllTerrainsProvider` - StreamProvider.family
- [x] `statsPeriodProvider` - StateNotifier (bornes stables)
- [x] `selectedTerrainsProvider` - StateNotifier<Set<int>>
- [x] `sacksSeriesProvider` - StreamProvider
- [x] `maintenanceTypesSeriesProvider` - StreamProvider
- [x] **Aucune dépendance async→async entre providers**

## ✅ Règles métier

- [x] Validation dans `MaintenanceNotifier` uniquement
- [x] Terre battue → Manto + Sottomanto uniquement (silice = 0)
- [x] Synthétique → Silice uniquement (manto = 0, sottomanto = 0)
- [x] Invariants garantis en base (pas de mélange non autorisé)
- [x] Tests positifs & négatifs pour validation métier

## ✅ Écrans

- [x] `HomeScreen` - Affiche totaux du mois (Stream réactif)
- [x] `MaintenanceScreen` - Liste des terrains + CTA ajout
- [x] `TerrainMaintenanceHistoryScreen` - Cartes Aujourd'hui + Cette semaine + liste
- [x] `StatsScreen` - Sélection période + multi-terrains + charts

## ✅ Widgets

- [x] `TerrainCard` - Affiche `maintenancesDuJour`, actions
- [x] `AddMaintenanceSheet` - Création/édition (validation déportée au Notifier)
- [x] `GroupedBarChart` - CustomPainter complet (axes, grille, labels, barres groupées/empilées)

## ✅ Tests

- [x] Tests Drift : watchers réémettent sur insert/update/delete
- [x] Tests Drift : agrégations respectent invariants
- [x] Tests Drift : BETWEEN avec epoch ms correct
- [x] Tests Drift : multi-terrains IN (...) correct
- [x] Tests Drift : totaux journaliers/hebdo/mensuels corrects
- [x] Tests Riverpod : pas de dépendances async→async
- [x] Tests Riverpod : clés `.family` stables
- [x] Tests Riverpod : Notifiers → validation stricte (positifs & négatifs)
- [x] Tests Riverpod : mise à jour réactive via providers Stream

## ✅ Fonctionnalités

- [x] CRUD maintenances
- [x] Totaux réactifs (Stream)
- [x] Totaux mensuels
- [x] Sélection période (Jour/Semaine/Mois/Custom)
- [x] Sélection multi-terrains
- [x] Séries temporelles (jour/semaine/mois)
- [x] Charts réactifs
- [x] Édition maintenance
- [x] Export CSV

## ✅ Configuration

- [x] `pubspec.yaml` avec Riverpod v2 + Drift
- [x] `build.yaml` configuré pour Drift
- [x] `build_runner` fonctionnel
- [x] Utils date : startOfDay, endOfDay, startOfWeek, endOfWeek, startOfMonth, endOfMonth (epoch ms)

## ✅ Qualité

- [x] Code organisé par fichiers avec chemins corrects
- [x] Pas de types Drift dans /domain
- [x] Styles Material 3
- [x] Gestion d'erreurs appropriée
- [x] Documentation inline où nécessaire

## ⚠️ Points d'attention

- [ ] Seed DEV optionnel (à implémenter si besoin)
- [ ] Ajout de terrains via UI (actuellement manuel)
- [ ] Gestion des erreurs réseau (non applicable, local-first)
- [ ] Tests UI (golden tests) - optionnel

## 🎯 Prochaines étapes (Phases 3 & 4)

- [ ] Table `stock` (manto, sottomanto, silice)
- [ ] Décrément automatique lors des maintenances validées
- [ ] Alerte seuil (Stream + provider dédié)
- [ ] Coût par matériau (table coûts)
- [ ] Coût par maintenance (calcul + attribution)
- [ ] Rapports financiers (totaux période & par terrain)
