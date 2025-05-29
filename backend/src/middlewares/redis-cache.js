const redis = require('../config/redis');
const logger = require('../utils/logger');

/**
 * Middleware de cache Redis avec invalidation granulaire
 * @param {Object} options Options du cache
 * @param {number} options.duration Durée du cache en secondes (défaut: process.env.CACHE_TTL || 300)
 * @param {string} options.prefix Préfixe pour les clés de cache (ex: 'residences', 'users')
 * @param {string} options.idParam Paramètre d'ID pour l'invalidation granulaire (ex: 'residenceId')
 */
const redisCacheMiddleware = (options = {}) => {
  const {
    duration = parseInt(process.env.CACHE_TTL || 300),
    prefix = 'cache',
    idParam = null
  } = options;

  return async (req, res, next) => {
    // Ignorer les requêtes non-GET
    if (req.method !== 'GET') {
      return next();
    }

    // Générer la clé de cache
    let key = `${prefix}:${req.originalUrl}`;
    
    try {
      // Tenter de récupérer depuis le cache
      const cachedData = await redis.get(key);
      
      if (cachedData) {
        logger.debug(`Cache hit for ${key}`);
        return res.json(JSON.parse(cachedData));
      }
      
      // Pas dans le cache, continuer avec la requête
      logger.debug(`Cache miss for ${key}`);
      
      // Stocker la méthode json originale
      const originalJson = res.json;
      
      // Remplacer res.json pour mettre en cache
      res.json = function(body) {
        if (res.statusCode === 200) {
          // Stocker dans Redis
          redis.setex(key, duration, JSON.stringify(body))
            .catch(err => logger.error(`Redis cache error: ${err.message}`));
          
          // Si idParam est spécifié, ajouter cette clé à un ensemble pour l'invalidation
          if (idParam && req.params[idParam]) {
            const resourceId = req.params[idParam];
            const indexKey = `${prefix}:ids:${resourceId}`;
            redis.sadd(indexKey, key)
              .catch(err => logger.error(`Redis index error: ${err.message}`));
          }
        }
        
        // Appeler la méthode originale
        return originalJson.call(this, body);
      };
      
      next();
    } catch (error) {
      logger.error(`Cache middleware error: ${error.message}`);
      next();
    }
  };
};

/**
 * Fonction d'invalidation du cache pour un type spécifique
 * @param {string} prefix Préfixe de cache (ex: 'residences')
 */
const invalidateByPrefix = async (prefix) => {
  try {
    const pattern = `${prefix}:*`;
    const keys = await redis.keys(pattern);
    
    if (keys.length > 0) {
      await redis.del(keys);
      logger.info(`Invalidated ${keys.length} cache entries with prefix ${prefix}`);
    }
    
    return keys.length;
  } catch (error) {
    logger.error(`Cache invalidation error: ${error.message}`);
    throw error;
  }
};

/**
 * Fonction d'invalidation du cache pour une ressource spécifique par ID
 * @param {string} prefix Préfixe de cache (ex: 'residences')
 * @param {string} id ID de la ressource
 */
const invalidateById = async (prefix, id) => {
  try {
    const indexKey = `${prefix}:ids:${id}`;
    const keys = await redis.smembers(indexKey);
    
    if (keys.length > 0) {
      await redis.del(keys);
      await redis.del(indexKey);
      logger.info(`Invalidated ${keys.length} cache entries for ${prefix} with ID ${id}`);
    }
    
    return keys.length;
  } catch (error) {
    logger.error(`Cache invalidation error: ${error.message}`);
    throw error;
  }
};

module.exports = {
  redisCacheMiddleware,
  invalidateByPrefix,
  invalidateById
};
