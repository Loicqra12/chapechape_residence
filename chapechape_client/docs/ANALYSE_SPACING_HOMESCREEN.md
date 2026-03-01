# Analyse stricte du spacing – HomeScreen

Valeurs de référence (**spacing.dart**) :
- `AppSpacing.lg` = **24 px**
- `AppSpacing.md` = **16 px**
- `AppSpacing.smd` = **12 px**

---

## 1. Fichier : `lib/core/theme/spacing.dart`

| Token   | Valeur | Usage typique |
|---------|--------|----------------|
| lg      | 24     | Entre blocs majeurs |
| md      | 16     | Padding vertical section, marges |
| smd     | 12     | Petit espace |

**Problème :** Aucun. Le fichier définit seulement les constantes. Les « gouffres » viennent de l’usage de **hauteurs fixes** et de **lg** entre trop de sections dans `home_screen.dart`.

---

## 2. Fichier : `lib/presentation/screens/home_screen.dart`

Structure actuelle du `ListView` (ordre des enfants) :

| # | Élément | Spacing / contrainte | Problème |
|---|---------|----------------------|----------|
| 1 | Hero (titre + sous-titre) | `Padding(24,28,24,20)` + `SizedBox(8)` entre les 2 textes | OK |
| 2 | — | **SizedBox(height: AppSpacing.lg)** = **24 px** | Espace hero → barre de recherche |
| 3 | HomeSearchBar | — | — |
| 4 | — | **SizedBox(height: AppSpacing.lg)** = **24 px** | — |
| 5 | QueCherchezVousWidget | — | — |
| 6 | — | **SizedBox(height: AppSpacing.lg)** = **24 px** | — |
| 7 | **À proximité** | **Padding(vertical: AppSpacing.md)** = **16 px haut + 16 px bas** | OK |
| 8 | — | **SizedBox(height: AppSpacing.lg)** = **24 px** | **Gap 1** : entre À proximité et la suite (promos ou Tendances) |
| 9 | Promotions (si présentes) | **Padding(bottom: AppSpacing.lg)** = **24 px** en bas | Quand visible, ajoute 24 px sous les promos |
| 10 | **Tendances (Les plus demandées)** | **SizedBox(height: 450)** conteneur fixe | **GOUFFRE PRINCIPAL** : la section a **450 px de hauteur fixe**. Contenu réel ≈ header (~36) + 4 + liste (~168) ≈ **208 px**. Donc **~242 px de vide** sous les cartes « Les plus demandées » avant « Résidences recommandées ». |
| 11 | — | **SizedBox(height: 12)** | OK (déjà réduit) |
| 12 | **Résidences recommandées** | **ConstrainedBox(maxHeight: 320)** | **Gouffre 2** : la section occupe **320 px**. Contenu réel ≈ header + sous-titre + liste ≈ **230 px**. Donc **~90 px de vide** sous les cartes. |
| 13 | — | **SizedBox(height: 12)** | OK |
| 14 | **Mieux notées** | **ConstrainedBox(maxHeight: 240)** | Column avec `Expanded` → occupe tout le 240 px. Contenu utile ≈ **212 px** → **~28 px de vide**. Risque d’overflow 1 px sur la carte (voir `home_compact_sections.dart`). |
| 15 | — | **SizedBox(height: 12)** | OK |
| 16 | **Récemment consultées** | **ConstrainedBox(maxHeight: 240)** | Même logique que Mieux notées, ~28 px de vide + overflow 1 px possible. |
| 17 | — | **SizedBox(height: 16)** | OK |
| 18 | CTA inscription | **margin: vertical AppSpacing.lg** = **24 px** haut et bas | OK |

