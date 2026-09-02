const User = require('../../../src/models/user.model');
const Residence = require('../../../src/models/residence.model');
const Reservation = require('../../../src/models/reservation.model');
const Payment = require('../../../src/models/payment.model');
const CancellationPolicy = require('../../../src/models/cancellationPolicy.model');
const Availability = require('../../../src/models/availability.model');
const AvailabilityBlock = require('../../../src/models/availability-block.model');
const { createReservation, modifyReservation } = require('../../../src/services/reservation.service');
const { applyPaymentPaid } = require('../../../src/services/payment-confirmation.service');
const { createBlock, releaseBlock } = require('../../../src/services/partner-block.service');
const errorCodes = require('../../../src/utils/errorCodes');

jest.setTimeout(180000);

async function seedActors() {
  const partner = await User.create({
    email: `p-${Date.now()}-${Math.random()}@test.com`,
    password: 'Test1234',
    firstName: 'Part',
    lastName: 'Ner',
    role: 'partner',
  });
  const client = await User.create({
    email: `c-${Date.now()}-${Math.random()}@test.com`,
    password: 'Test1234',
    firstName: 'Cli',
    lastName: 'Ent',
    role: 'client',
  });
  const policy = await CancellationPolicy.create({
    name: `default-${Date.now()}-${Math.random()}`,
    description: 'Test policy',
    isDefault: true,
    createdBy: partner._id,
    rules: [{ timeBeforeCheckIn: 0, refundPercentage: 100, description: 'full' }],
  });
  return { partner, client, policy };
}

async function seedResidence(partner, policy, extras = {}) {
  return Residence.create({
    title: 'Test Res',
    description: 'Desc test résidence assez longue',
    price: 10000,
    pricePeriod: extras.pricePeriod || 'day',
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
    paymentTTLMinutes: 60,
    hourlyRates: { oneHour: 5000, twoHours: 8000, threeHours: 10000, additionalHour: 2000 },
    ...extras,
  });
}

