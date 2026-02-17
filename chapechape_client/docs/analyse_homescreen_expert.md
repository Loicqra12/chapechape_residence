# Analyse experte – HomeScreen (chapechape_client)

## Vue d’ensemble

Le HomeScreen est un `ListView` avec **12 blocs** (bannière, recherche, catégories x2, promo, offres spéciales, résidences spéciales, autour de moi, recommandées, CTA inscription, témoignages, blog, footer). Analyse stricte par section, backend, cohérence partner et benchmark Airbnb/Booking.

---

## 1. Bannière d’accueil (HomeBannerCarousel)

| Critère | Verdict |
|--------|--------|
| **Backend** | Non. Données en dur : 3 slides (assets hero_bg.png, premium1.png, promo1.png). |
| **Indispensable** | Oui. Point d’entrée visuel, standard type Airbnb/Booking. |
| **État** | Acceptable. Contenu statique et non personnalisable. |
| **À faire** | Optionnel : bannière pilotée par API (promos/campagnes) pour Côte d’Ivoire. |

---

## 2. Recherche (AdvancedSearchWidget)

| Critère | Verdict |
|--------|--------|
| **Backend** | Indirect. Ouvre la recherche ; la recherche utilise ResidenceService (API `/residences`, `/residences/search`). |
| **Indispensable** | Oui. Cœur métier : trouver une résidence (comme barre Airbnb/Booking). |
| **État** | À garder. Position et rôle cohérents. |
| **À faire** | Vérifier que le widget déclenche bien une navigation/search avec critères (ville, dates, prix) branchés sur l’API. |

---

## 3. Catégories – double section

Deux blocs catégories se suivent :

- **PopularCategoriesWidget** : "Catégories populaires", grille avec types (Résidences meublées, Hôtels, etc.), **données 100 % statiques** (images assets, comptes en dur "243", "78", etc.).
- **CategoriesMenuWidget** : "Explorez par catégories", filtre `ResidenceType.other`, **données statiques** (liste de types + couleurs).

| Critère | Verdict |
|--------|--------|
| **Backend** | Aucun. Aucun appel API ; comptes et libellés en dur. |
| **Indispensable** | Une seule section catégories suffit. La deuxième est redondante. |
| **Inutile / à retirer** | **CategoriesMenuWidget** (ou PopularCategoriesWidget) : doublon fonctionnel et visuel. |
| **À faire** | Garder **une** section catégories. Idéalement la brancher sur des **comptes réels** (API type `/residences/stats-by-category` ou dérivé des résidences chargées). Sinon garder une grille statique mais avec libellés/icônes adaptés au marché ivoirien (studios, villas, chambres, etc.). |

---

## 4. PromoBannerWidget

| Critère | Verdict |
|--------|--------|
| **Backend** | Non. Texte fixe "Offre de Bienvenue -15% sur votre 1ère résa", aucun lien API. |
| **Indispensable** | Non. Promo non vérifiable (pas de code, pas de règle métier). |
| **Inutile / à retirer** | Oui en l’état. Crée une fausse promesse si le -15% n’est pas géré côté backend. |
| **À faire** | Soit retirer. Soit remplacer par un bandeau piloté par l’API promotions (titre + lien vers une vraie promo), cohérent avec ExclusivePromotionsWidget. |

---

## 5. Offres & Promotions (ExclusivePromotionsWidget)

| Critère | Verdict |
|--------|--------|
| **Backend** | Oui. `PromotionService` → `/promotions/active`, cache 15 min, fallback mock si 404. |
| **Indispensable** | Oui. Promos réelles = conversion (Airbnb/Booking ont équivalent). |
| **État** | Bon. Branché API, navigation vers PromotionDetailScreen. |
| **À faire** | Garder. Vérifier que le backend expose bien `/promotions/active` et que le format correspond au client. |

---

## 6. Résidences spéciales (SpecialResidencesWidget)

| Critère | Verdict |
|--------|--------|
| **Backend** | Oui. `ResidenceBloc` → `ResidenceService.getAllResidences()` (API `/residences` ou `/residences/all`). Même liste que "Recommandées", filtrée côté widget par `ResidenceType.luxury`. |
| **Indispensable** | Oui. Mise en avant "luxe / spécial" = standard marché. |
| **État** | Bon. Données réelles, hauteur fixe 450 px (éviter débordement). |
| **À faire** | Garder. Optionnel : endpoint dédié "résidences vedettes" ou flag `is_featured` côté backend pour ne pas refiltrer toute la liste. Aligner les types avec le modèle partner (villa, apartment, etc.). |

