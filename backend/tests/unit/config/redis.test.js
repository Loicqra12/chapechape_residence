const redis = require('../../../src/config/redis');

describe('Redis config (ioredis-mock, pas de réseau)', () => {
  it('NODE_ENV=test → client in-memory (isMock)', () => {
    expect(process.env.NODE_ENV).toBe('test');
    const client = redis.getClient();
    expect(client.isMock).toBe(true);
  });

  it('get / set EX / ttl / del sans localhost:6379', async () => {
    const client = redis.getClient();
    const key = `p203:${Date.now()}:${Math.random().toString(16).slice(2)}`;
    await client.set(key, 'v', 'EX', 60);
    expect(await client.get(key)).toBe('v');
    const ttl = await client.ttl(key);
    expect(ttl).toBeGreaterThan(0);
    expect(ttl).toBeLessThanOrEqual(60);
    await client.del(key);
    expect(await client.get(key)).toBeNull();
  });
});
