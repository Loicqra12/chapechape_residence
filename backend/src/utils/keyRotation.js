/**
 * Utilitaire pour la gestion et la rotation des clés et secrets
 */
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const logger = require('./logger');

// Répertoire pour stocker les clés rotatives
const KEY_DIR = path.join(__dirname, '../../.keys');

// Durée de vie des clés en jours
const KEY_LIFE_TIME = {
  JWT_SECRET: 30,       // Clé JWT expirée après 30 jours
  JWT_REFRESH_SECRET: 90, // Clé de refresh token expirée après 90 jours
  CRYPTO_SECRET: 180     // Clé de cryptage des données sensibles expirée après 180 jours
};

/**
 * Initialiser le système de rotation de clés
 */
exports.init = () => {
  try {
    // Créer le répertoire des clés s'il n'existe pas
    if (!fs.existsSync(KEY_DIR)) {
      fs.mkdirSync(KEY_DIR, { recursive: true });
      logger.info('Répertoire de clés créé');
    }

    // Vérifier et générer les clés si nécessaire
    this.checkAndRotateKeys();
    
    // Planifier la vérification quotidienne des clés
    setInterval(() => {
      this.checkAndRotateKeys();
    }, 24 * 60 * 60 * 1000); // Vérification quotidienne
    
    logger.info('Système de rotation de clés initialisé');
  } catch (error) {
    logger.error('Erreur lors de l\'initialisation de la rotation des clés:', error);
  }
};

/**
 * Vérifier et effectuer la rotation des clés si nécessaire
 */
exports.checkAndRotateKeys = () => {
  try {
    // Vérifier chaque type de clé
    for (const [keyType, lifetime] of Object.entries(KEY_LIFE_TIME)) {
      const keyFile = path.join(KEY_DIR, `${keyType.toLowerCase()}.json`);
      
      // Si le fichier n'existe pas ou la clé est expirée, générer une nouvelle clé
      if (!fs.existsSync(keyFile) || isKeyExpired(keyFile, lifetime)) {
        generateNewKey(keyType, keyFile);
      }
    }
  } catch (error) {
    logger.error('Erreur lors de la vérification des clés:', error);
  }
};

/**
 * Vérifier si une clé est expirée
 * @param {string} keyFile - Chemin du fichier de clé
 * @param {number} lifetime - Durée de vie en jours
 * @returns {boolean} - True si la clé est expirée
 */
function isKeyExpired(keyFile, lifetime) {
  try {
    const keyData = JSON.parse(fs.readFileSync(keyFile, 'utf8'));
    const createdAt = new Date(keyData.createdAt);
    const expiresAt = new Date(createdAt.getTime() + lifetime * 24 * 60 * 60 * 1000);
    
    return new Date() > expiresAt;
  } catch (error) {
    logger.error(`Erreur lors de la vérification de l'expiration de la clé ${keyFile}:`, error);
    // En cas d'erreur, considérer la clé comme expirée pour en générer une nouvelle
    return true;
  }
}

/**
 * Générer une nouvelle clé et l'enregistrer
 * @param {string} keyType - Type de clé (JWT_SECRET, etc.)
 * @param {string} keyFile - Chemin du fichier de sortie
 */
function generateNewKey(keyType, keyFile) {
  try {
    // Générer une nouvelle clé cryptographiquement sécurisée
    const newKey = crypto.randomBytes(64).toString('hex');
    
    // Créer l'objet de la clé avec métadonnées
    const keyData = {
      key: newKey,
      createdAt: new Date().toISOString(),
      type: keyType
    };
    
    // Sauvegarder la clé précédente si elle existe (pour la transition)
    if (fs.existsSync(keyFile)) {
      const oldKeyData = JSON.parse(fs.readFileSync(keyFile, 'utf8'));
      const oldKeyFile = `${keyFile}.old`;
      fs.writeFileSync(oldKeyFile, JSON.stringify(oldKeyData, null, 2));
      logger.info(`Clé précédente ${keyType} sauvegardée`);
    }
    
    // Sauvegarder la nouvelle clé
    fs.writeFileSync(keyFile, JSON.stringify(keyData, null, 2));
    
    // Mettre à jour la variable d'environnement pour utilisation immédiate
    process.env[keyType] = newKey;
    
    logger.info(`Nouvelle clé ${keyType} générée et mise en place`);
  } catch (error) {
    logger.error(`Erreur lors de la génération de la clé ${keyType}:`, error);
  }
}

/**
 * Récupérer une clé active
 * @param {string} keyType - Type de clé à récupérer
 * @returns {string} - La clé active
 */
exports.getActiveKey = (keyType) => {
  try {
    const keyFile = path.join(KEY_DIR, `${keyType.toLowerCase()}.json`);
    
    // Vérifier si le fichier existe
    if (!fs.existsSync(keyFile)) {
      // Si la clé n'existe pas, utiliser la valeur de la variable d'environnement
      if (process.env[keyType]) {
        return process.env[keyType];
      }
      
      // Si aucune clé n'est disponible, en générer une nouvelle
      generateNewKey(keyType, keyFile);
    }
    
    // Lire la clé depuis le fichier
    const keyData = JSON.parse(fs.readFileSync(keyFile, 'utf8'));
    return keyData.key;
  } catch (error) {
    logger.error(`Erreur lors de la récupération de la clé ${keyType}:`, error);
    // En cas d'erreur, utiliser la valeur de la variable d'environnement
    return process.env[keyType] || '';
  }
};

/**
 * Récupérer la clé précédente (pour validation des tokens existants)
 * @param {string} keyType - Type de clé à récupérer
 * @returns {string|null} - La clé précédente ou null si non disponible
 */
exports.getPreviousKey = (keyType) => {
  try {
    const oldKeyFile = path.join(KEY_DIR, `${keyType.toLowerCase()}.json.old`);
    
    // Vérifier si le fichier de clé précédente existe
    if (!fs.existsSync(oldKeyFile)) {
      return null;
    }
    
    // Lire la clé précédente depuis le fichier
    const keyData = JSON.parse(fs.readFileSync(oldKeyFile, 'utf8'));
    return keyData.key;
  } catch (error) {
    logger.error(`Erreur lors de la récupération de la clé précédente ${keyType}:`, error);
    return null;
  }
}; 