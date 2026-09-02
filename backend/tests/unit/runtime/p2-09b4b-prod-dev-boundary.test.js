/**
 * P2-09B4B — Production dependency boundary (ioredis-mock must stay out of prod load path)
 */
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const BACKEND_ROOT = path.join(__dirname, '../../..');
const REDIS_JS = path.join(BACKEND_ROOT, 'src/config/redis.js');
const PACKAGE_JSON = path.join(BACKEND_ROOT, 'package.json');
const SERVER_JS = path.join(BACKEND_ROOT, 'src/server.js');

function parseTopLevelRequires(src) {
  const lines = src.split(/\r?\n/);
  const top = [];
  for (const line of lines) {
    if (/^\s*(const|let|var|async function|function)\s+createRedisClient/.test(line)) break;
    const m = line.match(/^\s*(?:const|let|var)\s+\w+\s*=\s*require\(['"]([^'"]+)['"]\)/);
    if (m) top.push(m[1]);
  }
  return top;
}

function collectStaticRequiresFromFile(file, visited = new Set(), external = new Map()) {
  const abs = path.resolve(file);
  if (visited.has(abs) || !fs.existsSync(abs)) return { visited, external };
  visited.add(abs);
  const src = fs.readFileSync(abs, 'utf8');
  const re = /require\(['"]([^'"]+)['"]\)/g;
  let m;
  while ((m = re.exec(src))) {
    const id = m[1];
    if (id.startsWith('.')) {
      const base = path.resolve(path.dirname(abs), id);
      for (const ext of ['', '.js', '.json', '/index.js']) {
        const candidate = base + ext;
        if (fs.existsSync(candidate) && fs.statSync(candidate).isFile()) {
          collectStaticRequiresFromFile(candidate, visited, external);
          break;
        }
      }
      continue;
    }
    const top = id.startsWith('@') ? id.split('/').slice(0, 2).join('/') : id.split('/')[0];
    if (!external.has(top)) external.set(top, []);
    external.get(top).push(path.relative(BACKEND_ROOT, abs).replace(/\\/g, '/'));
  }
  return { visited, external };
}

function runRedisProbe(nodeEnv) {
  const script = `
    const Module = require('module');
    const path = require('path');
    process.env.NODE_ENV = ${JSON.stringify(nodeEnv)};
    const attempted = [];
    const orig = Module._load;
    Module._load = function (request) {
      if (request === 'ioredis-mock' || (typeof request === 'string' && request.startsWith('ioredis-mock/'))) {
        attempted.push(request);
        if (process.env.NODE_ENV === 'production') {
          throw new Error('ioredis-mock resolved in production');
        }
      }
      if (request === 'ioredis' && process.env.NODE_ENV === 'production') {
        function FakeRedis() { this.isMock = false; }
        FakeRedis.prototype.get = function () {};
        FakeRedis.prototype.set = function () {};
        FakeRedis.prototype.on = function () { return this; };
        FakeRedis.prototype.quit = async function () {};
        return FakeRedis;
      }
      return orig.apply(this, arguments);
    };
    const redis = require(${JSON.stringify(REDIS_JS)});
    const client = redis.getClient();
    const payload = {
      nodeEnv: process.env.NODE_ENV,
      attempted,
      isMock: client.isMock === true,
      ctor: client.constructor && client.constructor.name,
    };
    process.stdout.write('\\n__P2_09B4B__' + JSON.stringify(payload) + '\\n');
  `;
  const result = spawnSync(process.execPath, ['-e', script], {
    cwd: BACKEND_ROOT,
    encoding: 'utf8',
    env: { ...process.env, NODE_ENV: nodeEnv },
  });
  const match = (result.stdout || '').match(/__P2_09B4B__(\{.*\})/);
  return {
    status: result.status,
    stderr: result.stderr,
    stdout: result.stdout,
    payload: match ? JSON.parse(match[1]) : null,
  };
}

describe('P2-09B4B production dependency boundary', () => {
  it('ioredis-mock reste une devDependency (jamais dans dependencies)', () => {
    const pkg = JSON.parse(fs.readFileSync(PACKAGE_JSON, 'utf8'));
    expect(pkg.devDependencies['ioredis-mock']).toBeDefined();
    expect(pkg.dependencies['ioredis-mock']).toBeUndefined();
  });

  it('redis.js n’importe pas ioredis-mock au top-level', () => {
    const src = fs.readFileSync(REDIS_JS, 'utf8');
    const topLevel = parseTopLevelRequires(src);
    expect(topLevel).not.toContain('ioredis-mock');
    expect(src).toMatch(/if\s*\(\s*useRedisMock\s*\)\s*\{[\s\S]*?require\(['"]ioredis-mock['"]\)/);
  });

  it('NODE_ENV=production : charge redis.js sans jamais résoudre ioredis-mock', () => {
    const result = runRedisProbe('production');
    expect(result.status).toBe(0);
    expect(result.payload).toBeTruthy();
    expect(result.payload.attempted).toEqual([]);
    expect(result.payload.isMock).toBe(false);
  });

  it('NODE_ENV=test : continue d’utiliser Redis Mock', () => {
    const result = runRedisProbe('test');
    expect(result.status).toBe(0);
    expect(result.payload).toBeTruthy();
    expect(result.payload.attempted).toContain('ioredis-mock');
    expect(result.payload.isMock).toBe(true);
    expect(result.payload.ctor).toMatch(/Mock/i);
  });

  it('NODE_ENV=development : continue d’utiliser Redis Mock', () => {
    const result = runRedisProbe('development');
    expect(result.status).toBe(0);
    expect(result.payload).toBeTruthy();
    expect(result.payload.attempted).toContain('ioredis-mock');
    expect(result.payload.isMock).toBe(true);
    expect(result.payload.ctor).toMatch(/Mock/i);
  });

  it('audit startup : aucun autre top-level require de devDependency depuis server.js graph (hors mock conditionnel)', () => {
    const pkg = JSON.parse(fs.readFileSync(PACKAGE_JSON, 'utf8'));
    const deps = new Set(Object.keys(pkg.dependencies || {}));
    const devDeps = new Set(Object.keys(pkg.devDependencies || {}));
    const { external } = collectStaticRequiresFromFile(SERVER_JS);

    const BUILTINS = new Set([
      'fs', 'path', 'http', 'https', 'crypto', 'os', 'util', 'events', 'stream',
      'buffer', 'url', 'querystring', 'child_process', 'cluster', 'net', 'tls',
      'zlib', 'assert', 'module', 'process', 'v8', 'vm', 'worker_threads',
      'perf_hooks', 'readline', 'string_decoder', 'timers', 'tty', 'dns', 'dgram',
      'inspector', 'async_hooks', 'http2', 'diagnostics_channel', 'console',
    ]);

    const defects = [];
    for (const [name, files] of external.entries()) {
      if (BUILTINS.has(name) || name.startsWith('node:')) continue;
      const inDep = deps.has(name);
      const inDev = devDeps.has(name);
      if (!(inDev && !inDep)) continue;

      if (name === 'ioredis-mock') {
        const redisSrc = fs.readFileSync(REDIS_JS, 'utf8');
        const topLevel = parseTopLevelRequires(redisSrc);
        expect(topLevel).not.toContain('ioredis-mock');
        expect(files.every((f) => f.replace(/\\/g, '/').endsWith('src/config/redis.js'))).toBe(true);
        continue;
      }

      defects.push({ pkg: name, files: [...new Set(files)] });
    }

    expect(defects).toEqual([]);
  });
});
