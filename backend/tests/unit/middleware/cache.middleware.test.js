/**
 * Middleware réellement monté dans app.js : cache.middleware.js
 * Redis : getClient() mock (get/set EX) — pas de localhost:6379.
 * Fail-open lecture : erreur Redis → next(), pas 500.
 */
jest.mock('../../../src/config/redis', () => {
  const store = new Map();
  const client = {
    get: jest.fn(async (key) => (store.has(key) ? store.get(key) : null)),
    set: jest.fn(async (key, value) => {
      store.set(key, value);
      return 'OK';
    }),
  };
  return {
    getClient: jest.fn(() => client),
    __store: store,
    __client: client,
  };
});

jest.mock('../../../src/utils/logger', () => ({
  debug: jest.fn(),
  error: jest.fn(),
  info: jest.fn(),
  warn: jest.fn(),
}));

const redisModule = require('../../../src/config/redis');
const cacheMiddleware = require('../../../src/middlewares/cache.middleware');
const logger = require('../../../src/utils/logger');

describe('cache.middleware.js (app.js)', () => {
  let req;
  let res;
  let next;

  beforeEach(() => {
    jest.clearAllMocks();
    redisModule.__store.clear();
    redisModule.getClient.mockImplementation(() => redisModule.__client);
    redisModule.__client.get.mockImplementation(async (key) => (
      redisModule.__store.has(key) ? redisModule.__store.get(key) : null
    ));
    redisModule.__client.set.mockImplementation(async (key, value) => {
      redisModule.__store.set(key, value);
      return 'OK';
    });
    req = { method: 'GET', originalUrl: '/api/residences', headers: {} };
    res = { json: jest.fn(), statusCode: 200 };
    next = jest.fn();
  });

  it('skip POST (pas de get Redis)', async () => {
    req.method = 'POST';
    await cacheMiddleware()(req, res, next);
    expect(next).toHaveBeenCalled();
    expect(redisModule.__client.get).not.toHaveBeenCalled();
  });

  it('cache miss puis set EX', async () => {
    await cacheMiddleware({ duration: 120 })(req, res, next);
    expect(next).toHaveBeenCalled();
    res.json({ ok: true });
    expect(redisModule.__client.set).toHaveBeenCalledWith(
      'api:anon:/api/residences',
      JSON.stringify({ ok: true }),
      'EX',
      120
    );
  });

  it('cache hit', async () => {
    redisModule.__store.set('api:anon:/api/residences', JSON.stringify({ cached: 1 }));
    await cacheMiddleware()(req, res, next);
    expect(res.json).toHaveBeenCalledWith({ cached: 1 });
    expect(next).not.toHaveBeenCalled();
  });

  it('fail-open : Redis get throw → next(), pas de 500', async () => {
    redisModule.__client.get.mockRejectedValue(new Error('ECONNREFUSED'));
    await cacheMiddleware()(req, res, next);
    expect(next).toHaveBeenCalled();
    expect(logger.error).toHaveBeenCalled();
  });
});
