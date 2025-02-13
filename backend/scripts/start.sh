#!/bin/bash

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Fonction pour afficher les messages
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "package.json" ]; then
    error "Le script doit être exécuté depuis la racine du projet"
    exit 1
fi

# Vérifier Node.js
if ! command -v node &> /dev/null; then
    error "Node.js n'est pas installé"
    exit 1
fi

# Vérifier que les variables d'environnement sont configurées
if [ ! -f ".env" ]; then
    error "Fichier .env manquant"
    exit 1
fi

# Vérifier MongoDB
log "Vérification de la connexion MongoDB..."
if ! mongo --eval "db.serverStatus()" &> /dev/null; then
    warn "MongoDB n'est pas en cours d'exécution"
    log "Démarrage de MongoDB..."
    sudo systemctl start mongod
    sleep 5
fi

# Vérifier Redis
log "Vérification de la connexion Redis..."
if ! redis-cli ping &> /dev/null; then
    warn "Redis n'est pas en cours d'exécution"
    log "Démarrage de Redis..."
    sudo systemctl start redis
    sleep 2
fi

# Créer les répertoires nécessaires
log "Création des répertoires..."
mkdir -p logs/pm2
mkdir -p public/uploads
mkdir -p tmp

# Vérifier et installer les dépendances
log "Installation des dépendances..."
npm install --production

# Vérifier les vulnérabilités
log "Vérification des vulnérabilités..."
npm audit

# Nettoyer le cache
log "Nettoyage du cache..."
npm cache clean --force

# Vérifier PM2
if ! command -v pm2 &> /dev/null; then
    log "Installation de PM2..."
    npm install -g pm2
fi

# Arrêter les instances précédentes
log "Arrêt des instances précédentes..."
pm2 delete all &> /dev/null

# Démarrer l'application avec PM2
log "Démarrage de l'application..."
pm2 start ecosystem.config.js --env production

# Sauvegarder la configuration PM2
log "Sauvegarde de la configuration PM2..."
pm2 save

# Configurer le démarrage automatique
log "Configuration du démarrage automatique..."
pm2 startup

# Vérifier le statut
log "Vérification du statut de l'application..."
pm2 list

# Afficher les logs
log "Affichage des logs..."
pm2 logs --lines 20

log "Application démarrée avec succès!"
log "Pour voir les logs en temps réel: pm2 logs"
log "Pour le monitoring: pm2 monit"
