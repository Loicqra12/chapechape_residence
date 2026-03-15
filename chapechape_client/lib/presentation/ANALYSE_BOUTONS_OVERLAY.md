# Analyse des boutons overlay – chapechape_client

Inventaire des boutons affichés **par-dessus** le contenu (photo, carte, liste) sur tous les écrans, avec statut mode sombre / thème.

---

## 1. residence_details_screen.dart

| Emplacement | Widget | Style actuel | Mode sombre |
|------------|--------|--------------|-------------|
| Overlay sur galerie photo | `_circleBtn` (retour, partage, favoris) | `_surface`, `_onSurface`, `shadow` du thème | OK (déjà corrigé) |

- **Lignes 224–272** : `_buildPhotoOverlay` → 3 boutons ronds (retour, partage, cœur favori).
- Utilise `colorScheme.surface` et `colorScheme.onSurface` + ombre thème → visible en clair et sombre.

---

## 2. search_screen.dart

| Emplacement | Widget | Style actuel | Mode sombre |
|------------|--------|--------------|-------------|
| Barre flottante (carte) | Material + Row (retour, résumé, filtres) | `colorScheme.surface`, `onSurface`, `primary` (icône filtre) | OK |
| Cœur favori sur marqueur carte | `_FavoriteButton` (l.70–86) | `surface`, `onSurface` / `primaryColor` | OK |

- Barre : `Material(color: colorScheme.surface)` avec `IconButton` retour et bouton filtres (icône `primary` quand inactif).
- Cercle favori dans le carousel / carte : déjà en `surface` + `onSurface`.

---

## 3. full_map_screen.dart

| Emplacement | Widget | Style actuel | Mode sombre |
|------------|--------|--------------|-------------|
| AppBar | IconButtons (ma position, filtre, menu) | Thème AppBar | OK |
| Filtres par type (Positioned top) | Card avec chips | Card (thème) | OK |
| FAB couches / GPS (Positioned bottom-right) | FloatingActionButton mini | `colorScheme.surface`, `onSurface.withOpacity(0.8)` | OK |
| FAB Itinéraire | FloatingActionButton.extended | `primaryColor` | OK |
| Carte détail résidence (Positioned bottom) | `_buildResidenceDetailCard` | **Container `Colors.white`** | À corriger |

- **Correction à faire** : dans `_buildResidenceDetailCard`, remplacer le fond blanc du `Container` par `Theme.of(context).colorScheme.surface` (et bordures/ombres thème si besoin) pour que la carte détail en bas soit lisible en mode sombre.

---

## 4. promotion_detail_screen.dart

| Emplacement | Widget | Style actuel | Mode sombre |
|------------|--------|--------------|-------------|
| SliverAppBar leading | Cercle retour (sur image) | `Colors.black.withOpacity(0.4)`, icône blanche | Volontaire (sur image) |
| Header promotion (Stack) | Cercle retour (sur image) | `Colors.black.withOpacity(0.5)`, icône blanche | Volontaire (sur image) |

- Les deux boutons retour sont **sur image** (gradient + photo). Noir semi-transparent + blanc reste lisible sur la plupart des visuels. Pas de changement recommandé sauf refonte design.

---

## 5. main_screen.dart (accueil)

| Emplacement | Widget | Style actuel | Mode sombre |
|------------|--------|--------------|-------------|
| Header overlay (home) | `_buildHomeOverlayAppBar` | Cercle menu : `Colors.black.withOpacity(0.2)`, bordure `Colors.white.withOpacity(0.2)`, icône blanche | Choix design (overlay sur hero/liste) |

- Barre du haut en overlay sur l’écran d’accueil : texte et icônes **blancs** sur fond semi-transparent (cf. `MODE_SOMBRE_AUDIT_RESTANT.md` section 6). Conserver tel quel sauf décision de design contraire.

---

## 6. Widgets réutilisables

| Fichier | Widget | Style actuel | Mode sombre |
|---------|--------|--------------|-------------|
| residence_card.dart | Cercle favori sur carte résidence | `colorScheme.surface`, icône `primary` / `onSurface` | OK |
| home_search_bar.dart | Bouton close (cercle) | `colorScheme.surface`, icône `onSurface` | OK |
| search_filters_sheet (search_screen) | Chips / boutons | Thème + `surfaceContainerHigh`, `onSurface` | OK |
| message_bubble.dart (chat) | Bouton close overlay | `Colors.black54`, icône blanche | Volontaire (overlay) |

---

## 7. search_destination_screen.dart

| Emplacement | Widget | Style actuel | Mode sombre |
|------------|--------|--------------|-------------|
| Barre de recherche (leading/action) | Cercle close | **`AppTheme.dividerColor`** | À corriger |

- **Correction à faire** : remplacer `AppTheme.dividerColor` par une couleur de surface du thème (ex. `colorScheme.surfaceContainerHigh` ou `surface`) et garder l’icône en `onSurface` pour un bon contraste en mode sombre.

---

## Résumé des corrections à appliquer

1. **full_map_screen.dart** – `_buildResidenceDetailCard` : fond du `Container` → `Theme.of(context).colorScheme.surface` (et cohérence bordure/ombre si nécessaire).
2. **search_destination_screen.dart** – Cercle du bouton close dans la barre de recherche : fond → `Theme.of(context).colorScheme.surfaceContainerHigh` (ou `surface`) au lieu de `AppTheme.dividerColor`.

Tous les autres boutons overlay listés sont soit déjà adaptés au thème (surface/onSurface/primary), soit volontairement en blanc/noir pour un overlay sur image ou hero.
