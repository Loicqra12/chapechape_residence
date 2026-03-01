# Analyse approfondie et stricte — Tendances (Abidjan commune + quartier)

## Contexte

- **À faire** : Remplacer la section "Résidences Spéciales" par **"6️⃣ Tendances dans votre ville"**.
- **Règle stricte** : À Abidjan on parle par **commune + quartier**, pas "Tendances à Abidjan" (trop large, imprécis, pas réaliste culturellement).

---

## 1. Définition stricte de "Tendances" pour ChapeChape

| Signal | Poids proposé | Rôle |
|--------|----------------|------|
| Réservations confirmées (7 j) | × 5 | Principal |
| Vues (7 j) | × 1 | Engagement |
| Favoris (7 j) | × 2 | Intention |
| Taux de conversion | × 3 | Qualité |
| Saison (week-end, vacances, fêtes) | Modulateur | Contexte CI |
| **Commune / Quartier** | Filtre obligatoire | Hyper-local |

**Score proposé :**
```text
trendScore =
  (reservations_7_days * 5)
  + (views_7_days * 1)
  + (favorites_7_days * 2)
  + (conversion_rate * 3)
```
Puis regroupement / tri par : **quartier** → **commune** → **catégorie** (6 catégories).

---

## 2. Niveaux d’affichage (hiérarchie stricte)

| Niveau | Condition | Exemple de titre |
|--------|-----------|-------------------|
| **1. Hyper-local (quartier)** | Assez de données quartier + position/commune connue | "Les plus réservées à Cocody cette semaine" |
| **2. Commune** | Peu de données quartier | "Les plus réservées à Marcory" |
| **3. Ville (fallback)** | Peu de données commune | "Les plus demandées à Abidjan" |

**À ne jamais faire** : Afficher "Tendances à Abidjan" quand on peut afficher Cocody, Marcory, Yopougon, etc.

---

## 3. Structure Abidjan (terrain)

- **Format** : Commune + Quartier (éventuellement sous-zone).
- **Exemples** : Cocody Angré, Cocody Riviera, Marcory Zone 4, Yopougon Niangon, Treichville Belleville.
- **Stockage recommandé** :
  - `commune` (ex. "Cocody", "Marcory", "Yopougon")
  - `quartier` (ex. "Angré", "Riviera", "Zone 4")
  - `sousZone` (optionnel)

---

## 4. État actuel du code (écart par rapport au cahier des charges)

### 4.1 Backend

| Élément | Existant | Manquant / à adapter |
|--------|----------|----------------------|
| **Residence** | `address`, `city`, `locationData` (address, city, country) | **commune**, **quartier**, (optionnel) **sousZone** |
| **Booking / Reservation** | `residence`, `checkIn`, `checkOut`, `status`, `createdAt` | Pas de champs dénormalisés **category**, **type**, **commune**, **quartier** (possible de dériver depuis residence peuplé) |
| **Stats** (stats.model.js) | `residence`, `date`, `views`, `bookings`, `favoriteCount`, `revenue`, `trends` (viewsGrowth, bookingsGrowth) | Agrégation par commune/quartier absente ; pas d’endpoint "tendances" avec score et filtre géo |
| **Favorite** | `user`, `residence` | Comptage par résidence sur 7 j pour le score (à faire côté service/aggregation) |
| **Réservations confirmées (7 j)** | Données dans Booking/Reservation | Agrégation par résidence (puis par commune/quartier) à mettre en place |

**Conclusion** : Le backend a une base (résidences, réservations, stats, favoris) mais **aucune notion commune/quartier** sur Residence et **aucun calcul de tendances** (score + filtre quartier/commune/ville).

### 4.2 Client (Flutter)

| Élément | Existant | Manquant / à adapter |
|--------|----------|----------------------|
| **Section actuelle** | `SpecialResidencesWidget` (filtre type "luxury", liste fixe) | Remplacer par widget **Tendances** basé sur API tendances |
| **Localisation utilisateur** | `AroundMeWidget` (géoloc, rayon) | Exposer ou réutiliser **commune/quartier** (ou ville) pour choisir le niveau et le libellé "Tendance à [Quartier/Commune]" |
| **Résidence** (model) | `location` (address, city, country, coordinates) | **commune**, **quartier** pour affichage et filtrage cohérents avec le backend |
| **API** | Aucun appel "tendances" | Nouvel appel type `GET /trends?commune=&quartier=&category=&limit=8` (ou équivalent) |

**Conclusion** : Côté client, il faut un **nouveau widget Tendances**, un **modèle/API tendances**, et une **logique de libellé** (quartier > commune > ville).

---

