# Document d’implémentation — Vente de terrains et biens immobiliers

## Contexte et objectif

Ce document décrit **tout ce qu’il faut mettre en place** pour intégrer la vente de terrains et de biens immobiliers (location/vente/location_vente) dans l’écosystème ChapeChape Résidence, **sans code**, uniquement en termes de fonctionnalités, d’architecture, de parcours et d’adaptations à l’existant.


---

# Partie 1 — Écosystème actuel (résumé)

## 1.1 Backend (Node.js / Express)

- **Framework** : Express, Mongoose.
- **Auth** : JWT via `auth.middleware` (`protect`, `authorize`), rôles : client, partner_pending, partner, admin, superadmin, owner.
- **Validation** : Joi dans `validations/` (ex. `residence.validation.js`), middleware `validate.middleware`.
- **Routes** : Montées sous `/api/` dans `app.js` (ex. `/api/residences`, `/api/favorites`, `/api/admin`, `/api/dashboard`).
- **Modèles** : `residence.model.js` (pas de `residence.service.js` dédié ; logique dans contrôleurs), `favorite.model.js` (user + residence), `partner.model.js` (discriminator User), `payment.model.js`, `reservation.model.js`.
- **Résidences** : `residence.routes.js` (GET/POST/PUT/DELETE, search, my-residences, favorites, images, FAQs, payment-methods, enhanced-amenities). Pas de notion de vente ni de terrains.
- **Favoris** : Un seul type (résidence). Pas de catégorie (location / achat / terrain).
- **Admin** : `admin.routes.js` (partenaires, résidences, validate/reject/verify, etc.). Pas de validation de documents légaux ni de stats ventes.


## 1.2 App Partenaire (Flutter)

- **Navigation** : `GoRouter` dans `app_router.dart`, `MainScreen` avec 5 onglets : Dashboard, Résidences, Réservations, Messages, Profil.
- **State** : Bloc (Auth, Dashboard, Residence, Reservation, Message, Notification, Favorite, etc.) ; services API (ResidenceService, ApiService, etc.) ; pas de repository Land ni PropertySale.
- **Modèle Residence** : `lib/core/models/residence/residence.dart` (name, price, type, category, locationData, reservationMode, etc.). Pas de `transactionType` ni `salePrice`.
- **Écrans** : `dashboard_screen`, `residences_screen`, `edit_residence_screen`, `residence_details_screen`, etc. Pas d’écran Terrains ni de sélecteur Location/Vente dans le formulaire résidence.
- **Config** : `AppConfig` / `AppConfigManager`, baseUrl API.

## 1.3 App Client (Flutter)

- **Navigation** : `GoRouter` avec `ShellRoute` (MainScreen) : home, nearby, favorites, etc. Pas de section « Acheter » ni « Terrains ».
- **State** : Bloc (Auth, Residence, Favorite, Booking, etc.) ; repositories (ResidenceRepository, FavoriteRepository) ; services (ResidenceService, FavoriteService, ApiService).
- **Modèle Residence** : `lib/core/models/residence_model.dart` (title, price, location, type, etc.). Pas de transactionType ni salePrice.
- **Écrans** : `home_screen`, `search_screen`, `residence_details_screen`, `favorites_screen`. Filtres recherche sans « Transaction » ni « Documents vérifiés ».
- **Favoris** : Une seule liste (résidences). Pas de catégories (location / achat / terrain).

---

# Partie 2 — Modifications et créations par couche

## 2.1 Backend

### 2.1.1 Modèles

**Residence (modification)**  
- Ajouter dans le schéma :
  - `transactionType` : enum `['location', 'vente', 'location_vente']`, défaut `'location'`.
  - `salePrice` : Number, optionnel, requis si transactionType contient vente.
  - `legalDocuments` : tableau d’objets `{ type, url, verifiedAt, verifiedBy }` avec type dans `['AAV', 'ACD', 'titre_foncier']`.
  - `documentVerificationStatus` : enum `['pending', 'verified', 'rejected']`, défaut `'pending'` si des documents sont présents.
  - `documentVerifiedType` : string (ex. "ACD", "Titre foncier") pour afficher le badge côté client.
  - `collaborators` : tableau de références ObjectId vers le modèle Collaborator.
- Conserver `price` pour la location et `pricePeriod` ; `salePrice` uniquement pour la vente.
- Adapter les index et les requêtes de recherche pour filtrer par `transactionType` et `documentVerificationStatus`.

