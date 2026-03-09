# CourtCare — Design System Master

> **LOGIQUE :** Lors de la construction d'une page spécifique, vérifier d'abord `design-system/pages/[page-name].md`.
> Si ce fichier existe, ses règles **remplacent** ce Master. Sinon, suivre strictement les règles ci-dessous.

---

**Projet :** CourtCare
**Stack :** Flutter 3.x / Material 3 / Riverpod
**Dernière mise à jour :** 2026-03-09
**Source de vérité thème :** `lib/core/theme/app_theme.dart`

---

## 1. Palette de couleurs

### Brand

| Rôle | Hex | AppColors |
|------|-----|-----------|
| Primary | `#003580` | `AppColors.primary` |
| Primary Dark | `#002A5C` | `AppColors.primaryDark` |
| Primary Light | `#0EA5E9` | `AppColors.primaryLight` |

### Sémantique

| Rôle | Hex | AppColors |
|------|-----|-----------|
| Success | `#16A34A` | `AppColors.success` |
| Success Bg | `#DCFCE7` | `AppColors.successBg` |
| Warning | `#F59E0B` | `AppColors.warning` |
| Warning Bg | `#FEF3C7` | `AppColors.warningBg` |
| Danger | `#DC2626` | `AppColors.danger` |
| Danger Bg | `#FEE2E2` | `AppColors.dangerBg` |
| Info | `#0EA5E9` | `AppColors.info` |
| Info Bg | `#E0F2FE` | `AppColors.infoBg` |

### Types de terrain

| Rôle | Hex | AppColors |
|------|-----|-----------|
| Terre battue | `#EA580C` | `AppColors.terreBattue` |
| Synthétique | `#1D4ED8` | `AppColors.synthetique` |
| Dur | `#475569` | `AppColors.dur` |

### Surfaces

| Rôle | Hex | AppColors | Usage |
|------|-----|-----------|-------|
| Background Light | `#F5F7F8` | `AppColors.backgroundLight` | Scaffold light |
| Background Dark | `#101722` | `AppColors.backgroundDark` | Scaffold dark |
| Surface Dark | `#0F172A` | `AppColors.surfaceDark` | Cards dark |
| Surface Light | `#FFFFFF` | — | Cards light |

### Accès dans les widgets

```dart
// Couleurs Material adaptées au thème (PRÉFÉRER)
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.surface

// Couleurs brand statiques (hors-widget ou const)
AppColors.primary

// Couleurs métier dashboard
final dc = Theme.of(context).extension<DashboardColors>()!;
dc.maintenanceColor
dc.dangerColor
```

---

## 2. Typographie

**Police unique :** Inter (Google Fonts)
**Fichier :** `GoogleFonts.interTextTheme()`

| Style Flutter | Usage | Taille cible |
|---------------|-------|--------------|
| `displayLarge` | Titres principaux | 32px+ |
| `headlineMedium` | Titres de section | 24px |
| `titleMedium` | En-têtes de cards | 16px semibold |
| `bodyMedium` | Corps de texte | 14px |
| `bodySmall` | Labels, captions | 12px |
| `labelSmall` | Badges, chips | 11px |

**Règles :**
- Minimum 14px pour le corps de texte sur mobile
- `fontWeight: FontWeight.w600` pour les titres de sections
- Ne jamais hardcoder une `TextStyle` — utiliser `Theme.of(context).textTheme`

---

## 3. Espacement

| Token | Valeur | Usage Flutter |
|-------|--------|---------------|
| `xs` | 4px | `SizedBox(height: 4)`, gap inline |
| `sm` | 8px | Gap icône-texte, padding interne compact |
| `md` | 16px | Padding standard cards, padding horizontal |
| `lg` | 24px | Gap entre sections |
| `xl` | 32px | Marges grands blocs |
| `2xl` | 48px | Section hero, espacement vertical majeur |

**Règle :** Ne jamais hardcoder des valeurs de padding différentes — utiliser ces tokens.

---

## 4. Composants

### Cards

```dart
Card(
  // Thème global appliqué automatiquement :
  // elevation: 0, borderRadius: 16, color: surface
  child: Padding(
    padding: const EdgeInsets.all(16), // --space-md
  ),
)
```

**Règles :**
- `elevation: 0` toujours (défini dans CardThemeData)
- `borderRadius: 16` toujours
- Fond light : blanc pur `Colors.white`
- Fond dark : `AppColors.surfaceDark` (`#0F172A`)
- Pas de `surfaceTintColor` (désactivé globalement)

### Boutons

```dart
// CTA Principal
FilledButton(
  onPressed: () {},
  child: Text('Action'),
)
// => colorScheme.primary (#003580)

// Secondaire
OutlinedButton(...)

// Icône action
IconButton(
  iconSize: 24,
  // Touch target minimum : 48x48 automatique avec Material 3
)
```

**Touch targets :** Minimum 48×48px — Material 3 le garantit par défaut.

### AppBar

