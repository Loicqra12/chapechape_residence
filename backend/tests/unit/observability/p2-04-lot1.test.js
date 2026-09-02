const fs = require('fs');
const path = require('path');
const EventEmitter = require('events');
const express = require('express');
const request = require('supertest');
const morgan = require('morgan');
const logger = require('../../../src/utils/logger');
const {
  attachAgendaEnvelope,
  pickWhitelistedData,
  JOB_DATA_WHITELIST,
} = require('../../../src/observability/agenda-envelope');

describe('P2-04 lot 1 — Morgan / Winston / Agenda', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('Morgan unique', () => {
    it('app.js ne monte qu’une chaîne HTTP (logger.http, pas morgan() direct)', () => {
      const appSrc = fs.readFileSync(
        path.join(__dirname, '../../../src/app.js'),
        'utf8'
      );
      expect(appSrc).toMatch(/app\.use\(logger\.http\)/);
      expect(appSrc).not.toMatch(/app\.use\(morgan\(/);
      expect(appSrc).not.toMatch(/require\(["']morgan["']\)/);
    });

    it('une requête HTTP avec logger.http seul → un seul access log Winston', async () => {
      const infoSpy = jest.spyOn(logger, 'info').mockImplementation(() => logger);
      const app = express();
      app.use(logger.http);
      app.get('/ping', (req, res) => res.status(200).send('ok'));

      await request(app).get('/ping');

      const accessLines = infoSpy.mock.calls.filter(([msg]) =>
        typeof msg === 'string' && /GET \/ping/.test(msg)
      );
      expect(accessLines.length).toBe(1);
    });

    it('deux Morgan actifs produiraient deux access logs (preuve du doublon à éviter)', async () => {
      const writes = [];
      const stream = { write: (m) => writes.push(m.trim()) };
      const app = express();
      app.use(morgan('tiny', { stream }));
      app.use(morgan('tiny', { stream }));
      app.get('/dup', (req, res) => res.status(200).send('ok'));

      await request(app).get('/dup');
      expect(writes.filter((l) => /GET \/dup/.test(l)).length).toBe(2);
    });
  });

  describe('Winston canonique', () => {
    it('performance.middleware importe utils/logger, pas config/logger', () => {
      const src = fs.readFileSync(
        path.join(__dirname, '../../../src/middlewares/performance.middleware.js'),
        'utf8'
      );
      expect(src).toMatch(/require\(['"]\.\.\/utils\/logger['"]\)/);
      expect(src).not.toMatch(/require\(['"]\.\.\/config\/logger['"]\)/);
      expect(
        fs.existsSync(path.join(__dirname, '../../../src/config/logger.js'))
      ).toBe(false);
    });

    it('logPerformance canonique structure l’événement', () => {
      const infoSpy = jest.spyOn(logger, 'info').mockImplementation(() => logger);
      logger.logPerformance('GET /health', 12, { route: '/health' });
      expect(infoSpy).toHaveBeenCalledWith(
        'Performance Metric',
        expect.objectContaining({
          type: 'performance',
          operation: 'GET /health',
          duration: 12,
        })
      );
    });
  });

  describe('Agenda envelope', () => {
    it('whitelist exclut secrets / email / payload provider', () => {
      const picked = pickWhitelistedData({
        reservationId: 'r1',
        paymentId: 'p1',
        email: 'a@b.com',
        password: 'x',
        authorization: 'Bearer x',
        otp: '123456',
        providerPayload: { raw: true },
        token: 'jwt',
      });
      expect(picked).toEqual({ reservationId: 'r1', paymentId: 'p1' });
      expect(JOB_DATA_WHITELIST).not.toContain('email');
      expect(JOB_DATA_WHITELIST).not.toContain('password');
    });

    it('start/success/fail → événements structurés avec duration et IDs', () => {
      const infoSpy = jest.spyOn(logger, 'info').mockImplementation(() => logger);
      const warnSpy = jest.spyOn(logger, 'warn').mockImplementation(() => logger);
      const errorSpy = jest.spyOn(logger, 'error').mockImplementation(() => logger);

      const agenda = new EventEmitter();
      expect(attachAgendaEnvelope(agenda)).toBe(true);
      expect(attachAgendaEnvelope(agenda)).toBe(false);

      const job = {
        attrs: {
          _id: 'job-1',
          name: 'expire reservation',
          failCount: 0,
          data: {
            reservationId: 'res-1',
            email: 'secret@example.com',
            otp: '999999',
          },
        },
      };

      agenda.emit('start', job);
      expect(infoSpy).toHaveBeenCalledWith(
        'AGENDA_JOB_STARTED',
        expect.objectContaining({
          event: 'AGENDA_JOB_STARTED',
          jobName: 'expire reservation',
          jobId: 'job-1',
          reservationId: 'res-1',
        })
      );
      const startedMeta = infoSpy.mock.calls.find((c) => c[0] === 'AGENDA_JOB_STARTED')[1];
      expect(startedMeta.email).toBeUndefined();
      expect(startedMeta.otp).toBeUndefined();
      expect(warnSpy).not.toHaveBeenCalledWith('AGENDA_JOB_RETRY', expect.anything());

      agenda.emit('success', job);
      expect(infoSpy).toHaveBeenCalledWith(
        'AGENDA_JOB_COMPLETED',
        expect.objectContaining({
          event: 'AGENDA_JOB_COMPLETED',
          reservationId: 'res-1',
          durationMs: expect.any(Number),
        })
      );

      const failJob = {
        attrs: {
          _id: 'job-2',
          name: 'process payout',
          failCount: 2,
          data: { payoutId: 'po-1' },
        },
      };
      agenda.emit('start', failJob);
      expect(warnSpy).toHaveBeenCalledWith(
        'AGENDA_JOB_RETRY',
        expect.objectContaining({
          event: 'AGENDA_JOB_RETRY',
          attempt: 2,
          payoutId: 'po-1',
        })
      );
      agenda.emit('fail', new Error('provider_down'), failJob);
      expect(errorSpy).toHaveBeenCalledWith(
        'AGENDA_JOB_FAILED',
        expect.objectContaining({
          event: 'AGENDA_JOB_FAILED',
          err: 'provider_down',
          payoutId: 'po-1',
        })
      );
    });
  });

  describe('Dead / unused cleanup', () => {
    it('config/sentry.js absent ; Pino non importé dans src', () => {
      expect(
        fs.existsSync(path.join(__dirname, '../../../src/config/sentry.js'))
      ).toBe(false);

      const pkg = JSON.parse(
        fs.readFileSync(path.join(__dirname, '../../../package.json'), 'utf8')
      );
      expect(pkg.dependencies['express-pino-logger']).toBeUndefined();

      const srcRoot = path.join(__dirname, '../../../src');
      const walk = (dir) => {
        for (const name of fs.readdirSync(dir)) {
          const full = path.join(dir, name);
          if (fs.statSync(full).isDirectory()) walk(full);
          else if (full.endsWith('.js')) {
            const text = fs.readFileSync(full, 'utf8');
            expect(text).not.toMatch(/require\(['"]pino['"]\)/);
            expect(text).not.toMatch(/express-pino-logger/);
            expect(text).not.toMatch(/config\/sentry/);
            expect(text).not.toMatch(/require\(['"][^'"]*config\/logger['"]\)/);
          }
        }
      };
      walk(srcRoot);
    });
  });
});
