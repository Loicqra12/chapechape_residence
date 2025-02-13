# Guide de Déploiement - ChapeChape Residences Backend

## Prérequis

- Node.js v14+ et npm
- MongoDB v4.4+
- Redis v6+
- Un serveur Linux (Ubuntu 20.04 LTS recommandé)
- PM2 pour la gestion des processus
- Nginx comme reverse proxy
- Certificat SSL (Let's Encrypt recommandé)

## 1. Configuration de l'Environnement

### Variables d'Environnement

Créez un fichier `.env` à la racine du projet avec les variables suivantes :

```env
# Environnement
NODE_ENV=production
PORT=5000

# Base de données
MONGODB_URI=mongodb://username:password@host:port/database
MONGODB_URI_TEST=mongodb://username:password@host:port/database_test

# JWT
JWT_SECRET=votre_secret_jwt_tres_long_et_complexe
JWT_EXPIRE=24h
JWT_COOKIE_EXPIRE=24

# Email
SMTP_HOST=smtp.votreservice.com
SMTP_PORT=587
SMTP_USER=votre_email
SMTP_PASSWORD=votre_mot_de_passe
FROM_EMAIL=noreply@chapechape.com
FROM_NAME=ChapeChape Residences

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=votre_mot_de_passe_redis

# Sécurité
RATE_LIMIT_WINDOW=15
RATE_LIMIT_MAX=100

# URLs
FRONTEND_URL=https://votredomaine.com
API_URL=https://api.votredomaine.com
```

### Installation des Dépendances Système

```bash
# Mise à jour du système
sudo apt update && sudo apt upgrade -y

# Installation de Node.js
curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt install -y nodejs

# Installation de MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
sudo apt update
sudo apt install -y mongodb-org

# Installation de Redis
sudo apt install redis-server
```

## 2. Installation de l'Application

```bash
# Cloner le repository
git clone https://github.com/votre-repo/chapechape-residences-backend.git
cd chapechape-residences-backend

# Installer les dépendances
npm install --production

# Installation de PM2 globalement
sudo npm install -g pm2
```

## 3. Configuration de Nginx

```nginx
server {
    listen 80;
    server_name api.votredomaine.com;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

## 4. Configuration SSL avec Let's Encrypt

```bash
# Installation de Certbot
sudo apt install certbot python3-certbot-nginx

# Obtention du certificat
sudo certbot --nginx -d api.votredomaine.com
```

## 5. Démarrage de l'Application

```bash
# Configuration de PM2
pm2 ecosystem

# Démarrage de l'application
pm2 start ecosystem.config.js

# Sauvegarde de la configuration PM2
pm2 save

# Configuration du démarrage automatique
pm2 startup
```

## 6. Monitoring et Maintenance

### Logs

Les logs sont stockés dans le dossier `logs/` :
- `error-%DATE%.log` : Erreurs
- `combined-%DATE%.log` : Tous les logs

### Commandes Utiles

```bash
# Voir les logs
pm2 logs

# Monitoring
pm2 monit

# Redémarrage de l'application
pm2 restart all

# Mise à jour de l'application
git pull
npm install --production
pm2 reload all
```

### Sauvegarde

Configurez des sauvegardes automatiques de MongoDB :

```bash
# Créer un script de backup
mkdir -p /backup/mongodb
chmod 700 /backup/mongodb

# Ajouter une tâche cron
0 0 * * * mongodump --out /backup/mongodb/$(date +\%Y-\%m-\%d)
```

## 7. Sécurité

### Pare-feu

```bash
# Configuration de UFW
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw enable
```

### MongoDB

```bash
# Créer un utilisateur admin MongoDB
mongo
use admin
db.createUser({
  user: "admin",
  pwd: "votre_mot_de_passe_complexe",
  roles: [ { role: "userAdminAnyDatabase", db: "admin" } ]
})
```

### Redis

```bash
# Configurer un mot de passe Redis
sudo nano /etc/redis/redis.conf
# Décommenter et modifier : requirepass votre_mot_de_passe_redis
```

## 8. Tests avant Mise en Production

```bash
# Vérifier la configuration
npm run lint

# Exécuter les tests
npm test

# Vérifier les vulnérabilités
npm audit

# Test de charge (avec Artillery)
npm run test:load
```

## 9. Mise à l'Échelle

Pour une mise à l'échelle horizontale :

1. Configurer un load balancer (nginx ou HAProxy)
2. Utiliser PM2 cluster mode
3. Configurer MongoDB en replica set
4. Mettre en place Redis Sentinel pour la haute disponibilité

## Support

Pour toute question ou problème :
- Email : support@chapechape.com
- Documentation API : https://api.votredomaine.com/docs