```dart
AppBar(
  // elevation: 0
  // surfaceTintColor: transparent
  // backgroundColor: Colors.white (light) / AppColors.backgroundDark (dark)
)
```

### Chips / Badges KPI

```dart
Chip(
  // Hauteur minimum 32px
  // Padding horizontal 12px
  // borderRadius: 8
)
```

### FAB

```dart
FloatingActionButton(
  shape: const CircleBorder(), // OBLIGATOIRE — forme circulaire
  tooltip: 'Action selon rôle',
  onPressed: () {},
)
```

---

## 5. Ombres

| Niveau | BoxShadow Flutter | Usage |
|--------|-------------------|-------|
| None | `elevation: 0` | Cards standard (défaut) |
| Subtle | `BoxShadow(color: Colors.black12, blurRadius: 4)` | Éléments flottants légers |
| Medium | `BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: Offset(0,4))` | Modals, bottom sheets |
| Strong | `BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 16)` | FAB, overlays |

---

## 6. Animations & Transitions

| Contexte | Durée | Courbe |
|----------|-------|--------|
| Micro-interactions (tap, toggle) | 150ms | `Curves.easeOut` |
| Transitions de pages | 250ms | `Curves.easeInOut` |
| Apparition de modals | 300ms | `Curves.easeOut` |
| Animations complexes | 400ms | `Curves.elasticOut` |

**Règles :**
- Toujours utiliser `AnimatedContainer`, `AnimatedOpacity` pour les changements d'état
- Respecter `MediaQuery.of(context).disableAnimations` (prefers-reduced-motion)
- Pas d'animation > 400ms sans raison UX justifiée

---

## 7. Icônes

**Bibliothèque :** Material Icons (intégrées Flutter) + `Icons.*`

| Contexte | Taille |
|----------|--------|
| AppBar / navigation | 24px |
| Cards inline | 20px |
| Badges / chips | 16px |
| FAB | 28px |

**Règles :**
- Jamais d'emojis comme icônes UI
- Couleur icône = `colorScheme.onSurface` ou couleur sémantique contextuelle
- `semanticLabel` obligatoire sur les icônes sans libellé visible

---

## 8. Dark Mode

L'app supporte light + dark nativement via `AppTheme.lightTheme` / `AppTheme.darkTheme`.

**Règles :**
- Ne jamais hardcoder `Colors.white` ou `Colors.black` directement
- Toujours utiliser `Theme.of(context).colorScheme.*` pour les couleurs adaptatives
- Exception : `AppColors.*` pour les couleurs brand et sémantiques (restent fixes)
- Tester chaque écran en light ET dark avant livraison

---

## 9. Layout & Responsive

**Largeur cible principale :** 375px–430px (mobile)
**Breakpoints à considérer :** 600px (tablet portrait)

```dart
// Padding horizontal standard
const EdgeInsets.symmetric(horizontal: 16) // --space-md

// Padding horizontal sections importantes
const EdgeInsets.symmetric(horizontal: 24) // --space-lg
```

**Règles :**
- `CustomScrollView` + Slivers pour les écrans scrollables
- Pas de `SingleChildScrollView` + `Column` pour les listes longues
- `ListView.builder` ou `SliverList` pour les listes dynamiques
- `SafeArea` sur tous les écrans principaux

---

## 10. UX & Accessibilité

### Touch targets
- Minimum **48×48px** (Material 3 par défaut)
- Les actions secondaires (icônes seules) : envelopper dans `IconButton`

### Feedback interactif
- Loading async : `CircularProgressIndicator` ou skeleton (via `shimmer`)
- Erreurs : `SnackBar` avec action de retry
- Succès : `SnackBar` court (2s) ou animation inline

### Sémantique
- `Semantics(label: '...')` sur les éléments visuels sans texte
- `Tooltip` sur tous les `IconButton` sans libellé

### Contraste
- Texte sur fond clair : minimum ratio 4.5:1
- Texte sur `AppColors.primary` (#003580) : utiliser `Colors.white`
- Texte muted light : `Colors.black54` minimum

---

## 11. Anti-patterns (INTERDIT)

- ❌ `print()` → utiliser `debugPrint()`
- ❌ Logique métier dans les widgets → providers uniquement
- ❌ Hardcoder des couleurs hors `AppColors` / `colorScheme`
- ❌ Hardcoder des `TextStyle` hors `textTheme`
- ❌ `elevation` > 0 sur les `Card` (briser la cohérence)
- ❌ FAB non-circulaire
- ❌ Touch targets < 48px
- ❌ Animations > 400ms
- ❌ Emojis comme icônes UI

---

## 12. Checklist pré-livraison

- [ ] flutter analyze → 0 erreurs
- [ ] Testé en light mode ET dark mode
- [ ] Touch targets ≥ 48px sur toutes les actions
- [ ] Pas de couleurs hardcodées hors `AppColors` / `colorScheme`
- [ ] `debugPrint` à la place de `print`
- [ ] `SafeArea` présente sur l'écran
- [ ] `Semantics` / `Tooltip` sur les icônes seules
- [ ] Animations ≤ 400ms
