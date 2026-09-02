/**
 * P2-07F FINAL — Enum contract / behavior compatibility gate
 */
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const mongoose = require('mongoose');
const Notification = require('../../../src/models/notification.model');
const notificationTypes = require('../../../src/utils/notification-types');
const notificationService = require('../../../src/services/notification.service');
const oneSignalService = require('../../../src/services/onesignal.service');
const User = require('../../../src/models/user.model');

jest.setTimeout(180000);

const VALID_CATEGORIES = new Set(['bookings', 'messages', 'payments', 'promotions', 'system']);
const REPO_ROOT = path.join(__dirname, '../../../..');
const BACKEND_ROOT = path.join(__dirname, '../../..');

function loadHeadFile(relativePath) {
  const full = relativePath.replace(/\\/g, '/');
  const out = execSync(`git show HEAD:${full}`, { cwd: REPO_ROOT, encoding: 'utf8' });
  return out;
}

function evalHeadConstants() {
  const src = loadHeadFile('backend/src/utils/constants.js');
  const sandbox = { exports: {} };
  // eslint-disable-next-line no-eval
  eval(src.replace(/^exports\./gm, 'sandbox.exports.'));
  return sandbox.exports;
}

function evalHeadNotificationTypes() {
  const src = loadHeadFile('backend/src/utils/notification-types.js');
  const sandbox = { module: { exports: {} } };
  // eslint-disable-next-line no-new-func
  new Function('module', 'exports', src)(sandbox.module, sandbox.module.exports);
  return sandbox.module.exports;
}

function buildBeforeAllowedEnum() {
  const constants = evalHeadConstants();
  const headTypes = evalHeadNotificationTypes();
  return [
    ...Object.values(constants.NOTIFICATION_TYPES),
    ...Object.values(headTypes.COMMON),
    ...Object.values(headTypes.PARTNER),
    ...Object.values(headTypes.CLIENT),
  ];
}

function buildBeforeSchema() {
  const allowed = [...new Set(buildBeforeAllowedEnum())];
  return new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, required: true },
    type: { type: String, enum: allowed, required: true },
    message: { type: String, required: true },
  });
}

async function validateTypeAgainstSchema(schema, type, userId) {
  const Model = mongoose.models.BeforeNotificationGate ||
    mongoose.model('BeforeNotificationGate', schema);
  const doc = new Model({ user: userId, type, message: 'gate' });
  try {
    await doc.validate();
    return { accepted: true, error: null };
  } catch (err) {
    return { accepted: false, error: err.message };
  }
}

