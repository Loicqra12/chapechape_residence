/**
 * P2-07C — Arrival reminder Agenda scheduling idempotence + reliability gate
 */
const mongoose = require('mongoose');
const User = require('../../../src/models/user.model');
const Residence = require('../../../src/models/residence.model');
const Reservation = require('../../../src/models/reservation.model');
const Notification = require('../../../src/models/notification.model');
const CancellationPolicy = require('../../../src/models/cancellationPolicy.model');
const notificationTypes = require('../../../src/utils/notification-types');
const twilioService = require('../../../src/services/twilio.service');
const oneSignalService = require('../../../src/services/onesignal.service');
const { saveUniqueScheduledJob } = require('../../../src/runtime/agenda-cluster');
const {
  ARRIVAL_REMINDER_UNIQUE_INDEX,
  ensureArrivalReminderUniqueIndexForTests,
  classifyArrivalReminderIndex,
} = require('../../../src/runtime/agenda-indexes');
const { reservationSnapshotAttrs } = require('../../helpers/residence.fixture');

let agendaService;
let notificationService;

jest.setTimeout(180000);

const ARRIVAL_JOB = 'sendReservationReminder';
const DEPARTURE_JOB = 'sendReservationDepartureReminder';

function futureCheckIn(daysFromNow = 10) {
  const d = new Date();
  d.setDate(d.getDate() + daysFromNow);
  d.setHours(14, 0, 0, 0);
  return d;
}

function expectedReminderDate(checkIn) {
  const d = new Date(checkIn);
  d.setHours(d.getHours() - 24);
  return d;
}

async function countArrivalJobs(reservationId) {
  return mongoose.connection.collection('agendaJobs').countDocuments({
    name: ARRIVAL_JOB,
    'data.reservationId': String(reservationId),
  });
}

async function countDepartureJobs(reservationId) {
  const id = String(reservationId);
  let oid;
  try {
    oid = new mongoose.Types.ObjectId(id);
  } catch (_) {
    oid = null;
  }
  const query = {
    name: DEPARTURE_JOB,
    ...(oid
      ? { $or: [{ 'data.reservationId': id }, { 'data.reservationId': oid }] }
      : { 'data.reservationId': id }),
  };
  return mongoose.connection.collection('agendaJobs').countDocuments(query);
}

async function getArrivalJob(reservationId) {
  return mongoose.connection.collection('agendaJobs').findOne({
    name: ARRIVAL_JOB,
    'data.reservationId': String(reservationId),
  });
}

async function seedReservation(overrides = {}) {
  const partner = await User.create({
    email: `p-p2-07c-${Date.now()}-${Math.random()}@test.com`,
    password: 'Test1234!',
    firstName: 'Partner',
    lastName: 'Test',
    role: 'partner',
    phoneNumber: '+2250700000100',
  });
  const client = await User.create({
    email: `c-p2-07c-${Date.now()}-${Math.random()}@test.com`,
    password: 'Test1234!',
    firstName: 'Client',
    lastName: 'Test',
    role: 'client',
    phoneNumber: '+2250700000200',
    deviceTokens: [],
  });
  const policy = await CancellationPolicy.create({
    name: `policy-p2-07c-${Date.now()}`,
    description: 'Test',
    isDefault: true,
    createdBy: partner._id,
    rules: [{ timeBeforeCheckIn: 0, refundPercentage: 100, description: 'full' }],
  });
  const checkIn = overrides.checkIn || futureCheckIn(12);
  const checkOut = overrides.checkOut || new Date(checkIn.getTime() + 3 * 24 * 60 * 60 * 1000);
  const residence = await Residence.create({
    title: 'Res P2-07C',
    description: 'Description test assez longue pour validation',
    price: 10000,
    pricePeriod: 'day',
    address: 'Rue 1',
    city: 'Abidjan',
    locationData: { address: 'Rue 1', city: 'Abidjan', country: 'CI' },
    type: 'apartment',
    bedrooms: 1,
    bathrooms: 1,
    area: 40,
    partner: partner._id,
    cancellationPolicy: policy._id,
    reservationMode: 'instant',
  });
  const reservation = await Reservation.create({
    user: client._id,
    partner: partner._id,
    residence: residence._id,
    cancellationPolicy: policy._id,
    checkIn,
    checkOut,
    numberOfGuests: 1,
    bookingType: 'day',
    status: overrides.status || 'payment_pending',
    paymentStatus: overrides.paymentStatus || 'pending',
    totalPrice: 30000,
    ...reservationSnapshotAttrs(),
    ...overrides.reservationFields,
  });
  return { partner, client, residence, reservation, checkIn, checkOut };
}

