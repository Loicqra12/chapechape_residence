/**
 * P2-09B4A — Un seul propriétaire des signaux SIGINT/SIGTERM : server.js + shutdown.js
 */
const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');

const closeOrder = [];

jest.mock('../../../src/services/socket.service', () => ({
  close: jest.fn(async () => { closeOrder.push('socket'); }),
}));

jest.mock('../../../src/services/agenda.service', () => ({
  agenda: { stop: jest.fn(async () => { closeOrder.push('agenda'); }) },
}));

jest.mock('../../../src/config/redis', () => ({
  getClient: () => ({
    quit: jest.fn(async () => { closeOrder.push('redis'); }),
  }),
}));

const readiness = require('../../../src/runtime/readiness');
const { createShutdown } = require('../../../src/runtime/shutdown');

const BACKEND_ROOT = path.join(__dirname, '../../..');
const SERVER_JS = path.join(BACKEND_ROOT, 'src/server.js');
const DB_CONNECTOR_JS = path.join(BACKEND_ROOT, 'src/utils/dbConnector.js');

describe('P2-09B4A shutdown signal canonicalization', () => {
  afterEach(() => {
    readiness.resetForTests();
    closeOrder.length = 0;
    jest.clearAllMocks();
    jest.restoreAllMocks();
  });

  describe('signal ownership — static contract', () => {
    it('server.js enregistre SIGINT et SIGTERM vers createShutdown', () => {
      const src = fs.readFileSync(SERVER_JS, 'utf8');
      expect(src).toMatch(/process\.on\(['"]SIGTERM['"], \(\) => shutdown\(['"]SIGTERM['"]\)\)/);
      expect(src).toMatch(/process\.on\(['"]SIGINT['"], \(\) => shutdown\(['"]SIGINT['"]\)\)/);
    });

    it('dbConnector.js ne possède plus de handler process SIGINT/SIGTERM', () => {
      const src = fs.readFileSync(DB_CONNECTOR_JS, 'utf8');
      expect(src).not.toMatch(/process\.on\(['"]SIGINT['"]/);
      expect(src).not.toMatch(/process\.on\(['"]SIGTERM['"]/);
    });
  });

  describe('dbConnector runtime — no signal registration on connect', () => {
    it('connect() n’ajoute aucun listener SIGINT/SIGTERM', async () => {
      const sigintBefore = process.listenerCount('SIGINT');
      const sigtermBefore = process.listenerCount('SIGTERM');

      let connectPromise;
      jest.isolateModules(() => {
        jest.doMock('mongoose', () => {
          const conn = {
            on: jest.fn(),
            eventNames: () => [],
            readyState: 0,
            host: 'localhost',
            port: 27017,
            name: 'test',
            db: { databaseName: 'test' },
          };
          return {
            connect: jest.fn().mockResolvedValue(undefined),
            connection: conn,
            connections: [conn],
          };
        });

        jest.doMock('../../../src/utils/logger', () => ({
          info: jest.fn(),
          warn: jest.fn(),
          error: jest.fn(),
        }));

        process.env.MONGODB_URI = 'mongodb://localhost:27017/test';
        const dbConnector = require('../../../src/utils/dbConnector');
        connectPromise = dbConnector.connect();
      });

      await connectPromise;

      expect(process.listenerCount('SIGINT')).toBe(sigintBefore);
      expect(process.listenerCount('SIGTERM')).toBe(sigtermBefore);
    });
  });

  describe('createShutdown — idempotence et séquence de fermeture', () => {
    it('createShutdown est idempotent (second signal ignoré)', async () => {
      const httpClose = jest.fn((cb) => {
        closeOrder.push('http');
        cb();
      });

      jest.spyOn(mongoose.connection, 'close').mockResolvedValue(undefined);
      jest.spyOn(process, 'exit').mockImplementation(() => {});

      const prevReadyState = mongoose.connection.readyState;
      Object.defineProperty(mongoose.connection, 'readyState', {
        configurable: true,
        get: () => 1,
      });

      const shutdown = createShutdown({ server: { close: httpClose } });
      shutdown('SIGTERM');
      shutdown('SIGINT');

      await new Promise((resolve) => setImmediate(resolve));

      expect(httpClose).toHaveBeenCalledTimes(1);
      expect(process.exit).toHaveBeenCalledTimes(1);
      expect(process.exit).toHaveBeenCalledWith(0);
      expect(readiness.isShuttingDown()).toBe(true);

      Object.defineProperty(mongoose.connection, 'readyState', {
        configurable: true,
        value: prevReadyState,
        writable: true,
      });
    });

    it('fermeture HTTP → Socket → Agenda → Redis → Mongo', async () => {
      const prevEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'production';

      const httpClose = jest.fn((cb) => {
        closeOrder.push('http');
        cb();
      });

      jest.spyOn(mongoose.connection, 'close').mockImplementation(async () => {
        closeOrder.push('mongo');
      });
      jest.spyOn(process, 'exit').mockImplementation(() => {});

      const prevReadyState = mongoose.connection.readyState;
      Object.defineProperty(mongoose.connection, 'readyState', {
        configurable: true,
        get: () => 1,
      });

      const shutdown = createShutdown({ server: { close: httpClose } });
      shutdown('SIGTERM');

      await new Promise((resolve) => setImmediate(resolve));

      expect(closeOrder).toEqual(['http', 'socket', 'agenda', 'redis', 'mongo']);
      expect(process.exit).toHaveBeenCalledWith(0);

      Object.defineProperty(mongoose.connection, 'readyState', {
        configurable: true,
        value: prevReadyState,
        writable: true,
      });
      if (prevEnv === undefined) delete process.env.NODE_ENV;
      else process.env.NODE_ENV = prevEnv;
    });
  });
});
