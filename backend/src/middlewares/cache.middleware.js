const redisClient = require('../config/redis');
const logger = require('../utils/logger');

/**
 * Middleware de cache avancé utilisant Redis
 * @param {Object} options - Options de configuration du cache
 * @param {number} options.duration - Durée de mise en cache en secondes (défaut: 300 secondes)
 * @param {string} options.prefix - Préfixe de clé pour le cache (défaut: 'api:')
 * @param {Function} options.keyGenerator - Fonction personnalisée pour générer la clé de cache
 * @param {Function} options.condition - Fonction pour déterminer si la requête doit être mise en cache
 * @returns {Function} Express middleware
 */
const cacheMiddleware = (options = {}) => {
    // Options par défaut
    const {
        duration = 300,
        prefix = 'api:',
        keyGenerator,
        condition
    } = typeof options === 'number' ? { duration: options } : options;

    return async (req, res, next) => {
        // Vérifier si cette requête doit être mise en cache
        const shouldCache = condition 
            ? condition(req) 
            : req.method === 'GET';

        if (!shouldCache) {
            return next();
        }

        try {
            // Générer une clé de cache
            const cacheKey = keyGenerator 
                ? keyGenerator(req)
                : `${prefix}${req.originalUrl}`;

            // Tenter de récupérer depuis le cache
            const cachedData = await redisClient.get(cacheKey);
            
            if (cachedData) {
                const parsedData = JSON.parse(cachedData);
                logger.debug(`Cache hit: ${cacheKey}`);
                return res.json(parsedData);
            }
            
            logger.debug(`Cache miss: ${cacheKey}`);
            
            // Monitorer le statut de la réponse et mettre en cache les réponses réussies
            const originalJson = res.json;
            res.json = function(body) {
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    try {
                        redisClient.set(cacheKey, JSON.stringify(body), 'EX', duration);
                        logger.debug(`Cache set: ${cacheKey}, TTL: ${duration}s`);
                    } catch (error) {
                        logger.error(`Erreur lors de la mise en cache: ${error.message}`);
                    }
                }
                return originalJson.call(this, body);
            };
            
            next();
        } catch (error) {
            logger.error(`Erreur middleware cache: ${error.message}`);
            next(); // Continuer sans cache en cas d'erreur
        }
    };
};

module.exports = cacheMiddleware;
