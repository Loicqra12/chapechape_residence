const Redis = require('ioredis');
const RedisMock = require('ioredis-mock');
const logger = require('../utils/logger');

let clientInstance;

// Créer (une seule fois) un client Redis partagé
const createRedisClient = () => {
    if (clientInstance) {
        return clientInstance;
    }

    // Utiliser redis-mock en test et développement
    const useRedisMock = process.env.NODE_ENV === 'test' || process.env.NODE_ENV === 'development' || !process.env.NODE_ENV;
    const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';
    
    let client;
    
    if (useRedisMock) {
        logger.info('Using Redis Mock');
        client = new RedisMock();
        client.isMock = true;
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

    clientInstance = client;
    return clientInstance;
};

const client = createRedisClient();

// Export principal rétro-compatible:
// - appelable comme fonction => retourne le singleton
// - utilisable comme client Redis direct => redis.get(), redis.set(), etc.
const redisExport = () => createRedisClient();

Object.getOwnPropertyNames(Object.getPrototypeOf(client)).forEach(key => {
    if (key !== 'constructor') {
        if (typeof client[key] === 'function') {
            redisExport[key] = (...args) => createRedisClient()[key](...args);
        } else {
            Object.defineProperty(redisExport, key, {
                get: () => createRedisClient()[key],
                enumerable: true,
                configurable: true
            });
        }
    }
});

// Exposer explicitement le singleton pour les nouveaux appels
redisExport.client = client;
redisExport.getClient = createRedisClient;

module.exports = redisExport;
