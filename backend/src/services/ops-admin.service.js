/**
 * P1-07 — centre Ops Admin Reservation / Payment / Inventory.
 *
 * Règle : Dashboard → action métier → ce service → ReservationStateService / refund.service
 * Jamais : PATCH status libre depuis React.
 */
const crypto = require('crypto');
const mongoose = require('mongoose');
const Reservation = require('../models/reservation.model');
const Payment = require('../models/payment.model');
const User = require('../models/user.model');
const Residence = require('../models/residence.model');
const Availability = require('../models/availability.model');
const OpsAuditLog = require('../models/ops-audit-log.model');
const ActivityLog = require('../models/activityLog.model');
const ReservationStateService = require('./reservation-state.service');
const CalendarProjectionService = require('./calendar-projection.service');
const { release } = require('./inventory.service');
const {
  markRefundRequired,
  processPaymentRefund,
  confirmManualRefund,
} = require('./refund.service');
const { ACTIVE_BLOCKING_STATUSES } = require('../constants/reservation-status');
const ApiError = require('../utils/apiError');
const errorCodes = require('../utils/errorCodes');
const logger = require('../utils/logger');

const CANCELABLE_STATUSES = [
  'pending',
  'awaiting_approval',
  'payment_pending',
  'confirmed',
  'in_stay',
];

const REFUND_BUCKETS = Object.freeze({
  required: 'required',
  pending: 'pending',
  failed: 'failed',
  ops_required: 'ops_required',
  refunded: 'refunded',
});

function displayName(user) {
  if (!user) return null;
  const composed = `${user.firstName || ''} ${user.lastName || ''}`.trim();
  return composed || user.name || user.email || null;
}

function allowedReservationActions(reservation) {
  const status = reservation?.status;
  const paymentStatus = reservation?.paymentStatus;
  const actions = [];
  if (CANCELABLE_STATUSES.includes(status)) {
    actions.push('cancel');
  }
  if (status === 'confirmed' && paymentStatus === 'paid') {
    actions.push('checkin');
  }
  if (status === 'in_stay') {
    actions.push('checkout');
  }
  return actions;
}

function inventoryStateFor(reservation) {
  return ACTIVE_BLOCKING_STATUSES.includes(reservation.status)
    ? 'occupying'
    : 'released';
}

function assertActionAllowed(reservation, action) {
  const allowed = allowedReservationActions(reservation);
  if (!allowed.includes(action)) {
    throw new ApiError(
      `Action '${action}' non autorisée pour le statut ${reservation.status}`,
      400,
      errorCodes.RESERVATION.INVALID_STATE_TRANSITION
    );
  }
}

function requireReason(reason, min = 5) {
  const text = String(reason || '').trim();
  if (text.length < min) {
    throw new ApiError(
      `Un motif d'au moins ${min} caractères est requis`,
      400,
      errorCodes.GENERAL.VALIDATION_ERROR
    );
  }
  return text;
}

function parsePageLimit(query) {
  const page = Math.max(1, parseInt(query.page, 10) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(query.limit, 10) || 20));
  return { page, limit, skip: (page - 1) * limit };
}

function requestTrace(req) {
  const headers = req?.headers || {};
  const incoming = headers['x-request-id'] || headers['x-correlation-id'] || req?.id;
  const requestId = String(incoming || crypto.randomUUID()).slice(0, 80);
  const correlationId = String(headers['x-correlation-id'] || requestId).slice(0, 80);
  return { requestId, correlationId };
}