**Résumé des problèmes dans ce fichier :**
1. **Ligne 240–248** : `SizedBox(height: 450)` autour de `TendancesWidget` → **~242 px de vide** sous « Les plus demandées ».
2. **Ligne 254** : `ConstrainedBox(maxHeight: 320)` pour `FeaturedListings` → **~90 px de vide** sous « Résidences recommandées ».
3. **Lignes 285–294** : `ConstrainedBox(maxHeight: 240)` pour Mieux notées / Récemment consultées → peu de vide mais **hauteur fixe** qui empêche un rendu « juste à la taille du contenu ».
4. **Lignes 181, 185, 189, 203** : quatre `SizedBox(height: AppSpacing.lg)` = 24 px entre les blocs du haut → cumul important si on veut un rendu plus compact.

---

## 3. Fichier : `lib/presentation/widgets/tendances_widget.dart`

- **Padding section** : `horizontal: 16, vertical: 8` (ligne 30).
- **Header** : ce padding + une ligne de titre → hauteur utile ~36 px.
- **Entre header et liste** : `SizedBox(height: 4)` (ligne 81).
- **Liste** : dans un `Expanded` → remplit tout l’espace donné par le **parent** (le `SizedBox(height: 450)` dans `home_screen.dart`). Donc la liste reçoit **450 − 36 − 4 ≈ 410 px** de hauteur alors qu’une seule ligne de cartes fait ~168 px.

**Problème :** Le widget est conçu pour un parent à hauteur fixe (450 px). Tant que le parent garde `height: 450`, tout l’espace sous la ligne de cartes reste vide. **La cause du gouffre est côté `home_screen.dart`** (hauteur 450), pas dans la logique interne de `TendancesWidget`.

---

## 4. Fichier : `lib/presentation/widgets/featured_listings.dart`

- **Header** : `widget.padding` = `(horizontal: 16, vertical: 8)` (ligne 42).
- **Entre header et sous-titre** : `SizedBox(height: 4)` (ligne 83).
- **Sous-titre** : `_buildSubtitle` (ligne 84).
- **Entre sous-titre et liste** : `SizedBox(height: 4)` (ligne 85).
- **Liste** : `SizedBox(height: 168)` (ligne 171) pour la zone scrollable.

Contenu utile ≈ 36 + 4 + ~18 + 4 + 168 ≈ **230 px**. Le parent dans `home_screen.dart` impose **maxHeight: 320**, donc **Column + Expanded** étire jusqu’à 320 px → **~90 px de vide** en bas. **Problème :** encore une fois la **contrainte maxHeight: 320** dans `home_screen.dart`, pas le widget lui‑même.

---

## 5. Fichier : `lib/presentation/widgets/home_compact_sections.dart`

### TopRatedSectionWidget / RecentlyViewedSectionWidget

- **Header** : `padding` = `(horizontal: 16, vertical: 8)` (ligne 24 / 138) → ~36 px.
- **Entre header et liste** : `SizedBox(height: 8)` (lignes 43, 182).
- **Liste** : `Expanded` → remplit la hauteur restante du `ConstrainedBox(maxHeight: 240)`.

Hauteur utile : 36 + 8 + hauteur d’une carte. Carte `_CompactResidenceCard` :
- Image : **120 px**
- `SizedBox(height: 6)` (ligne 321)
- Titre : fontSize 13 → ~**16 px** (ligne 323)
- `SizedBox(height: 2)` (ligne 332)
- Ligne lieu : icône 12 + texte 12 → ~**14 px** (lignes 334–345)

Total carte ≈ **120 + 6 + 16 + 2 + 14 = 158 px**. Liste reçue : **240 − 36 − 8 = 196 px**. Une seule ligne de cartes ≈ 158 px → pas d’overflow par la liste. Le message **« BOTTOM OVERFLOWED BY 1.00 PIXELS »** vient donc très probablement du **conteneur qui enveloppe la carte** (ex. hauteur fixe 157 ou 158 quelque part) ou d’un calcul de contrainte qui donne 1 px de moins que le besoin réel (police, ligne, padding).

