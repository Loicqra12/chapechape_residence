const redis = require('../config/redis');
const logger = require('../utils/logger');

const cacheMiddleware = (duration) => {
    return async (req, res, next) => {
        // Skip cache if it's a POST, PUT, DELETE request
        if (req.method !== 'GET') {
            return next();
        }

        const key = `cache:${req.originalUrl || req.url}`;

        try {
            const cachedResponse = await redis.get(key);

            if (cachedResponse) {
                return res.json(JSON.parse(cachedResponse));
            }

            // Modify res.json to store the response in cache
            const originalJson = res.json;
            res.json = function(body) {
                redis.setex(key, duration, JSON.stringify(body));
                return originalJson.call(this, body);
            };

            next();
        } catch (error) {
            logger.error('Cache middleware error:', error);
            next();
        }
    };
};

// Fonction pour invalider le cache (utilisée dans les tests)
const invalidateCache = async (pattern) => {
    try {
        if (!pattern) {
            throw new Error('Pattern is required for cache invalidation');
        }
        
        // Utiliser redis.keys pour trouver toutes les clés correspondant au pattern
        const keys = await redis.keys(`cache:${pattern}`);
        
        if (keys.length > 0) {
            // Utiliser redis.del pour supprimer les clés
            await redis.del(keys);
            logger.info(`Cache invalidated for pattern: ${pattern}, ${keys.length} keys removed`);
        } else {
            logger.info(`No cache keys found for pattern: ${pattern}`);
        }
        
        return true;
    } catch (error) {
        logger.error('Cache invalidation error:', error);
        return false;
    }
};

module.exports = {
    cacheMiddleware,
    invalidateCache
};
