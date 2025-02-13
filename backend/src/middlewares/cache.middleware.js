const NodeCache = require('node-cache');
const cache = new NodeCache({ stdTTL: 300 }); // 5 minutes par défaut

const cacheMiddleware = (duration) => {
    return (req, res, next) => {
        // Skip cache for non-GET requests
        if (req.method !== 'GET') {
            return next();
        }

        const key = req.originalUrl;
        const cachedResponse = cache.get(key);

        if (cachedResponse) {
            return res.json(cachedResponse);
        }

        // Override res.json to cache the response
        const originalJson = res.json;
        res.json = function(body) {
            cache.set(key, body, duration || 300);
            originalJson.call(this, body);
        };

        next();
    };
};

module.exports = cacheMiddleware;
