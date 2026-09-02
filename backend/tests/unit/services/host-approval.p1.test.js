const User = require('../../../src/models/user.model');
const Residence = require('../../../src/models/residence.model');
const Reservation = require('../../../src/models/reservation.model');
const CancellationPolicy = require('../../../src/models/cancellationPolicy.model');
const Availability = require('../../../src/models/availability.model');
const { createReservation } = require('../../../src/services/reservation.service');
const {
  expireHostApproval,
  approveHostRequest,
} = require('../../../src/services/host-approval.service');
const errorCodes = require('../../../src/utils/errorCodes');

jest.setTimeout(120000);

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
    reservationMode: 'approval_required',
    paymentTTLMinutes: 60,
    hostAcceptTTLMinutes: 480,
    hourlyRates: { oneHour: 5000, twoHours: 8000, threeHours: 10000, additionalHour: 2000 },
    ...extras,
  });
}

async function makeRequest(partner, client, policy, checkIn, checkOut) {
  const residence = await seedResidence(partner, policy);
  const reservation = await createReservation({
    residence: residence._id,
    user: client._id,
    checkIn,
    checkOut,
    numberOfGuests: 1,
    bookingType: 'day',
  });
  return { residence, reservation };
}

async function reservedCount(reservationId) {
  return Availability.countDocuments({ reservationId, status: 'reserved' });
}