describe('P1-02 Partner blocks autoritatifs', () => {
  it('day conflict : block 10→15 vs reservation 12→17 → conflict', async () => {
    const { partner, client, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    await createBlock(partner, {
      residenceId: residence._id,
      startDate: new Date('2027-08-10T14:00:00.000Z'),
      endDate: new Date('2027-08-15T11:00:00.000Z'),
      type: 'maintenance',
    });
    await expect(createReservation({
      residence: residence._id,
      user: client._id,
      checkIn: new Date('2027-08-12T14:00:00.000Z'),
      checkOut: new Date('2027-08-17T11:00:00.000Z'),
      numberOfGuests: 1,
      bookingType: 'day',
    })).rejects.toMatchObject({ statusCode: 409 });
  });

  it('day back-to-back : block 10→15 vs reservation 15→18 → allowed', async () => {
    const { partner, client, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    await createBlock(partner, {
      residenceId: residence._id,
      startDate: new Date('2027-08-10T14:00:00.000Z'),
      endDate: new Date('2027-08-15T11:00:00.000Z'),
    });
    const reservation = await createReservation({
      residence: residence._id,
      user: client._id,
      checkIn: new Date('2027-08-15T14:00:00.000Z'),
      checkOut: new Date('2027-08-18T11:00:00.000Z'),
      numberOfGuests: 1,
      bookingType: 'day',
    });
    expect(reservation.status).toBe('payment_pending');
  });

  it('hour overlap : block 13→15 vs reservation 14→16 → conflict', async () => {
    const { partner, client, policy } = await seedActors();
    const residence = await seedResidence(partner, policy, { pricePeriod: 'hour' });
    await createBlock(partner, {
      residenceId: residence._id,
      startDate: new Date('2027-08-10T13:00:00.000Z'),
      endDate: new Date('2027-08-10T15:00:00.000Z'),
      bookingType: 'hour',
    });
    await expect(createReservation({
      residence: residence._id,
      user: client._id,
      checkIn: new Date('2027-08-10T14:00:00.000Z'),
      checkOut: new Date('2027-08-10T16:00:00.000Z'),
      numberOfGuests: 1,
      bookingType: 'hour',
    })).rejects.toMatchObject({ statusCode: 409 });
  });

  it('hour back-to-back : block 13→15 vs reservation 15→17 → allowed', async () => {
    const { partner, client, policy } = await seedActors();
    const residence = await seedResidence(partner, policy, { pricePeriod: 'hour' });
    await createBlock(partner, {
      residenceId: residence._id,
      startDate: new Date('2027-08-10T13:00:00.000Z'),
      endDate: new Date('2027-08-10T15:00:00.000Z'),
      bookingType: 'hour',
    });
    const reservation = await createReservation({
      residence: residence._id,
      user: client._id,
      checkIn: new Date('2027-08-10T15:00:00.000Z'),
      checkOut: new Date('2027-08-10T17:00:00.000Z'),
      numberOfGuests: 1,
      bookingType: 'hour',
    });
    expect(['payment_pending', 'pending']).toContain(reservation.status);
  });

  it('block vs create : 20 races, jamais les deux sur le même slot', async () => {
    const { partner, client, policy } = await seedActors();
    for (let i = 0; i < 20; i += 1) {
      const residence = await seedResidence(partner, policy);
      const start = new Date('2027-09-10T14:00:00.000Z');
      const end = new Date('2027-09-15T11:00:00.000Z');
      const results = await Promise.allSettled([
        createBlock(partner, { residenceId: residence._id, startDate: start, endDate: end }),
        createReservation({
          residence: residence._id,
          user: client._id,
          checkIn: start,
          checkOut: end,
          numberOfGuests: 1,
          bookingType: 'day',
        }),
      ]);
      const ok = results.filter((r) => r.status === 'fulfilled');
      const ko = results.filter((r) => r.status === 'rejected');
      expect(ok.length).toBe(1);
      expect(ko.length).toBe(1);
      expect([409, 400, 503]).toContain(ko[0].reason.statusCode);
    }
  });

  it('block vs modify : un seul obtient la plage', async () => {
    const { partner, client, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    const reservation = await createReservation({
      residence: residence._id,
      user: client._id,
      checkIn: new Date('2027-10-10T14:00:00.000Z'),
      checkOut: new Date('2027-10-12T11:00:00.000Z'),
      numberOfGuests: 1,
      bookingType: 'day',
    });
    const results = await Promise.allSettled([
      modifyReservation(reservation._id, {
        checkIn: new Date('2027-10-10T14:00:00.000Z'),
        checkOut: new Date('2027-10-18T11:00:00.000Z'),
      }, client._id),
      createBlock(partner, {
        residenceId: residence._id,
        startDate: new Date('2027-10-12T14:00:00.000Z'),
        endDate: new Date('2027-10-18T11:00:00.000Z'),
      }),
    ]);
    const ok = results.filter((r) => r.status === 'fulfilled');
    const ko = results.filter((r) => r.status === 'rejected');
    expect(ok.length).toBe(1);
    expect(ko.length).toBe(1);
  });

  it('block vs late payment reacquire → refund_required', async () => {
    const { partner, client, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    const reservationA = await createReservation({
      residence: residence._id,
      user: client._id,
      checkIn: new Date('2027-11-10T14:00:00.000Z'),
      checkOut: new Date('2027-11-15T11:00:00.000Z'),
      numberOfGuests: 1,
      bookingType: 'day',
    });
    await Availability.updateMany(
      { residenceId: residence._id, reservationId: reservationA._id },
      { $set: { status: 'available', reservationId: null, sourceType: null, sourceId: null } }
    );
    await Reservation.updateOne({ _id: reservationA._id }, { $set: { status: 'expired' } });
    await createBlock(partner, {
      residenceId: residence._id,
      startDate: new Date('2027-11-10T14:00:00.000Z'),
      endDate: new Date('2027-11-15T11:00:00.000Z'),
    });
    const payment = await Payment.create({
      reservation: reservationA._id,
      amount: 10000,
      paymentMethod: 'wave',
      paymentProvider: 'wave',
      status: 'pending',
      phoneNumber: '0102030405',
    });
    const result = await applyPaymentPaid(payment, { triggerPayout: false, allowExpired: true });
    expect(result.refundRequired).toBe(true);
    expect((await Reservation.findById(reservationA._id)).status).toBe('expired');
  });

  it('block chevauchant Reservation active → 409', async () => {
    const { partner, client, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    await createReservation({
      residence: residence._id,
      user: client._id,
      checkIn: new Date('2027-12-10T14:00:00.000Z'),
      checkOut: new Date('2027-12-15T11:00:00.000Z'),
      numberOfGuests: 1,
      bookingType: 'day',
    });
    await expect(createBlock(partner, {
      residenceId: residence._id,
      startDate: new Date('2027-12-12T14:00:00.000Z'),
      endDate: new Date('2027-12-14T11:00:00.000Z'),
    })).rejects.toMatchObject({
      statusCode: 409,
      errorCode: errorCodes.INVENTORY.ALREADY_RESERVED,
    });
  });

  it('Partner A ne peut pas bloquer la résidence de Partner B', async () => {
    const { partner, policy } = await seedActors();
    const other = await User.create({
      email: `p2-${Date.now()}@test.com`,
      password: 'Test1234',
      firstName: 'Other',
      lastName: 'Partner',
      role: 'partner',
    });
    const residence = await seedResidence(partner, policy);
    await expect(createBlock(other, {
      residenceId: residence._id,
      startDate: new Date('2027-12-20T14:00:00.000Z'),
      endDate: new Date('2027-12-22T11:00:00.000Z'),
    })).rejects.toMatchObject({ statusCode: 403 });
  });

  it('unblock manual block OK ; reservation inventory non libérable comme block', async () => {
    const { partner, client, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    const block = await createBlock(partner, {
      residenceId: residence._id,
      startDate: new Date('2028-01-10T14:00:00.000Z'),
      endDate: new Date('2028-01-15T11:00:00.000Z'),
      type: 'personal_use',
    });
    const released = await releaseBlock(partner, block._id);
    expect(released.status).toBe('released');
    expect(await Availability.countDocuments({
      residenceId: residence._id,
      sourceId: block._id,
      status: 'blocked',
    })).toBe(0);

    const reservation = await createReservation({
      residence: residence._id,
      user: client._id,
      checkIn: new Date('2028-01-10T14:00:00.000Z'),
      checkOut: new Date('2028-01-15T11:00:00.000Z'),
      numberOfGuests: 1,
      bookingType: 'day',
    });
    await expect(releaseBlock(partner, reservation._id)).rejects.toMatchObject({
      statusCode: 404,
      errorCode: errorCodes.INVENTORY.BLOCK_NOT_FOUND,
    });
    expect(await Availability.countDocuments({
      residenceId: residence._id,
      reservationId: reservation._id,
      status: 'reserved',
    })).toBeGreaterThan(0);
  });

  it('refuse un bloc entièrement passé', async () => {
    const { partner, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    await expect(createBlock(partner, {
      residenceId: residence._id,
      startDate: new Date('2020-01-10T14:00:00.000Z'),
      endDate: new Date('2020-01-15T11:00:00.000Z'),
    })).rejects.toMatchObject({
      statusCode: 400,
      errorCode: errorCodes.INVENTORY.INVALID_BLOCK_PERIOD,
    });
  });

  it('unblock vs create : état déterministe', async () => {
    const { partner, client, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    const block = await createBlock(partner, {
      residenceId: residence._id,
      startDate: new Date('2028-02-10T14:00:00.000Z'),
      endDate: new Date('2028-02-15T11:00:00.000Z'),
    });
    const results = await Promise.allSettled([
      releaseBlock(partner, block._id),
      createReservation({
        residence: residence._id,
        user: client._id,
        checkIn: new Date('2028-02-10T14:00:00.000Z'),
        checkOut: new Date('2028-02-15T11:00:00.000Z'),
        numberOfGuests: 1,
        bookingType: 'day',
      }),
    ]);
    const reservationOk = results[1].status === 'fulfilled';
    const blockReleased = results[0].status === 'fulfilled';
    expect(blockReleased).toBe(true);
    if (reservationOk) {
      expect(results[1].value.status).toBe('payment_pending');
    } else {
      expect([409, 400, 503]).toContain(results[1].reason.statusCode);
      expect((await AvailabilityBlock.findById(block._id)).status).toBe('released');
    }
  });

  it('createBlock day : AvailabilityBlock + Availability dans la même transaction', async () => {
    const { partner, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    let sawTransactionalWrite = false;
    const original = Availability.upsertBulk.bind(Availability);
    const spy = jest.spyOn(Availability, 'upsertBulk').mockImplementation(async (records, options) => {
      expect(options?.session).toBeTruthy();
      expect(options.session.inTransaction()).toBe(true);
      sawTransactionalWrite = true;
      return original(records, options);
    });
    try {
      const block = await createBlock(partner, {
        residenceId: residence._id,
        startDate: new Date('2028-03-10T14:00:00.000Z'),
        endDate: new Date('2028-03-15T11:00:00.000Z'),
      });
      expect(sawTransactionalWrite).toBe(true);
      const days = await Availability.find({
        residenceId: residence._id,
        sourceType: 'manual_block',
        sourceId: block._id,
        status: 'blocked',
      });
      expect(days.length).toBeGreaterThan(0);
      expect(days.every((d) => String(d.sourceId) === String(block._id))).toBe(true);
    } finally {
      spy.mockRestore();
    }
  });

  it('createBlock rollback si Availability échoue : aucun block orphelin', async () => {
    const { partner, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    const spy = jest.spyOn(Availability, 'upsertBulk').mockRejectedValue(new Error('availability write failed'));
    try {
      await expect(createBlock(partner, {
        residenceId: residence._id,
        startDate: new Date('2028-04-10T14:00:00.000Z'),
        endDate: new Date('2028-04-15T11:00:00.000Z'),
      })).rejects.toThrow('availability write failed');
      expect(await AvailabilityBlock.countDocuments({ residence: residence._id })).toBe(0);
      expect(await Availability.countDocuments({
        residenceId: residence._id,
        status: 'blocked',
      })).toBe(0);
    } finally {
      spy.mockRestore();
    }
  });

  it('releaseBlock rollback si Availability échoue : block reste actif', async () => {
    const { partner, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    const block = await createBlock(partner, {
      residenceId: residence._id,
      startDate: new Date('2028-05-10T14:00:00.000Z'),
      endDate: new Date('2028-05-15T11:00:00.000Z'),
    });
    const spy = jest.spyOn(Availability, 'updateMany').mockImplementation(() => {
      throw new Error('availability clear failed');
    });
    try {
      await expect(releaseBlock(partner, block._id)).rejects.toThrow('availability clear failed');
      expect((await AvailabilityBlock.findById(block._id)).status).toBe('active');
      expect(await Availability.countDocuments({
        sourceId: block._id,
        status: 'blocked',
      })).toBeGreaterThan(0);
    } finally {
      spy.mockRestore();
    }
  });

  it('PUT legacy blockDates n\'écrit pas Residence.blockedDates', async () => {
    const availabilityService = require('../../../src/services/availability.service');
    const { partner, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    await availabilityService.blockDates(
      residence._id,
      { startDate: new Date('2028-06-10T14:00:00.000Z'), endDate: new Date('2028-06-12T11:00:00.000Z') },
      null,
      'legacy',
      partner
    );
    const fresh = await Residence.findById(residence._id).lean();
    expect(fresh.blockedDates).toBeUndefined();
    expect(await AvailabilityBlock.countDocuments({ residence: residence._id, status: 'active' })).toBe(1);
  });
});
