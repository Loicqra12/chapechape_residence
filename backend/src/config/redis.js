const Redis = require('ioredis');
const RedisMock = require('ioredis-mock');
const logger = require('../utils/logger');

// Créer une instance unique du client Redis
const createRedisClient = () => {
    // Utiliser redis-mock en test et développement
    const useRedisMock = process.env.NODE_ENV === 'test' || process.env.NODE_ENV === 'development' || !process.env.NODE_ENV;
    const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';
    
    let client;
    
    if (useRedisMock) {
        logger.info('Using Redis Mock');
        client = new RedisMock();
    } else {
        client = new Redis(redisUrl, {
            retryStrategy(times) {
                if (times > 5) {
                    return undefined;
                }
                return Math.min(times * 100, 3000);
            },
            maxRetriesPerRequest: 3
        });

        client.on('error', (err) => {
            logger.error('Redis connection error:', err);
        });

        client.on('ready', () => {
            logger.info('Redis client connected successfully');
        });
    }

    return client;
};

// Exporter une instance unique du client Redis
module.exports = createRedisClient();
