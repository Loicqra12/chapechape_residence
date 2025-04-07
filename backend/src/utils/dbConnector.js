/**
 * Gestionnaire avancé de connexion MongoDB avec reconnexion automatique
 */
const mongoose = require('mongoose');
const logger = require('./logger');

// Configuration de la connexion
const options = {
  useNewUrlParser: true,
  useUnifiedTopology: true,
  serverSelectionTimeoutMS: 5000, // Timeout de sélection du serveur
  socketTimeoutMS: 45000,         // Timeout de socket
  family: 4,                      // IPv4
  maxPoolSize: 10,                // Taille maximale du pool de connexions
  minPoolSize: 2,                 // Taille minimale du pool
  heartbeatFrequencyMS: 10000,    // Fréquence des pulsations du serveur
  retryWrites: true,              // Retry des opérations d'écriture
  retryReads: true,               // Retry des opérations de lecture
  connectTimeoutMS: 10000,        // Timeout de connexion
};

// État de la connexion
let isConnected = false;
let retryCount = 0;
const MAX_RETRIES = 5;
let retryTimeout = null;

/**
 * Établit une connexion à MongoDB avec gestion des retries et monitoring
 */
const connect = async () => {
  const dbUri = process.env.MONGODB_URI;
  
  if (!dbUri) {
    logger.error('❌ URI MongoDB non définie !');
    process.exit(1);
  }

  if (isConnected) {
    logger.info('📊 Déjà connecté à MongoDB');
    return;
  }

  // Ajouter les moniteurs d'événements seulement si ce n'est pas déjà fait
  if (!hasEventListeners()) {
    setupEventListeners();
  }

  try {
    logger.info('🔄 Connexion à MongoDB...');
    await mongoose.connect(dbUri, options);
    
    isConnected = true;
    retryCount = 0;
    logger.info('✅ Connecté à MongoDB');
    
    // Afficher les statistiques de connexion
    showConnectionStats();
  } catch (error) {
    isConnected = false;
    logger.error(`❌ Erreur de connexion à MongoDB: ${error.message}`);
    
    // Retry logique avec backoff exponentiel
    if (retryCount < MAX_RETRIES) {
      const delay = Math.pow(2, retryCount) * 1000; // 1s, 2s, 4s, 8s, 16s
      retryCount++;
      
      logger.info(`🔄 Tentative de reconnexion (${retryCount}/${MAX_RETRIES}) dans ${delay/1000}s...`);
      
      clearTimeout(retryTimeout);
      retryTimeout = setTimeout(() => {
        connect();
      }, delay);
    } else {
      logger.error('❌ Nombre maximum de tentatives de connexion atteint !');
      // Ne pas arrêter le processus pour permettre le traitement des requêtes en cache
    }
  }
};

/**
 * Configuration des écouteurs d'événements pour la connexion MongoDB
 */
const setupEventListeners = () => {
  mongoose.connection.on('connected', () => {
    isConnected = true;
    logger.info('🔗 MongoDB connecté');
  });

  mongoose.connection.on('error', (err) => {
    isConnected = false;
    logger.error(`❌ Erreur MongoDB: ${err.message}`);
  });

  mongoose.connection.on('disconnected', () => {
    isConnected = false;
    logger.warn('⚠️ MongoDB déconnecté');
    
    // Tentative de reconnexion automatique
    if (retryCount < MAX_RETRIES) {
      connect();
    }
  });

  mongoose.connection.on('reconnected', () => {
    isConnected = true;
    logger.info('🔄 MongoDB reconnecté');
  });

  // Gestion de l'arrêt propre
  process.on('SIGINT', async () => {
    try {
      await mongoose.connection.close();
      logger.info('🛑 Connexion MongoDB fermée suite à l\'arrêt de l\'application');
      process.exit(0);
    } catch (error) {
      logger.error(`❌ Erreur lors de la fermeture de la connexion: ${error.message}`);
      process.exit(1);
    }
  });
};