describe('P2-07F FINAL compatibility gate', () => {
  let userId;
  let sendPushSpy;
  let emailSpy;

  beforeAll(async () => {
    const user = await User.create({
      email: `p2-07f-gate-${Date.now()}@test.com`,
      password: 'Test1234!',
      firstName: 'Gate',
      lastName: 'P2-07F',
      role: 'client',
      deviceTokens: ['aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee-111111111111'],
    });
    userId = user._id;
  });

  beforeEach(() => {
    sendPushSpy = jest.spyOn(oneSignalService, 'sendToMultipleUsers').mockResolvedValue({
      success: true,
      status: 'sent',
      providerId: 'os-gate-1',
      recipients: 1,
      invalidSubscriptionIds: [],
    });
    emailSpy = jest.spyOn(require('../../../src/services/email.service'), 'sendNotificationEmail')
      .mockResolvedValue(undefined);
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('enum before/after reconstruction from git HEAD diff', () => {
    it('reconstructs exact BEFORE and AFTER sets', () => {
      const before = [...new Set(buildBeforeAllowedEnum())].sort();
      const after = [...notificationTypes.ALLOWED_NOTIFICATION_TYPES].sort();
      const beforeSet = new Set(before);
      const afterSet = new Set(after);
      const newlyAccepted = after.filter((v) => !beforeSet.has(v));
      const removed = before.filter((v) => !afterSet.has(v));

      expect(before.length).toBe(59);
      expect(after.length).toBe(63);
      expect(newlyAccepted.sort()).toEqual([
        'booking_update',
        'client_payment_refund',
        'payment_required',
        'reservation_request_expired',
      ]);
      expect(removed).toEqual([]);
    });
  });

  describe('mongoose characterization — before schema vs after schema', () => {
    let beforeSchema;

    beforeAll(() => {
      beforeSchema = buildBeforeSchema();
    });

    const cases = [
      { type: 'favorite_added', label: 'favorite_added' },
      { type: 'favorite_status_changed', label: 'favorite_status_changed' },
      { type: 'booking_update', label: 'booking_update' },
      { type: 'payment_required', label: 'payment_required' },
      { type: 'booking_confirmed', label: 'booking_confirmed' },
    ];

    it.each(cases)('$label before/after acceptance', async ({ type }) => {
      const before = await validateTypeAgainstSchema(beforeSchema, type, userId);
      const afterDoc = new Notification({ user: userId, type, message: 'after' });
      let afterAccepted = true;
      try {
        await afterDoc.validate();
      } catch (err) {
        afterAccepted = false;
      }

      if (type === 'favorite_added' || type === 'favorite_status_changed' || type === 'booking_confirmed') {
        expect(before.accepted).toBe(true);
        expect(afterAccepted).toBe(true);
      } else {
        expect(before.accepted).toBe(false);
        expect(afterAccepted).toBe(true);
      }
    });

    it('undefined type rejected before and after (SMS bug characterization)', async () => {
      const headConstants = evalHeadConstants();
      expect(headConstants.NOTIFICATION_TYPES.BOOKING_UPDATE).toBeUndefined();
      expect(headConstants.NOTIFICATION_TYPES.PAYMENT_REQUIRED).toBeUndefined();

      const beforeUndefined = await validateTypeAgainstSchema(beforeSchema, undefined, userId);
      expect(beforeUndefined.accepted).toBe(false);

      const afterDoc = new Notification({ user: userId, type: undefined, message: 'x' });
      await expect(afterDoc.validate()).rejects.toThrow();
    });
  });

  describe('unknown raw document hydrate (read vs write)', () => {
    const UNKNOWN = '__legacy_unknown_test__';

    afterAll(async () => {
      await mongoose.connection.db
        .collection('notifications')
        .deleteOne({ type: UNKNOWN });
    });

    it('hydrates unknown type inserted via native collection; write still rejected', async () => {
      await mongoose.connection.db.collection('notifications').insertOne({
        user: userId,
        type: UNKNOWN,
        message: 'native insert',
        read: false,
        createdAt: new Date(),
      });

      const hydrated = await Notification.findOne({ type: UNKNOWN });
      expect(hydrated).toBeTruthy();
      expect(hydrated.type).toBe(UNKNOWN);

      const invalidWrite = new Notification({
        user: userId,
        type: UNKNOWN,
        message: 'should fail enum',
      });
      await expect(invalidWrite.validate()).rejects.toThrow(/enum/);
    });
  });

  describe('favorite flow — before parity preserved, channels intact', () => {
    it('persists favorite_added with system category; push skipped when pushEnabled=false', async () => {
      await User.updateOne(
        { _id: userId },
        {
          $set: {
            deviceTokens: ['aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee-111111111111'],
            'notificationSettings.pushEnabled': false,
            'notificationSettings.emailEnabled': true,
            'notificationSettings.categories.system': true,
          },
        }
      );

      sendPushSpy.mockClear();

      const notif = await notificationService.createNotification(
        userId,
        notificationTypes.LEGACY.FAVORITE_ADDED,
        'Favori ajouté gate',
        { residenceId: new mongoose.Types.ObjectId() }
      );

      expect(notif.type).toBe('favorite_added');
      expect(notificationTypes.getCategoryByNotificationType(notif.type)).toBe('system');
      expect(sendPushSpy).not.toHaveBeenCalled();
    });

    it('email skipped when emailEnabled=false but Mongo persists', async () => {
      await User.updateOne(
        { _id: userId },
        { $set: { 'notificationSettings.emailEnabled': false } }
      );
      emailSpy.mockClear();

      await notificationService.createNotification(
        userId,
        notificationTypes.LEGACY.FAVORITE_ADDED,
        'Favori email-off gate'
      );

      expect(emailSpy).not.toHaveBeenCalled();
      expect(
        await Notification.countDocuments({ user: userId, type: 'favorite_added' })
      ).toBeGreaterThan(0);
    });

    it('favorite_status_changed blocks push when system category disabled', async () => {
      await User.updateOne(
        { _id: userId },
        {
          $set: {
            deviceTokens: ['aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee-111111111111'],
            'notificationSettings.pushEnabled': true,
            'notificationSettings.categories.system': false,
          },
        }
      );

      sendPushSpy.mockClear();
      await notificationService.createNotification(
        userId,
        notificationTypes.LEGACY.FAVORITE_STATUS_CHANGED,
        'Favori retiré gate'
      );

      expect(sendPushSpy).not.toHaveBeenCalled();
      const saved = await Notification.findOne({
        user: userId,
        type: 'favorite_status_changed',
      }).sort({ createdAt: -1 });
      expect(saved).toBeTruthy();
    });
  });

  describe('SMS BOOKING_UPDATE / PAYMENT_REQUIRED bugfix behavior', () => {
    it('BOOKING_UPDATE persists Mongo, respects push prefs, does not duplicate producers', async () => {
      await User.updateOne(
        { _id: userId },
        {
          $set: {
            deviceTokens: ['aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee-111111111111'],
            'notificationSettings.pushEnabled': true,
            'notificationSettings.categories.bookings': false,
          },
        }
      );

      sendPushSpy.mockClear();
      const notif = await notificationService.createNotification(
        userId,
        notificationTypes.LEGACY.BOOKING_UPDATE,
        'Réservation mise à jour gate',
        { bookingId: new mongoose.Types.ObjectId() }
      );

      expect(notif.type).toBe('booking_update');
      expect(sendPushSpy).not.toHaveBeenCalled();
      expect(notificationTypes.getCategoryByNotificationType('booking_update')).toBe('bookings');
    });

    it('PAYMENT_REQUIRED persists Mongo, blocks push when payments category off', async () => {
      await User.updateOne(
        { _id: userId },
        {
          $set: {
            deviceTokens: ['aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee-111111111111'],
            'notificationSettings.pushEnabled': true,
            'notificationSettings.categories.payments': false,
          },
        }
      );

      sendPushSpy.mockClear();
      const notif = await notificationService.createNotification(
        userId,
        notificationTypes.LEGACY.PAYMENT_REQUIRED,
        'Paiement requis gate',
        { bookingId: new mongoose.Types.ObjectId() }
      );

      expect(notif.type).toBe('payment_required');
      expect(sendPushSpy).not.toHaveBeenCalled();
    });

    it('no duplicate producers for booking_update / payment_required in backend src', () => {
      const srcRoot = path.join(BACKEND_ROOT, 'src');
      const hits = [];
      const walk = (dir) => {
        for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
          const p = path.join(dir, entry.name);
          if (entry.isDirectory()) walk(p);
          else if (entry.name.endsWith('.js')) {
            const text = fs.readFileSync(p, 'utf8');
            if (text.includes("'booking_update'") || text.includes('BOOKING_UPDATE')) {
              hits.push({ file: path.relative(BACKEND_ROOT, p), kind: 'booking_update' });
            }
            if (text.includes("'payment_required'") || text.includes('PAYMENT_REQUIRED')) {
              hits.push({ file: path.relative(BACKEND_ROOT, p), kind: 'payment_required' });
            }
          }
        }
      };
      walk(srcRoot);

      const bookingProducers = hits.filter((h) => h.kind === 'booking_update');
      const paymentProducers = hits.filter((h) => h.kind === 'payment_required');
      expect(bookingProducers.some((h) => h.file.includes('sms.controller.js'))).toBe(true);
      expect(paymentProducers.some((h) => h.file.includes('sms.controller.js'))).toBe(true);
      expect(bookingProducers.filter((h) => h.file.includes('controller')).length).toBe(1);
      expect(paymentProducers.filter((h) => h.file.includes('controller')).length).toBe(1);
    });
  });

  describe('60-type matrix and canonical coverage', () => {
    it('ALLOWED_NOTIFICATION_TYPES — 63 unique, schema + category valid', async () => {
      const allowed = notificationTypes.ALLOWED_NOTIFICATION_TYPES;
      expect(allowed.length).toBe(63);
      expect(new Set(allowed).size).toBe(63);

      for (const type of allowed) {
        const doc = new Notification({ user: userId, type, message: `matrix ${type}` });
        await expect(doc.validate()).resolves.toBeUndefined();
        const category = notificationTypes.getCategoryByNotificationType(type);
        expect(VALID_CATEGORIES.has(category)).toBe(true);
      }
    });

    it('canonical COMMON+PARTNER+CLIENT — schema + category valid', async () => {
      const canonical = [
        ...Object.values(notificationTypes.COMMON),
        ...Object.values(notificationTypes.PARTNER),
        ...Object.values(notificationTypes.CLIENT),
      ];
      expect(canonical.length).toBe(50);
      expect(new Set(canonical).size).toBe(50);

      for (const type of canonical) {
        const doc = new Notification({ user: userId, type, message: `canon ${type}` });
        await expect(doc.validate()).resolves.toBeUndefined();
        expect(VALID_CATEGORIES.has(notificationTypes.getCategoryByNotificationType(type))).toBe(true);
      }
    });
  });

  describe('swagger exact match to ALLOWED_NOTIFICATION_TYPES', () => {
    it('swagger enum set equals ALLOWED_NOTIFICATION_TYPES exactly', () => {
      const swaggerPath = path.join(BACKEND_ROOT, 'src/swagger/schemas/notification.schema.js');
      const source = fs.readFileSync(swaggerPath, 'utf8');
      const match = source.match(/enum:\s*\[([^\]]+)\]/);
      expect(match).toBeTruthy();
      const swaggerValues = match[1]
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean);
      expect([...swaggerValues].sort()).toEqual(
        [...notificationTypes.ALLOWED_NOTIFICATION_TYPES].sort()
      );
    });
  });

  describe('prod audit script fixture classification', () => {
    it('classifies canonical, legacy, unknown without writes', () => {
      const scriptPath = path.join(BACKEND_ROOT, 'scripts/audit-notification-type-values.js');
      const source = fs.readFileSync(scriptPath, 'utf8');
      expect(source).not.toMatch(/updateMany|insertMany|deleteMany|bulkWrite/i);

      const CANONICAL_VALUES = new Set([
        ...Object.values(notificationTypes.COMMON),
        ...Object.values(notificationTypes.PARTNER),
        ...Object.values(notificationTypes.CLIENT),
      ]);
      const LEGACY_VALUES = new Set(Object.values(notificationTypes.LEGACY));

      const classify = (type) => ({
        CANONICAL: CANONICAL_VALUES.has(type) ? 'YES' : 'NO',
        LEGACY: LEGACY_VALUES.has(type) ? 'YES' : 'NO',
        UNKNOWN: notificationTypes.ALLOWED_NOTIFICATION_TYPES.includes(type) ? 'NO' : 'YES',
      });

      expect(classify('client_booking_confirmed')).toEqual({
        CANONICAL: 'YES',
        LEGACY: 'NO',
        UNKNOWN: 'NO',
      });
      expect(classify('favorite_added')).toEqual({
        CANONICAL: 'NO',
        LEGACY: 'YES',
        UNKNOWN: 'NO',
      });
      expect(classify('__legacy_unknown_test__')).toEqual({
        CANONICAL: 'NO',
        LEGACY: 'NO',
        UNKNOWN: 'YES',
      });
    });
  });
});
