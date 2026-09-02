const User = require('../../../src/models/user.model');
const Residence = require('../../../src/models/residence.model');
const Reservation = require('../../../src/models/reservation.model');
const CancellationPolicy = require('../../../src/models/cancellationPolicy.model');
const { createReservation } = require('../../../src/services/reservation.service');
const { createBlock, releaseBlock } = require('../../../src/services/partner-block.service');
const {
  createExternalReservation,
  cancelExternalReservation,
} = require('../../../src/services/external-reservation.service');
const {
  CALENDAR_TIMEZONE,
  overlaps,
  clipToDay,
  startOfUtcDay,
  addUtcDays,
  touchedUtcDays,
  getPublicCalendar,
  getPartnerCalendar,
  checkPublicAvailability,
} = require('../../../src/services/calendar-projection.service');
const { checkAvailabilityForFlutterApp } = require('../../../src/controllers/availability.controller');

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

function assertNoPublicPii(payload) {
  const json = JSON.stringify(payload);
  expect(json).not.toMatch(/guestName|guestPhone|externalReference|"channel"|"notes"|Jean Kouassi|\+22501020304|whatsapp/i);
  expect(json).not.toMatch(/manual_block|external_reservation|"sourceType"/);
}

async function invokeFlutterCheck({ residenceId, checkIn, checkOut }) {
  const req = { query: { residenceId: String(residenceId), checkIn, checkOut } };
  return new Promise((resolve, reject) => {
    const res = {
      statusCode: 200,
      body: null,
      status(code) {
        this.statusCode = code;
        return this;
      },
      json(payload) {
        this.body = payload;
        resolve(this);
      },
    };
    checkAvailabilityForFlutterApp(req, res, (err) => {
      if (err) reject(err);
    });
  });
}

