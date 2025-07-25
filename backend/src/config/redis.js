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

// Créer une instance unique du client Redis
const client = createRedisClient();

// Exporter la fonction createRedisClient comme export principal
const redisExport = createRedisClient;

// Ajouter le client comme propriété pour la rétro-compatibilité
Object.keys(client).forEach(key => {
    redisExport[key] = client[key];
});

// Ajouter les méthodes du client au module export
Object.getOwnPropertyNames(Object.getPrototypeOf(client)).forEach(key => {
    if (key !== 'constructor') {
        // Vérifier si la propriété est une fonction avant d'appliquer .bind()
        if (typeof client[key] === 'function') {
            redisExport[key] = client[key].bind(client);
        } else {
            // Pour les getter/setter ou autres propriétés, copier la référence
            redisExport[key] = client[key];
        }
    }
});

module.exports = redisExport;