**Land (nouveau modèle)**  
- Champs : `title`, `description`, `price`, `area` (m²), `landType` (enum : villageois, urbain_loti, agricole), `documentType` (enum : AAV, ACD, titre_foncier), `locationData` (même structure que residence : coordinates, address, city, country), `images`, `partner` (ref User), `status` (available, unavailable), `documentVerificationStatus`, `documentVerifiedType`, `legalDocuments` (même structure que residence), `collaborators` (ref Collaborator), `deleted`, `deletedAt`, `timestamps`.
- Index : partner, landType, city, documentVerificationStatus, locationData 2dsphere si besoin.

**Collaborator (nouveau modèle)**  
- Champs : `partner` (ref User), `name`, `photo` (URL), `phone`, `role` (ex. "visiteur terrain"), `timestamps`.
- Utilisé par Residence et Land pour les collaborateurs de visite (pas de compte dédié en MVP).

**Favorite (modification)**  
- Ajouter `category` : enum `['location', 'sale', 'land']`.
- Pour les favoris « sale », référencer soit une Residence (avec transactionType vente/location_vente), soit à définir (ex. champ optionnel `residence` ou `land`).
- Pour les favoris « land », ajouter une référence optionnelle `land` (ref Land).
- Adapter les méthodes statiques (getFavorites, toggleFavorite) pour accepter et filtrer par category.

**Commission (nouveau modèle, pour phase 2)**  
- Champs : type (location / vente), référence (reservation ou vente), taux, montant, partenaire, statut, etc. À détailler dans une phase dédiée.

### 2.1.2 Validations (Joi)

- **residence.validation.js**  
  - Dans createResidence et updateResidence : ajouter `transactionType`, `salePrice` (conditionnel), `legalDocuments`, `collaborators` (liste d’IDs).
- **land.validation.js (nouveau)**  
  - createLand, updateLand, searchLand : title, description, price, area, landType, documentType, location (coordinates, address, city), images, legalDocuments, collaborators.
- **favorite.validation.js (nouveau ou modification)**  
  - Pour addToFavorites : body avec `category` et soit `residenceId` soit `landId` selon la catégorie.

### 2.1.3 Contrôleurs et routes

**Résidences**  
- Modifier le contrôleur résidence existant pour :
  - Création / mise à jour : gérer `transactionType`, `salePrice`, `legalDocuments`, `collaborators`.
  - Recherche : ajouter paramètres de query `transactionType`, `documentVerified` (bool), `minSalePrice`, `maxSalePrice`.
- Pas de nouveau fichier de routes ; étendre `residence.routes.js`.

**Lands**  
- Nouveau fichier `controllers/land/land.controller.js` : create, update, delete, getById, getMyLands (partner), search (public avec filtres landType, city, price, area, documentVerified).
- Nouveau fichier `routes/land.routes.js` :  
  - GET `/` (search), GET `/:id` (public),  
  - sous `protect` : GET `/my-lands` (authorize partner), POST `/`, PUT `/:id`, DELETE `/:id`.
- Dans `app.js` : `app.use('/api/lands', landRoutes)`.

**Collaborators**  
- Nouveau contrôleur `collaborator.controller.js` : create, update, delete, list (pour un partner).
- Nouvelles routes (ex. sous `/api/collaborators` ou intégrées dans partner) : CRUD, réservées au partner propriétaire.

**Favoris**  
- Modifier le contrôleur favoris existant pour accepter `category` et soit `residenceId` soit `landId`.
- GET `/favorites` : paramètre query `category` (location | sale | land) pour filtrer.

**Admin**  
- Nouveaux endpoints (ou extension de `admin.routes.js`) :
  - GET `/admin/residences/pending-verification` : résidences avec documents en attente (transactionType vente ou location_vente).
  - PUT `/admin/residences/:id/verify-documents` : passer documentVerificationStatus à verified/rejected, renseigner documentVerifiedType.
  - GET `/admin/lands/pending-verification` : terrains en attente.
  - PUT `/admin/lands/:id/verify-documents` : idem.
  - GET `/admin/stats/sales` : statistiques ventes (nombre de biens à vendre, terrains, ratio location/vente, CA potentiel ventes). À brancher sur les mêmes patterns que le dashboard existant.

### 2.1.4 Middlewares et sécurité

- Réutiliser `protect` et `authorize('partner', 'admin')` pour les routes Land et Collaborator.
- Admin : `authorize('admin')` pour vérification des documents et stats.
- Pas de nouveau middleware spécifique ; respect des patterns existants (validate avec Joi, asyncHandler si utilisé).