describe('P2-07C arrival reminder idempotence', () => {
  beforeAll(async () => {
    await ensureArrivalReminderUniqueIndexForTests(mongoose.connection.db);
    const agendaPath = require.resolve('../../../src/services/agenda.service');
    delete require.cache[agendaPath];
    agendaService = require('../../../src/services/agenda.service');
    notificationService = require('../../../src/services/notification.service');
    await agendaService.startAgenda();
  });

  afterAll(async () => {
    try {
      await agendaService.agenda.stop();
    } catch (_) {
      /* ignore */
    }
  });

  beforeEach(async () => {
    await mongoose.connection.collection('agendaJobs').deleteMany({});
    jest.restoreAllMocks();
  });

  describe('Mongo uniqueness gate', () => {
    it('partial unique index is present on agendaJobs in test', async () => {
      const indexes = await mongoose.connection.collection('agendaJobs').indexes();
      const result = classifyArrivalReminderIndex(indexes);
      expect(result.status).toBe('PRESENT');
    });

    it('direct duplicate insert → E11000 (DB-level constraint)', async () => {
      const col = mongoose.connection.collection('agendaJobs');
      const rid = new mongoose.Types.ObjectId().toString();
      const base = {
        name: ARRIVAL_JOB,
        type: 'once',
        data: { reservationId: rid },
        nextRunAt: new Date(Date.now() + 86400000),
        priority: 0,
        disabled: false,
      };
      await col.insertOne({ ...base });
      await expect(
        col.insertOne({ ...base, nextRunAt: new Date(Date.now() + 172800000) })
      ).rejects.toMatchObject({ code: 11000 });
      expect(await countArrivalJobs(rid)).toBe(1);
    });

    it('legacy jobs without data.reservationId are not constrained by partial index', async () => {
      const col = mongoose.connection.collection('agendaJobs');
      const legacy = {
        name: ARRIVAL_JOB,
        type: 'once',
        data: {},
        nextRunAt: new Date(Date.now() + 86400000),
        priority: 0,
        disabled: false,
      };
      await col.insertOne({ ...legacy });
      await col.insertOne({ ...legacy, nextRunAt: new Date(Date.now() + 172800000) });
      expect(await col.countDocuments({ name: ARRIVAL_JOB, data: {} })).toBe(2);
    });

    it('20 concurrent first-time schedules → 1 DB document, zero dedup deleteMany', async () => {
      const { reservation, checkIn } = await seedReservation();
      const col = agendaService.agenda._collection;
      let dedupDeleteCalls = 0;
      const origDeleteMany = col.deleteMany.bind(col);
      jest.spyOn(col, 'deleteMany').mockImplementation(async (filter, ...rest) => {
        if (filter && filter._id && Array.isArray(filter._id.$in)) {
          dedupDeleteCalls += 1;
        }
        return origDeleteMany(filter, ...rest);
      });

      await Promise.all(
        Array.from({ length: 20 }, () =>
          agendaService.scheduleReservationReminder(reservation._id, checkIn)
        )
      );

      expect(await countArrivalJobs(reservation._id)).toBe(1);
      expect(dedupDeleteCalls).toBe(0);
    });

    it('same reservation: arrival + departure + expire reservation — no E11000 collision', async () => {
      const { reservation, checkIn, checkOut } = await seedReservation();
      const rid = String(reservation._id);

      await agendaService.scheduleReservationReminder(reservation._id, checkIn);
      await agendaService.scheduleReservationDepartureReminder(reservation._id, checkOut);
      await saveUniqueScheduledJob(
        agendaService.agenda,
        'expire reservation',
        new Date(Date.now() + 3600000),
        { reservationId: rid },
        'reservationId'
      );
      await agendaService.agenda.schedule(
        new Date(Date.now() + 1800000),
        'reservation payment reminder',
        { reservationId: rid, phase: 'mid' }
      );

      expect(await countArrivalJobs(reservation._id)).toBe(1);
      expect(await countDepartureJobs(reservation._id)).toBe(1);
      expect(await mongoose.connection.collection('agendaJobs').countDocuments({
        name: 'expire reservation',
        'data.reservationId': rid,
      })).toBe(1);
      expect(await mongoose.connection.collection('agendaJobs').countDocuments({
        name: 'reservation payment reminder',
        'data.reservationId': rid,
      })).toBe(1);
    });

    it('sequential D1 then D2 → 1 job, same _id, nextRunAt = D2', async () => {
      const rid = new mongoose.Types.ObjectId().toString();
      const d1 = expectedReminderDate(futureCheckIn(12));
      const d2 = expectedReminderDate(futureCheckIn(20));

      await saveUniqueScheduledJob(
        agendaService.agenda,
        ARRIVAL_JOB,
        d1,
        { reservationId: rid },
        'reservationId'
      );
      const first = await getArrivalJob(rid);

      await saveUniqueScheduledJob(
        agendaService.agenda,
        ARRIVAL_JOB,
        d2,
        { reservationId: rid },
        'reservationId'
      );
      const second = await getArrivalJob(rid);

      expect(await countArrivalJobs(rid)).toBe(1);
      expect(String(second._id)).toBe(String(first._id));
      expect(new Date(second.nextRunAt).getTime()).toBe(d2.getTime());
    });

    it('post-save collapse logic is absent from agenda-cluster.js', () => {
      const fs = require('fs');
      const path = require('path');
      const src = fs.readFileSync(
        path.join(__dirname, '../../../src/runtime/agenda-cluster.js'),
        'utf8'
      );
      expect(src).not.toMatch(/deleteMany\(\{ _id: \{ \$in:/);
      expect(src).not.toMatch(/Collapse race duplicates/);
    });
  });

  describe('reliability gate — saveUniqueScheduledJob semantics', () => {
    it('saveUniqueScheduledJob upserts same logical job and updates nextRunAt without cancel', async () => {
      const rid = new mongoose.Types.ObjectId().toString();
      const d1 = expectedReminderDate(futureCheckIn(12));
      const d2 = expectedReminderDate(futureCheckIn(20));

      await saveUniqueScheduledJob(
        agendaService.agenda,
        ARRIVAL_JOB,
        d1,
        { reservationId: rid },
        'reservationId'
      );
      expect(await countArrivalJobs(rid)).toBe(1);
      const first = await getArrivalJob(rid);
      expect(new Date(first.nextRunAt).getTime()).toBe(d1.getTime());

      await saveUniqueScheduledJob(
        agendaService.agenda,
        ARRIVAL_JOB,
        d2,
        { reservationId: rid },
        'reservationId'
      );
      expect(await countArrivalJobs(rid)).toBe(1);
      const second = await getArrivalJob(rid);
      expect(new Date(second.nextRunAt).getTime()).toBe(d2.getTime());
      expect(String(second._id)).toBe(String(first._id));
    });

    it('cancel-before-save anti-pattern: cancel succeeds then save skipped → 0 jobs (loss window)', async () => {
      const { reservation, checkIn } = await seedReservation();
      const rid = String(reservation._id);

      await saveUniqueScheduledJob(
        agendaService.agenda,
        ARRIVAL_JOB,
        expectedReminderDate(checkIn),
        { reservationId: rid },
        'reservationId'
      );
      expect(await countArrivalJobs(reservation._id)).toBe(1);

      await agendaService.agenda.cancel({ name: ARRIVAL_JOB, 'data.reservationId': rid });
      expect(await countArrivalJobs(reservation._id)).toBe(0);
    });

    it('upsert-only scheduler: failed reschedule preserves existing reminder', async () => {
      const { reservation, checkIn } = await seedReservation();
      await agendaService.scheduleReservationReminder(reservation._id, checkIn);
      const before = await getArrivalJob(reservation._id);
      const beforeRunAt = new Date(before.nextRunAt).getTime();

      const col = agendaService.agenda._collection;
      jest.spyOn(col, 'findOneAndUpdate').mockRejectedValueOnce(
        new Error('P2-07C injected save failure')
      );

      const newCheckIn = futureCheckIn(20);
      await expect(
        agendaService.scheduleReservationReminder(reservation._id, newCheckIn)
      ).rejects.toThrow('P2-07C injected save failure');

      expect(await countArrivalJobs(reservation._id)).toBe(1);
      const after = await getArrivalJob(reservation._id);
      expect(new Date(after.nextRunAt).getTime()).toBe(beforeRunAt);
    });

    it('real Agenda in test when mongoose connected — no JEST_AGENDA_REAL flag', async () => {
      expect(process.env.JEST_AGENDA_REAL).toBeUndefined();
      expect(mongoose.connection.readyState).toBe(1);

      const { reservation, checkIn } = await seedReservation();
      await agendaService.scheduleReservationReminder(reservation._id, checkIn);
      expect(await countArrivalJobs(reservation._id)).toBe(1);
    });

    it('agenda.cancel removes locked job document (characterization)', async () => {
      const { reservation, checkIn } = await seedReservation();
      const rid = String(reservation._id);

      await agendaService.scheduleReservationReminder(reservation._id, checkIn);
      await mongoose.connection.collection('agendaJobs').updateOne(
        { name: ARRIVAL_JOB, 'data.reservationId': rid },
        { $set: { lockedAt: new Date() } }
      );

      const deleted = await agendaService.agenda.cancel({
        name: ARRIVAL_JOB,
        'data.reservationId': rid,
      });
      expect(deleted).toBe(1);
      expect(await countArrivalJobs(reservation._id)).toBe(0);
    });

    it('locked job: upsert reschedule updates nextRunAt without deleting document', async () => {
      const { reservation, checkIn } = await seedReservation();
      const rid = String(reservation._id);
      const lockedAt = new Date();

      await agendaService.scheduleReservationReminder(reservation._id, checkIn);
      await mongoose.connection.collection('agendaJobs').updateOne(
        { name: ARRIVAL_JOB, 'data.reservationId': rid },
        { $set: { lockedAt } }
      );

      const newCheckIn = futureCheckIn(20);
      await agendaService.scheduleReservationReminder(reservation._id, newCheckIn);

      expect(await countArrivalJobs(reservation._id)).toBe(1);
      const job = await getArrivalJob(reservation._id);
      expect(new Date(job.nextRunAt).getTime()).toBe(expectedReminderDate(newCheckIn).getTime());
      expect(job.lockedAt).toBeTruthy();
    });
  });

  describe('sequential scheduling', () => {
    it('schedule arrival once → one Agenda job', async () => {
      const { reservation, checkIn } = await seedReservation();
      await agendaService.scheduleReservationReminder(reservation._id, checkIn);
      expect(await countArrivalJobs(reservation._id)).toBe(1);
    });

    it('schedule same arrival twice → one Agenda job', async () => {
      const { reservation, checkIn } = await seedReservation();
      await agendaService.scheduleReservationReminder(reservation._id, checkIn);
      await agendaService.scheduleReservationReminder(reservation._id, checkIn);
      expect(await countArrivalJobs(reservation._id)).toBe(1);
    });

    it('create flow + payment-confirm flow → one Agenda job', async () => {
      const { reservation, checkIn } = await seedReservation();
      await notificationService.scheduleReservationReminders(reservation);
      expect(await countArrivalJobs(reservation._id)).toBe(1);

      await agendaService.scheduleReservationReminder(reservation._id, checkIn);
      expect(await countArrivalJobs(reservation._id)).toBe(1);
    });
  });

  describe('concurrent scheduling', () => {
    it('20 concurrent scheduleReservationReminder → one logical job', async () => {
      const { reservation, checkIn } = await seedReservation();
      await Promise.all(
        Array.from({ length: 20 }, () =>
          agendaService.scheduleReservationReminder(reservation._id, checkIn)
        )
      );
      expect(await countArrivalJobs(reservation._id)).toBe(1);
    });
  });

  describe('multiple reservations', () => {
    it('Reservation A and B each keep their own arrival reminder', async () => {
      const a = await seedReservation();
      const b = await seedReservation();
      await agendaService.scheduleReservationReminder(a.reservation._id, a.checkIn);
      await agendaService.scheduleReservationReminder(b.reservation._id, b.checkIn);
      expect(await countArrivalJobs(a.reservation._id)).toBe(1);
      expect(await countArrivalJobs(b.reservation._id)).toBe(1);
      expect(await mongoose.connection.collection('agendaJobs').countDocuments({ name: ARRIVAL_JOB })).toBe(2);
    });
  });

  describe('arrival vs departure', () => {
    it('same reservation → arrival + departure = 2 jobs, no collision', async () => {
      const { reservation, checkIn, checkOut } = await seedReservation();
      await agendaService.scheduleReservationReminder(reservation._id, checkIn);
      await agendaService.scheduleReservationDepartureReminder(reservation._id, checkOut);
      expect(await countArrivalJobs(reservation._id)).toBe(1);
      expect(await countDepartureJobs(reservation._id)).toBe(1);
    });
  });

  describe('reschedule on checkIn change', () => {
    it('same reservation with new checkIn → one job, nextRunAt updated', async () => {
      const { reservation, checkIn } = await seedReservation();
      await agendaService.scheduleReservationReminder(reservation._id, checkIn);
      const firstJob = await getArrivalJob(reservation._id);
      const firstRunAt = firstJob.nextRunAt;

      const newCheckIn = futureCheckIn(20);
      await agendaService.scheduleReservationReminder(reservation._id, newCheckIn);
      expect(await countArrivalJobs(reservation._id)).toBe(1);

      const updatedJob = await getArrivalJob(reservation._id);
      const expected = expectedReminderDate(newCheckIn);
      expect(new Date(updatedJob.nextRunAt).getTime()).toBe(expected.getTime());
      expect(new Date(updatedJob.nextRunAt).getTime()).not.toBe(new Date(firstRunAt).getTime());
      expect(String(updatedJob._id)).toBe(String(firstJob._id));
    });
  });

  describe('job execution guard', () => {
    it('one job execution → max 1 SMS + max 1 ARRIVAL_REMINDER notification', async () => {
      const { reservation, checkIn, client } = await seedReservation({
        status: 'confirmed',
        paymentStatus: 'paid',
      });

      const smsSpy = jest.spyOn(twilioService, 'sendReservationNotification').mockResolvedValue({
        sid: 'SM-test',
        status: 'sent',
      });
      jest.spyOn(oneSignalService, 'sendToMultipleUsers').mockResolvedValue({
        success: true,
        status: 'sent',
        providerId: 'os-reminder',
        recipients: 1,
        invalidSubscriptionIds: [],
      });
      jest.spyOn(require('../../../src/services/email.service'), 'sendNotificationEmail')
        .mockResolvedValue(undefined);

      await agendaService.scheduleReservationReminder(reservation._id, checkIn);
      const jobs = await agendaService.agenda.jobs({
        name: ARRIVAL_JOB,
        'data.reservationId': String(reservation._id),
      });
      expect(jobs).toHaveLength(1);
      await jobs[0].run();

      expect(smsSpy).toHaveBeenCalledTimes(1);
      const notifs = await Notification.find({
        user: client._id,
        type: notificationTypes.CLIENT.ARRIVAL_REMINDER,
      });
      expect(notifs.length).toBeLessThanOrEqual(1);
    });

    it('payment_pending reservation → job runs but no SMS/notification (status guard)', async () => {
      const { reservation, checkIn, client } = await seedReservation({
        status: 'payment_pending',
        paymentStatus: 'pending',
      });

      const smsSpy = jest.spyOn(twilioService, 'sendReservationNotification').mockResolvedValue({
        sid: 'SM-test',
        status: 'sent',
      });
      jest.spyOn(oneSignalService, 'sendToMultipleUsers').mockResolvedValue({
        success: true,
        status: 'sent',
        providerId: 'os-reminder',
        recipients: 1,
        invalidSubscriptionIds: [],
      });

      await agendaService.scheduleReservationReminder(reservation._id, checkIn);
      const jobs = await agendaService.agenda.jobs({
        name: ARRIVAL_JOB,
        'data.reservationId': String(reservation._id),
      });
      await jobs[0].run();

      expect(smsSpy).not.toHaveBeenCalled();
      expect(await Notification.countDocuments({
        user: client._id,
        type: notificationTypes.CLIENT.ARRIVAL_REMINDER,
      })).toBe(0);
    });
  });
});