---

## 7. Autour de moi (AroundMeWidget)

| Critère | Verdict |
|--------|--------|
| **Backend** | Oui. `LocationService` + `NearbyResidencesService` → API `/maps/nearby` (lat, lng, radius). |
| **Indispensable** | Très pertinent. Proximité = critère fort (Airbnb "À proximité", Booking carte). Contexte ivoirien : quartiers, sécurité, transport. |
| **État** | Bon. Carte + liste, rayon configurable. |
| **À faire** | Garder. Vérifier que le backend expose `/maps/nearby` et que les résidences ont bien lat/lng. En Côte d’Ivoire, prévoir messages clairs si géoloc refusée ou indisponible. |

---

## 8. Résidences recommandées (FeaturedListings)

| Critère | Verdict |
|--------|--------|
| **Backend** | Oui. Même `ResidenceBloc` que "Résidences spéciales" : même liste, pas de filtre type dans le code (affichage "recommandées" = liste globale). |
| **Indispensable** | Oui. Bloc principal "nos meilleures sélections" (équivalent "Recommandé pour vous" Airbnb). |
| **État** | Bon. "Voir tout" → `/search`. |
| **À faire** | Garder. Idéalement différencier les données (ex. scoring, popularité, ou endpoint "recommandations") pour ne pas dupliquer la même liste que "Résidences spéciales". |

---

## 9. CTA Inscription (_buildSignUpPrompt)

| Critère | Verdict |
|--------|--------|
| **Backend** | Non (affichage). `AuthBloc` : affiché seulement si non connecté. |
| **Indispensable** | Oui. Conversion inscrits / connexion, standard. |
| **État** | Bon. Condition Authenticated, boutons S’inscrire / Se connecter. |
| **À faire** | Garder tel quel. |

---

## 10. Témoignages (TestimonialsWidget)

| Critère | Verdict |
|--------|--------|
| **Backend** | Non. `TestimonialsData.testimonials` = données statiques (fichier local). |
| **Indispensable** | Utile pour la confiance, pas critique fonctionnellement. |
| **État** | Template. Contenu figé, pas de modération ni de mise à jour. |
| **À faire** | **Option 1** : Garder en statique mais remplacer par de vrais témoignages ivoiriens (texte + prénom/ville). **Option 2** : Retirer en attendant un backend "avis / témoignages" (ex. agrégation des avis résidences). **Option 3** : Remplacer par un bloc "Avis récents" branché sur les vrais avis des résidences si l’API existe. |

---

## 11. Blog & Conseils (BlogAndTipsWidget)

| Critère | Verdict |
|--------|--------|
| **Backend** | Non en pratique. `BlogService.getRecentBlogPosts()` : cache local + `_generateDummyBlogPosts()` (données fictives). Le backend a des routes `/api/blog` mais le client ne les appelle pas. |
| **Indispensable** | Non pour le cœur métier (réserver). SEO / contenu secondaire. |
| **État** | Trompeur : donne l’impression d’un blog alors que contenu dummy. |
| **À faire** | **Option 1** : Brancher sur l’API blog du backend (`GET /blog`, `GET /blog/featured`) et afficher de vrais articles (conseils voyage, quartiers Abidjan, etc.). **Option 2** : Retirer tant qu’il n’y a pas de contenu réel, pour éviter un bloc "faux" blog. Contexte ivoirien : articles sur quartiers, transports, sécurité, bonnes adresses = forte valeur. |

---

## 12. Footer (FooterWidget)

| Critère | Verdict |
|--------|--------|
| **Backend** | Non. Liens et textes statiques (À propos, Aide, Légal, contact). |
| **Indispensable** | Oui. Légal, confiance, aide (obligations et bonnes pratiques). |
| **État** | Correct. Accordéons, liens. |
| **À faire** | Garder. S’assurer que les liens (CGU, confidentialité, contact) pointent vers des pages ou URLs réelles. |

---

## Synthèse par critère

### Indispensable (à garder)

- Bannière (avec option future API).
- Recherche (AdvancedSearchWidget).
- Une seule section Catégories (à unifier, idéalement avec comptes réels).
- Offres & Promotions (ExclusivePromotionsWidget).
- Résidences spéciales (SpecialResidencesWidget).
- Autour de moi (AroundMeWidget).
- Résidences recommandées (FeaturedListings).
- CTA Inscription.
- Footer.

