/**
 * Utilitaire de configuration du cache permettant une migration progressive
 * vers Redis tout en maintenant la compatibilité avec l'ancien système.
 */

const cacheMiddleware = require('../middlewares/cache.middleware');
const { redisCacheMiddleware } = require('../middlewares/redis-cache');
const logger = require('./logger');

/**
 * Configure le middleware de cache approprié selon la configuration
 * @param {Object} options Options de configuration
 * @param {string} options.prefix Préfixe pour Redis (ignoré pour node-cache)
 * @param {number} options.duration Durée du cache en secondes
 * @param {string} options.idParam Paramètre d'ID pour l'invalidation (ignoré pour node-cache)
 * @returns {Function} Middleware configuré
 */
const configureCache = (options = {}) => {
  const { 
    prefix = 'cache',
    duration = parseInt(process.env.CACHE_TTL || 300),
    idParam = null
  } = options;
  
  // Utiliser Redis ou node-cache selon la configuration
  const useRedisCache = process.env.USE_REDIS_CACHE === 'true';
  
  if (useRedisCache) {
    logger.debug(`Using Redis cache for route with prefix: ${prefix}`);
    return redisCacheMiddleware({ prefix, duration, idParam });
  } else {
    logger.debug(`Using node-cache for route with duration: ${duration}s`);
    return cacheMiddleware(duration);
  }
};

module.exports = {
  configureCache
};