### 2.1.5 Upload et stockage

- Documents légaux : même stratégie que les images (ex. Cloudinary ou upload existant) ; ne pas les exposer publiquement ; uniquement URL stockée et accès restreint (admin + partenaire propriétaire). Côté client, afficher uniquement le badge (documentVerifiedType).

---

## 2.2 App Partenaire (Flutter)

### 2.2.1 Modèles

- **Residence** (`lib/core/models/residence/residence.dart`) : ajouter `transactionType`, `salePrice`, `legalDocuments` (liste), `documentVerificationStatus`, `documentVerifiedType`, `collaboratorIds` ou liste de Collaborator. Adapter `fromJson` / `toJson`.
- **Land (nouveau)** : `lib/core/models/land/land.dart` avec champs alignés sur le backend (title, description, price, area, landType, documentType, locationData, images, documentVerificationStatus, documentVerifiedType, legalDocuments, collaborators).
- **Collaborator (nouveau)** : `lib/core/models/collaborator/collaborator.dart` (id, name, photo, phone, role).

### 2.2.2 Services API

- **ResidenceService** : étendre les méthodes create/update pour envoyer transactionType, salePrice, legalDocuments, collaborators. Appeler les nouvelles query params dans search si le backend expose une recherche « vente ».
- **LandService (nouveau)** : même pattern que ResidenceService (Dio + baseUrl + intercepteur token). Méthodes : getMyLands, getLand(id), createLand, updateLand, deleteLand, searchLands (optionnel côté app si toute la recherche passe par le backend).
- **CollaboratorService (nouveau)** : list, create, update, delete pour le partner connecté.

### 2.2.3 Blocs

- **ResidenceBloc** : étendre les événements/états pour gérer transactionType et salePrice dans les formulaires et la liste (mes résidences avec filtre vente/location si besoin).
- **LandBloc (nouveau)** : événements (LoadMyLands, CreateLand, UpdateLand, DeleteLand, Refresh) ; états (LandInitial, LandLoading, LandLoaded, LandError). Utiliser LandService.
- **FavoriteBloc** : inchangeable côté partenaire si les favoris sont uniquement côté client ; sinon prévoir category si le partenaire a des favoris.

### 2.2.4 Écrans et navigation

- **MainScreen** : ajouter un 6e onglet « Terrains » (ou regrouper « Résidences » et « Terrains » dans un même onglet avec sous-onglets, selon le choix UX). Si 6e onglet : ajouter `LandsListScreen` dans la liste des écrans et une entrée dans la bottom nav.
- **Dashboard** : dans le contenu ou les raccourcis, ajouter une carte/liens vers « Mes terrains » et éventuellement « Annonces en attente de validation » (résidences + terrains).
- **EditResidenceScreen** :  
  - Ajouter un sélecteur **Transaction** : Location / Vente / Location et vente.  
  - Si Vente ou Location et vente : afficher champ **Prix de vente** (salePrice), section **Documents légaux** (upload AAV/ACD/Titre foncier), et option **Collaborateurs de visite** (liste de Collaborator).  
  - Envoi des nouveaux champs au backend à la création/mise à jour.
- **ResidencesScreen** : option de filtre par transactionType (tout / location / vente / location_vente) pour afficher les annonces côté partenaire.
- **LandsListScreen (nouveau)** : liste des terrains du partner (appel LandService/LandBloc), avec statut (en attente / validé / rejeté). Bouton « Ajouter un terrain ».
- **AddLandScreen / EditLandScreen (nouveaux)** : formulaire (titre, description, prix, surface, type de terrain, type de document, localisation, photos, documents légaux, collaborateurs). Réutiliser le même pattern que EditResidenceScreen (AddressAutocomplete, carte, upload images/documents).
- **Router** : ajouter routes `/lands`, `/lands/add`, `/lands/:id/edit` (ou équivalent avec paramètre d’état). Déclarer les écrans Land dans `app_router.dart`.

### 2.2.5 Injection et configuration

- Enregistrer LandService, LandBloc, CollaboratorService (et éventuellement CollaboratorBloc) dans le conteneur d’injection (GetIt ou équivalent) et les fournir aux écrans concernés (Land list, Add/Edit Land, et formulaire résidence si besoin de sélection de collaborateurs).

---

## 2.3 App Client (Flutter)

### 2.3.1 Modèles