async function logOps(entry, req, actor = null) {
  const trace = requestTrace(req);
  const payload = {
    ...entry,
    actorRole: entry.actorRole || actor?.role || req?.user?.role || 'unknown',
    requestId: entry.requestId || trace.requestId,
    correlationId: entry.correlationId || trace.correlationId,
  };
  try {
    await OpsAuditLog.create(payload);
  } catch (err) {
    logger.error('OPS_AUDIT_WRITE_FAILED', { err: err.message, action: entry.action });
  }
  try {
    const actionMap = {
      cancel: 'ops_cancel',
      checkin: 'ops_checkin',
      checkout: 'ops_checkout',
      refund_confirm: 'ops_refund_confirm',
    };
    await ActivityLog.create({
      user: entry.actor,
      action: actionMap[entry.action] || 'reservation_updated',
      module: 'ops',
      description: entry.reason || entry.action,
      ipAddress: req?.ip || '127.0.0.1',
      userAgent: req?.headers?.['user-agent'] || 'ops',
      metadata: {
        entityType: entry.entityType,
        entityId: String(entry.entityId),
        requestId: payload.requestId,
        correlationId: payload.correlationId,
        actorRole: payload.actorRole,
        ...(entry.metadata || {}),
      },
    });
  } catch (err) {
    logger.warn('OPS_ACTIVITY_LOG_FAILED', { err: err.message });
  }
}

function latestPaymentByReservation(payments) {
  const map = new Map();
  for (const payment of payments) {
    const key = String(payment.reservation);
    if (!map.has(key)) map.set(key, payment);
  }
  return map;
}

function mapPaymentSummary(payment) {
  if (!payment) return null;
  return {
    _id: payment._id,
    status: payment.status,
    amount: payment.amount,
    currency: payment.currency || 'XOF',
    provider: payment.paymentProvider,
    paymentMethod: payment.paymentMethod,
    transactionId: payment.transactionId || null,
    refundStatus: payment.refundStatus || 'not_required',
    refundOpsRequired: Boolean(payment.refundOpsRequired),
    refundReason: payment.refundReason || null,
    refundAttempts: payment.refundAttempts || 0,
    refundLastError: payment.refundLastError || null,
    refundLastAttemptAt: payment.refundLastAttemptAt || null,
    refundOpsConfirmedAt: payment.refundOpsConfirmedAt || null,
    createdAt: payment.createdAt,
    updatedAt: payment.updatedAt,
  };
}

function mapReservationDto(reservation, payment) {
  const client = reservation.user;
  const partner = reservation.partner;
  const residence = reservation.residence;
  return {
    _id: reservation._id,
    checkIn: reservation.checkIn,
    checkOut: reservation.checkOut,
    actualCheckIn: reservation.actualCheckIn || null,
    actualCheckOut: reservation.actualCheckOut || null,
    bookingType: reservation.bookingType || 'day',
    status: reservation.status,
    paymentStatus: reservation.paymentStatus,
    reservationMode: reservation.reservationModeSnapshot || reservation.reservationMode,
    hostApprovalDeadline: reservation.hostApprovalDeadline || null,
    paymentDeadline: reservation.paymentDeadline || null,
    totalPrice: reservation.totalPrice,
    numberOfGuests: reservation.numberOfGuests,
    residence: residence
      ? {
          _id: residence._id,
          title: residence.title,
          city: residence.city,
          address: residence.address,
        }
      : null,
    client: client
      ? {
          _id: client._id,
          firstName: client.firstName,
          lastName: client.lastName,
          email: client.email,
          phoneNumber: client.phoneNumber,
          name: displayName(client),
        }
      : null,
    partner: partner
      ? {
          _id: partner._id,
          firstName: partner.firstName,
          lastName: partner.lastName,
          email: partner.email,
          name: displayName(partner),
        }
      : null,
    payment: mapPaymentSummary(payment),
    inventoryState: inventoryStateFor(reservation),
    allowedActions: allowedReservationActions(reservation),
    statusHistory: reservation.statusHistory || [],
    createdAt: reservation.createdAt,
    updatedAt: reservation.updatedAt,
  };
}

async function attachPayments(reservations) {
  const ids = reservations.map((r) => r._id);
  const payments = await Payment.find({ reservation: { $in: ids } })
    .sort({ createdAt: -1 })
    .lean();
  const latest = latestPaymentByReservation(payments);
  return reservations.map((reservation) =>
    mapReservationDto(reservation, latest.get(String(reservation._id)))
  );
}

