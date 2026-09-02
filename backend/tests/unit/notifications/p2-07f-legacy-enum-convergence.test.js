/**
 * P2-07F — Legacy / canonical notification type convergence
 */
const Notification = require('../../../src/models/notification.model');
const constants = require('../../../src/utils/constants');
const notificationTypes = require('../../../src/utils/notification-types');
const User = require('../../../src/models/user.model');

jest.setTimeout(120000);

const VALID_CATEGORIES = new Set(['bookings', 'messages', 'payments', 'promotions', 'system']);

const LEGACY_STRINGS_FROM_OLD_CONSTANTS = {
  FAVORITE_ADDED: 'favorite_added',
  FAVORITE_PRICE_CHANGED: 'favorite_price_changed',
  FAVORITE_STATUS_CHANGED: 'favorite_status_changed',
  BOOKING_CONFIRMED: 'booking_confirmed',
  BOOKING_CANCELLED: 'booking_cancelled',
  BOOKING_REMINDER: 'booking_reminder',
  PAYMENT_RECEIVED: 'payment_received',
  PAYMENT_FAILED: 'payment_failed',
  PAYMENT_REFUNDED: 'payment_refunded',
  SYSTEM_MAINTENANCE: 'system_maintenance',
  ACCOUNT_UPDATE: 'account_update',
};