**Problèmes dans ce fichier :**
1. **Lignes 321, 332** : les `SizedBox(height: 6)` et `SizedBox(height: 2)` sous l’image, plus les lignes de texte, peuvent dépasser d’1 px si le parent impose une hauteur stricte. À traiter en réduisant d’1 px un de ces espacements ou en évitant une hauteur fixe sur la carte.
2. Les sections sont dans un **ConstrainedBox(maxHeight: 240)** (défini dans `home_screen.dart`), donc le « vide » sous Mieux notées / Récemment consultées reste limité mais imposé par ce maxHeight.

---

## 6. Fichier : `lib/presentation/widgets/around_me_widget.dart`

- Le widget n’impose pas de hauteur fixe particulière pour la section.
- Dans `home_screen.dart`, il est wrappé dans **`Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.md))`** → **16 px** en haut et en bas.

**Problème :** Pas de gouffre créé par ce fichier. Le grand vide entre « À proximité » et « Les plus demandées » vient de :
1. **SizedBox(height: AppSpacing.lg)** = 24 px après À proximité (ligne 203 de `home_screen.dart`).
2. Éventuellement la section Promotions (avec son `bottom: 24`).
3. Surtout le **SizedBox(height: 450)** de Tendances qui réserve 450 px alors que le contenu n’en utilise qu’environ 208.

---

## Synthèse : cause des gouffres par section

| Section / espace | Fichier | Cause exacte |
|------------------|---------|--------------|
| Entre **À proximité** et **Les plus demandées** | home_screen.dart | `SizedBox(height: 24)` (l.203) + conteneur **Tendances** avec **height: 450** dont une grosse partie est vide. |
| **Gouffre sous « Les plus demandées »** | home_screen.dart | **SizedBox(height: 450)** (l.240) pour `TendancesWidget`. Contenu ≈ 208 px → **~242 px de blanc** en bas du bloc. |
| **Gouffre sous « Résidences recommandées »** | home_screen.dart | **ConstrainedBox(maxHeight: 320)** (l.254). Contenu ≈ 230 px → **~90 px de blanc** en bas. |
| Entre **Résidences recommandées**, **Mieux notées**, **Récemment consultées** | home_screen.dart | Déjà réduit à **SizedBox(12)**. Les blocs Mieux notées / Récemment consultées ont **maxHeight: 240** avec un peu de vide et risque d’overflow 1 px. |
| **BOTTOM OVERFLOWED 1 px** (Mieux notées / Récemment consultées) | home_compact_sections.dart | Carte `_CompactResidenceCard` : total contenu ~158 px ; si un parent impose 157 px ou que le calcul de ligne dépasse d’1 px → overflow. À corriger en réduisant d’1 px un `SizedBox` sous l’image ou en assouplissant la contrainte. |

---

## Corrections recommandées (ordre prioritaire)

1. **home_screen.dart**
   - Remplacer **SizedBox(height: 450)** par une hauteur adaptée au contenu (ex. **230** ou **240**) ou par un **ConstrainedBox(maxHeight: 240)** pour Tendances, pour supprimer le gouffre sous « Les plus demandées ».
   - Réduire **ConstrainedBox(maxHeight: 320)** de Résidences recommandées à **250** (ou 240) pour supprimer le vide sous « Résidences recommandées ».
   - Optionnel : remplacer les **SizedBox(height: AppSpacing.lg)** du haut (entre hero, search, que cherchez vous, around me) par **12** ou **16** pour un rendu plus compact.

2. **home_compact_sections.dart**
   - Corriger l’overflow 1 px : par exemple **SizedBox(height: 6)** → **5** ou **SizedBox(height: 2)** → **1** sous l’image / entre titre et lieu dans `_CompactResidenceCard`, ou s’assurer qu’aucun parent ne force une hauteur fixe trop juste.

Après ces changements, les espacements entre sections et les hauteurs de blocs seront alignés avec le contenu réel et les « gouffres » disparaîtront.