/**
 * Vérifie si les écouteurs d'événements sont déjà configurés
 */
const hasEventListeners = () => {
  const listeners = mongoose.connection.eventNames();
  return listeners.includes('connected') && listeners.includes('error');
};

/**
 * Affiche les statistiques de connexion MongoDB
 */
const showConnectionStats = () => {
  const connection = mongoose.connection;
  
  if (connection.readyState === 1) { // 1 = Connecté
    logger.info(`📊 Statistiques de connexion:
    - Serveur: ${connection.host}:${connection.port}
    - Base de données: ${connection.name}
    - Statut: ${connection.readyState === 1 ? 'Connecté' : 'Déconnecté'}
    - Pool: ${mongoose.connections.length} connexions
    `);
  }
};

/**
 * Utilitaires pour vérifier l'état et la santé de la connexion
 */
const health = {
  isConnected: () => mongoose.connection.readyState === 1,
  status: () => {
    const states = ['Déconnecté', 'Connecté', 'Connexion en cours', 'Déconnexion en cours'];
    const state = mongoose.connection.readyState;
    return {
      status: states[state] || 'Inconnu',
      databases: mongoose.connection.db ? [mongoose.connection.db.databaseName] : [],
      host: mongoose.connection.host,
      port: mongoose.connection.port,
      isConnected: state === 1
    };
  }
};

/**
 * Crée une fonction de retry pour les opérations MongoDB
 * @param {Function} operation - Fonction d'opération MongoDB à retrier en cas d'échec
 * @param {number} maxAttempts - Nombre maximum de tentatives
 * @param {number} delay - Délai initial entre les tentatives en ms
 * @returns {Function} - Fonction avec retry
 */
const withRetry = (operation, maxAttempts = 3, delay = 300) => {
  return async (...args) => {
    let attempts = 0;
    let lastError;

    while (attempts < maxAttempts) {
      try {
        return await operation(...args);
      } catch (error) {
        lastError = error;
        attempts++;
        
        // Vérifier si l'erreur est récupérable
        if (isRecoverableError(error) && attempts < maxAttempts) {
          // Délai exponentiel avec jitter aléatoire pour éviter les tempêtes de connexion
          const backoff = Math.floor(delay * Math.pow(2, attempts - 1) * (1 + Math.random() * 0.1));
          logger.warn(`⚠️ MongoDB retry (${attempts}/${maxAttempts}) dans ${backoff}ms: ${error.message}`);
          
          await new Promise(resolve => setTimeout(resolve, backoff));
          continue;
        }
        
        // Erreur non récupérable ou nombre maximum de tentatives atteint
        throw error;
      }
    }
    
    throw lastError;
  };
};

/**
 * Vérifie si une erreur MongoDB est récupérable (peut être retryée)
 * @param {Error} error - L'erreur à vérifier
 * @returns {boolean} - True si l'erreur est récupérable
 */
const isRecoverableError = (error) => {
  // Liste des codes d'erreur MongoDB récupérables
  const recoverableCodes = [
    'HostUnreachable', 'HostNotFound', 
    'NetworkTimeout', 'SocketTimeout',
    'ConnectionTimeout', 'ConnectionError',
    'ExceededTimeLimit', 'WriteConcernError'
  ];
  
  // Vérifier si l'erreur est une erreur de connexion ou d'opération récupérable
  if (!error) return false;
  
  if (error.name === 'MongoNetworkError') return true;
  if (error.name === 'MongoTimeoutError') return true;
  
  if (error.code) {
    // Les codes 11600-11699 sont généralement liés au réseau
    if (error.code >= 11600 && error.code <= 11699) return true;
  }
  
  return recoverableCodes.some(code => 
    error.message && error.message.includes(code)
  );
};

module.exports = {
  connect,
  health,
  withRetry,
  isRecoverableError,
}; 