### Connecté au backend (vraies données)

- ExclusivePromotionsWidget → `/promotions/active`.
- SpecialResidencesWidget, FeaturedListings → ResidenceBloc → `/residences` ou `/residences/all`.
- AroundMeWidget → `/maps/nearby`.
- AdvancedSearchWidget → indirect via écran recherche.

### Non connecté / statique ou dummy

- HomeBannerCarousel : assets + texte en dur.
- PopularCategoriesWidget, CategoriesMenuWidget : listes et comptes en dur.
- PromoBannerWidget : texte en dur (-15%).
- TestimonialsWidget : `TestimonialsData` statique.
- BlogAndTipsWidget : `BlogService` avec dummy en mémoire/cache, pas d’appel API blog.
- FooterWidget : liens statiques.

### À retirer ou à remplacer

- **CategoriesMenuWidget** : doublon avec PopularCategoriesWidget ; retirer l’un des deux.
- **PromoBannerWidget** : retirer tant que -15% n’est pas géré par le backend, ou remplacer par un bandeau piloté par l’API promotions.
- **BlogAndTipsWidget** : retirer si on ne branche pas l’API blog ; sinon brancher `GET /blog` (ou équivalent) et afficher de vrais articles.
- **TestimonialsWidget** : optionnel à retirer ou à remplacer par "Avis récents" si API avis existe.

### Déjà bien en place

- Recherche, Promotions (API), Résidences spéciales / recommandées (API), Autour de moi (API), CTA inscription (AuthBloc), Footer.

---

## Comparaison Airbnb / Booking.com

- **Airbnb** : grande recherche (lieu, dates, voyageurs) ; catégories type "Maisons", "Appartements" ; "À proximité" / carte ; "Recommandé" ; promos ciblées ; pas de blog lourd sur la home ; footer légal et aide.
- **Booking** : barre recherche ; filtres rapides ; "Sélections" ; carte / proximité ; offres limitées dans le temps ; avis mis en avant.

À garder / renforcer côté ChapeChape : recherche centrale, une section catégories claire, proximité (Autour de moi), une liste "recommandées" ou "spéciales", promos réelles. À alléger : pas deux blocs catégories, pas de blog "faux", pas de bandeau promo non géré.

---

## Cohérence avec l’app Partner

- Partner : Dashboard (résidences, réservations, revenus), pas de "home" grand public.
- Client : Home = découverte et recherche pour le voyageur.

Les deux s’appuient sur les mêmes résidences (API résidences) et les mêmes promos (API promotions). À aligner : **types de résidences** (partner : type apartment, villa, etc. ; client : ResidenceType enum) pour que filtres et catégories correspondent aux données réelles. Vérifier que les libellés (Appartement, Villa, Studio…) sont cohérents entre partner et client.

---

## Contexte ivoirien – pistes

- **Villes / quartiers** : Abidjan (Cocody, Plateau, Yopougon, etc.), autres villes. Recherche et "Autour de moi" doivent supporter ville/quartier.
- **Paiement** : Wave, Orange Money, MTN (comme partner). Les promos et prix doivent refléter la devise (FCFA) et les moyens de paiement.
- **Contenu** : Témoignages et blog en français, exemples ivoiriens (noms, lieux) pour la confiance.
- **Sécurité / confiance** : Avis réels, vérification partenaires (si affichée), infos claires sur annulation et règles.

---

## Plan d’action recommandé (strict)

1. **Retirer** : CategoriesMenuWidget (ou PopularCategoriesWidget) pour supprimer la redondance catégories.
2. **Retirer ou remplacer** : PromoBannerWidget (retrait si pas de règle -15% ; sinon bandeau piloté API).
3. **Décider** : BlogAndTipsWidget → soit brancher `GET /blog` et afficher de vrais articles, soit retirer.
4. **Décider** : TestimonialsWidget → garder en statique avec contenu ivoirien réaliste, ou remplacer par avis réels si API disponible.
5. **Garder sans changer** : Bannière, Recherche, ExclusivePromotions, SpecialResidences, AroundMe, FeaturedListings, CTA Inscription, Footer.
6. **Optionnel** : Unifier catégories en une seule section et, si possible, brancher des comptes réels (API ou dérivé des résidences).
7. **Vérifier** : Backend `/residences`, `/residences/all`, `/promotions/active`, `/maps/nearby` disponibles et conformes aux appels client.
