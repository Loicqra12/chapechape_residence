/**
 * P2-09B0 — Prod audit hardening (stay credential duplicates + notification fail-closed).
 */
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const mongoose = require('mongoose');
const notificationTypes = require('../../../src/utils/notification-types');

const BACKEND_ROOT = path.join(__dirname, '../../..');
const STAY_DUP_SCRIPT = path.join(BACKEND_ROOT, 'scripts/verify-stay-credential-duplicates.js');
const STAY_IDX_SCRIPT = path.join(BACKEND_ROOT, 'scripts/verify-stay-credential-indexes.js');
const NOTIF_SCRIPT = path.join(BACKEND_ROOT, 'scripts/audit-notification-type-values.js');
const RESERVATION_MODEL = path.join(BACKEND_ROOT, 'src/models/reservation.model.js');

const WRITE_PATTERN = /insertMany|updateMany|deleteMany|bulkWrite|\.save\(|createIndex|dropIndex|syncIndexes/i;

function mongoUri() {
  return mongoose.connection.getClient().s.url;
}

function runNodeScript(scriptPath, args = [], envOverrides = {}) {
  return spawnSync(process.execPath, [scriptPath, ...args], {
    cwd: BACKEND_ROOT,
    env: { ...process.env, MONGODB_URI: mongoUri(), ...envOverrides },
    encoding: 'utf8',
  });
}

function reservationDoc(overrides = {}) {
  return {
    status: 'confirmed',
    checkIn: new Date('2026-07-01T14:00:00.000Z'),
    checkOut: new Date('2026-07-05T11:00:00.000Z'),
    ...overrides,
  };
}

describe('P2-09B0 prod audit hardening', () => {
  beforeEach(async () => {
    await mongoose.connection.db.collection('reservations').deleteMany({});
    await mongoose.connection.db.collection('notifications').deleteMany({});
  });

  describe('script safety (static)', () => {
    it('verify-stay-credential-duplicates.js is read-only', () => {
      const source = fs.readFileSync(STAY_DUP_SCRIPT, 'utf8');
      expect(source).toMatch(/MONGODB_URI/);
      expect(source).toMatch(/fingerprintFromUri/);
      expect(source).not.toMatch(WRITE_PATTERN);
    });

    it('audit-notification-type-values.js is read-only', () => {
      const source = fs.readFileSync(NOTIF_SCRIPT, 'utf8');
      expect(source).toMatch(/dryRun:\s*true/);
      expect(source).not.toMatch(WRITE_PATTERN);
      expect(source).toMatch(/process\.exit\(1\)/);
    });

    it('partial-filter population matches reservation.model.js and index verifier fields', () => {
      const dupSource = fs.readFileSync(STAY_DUP_SCRIPT, 'utf8');
      const modelSource = fs.readFileSync(RESERVATION_MODEL, 'utf8');
      const idxSource = fs.readFileSync(STAY_IDX_SCRIPT, 'utf8');

      expect(modelSource).toContain(
        "'stayCredentials.checkIn.tokenHash': { $exists: true, $type: 'string' }"
      );
      expect(modelSource).toContain(
        "'stayCredentials.checkOut.tokenHash': { $exists: true, $type: 'string' }"
      );
      expect(dupSource).toContain(
        "'stayCredentials.checkIn.tokenHash': { $exists: true, $type: 'string' }"
      );
      expect(dupSource).toContain(
        "'stayCredentials.checkOut.tokenHash': { $exists: true, $type: 'string' }"
      );
      expect(idxSource).toContain('stayCredentials.checkIn.tokenHash');
      expect(idxSource).toContain('stayCredentials.checkOut.tokenHash');
    });
  });

  describe('stay credential duplicate audit', () => {
    it('unique fixtures → exit 0 / OVERALL UNIQUE', async () => {
      const col = mongoose.connection.db.collection('reservations');
      await col.insertMany([
        reservationDoc({
          stayCredentials: {
            checkIn: { tokenHash: 'hash-checkin-unique-a' },
            checkOut: { tokenHash: 'hash-checkout-unique-a' },
          },
        }),
        reservationDoc({
          stayCredentials: {
            checkIn: { tokenHash: 'hash-checkin-unique-b' },
            checkOut: { tokenHash: 'hash-checkout-unique-b' },
          },
        }),
      ]);

      const result = runNodeScript(STAY_DUP_SCRIPT);
      expect(result.status).toBe(0);
      expect(result.stdout).toMatch(/CHECKIN_HASHES/);
      expect(result.stdout).toMatch(/CHECKOUT_HASHES/);
      expect(result.stdout).toMatch(/RESULT: UNIQUE/);
      expect(result.stdout).toMatch(/OVERALL: UNIQUE/);
      expect(result.stdout).not.toMatch(/hash-checkin-unique-a/);
    });

    it('duplicate check-in hash → exit 1 / DUPLICATE', async () => {
      const col = mongoose.connection.db.collection('reservations');
      const shared = 'shared-checkin-hash-value-xyz';
      await col.insertMany([
        reservationDoc({ stayCredentials: { checkIn: { tokenHash: shared } } }),
        reservationDoc({ stayCredentials: { checkIn: { tokenHash: shared } } }),
      ]);

      const result = runNodeScript(STAY_DUP_SCRIPT);
      expect(result.status).toBe(1);
      expect(result.stdout).toMatch(/CHECKIN_HASHES[\s\S]*RESULT: DUPLICATE/);
      expect(result.stderr).toMatch(/OVERALL: DUPLICATE/);
    });

    it('duplicate check-out hash → exit 1 / DUPLICATE', async () => {
      const col = mongoose.connection.db.collection('reservations');
      const shared = 'shared-checkout-hash-value-xyz';
      await col.insertMany([
        reservationDoc({ stayCredentials: { checkOut: { tokenHash: shared } } }),
        reservationDoc({ stayCredentials: { checkOut: { tokenHash: shared } } }),
      ]);

      const result = runNodeScript(STAY_DUP_SCRIPT);
      expect(result.status).toBe(1);
      expect(result.stdout).toMatch(/CHECKOUT_HASHES[\s\S]*RESULT: DUPLICATE/);
    });

    it('missing / non-string fields ignored per index contract', async () => {
      const col = mongoose.connection.db.collection('reservations');
      await col.insertMany([
        reservationDoc({ stayCredentials: { checkIn: { tokenHash: null } } }),
        reservationDoc({ stayCredentials: { checkIn: { tokenHash: 12345 } } }),
        reservationDoc({}),
        reservationDoc({
          stayCredentials: {
            checkIn: { tokenHash: 'only-eligible-string-hash' },
          },
        }),
      ]);

      const result = runNodeScript(STAY_DUP_SCRIPT);
      expect(result.status).toBe(0);
      expect(result.stdout).toMatch(/eligible count: 1/);
    });

    it('missing MONGODB_URI → exit >= 2', () => {
      const result = spawnSync(process.execPath, [STAY_DUP_SCRIPT], {
        cwd: BACKEND_ROOT,
        env: { ...process.env, MONGODB_URI: '' },
        encoding: 'utf8',
      });
      expect(result.status).toBeGreaterThanOrEqual(2);
    });
  });

  describe('notification type audit fail-closed', () => {
    async function seedNotification(type) {
      const userId = new mongoose.Types.ObjectId();
      await mongoose.connection.db.collection('notifications').insertOne({
        user: userId,
        type,
        message: 'fixture',
        read: false,
        createdAt: new Date(),
      });
    }

    it('canonical only → exit 0', async () => {
      await seedNotification(notificationTypes.CLIENT.BOOKING_CONFIRMED);
      const result = runNodeScript(NOTIF_SCRIPT);
      expect(result.status).toBe(0);
      expect(result.stdout + result.stderr).toMatch(/RESULT: OK/);
    });

    it('legacy only → exit 0', async () => {
      await seedNotification(notificationTypes.LEGACY.BOOKING_UPDATE);
      const result = runNodeScript(NOTIF_SCRIPT);
      expect(result.status).toBe(0);
    });

    it('unknown type → exit 1 with valid JSON when --json', async () => {
      await seedNotification('totally_unknown_notification_type_p209b0');
      const result = runNodeScript(NOTIF_SCRIPT, ['--json']);
      expect(result.status).toBe(1);
      expect(() => JSON.parse(result.stdout.trim())).not.toThrow();
      const report = JSON.parse(result.stdout.trim());
      expect(report.unknownValues.length).toBeGreaterThan(0);
      expect(report.dryRun).toBe(true);
      expect(result.stderr).toMatch(/UNKNOWN_TYPES/);
    });

    it('missing MONGODB_URI → exit >= 2', () => {
      const result = spawnSync(process.execPath, [NOTIF_SCRIPT], {
        cwd: BACKEND_ROOT,
        env: { ...process.env, MONGODB_URI: '' },
        encoding: 'utf8',
      });
      expect(result.status).toBeGreaterThanOrEqual(2);
    });
  });
});
