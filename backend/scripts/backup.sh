#!/bin/bash

# Configuration
BACKUP_DIR="/backup/chapechape"
MONGODB_HOST="localhost"
MONGODB_PORT="27017"
MONGODB_DB="chapechape_residences"
MONGODB_USER="admin"
MONGODB_PASS="votre_mot_de_passe"
S3_BUCKET="chapechape-backups"
RETENTION_DAYS=30

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Date du jour
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_PATH="${BACKUP_DIR}/${DATE}"

# Fonction de logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Création des répertoires
mkdir -p "${BACKUP_PATH}"
mkdir -p "${BACKUP_PATH}/mongodb"
mkdir -p "${BACKUP_PATH}/uploads"
mkdir -p "${BACKUP_PATH}/logs"

# Backup MongoDB
log "Démarrage de la sauvegarde MongoDB..."
mongodump --host="${MONGODB_HOST}" \
          --port="${MONGODB_PORT}" \
          --db="${MONGODB_DB}" \
          --username="${MONGODB_USER}" \
          --password="${MONGODB_PASS}" \
          --out="${BACKUP_PATH}/mongodb" \
          --gzip

if [ $? -eq 0 ]; then
    log "Sauvegarde MongoDB terminée avec succès"
else
    error "Erreur lors de la sauvegarde MongoDB"
    exit 1
fi

# Backup des fichiers uploadés
log "Sauvegarde des fichiers uploadés..."
rsync -av --delete ../public/uploads/ "${BACKUP_PATH}/uploads/"

if [ $? -eq 0 ]; then
    log "Sauvegarde des fichiers terminée avec succès"
else
    error "Erreur lors de la sauvegarde des fichiers"
    exit 1
fi

# Backup des logs
log "Sauvegarde des logs..."
rsync -av --delete ../logs/ "${BACKUP_PATH}/logs/"

if [ $? -eq 0 ]; then
    log "Sauvegarde des logs terminée avec succès"
else
    error "Erreur lors de la sauvegarde des logs"
    exit 1
fi

# Compression de la sauvegarde
log "Compression de la sauvegarde..."
cd "${BACKUP_DIR}"
tar -czf "${DATE}.tar.gz" "${DATE}"

if [ $? -eq 0 ]; then
    log "Compression terminée avec succès"
else
    error "Erreur lors de la compression"
    exit 1
fi

# Upload vers S3 (si AWS CLI est configuré)
if command -v aws &> /dev/null; then
    log "Upload vers S3..."
    aws s3 cp "${DATE}.tar.gz" "s3://${S3_BUCKET}/backups/${DATE}.tar.gz"
    
    if [ $? -eq 0 ]; then
        log "Upload S3 terminé avec succès"
    else
        error "Erreur lors de l'upload S3"
    fi
fi

# Nettoyage des anciennes sauvegardes
log "Nettoyage des anciennes sauvegardes..."
find "${BACKUP_DIR}" -type f -name "*.tar.gz" -mtime +${RETENTION_DAYS} -delete
find "${BACKUP_DIR}" -type d -mtime +${RETENTION_DAYS} -exec rm -rf {} \;

# Nettoyage des anciennes sauvegardes sur S3
if command -v aws &> /dev/null; then
    log "Nettoyage des anciennes sauvegardes sur S3..."
    aws s3 ls "s3://${S3_BUCKET}/backups/" | while read -r line; do
        createDate=`echo $line | awk {'print $1" "$2'}`
        createDate=`date -d"$createDate" +%s`
        olderThan=`date -d"-${RETENTION_DAYS} days" +%s`
        if [[ $createDate -lt $olderThan ]]
        then
            fileName=`echo $line | awk {'print $4'}`
            if [[ $fileName != "" ]]
            then
                aws s3 rm "s3://${S3_BUCKET}/backups/$fileName"
            fi
        fi
    done
fi

# Vérification de l'espace disque
DISK_USAGE=$(df -h "${BACKUP_DIR}" | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "${DISK_USAGE}" -gt 80 ]; then
    error "Attention: L'espace disque est supérieur à 80% (${DISK_USAGE}%)"
fi

log "Sauvegarde terminée avec succès!"
log "Emplacement: ${BACKUP_PATH}"
log "Archive: ${DATE}.tar.gz"

# Envoi d'un rapport par email (à configurer)
# mail -s "Rapport de sauvegarde ChapeChape ${DATE}" admin@chapechape.com << EOF
# Sauvegarde terminée avec succès
# Date: ${DATE}
# Emplacement: ${BACKUP_PATH}
# Archive: ${DATE}.tar.gz
# Espace disque utilisé: ${DISK_USAGE}%
# EOF