describe('P1-01 host approval TTL', () => {
  it('create approval_required pose hostApprovalDeadline et awaiting_approval', async () => {
    const { partner, client, policy } = await seedActors();
    const before = Date.now();
    const { reservation } = await makeRequest(
      partner,
      client,
      policy,
      new Date('2027-08-10T14:00:00.000Z'),
      new Date('2027-08-12T11:00:00.000Z')
    );
    expect(reservation.status).toBe('awaiting_approval');
    expect(reservation.hostApprovalDeadline).toBeTruthy();
    const ttlMs = 480 * 60 * 1000;
    const delta = new Date(reservation.hostApprovalDeadline).getTime() - before;
    expect(delta).toBeGreaterThan(ttlMs - 5000);
    expect(delta).toBeLessThan(ttlMs + 5000);
  });

  it('approve avant deadline → payment_pending', async () => {
    const { partner, client, policy } = await seedActors();
    const { reservation } = await makeRequest(
      partner,
      client,
      policy,
      new Date('2027-08-20T14:00:00.000Z'),
      new Date('2027-08-22T11:00:00.000Z')
    );
    const updated = await approveHostRequest(reservation._id, partner._id);
    expect(updated.status).toBe('payment_pending');
    expect(updated.paymentDeadline).toBeTruthy();
    expect(await reservedCount(reservation._id)).toBeGreaterThan(0);
  });

  it('timeout → expired + inventory free', async () => {
    const { partner, client, policy } = await seedActors();
    const { reservation } = await makeRequest(
      partner,
      client,
      policy,
      new Date('2027-08-24T14:00:00.000Z'),
      new Date('2027-08-26T11:00:00.000Z')
    );
    await Reservation.updateOne(
      { _id: reservation._id },
      { $set: { hostApprovalDeadline: new Date(Date.now() - 1000) } }
    );
    const result = await expireHostApproval(reservation._id);
    expect(result.expired).toBe(true);
    const fresh = await Reservation.findById(reservation._id);
    expect(fresh.status).toBe('expired');
    expect(fresh.expirationReason).toBe('host_approval_timeout');
    expect(await reservedCount(reservation._id)).toBe(0);
  });

  it('approve après deadline mais avant Agenda → REFUSÉ + expire canonique', async () => {
    const { partner, client, policy } = await seedActors();
    const { reservation } = await makeRequest(
      partner,
      client,
      policy,
      new Date('2027-09-01T14:00:00.000Z'),
      new Date('2027-09-03T11:00:00.000Z')
    );
    await Reservation.updateOne(
      { _id: reservation._id },
      { $set: { hostApprovalDeadline: new Date(Date.now() - 500) } }
    );
    await expect(approveHostRequest(reservation._id, partner._id)).rejects.toMatchObject({
      statusCode: 409,
      errorCode: errorCodes.RESERVATION.APPROVAL_EXPIRED,
    });
    const fresh = await Reservation.findById(reservation._id);
    expect(fresh.status).toBe('expired');
    expect(fresh.expirationReason).toBe('host_approval_timeout');
  });

  it('5 jobs expiry → une seule expiration', async () => {
    const { partner, client, policy } = await seedActors();
    const { reservation } = await makeRequest(
      partner,
      client,
      policy,
      new Date('2027-09-10T14:00:00.000Z'),
      new Date('2027-09-12T11:00:00.000Z')
    );
    await Reservation.updateOne(
      { _id: reservation._id },
      { $set: { hostApprovalDeadline: new Date(Date.now() - 1000) } }
    );
    const results = await Promise.all([
      expireHostApproval(reservation._id),
      expireHostApproval(reservation._id),
      expireHostApproval(reservation._id),
      expireHostApproval(reservation._id),
      expireHostApproval(reservation._id),
    ]);
    expect(results.filter((r) => r.expired).length).toBe(1);
    expect(results.filter((r) => !r.expired).length).toBe(4);
    expect((await Reservation.findById(reservation._id)).status).toBe('expired');
  });

  it('approve vs expire (deadline future) : approve gagne, expire no-op', async () => {
    const { partner, client, policy } = await seedActors();
    const { reservation } = await makeRequest(
      partner,
      client,
      policy,
      new Date('2027-09-20T14:00:00.000Z'),
      new Date('2027-09-22T11:00:00.000Z')
    );
    const [approved, expired] = await Promise.all([
      approveHostRequest(reservation._id, partner._id),
      expireHostApproval(reservation._id),
    ]);
    expect(approved.status).toBe('payment_pending');
    expect(expired.expired).toBe(false);
    expect((await Reservation.findById(reservation._id)).status).toBe('payment_pending');
  });

  it('20 courses deadline passée : un seul état final cohérent (expired)', async () => {
    const { partner, client, policy } = await seedActors();
    for (let i = 0; i < 20; i += 1) {
      const { reservation } = await makeRequest(
        partner,
        client,
        policy,
        new Date('2028-01-10T14:00:00.000Z'),
        new Date('2028-01-12T11:00:00.000Z')
      );
      await Reservation.updateOne(
        { _id: reservation._id },
        { $set: { hostApprovalDeadline: new Date(Date.now() - 200) } }
      );
      const outcomes = await Promise.all([
        approveHostRequest(reservation._id, partner._id).then(() => 'approved').catch((err) => err.errorCode),
        expireHostApproval(reservation._id),
        expireHostApproval(reservation._id),
        approveHostRequest(reservation._id, partner._id).then(() => 'approved').catch((err) => err.errorCode),
      ]);
      const fresh = await Reservation.findById(reservation._id);
      expect(fresh.status).toBe('expired');
      expect(outcomes).not.toContain('approved');
      expect(await reservedCount(reservation._id)).toBe(0);
    }
  });

  it('après expiration, même dates acceptées pour un autre client', async () => {
    const { partner, client, policy } = await seedActors();
    const checkIn = new Date('2027-10-10T14:00:00.000Z');
    const checkOut = new Date('2027-10-15T11:00:00.000Z');
    const { residence, reservation } = await makeRequest(partner, client, policy, checkIn, checkOut);
    await Reservation.updateOne(
      { _id: reservation._id },
      { $set: { hostApprovalDeadline: new Date(Date.now() - 1000) } }
    );
    await expireHostApproval(reservation._id);

    const clientB = await User.create({
      email: `b-${Date.now()}@test.com`,
      password: 'Test1234',
      firstName: 'B',
      lastName: 'B',
      role: 'client',
    });
    const second = await createReservation({
      residence: residence._id,
      user: clientB._id,
      checkIn,
      checkOut,
      numberOfGuests: 1,
      bookingType: 'day',
    });
    expect(second.status).toBe('awaiting_approval');
    expect(String(second._id)).not.toBe(String(reservation._id));
  });
});
