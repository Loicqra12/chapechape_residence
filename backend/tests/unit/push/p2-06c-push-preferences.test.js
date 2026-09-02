/**
 * P2-06C — Push preferences, device tokens, OneSignal transport correctness
 */
const request = require('supertest');
const app = require('../../../src/app');
const User = require('../../../src/models/user.model');
const Notification = require('../../../src/models/notification.model');
const notificationService = require('../../../src/services/notification.service');
const oneSignalService = require('../../../src/services/onesignal.service');
const {
  parseInvalidSubscriptionIds,
  classifyProviderFailure,
} = require('../../../src/services/onesignal.service');
const { registerDeviceTokenAtomic } = require('../../../src/controllers/device.controller');
const notificationTypes = require('../../../src/utils/notification-types');
const { generateAccessToken } = require('../../../src/utils/jwt');

jest.setTimeout(120000);

const VALID_TOKEN_A = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee-111111111111';
const VALID_TOKEN_B = 'bbbbbbbb-cccc-dddd-eeee-ffff-ffffffffffff-222222222222';
const VALID_TOKEN_C = 'cccccccc-dddd-eeee-ffff-aaaa-aaaaaaaaaaaa-333333333333';
const VALID_TOKEN_D = 'dddddddd-eeee-ffff-aaaa-bbbb-bbbbbbbbbbbb-444444444444';
const VALID_TOKEN_E = 'eeeeeeee-ffff-aaaa-bbbb-cccc-cccccccccccc-555555555555';
const VALID_TOKEN_Z = 'ffffffff-aaaa-bbbb-cccc-dddd-dddddddddddd-666666666666';

const VALID_CATEGORIES = new Set(['bookings', 'messages', 'payments', 'promotions', 'system']);

async function createUser(role, suffix = '', extra = {}) {
  return User.create({
    email: `${role}-p2-06c-${suffix}-${Date.now()}-${Math.random()}@test.com`,
    password: 'Test1234!',
    firstName: role,
    lastName: 'Test',
    role,
    deviceTokens: [],
    ...extra,
  });
}

function authHeader(user) {
  return `Bearer ${generateAccessToken(user._id, user.role)}`;
}

async function countUsersWithToken(token) {
  return User.countDocuments({ deviceTokens: token });
}

