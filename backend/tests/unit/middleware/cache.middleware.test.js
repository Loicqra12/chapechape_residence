/**
 * Tests unitaires pour le middleware de cache Redis
 * Compatible avec l'implémentation moderne utilisant des promesses
 */

// Import du middleware à tester
const cacheMiddleware = require('../../../src/middlewares/cache.middleware');

// Mock des dépendances
jest.mock('../../../src/config/redis', () => ({
  get: jest.fn(),
  set: jest.fn()
}));

jest.mock('../../../src/utils/logger', () => ({
  debug: jest.fn(),
  error: jest.fn(),
  info: jest.fn()
}));

// Import des mocks
const redisClient = require('../../../src/config/redis');
const logger = require('../../../src/utils/logger');

describe('Cache Middleware (Promesses)', () => {
  let req;
  let res;
  let next;

  beforeEach(() => {
    // Réinitialiser les mocks
    jest.clearAllMocks();
    
    // Setup des objets req, res et next
    req = {
      method: 'GET',
      originalUrl: '/api/test'
    };
    
    res = {
      json: jest.fn(),
      statusCode: 200
    };
    
    next = jest.fn();
  });

  test('devrait ignorer le cache pour les requêtes non-GET', async () => {
    req.method = 'POST';
    
    await cacheMiddleware()(req, res, next);
    
    expect(next).toHaveBeenCalled();
    expect(redisClient.get).not.toHaveBeenCalled();
  });

  test('devrait renvoyer les données du cache si disponibles', async () => {
    const cachedData = { data: 'from-cache' };
    redisClient.get.mockResolvedValue(JSON.stringify(cachedData));
    
    await cacheMiddleware()(req, res, next);
    
    expect(redisClient.get).toHaveBeenCalledWith('api:/api/test');
    expect(res.json).toHaveBeenCalledWith(cachedData);
    expect(next).not.toHaveBeenCalled();
    expect(logger.debug).toHaveBeenCalledWith(expect.stringContaining('Cache hit'));
  });

  test('devrait mettre en cache les nouvelles données de réponse', async () => {
    const responseData = { data: 'new-response' };
    redisClient.get.mockResolvedValue(null);
    
    await cacheMiddleware()(req, res, next);
    
    // Simuler une réponse de l'API
    res.json(responseData);
    
    expect(redisClient.set).toHaveBeenCalledWith(
      'api:/api/test',
      expect.any(String),
      'EX',
      300
    );
    expect(logger.debug).toHaveBeenCalledWith(expect.stringContaining('Cache set'));
  });

  test('devrait utiliser les options de durée personnalisées', async () => {
    const customDuration = 600; // 10 minutes
    redisClient.get.mockResolvedValue(null);
    
    await cacheMiddleware({ duration: customDuration })(req, res, next);
    
    res.json({ test: 'data' });
    
    expect(redisClient.set).toHaveBeenCalledWith(
      'api:/api/test',
      expect.any(String),
      'EX',
      customDuration
    );
  });

  test('devrait utiliser un préfixe personnalisé', async () => {
    const customPrefix = 'custom:';
    redisClient.get.mockResolvedValue(null);
    
    await cacheMiddleware({ prefix: customPrefix })(req, res, next);
    
    expect(redisClient.get).toHaveBeenCalledWith(`${customPrefix}/api/test`);
  });

  test('devrait gérer les erreurs Redis gracieusement', async () => {
    redisClient.get.mockRejectedValue(new Error('Redis error'));
    
    await cacheMiddleware()(req, res, next);
    
    expect(logger.error).toHaveBeenCalledWith(expect.stringContaining('Erreur middleware cache'));
    expect(next).toHaveBeenCalled();
  });

  test('devrait utiliser un générateur de clé personnalisé', async () => {
    const keyGenerator = req => `custom-key:${req.originalUrl}`;
    redisClient.get.mockResolvedValue(null);
    
    await cacheMiddleware({ keyGenerator })(req, res, next);
    
    expect(redisClient.get).toHaveBeenCalledWith('custom-key:/api/test');
  });

  test('devrait utiliser une condition personnalisée', async () => {
    // Condition: mettre en cache uniquement les URLs contenant "cacheable"
    const condition = req => req.originalUrl.includes('cacheable');
    
    // Cas 1: URL qui devrait être mise en cache
    req.originalUrl = '/api/cacheable-endpoint';
    await cacheMiddleware({ condition })(req, res, next);
    expect(redisClient.get).toHaveBeenCalled();
    
    // Réinitialiser les mocks
    jest.clearAllMocks();
    
    // Cas 2: URL qui ne devrait pas être mise en cache
    req.originalUrl = '/api/non-cacheable';
    await cacheMiddleware({ condition })(req, res, next);
    expect(redisClient.get).not.toHaveBeenCalled();
    expect(next).toHaveBeenCalled();
  });


});