- **Residence** (`residence_model.dart`) : ajouter `transactionType`, `salePrice`, `documentVerificationStatus`, `documentVerifiedType`. Adapter fromJson/toJson et affichage (prix location vs prix vente).
- **Land (nouveau)** : même structure que côté partenaire, alignée backend.
- **Favorite** : si le modèle existe côté client, ajouter `category` (location | sale | land) et référence land (optionnel).

### 2.3.2 Services et repositories

- **ResidenceService / ResidenceRepository** : appels search avec paramètres transactionType, documentVerified, minSalePrice, maxSalePrice. Liste et détail doivent retourner les champs vente et vérification.
- **LandService (nouveau)** : getLands (liste/search), getLandById. Même pattern que ResidenceService (Dio, baseUrl, token).
- **LandRepository (nouveau)** : encapsule LandService, expose getLands, getLandById.
- **FavoriteService / FavoriteRepository** : étendre pour supporter category (location, sale, land) et landId. Appels API GET/POST favoris avec category et id correspondant.

### 2.3.3 Blocs

- **ResidenceBloc** : étendre SearchResidencesEvent (et paramètres) pour transactionType, documentVerified, prix vente. Les états ResidencesLoaded doivent inclure les champs vente et vérification pour l’affichage.
- **LandBloc (nouveau)** : LoadLands, LoadLandDetail, SearchLands (filtres). États : LandInitial, LandLoading, LandsLoaded, LandDetailLoaded, LandError.
- **FavoriteBloc** : étendre pour catégories (location, sale, land) : événements avec category, états avec listes ou structure par catégorie selon le design retenu.

### 2.3.4 Écrans et navigation

- **HomeScreen** :  
  - Ajouter une section **« Acheter »** (biens à vendre + terrains) : liens vers recherche « achat » et « terrains ».  
  - Conserver **« Louer »** (recherche location).  
  - Option : section **« Terrains »** dédiée.
- **SearchScreen** :  
  - Filtre **Transaction** : Louer / Acheter (et éventuellement « Les deux »).  
  - Si Acheter : filtres **Type de bien** (Studio, Appartement, Maison, Villa, etc.), **Prix de vente** (min/max), **Documents vérifiés uniquement** (oui/non), **Type de document vérifié** (ACD, Titre foncier, etc.).  
  - Pour les terrains : soit onglet/filtre « Terrains » dans la même recherche, soit écran de recherche dédié aux terrains (LandSearchScreen) avec filtres landType, prix, surface, documentVerified.
- **Résultats** : liste et carte (si existante) doivent afficher à la fois résidences (location/vente) et terrains selon les filtres. Différencier par type (résidence vs terrain) et afficher prix location ou prix vente + badge « Vérifié • ACD » (ou équivalent).
- **ResidenceDetailsScreen** :  
  - Si `transactionType` contient vente : afficher **Prix de vente**, **Badge de vérification** (texte type « Vérifié • ACD » / « Vérifié • Titre foncier »).  
  - Ne pas afficher les documents bruts ; option « Contacter pour plus d’infos » (messagerie).
- **LandDetailScreen (nouveau)** : même principe (description, prix, surface, type terrain, localisation, carte, photos, badge vérification, bouton Contacter / Demander visite).
- **Favoris** :  
  - **FavoritesScreen** : onglets ou sections « Location », « Achat », « Terrains » (selon category). Afficher résidences en vente et terrains avec les mêmes infos que dans les listes/détails.
- **Router** : ajouter routes pour liste terrains, détail terrain, et éventuellement « Acheter » (écran d’accueil achat). Ex. `/buy`, `/lands`, `/lands/:id`, `/search` avec query params pour transaction et type.

### 2.3.5 UX et contenu

- **Badge** : composant réutilisable « Vérifié • [documentVerifiedType] » (vert ou neutre), affiché sur les cartes et écrans de détail.
- **Prix** : sur les cartes/listes, afficher « X FCFA/mois » pour location et « Y FCFA » (vente) selon transactionType. Sur le détail, les deux si location_vente.
- **Contact et visite** : réutiliser la messagerie existante ; bouton « Demander une visite » qui ouvre une conversation ou un formulaire (date/heure) selon l’existant. Pas de prix de visite dans l’app (gratuit ou négocié avec le vendeur).

---

## 2.4 Dashboard Admin (Backend + éventuelle app/web)

