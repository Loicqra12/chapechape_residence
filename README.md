# ChapeChape Residences

Application de gestion de résidences développée avec Flutter et Node.js.

## Technologies Utilisées

### Frontend
- Flutter pour l'interface utilisateur
- Provider pour la gestion d'état
- Material Design pour l'UI/UX

### Backend
- Node.js avec Express.js
- MongoDB pour la base de données
- JWT pour l'authentification
- Multer pour la gestion des fichiers

## Fonctionnalités

### Pour les Administrateurs
- Gestion des résidences
- Gestion des clients
- Gestion des partenaires
- Tableau de bord administratif
- Gestion des permissions

### Pour les Partenaires
- Gestion des résidences
- Suivi des clients
- Système de commission
- Tableau de bord personnel

### Pour les Clients
- Recherche de résidences
- Favoris et historique
- Prise de rendez-vous
- Messagerie

## Configuration de l'Environnement

### Prérequis
- Flutter (dernière version stable)
- Node.js (v14 ou supérieur)
- MongoDB
- Git

### Structure du Projet
```
chapechape_residences/
├── backend/           # Backend Node.js
├── lib/              # Application Flutter
├── .env.example      # Variables d'environnement Flutter
└── backend/.env.example  # Variables d'environnement Backend
```

### Configuration des Variables d'Environnement

#### 1. Backend (.env)

Pour configurer le backend :

```bash
cd backend
cp .env.example .env
```

Variables importantes du backend :
- `PORT` : Port du serveur (défaut: 4000)
- `MONGODB_URI` : URI de connexion MongoDB
- `JWT_SECRET` : Clé secrète pour les tokens
- `SMTP_*` : Configuration email
- `STRIPE_*` : Configuration Stripe (paiements)
- `TWILIO_*` : Configuration Twilio (SMS)

#### 2. Frontend Flutter (.env)

Pour configurer le frontend :

```bash
cp .env.example .env
```

Variables importantes du frontend :
- `API_BASE_URL` : URL du backend
- `FIREBASE_*` : Configuration Firebase
- `GOOGLE_MAPS_API_KEY` : Clé API Google Maps
- `STRIPE_PUBLIC_KEY` : Clé publique Stripe

### Services Externes

#### Configuration Email (Gmail)
1. Activer "Accès moins sécurisé" dans les paramètres Google
2. Générer un mot de passe d'application
3. Utiliser ces identifiants dans SMTP_USER et SMTP_PASS

#### Firebase
1. Créer un projet dans Firebase Console
2. Télécharger google-services.json
3. Configurer les variables FIREBASE_* dans .env

#### Google Maps
1. Créer un projet dans Google Cloud Console
2. Activer Maps SDK pour Android/iOS
3. Générer une clé API
4. Ajouter la clé dans GOOGLE_MAPS_API_KEY

#### Stripe (Paiements)
1. Créer un compte Stripe
2. Récupérer les clés de test/production
3. Configurer STRIPE_* dans les deux .env

### Sécurité
- Ne jamais commiter les fichiers .env
- Utiliser des valeurs différentes en dev/prod
- Changer régulièrement les clés en production

### Démarrage du Projet

1. Backend :
```bash
cd backend
npm install
npm run dev
```

2. Flutter :
```bash
flutter pub get
flutter run
```

### Support

Pour toute question sur la configuration :
- Consulter la documentation technique
- Contacter l'équipe de développement

## Installation

### Backend (Node.js)
1. Aller dans le dossier backend
```bash
cd backend
```

2. Installer les dépendances
```bash
npm install
```

3. Configurer les variables d'environnement
```bash
cp .env.example .env
# Modifier les variables dans .env selon votre configuration
```

4. Démarrer le serveur
```bash
# Mode développement
npm run dev

# Mode production
npm start
```

### Frontend (Flutter)
1. Installer les dépendances
```bash
flutter pub get
```

2. Lancer l'application
```bash
flutter run
```

## Structure du Projet

```
.
├── backend/                 # Backend Node.js
│   ├── src/
│   │   ├── controllers/    # Contrôleurs
│   │   ├── models/        # Modèles Mongoose
│   │   ├── routes/        # Routes API
│   │   ├── middleware/    # Middleware
│   │   └── utils/         # Utilitaires
│   └── uploads/           # Fichiers uploadés
│
└── lib/                    # Frontend Flutter
    ├── features/
    │   ├── admin/         # Fonctionnalités admin
    │   ├── auth/          # Authentification
    │   ├── client/        # Interface client
    │   └── partner/       # Interface partenaire
    ├── core/              # Logique métier
    └── shared/            # Widgets partagés
```

## API Endpoints

### Auth
- POST /api/auth/register
- POST /api/auth/login
- GET /api/auth/me

### Residences
- GET /api/residences
- POST /api/residences
- GET /api/residences/:id
- PUT /api/residences/:id
- DELETE /api/residences/:id

### Partners
- GET /api/partners
- POST /api/partners
- GET /api/partners/:id
- PUT /api/partners/:id
- DELETE /api/partners/:id

### Clients
- GET /api/clients
- POST /api/clients
- GET /api/clients/:id
- PUT /api/clients/:id
- DELETE /api/clients/:id

## Contribution

1. Fork le projet
2. Créer une branche (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## License

Distribué sous la licence MIT. Voir `LICENSE` pour plus d'informations.
