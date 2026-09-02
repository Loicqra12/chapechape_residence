/**
 * P1-04 — projection calendrier. PAS une source de vérité.
 *
 * Reservation + AvailabilityBlock + ExternalReservation
 *        ↓
 * CalendarProjectionService (DTO)
 *
 * Timezone canonique : Africa/Abidjan (UTC+0, pas de DST).
 * Les jours sont donc identiques aux clés UTC de inventory.service.
 * Convention de plage : [start, end) — identique à l'inventaire.
 */
const Residence = require('../models/residence.model');
const Reservation = require('../models/reservation.model');
const AvailabilityBlock = require('../models/availability-block.model');
const ExternalReservation = require('../models/external-reservation.model');
const ApiError = require('../utils/apiError');
const errorCodes = require('../utils/errorCodes');
const {
  ACTIVE_BLOCKING_STATUSES,
  inventoryDayKeys,
} = require('./inventory.service');
const { assertCanManageResidence } = require('./partner-block.service');

const CALENDAR_TIMEZONE = 'Africa/Abidjan';
const MAX_WINDOW_MS = 400 * 24 * 60 * 60 * 1000;
const PII_KEYS = ['guestName', 'guestPhone', 'channel', 'externalReference', 'notes'];

function parseDate(value, label) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    throw new ApiError(`${label} invalide`, 400, errorCodes.GENERAL.BAD_REQUEST);
  }
  return date;
}

function startOfUtcDay(date) {
  const d = new Date(date);
  return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
}

function addUtcDays(date, days) {
  const next = startOfUtcDay(date);
  next.setUTCDate(next.getUTCDate() + days);
  return next;
}

function utcDayKey(date) {
  return startOfUtcDay(date).toISOString().slice(0, 10);
}

function looksLikeDateOnly(date) {
  return date.getUTCHours() === 0
    && date.getUTCMinutes() === 0
    && date.getUTCSeconds() === 0
    && date.getUTCMilliseconds() === 0;
}

/**
 * Fenêtre calendrier : [from, to).
 * Si les deux bornes sont des dates UTC à minuit, endDate est inclusif
 * (1→31 août = tout le mois) et devient exclusive le lendemain.
 */
function parseWindow(startDate, endDate) {
  const start = parseDate(startDate, 'startDate');
  const end = parseDate(endDate, 'endDate');
  let from = start;
  let to = end;
  if (looksLikeDateOnly(start) && looksLikeDateOnly(end)) {
    from = start;
    to = addUtcDays(end, 1);
  }
  if (!(from < to)) {
    throw new ApiError('La date de fin doit être postérieure à la date de début', 400, errorCodes.GENERAL.BAD_REQUEST);
  }
  if (to.getTime() - from.getTime() > MAX_WINDOW_MS) {
    throw new ApiError('Période de calendrier trop large', 400, errorCodes.GENERAL.BAD_REQUEST);
  }
  return { from, to };
}

function overlaps(aStart, aEnd, bStart, bEnd) {
  return aStart < bEnd && aEnd > bStart;
}

function clipToDay(start, end, dayStart, dayEnd) {
  const clippedStart = start > dayStart ? start : dayStart;
  const clippedEnd = end < dayEnd ? end : dayEnd;
  if (!(clippedStart < clippedEnd)) return null;
  return { start: clippedStart, end: clippedEnd };
}

