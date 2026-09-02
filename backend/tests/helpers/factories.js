const User = require('../../src/models/user.model');
const Residence = require('../../src/models/residence.model');
const Reservation = require('../../src/models/reservation.model');
const Payment = require('../../src/models/payment.model');
const { generateAccessToken } = require('../../src/utils/jwt');
const { residenceAttrs, reservationSnapshotAttrs } = require('./residence.fixture');

function stamp() {
  return `${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

async function createUser(role, extra = {}) {
  const id = stamp();
  return User.create({
    email: `${role}-${id}@test.com`,
    password: extra.password || 'Test1234',
    firstName: extra.firstName || role,
    lastName: extra.lastName || 'User',
    phoneNumber: extra.phoneNumber,
    role,
    isActive: extra.isActive !== false,
    ...extra,
  });
}

const createClient = (extra) => createUser('client', extra);
const createPartner = (extra) => createUser('partner', extra);
const createAdmin = (extra) => createUser('admin', extra);
const createSuperadmin = (extra) => createUser('superadmin', extra);

function authHeader(user) {
  return `Bearer ${generateAccessToken(user._id.toString(), user.role)}`;
}

/** JWT avec un rôle claim différent du rôle Mongo — le runtime doit ignorer le claim. */
function authHeaderWithJwtRole(user, jwtRole) {
  return `Bearer ${generateAccessToken(user._id.toString(), jwtRole)}`;
}

async function createResidence(partner, extra = {}) {
  return Residence.create(residenceAttrs({
    partner: partner._id || partner,
    ...extra,
  }));
}

function fixedStay(start = '2026-09-01T12:00:00.000Z', end = '2026-09-05T12:00:00.000Z') {
  return {
    checkIn: new Date(start),
    checkOut: new Date(end),
  };
}

async function createReservation(user, residence, extra = {}) {
  const stay = extra.checkIn ? {} : fixedStay();
  return Reservation.create({
    user: user._id || user,
    residence: residence._id || residence,
    status: extra.status || 'pending',
    ...stay,
    ...reservationSnapshotAttrs(),
    ...extra,
  });
}

async function createPayment(reservation, extra = {}) {
  return Payment.create({
    reservation: reservation._id || reservation,
    amount: extra.amount || 50000,
    status: extra.status || 'pending',
    paymentMethod: extra.paymentMethod || 'wave',
    paymentProvider: extra.paymentProvider || 'wave',
    ...extra,
  });
}

async function createPayout(partner, extra = {}) {
  const Payout = require('../../src/models/payout.model');
  const amount = extra.net_amount || extra.amount || 10000;
  return Payout.create({
    payout_id: extra.payout_id || `PO-${stamp()}`,
    partner: partner._id || partner,
    source_transactions: extra.source_transactions || [],
    gross_amount: extra.gross_amount || amount,
    commission_amount: extra.commission_amount || 0,
    commission_rate: extra.commission_rate || 0,
    net_amount: amount,
    channel: extra.channel || 'wave',
    recipient_info: extra.recipient_info || {
      phone_prefix: '225',
      phone_number: '0700000000',
      full_name: 'Test Partner',
      email: 'partner-payout@test.com',
    },
    ...extra,
  });
}

module.exports = {
  createUser,
  createClient,
  createPartner,
  createAdmin,
  createSuperadmin,
  authHeader,
  authHeaderWithJwtRole,
  createResidence,
  createReservation,
  createPayment,
  createPayout,
  fixedStay,
};
