/**
 * P2-06D — Distributed presence / chat push fallback correctness
 */
const http = require('http');
const socketIO = require('socket.io');
const ioClient = require('socket.io-client');
const { createAdapter } = require('@socket.io/redis-adapter');
const Redis = require('ioredis');
const mongoose = require('mongoose');
const { generateAccessToken } = require('../../../src/utils/jwt');
const SocketService = require('../../../src/services/socket.service');
const User = require('../../../src/models/user.model');
const notificationService = require('../../../src/services/notification.service');
const oneSignalService = require('../../../src/services/onesignal.service');
const { COMMON } = require('../../../src/utils/notification-types');

jest.setTimeout(120000);

/** @param {import('http').Server} server */
function closeHttpServer(server) {
  if (!server || !server.listening) {
    return Promise.resolve();
  }
  return new Promise((resolve, reject) => {
    server.close((err) => (err ? reject(err) : resolve()));
  });
}

/** @param {import('socket.io').Server} io */
function closeSocketIo(io) {
  if (!io) {
    return Promise.resolve();
  }
  return new Promise((resolve, reject) => {
    io.close((err) => (err ? reject(err) : resolve()));
  });
}

/** @param {import('ioredis').Redis} client */
async function quitRedisClient(client) {
  if (!client) return;
  const status = client.status;
  if (status === 'end' || status === 'close') return;
  try {
    await client.quit();
  } catch (err) {
    const msg = err?.message || String(err);
    if (/closed|ended|not connected|stream/i.test(msg)) {
      client.disconnect();
      return;
    }
    throw err;
  }
}

/** @param {import('socket.io-client').Socket} socket */
async function closeSocketClient(socket) {
  if (!socket) return;
  try {
    if (socket.connected) {
      socket.disconnect();
    }
  } catch (_) {
    /* already disconnected */
  }
  try {
    if (socket.io && typeof socket.io.close === 'function') {
      socket.io.close();
    }
  } catch (_) {
    /* manager already closed */
  }
  try {
    socket.close();
  } catch (_) {
    /* already closed */
  }
  await new Promise((resolve) => setTimeout(resolve, 50));
}

function trackSocket(clients, socket) {
  clients.push(socket);
  return socket;
}

function waitForConnect(socket) {
  return new Promise((resolve, reject) => {
    socket.on('connect', resolve);
    socket.on('connect_error', reject);
  });
}

function waitForEvent(socket, event, timeoutMs = 5000) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`Timeout waiting for ${event}`)), timeoutMs);
    socket.once(event, (payload) => {
      clearTimeout(timer);
      resolve(payload);
    });
  });
}

async function waitUntil(conditionFn, { timeoutMs = 5000, intervalMs = 25 } = {}) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (await conditionFn()) return;
    await new Promise((r) => setTimeout(r, intervalMs));
  }
  throw new Error('waitUntil: condition not met within timeout');
}

async function createTestUser(role, suffix = '') {
  return User.create({
    email: `${role}-p2-06d-${suffix}-${Date.now()}-${Math.random()}@test.com`,
    password: 'Test1234!',
    firstName: role,
    lastName: 'Test',
    role,
    deviceTokens: [],
  });
}

/**
 * Simule la décision push du message.controller (sans HTTP).
 */
async function shouldSendOfflinePush(recipientId) {
  const isOnline = await SocketService.isUserOnline(recipientId);
  return !isOnline;
}