async function listReservations(query = {}) {
  const { page, limit, skip } = parsePageLimit(query);
  const filter = {};

  if (query.status) {
    const statuses = Array.isArray(query.status)
      ? query.status
      : String(query.status).split(',').map((s) => s.trim()).filter(Boolean);
    if (statuses.length === 1) filter.status = statuses[0];
    else if (statuses.length > 1) filter.status = { $in: statuses };
  }
  if (query.paymentStatus) filter.paymentStatus = query.paymentStatus;
  if (query.residenceId && mongoose.isValidObjectId(query.residenceId)) {
    filter.residence = query.residenceId;
  }
  if (query.partnerId && mongoose.isValidObjectId(query.partnerId)) {
    filter.partner = query.partnerId;
  }
  if (query.clientId && mongoose.isValidObjectId(query.clientId)) {
    filter.user = query.clientId;
  }
  if (query.startDate || query.endDate) {
    filter.checkIn = {};
    if (query.startDate) filter.checkIn.$gte = new Date(query.startDate);
    if (query.endDate) filter.checkIn.$lte = new Date(query.endDate);
  }

  const search = String(query.search || query.searchQuery || '').trim();
  if (search) {
    if (mongoose.isValidObjectId(search)) {
      filter._id = search;
    } else {
      const rx = new RegExp(search.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
      const [users, residences] = await Promise.all([
        User.find({
          $or: [{ email: rx }, { firstName: rx }, { lastName: rx }],
        }).select('_id').lean(),
        Residence.find({ title: rx }).select('_id').lean(),
      ]);
      filter.$or = [
        { user: { $in: users.map((u) => u._id) } },
        { partner: { $in: users.map((u) => u._id) } },
        { residence: { $in: residences.map((r) => r._id) } },
      ];
    }
  }

  const [rows, total] = await Promise.all([
    Reservation.find(filter)
      .populate('user', 'firstName lastName email phoneNumber')
      .populate('partner', 'firstName lastName email')
      .populate('residence', 'title city address')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean(),
    Reservation.countDocuments(filter),
  ]);

  const data = await attachPayments(rows);
  return {
    data,
    pagination: {
      page,
      limit,
      total,
      pages: Math.max(1, Math.ceil(total / limit)),
    },
  };
}

async function getReservation(id) {
  if (!mongoose.isValidObjectId(id)) {
    throw new ApiError('Réservation introuvable', 404, errorCodes.RESERVATION.NOT_FOUND);
  }
  const reservation = await Reservation.findById(id)
    .populate('user', 'firstName lastName email phoneNumber')
    .populate('partner', 'firstName lastName email')
    .populate('residence', 'title city address partner')
    .lean();
  if (!reservation) {
    throw new ApiError('Réservation introuvable', 404, errorCodes.RESERVATION.NOT_FOUND);
  }
  const payment = await Payment.findOne({ reservation: reservation._id }).sort({ createdAt: -1 }).lean();
  const dto = mapReservationDto(reservation, payment);
  let occupations = [];
  if (reservation.residence?._id && reservation.checkIn && reservation.checkOut) {
    occupations = await CalendarProjectionService.loadActiveOccupations(
      reservation.residence._id,
      reservation.checkIn,
      reservation.checkOut
    );
  }
  const audit = await OpsAuditLog.find({
    entityType: 'reservation',
    entityId: reservation._id,
  })
    .sort({ createdAt: -1 })
    .limit(50)
    .lean();

  return {
    ...dto,
    cancellationDetails: reservation.cancellationDetails || null,
    inventoryOccupations: occupations.map((occ) => ({
      id: String(occ.id),
      sourceType: occ.sourceType,
      status: occ.status,
      start: occ.start,
      end: occ.end,
      bookingType: occ.bookingType,
      blockType: occ.blockType || null,
    })),
    opsAudit: audit,
  };
}

async function cancelReservation(id, actor, { reason } = {}, req = null) {
  const motif = requireReason(reason);
  const reservation = await Reservation.findById(id);
  if (!reservation) {
    throw new ApiError('Réservation introuvable', 404, errorCodes.RESERVATION.NOT_FOUND);
  }
  assertActionAllowed(reservation, 'cancel');
  const before = { status: reservation.status, paymentStatus: reservation.paymentStatus };

  const updated = await ReservationStateService.updateStatus(
    id,
    'cancelled',
    actor._id,
    {
      reason: motif,
      fromStatuses: CANCELABLE_STATUSES.filter((s) =>
        ReservationStateService.isTransitionAllowed(s, 'cancelled')),
    }
  );
  if (!updated) {
    throw new ApiError('Échec de l\'annulation', 409, errorCodes.RESERVATION.CONCURRENT_MODIFICATION);
  }

  try {
    await release({
      residenceId: reservation.residence,
      checkIn: reservation.checkIn,
      checkOut: reservation.checkOut,
      reservationId: reservation._id,
      bookingType: reservation.bookingType || 'day',
    });
  } catch (err) {
    logger.error('OPS_CANCEL_INVENTORY_RELEASE_FAILED', {
      reservationId: String(id),
      err: err.message,
    });
  }

  const payment = await Payment.findOne({ reservation: id, status: 'paid' }).sort({ createdAt: -1 });
  if (payment) {
    await markRefundRequired(payment, `ops_cancel:${motif}`.slice(0, 200));
    try {
      await processPaymentRefund(payment._id);
    } catch (err) {
      logger.warn('OPS_CANCEL_REFUND_PROCESS', { paymentId: String(payment._id), err: err.message });
    }
  }

  await logOps({
    actor: actor._id,
    action: 'cancel',
    entityType: 'reservation',
    entityId: reservation._id,
    reason: motif,
    before,
    after: { status: 'cancelled' },
  }, req, actor);

  return getReservation(id);
}

async function checkinReservation(id, actor, { reason } = {}, req = null) {
  const motif = requireReason(reason, 3);
  const reservation = await Reservation.findById(id);
  if (!reservation) {
    throw new ApiError('Réservation introuvable', 404, errorCodes.RESERVATION.NOT_FOUND);
  }
  assertActionAllowed(reservation, 'checkin');
  const before = { status: reservation.status, actualCheckIn: reservation.actualCheckIn };

  const updated = await ReservationStateService.updateStatus(id, 'in_stay', actor._id, {
    reason: motif,
    fromStatuses: ['confirmed'],
  });

  await logOps({
    actor: actor._id,
    action: 'checkin',
    entityType: 'reservation',
    entityId: reservation._id,
    reason: motif,
    before,
    after: { status: 'in_stay' },
  }, req, actor);

  if (before.status === 'confirmed' && updated.status === 'in_stay') {
    try {
      const SocketService = require('./socket.service');
      SocketService.emitReservationStatusChange(updated, before.status, 'in_stay');
    } catch (socketErr) {
      logger.warn('Ops check-in socket emit failed:', socketErr?.message);
    }
  }

  return getReservation(id);
}

async function checkoutReservation(id, actor, { reason } = {}, req = null) {
  const motif = requireReason(reason, 3);
  const reservation = await Reservation.findById(id);
  if (!reservation) {
    throw new ApiError('Réservation introuvable', 404, errorCodes.RESERVATION.NOT_FOUND);
  }
  assertActionAllowed(reservation, 'checkout');
  if (reservation.status !== 'in_stay' || !reservation.actualCheckIn) {
    throw new ApiError(
      'Le check-out n\'est possible qu\'après un check-in (statut in_stay)',
      400,
      errorCodes.RESERVATION.INVALID_STATE_TRANSITION
    );
  }
  const before = { status: reservation.status, actualCheckOut: reservation.actualCheckOut };

  const updated = await ReservationStateService.updateStatus(id, 'completed', actor._id, {
    reason: motif,
    fromStatuses: ['in_stay'],
  });

  await logOps({
    actor: actor._id,
    action: 'checkout',
    entityType: 'reservation',
    entityId: reservation._id,
    reason: motif,
    before,
    after: { status: 'completed' },
  }, req, actor);

  if (before.status === 'in_stay' && updated.status === 'completed') {
    try {
      const SocketService = require('./socket.service');
      SocketService.emitReservationStatusChange(updated, before.status, 'completed');
    } catch (socketErr) {
      logger.warn('Ops checkout socket emit failed:', socketErr?.message);
    }
  }

  return getReservation(id);
}

function refundBucketFilter(bucket) {
  switch (bucket) {
    case REFUND_BUCKETS.required:
      return {
        status: 'paid',
        refundStatus: 'required',
        refundOpsRequired: { $ne: true },
      };
    case REFUND_BUCKETS.pending:
      return { refundStatus: 'pending' };
    case REFUND_BUCKETS.failed:
      return { refundStatus: 'failed' };
    case REFUND_BUCKETS.ops_required:
      return { refundOpsRequired: true, status: { $ne: 'refunded' } };
    case REFUND_BUCKETS.refunded:
      return {
        $or: [{ status: 'refunded' }, { refundStatus: 'succeeded' }],
      };
    default:
      return {
        $or: [
          { refundStatus: { $in: ['required', 'pending', 'failed', 'succeeded'] } },
          { refundOpsRequired: true },
        ],
      };
  }
}

async function listRefunds(query = {}) {
  const { page, limit, skip } = parsePageLimit(query);
  const bucket = query.bucket || query.queue || 'all';
  const filter = refundBucketFilter(bucket);

  const [rows, total, counts] = await Promise.all([
    Payment.find(filter)
      .populate({
        path: 'reservation',
        select: 'status paymentStatus checkIn checkOut user partner residence totalPrice',
        populate: [
          { path: 'user', select: 'firstName lastName email phoneNumber' },
          { path: 'partner', select: 'firstName lastName email' },
          { path: 'residence', select: 'title city' },
        ],
      })
      .sort({ refundOpsRequired: -1, updatedAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean(),
    Payment.countDocuments(filter),
    Payment.aggregate([
      {
        $facet: {
          required: [
            { $match: refundBucketFilter(REFUND_BUCKETS.required) },
            { $count: 'n' },
          ],
          pending: [
            { $match: refundBucketFilter(REFUND_BUCKETS.pending) },
            { $count: 'n' },
          ],
          failed: [
            { $match: refundBucketFilter(REFUND_BUCKETS.failed) },
            { $count: 'n' },
          ],
          ops_required: [
            { $match: refundBucketFilter(REFUND_BUCKETS.ops_required) },
            { $count: 'n' },
          ],
          refunded: [
            { $match: refundBucketFilter(REFUND_BUCKETS.refunded) },
            { $count: 'n' },
          ],
        },
      },
    ]),
  ]);

  const facet = counts[0] || {};
  const countOf = (key) => facet[key]?.[0]?.n || 0;

  return {
    data: rows.map((payment) => ({
      ...mapPaymentSummary(payment),
      reason: payment.refundReason || null,
      lastAttemptAt: payment.refundLastAttemptAt || payment.updatedAt,
      retryCount: payment.refundAttempts || 0,
      reservation: payment.reservation
        ? {
            _id: payment.reservation._id,
            status: payment.reservation.status,
            paymentStatus: payment.reservation.paymentStatus,
            checkIn: payment.reservation.checkIn,
            checkOut: payment.reservation.checkOut,
            residence: payment.reservation.residence,
            client: payment.reservation.user
              ? {
                  _id: payment.reservation.user._id,
                  name: displayName(payment.reservation.user),
                  email: payment.reservation.user.email,
                }
              : null,
            partner: payment.reservation.partner
              ? {
                  _id: payment.reservation.partner._id,
                  name: displayName(payment.reservation.partner),
                }
              : null,
          }
        : null,
      allowedActions: payment.refundOpsRequired && payment.status === 'paid'
        ? ['confirm_manual_refund']
        : [],
    })),
    counts: {
      required: countOf('required'),
      pending: countOf('pending'),
      failed: countOf('failed'),
      ops_required: countOf('ops_required'),
      refunded: countOf('refunded'),
    },
    pagination: {
      page,
      limit,
      total,
      pages: Math.max(1, Math.ceil(total / limit)),
    },
  };
}

async function confirmRefund(paymentId, actor, body = {}, req = null) {
  const note = requireReason(body.note, 8);
  const externalReference = String(body.externalReference || body.transactionId || '').trim();
  if (externalReference.length < 3) {
    throw new ApiError(
      'La référence externe du remboursement (Wave/CinetPay) est requise',
      400,
      errorCodes.GENERAL.VALIDATION_ERROR
    );
  }

  let payment;
  try {
    payment = await confirmManualRefund(paymentId, {
      actorId: actor._id,
      note,
      externalReference,
    });
  } catch (err) {
    if (err.message === 'PAYMENT_NOT_FOUND') {
      throw new ApiError('Paiement introuvable', 404, errorCodes.GENERAL.NOT_FOUND);
    }
    if (err.message === 'NOTE_REQUIRED' || err.message === 'EXTERNAL_REF_REQUIRED') {
      throw new ApiError(err.message, 400, errorCodes.GENERAL.VALIDATION_ERROR);
    }
    throw new ApiError(
      'Ce paiement ne peut pas être marqué remboursé (refundOpsRequired + paid requis)',
      err.statusCode || 409,
      errorCodes.GENERAL.BAD_REQUEST
    );
  }

  const reservation = await Reservation.findById(payment.reservation);
  if (reservation) {
    if (['cancelled', 'completed'].includes(reservation.status)) {
      try {
        await ReservationStateService.updateStatus(reservation._id, 'refunded', actor._id, {
          reason: `ops_refund_confirm:${note}`.slice(0, 200),
        });
      } catch (err) {
        logger.warn('OPS_REFUND_RESERVATION_STATUS', { err: err.message });
      }
    }
    await Reservation.updateOne(
      { _id: reservation._id },
      { $set: { paymentStatus: 'refunded' } }
    );
  }

  await logOps({
    actor: actor._id,
    action: 'refund_confirm',
    entityType: 'payment',
    entityId: payment._id,
    reason: note,
    metadata: { externalReference, reservationId: String(payment.reservation) },
    before: { status: 'paid', refundOpsRequired: true },
    after: { status: 'refunded', refundStatus: 'succeeded' },
  }, req, actor);

  return mapPaymentSummary(payment.toObject ? payment.toObject() : payment);
}

async function getInventoryCalendar(user, residenceId, startDate, endDate) {
  return CalendarProjectionService.getPartnerCalendar(user, residenceId, startDate, endDate);
}

function overlapPairs(reservations) {
  const byResidence = new Map();
  for (const row of reservations) {
    const key = String(row.residence);
    if (!byResidence.has(key)) byResidence.set(key, []);
    byResidence.get(key).push(row);
  }
  const pairs = [];
  for (const [residenceId, list] of byResidence) {
    const sorted = list.slice().sort((a, b) => a.checkIn - b.checkIn);
    for (let i = 0; i < sorted.length; i += 1) {
      for (let j = i + 1; j < sorted.length; j += 1) {
        if (sorted[j].checkIn >= sorted[i].checkOut) break;
        if (sorted[i].checkIn < sorted[j].checkOut && sorted[j].checkIn < sorted[i].checkOut) {
          pairs.push({
            residenceId,
            a: String(sorted[i]._id),
            b: String(sorted[j]._id),
            aRange: { checkIn: sorted[i].checkIn, checkOut: sorted[i].checkOut },
            bRange: { checkIn: sorted[j].checkIn, checkOut: sorted[j].checkOut },
          });
        }
      }
    }
  }
  return pairs;
}

async function listAnomalies() {
  const LIMIT = 50;
  const staleApprovalBefore = new Date(Date.now() - 48 * 60 * 60 * 1000);

  const [
    paidPlusExpired,
    confirmedUnpaid,
    staleAwaitingApproval,
    overduePaymentPending,
    refundOpsRequired,
    refundFailed,
    activeReservations,
    reservedWithId,
  ] = await Promise.all([
    Payment.aggregate([
      { $match: { status: 'paid' } },
      {
        $lookup: {
          from: 'reservations',
          localField: 'reservation',
          foreignField: '_id',
          as: 'res',
        },
      },
      { $unwind: { path: '$res', preserveNullAndEmptyArrays: true } },
      { $match: { 'res.status': 'expired' } },
      { $project: { _id: 1, refundStatus: 1, refundOpsRequired: 1, reservation: 1, amount: 1 } },
      { $limit: LIMIT },
    ]),
    Reservation.find({
      status: { $in: ['confirmed', 'in_stay'] },
      paymentStatus: { $ne: 'paid' },
    }).select('_id status paymentStatus').limit(LIMIT).lean(),
    Reservation.find({
      status: 'awaiting_approval',
      createdAt: { $lt: staleApprovalBefore },
    }).select('_id createdAt status hostApprovalDeadline').limit(LIMIT).lean(),
    Reservation.find({
      status: 'payment_pending',
      paymentDeadline: { $lt: new Date() },
    }).select('_id status paymentDeadline paymentStatus').limit(LIMIT).lean(),
    Payment.find({ refundOpsRequired: true, status: { $ne: 'refunded' } })
      .select('_id amount paymentProvider refundStatus reservation')
      .limit(LIMIT)
      .lean(),
    Payment.find({ refundStatus: 'failed' })
      .select('_id amount paymentProvider refundLastError reservation')
      .limit(LIMIT)
      .lean(),
    Reservation.find({ status: { $in: [...ACTIVE_BLOCKING_STATUSES] } })
      .select('_id residence checkIn checkOut status')
      .limit(2000)
      .lean(),
    Availability.find({ status: 'reserved', reservationId: { $ne: null } })
      .select('reservationId residenceId date')
      .limit(1000)
      .lean(),
  ]);

  const resIds = [...new Set(reservedWithId.map((a) => String(a.reservationId)))];
  const existing = await Reservation.find({ _id: { $in: resIds } }).select('_id').lean();
  const existingSet = new Set(existing.map((r) => String(r._id)));
  const danglingAvailability = reservedWithId
    .filter((a) => !existingSet.has(String(a.reservationId)))
    .slice(0, LIMIT);

  const overlaps = overlapPairs(activeReservations).slice(0, LIMIT);

  const findings = {
    paidPlusExpired,
    confirmedUnpaid,
    staleAwaitingApproval,
    overduePaymentPending,
    refundOpsRequired,
    refundFailed,
    historicalOverlaps: overlaps,
    danglingAvailability,
  };

  return {
    generatedAt: new Date().toISOString(),
    summary: Object.fromEntries(
      Object.entries(findings).map(([key, value]) => [key, Array.isArray(value) ? value.length : 0])
    ),
    findings,
  };
}

async function listAudit(query = {}) {
  const { page, limit, skip } = parsePageLimit(query);
  const filter = {};
  if (query.action) filter.action = query.action;
  if (query.entityType) filter.entityType = query.entityType;
  if (query.entityId && mongoose.isValidObjectId(query.entityId)) {
    filter.entityId = query.entityId;
  }
  const [rows, total] = await Promise.all([
    OpsAuditLog.find(filter)
      .populate('actor', 'firstName lastName email role')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean(),
    OpsAuditLog.countDocuments(filter),
  ]);
  return {
    data: rows,
    pagination: { page, limit, total, pages: Math.max(1, Math.ceil(total / limit)) },
  };
}

module.exports = {
  CANCELABLE_STATUSES,
  REFUND_BUCKETS,
  allowedReservationActions,
  listReservations,
  getReservation,
  cancelReservation,
  checkinReservation,
  checkoutReservation,
  listRefunds,
  confirmRefund,
  getInventoryCalendar,
  listAnomalies,
  listAudit,
};
