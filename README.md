# 🏠 ChapeChape Residence - Écosystème Complet

## 📱 Applications

### ChapeChape Client (Flutter)
Application mobile pour les clients cherchant des résidences.
- Recherche et filtrage de résidences
- Réservations en ligne
- Paiements sécurisés
- Gestion du profil utilisateur

### ChapeChape Partner (Flutter)
Application mobile pour les propriétaires/partenaires.
- Gestion des résidences
- Suivi des réservations
- Analytics et rapports
- Communication avec les clients

### Dashboard Web (React)
Interface d'administration web.
- Gestion globale du système
- Monitoring et métriques
- Support client
- Configuration système

### Site de Présentation (React)
Site vitrine de ChapeChape.
- Présentation des services
- Landing pages marketing
- SEO optimisé
- Conversion leads

## 🚀 Démarrage Rapide

### Prérequis
- Docker & Docker Compose
- Node.js 18+ (pour développement local)
- Flutter 3.24+ (pour apps mobiles)

### Installation Développement
```bash
# Cloner le repository
git clone <repository-url>
cd chapechape_residence

# Setup environnement de développement
chmod +x scripts/setup-dev.sh
./scripts/setup-dev.sh
```

### Services Disponibles
- **Backend API**: http://localhost:5000
- **Dashboard**: http://localhost:3001  
- **Site Présentation**: http://localhost:3002
- **MongoDB Express**: http://localhost:8081
- **Redis Commander**: http://localhost:8082

## 🏗️ Architecture

### Backend (Node.js)
```
backend/
├── src/
│   ├── controllers/     # Contrôleurs API
│   ├── models/         # Modèles MongoDB
│   ├── routes/         # Routes Express
│   ├── middleware/     # Middleware custom
│   └── services/       # Logique métier
├── tests/              # Tests automatisés
└── docs/              # Documentation API
```

### Frontend Apps
```
chapechape_dashboard/    # React Dashboard
chapechape_sitepresentation/  # React Site
chapechape_client/      # Flutter Client
chapechape_partner/     # Flutter Partner
```

## 🔧 Commandes Utiles

### Docker
```bash
# Développement
docker-compose -f docker-compose.dev.yml up -d
docker-compose -f docker-compose.dev.yml logs -f

# Production
docker-compose up -d
docker-compose logs -f
```

### Flutter
```bash
# Build APK
./scripts/build-flutter.sh client apk

# Build AAB pour Play Store
./scripts/build-flutter.sh partner aab

# Build toutes les apps
./scripts/build-flutter.sh all both
```

### Déploiement
```bash
# Déploiement complet
./scripts/deploy.sh production all

# Déploiement service spécifique
./scripts/deploy.sh production backend
```

## 🧪 Tests

### Backend
```bash
cd backend
npm test                # Tests unitaires
npm run test:integration # Tests d'intégration
npm run test:load       # Tests de charge
```

### Frontend
```bash
cd chapechape_dashboard
npm test -- --coverage

cd chapechape_sitepresentation  
npm test -- --coverage
```

### Flutter
```bash
cd chapechape_client
flutter test

cd chapechape_partner
flutter test
```

## 📊 CI/CD

### GitHub Actions
Pipeline automatique sur push/PR:
- Tests automatisés
- Build Docker images
- Déploiement automatique
- Tests de charge

### Monitoring
- **Logs**: Centralisés via Docker
- **Métriques**: Prometheus + Grafana
- **APM**: New Relic (configuré)
- **Alertes**: Slack/Email

## 🔐 Sécurité

### Authentification
- JWT tokens
- Refresh tokens
- OAuth (Google, Facebook)
- 2FA (optionnel)

### API Security
- Rate limiting
- CORS configuré
- Headers sécurisés
- Validation des entrées

### Infrastructure
- SSL/TLS obligatoire
- Firewall configuré
- Secrets management
- Backup automatique

## 📈 Performance

### Optimisations
- Cache Redis
- CDN pour assets
- Compression Gzip
- Lazy loading

### Scalabilité
- Load balancing Nginx
- Horizontal scaling
- Database indexing
- Connection pooling

## 🗂️ Base de Données

### MongoDB Collections
- `users` - Utilisateurs
- `residences` - Résidences
- `bookings` - Réservations
- `payments` - Paiements
- `reviews` - Avis clients

### Redis Cache
- Sessions utilisateurs
- Cache API responses
- Rate limiting data
- Temporary data

## 🌍 Environnements

### Développement
- Docker Compose local
- Hot reload activé
- Debug tools
- Test data

### Staging
- Environnement de test
- Données anonymisées
- Tests automatisés
- Review apps

### Production
- Haute disponibilité
- Monitoring complet
- Backup automatique
- SSL/CDN

## 📚 Documentation

### API
- Swagger/OpenAPI
- Postman collections
- Exemples d'usage
- Codes d'erreur

### Développement
- Setup guides
- Architecture docs
- Best practices
- Troubleshooting

## 🤝 Contribution

### Workflow
1. Fork le repository
2. Créer une branche feature
3. Commits avec messages clairs
4. Tests passants
5. Pull Request avec description

### Standards
- ESLint/Prettier pour JS
- Dart analyzer pour Flutter
- Conventional commits
- Code review obligatoire

## 📞 Support

### Contacts
- **Tech Lead**: [email]
- **DevOps**: [email]
- **Product**: [email]

### Resources
- Documentation: `/docs`
- Issues: GitHub Issues
- Slack: #chapechape-dev
- Wiki: GitHub Wiki

---

## 🚀 Roadmap

### Q1 2024
- [x] Architecture microservices
- [x] CI/CD Pipeline
- [x] Docker containerisation
- [ ] Kubernetes migration

### Q2 2024
- [ ] Mobile app v2.0
- [ ] API Gateway
- [ ] Advanced analytics
- [ ] Multi-tenant support

### Q3 2024
- [ ] AI recommendations
- [ ] Real-time chat
- [ ] Payment gateway v2
- [ ] International expansion

---

**ChapeChape** - Révolutionner l'hébergement résidentiel 🏡
