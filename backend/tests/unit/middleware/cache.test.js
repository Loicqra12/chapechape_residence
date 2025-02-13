const { cacheMiddleware, invalidateCache } = require('../../../src/middleware/cache');
const redis = require('../../../src/config/redis');
const logger = require('../../../src/utils/logger');

jest.mock('../../../src/config/redis');
jest.mock('../../../src/utils/logger', () => ({
    debug: jest.fn(),
    error: jest.fn(),
    info: jest.fn()
}));

describe('Cache Middleware', () => {
    let req;
    let res;
    let next;

    beforeEach(() => {
        req = {
            method: 'GET',
            originalUrl: '/test-url'
        };
        res = {
            json: jest.fn()
        };
        next = jest.fn();
        redis.get.mockImplementation((key, callback) => callback(null, null));
        redis.setex.mockImplementation((key, duration, value, callback) => callback(null));
        redis.keys.mockImplementation((pattern, callback) => callback(null, []));
        redis.del.mockImplementation((keys, callback) => callback(null));
        jest.clearAllMocks();
    });

    describe('Cache Middleware', () => {
        it('should skip cache for non-GET requests', async () => {
            req.method = 'POST';
            await cacheMiddleware()(req, res, next);
            expect(next).toHaveBeenCalled();
            expect(redis.get).not.toHaveBeenCalled();
        });

        it('should return cached data if available', async () => {
            const cachedData = { foo: 'bar' };
            redis.get.mockImplementation((key, callback) => 
                callback(null, JSON.stringify(cachedData))
            );

            await cacheMiddleware()(req, res, next);

            expect(redis.get).toHaveBeenCalledWith('cache:/test-url', expect.any(Function));
            expect(res.json).toHaveBeenCalledWith(cachedData);
            expect(next).not.toHaveBeenCalled();
            expect(logger.debug).toHaveBeenCalledWith(expect.stringContaining('Cache hit'));
        });

        it('should cache new response data', async () => {
            const responseData = { foo: 'bar' };
            
            await cacheMiddleware()(req, res, next);
            res.json(responseData);

            expect(redis.setex).toHaveBeenCalledWith(
                'cache:/test-url',
                3600,
                JSON.stringify(responseData),
                expect.any(Function)
            );
        });

        it('should handle redis get errors gracefully', async () => {
            redis.get.mockImplementation((key, callback) => 
                callback(new Error('Redis error'))
            );

            await cacheMiddleware()(req, res, next);

            expect(logger.error).toHaveBeenCalledWith(
                'Cache middleware error:',
                'Redis error'
            );
            expect(next).toHaveBeenCalled();
        });

        it('should handle redis set errors gracefully', async () => {
            redis.setex.mockImplementation((key, duration, value, callback) => 
                callback(new Error('Redis set error'))
            );

            await cacheMiddleware()(req, res, next);
            res.json({ test: 'data' });

            expect(logger.error).toHaveBeenCalledWith(
                'Redis cache error:',
                'Redis set error'
            );
        });

        it('should use custom cache duration', async () => {
            const customDuration = 7200;
            const responseData = { foo: 'bar' };

            await cacheMiddleware(customDuration)(req, res, next);
            res.json(responseData);

            expect(redis.setex).toHaveBeenCalledWith(
                'cache:/test-url',
                customDuration,
                JSON.stringify(responseData),
                expect.any(Function)
            );
        });
    });

    describe('Cache Invalidation', () => {
        it('should invalidate cache for given pattern', async () => {
            const keys = ['cache:test1', 'cache:test2'];
            redis.keys.mockImplementation((pattern, callback) => callback(null, keys));

            await invalidateCache('test*');

            expect(redis.keys).toHaveBeenCalledWith('cache:test*', expect.any(Function));
            expect(redis.del).toHaveBeenCalledWith(keys, expect.any(Function));
            expect(logger.info).toHaveBeenCalledWith(expect.stringContaining('Cache invalidated'));
        });

        it('should handle empty keys gracefully', async () => {
            await invalidateCache('test*');

            expect(redis.keys).toHaveBeenCalledWith('cache:test*', expect.any(Function));
            expect(redis.del).not.toHaveBeenCalled();
        });

        it('should handle redis keys error gracefully', async () => {
            redis.keys.mockImplementation((pattern, callback) => 
                callback(new Error('Redis keys error'))
            );

            await invalidateCache('test*');

            expect(logger.error).toHaveBeenCalledWith(
                'Cache invalidation error:',
                'Redis keys error'
            );
        });

        it('should handle redis del error gracefully', async () => {
            const keys = ['cache:test1'];
            redis.keys.mockImplementation((pattern, callback) => callback(null, keys));
            redis.del.mockImplementation((keys, callback) => 
                callback(new Error('Redis del error'))
            );

            await invalidateCache('test*');

            expect(logger.error).toHaveBeenCalledWith(
                'Cache invalidation error:',
                'Redis del error'
            );
        });
    });
});
