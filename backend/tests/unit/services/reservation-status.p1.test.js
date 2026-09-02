const Reservation = require('../../../src/models/reservation.model');
const ReservationStateService = require('../../../src/services/reservation-state.service');
const {
  RESERVATION_STATUS,
  RESERVATION_STATUS_VALUES,
  ACTIVE_BLOCKING_STATUSES,
  normalizeReservationStatusInput,
  isCanonicalReservationStatus,
  isLegacyReservationStatusAlias,
  LEGACY_ALIAS_VALUES,
} = require('../../../src/constants/reservation-status');
const { BOOKING_STATUS, RESERVATION_STATUS: CONST_RESERVATION_STATUS } = require('../../../src/utils/constants');

describe('P1-06 reservation status canonicalization', () => {
  it('exposes the nine canonical Reservation statuses', () => {
    expect(RESERVATION_STATUS_VALUES).toEqual([
      'pending',
      'awaiting_approval',
      'payment_pending',
      'confirmed',
      'in_stay',
      'expired',
      'cancelled',
      'completed',
      'refunded',
    ]);
  });

  it('does not persist legacy aliases on the Reservation schema', () => {
    const enumValues = Reservation.schema.path('status').enumValues;
    for (const alias of LEGACY_ALIAS_VALUES) {
      expect(enumValues).not.toContain(alias);
    }
    expect(enumValues).not.toContain('checked_in');
    expect(enumValues).not.toContain('checked_out');
    expect(enumValues).not.toContain('in_progress');
    expect(enumValues).not.toContain('pending_payment');
    expect(enumValues).not.toContain('rejected');
    expect(enumValues).toEqual(expect.arrayContaining(RESERVATION_STATUS_VALUES));
  });

  it('BOOKING_STATUS is an alias of RESERVATION_STATUS, not a diverging enum', () => {
    expect(BOOKING_STATUS).toBe(CONST_RESERVATION_STATUS);
    expect(BOOKING_STATUS.PAYMENT_PENDING).toBe('payment_pending');
    expect(BOOKING_STATUS.IN_STAY).toBe('in_stay');
  });

  it('normalizes input aliases immediately and never returns them as canonical', () => {
    expect(normalizeReservationStatusInput('pending_payment')).toBe('payment_pending');
    expect(normalizeReservationStatusInput('checked_in')).toBe('in_stay');
    expect(normalizeReservationStatusInput('checked_out')).toBe('completed');
    expect(normalizeReservationStatusInput('in_progress')).toBe('in_stay');
    expect(normalizeReservationStatusInput('canceled')).toBe('cancelled');
    expect(normalizeReservationStatusInput('payment_pending')).toBe('payment_pending');
    expect(isCanonicalReservationStatus('pending_payment')).toBe(false);
    expect(isLegacyReservationStatusAlias('pending_payment')).toBe(true);
    expect(isCanonicalReservationStatus('payment_pending')).toBe(true);
  });

  it('does not treat rejected as a Reservation.status alias', () => {
    expect(normalizeReservationStatusInput('rejected')).toBe('rejected');
    expect(isCanonicalReservationStatus('rejected')).toBe(false);
    expect(isLegacyReservationStatusAlias('rejected')).toBe(false);
  });

  it('keeps the canonical state machine (no checked_in / pending_payment transitions)', () => {
    expect(ReservationStateService.isTransitionAllowed('awaiting_approval', 'payment_pending')).toBe(true);
    expect(ReservationStateService.isTransitionAllowed('payment_pending', 'confirmed')).toBe(true);
    expect(ReservationStateService.isTransitionAllowed('confirmed', 'in_stay')).toBe(true);
    expect(ReservationStateService.isTransitionAllowed('in_stay', 'completed')).toBe(true);
    expect(ReservationStateService.isTransitionAllowed('confirmed', 'completed')).toBe(false);

    expect(ReservationStateService.isTransitionAllowed('payment_pending', 'checked_in')).toBe(false);
    expect(ReservationStateService.isTransitionAllowed('confirmed', 'checked_in')).toBe(false);
    expect(ReservationStateService.isTransitionAllowed('in_stay', 'checked_out')).toBe(false);
    expect(ReservationStateService.isTransitionAllowed('pending_payment', 'confirmed')).toBe(false);
    expect(ReservationStateService.isTransitionAllowed('in_progress', 'completed')).toBe(false);
  });

  it('keeps ACTIVE_BLOCKING_STATUSES as a blocking subset, not the full lifecycle', () => {
    expect(ACTIVE_BLOCKING_STATUSES).toEqual([
      RESERVATION_STATUS.PENDING,
      RESERVATION_STATUS.AWAITING_APPROVAL,
      RESERVATION_STATUS.PAYMENT_PENDING,
      RESERVATION_STATUS.CONFIRMED,
      RESERVATION_STATUS.IN_STAY,
    ]);
    expect(ACTIVE_BLOCKING_STATUSES).not.toContain('expired');
    expect(ACTIVE_BLOCKING_STATUSES).not.toContain('cancelled');
    expect(ACTIVE_BLOCKING_STATUSES).not.toContain('completed');
  });
});
