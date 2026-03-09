# Design System Override — MaintenanceHistoryScreen

> Ces règles **remplacent** les règles correspondantes de `MASTER.md` pour cet écran.
> Pour tout ce qui n'est pas mentionné ici, appliquer `MASTER.md`.

---

**Fichier :** `lib/features/maintenance/presentation/screens/maintenance_history_screen.dart`
**Dernière mise à jour :** 2026-03-09

---

## AppBar / SliverAppBar

- Ajouter un `SliverAppBar` en premier sliver :
```dart
SliverAppBar(
  title: Text('Historique'),
  floating: true,
  snap: true,
  elevation: 0,
  surfaceTintColor: Colors.transparent,
)
```
- Le back button est géré automatiquement par Flutter/GoRouter

## KPI Row

- Les 3 KPIs DOIVENT refléter le filtre actif (`_selectedPeriod`)
- Recalculer `doneCount` et `plannedCount` en appliquant le même `startDate` que pour les listes
- Structure du calcul à aligner sur `_TerrainHistoryTile._applyFilters`
- Chips : même style que `MASTER.md` — `borderRadius: 16`, padding `horizontal: 12, vertical: 8`

## Filter Bar

**Interdire le mélange `DropdownButton` + `ChoiceChip`.**

Remplacer `DropdownButton<String?>` par `DropdownMenu<String?>` (Material 3) :
```dart
DropdownMenu<String?>(
  initialSelection: _selectedType,
  hintText: 'Tous types',
  inputDecorationTheme: InputDecorationTheme(
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
  ),
  dropdownMenuEntries: [
    DropdownMenuEntry<String?>(value: null, label: 'Tous types'),
    ...maintenanceTypes.map((t) => DropdownMenuEntry<String?>(value: t, label: t)),
  ],
  onSelected: (val) => setState(() => _selectedType = val),
)
```
- Hauteur du DropdownMenu : alignée avec les ChoiceChips (32px dense)
- Les séparateurs manuels (`Container(width: 1, height: 24)`) peuvent être conservés

## Emojis → Icon widgets

Remplacer dans `_TerrainHistoryTile.subtitle` :
```dart
// AVANT (interdit)
Text('✅ $filteredDoneCount effectuées', ...)
Text('📅 $plannedCount planifiées', ...)
Text('🕒 Dernière: $formattedLastDate', ...)

// APRÈS
Row(children: [
  Icon(Icons.check_circle_outline, size: 14, color: dc?.successColor ?? Colors.green),
  SizedBox(width: 4),
  Text('$filteredDoneCount effectuées', style: TextStyle(color: dc?.successColor ?? Colors.green, fontSize: 12)),
])
// Même pattern pour les 3 lignes
// Envelopper dans un Wrap(spacing: 12, runSpacing: 4)
```

## `_TerrainHistoryTile`

- `elevation: 0` (au lieu de 2) — conformité design system
- `borderRadius: 16` (au lieu de 12)
- `margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6)` (au lieu de 8)
- Titre terrain : `textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)` (au lieu de `const TextStyle(fontWeight: FontWeight.bold)`)
- Empty state dans l'expanded (aucune maintenance) :
```dart
Padding(
  padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
  child: Column(
    children: [
      Icon(Icons.inbox_outlined, size: 32, color: cs.onSurfaceVariant),
      SizedBox(height: 8),
      Text('Aucune maintenance pour cette période',
          style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontStyle: FontStyle.italic)),
    ],
  ),
)
```

## `_MaintenanceHistoryItem`

- Remplacer `const TextStyle(fontWeight: FontWeight.bold)` → `textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)`
- Remplacer `const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)` → `textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)`
- Remplacer `Theme.of(context).primaryColor` → `Theme.of(context).colorScheme.primary`
- `useSafeArea: true` sur le `showModalBottomSheet` du bouton edit (ligne 556)
- `showDragHandle: true` sur le bottomSheet edit pour cohérence

## `_SacChip` — Labels explicites

Remplacer les labels cryptiques :
- `'M: $n'` → `'Manto: $n'`
- `'S: $n'` → `'Sott.: $n'`
- `'Si: $n'` → `'Silice: $n'`

## Couleurs

- `dc?.maintenanceColor` → chip type de maintenance
- `dc?.successColor` → maintenances effectuées
- `dc?.warningColor` → maintenances planifiées
- Jamais `Colors.brown`, `Colors.blueGrey`, `Colors.teal` hardcodés dans les SacChips : utiliser des constantes nommées ou les couleurs du thème terrain