describe('P1-04 Calendar projection', () => {
  it('timezone canonique Africa/Abidjan = UTC (pas de dérive locale)', () => {
    expect(CALENDAR_TIMEZONE).toBe('Africa/Abidjan');
    const start = new Date('2027-08-10T22:00:00.000Z');
    const end = new Date('2027-08-11T02:00:00.000Z');
    expect(touchedUtcDays(start, end)).toEqual(['2027-08-10', '2027-08-11']);
    expect(startOfUtcDay(start).toISOString()).toBe('2027-08-10T00:00:00.000Z');
  });

  it('day reservation 10→15 visible sur le calendrier', async () => {
    const { partner, client, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    await createReservation({
      residence: residence._id,
      user: client._id,
      checkIn: new Date('2027-08-10T14:00:00.000Z'),
      checkOut: new Date('2027-08-15T11:00:00.000Z'),
      numberOfGuests: 1,
      bookingType: 'day',
    });
    const pub = await getPublicCalendar(residence._id, '2027-08-01T00:00:00.000Z', '2027-08-31T00:00:00.000Z');
    expect(pub.occupations).toHaveLength(1);
    expect(pub.occupations[0].start).toBe('2027-08-10T14:00:00.000Z');
    expect(pub.occupations[0].end).toBe('2027-08-15T11:00:00.000Z');
    expect(pub.occupations[0].status).toBe('unavailable');
    const day10 = pub.days.find((d) => d.date === '2027-08-10');
    expect(day10.available).toBe(false);
  });

  it('block maintenance visible Partner, unavailable Client, sans source publique', async () => {
    const { partner, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    await createBlock(partner, {
      residenceId: residence._id,
      startDate: new Date('2027-08-15T14:00:00.000Z'),
      endDate: new Date('2027-08-17T11:00:00.000Z'),
      type: 'maintenance',
    });
    const partnerCal = await getPartnerCalendar(
      partner,
      residence._id,
      '2027-08-01T00:00:00.000Z',
      '2027-08-31T00:00:00.000Z'
    );
    expect(partnerCal.occupations[0].sourceType).toBe('manual_block');
    expect(partnerCal.occupations[0].blockType).toBe('maintenance');
    expect(partnerCal.occupations[0].status).toBe('blocked');

    const pub = await getPublicCalendar(residence._id, '2027-08-01T00:00:00.000Z', '2027-08-31T00:00:00.000Z');
    expect(pub.occupations[0].status).toBe('unavailable');
    expect(pub.occupations[0].sourceType).toBeUndefined();
    assertNoPublicPii(pub);
    const occupancy = await checkPublicAvailability(
      residence._id,
      new Date('2027-08-15T14:00:00.000Z'),
      new Date('2027-08-16T11:00:00.000Z')
    );
    expect(occupancy.available).toBe(false);
  });

  it('external visible Partner avec PII, public seulement unavailable', async () => {
    const { partner, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    await createExternalReservation(partner, {
      residenceId: residence._id,
      checkIn: new Date('2027-08-17T14:00:00.000Z'),
      checkOut: new Date('2027-08-20T11:00:00.000Z'),
      channel: 'whatsapp',
      guestName: 'Jean Kouassi',
      guestPhone: '+22501020304',
      notes: 'via WhatsApp',
      externalReference: 'WA-99',
    });
    const partnerCal = await getPartnerCalendar(
      partner,
      residence._id,
      '2027-08-01T00:00:00.000Z',
      '2027-08-31T00:00:00.000Z'
    );
    expect(partnerCal.occupations[0].sourceType).toBe('external_reservation');
    expect(partnerCal.occupations[0].guestName).toBe('Jean Kouassi');
    expect(partnerCal.occupations[0].channel).toBe('whatsapp');

    const pub = await getPublicCalendar(residence._id, '2027-08-01T00:00:00.000Z', '2027-08-31T00:00:00.000Z');
    expect(pub.occupations[0].status).toBe('unavailable');
    assertNoPublicPii(pub);
  });

  it('hour block 13:00→15:00 projeté sur le jour avec slot horaire', async () => {
    const { partner, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    await createBlock(partner, {
      residenceId: residence._id,
      startDate: new Date('2027-08-10T13:00:00.000Z'),
      endDate: new Date('2027-08-10T15:00:00.000Z'),
      bookingType: 'hour',
      type: 'cleaning',
    });
    const pub = await getPublicCalendar(residence._id, '2027-08-10T00:00:00.000Z', '2027-08-11T00:00:00.000Z');
    expect(pub.occupations[0].start).toBe('2027-08-10T13:00:00.000Z');
    expect(pub.occupations[0].end).toBe('2027-08-10T15:00:00.000Z');
    const day = pub.days.find((d) => d.date === '2027-08-10');
    expect(day.slots[0].start).toBe('2027-08-10T13:00:00.000Z');
    expect(day.slots[0].end).toBe('2027-08-10T15:00:00.000Z');
  });

  it('hour external 13:00→15:00 projeté pareil', async () => {
    const { partner, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    await createExternalReservation(partner, {
      residenceId: residence._id,
      checkIn: new Date('2027-08-10T13:00:00.000Z'),
      checkOut: new Date('2027-08-10T15:00:00.000Z'),
      bookingType: 'hour',
    });
    const pub = await getPublicCalendar(residence._id, '2027-08-10T00:00:00.000Z', '2027-08-11T00:00:00.000Z');
    expect(pub.occupations[0].start).toBe('2027-08-10T13:00:00.000Z');
    expect(pub.occupations[0].end).toBe('2027-08-10T15:00:00.000Z');
  });

  it('back-to-back 13→15 et 15→17 : deux occupations adjacentes, pas chevauchantes', async () => {
    const { partner, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    await createBlock(partner, {
      residenceId: residence._id,
      startDate: new Date('2027-08-10T13:00:00.000Z'),
      endDate: new Date('2027-08-10T15:00:00.000Z'),
      bookingType: 'hour',
    });
    await createExternalReservation(partner, {
      residenceId: residence._id,
      checkIn: new Date('2027-08-10T15:00:00.000Z'),
      checkOut: new Date('2027-08-10T17:00:00.000Z'),
      bookingType: 'hour',
    });
    const startA = new Date('2027-08-10T13:00:00.000Z');
    const endA = new Date('2027-08-10T15:00:00.000Z');
    const startB = new Date('2027-08-10T15:00:00.000Z');
    const endB = new Date('2027-08-10T17:00:00.000Z');
    expect(overlaps(startA, endA, startB, endB)).toBe(false);

    const pub = await getPublicCalendar(residence._id, '2027-08-10T00:00:00.000Z', '2027-08-11T00:00:00.000Z');
    expect(pub.occupations).toHaveLength(2);
    expect(pub.occupations[0].end).toBe(pub.occupations[1].start);
  });

  it('flutter-check : external hour 13→15 rend 14→16 unavailable', async () => {
    const { partner, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    await createExternalReservation(partner, {
      residenceId: residence._id,
      checkIn: new Date('2027-08-10T13:00:00.000Z'),
      checkOut: new Date('2027-08-10T15:00:00.000Z'),
      bookingType: 'hour',
      guestName: 'Jean Kouassi',
      guestPhone: '+22501020304',
      channel: 'whatsapp',
    });
    const res = await invokeFlutterCheck({
      residenceId: residence._id,
      checkIn: '2027-08-10T14:00:00.000Z',
      checkOut: '2027-08-10T16:00:00.000Z',
    });
    expect(res.statusCode).toBe(200);
    expect(res.body.data.isAvailable).toBe(false);
    assertNoPublicPii(res.body);
  });

  it('cross-midnight 22:00→02:00 projeté sur les deux dates UTC', async () => {
    const { partner, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    await createBlock(partner, {
      residenceId: residence._id,
      startDate: new Date('2027-08-10T22:00:00.000Z'),
      endDate: new Date('2027-08-11T02:00:00.000Z'),
      bookingType: 'hour',
    });
    const pub = await getPublicCalendar(residence._id, '2027-08-10T00:00:00.000Z', '2027-08-12T00:00:00.000Z');
    expect(pub.occupations).toHaveLength(1);
    const day10 = pub.days.find((d) => d.date === '2027-08-10');
    const day11 = pub.days.find((d) => d.date === '2027-08-11');
    expect(day10.available).toBe(false);
    expect(day11.available).toBe(false);
    expect(day10.slots[0].start).toBe('2027-08-10T22:00:00.000Z');
    expect(day10.slots[0].end).toBe('2027-08-11T00:00:00.000Z');
    expect(day11.slots[0].start).toBe('2027-08-11T00:00:00.000Z');
    expect(day11.slots[0].end).toBe('2027-08-11T02:00:00.000Z');

    const dayStart = startOfUtcDay(new Date('2027-08-10T22:00:00.000Z'));
    const clipped = clipToDay(
      new Date('2027-08-10T22:00:00.000Z'),
      new Date('2027-08-11T02:00:00.000Z'),
      dayStart,
      addUtcDays(dayStart, 1)
    );
    expect(clipped.end.toISOString()).toBe('2027-08-11T00:00:00.000Z');
  });

  it('mixte Reservation + Block hour + External, projection cohérente', async () => {
    const { partner, client, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    await createReservation({
      residence: residence._id,
      user: client._id,
      checkIn: new Date('2027-08-10T14:00:00.000Z'),
      checkOut: new Date('2027-08-12T11:00:00.000Z'),
      numberOfGuests: 1,
      bookingType: 'day',
    });
    await createBlock(partner, {
      residenceId: residence._id,
      startDate: new Date('2027-08-12T13:00:00.000Z'),
      endDate: new Date('2027-08-12T15:00:00.000Z'),
      bookingType: 'hour',
      type: 'maintenance',
    });
    await createExternalReservation(partner, {
      residenceId: residence._id,
      checkIn: new Date('2027-08-13T14:00:00.000Z'),
      checkOut: new Date('2027-08-16T11:00:00.000Z'),
      channel: 'airbnb',
      guestName: 'Jean Kouassi',
    });

    const partnerCal = await getPartnerCalendar(
      partner,
      residence._id,
      '2027-08-01T00:00:00.000Z',
      '2027-08-31T00:00:00.000Z'
    );
    expect(partnerCal.occupations.map((o) => o.sourceType)).toEqual([
      'reservation',
      'manual_block',
      'external_reservation',
    ]);

    const pub = await getPublicCalendar(residence._id, '2027-08-01T00:00:00.000Z', '2027-08-31T00:00:00.000Z');
    expect(pub.occupations).toHaveLength(3);
    assertNoPublicPii(pub);
  });

  it('expired / cancelled / released n\'apparaissent pas comme occupation active', async () => {
    const { partner, client, policy } = await seedActors();
    const residence = await seedResidence(partner, policy);
    const reservation = await createReservation({
      residence: residence._id,
      user: client._id,
      checkIn: new Date('2027-09-10T14:00:00.000Z'),
      checkOut: new Date('2027-09-12T11:00:00.000Z'),
      numberOfGuests: 1,
      bookingType: 'day',
    });
    await Reservation.updateOne({ _id: reservation._id }, { $set: { status: 'expired' } });

    const block = await createBlock(partner, {
      residenceId: residence._id,
      startDate: new Date('2027-09-12T14:00:00.000Z'),
      endDate: new Date('2027-09-13T11:00:00.000Z'),
    });
    await releaseBlock(partner, block._id);

    const external = await createExternalReservation(partner, {
      residenceId: residence._id,
      checkIn: new Date('2027-09-14T14:00:00.000Z'),
      checkOut: new Date('2027-09-16T11:00:00.000Z'),
    });
    await cancelExternalReservation(partner, external._id);

    const pub = await getPublicCalendar(residence._id, '2027-09-01T00:00:00.000Z', '2027-09-30T00:00:00.000Z');
    expect(pub.occupations).toHaveLength(0);
    expect(pub.days.every((d) => d.available)).toBe(true);
  });

  it('Partner A ne peut pas lire le calendrier enrichi de Partner B', async () => {
    const { partner, policy } = await seedActors();
    const other = await User.create({
      email: `p2-${Date.now()}@test.com`,
      password: 'Test1234',
      firstName: 'Other',
      lastName: 'Partner',
      role: 'partner',
    });
    const residence = await seedResidence(partner, policy);
    await expect(getPartnerCalendar(
      other,
      residence._id,
      '2027-08-01T00:00:00.000Z',
      '2027-08-31T00:00:00.000Z'
    )).rejects.toMatchObject({ statusCode: 403 });
  });
});
