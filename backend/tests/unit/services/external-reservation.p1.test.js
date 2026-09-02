const User = require('../../../src/models/user.model');
const Residence = require('../../../src/models/residence.model');
const Reservation = require('../../../src/models/reservation.model');
const Payment = require('../../../src/models/payment.model');
const CancellationPolicy = require('../../../src/models/cancellationPolicy.model');
const Availability = require('../../../src/models/availability.model');
const ExternalReservation = require('../../../src/models/external-reservation.model');
const { createReservation } = require('../../../src/services/reservation.service');
const { applyPaymentPaid } = require('../../../src/services/payment-confirmation.service');
const { createBlock } = require('../../../src/services/partner-block.service');
const {
  createExternalReservation,
  modifyExternalReservation,
  cancelExternalReservation,
  completeExternalReservation,
  toPublicOccupation,
} = require('../../../src/services/external-reservation.service');
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

describe('P1-03 ExternalReservation', () => {
  it('day conflict : external 10→15 vs reservation 12→17 → conflict', async () => {
    const { partner, client, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    await createExternalReservation(partner, {
      residenceId: residence._id,
      checkIn: new Date('2027-08-10T14:00:00.000Z'),
      checkOut: new Date('2027-08-15T11:00:00.000Z'),
      channel: 'whatsapp',
      guestName: 'Jean Kouassi',
      guestPhone: '+22501020304',
    });
    await expect(createReservation({
      residence: residence._id,
      user: client._id,
      checkIn: new Date('2027-08-12T14:00:00.000Z'),
      checkOut: new Date('2027-08-17T11:00:00.000Z'),
      numberOfGuests: 1,
      bookingType: 'day',
    })).rejects.toMatchObject({
      statusCode: 409,
      errorCode: errorCodes.RESERVATION.DATE_CONFLICT,
    });
  });

  it('day back-to-back : external 10→15 vs reservation 15→18 → allowed', async () => {
    const { partner, client, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    await createExternalReservation(partner, {
      residenceId: residence._id,
      checkIn: new Date('2027-08-10T14:00:00.000Z'),
      checkOut: new Date('2027-08-15T11:00:00.000Z'),
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

  it('hour overlap : external 13→15 vs reservation 14→16 → conflict', async () => {
    const { partner, client, policy } = await seedActors();
    const residence = await seedResidence(partner, policy, { pricePeriod: 'hour' });
    await createExternalReservation(partner, {
      residenceId: residence._id,
      checkIn: new Date('2027-08-10T13:00:00.000Z'),
      checkOut: new Date('2027-08-10T15:00:00.000Z'),
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

  it('hour back-to-back : external 13→15 vs reservation 15→17 → allowed', async () => {
    const { partner, client, policy } = await seedActors();
    const residence = await seedResidence(partner, policy, { pricePeriod: 'hour' });
    await createExternalReservation(partner, {
      residenceId: residence._id,
      checkIn: new Date('2027-08-10T13:00:00.000Z'),
      checkOut: new Date('2027-08-10T15:00:00.000Z'),
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

  it('external vs create : 20 races, jamais les deux sur le même slot', async () => {
    const { partner, client, policy } = await seedActors();
    for (let i = 0; i < 20; i += 1) {
      const residence = await seedResidence(partner, policy);
      const start = new Date('2027-09-10T14:00:00.000Z');
      const end = new Date('2027-09-15T11:00:00.000Z');
      const results = await Promise.allSettled([
        createExternalReservation(partner, {
          residenceId: residence._id,
          checkIn: start,
          checkOut: end,
        }),
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

  it('external vs partner block : un seul gagne', async () => {
    const { partner, policy } = await seedActors();
    for (let i = 0; i < 8; i += 1) {
      const residence = await seedResidence(partner, policy);
      const start = new Date('2027-09-20T14:00:00.000Z');
      const end = new Date('2027-09-25T11:00:00.000Z');
      const results = await Promise.allSettled([
        createExternalReservation(partner, {
          residenceId: residence._id,
          checkIn: start,
          checkOut: end,
        }),
        createBlock(partner, {
          residenceId: residence._id,
          startDate: start,
          endDate: end,
        }),
      ]);
      const ok = results.filter((r) => r.status === 'fulfilled');
      const ko = results.filter((r) => r.status === 'rejected');
      expect(ok.length).toBe(1);
      expect(ko.length).toBe(1);
    }
  });

  it('external modify vs reservation create : un seul obtient la plage', async () => {
    const { partner, client, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    const external = await createExternalReservation(partner, {
      residenceId: residence._id,
      checkIn: new Date('2027-10-10T14:00:00.000Z'),
      checkOut: new Date('2027-10-15T11:00:00.000Z'),
    });
    const results = await Promise.allSettled([
      modifyExternalReservation(partner, external._id, {
        checkIn: new Date('2027-10-10T14:00:00.000Z'),
        checkOut: new Date('2027-10-18T11:00:00.000Z'),
      }),
      createReservation({
        residence: residence._id,
        user: client._id,
        checkIn: new Date('2027-10-15T14:00:00.000Z'),
        checkOut: new Date('2027-10-18T11:00:00.000Z'),
        numberOfGuests: 1,
        bookingType: 'day',
      }),
    ]);
    const ok = results.filter((r) => r.status === 'fulfilled');
    const ko = results.filter((r) => r.status === 'rejected');
    expect(ok.length).toBe(1);
    expect(ko.length).toBe(1);
  });

  it('external vs late payment reacquire → refund_required', async () => {
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
    await createExternalReservation(partner, {
      residenceId: residence._id,
      checkIn: new Date('2027-11-10T14:00:00.000Z'),
      checkOut: new Date('2027-11-15T11:00:00.000Z'),
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

  it('cancel libère l\'inventaire ; client peut ensuite réserver', async () => {
    const { partner, client, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    const external = await createExternalReservation(partner, {
      residenceId: residence._id,
      checkIn: new Date('2028-01-10T14:00:00.000Z'),
      checkOut: new Date('2028-01-15T11:00:00.000Z'),
    });
    const cancelled = await cancelExternalReservation(partner, external._id);
    expect(cancelled.status).toBe('cancelled');
    expect(await Availability.countDocuments({
      sourceId: external._id,
      status: 'reserved',
    })).toBe(0);
    const reservation = await createReservation({
      residence: residence._id,
      user: client._id,
      checkIn: new Date('2028-01-10T14:00:00.000Z'),
      checkOut: new Date('2028-01-15T11:00:00.000Z'),
      numberOfGuests: 1,
      bookingType: 'day',
    });
    expect(reservation.status).toBe('payment_pending');
  });

  it('complete libère l\'inventaire', async () => {
    const { partner, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    const external = await createExternalReservation(partner, {
      residenceId: residence._id,
      checkIn: new Date('2028-02-10T14:00:00.000Z'),
      checkOut: new Date('2028-02-15T11:00:00.000Z'),
    });
    const completed = await completeExternalReservation(partner, external._id);
    expect(completed.status).toBe('completed');
    expect(await Availability.countDocuments({
      sourceId: external._id,
      status: 'reserved',
    })).toBe(0);
  });

  it('ne crée aucun Payment ChapeChape', async () => {
    const { partner, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    const external = await createExternalReservation(partner, {
      residenceId: residence._id,
      checkIn: new Date('2028-03-10T14:00:00.000Z'),
      checkOut: new Date('2028-03-12T11:00:00.000Z'),
    });
    expect(await Payment.countDocuments({ reservation: external._id })).toBe(0);
    expect(await Payment.countDocuments({})).toBe(0);
  });

  it('vue publique : pas de PII (guestName / guestPhone / notes)', async () => {
    const { partner, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    const external = await createExternalReservation(partner, {
      residenceId: residence._id,
      checkIn: new Date('2028-04-10T14:00:00.000Z'),
      checkOut: new Date('2028-04-12T11:00:00.000Z'),
      guestName: 'Jean Kouassi',
      guestPhone: '+22501020304',
      notes: 'via WhatsApp',
      channel: 'whatsapp',
    });
    const pub = toPublicOccupation(external);
    expect(pub.guestName).toBeUndefined();
    expect(pub.guestPhone).toBeUndefined();
    expect(pub.notes).toBeUndefined();
    expect(pub.channel).toBeUndefined();
    expect(pub.externalReference).toBeUndefined();
    expect(JSON.stringify(pub)).not.toMatch(/Jean|01020304|WhatsApp/i);
    expect(pub.sourceType).toBe('external_reservation');
  });

  it('Partner A ne peut pas créer une externe sur la résidence de Partner B', async () => {
    const { partner, policy } = await seedActors();
    const other = await User.create({
      email: `p2-${Date.now()}@test.com`,
      password: 'Test1234',
      firstName: 'Other',
      lastName: 'Partner',
      role: 'partner',
    });
    const residence = await seedResidence(partner, policy);
    await expect(createExternalReservation(other, {
      residenceId: residence._id,
      checkIn: new Date('2028-05-10T14:00:00.000Z'),
      checkOut: new Date('2028-05-12T11:00:00.000Z'),
    })).rejects.toMatchObject({ statusCode: 403 });
  });

  it('refuse une externe entièrement passée', async () => {
    const { partner, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    await expect(createExternalReservation(partner, {
      residenceId: residence._id,
      checkIn: new Date('2020-01-10T14:00:00.000Z'),
      checkOut: new Date('2020-01-15T11:00:00.000Z'),
    })).rejects.toMatchObject({
      statusCode: 400,
      errorCode: errorCodes.INVENTORY.INVALID_EXTERNAL_PERIOD,
    });
  });

  it('createExternal rollback si Availability échoue', async () => {
    const { partner, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    const spy = jest.spyOn(Availability, 'upsertBulk').mockRejectedValue(new Error('availability write failed'));
    try {
      await expect(createExternalReservation(partner, {
        residenceId: residence._id,
        checkIn: new Date('2028-06-10T14:00:00.000Z'),
        checkOut: new Date('2028-06-15T11:00:00.000Z'),
      })).rejects.toThrow('availability write failed');
      expect(await ExternalReservation.countDocuments({ residence: residence._id })).toBe(0);
    } finally {
      spy.mockRestore();
    }
  });
});
