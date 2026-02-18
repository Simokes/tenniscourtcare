# Court Care - Instructions d'installation et d'utilisation

## 📋 Prérequis

- Flutter SDK 3.10.8 ou supérieur
- Dart 3.x
- Un IDE (VS Code, Android Studio, etc.)

## 🚀 Installation

### 1. Installer les dépendances

```bash
flutter pub get
```

### 2. Générer le code Drift

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Note:** Si vous modifiez les tables Drift, relancez cette commande.

### 3. Lancer l'application

#### Mobile (Android/iOS)
```bash
flutter run
```

#### Web
```bash
flutter run -d chrome
```

**Note pour le web:** Drift utilise IndexedDB sur le web. Les données sont persistées dans le navigateur.

#### Desktop (Windows/Linux/macOS)
```bash
flutter run -d windows  # ou linux, macos
```

## 📁 Structure du projet

```
lib/
├── domain/
│   └── entities/          # Entités métier (Terrain, Maintenance)
├── data/
│   └── database/          # Drift (tables, app_database, watchers)
├── presentation/
│   ├── providers/         # Riverpod providers
│   ├── screens/           # Écrans principaux
│   └── widgets/           # Widgets réutilisables
└── utils/                 # Utilitaires (dates, CSV)
```

## 🧪 Tests

### Lancer tous les tests
```bash
flutter test
```

### Tests spécifiques
```bash
flutter test test/drift/database_test.dart
flutter test test/providers/maintenance_provider_test.dart
flutter test test/providers/stats_providers_test.dart
```

## 🔧 Configuration

### Base de données

La base de données SQLite est créée automatiquement au premier lancement :
- **Mobile:** `{appDocumentsDirectory}/court_care.db`
- **Web:** IndexedDB (géré automatiquement)
- **Desktop:** `{appDocumentsDirectory}/court_care.db`

### Migrations

Les migrations sont gérées dans `app_database.dart` via `MigrationStrategy`. Pour ajouter une migration :

1. Incrémenter `schemaVersion`
2. Ajouter la logique dans `onUpgrade`

## 📊 Fonctionnalités

### Phase 1 (Terminée)
- ✅ CRUD maintenances
- ✅ Règles métier matériaux (validation côté Notifier)
- ✅ Historique par terrain
- ✅ Totaux réactifs

### Phase 2 (Terminée)
- ✅ Totaux mensuels
- ✅ Sélection période (Jour/Semaine/Mois/Custom)
- ✅ Sélection multi-terrains
- ✅ Séries temporelles
- ✅ Stats screen + charts
- ✅ Édition maintenance
- ✅ Tests Drift & Riverpod
- ✅ Chart option "empilé"
- ✅ Export CSV

### Phase 3 (À venir)
- Table `stock` (manto, sottomanto, silice)
- Décrément automatique lors des maintenances
- Alerte seuil

### Phase 4 (À venir)
- Coûts par matériau
- Coût par maintenance
- Rapports financiers

## 🎯 Règles métier

### Terrains en terre battue
- ✅ Autorise : Manto, Sottomanto
- ❌ Interdit : Silice

### Terrains synthétiques
- ✅ Autorise : Silice
- ❌ Interdit : Manto, Sottomanto

**Important:** La validation est effectuée dans `MaintenanceNotifier`. L'UI peut masquer des champs, mais la validation finale est côté Notifier.

## 🔍 Dépannage

### Erreur "Table not found"
- Vérifiez que `build_runner` a été exécuté
- Supprimez l'app et relancez (pour recréer la DB)

### Erreur "Provider not found"
- Vérifiez que `ProviderScope` entoure l'app dans `main.dart`

### Watchers ne se mettent pas à jour
- Vérifiez que les clés `.family` sont stables
- Vérifiez que les providers utilisent `watch()` et non `read()`

## 📝 Notes de développement

### Ajouter un terrain

Pour l'instant, les terrains doivent être ajoutés directement en base de données ou via un écran dédié (à implémenter).

### Ajouter une maintenance

1. Cliquer sur le bouton "+" sur un terrain
2. Remplir le formulaire
3. La validation métier s'effectue automatiquement

### Export CSV

1. Aller dans l'écran Statistiques
2. Cliquer sur l'icône de téléchargement
3. Le fichier CSV est généré avec les séries de sacs

## 🚨 Invariants (NE JAMAIS CASSER)

1. **Terre battue → silice = 0** (garanti par validation Notifier)
2. **Synthétique → manto = 0 & sottomanto = 0** (garanti par validation Notifier)
3. **Aucune écriture DB hors providers/notifiers**
4. **Aucune règle métier en UI**
5. **Toutes les agrégations via Drift watch()**

## 📚 Documentation

- [Riverpod v2](https://riverpod.dev/)
- [Drift](https://drift.simonbinder.eu/)
- [Flutter](https://flutter.dev/)