describe('P2-06C push / preferences / device tokens', () => {
  let sendPushSpy;

  beforeAll(async () => {
    await User.syncIndexes();
  });

  beforeEach(() => {
    sendPushSpy = jest.spyOn(oneSignalService, 'sendToMultipleUsers').mockResolvedValue({
      success: true,
      status: 'sent',
      providerId: 'os-notif-1',
      recipients: 1,
      invalidSubscriptionIds: [],
    });
    jest.spyOn(require('../../../src/services/email.service'), 'sendNotificationEmail')
      .mockResolvedValue(undefined);
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('preference contract — push category enforcement', () => {
    it('pushEnabled=false → Mongo created, push skipped', async () => {
      const user = await createUser('client', 'push-off');
      await User.updateOne(
        { _id: user._id },
        {
          $set: {
            deviceTokens: [VALID_TOKEN_A],
            'notificationSettings.pushEnabled': false,
          },
        }
      );

      const notif = await notificationService.createNotification(
        user._id,
        notificationTypes.CLIENT.BOOKING_CONFIRMED,
        'Confirmé'
      );

      expect(notif).toBeTruthy();
      expect(await Notification.countDocuments({ user: user._id })).toBe(1);
      expect(sendPushSpy).not.toHaveBeenCalled();
    });

    it('categories.bookings=false → Mongo created, push skipped', async () => {
      const user = await createUser('client', 'bookings-off');
      await User.updateOne(
        { _id: user._id },
        {
          $set: {
            deviceTokens: [VALID_TOKEN_A],
            'notificationSettings.pushEnabled': true,
            'notificationSettings.categories.bookings': false,
          },
        }
      );

      await notificationService.createNotification(
        user._id,
        notificationTypes.CLIENT.BOOKING_CONFIRMED,
        'Confirmé'
      );

      expect(sendPushSpy).not.toHaveBeenCalled();
      expect(await Notification.countDocuments({ user: user._id })).toBe(1);
    });

    it('categories.promotions=false blocks promotion type only', async () => {
      const user = await createUser('client', 'promo-off');
      await User.updateOne(
        { _id: user._id },
        {
          $set: {
            deviceTokens: [VALID_TOKEN_A],
            'notificationSettings.categories.promotions': false,
          },
        }
      );

      await notificationService.createNotification(
        user._id,
        notificationTypes.CLIENT.REENGAGE,
        'Reengage'
      );
      expect(sendPushSpy).not.toHaveBeenCalled();

      sendPushSpy.mockClear();
      await notificationService.createNotification(
        user._id,
        notificationTypes.CLIENT.BOOKING_CONFIRMED,
        'Confirmé'
      );
      expect(sendPushSpy).toHaveBeenCalledTimes(1);
    });

    it('emailEnabled=false does not block push', async () => {
      const user = await createUser('client', 'email-off');
      await User.updateOne(
        { _id: user._id },
        {
          $set: {
            deviceTokens: [VALID_TOKEN_A],
            'notificationSettings.emailEnabled': false,
          },
        }
      );

      await notificationService.createNotification(
        user._id,
        notificationTypes.CLIENT.BOOKING_CONFIRMED,
        'Confirmé'
      );

      expect(sendPushSpy).toHaveBeenCalledTimes(1);
    });

    it('legacy user without categories → push allowed (schema defaults)', async () => {
      const user = await createUser('client', 'legacy');
      await User.updateOne(
        { _id: user._id },
        {
          $set: { deviceTokens: [VALID_TOKEN_A], notificationSettings: { pushEnabled: true } },
        }
      );

      await notificationService.createNotification(
        user._id,
        notificationTypes.CLIENT.BOOKING_CONFIRMED,
        'Confirmé'
      );
      expect(sendPushSpy).toHaveBeenCalledTimes(1);
    });

    it('security alert maps to system category, not promotions', async () => {
      expect(notificationTypes.getCategoryByNotificationType(
        notificationTypes.CLIENT.SECURITY_ALERT
      )).toBe('system');
      expect(notificationTypes.getCategoryByNotificationType(
        notificationTypes.CLIENT.LOGIN_ALERT
      )).toBe('system');
    });
  });

  describe('OneSignal invalid token cleanup', () => {
    it('parses invalid_player_ids from provider response object', () => {
      const ids = parseInvalidSubscriptionIds({
        id: 'n1',
        errors: {
          invalid_player_ids: [VALID_TOKEN_B],
        },
      });
      expect(ids).toEqual([VALID_TOKEN_B]);
    });

    it('parses invalid_subscription_ids from provider response object', () => {
      const ids = parseInvalidSubscriptionIds({
        id: 'n1',
        errors: {
          invalid_subscription_ids: [VALID_TOKEN_B],
        },
      });
      expect(ids).toEqual([VALID_TOKEN_B]);
    });

    it('does not treat no_recipients string errors as invalid ids', () => {
      const ids = parseInvalidSubscriptionIds({
        id: '',
        errors: ['All included players are not subscribed'],
      });
      expect(ids).toEqual([]);
    });

    it('mixed batch — invalid token purged, valid kept', async () => {
      const user = await createUser('client', 'mixed-batch');
      await User.updateOne(
        { _id: user._id },
        { $set: { deviceTokens: [VALID_TOKEN_A, VALID_TOKEN_B] } }
      );

      sendPushSpy.mockResolvedValueOnce({
        success: true,
        status: 'sent',
        providerId: 'n2',
        recipients: 1,
        invalidSubscriptionIds: [VALID_TOKEN_B],
      });

      await notificationService.createNotification(
        user._id,
        notificationTypes.CLIENT.BOOKING_CONFIRMED,
        'Confirmé'
      );

      const fresh = await User.findById(user._id);
      expect(fresh.deviceTokens).toContain(VALID_TOKEN_A);
      expect(fresh.deviceTokens).not.toContain(VALID_TOKEN_B);
    });

    it('temporary 429 failure → tokens kept', async () => {
      const user = await createUser('client', '429');
      await User.updateOne(
        { _id: user._id },
        { $set: { deviceTokens: [VALID_TOKEN_A] } }
      );

      const err = new Error('rate limited');
      err.response = { status: 429 };
      sendPushSpy.mockRejectedValueOnce(err);

      const classification = classifyProviderFailure(err);
      expect(classification.kind).toBe('rate_limit');
      expect(classification.retryable).toBe(true);

      await notificationService.createNotification(
        user._id,
        notificationTypes.CLIENT.BOOKING_CONFIRMED,
        'Confirmé'
      );

      const fresh = await User.findById(user._id);
      expect(fresh.deviceTokens).toContain(VALID_TOKEN_A);
      expect(await Notification.countDocuments({ user: user._id })).toBe(1);
    });

    it('500 provider error → tokens kept', async () => {
      const user = await createUser('client', '500');
      await User.updateOne({ _id: user._id }, { $set: { deviceTokens: [VALID_TOKEN_A] } });

      sendPushSpy.mockResolvedValueOnce({
        success: false,
        status: 'provider_5xx',
        reason: 'server error',
        recipients: 0,
      });

      await notificationService.createNotification(
        user._id,
        notificationTypes.CLIENT.BOOKING_CONFIRMED,
        'Confirmé'
      );

      expect((await User.findById(user._id)).deviceTokens).toContain(VALID_TOKEN_A);
    });

    it('no_recipients response → tokens kept', async () => {
      const user = await createUser('client', 'no-recip');
      await User.updateOne({ _id: user._id }, { $set: { deviceTokens: [VALID_TOKEN_A] } });

      sendPushSpy.mockResolvedValueOnce({
        success: false,
        status: 'skipped',
        reason: 'no_recipients',
        recipients: 0,
      });

      await notificationService.createNotification(
        user._id,
        notificationTypes.CLIENT.BOOKING_CONFIRMED,
        'Confirmé'
      );

      expect((await User.findById(user._id)).deviceTokens).toContain(VALID_TOKEN_A);
    });
  });

  describe('category mapping matrix', () => {
    it('every active notification type maps to a valid push category', () => {
      const { COMMON, PARTNER, CLIENT } = notificationTypes;
      const activeTypes = [
        ...Object.values(COMMON),
        ...Object.values(PARTNER),
        ...Object.values(CLIENT),
      ];

      for (const type of activeTypes) {
        const category = notificationTypes.getCategoryByNotificationType(type);
        expect(category).toBeTruthy();
        expect(VALID_CATEGORIES.has(category)).toBe(true);
      }
    });
  });

  describe('device token unique index integration', () => {
    it('allows many legacy users with empty deviceTokens arrays', async () => {
      const legacy = await Promise.all(
        Array.from({ length: 20 }, (_, i) => createUser('client', `legacy-${i}`, {
          deviceTokens: [],
        }))
      );
      expect(legacy).toHaveLength(20);
    });

    it('rejects cross-user duplicate token at DB level (E11000)', async () => {
      const userA = await createUser('client', 'idx-a');
      const userB = await createUser('client', 'idx-b');
      await User.updateOne({ _id: userA._id }, { $addToSet: { deviceTokens: VALID_TOKEN_D } });

      await expect(
        User.updateOne({ _id: userB._id }, { $addToSet: { deviceTokens: VALID_TOKEN_D } })
      ).rejects.toMatchObject({ code: 11000 });
    });

    it('allows multiple distinct tokens on same user', async () => {
      const user = await createUser('client', 'idx-multi');
      await User.updateOne(
        { _id: user._id },
        { $addToSet: { deviceTokens: { $each: [VALID_TOKEN_D, VALID_TOKEN_E] } } }
      );
      const fresh = await User.findById(user._id);
      expect(fresh.deviceTokens).toEqual(expect.arrayContaining([VALID_TOKEN_D, VALID_TOKEN_E]));
    });
  });

  describe('device registration', () => {
    it('register via API attaches token to authenticated user', async () => {
      const user = await createUser('client', 'reg');
      const res = await request(app)
        .post('/api/devices/register')
        .set('Authorization', authHeader(user))
        .send({ deviceToken: VALID_TOKEN_A, appKind: 'client', platform: 'android' });

      expect(res.status).toBe(200);
      expect(res.body.data.deviceTokens).toContain(VALID_TOKEN_A);
    });

    it('transfer token from user A to user B', async () => {
      const userA = await createUser('client', 'a');
      const userB = await createUser('client', 'b');

      await registerDeviceTokenAtomic(userA._id, VALID_TOKEN_A);
      await registerDeviceTokenAtomic(userB._id, VALID_TOKEN_A);

      expect(await countUsersWithToken(VALID_TOKEN_A)).toBe(1);
      const owner = await User.findOne({ deviceTokens: VALID_TOKEN_A });
      expect(String(owner._id)).toBe(String(userB._id));
    });

    it('sequential transfer A → B → A (last registration wins)', async () => {
      const userA = await createUser('client', 'seq-a');
      const userB = await createUser('client', 'seq-b');

      await registerDeviceTokenAtomic(userA._id, VALID_TOKEN_B);
      expect(String((await User.findOne({ deviceTokens: VALID_TOKEN_B }))._id)).toBe(String(userA._id));

      await registerDeviceTokenAtomic(userB._id, VALID_TOKEN_B);
      expect(String((await User.findOne({ deviceTokens: VALID_TOKEN_B }))._id)).toBe(String(userB._id));

      await registerDeviceTokenAtomic(userA._id, VALID_TOKEN_B);
      expect(String((await User.findOne({ deviceTokens: VALID_TOKEN_B }))._id)).toBe(String(userA._id));
      expect(await countUsersWithToken(VALID_TOKEN_B)).toBe(1);
    });

    it('multi-device — same user keeps X, Y and Z', async () => {
      const user = await createUser('partner', 'multi-xyz');
      await registerDeviceTokenAtomic(user._id, VALID_TOKEN_A);
      await registerDeviceTokenAtomic(user._id, VALID_TOKEN_B);
      await registerDeviceTokenAtomic(user._id, VALID_TOKEN_Z);

      const fresh = await User.findById(user._id);
      expect(fresh.deviceTokens).toEqual(expect.arrayContaining([
        VALID_TOKEN_A,
        VALID_TOKEN_B,
        VALID_TOKEN_Z,
      ]));
    });

    it('20 concurrent same-token same-user → token appears once', async () => {
      const user = await createUser('client', 'same-user-race');
      const settled = await Promise.allSettled(
        Array.from({ length: 20 }, () => registerDeviceTokenAtomic(user._id, VALID_TOKEN_D))
      );
      expect(settled.filter((r) => r.status === 'fulfilled').length).toBeGreaterThan(0);
      const fresh = await User.findById(user._id);
      expect(fresh.deviceTokens.filter((t) => t === VALID_TOKEN_D)).toHaveLength(1);
    });

    it('unregister removes token', async () => {
      const user = await createUser('client', 'unreg');
      await registerDeviceTokenAtomic(user._id, VALID_TOKEN_A);

      const res = await request(app)
        .delete('/api/devices/unregister')
        .set('Authorization', authHeader(user))
        .send({ deviceToken: VALID_TOKEN_A });

      expect(res.status).toBe(200);
      expect(res.body.data.deviceTokens).not.toContain(VALID_TOKEN_A);
    });

    it('20 concurrent same-token registrations → token on exactly one user', async () => {
      const InventoryLock = require('../../../src/models/inventory-lock.model');
      const users = await Promise.all(
        Array.from({ length: 10 }, (_, i) => createUser('client', `race-${i}`))
      );

      const attempts = 20;
      const settled = await Promise.allSettled(
        Array.from({ length: attempts }, (_, i) => {
          const owner = users[i % users.length];
          return registerDeviceTokenAtomic(owner._id, VALID_TOKEN_C);
        })
      );

      expect(settled).toHaveLength(attempts);
      expect(await countUsersWithToken(VALID_TOKEN_C)).toBe(1);
      expect(await InventoryLock.countDocuments({ key: { $regex: /^device:/ } })).toBe(0);

      const owners = await User.find({ deviceTokens: VALID_TOKEN_C }).select('_id');
      expect(owners).toHaveLength(1);
    });
  });

  describe('preferences API contract', () => {
    it('PUT /devices/preferences accepts canonical category keys', async () => {
      const user = await createUser('client', 'prefs');
      const res = await request(app)
        .put('/api/devices/preferences')
        .set('Authorization', authHeader(user))
        .send({
          pushEnabled: true,
          emailEnabled: false,
          categories: {
            bookings: false,
            messages: true,
            payments: true,
            promotions: false,
            system: true,
          },
        });

      expect(res.status).toBe(200);
      expect(res.body.data.notificationSettings.categories.bookings).toBe(false);
      expect(res.body.data.notificationSettings.emailEnabled).toBe(false);
    });
  });
});