- **Validation des documents** : écrans/listes pour résidences et terrains « en attente ». Actions : Valider (avec choix du type de document vérifié) / Rejeter. Appels PUT `/admin/residences/:id/verify-documents` et PUT `/admin/lands/:id/verify-documents`.
- **Statistiques ventes** : tableau de bord avec indicateurs (nombre de terrains, nombre de biens à vendre, ratio vente/location, CA potentiel ventes). Appel GET `/admin/stats/sales`.
- **Modération** : possibilité de rejeter ou masquer une annonce (résidence ou terrain) si déjà prévu dans l’admin actuel ; étendre aux nouveaux types si besoin.

---

# Partie 3 — Parcours utilisateur (résumé)

## 3.1 Partenaire

1. **Connexion** : inchangé.
2. **Résidence** : Création/édition → choix **Transaction** (Location / Vente / Les deux) → si vente : prix de vente, documents légaux, collaborateurs → soumission → statut « En attente » tant que l’admin n’a pas validé les documents.
3. **Terrain** : Onglet Terrains → Ajouter terrain → formulaire (type terrain, type document, surface, prix, localisation, photos, documents) → soumission → en attente de validation.
4. **Gestion** : Liste résidences (avec filtre transaction) ; liste terrains ; statuts (En attente / Validé / Rejeté) visibles. Modification/suppression possible selon les règles métier.
5. **Messages / Visites** : utilisation de la messagerie existante ; pas de compte dédié pour les collaborateurs (nom, photo, contact seulement).

## 3.2 Client

1. **Accueil** : voir sections Louer, Acheter, Terrains.
2. **Recherche** : choix Transaction (Louer / Acheter) + filtres (type, prix, surface, documents vérifiés, type de document) ; résultats résidences + terrains selon les filtres.
3. **Détail** : résidence ou terrain → prix (location et/ou vente), badge « Vérifié • ACD » (ou autre), carte, contact, demande de visite.
4. **Favoris** : onglets Location / Achat / Terrains ; ajout/suppression par catégorie.
5. **Contact** : messagerie existante ; pas de négociation de prix dans l’app (phase 1), seulement contact et proposition possible dans le chat.

## 3.3 Admin

1. **File de validation** : liste résidences et terrains avec documents en attente.
2. **Action** : Valider (et renseigner type de document) ou Rejeter.
3. **Stats** : consultation du tableau de bord ventes (terrains, biens à vendre, ratio, CA potentiel).

---

# Partie 4 — Règles métier et contraintes

- **Résidence** : si `transactionType` est `vente` ou `location_vente`, `salePrice` obligatoire et au moins un document légal attendu pour soumission. `documentVerificationStatus` reste `pending` jusqu’à action admin.
- **Terrain** : documents obligatoires selon le type (AAV/ACD/Titre foncier) ; même logique de vérification.
- **Affichage public** : seules les annonces avec `documentVerificationStatus === 'verified'` peuvent afficher le badge ; les annonces rejetées ne sont pas listées (ou sont masquées) côté client.
- **Favoris** : un même utilisateur peut avoir des favoris dans les trois catégories (location, sale, land) ; pas de doublon (même residenceId ou landId dans la même category).
- **Commissions** : hors scope de ce document ; prévoir un modèle et des calculs (location vs vente) dans une phase ultérieure.

---

# Partie 5 — Checklist d’implémentation (ordre suggéré)

1. Backend : schémas Residence (champs vente + documents), Land, Collaborator, Favorite (category + land).
2. Backend : validations Joi (residence, land, favorite).
3. Backend : contrôleurs et routes Land, extension résidences et favoris, admin (pending + verify-documents + stats/sales).
4. App Partenaire : modèles Residence (vente), Land, Collaborator ; services Land, Collaborator ; LandBloc.
5. App Partenaire : EditResidenceScreen (transaction, salePrice, documents, collaborateurs) ; LandsListScreen, AddLandScreen, EditLandScreen ; routes et onglet Terrains.
6. App Client : modèles Residence (vente), Land ; services/repos Land et Favorite (category) ; ResidenceBloc et LandBloc étendus, FavoriteBloc étendu.
7. App Client : HomeScreen (Acheter, Terrains), SearchScreen (filtres transaction + documents vérifiés), ResidenceDetailsScreen (vente + badge), LandDetailScreen, FavoritesScreen (onglets) ; routes.
8. Admin : écrans de validation et stats ventes (si interface dédiée).
9. Tests et recette (création résidence vente, terrain, validation admin, recherche client, favoris par catégorie).

---

Ce document sert de référence unique pour l’implémentation : chaque modification ou création (fichier, route, écran, champ) doit être alignée avec cette description pour rester cohérente avec l’écosystème existant.
