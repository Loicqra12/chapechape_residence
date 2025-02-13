const redis = require('../config/redis');

const cache = (duration) => {
    return async (req, res, next) => {
        // Skip cache if it's a POST, PUT, DELETE request
        if (req.method !== 'GET') {
            return next();
        }

        const key = `__chapechape__${req.originalUrl || req.url}`;

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
            console.error('Cache middleware error:', error);
            next();
        }
    };
};

module.exports = cache;