async function loadActiveOccupations(residenceId, from, to) {
  const [reservations, blocks, externals] = await Promise.all([
    Reservation.find({
      residence: residenceId,
      status: { $in: ACTIVE_BLOCKING_STATUSES },
      checkIn: { $lt: to },
      checkOut: { $gt: from },
    }).select('checkIn checkOut bookingType status hostApprovalDeadline').lean(),
    AvailabilityBlock.find({
      residence: residenceId,
      status: 'active',
      start: { $lt: to },
      end: { $gt: from },
    }).select('start end bookingType type status').lean(),
    ExternalReservation.find({
      residence: residenceId,
      status: 'active',
      checkIn: { $lt: to },
      checkOut: { $gt: from },
    }).select('checkIn checkOut bookingType status channel guestName guestPhone externalReference notes').lean(),
  ]);

  const occupations = [];

  for (const reservation of reservations) {
    occupations.push({
      id: reservation._id,
      sourceType: 'reservation',
      status: 'reserved',
      start: new Date(reservation.checkIn),
      end: new Date(reservation.checkOut),
      bookingType: reservation.bookingType || 'day',
      blockType: null,
      reservationStatus: reservation.status,
      hostApprovalDeadline: reservation.hostApprovalDeadline || null,
    });
  }

  for (const block of blocks) {
    occupations.push({
      id: block._id,
      sourceType: 'manual_block',
      status: 'blocked',
      start: new Date(block.start),
      end: new Date(block.end),
      bookingType: block.bookingType || 'day',
      blockType: block.type || 'other',
    });
  }

  for (const external of externals) {
    occupations.push({
      id: external._id,
      sourceType: 'external_reservation',
      status: 'reserved',
      start: new Date(external.checkIn),
      end: new Date(external.checkOut),
      bookingType: external.bookingType || 'day',
      blockType: null,
      channel: external.channel,
      guestName: external.guestName,
      guestPhone: external.guestPhone,
      externalReference: external.externalReference,
      notes: external.notes,
    });
  }

  occupations.sort((a, b) => a.start - b.start || a.end - b.end);
  return occupations;
}

function toPublicOccupation(occ) {
  return {
    start: occ.start.toISOString(),
    end: occ.end.toISOString(),
    bookingType: occ.bookingType,
    status: 'unavailable',
  };
}

function toPartnerOccupation(occ) {
  const dto = {
    id: String(occ.id),
    sourceType: occ.sourceType,
    status: occ.status,
    start: occ.start.toISOString(),
    end: occ.end.toISOString(),
    bookingType: occ.bookingType,
    blockType: occ.blockType || null,
  };
  if (occ.sourceType === 'reservation') {
    dto.reservationStatus = occ.reservationStatus;
    dto.hostApprovalDeadline = occ.hostApprovalDeadline
      ? new Date(occ.hostApprovalDeadline).toISOString()
      : null;
  }
  if (occ.sourceType === 'external_reservation') {
    dto.channel = occ.channel || 'other';
    dto.guestName = occ.guestName || '';
    dto.guestPhone = occ.guestPhone || '';
    dto.externalReference = occ.externalReference || '';
    dto.notes = occ.notes || '';
  }
  return dto;
}

function assertNoPublicPii(payload) {
  const json = JSON.stringify(payload);
  for (const key of PII_KEYS) {
    if (new RegExp(`"${key}"`, 'i').test(json)) {
      throw new Error(`PII leak in public calendar: ${key}`);
    }
  }
  return payload;
}

function buildDays(from, to, occupations, mapper) {
  const days = [];
  for (let current = startOfUtcDay(from); current < to; current = addUtcDays(current, 1)) {
    const dayEnd = addUtcDays(current, 1);
    const hits = occupations
      .map((occ) => {
        const clipped = clipToDay(occ.start, occ.end, current, dayEnd);
        if (!clipped) return null;
        return { occ, clipped };
      })
      .filter(Boolean);

    days.push({
      date: utcDayKey(current),
      available: hits.length === 0,
      // full_day : « puis-je louer la journée entière ? » — un slot hour rend false.
      // Ce n'est PAS « aucune minute occupée ». L'heure se lit dans slots.
      availableMeaning: 'full_day',
      status: hits.length === 0 ? 'available' : 'unavailable',
      slots: hits.map(({ occ, clipped }) => mapper(occ, clipped)),
    });
  }
  return days;
}

