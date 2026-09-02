const { EXPECTED_PROD_MONGO_FINGERPRINT } = require('../../../src/runtime/prod-constants');
const { fingerprintFromUri } = require('../../../src/utils/mongo-fingerprint');
const { isPrimaryScheduler, workerLabel, FINANCIAL_JOB_OPTIONS, saveUniqueScheduledJob } = require('../../../src/runtime/agenda-cluster');
const readiness = require('../../../src/runtime/readiness');
const { configPresence } = require('../../../src/runtime/config-presence');

describe('P2-01 runtime invariants', () => {
  afterEach(() => {
    readiness.resetForTests();
  });
  it('empreinte attendue est le hash 16 hex figé P0', () => {
    expect(EXPECTED_PROD_MONGO_FINGERPRINT).toBe('efebb871c934cf3c');
    expect(EXPECTED_PROD_MONGO_FINGERPRINT).toMatch(/^[a-f0-9]{16}$/);
  });

  it('fingerprintFromUri n’inclut jamais user/password', () => {
    const info = fingerprintFromUri('mongodb+srv://user:supersecret@cluster0.abc.mongodb.net/chapechape');
    expect(info.host).toBe('cluster0.abc.mongodb.net');
    expect(JSON.stringify(info)).not.toMatch(/supersecret/);
    expect(info.host).not.toContain('user:');
  });

  it('seul le worker PM2 0 est scheduler primaire', () => {
    const prev = process.env.NODE_APP_INSTANCE;
    delete process.env.NODE_APP_INSTANCE;
    expect(isPrimaryScheduler()).toBe(true);
    process.env.NODE_APP_INSTANCE = '0';
    expect(isPrimaryScheduler()).toBe(true);
    expect(workerLabel()).toBe('pm2:0');
    process.env.NODE_APP_INSTANCE = '2';
    expect(isPrimaryScheduler()).toBe(false);
    if (prev === undefined) delete process.env.NODE_APP_INSTANCE;
    else process.env.NODE_APP_INSTANCE = prev;
  });

  it('jobs financiers ont lockLifetime et concurrency 1', () => {
    expect(FINANCIAL_JOB_OPTIONS.concurrency).toBe(1);
    expect(FINANCIAL_JOB_OPTIONS.lockLimit).toBe(1);
    expect(FINANCIAL_JOB_OPTIONS.lockLifetime).toBe(10 * 60 * 1000);
  });

  it('readiness : /health reste vivant, /ready passe not_ready au shutdown', () => {
    readiness.markReady();
    expect(readiness.isReady()).toBe(true);
    readiness.beginShutdown();
    expect(readiness.isReady()).toBe(false);
    expect(readiness.isShuttingDown()).toBe(true);
  });

  it('configPresence n’expose aucune valeur de secret', () => {
    const prevJwt = process.env.JWT_SECRET;
    process.env.JWT_SECRET = 'this-is-a-secret-value-min-32-chars!!';
    const presence = configPresence();
    const dumped = JSON.stringify(presence);
    expect(presence.secretsConfigured.JWT_SECRET).toBe(true);
    expect(dumped).not.toContain('this-is-a-secret-value');
    if (prevJwt === undefined) delete process.env.JWT_SECRET;
    else process.env.JWT_SECRET = prevJwt;
  });

  it('saveUniqueScheduledJob déduplique sur data.<uniqueField>', async () => {
    const uniqueCalls = [];
    const fakeAgenda = {
      create(_name, data) {
        return {
          unique(query) {
            uniqueCalls.push(query);
            return this;
          },
          schedule() { return this; },
          async save() { return { attrs: { data } }; },
        };
      },
    };
    await saveUniqueScheduledJob(
      fakeAgenda,
      'process payment refund',
      'now',
      { paymentId: 'pay_1' },
      'paymentId'
    );
    expect(uniqueCalls).toEqual([{ name: 'process payment refund', 'data.paymentId': 'pay_1' }]);
  });
});
