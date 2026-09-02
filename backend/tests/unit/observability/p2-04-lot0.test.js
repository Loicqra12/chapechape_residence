const fs = require('fs');
const path = require('path');
const express = require('express');
const request = require('supertest');
const ApiError = require('../../../src/utils/apiError');
const logger = require('../../../src/utils/logger');
const { errorHandler } = require('../../../src/middlewares/error.middleware');
const { protect } = require('../../../src/middlewares/auth.middleware');
const { requestIdMiddleware } = require('../../../src/middlewares/request-id.middleware');
const { runWithRequestContext } = require('../../../src/observability/request-context');
const {
  buildSentryInitOptions,
} = require('../../../src/observability/sentry-init');
const {
  shouldCaptureSentry,
  logLevelForError,
} = require('../../../src/observability/http-error-policy');
const { parseBoundedTraceId, resolveRequestId } = require('../../../src/observability/trace-ids');

function mockRes() {
  return {
    status: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis(),
    setHeader: jest.fn(),
  };
}

function mockReq(overrides = {}) {
  return {
    method: 'POST',
    path: '/api/reservations',
    ip: '127.0.0.1',
    get: () => 'jest',
    headers: {},
    originalUrl: '/api/reservations',
    ...overrides,
  };
}

describe('P2-04 lot 0 — Sentry / PII / niveaux / requestId', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('SENTRY_DSN absent → Sentry disabled, pas de DSN', () => {
    const opts = buildSentryInitOptions({ NODE_ENV: 'production' });
    expect(opts.enabled).toBe(false);
    expect(opts.dsn).toBeUndefined();
    expect(opts.sendDefaultPii).toBe(false);
  });

  it('sendDefaultPii est false même avec DSN', () => {
    const opts = buildSentryInitOptions({
      NODE_ENV: 'production',
      SENTRY_DSN: 'https://abc@o123.ingest.sentry.io/1',
    });
    expect(opts.enabled).toBe(true);
    expect(opts.sendDefaultPii).toBe(false);
  });

  it('aucun DSN Sentry hardcodé dans instrument.js / sentry-init.js', () => {
    const instrument = fs.readFileSync(path.join(__dirname, '../../../instrument.js'), 'utf8');
    const sentryInit = fs.readFileSync(
      path.join(__dirname, '../../../src/observability/sentry-init.js'),
      'utf8'
    );
    expect(instrument).not.toMatch(/ingest\.(us\.)?sentry\.io/);
    expect(instrument).not.toMatch(/SENTRY_DSN\s*\|\|\s*['"]https?:/);
    expect(sentryInit).not.toMatch(/ingest\.(us\.)?sentry\.io/);
  });

  it('409 métier → logger.info, pas logger.error, pas Sentry', () => {
    const err = ApiError.conflict('Déjà réservé', 'INVENTORY_ALREADY_RESERVED');
    expect(logLevelForError(err)).toBe('info');
    expect(shouldCaptureSentry(err)).toBe(false);

    const errorSpy = jest.spyOn(logger, 'error');
    const infoSpy = jest.spyOn(logger, 'info');
    errorHandler(err, mockReq(), mockRes(), jest.fn());
    expect(errorSpy).not.toHaveBeenCalled();
    expect(infoSpy).toHaveBeenCalled();

    const opts = buildSentryInitOptions({
      NODE_ENV: 'production',
      SENTRY_DSN: 'https://abc@o123.ingest.sentry.io/1',
    });
    expect(opts.beforeSend({ request: {} }, { originalException: err })).toBeNull();
  });

  it('401 token absent → warn AUTH_FAILURE, pas logger.error, pas Sentry', async () => {
    const errorSpy = jest.spyOn(logger, 'error');
    const warnSpy = jest.spyOn(logger, 'warn');
    const next = jest.fn();
    await protect(mockReq({ headers: {} }), mockRes(), next);

    expect(errorSpy).not.toHaveBeenCalled();
    expect(warnSpy).toHaveBeenCalledWith(
      'AUTH_FAILURE',
      expect.objectContaining({ reason: 'missing_token' })
    );
    expect(next).toHaveBeenCalled();
    const passed = next.mock.calls[0][0];
    expect(passed.statusCode).toBe(401);
    expect(shouldCaptureSentry(passed)).toBe(false);
    expect(logLevelForError(passed)).toBe('warn');
  });

  it('erreur technique 500 → logger.error et capturable Sentry', () => {
    const err = new Error('Mongo transaction aborted');
    expect(logLevelForError(err)).toBe('error');
    expect(shouldCaptureSentry(err)).toBe(true);

    const errorSpy = jest.spyOn(logger, 'error');
    errorHandler(err, mockReq(), mockRes(), jest.fn());
    expect(errorSpy).toHaveBeenCalled();

    const opts = buildSentryInitOptions({
      NODE_ENV: 'production',
      SENTRY_DSN: 'https://abc@o123.ingest.sentry.io/1',
    });
    const event = { request: { headers: { authorization: 'Bearer secret' } } };
    const kept = opts.beforeSend(event, { originalException: err });
    expect(kept).not.toBeNull();
    expect(kept.request.headers.authorization).toBeUndefined();
  });

  it('sanitizer : secrets et PII email/téléphone', () => {
    const sanitized = logger.sanitizeObject({
      password: 'hunter2',
      token: 'jwt-value',
      authorization: 'Bearer abc',
      otp: '123456',
      email: 'admin@example.com',
      phone: '+22507012345642',
      nested: { refreshToken: 'rt', userEmail: 'ada.lovelace@example.com' },
    });
    expect(sanitized.password).toBe('***MASKED***');
    expect(sanitized.token).toBe('***MASKED***');
    expect(sanitized.authorization).toBe('***MASKED***');
    expect(sanitized.otp).toBe('***MASKED***');
    expect(sanitized.email).toBe('ad***@example.com');
    expect(sanitized.phone).toBe('+22507******42');
    expect(sanitized.nested.refreshToken).toBe('***MASKED***');
    expect(sanitized.nested.userEmail).toBe('ad***@example.com');
    expect(logger.maskEmail('admin@example.com')).toBe('ad***@example.com');
    expect(logger.sanitizeObject('password=supersecret')).toContain('***MASKED***');
  });

  it('x-request-id valide est repris ; absent → UUID ; invalide → remplacé', () => {
    expect(parseBoundedTraceId('req-abc_123')).toBe('req-abc_123');
    expect(parseBoundedTraceId('x'.repeat(200))).toBeNull();
    expect(parseBoundedTraceId('has space')).toBeNull();
    expect(parseBoundedTraceId('<script>')).toBeNull();

    const generated = resolveRequestId(undefined);
    expect(generated).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    );
    expect(resolveRequestId('x'.repeat(500))).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    );
  });

  it('middleware : reprend x-request-id, conserve correlationId, expose X-Request-Id', async () => {
    const app = express();
    app.use(requestIdMiddleware);
    app.get('/ping', (req, res) => {
      res.json({
        id: req.id,
        requestId: req.requestId,
        correlationId: req.correlationId,
      });
    });

    const valid = await request(app)
      .get('/ping')
      .set('x-request-id', 'http-req-001')
      .set('x-correlation-id', 'ops-corr-001');
    expect(valid.headers['x-request-id']).toBe('http-req-001');
    expect(valid.headers['x-correlation-id']).toBe('ops-corr-001');
    expect(valid.body.id).toBe('http-req-001');
    expect(valid.body.correlationId).toBe('ops-corr-001');
    expect(valid.body.id).not.toBe(valid.body.correlationId);

    const generated = await request(app).get('/ping');
    expect(generated.headers['x-request-id']).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    );
    expect(generated.body.correlationId).toBeUndefined();

    const rejected = await request(app)
      .get('/ping')
      .set('x-request-id', 'not valid id')
      .set('x-correlation-id', 'also bad');
    expect(rejected.headers['x-request-id']).not.toBe('not valid id');
    expect(rejected.headers['x-correlation-id']).toBeUndefined();
  });

  it('logger injecte requestId depuis le contexte ALS', () => {
    const attached = runWithRequestContext(
      { requestId: 'ctx-req-1', correlationId: 'ctx-corr-1' },
      () => logger.attachRequestContext({ event: 'TEST' })
    );
    expect(attached).toEqual({
      requestId: 'ctx-req-1',
      correlationId: 'ctx-corr-1',
      event: 'TEST',
    });
  });
});