async function getPublicCalendar(residenceId, startDate, endDate) {
  const residence = await Residence.findById(residenceId).select('_id price');
  if (!residence) {
    throw new ApiError('Résidence non trouvée', 404, errorCodes.RESIDENCE.NOT_FOUND);
  }
  const { from, to } = parseWindow(startDate, endDate);
  const occupations = await loadActiveOccupations(residence._id, from, to);
  const publicOccupations = occupations.map(toPublicOccupation);
  const days = buildDays(from, to, occupations, (occ, clipped) => ({
    start: clipped.start.toISOString(),
    end: clipped.end.toISOString(),
    bookingType: occ.bookingType,
    status: 'unavailable',
  }));

  const payload = {
    timezone: CALENDAR_TIMEZONE,
    residenceId: String(residence._id),
    start: from.toISOString(),
    end: to.toISOString(),
    occupations: publicOccupations,
    days,
  };
  return assertNoPublicPii(payload);
}

async function getPartnerCalendar(user, residenceId, startDate, endDate) {
  const residence = await Residence.findById(residenceId);
  if (!residence) {
    throw new ApiError('Résidence non trouvée', 404, errorCodes.RESIDENCE.NOT_FOUND);
  }
  assertCanManageResidence(user, residence);
  const { from, to } = parseWindow(startDate, endDate);
  const occupations = await loadActiveOccupations(residence._id, from, to);
  const partnerOccupations = occupations.map(toPartnerOccupation);
  const days = buildDays(from, to, occupations, (occ, clipped) => ({
    id: String(occ.id),
    sourceType: occ.sourceType,
    status: occ.status,
    start: clipped.start.toISOString(),
    end: clipped.end.toISOString(),
    bookingType: occ.bookingType,
    blockType: occ.blockType || null,
  }));

  return {
    timezone: CALENDAR_TIMEZONE,
    residenceId: String(residence._id),
    start: from.toISOString(),
    end: to.toISOString(),
    occupations: partnerOccupations,
    days,
  };
}

async function isRangeAvailable(residenceId, start, end) {
  const from = new Date(start);
  const to = new Date(end);
  if (!(from < to)) {
    throw new ApiError('La date de départ doit être ultérieure à la date d\'arrivée', 400, errorCodes.GENERAL.BAD_REQUEST);
  }
  const occupations = await loadActiveOccupations(residenceId, from, to);
  return !occupations.some((occ) => overlaps(occ.start, occ.end, from, to));
}

async function checkPublicAvailability(residenceId, start, end) {
  const residence = await Residence.findById(residenceId).select('_id');
  if (!residence) {
    throw new ApiError('Résidence introuvable', 404, errorCodes.RESIDENCE.NOT_FOUND);
  }
  const from = parseDate(start, 'checkIn');
  const to = parseDate(end, 'checkOut');
  if (!(from < to)) {
    throw new ApiError('La date de départ doit être ultérieure à la date d\'arrivée', 400, errorCodes.GENERAL.BAD_REQUEST);
  }
  const occupations = await loadActiveOccupations(residence._id, from, to);
  const hits = occupations.filter((occ) => overlaps(occ.start, occ.end, from, to));
  const payload = {
    available: hits.length === 0,
    occupations: hits.map(toPublicOccupation),
  };
  return assertNoPublicPii(payload);
}

function touchedUtcDays(start, end) {
  return inventoryDayKeys('x', start, end).map((key) => key.slice(2));
}

module.exports = {
  CALENDAR_TIMEZONE,
  PII_KEYS,
  ACTIVE_BLOCKING_STATUSES,
  parseWindow,
  overlaps,
  clipToDay,
  utcDayKey,
  startOfUtcDay,
  addUtcDays,
  touchedUtcDays,
  toPublicOccupation,
  toPartnerOccupation,
  loadActiveOccupations,
  getPublicCalendar,
  getPartnerCalendar,
  isRangeAvailable,
  checkPublicAvailability,
};
