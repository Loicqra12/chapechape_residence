const { redisCacheMiddleware, invalidateByPrefix, invalidateById } = require('../../../src/middlewares/redis-cache');
const redis = require('../../../src/config/redis');
const logger = require('../../../src/utils/logger');

// Mock des dépendances
jest.mock('../../../src/config/redis');
jest.mock('../../../src/utils/logger', () => ({
  debug: jest.fn(),
  error: jest.fn(),
  info: jest.fn()
}));

describe('Redis Cache Middleware', () => {
  let req;
  let res;
  let next;
  
  beforeEach(() => {
    // Réinitialiser les mocks
    jest.clearAllMocks();
    
    // Configuration des objets de test
    req = {
      method: 'GET',
      originalUrl: '/api/residences/123',
      params: {
        residenceId: '123'
      }
    };
    
    res = {
      json: jest.fn(),
      statusCode: 200
    };
    
    next = jest.fn();
  });
  
  describe('redisCacheMiddleware', () => {
    test('devrait ignorer le cache pour les requêtes non-GET', async () => {
      req.method = 'POST';
      
      const middleware = redisCacheMiddleware();
      await middleware(req, res, next);
      
      expect(redis.get).not.toHaveBeenCalled();
      expect(next).toHaveBeenCalled();
    });
    
    test('devrait retourner les données du cache si disponibles', async () => {
      const cachedData = { success: true, data: { title: 'Résidence de test' } };
      redis.get.mockResolvedValue(JSON.stringify(cachedData));
      
      const middleware = redisCacheMiddleware();
      await middleware(req, res, next);
      
      expect(redis.get).toHaveBeenCalledWith('cache:/api/residences/123');
      expect(res.json).toHaveBeenCalledWith(cachedData);
      expect(next).not.toHaveBeenCalled();
    });
    
    test('devrait mettre en cache les données lors d\'une réponse 200', async () => {
      redis.get.mockResolvedValue(null);
      redis.setex.mockResolvedValue('OK');
      
      const middleware = redisCacheMiddleware({ duration: 60 });
      await middleware(req, res, next);
      
      // Simuler la réponse
      const responseData = { success: true, data: { title: 'Résidence de test' } };
      res.json(responseData);
      
      expect(redis.setex).toHaveBeenCalledWith(
        'cache:/api/residences/123',
        60,
        JSON.stringify(responseData)
      );
      expect(next).toHaveBeenCalled();
    });

    test('devrait indexer les clés par ID pour l\'invalidation', async () => {
      redis.get.mockResolvedValue(null);
      redis.setex.mockResolvedValue('OK');
      redis.sadd.mockResolvedValue(1);
      
      const middleware = redisCacheMiddleware({
        prefix: 'residences',
        idParam: 'residenceId'
      });
      
      await middleware(req, res, next);
      
      // Simuler la réponse
      const responseData = { success: true, data: { title: 'Résidence de test' } };
      res.json(responseData);
      
      expect(redis.sadd).toHaveBeenCalledWith(
        'residences:ids:123',
        'residences:/api/residences/123'
      );
      expect(next).toHaveBeenCalled();
    });
    
    test('devrait gérer les erreurs Redis', async () => {
      redis.get.mockRejectedValue(new Error('Redis connection error'));
      
      const middleware = redisCacheMiddleware();
      await middleware(req, res, next);
      
      expect(logger.error).toHaveBeenCalled();
      expect(next).toHaveBeenCalled();
    });
  });
  
  describe('invalidateByPrefix', () => {
    test('devrait invalider toutes les clés avec un préfixe donné', async () => {
      const keys = ['residences:1', 'residences:2', 'residences:3'];
      redis.keys.mockResolvedValue(keys);
      redis.del.mockResolvedValue(3);
      
      const count = await invalidateByPrefix('residences');
      
      expect(redis.keys).toHaveBeenCalledWith('residences:*');
      expect(redis.del).toHaveBeenCalledWith(keys);
      expect(count).toBe(3);
      expect(logger.info).toHaveBeenCalled();
    });
    
    test('ne devrait rien faire si aucune clé n\'est trouvée', async () => {
      redis.keys.mockResolvedValue([]);
      
      const count = await invalidateByPrefix('residences');
      
      expect(redis.del).not.toHaveBeenCalled();
      expect(count).toBe(0);
    });
    
    test('devrait gérer les erreurs Redis', async () => {
      redis.keys.mockRejectedValue(new Error('Redis connection error'));
      
      await expect(invalidateByPrefix('residences')).rejects.toThrow('Redis connection error');
      expect(logger.error).toHaveBeenCalled();
    });
  });
  
  describe('invalidateById', () => {
    test('devrait invalider les clés associées à un ID spécifique', async () => {
      const keys = ['residences:/api/residences/123', 'residences:/api/residences/123/reviews'];
      redis.smembers.mockResolvedValue(keys);
      redis.del.mockResolvedValue(2);
      
      const count = await invalidateById('residences', '123');
      
      expect(redis.smembers).toHaveBeenCalledWith('residences:ids:123');
      expect(redis.del).toHaveBeenCalledWith(keys);
      expect(redis.del).toHaveBeenCalledWith('residences:ids:123');
      expect(count).toBe(2);
      expect(logger.info).toHaveBeenCalled();
    });
    
    test('ne devrait rien faire si aucune clé n\'est trouvée', async () => {
      redis.smembers.mockResolvedValue([]);
      
      const count = await invalidateById('residences', '123');
      
      expect(redis.del).not.toHaveBeenCalled();
      expect(count).toBe(0);
    });
    
    test('devrait gérer les erreurs Redis', async () => {
      redis.smembers.mockRejectedValue(new Error('Redis connection error'));
      
      await expect(invalidateById('residences', '123')).rejects.toThrow('Redis connection error');
      expect(logger.error).toHaveBeenCalled();
    });
  });
});
