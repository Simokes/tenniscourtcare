# Design System Override — MaintenanceScreen

> Ces règles **remplacent** les règles correspondantes de `MASTER.md` pour cet écran.
> Pour tout ce qui n'est pas mentionné ici, appliquer `MASTER.md`.

---

**Fichier :** `lib/features/maintenance/presentation/screens/maintenance_screen.dart`
**Dernière mise à jour :** 2026-03-09

---

## FAB

- Utiliser `FloatingActionButton` avec `shape: const CircleBorder()` — PAS `.extended`
- Icône : `Icons.add`
- Tooltip : libellé selon le rôle utilisateur (ex. "Nouvelle maintenance")
- Position : `floatingActionButtonLocation: FloatingActionButtonLocation.endFloat`

## KPI Strip

- Hauteur container : 56px (au lieu de 48px) pour respiration suffisante
- Padding vertical chips : 8px minimum
- Margin top depuis AppBar : `SizedBox(height: 12)` avant la strip
- Chip "en retard" : fond `dangerBgColor` + border `dangerColor.withOpacity(0.4)` quand count > 0
- Chip "à venir" et "ce mois" : fond transparent avec border `outlineVariant`

## Section Headers (`_MaintenanceSectionHeader`)

Structure premium :
```
Row(
  Bar colorée 3×18px  |  Label texte titleSmall bold  |  Spacer  |  Badge pilule count
)
```
- Badge pilule : `borderRadius: 12`, padding `horizontal: 8, vertical: 2`
- Badge bg : `color.withOpacity(0.15)`, text : `color`, fontSize: 12, fontWeight: bold
- Remplacer `'$label ($count)'` → label seul + badge séparé

## ActionCards (`_MaintenanceActionCard`)

- `borderRadius: 16` (au lieu de 12) — conformité design system
- `margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6)` (au lieu de 4)
- Boutons "Reporter" + "Compléter" :
  - Retirer `visualDensity: VisualDensity.compact`
  - Ajouter `minimumSize: Size(0, 44)` dans le style — touch target minimum
- Badge "EN RETARD" :
  - `fontSize: 11`, `letterSpacing: 0.5`, `borderRadius: 6`
  - Texte : 'EN RETARD' reste en majuscules
- `trailing` du card overdue : badge EN RETARD en haut à droite de la card

## PlannedCards (`_MaintenancePlannedCard`)

- `borderRadius: 16` (au lieu de 12)
- `margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6)`
- `dense: false` sur le `ListTile` → touch target suffisant
- Supprimer `trailing: Icon(Icons.chevron_right)` — l'action est un modal, pas une navigation
- Remplacer par : pas de trailing, ou `Icon(Icons.edit_outlined, size: 18, color: onSurfaceVariant)`

## Loading State

- Remplacer `CircularProgressIndicator` centré par 3 skeleton cards :
```dart
// Skeleton card simple
Container(
  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  height: 80,
  decoration: BoxDecoration(
    color: colorScheme.surfaceVariant.withOpacity(0.5),
    borderRadius: BorderRadius.circular(16),
  ),
)
```
- Répéter 3× dans une Column

## Error State

```dart
Column(
  children: [
    Icon(Icons.cloud_off_outlined, size: 48, color: colorScheme.onSurfaceVariant),
    SizedBox(height: 12),
    Text('Impossible de charger les maintenances', style: textTheme.bodyMedium),
    SizedBox(height: 8),
    TextButton(onPressed: () => ref.invalidate(plannedMaintenancesProvider), child: Text('Réessayer')),
  ],
)
```

## Empty State

```dart
Column(
  children: [
    Icon(Icons.check_circle_outline, size: 56, color: successColor),
    SizedBox(height: 16),
    Text('Tout est à jour', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
    SizedBox(height: 4),
    Text('Aucune maintenance planifiée', style: textTheme.bodySmall?.copyWith(color: onSurfaceVariant)),
  ],
)
```

## Bouton "Voir l'historique"

- Remplacer `TextButton.icon` par `OutlinedButton.icon` pleine largeur :
```dart
SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    icon: Icon(Icons.history),
    label: Text("Voir l'historique"),
    onPressed: () => context.push('/maintenance/history'),  // push, pas go
  ),
)
```
- Margin : `EdgeInsets.symmetric(horizontal: 16, vertical: 16)`

## Navigation

- Remplacer le bloc try/catch par : `context.push('/maintenance/history')`
- `context.push` conserve le back button (stack correct)
- Supprimer le fallback `Navigator.push`
