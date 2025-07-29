#!/bin/bash

# ==============================================
# SCRIPT DE DÉPLOIEMENT CHAPECHAPE BACKEND
# ==============================================

set -e

echo "🚀 Démarrage du déploiement ChapeChape Backend..."

# Variables
APP_NAME="chapechape-residences-api"
APP_DIR="/var/www/chapechape-backend"
NGINX_CONFIG="/etc/nginx/sites-available/chapechape-api"
DOMAIN="api.chapechaperesidence.com"

# 1. Arrêter l'application existante
echo "🛑 Arrêt de l'application existante..."
pm2 stop $APP_NAME || true
pm2 delete $APP_NAME || true

# 2. Mise à jour du code
echo "📥 Mise à jour du code..."
cd $APP_DIR
git pull origin main || git pull origin master

# 3. Installation des dépendances
echo "📦 Installation des dépendances..."
npm install --production

# 4. Vérification des variables d'environnement
echo "🔧 Vérification de la configuration..."
if [ ! -f .env ]; then
    echo "❌ Fichier .env manquant!"
    echo "📝 Copiez .env.example vers .env et configurez vos variables"
    exit 1
fi

# 5. Test de connexion MongoDB
echo "🗄️ Test de connexion MongoDB..."
node -e "
const mongoose = require('mongoose');
require('dotenv').config();
mongoose.connect(process.env.MONGODB_URI)
  .then(() => { console.log('✅ MongoDB OK'); process.exit(0); })
  .catch((err) => { console.log('❌ MongoDB Error:', err.message); process.exit(1); });
"

# 6. Démarrage avec PM2
echo "🚀 Démarrage de l'application..."
pm2 start ecosystem.config.js --env production
pm2 save

# 7. Mise à jour configuration Nginx
echo "🌐 Mise à jour configuration Nginx..."
if [ -f "nginx.conf" ]; then
    echo "📄 Copie de nginx.conf vers /etc/nginx/nginx.conf"
    sudo cp nginx.conf /etc/nginx/nginx.conf
    echo "✅ Configuration nginx mise à jour"
else
    echo "⚠️ Fichier nginx.conf local non trouvé, utilisation de la config existante"
fi

# 8. Vérification Nginx
echo "🔍 Test de la configuration Nginx..."
sudo nginx -t
if [ $? -eq 0 ]; then
    echo "✅ Configuration nginx valide"
    sudo systemctl reload nginx
    echo "🔄 Nginx rechargé avec succès"
else
    echo "❌ Erreur dans la configuration nginx"
    exit 1
fi

# 8. Vérifications finales
echo "🔍 Vérifications finales..."
sleep 5

# Vérifier que l'app tourne
if pm2 list | grep -q $APP_NAME; then
    echo "✅ Application PM2 démarrée"
else
    echo "❌ Erreur PM2"
    pm2 logs $APP_NAME --lines 10
    exit 1
fi

# Vérifier le port
if netstat -tlnp | grep -q :5000; then
    echo "✅ Port 5000 ouvert"
else
    echo "❌ Port 5000 non disponible"
    exit 1
fi

# Test de l'API
echo "🧪 Test de l'API..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN/api/health || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ API accessible (HTTP $HTTP_CODE)"
elif [ "$HTTP_CODE" = "000" ]; then
    echo "⚠️ API non accessible (connexion échouée)"
else
    echo "⚠️ API répond avec HTTP $HTTP_CODE"
fi

echo ""
echo "🎉 Déploiement terminé!"
echo "🔗 API: https://$DOMAIN/api"
echo "📊 Monitoring: pm2 monit"
echo "📋 Logs: pm2 logs $APP_NAME"
echo ""