describe('P2-07F notification type legacy / canonical convergence', () => {
  let userId;

  beforeAll(async () => {
    const user = await User.create({
      email: `p2-07f-${Date.now()}@test.com`,
      password: 'Test1234!',
      firstName: 'P2',
      lastName: '07F',
      role: 'client',
    });
    userId = user._id;
  });

  describe('canonical source of truth', () => {
    it('constants.js no longer exports NOTIFICATION_TYPES', () => {
      expect(constants.NOTIFICATION_TYPES).toBeUndefined();
    });

    it('notification-types.js exports ALLOWED_NOTIFICATION_TYPES as single persisted enum', () => {
      const { ALLOWED_NOTIFICATION_TYPES, COMMON, PARTNER, CLIENT, LEGACY } = notificationTypes;
      expect(ALLOWED_NOTIFICATION_TYPES.length).toBe(
        Object.values(COMMON).length +
          Object.values(PARTNER).length +
          Object.values(CLIENT).length +
          Object.values(LEGACY).length
      );
      expect(new Set(ALLOWED_NOTIFICATION_TYPES).size).toBe(ALLOWED_NOTIFICATION_TYPES.length);
    });

    it('Notification model enum matches ALLOWED_NOTIFICATION_TYPES', () => {
      const schemaEnum = Notification.schema.path('type').enumValues;
      expect(schemaEnum).toEqual(notificationTypes.ALLOWED_NOTIFICATION_TYPES);
    });
  });

  describe('EXACT_EQUIVALENT legacy parity', () => {
    it('LEGACY symbols preserve pre-migration stored strings from old constants', () => {
      for (const [symbol, value] of Object.entries(LEGACY_STRINGS_FROM_OLD_CONSTANTS)) {
        expect(notificationTypes.LEGACY[symbol]).toBe(value);
      }
    });

    it('sms legacy types are defined (were undefined before P2-07F)', () => {
      expect(notificationTypes.LEGACY.BOOKING_UPDATE).toBe('booking_update');
      expect(notificationTypes.LEGACY.PAYMENT_REQUIRED).toBe('payment_required');
    });

    it('favorite controller paths use same strings as before migration', () => {
      expect(notificationTypes.LEGACY.FAVORITE_ADDED).toBe('favorite_added');
      expect(notificationTypes.LEGACY.FAVORITE_STATUS_CHANGED).toBe('favorite_status_changed');
    });
  });

  describe('SEMANTIC_EQUIVALENT_DIFFERENT_VALUE — no silent migration', () => {
    it('legacy booking_confirmed differs from canonical client_booking_confirmed', () => {
      expect(notificationTypes.LEGACY.BOOKING_CONFIRMED).toBe('booking_confirmed');
      expect(notificationTypes.CLIENT.BOOKING_CONFIRMED).toBe('client_booking_confirmed');
      expect(notificationTypes.LEGACY.BOOKING_CONFIRMED).not.toBe(
        notificationTypes.CLIENT.BOOKING_CONFIRMED
      );
    });

    it('legacy payment_received differs from partner_payment_received', () => {
      expect(notificationTypes.LEGACY.PAYMENT_RECEIVED).toBe('payment_received');
      expect(notificationTypes.PARTNER.PAYMENT_RECEIVED).toBe('partner_payment_received');
    });
  });

  describe('Notification schema acceptance', () => {
    it('every canonical active type is accepted by Mongoose enum on write', async () => {
      const { COMMON, PARTNER, CLIENT } = notificationTypes;
      const activeTypes = [
        ...Object.values(COMMON),
        ...Object.values(PARTNER),
        ...Object.values(CLIENT),
      ];

      for (const type of activeTypes) {
        const doc = new Notification({
          user: userId,
          type,
          message: `schema-accept ${type}`,
        });
        await expect(doc.validate()).resolves.toBeUndefined();
      }
    });

    it('every legacy persisted type is accepted by Mongoose enum on write', async () => {
      for (const type of Object.values(notificationTypes.LEGACY)) {
        const doc = new Notification({
          user: userId,
          type,
          message: `legacy-accept ${type}`,
        });
        await expect(doc.validate()).resolves.toBeUndefined();
      }
    });

    it('rejects unknown type on write', async () => {
      const doc = new Notification({
        user: userId,
        type: 'totally_unknown_notification_type',
        message: 'should fail',
      });
      await expect(doc.validate()).rejects.toThrow(/enum/);
    });
  });

  describe('category mapping matrix (P2-06C frozen policy)', () => {
    it('every allowed type maps to a valid push category', () => {
      for (const type of notificationTypes.ALLOWED_NOTIFICATION_TYPES) {
        const category = notificationTypes.getCategoryByNotificationType(type);
        expect(category).toBeTruthy();
        expect(VALID_CATEGORIES.has(category)).toBe(true);
      }
    });

    it('unknown notification type falls back to system', () => {
      expect(notificationTypes.getCategoryByNotificationType(undefined)).toBe('system');
      expect(notificationTypes.getCategoryByNotificationType('not_a_real_type')).toBe('system');
    });

    it('legacy favorite types map to system category', () => {
      expect(notificationTypes.getCategoryByNotificationType('favorite_added')).toBe('system');
      expect(notificationTypes.getCategoryByNotificationType('favorite_status_changed')).toBe(
        'system'
      );
    });

    it('legacy booking_update and payment_required map to bookings/payments', () => {
      expect(notificationTypes.getCategoryByNotificationType('booking_update')).toBe('bookings');
      expect(notificationTypes.getCategoryByNotificationType('payment_required')).toBe('payments');
    });
  });

  describe('dormant product types — not removed', () => {
    it('CHECKIN_READY and CHECKOUT_REMINDER remain in canonical enum', () => {
      expect(notificationTypes.CLIENT.CHECKIN_READY).toBe('client_checkin_ready');
      expect(notificationTypes.CLIENT.CHECKOUT_REMINDER).toBe('client_checkout_reminder');
      expect(notificationTypes.ALLOWED_NOTIFICATION_TYPES).toContain('client_checkin_ready');
      expect(notificationTypes.ALLOWED_NOTIFICATION_TYPES).toContain('client_checkout_reminder');
    });
  });

  describe('audit script contract', () => {
    it('audit-notification-type-values.js exists and is read-only (no writes)', () => {
      const fs = require('fs');
      const path = require('path');
      const scriptPath = path.join(
        __dirname,
        '../../../scripts/audit-notification-type-values.js'
      );
      const source = fs.readFileSync(scriptPath, 'utf8');
      expect(source).toMatch(/dryRun:\s*true/);
      expect(source).not.toMatch(/updateMany|insertMany|deleteMany|bulkWrite/i);
    });
  });
});

describe('P2-07F swagger enum alignment', () => {
  it('swagger notification schema includes canonical and legacy persisted values', () => {
    const fs = require('fs');
    const path = require('path');
    const swaggerPath = path.join(
      __dirname,
      '../../../src/swagger/schemas/notification.schema.js'
    );
    const source = fs.readFileSync(swaggerPath, 'utf8');
    expect(source).toContain('client_booking_confirmed');
    expect(source).toContain('partner_new_booking');
    expect(source).toContain('favorite_added');
    expect(source).toContain('booking_update');
    expect(source).toContain('payment_required');
  });
});
