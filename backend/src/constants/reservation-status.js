/**
 * P1-06 — source canonique Reservation.status.
 * Ne pas confondre avec Payment.status / paymentStatus, ExternalReservation.status,
 * AvailabilityBlock.status, Residence.status, User.status.
 */

const RESERVATION_STATUS = Object.freeze({
  PENDING: 'pending',
  AWAITING_APPROVAL: 'awaiting_approval',
  PAYMENT_PENDING: 'payment_pending',
  CONFIRMED: 'confirmed',
  IN_STAY: 'in_stay',
  EXPIRED: 'expired',
  CANCELLED: 'cancelled',
  COMPLETED: 'completed',
  REFUNDED: 'refunded',
});

const RESERVATION_STATUS_VALUES = Object.freeze(Object.values(RESERVATION_STATUS));

/** Occupent réellement l'inventaire. Sous-ensemble métier, pas un second lifecycle. */
const ACTIVE_BLOCKING_STATUSES = Object.freeze([
  RESERVATION_STATUS.PENDING,
  RESERVATION_STATUS.AWAITING_APPROVAL,
  RESERVATION_STATUS.PAYMENT_PENDING,
  RESERVATION_STATUS.CONFIRMED,
  RESERVATION_STATUS.IN_STAY,
]);

const TERMINAL_STATUSES = Object.freeze([
  RESERVATION_STATUS.EXPIRED,
  RESERVATION_STATUS.CANCELLED,
  RESERVATION_STATUS.COMPLETED,
  RESERVATION_STATUS.REFUNDED,
]);

/**
 * Alias d'entrée (anciennes apps / caches). Jamais persistés.
 * `rejected` n'est PAS un alias : le rejet passe par l'endpoint dédié
 * (cancelled + rejectedByHost).
 */
const RESERVATION_STATUS_INPUT_ALIASES = Object.freeze({
  pending_payment: RESERVATION_STATUS.PAYMENT_PENDING,
  waiting_payment: RESERVATION_STATUS.PAYMENT_PENDING,
  payment_required: RESERVATION_STATUS.PAYMENT_PENDING,
  in_progress: RESERVATION_STATUS.IN_STAY,
  checked_in: RESERVATION_STATUS.IN_STAY,
  ongoing: RESERVATION_STATUS.IN_STAY,
  checked_out: RESERVATION_STATUS.COMPLETED,
  finished: RESERVATION_STATUS.COMPLETED,
  complete: RESERVATION_STATUS.COMPLETED,
  canceled: RESERVATION_STATUS.CANCELLED,
  payment_expired: RESERVATION_STATUS.EXPIRED,
});

const LEGACY_ALIAS_VALUES = Object.freeze(Object.keys(RESERVATION_STATUS_INPUT_ALIASES));

function normalizeReservationStatusInput(value) {
  if (value == null) return value;
  const raw = String(value).trim().toLowerCase();
  if (RESERVATION_STATUS_VALUES.includes(raw)) return raw;
  if (Object.prototype.hasOwnProperty.call(RESERVATION_STATUS_INPUT_ALIASES, raw)) {
    return RESERVATION_STATUS_INPUT_ALIASES[raw];
  }
  return raw;
}

function isCanonicalReservationStatus(value) {
  return RESERVATION_STATUS_VALUES.includes(value);
}

function isLegacyReservationStatusAlias(value) {
  if (value == null) return false;
  return Object.prototype.hasOwnProperty.call(
    RESERVATION_STATUS_INPUT_ALIASES,
    String(value).trim().toLowerCase()
  );
}

module.exports = {
  RESERVATION_STATUS,
  RESERVATION_STATUS_VALUES,
  ACTIVE_BLOCKING_STATUSES,
  TERMINAL_STATUSES,
  RESERVATION_STATUS_INPUT_ALIASES,
  LEGACY_ALIAS_VALUES,
  normalizeReservationStatusInput,
  isCanonicalReservationStatus,
  isLegacyReservationStatusAlias,
};
