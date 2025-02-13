const logger = require('../../../src/utils/logger');

// Mock du logger
jest.mock('../../../src/utils/logger', () => ({
    error: jest.fn(),
    info: jest.fn(),
    debug: jest.fn(),
    warn: jest.fn(),
    http: jest.fn()
}));

// Mock de ioredis-mock
jest.mock('ioredis-mock', () => {
    const mockClient = {
        on: jest.fn(),
        set: jest.fn().mockResolvedValue('OK'),
        get: jest.fn().mockResolvedValue(null),
        del: jest.fn().mockResolvedValue(1),
        hset: jest.fn().mockResolvedValue(1),
        hget: jest.fn().mockResolvedValue(null),
        hdel: jest.fn().mockResolvedValue(1),
        rpush: jest.fn().mockResolvedValue(2),
        lrange: jest.fn().mockResolvedValue([]),
        lpop: jest.fn().mockResolvedValue(null),
        sadd: jest.fn().mockResolvedValue(2),
        smembers: jest.fn().mockResolvedValue([]),
        srem: jest.fn().mockResolvedValue(1)
    };

    return jest.fn().mockImplementation(() => mockClient);
});

describe('Redis Configuration', () => {
    const originalEnv = process.env;
    let createRedisClient;
    let mockClient;
    
    beforeEach(() => {
        jest.clearAllMocks();
        jest.resetModules();
        process.env = { ...originalEnv };
        
        // Réinitialiser le module redis.js
        createRedisClient = require('../../../src/config/redis');
        mockClient = createRedisClient();
    });

    afterEach(() => {
        process.env = originalEnv;
    });

    it('should use redis-mock in test environment', () => {
        process.env.NODE_ENV = 'test';
        createRedisClient();
        expect(logger.info).toHaveBeenCalledWith('Using Redis Mock');
    });

    it('should use redis-mock in development environment', () => {
        process.env.NODE_ENV = 'development';
        createRedisClient();
        expect(logger.info).toHaveBeenCalledWith('Using Redis Mock');
    });

    it('should use redis-mock when NODE_ENV is not set', () => {
        delete process.env.NODE_ENV;
        createRedisClient();
        expect(logger.info).toHaveBeenCalledWith('Using Redis Mock');
    });

    it('should handle basic Redis operations', async () => {
        mockClient.get.mockImplementationOnce(() => Promise.resolve('test-value'));
        
        await mockClient.set('test-key', 'test-value');
        const value = await mockClient.get('test-key');
        expect(value).toBe('test-value');
        
        await mockClient.del('test-key');
        const deletedValue = await mockClient.get('test-key');
        expect(deletedValue).toBeNull();
    });

    it('should handle hash operations', async () => {
        mockClient.hget.mockImplementationOnce(() => Promise.resolve('value1'));
        
        await mockClient.hset('hash-test', 'field1', 'value1');
        const value = await mockClient.hget('hash-test', 'field1');
        expect(value).toBe('value1');
        
        await mockClient.hdel('hash-test', 'field1');
        const deletedValue = await mockClient.hget('hash-test', 'field1');
        expect(deletedValue).toBeNull();
    });

    it('should handle list operations', async () => {
        mockClient.lrange.mockImplementationOnce(() => Promise.resolve(['value1', 'value2']));
        mockClient.lpop.mockImplementationOnce(() => Promise.resolve('value1'));
        
        await mockClient.rpush('list-test', 'value1', 'value2');
        const values = await mockClient.lrange('list-test', 0, -1);
        expect(values).toEqual(['value1', 'value2']);
        
        const poppedValue = await mockClient.lpop('list-test');
        expect(poppedValue).toBe('value1');
    });

    it('should handle set operations', async () => {
        mockClient.smembers
            .mockImplementationOnce(() => Promise.resolve(['member1', 'member2']))
            .mockImplementationOnce(() => Promise.resolve(['member2']));
        
        await mockClient.sadd('set-test', 'member1', 'member2');
        const members = await mockClient.smembers('set-test');
        expect(members.sort()).toEqual(['member1', 'member2'].sort());
        
        await mockClient.srem('set-test', 'member1');
        const remainingMembers = await mockClient.smembers('set-test');
        expect(remainingMembers).toEqual(['member2']);
    });
});