## 5. Recommandations techniques strictes

### 5.1 Backend

1. **Résidence**
   - Ajouter dans le schéma (ou dans `locationData`) : **commune**, **quartier**, **sousZone** (optionnel).
   - Validation : pour Abidjan, au moins commune renseignée.

2. **Réservations (Booking / Reservation)**
   - Option A (recommandée) : À la création, dénormaliser sur le document : **category**, **type**, **commune**, **quartier** (copiés depuis la résidence). Facilite les agrégations tendances sans peupler Residence à chaque fois.
   - Option B : Toujours dériver depuis Residence (populate) ; plus lourd en agrégations.

3. **Stats / analytique**
   - S’assurer que **views** et **favoriteCount** sont bien alimentés (incrément vues, comptage favoris sur 7 j).
   - Créer un **service ou endpoint dédié "tendances"** qui :
     - Agrège sur les 7 derniers jours : réservations confirmées, vues, favoris par résidence.
     - Dérive ou lit commune/quartier (depuis Residence ou depuis champs dénormalisés réservation).
     - Calcule un **trendScore** (formule ci-dessus) et un **taux de conversion** (réservations / vues ou équivalent).
     - Filtre par **commune**, **quartier** (et optionnellement **catégorie**, **saison**).
     - Retourne 5–8 résidences avec métadonnées : score, compteur "X réservations cette semaine".

4. **Saisonnalité CI**
   - Référentiel de périodes (fin d’année, Ramadan, Tabaski, rentrée, CAN, etc.) : soit en config (dates ou plages), soit en table. Le service tendances peut **moduler** le score ou **filtrer** par période pour libellés du type "Colocations les plus demandées (Rentrée)".

### 5.2 Client

1. **Widget "Tendances"**
   - Titre dynamique : **"Tendance à [Quartier]"** ou **"Tendance à [Commune]"** ou **"Les plus demandées à [Ville]"** (fallback), jamais "Tendances à Abidjan" si on peut être plus précis.
   - 5 à 8 résidences max.
   - Badge **"Populaire"**.
   - Compteur discret : **"X réservations cette semaine"** (donné par l’API).

2. **Source de la localisation**
   - Priorité : position ou dernière **commune/quartier** connus (géoloc ou sélection utilisateur).
   - Si rien : fallback ville (ex. Abidjan) pour le niveau 3.

3. **Gestion peu de données**
   - Si pas assez de réservations : s’appuyer sur **vues**, **favoris**, **taux de clic** (si disponible) pour le score.
   - Ne pas afficher une section vide : soit masquer la section, soit afficher un message du type "Pas encore de tendances pour ce quartier" avec CTA (explorer la commune/ville).

### 5.3 Erreurs à éviter (checklist)

- Ne pas afficher toujours la même liste (les tendances doivent dépendre du score et du filtre géo).
- Ne pas ignorer la commune (au minimum commune pour Abidjan).
- Ne pas mélanger longue durée et hôtel dans la même logique sans filtre catégorie.
- Rafraîchir les tendances (cache court, ex. 15–30 min, ou à chaque ouverture de l’accueil).
- Ne pas afficher des tendances "nationales" ou ville large quand l’utilisateur a une commune/quartier connue.

---

## 6. Structure cible de la section Tendances (résumé)

- **Titre** : "Tendance à [Quartier]" | "Tendance à [Commune]" | "Les plus demandées à [Ville]".
- **Contenu** : 5 à 8 résidences, badge "Populaire", compteur "X réservations cette semaine".
- **Données** : Réservations 7 j, vues 7 j, favoris 7 j, taux de conversion, commune/quartier, catégorie, saison.
- **Niveaux** : Quartier (prioritaire) → Commune → Ville (fallback).

---

## 7. Plan d’implémentation proposé (phases)

| Phase | Objectif | Backend | Client |
|-------|----------|---------|--------|
| **1** | Données géo (commune/quartier) | Ajouter commune, quartier (et optionnel sousZone) à Residence ; validation Abidjan | Étendre modèle Residence + affichage si besoin |
| **2** | Score et agrégations | Service/endpoint tendances : 7 j, score, filtre commune/quartier/ville, limit 8 | Appel API + modèle réponse |
| **3** | Section accueil | - | Remplacer SpecialResidencesWidget par widget Tendances (titre dynamique, 5–8 cartes, badge, compteur) |
| **4** | Catégorie + saisonnalité | Filtre par catégorie ; référentiel saison CI ; libellés contextuels | Titre optionnel "Tendance hôtels à Cocody" / "Colocations (Rentrée)" etc. |

Cette analyse peut servir de référence stricte pour l’implémentation et les revues de code.