describe('P2-06D distributed presence / chat push fallback', () => {
  describe('SocketService.isUserOnline — single worker', () => {
    let server;
    let baseUrl;
    /** @type {import('socket.io-client').Socket[]} */
    let socketClients;

    beforeAll(async () => {
      socketClients = [];
      server = http.createServer();
      await new Promise((resolve) => server.listen(0, resolve));
      const { port } = server.address();
      baseUrl = `http://127.0.0.1:${port}`;
      SocketService.initialize(server);
    });

    afterAll(async () => {
      for (const socket of socketClients) {
        await closeSocketClient(socket);
      }
      await SocketService.close();
      await closeHttpServer(server);
    });

    it('returns false when user has no socket (offline)', async () => {
      const user = await createTestUser('client', 'offline');
      expect(await SocketService.isUserOnline(String(user._id))).toBe(false);
    });

    it('returns true when user has one connected socket (online)', async () => {
      const user = await createTestUser('client', 'online');
      const token = generateAccessToken(user._id, 'client');
      const socket = trackSocket(socketClients, ioClient(baseUrl, {
        transports: ['websocket'],
        auth: { token },
        forceNew: true,
        reconnection: false,
      }));
      const authPromise = waitForEvent(socket, 'socket_authenticated');
      await waitForConnect(socket);
      await authPromise;

      expect(await SocketService.isUserOnline(String(user._id))).toBe(true);

      await closeSocketClient(socket);
      await new Promise((r) => setTimeout(r, 100));
      expect(await SocketService.isUserOnline(String(user._id))).toBe(false);
    });

    it('stays online with multiple sockets until last disconnect', async () => {
      const user = await createTestUser('client', 'multi');
      const token = generateAccessToken(user._id, 'client');
      const socketA = trackSocket(socketClients, ioClient(baseUrl, {
        transports: ['websocket'],
        auth: { token },
        forceNew: true,
        reconnection: false,
      }));
      const socketB = trackSocket(socketClients, ioClient(baseUrl, {
        transports: ['websocket'],
        auth: { token },
        forceNew: true,
        reconnection: false,
      }));

      await Promise.all([waitForConnect(socketA), waitForConnect(socketB)]);
      expect(await SocketService.isUserOnline(String(user._id))).toBe(true);

      await closeSocketClient(socketA);
      await new Promise((r) => setTimeout(r, 100));
      expect(await SocketService.isUserOnline(String(user._id))).toBe(true);

      await closeSocketClient(socketB);
      await new Promise((r) => setTimeout(r, 100));
      expect(await SocketService.isUserOnline(String(user._id))).toBe(false);
    });

    it('presence lookup failure → treats as offline (push allowed)', async () => {
      const user = await createTestUser('client', 'fail');
      const token = generateAccessToken(user._id, 'client');
      const socket = trackSocket(socketClients, ioClient(baseUrl, {
        transports: ['websocket'],
        auth: { token },
        forceNew: true,
        reconnection: false,
      }));
      await waitForConnect(socket);

      const ioInstance = SocketService.initialize(server);
      jest.spyOn(ioInstance, 'in').mockImplementation(() => ({
        fetchSockets: () => Promise.reject(new Error('REDIS_ADAPTER_DOWN')),
      }));

      expect(await SocketService.isUserOnline(String(user._id))).toBe(false);
      expect(await shouldSendOfflinePush(String(user._id))).toBe(true);

      jest.restoreAllMocks();
      await closeSocketClient(socket);
    });

    it('presence timeout → treats as offline (push allowed)', async () => {
      const user = await createTestUser('client', 'timeout');
      const prev = process.env.SOCKET_PRESENCE_TIMEOUT_MS;
      process.env.SOCKET_PRESENCE_TIMEOUT_MS = '50';

      const ioInstance = SocketService.initialize(server);
      jest.spyOn(ioInstance, 'in').mockImplementation(() => ({
        fetchSockets: () => new Promise(() => {}),
      }));

      expect(await SocketService.isUserOnline(String(user._id))).toBe(false);

      jest.restoreAllMocks();
      process.env.SOCKET_PRESENCE_TIMEOUT_MS = prev;
    });
  });

  describe('Redis adapter — cross-worker fetchSockets', () => {
    let serverA;
    let serverB;
    let ioA;
    let ioB;
    let urlA;
    let urlB;
    /** @type {import('ioredis').Redis[]} */
    let redisClients;
    /** @type {import('socket.io-client').Socket[]} */
    let socketClients;

    beforeAll(async () => {
      socketClients = [];
      const pubClient = new Redis();
      const subClient = pubClient.duplicate();
      const pubClientB = pubClient.duplicate();
      const subClientB = pubClient.duplicate();
      redisClients = [pubClient, subClient, pubClientB, subClientB];

      serverA = http.createServer();
      serverB = http.createServer();
      await Promise.all([
        new Promise((resolve) => serverA.listen(0, resolve)),
        new Promise((resolve) => serverB.listen(0, resolve)),
      ]);

      urlA = `http://127.0.0.1:${serverA.address().port}`;
      urlB = `http://127.0.0.1:${serverB.address().port}`;

      ioA = socketIO(serverA, { cors: { origin: '*' } });
      ioB = socketIO(serverB, { cors: { origin: '*' } });
      ioA.adapter(createAdapter(pubClient, subClient));
      ioB.adapter(createAdapter(pubClientB, subClientB));

      ioA.on('connection', (socket) => {
        const userId = socket.handshake.auth?.userId;
        if (userId) {
          socket.join(`user_${userId}`);
        }
      });
      ioB.on('connection', (socket) => {
        const userId = socket.handshake.auth?.userId;
        if (userId) {
          socket.join(`user_${userId}`);
        }
      });
    });

    afterAll(async () => {
      for (const socket of socketClients) {
        await closeSocketClient(socket);
      }
      await closeSocketIo(ioA);
      await closeSocketIo(ioB);
      await closeHttpServer(serverA);
      await closeHttpServer(serverB);
      for (const client of redisClients) {
        await quitRedisClient(client);
      }
    });

    it('user connected on worker B is online when queried from worker A', async () => {
      const userId = new mongoose.Types.ObjectId().toString();
      const clientOnB = trackSocket(socketClients, ioClient(urlB, {
        transports: ['websocket'],
        auth: { userId },
        forceNew: true,
        reconnection: false,
      }));
      await waitForConnect(clientOnB);
      await waitUntil(async () => {
        const sockets = await ioA.in(`user_${userId}`).fetchSockets();
        return sockets.length > 0;
      });

      const socketsFromA = await ioA.in(`user_${userId}`).fetchSockets();
      expect(socketsFromA.length).toBeGreaterThan(0);

      await closeSocketClient(clientOnB);
      await waitUntil(async () => {
        const sockets = await ioA.in(`user_${userId}`).fetchSockets();
        return sockets.length === 0;
      });
      const socketsAfter = await ioA.in(`user_${userId}`).fetchSockets();
      expect(socketsAfter.length).toBe(0);
    });
  });

  describe('push fallback decision', () => {
    let server;
    let baseUrl;
    let sendPushSpy;
    /** @type {import('socket.io-client').Socket[]} */
    let socketClients;

    beforeAll(async () => {
      socketClients = [];
      server = http.createServer();
      await new Promise((resolve) => server.listen(0, resolve));
      baseUrl = `http://127.0.0.1:${server.address().port}`;
      SocketService.initialize(server);
    });

    afterAll(async () => {
      for (const socket of socketClients) {
        await closeSocketClient(socket);
      }
      await SocketService.close();
      await closeHttpServer(server);
    });

    beforeEach(() => {
      sendPushSpy = jest.spyOn(oneSignalService, 'sendToMultipleUsers').mockResolvedValue({
        success: true,
        status: 'sent',
        providerId: 'os-p2-06d',
        recipients: 1,
        invalidSubscriptionIds: [],
      });
      jest.spyOn(require('../../../src/services/email.service'), 'sendNotificationEmail')
        .mockResolvedValue(undefined);
    });

    afterEach(() => {
      jest.restoreAllMocks();
    });

    it('online recipient → no offline push', async () => {
      const recipient = await createTestUser('client', 'push-online');
      await User.updateOne(
        { _id: recipient._id },
        { $set: { deviceTokens: ['aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee-111111111111'] } }
      );

      const token = generateAccessToken(recipient._id, 'client');
      const socket = trackSocket(socketClients, ioClient(baseUrl, {
        transports: ['websocket'],
        auth: { token },
        forceNew: true,
        reconnection: false,
      }));
      const authPromise = waitForEvent(socket, 'socket_authenticated');
      await waitForConnect(socket);
      await authPromise;

      const pushNeeded = await shouldSendOfflinePush(String(recipient._id));
      expect(pushNeeded).toBe(false);

      if (pushNeeded) {
        await notificationService.createNotification(
          recipient._id,
          COMMON.NEW_MESSAGE,
          'Test message'
        );
      }
      expect(sendPushSpy).not.toHaveBeenCalled();

      await closeSocketClient(socket);
    });

    it('offline recipient → push via notification hub', async () => {
      const recipient = await createTestUser('client', 'push-offline');
      await User.updateOne(
        { _id: recipient._id },
        { $set: { deviceTokens: ['bbbbbbbb-cccc-dddd-eeee-ffff-ffffffffffff-222222222222'] } }
      );

      const pushNeeded = await shouldSendOfflinePush(String(recipient._id));
      expect(pushNeeded).toBe(true);

      await notificationService.createNotification(
        recipient._id,
        COMMON.NEW_MESSAGE,
        'Test offline message'
      );
      expect(sendPushSpy).toHaveBeenCalledTimes(1);
    });

    it('messages category OFF → no push even if offline (P2-06C regression)', async () => {
      const recipient = await createTestUser('client', 'pref-off');
      await User.updateOne(
        { _id: recipient._id },
        {
          $set: {
            deviceTokens: ['cccccccc-dddd-eeee-ffff-aaaa-aaaaaaaaaaaa-333333333333'],
            'notificationSettings.pushEnabled': true,
            'notificationSettings.categories.messages': false,
          },
        }
      );

      expect(await shouldSendOfflinePush(String(recipient._id))).toBe(true);

      await notificationService.createNotification(
        recipient._id,
        COMMON.NEW_MESSAGE,
        'Should not push'
      );
      expect(sendPushSpy).not.toHaveBeenCalled();
    });
  });
});
