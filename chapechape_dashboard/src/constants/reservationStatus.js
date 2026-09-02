export const RESERVATION_STATUS = Object.freeze({
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

export const RESERVATION_STATUS_VALUES = Object.values(RESERVATION_STATUS);

const ALIASES = {
  pending_payment: RESERVATION_STATUS.PAYMENT_PENDING,
  waiting_payment: RESERVATION_STATUS.PAYMENT_PENDING,
  in_progress: RESERVATION_STATUS.IN_STAY,
  checked_in: RESERVATION_STATUS.IN_STAY,
  checked_out: RESERVATION_STATUS.COMPLETED,
  canceled: RESERVATION_STATUS.CANCELLED,
};

export const RESERVATION_STATUS_LABELS = {
  [RESERVATION_STATUS.PENDING]: 'En attente',
  [RESERVATION_STATUS.AWAITING_APPROVAL]: 'En attente d\'approbation',
  [RESERVATION_STATUS.PAYMENT_PENDING]: 'Paiement en attente',
  [RESERVATION_STATUS.CONFIRMED]: 'Confirmé',
  [RESERVATION_STATUS.IN_STAY]: 'Séjour en cours',
  [RESERVATION_STATUS.EXPIRED]: 'Expiré',
  [RESERVATION_STATUS.CANCELLED]: 'Annulé',
  [RESERVATION_STATUS.COMPLETED]: 'Terminé',
  [RESERVATION_STATUS.REFUNDED]: 'Remboursé',
};

export const RESERVATION_STATUS_COLORS = {
  [RESERVATION_STATUS.PENDING]: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300',
  [RESERVATION_STATUS.AWAITING_APPROVAL]: 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-300',
  [RESERVATION_STATUS.PAYMENT_PENDING]: 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-300',
  [RESERVATION_STATUS.CONFIRMED]: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300',
  [RESERVATION_STATUS.IN_STAY]: 'bg-teal-100 text-teal-800 dark:bg-teal-900 dark:text-teal-300',
  [RESERVATION_STATUS.EXPIRED]: 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300',
  [RESERVATION_STATUS.CANCELLED]: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300',
  [RESERVATION_STATUS.COMPLETED]: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300',
  [RESERVATION_STATUS.REFUNDED]: 'bg-slate-100 text-slate-800 dark:bg-slate-900 dark:text-slate-300',
};

export function normalizeReservationStatus(value) {
  if (!value) return value;
  const raw = String(value).trim().toLowerCase();
  if (RESERVATION_STATUS_VALUES.includes(raw)) return raw;
  return ALIASES[raw] || raw;
}

export function reservationStatusLabel(status) {
  const canonical = normalizeReservationStatus(status);
  return RESERVATION_STATUS_LABELS[canonical] || 'Statut inconnu';
}

export function reservationStatusColor(status) {
  const canonical = normalizeReservationStatus(status);
  return RESERVATION_STATUS_COLORS[canonical] || 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300';
}

export const FILTERABLE_RESERVATION_STATUSES = [
  RESERVATION_STATUS.PENDING,
  RESERVATION_STATUS.AWAITING_APPROVAL,
  RESERVATION_STATUS.PAYMENT_PENDING,
  RESERVATION_STATUS.CONFIRMED,
  RESERVATION_STATUS.IN_STAY,
  RESERVATION_STATUS.EXPIRED,
  RESERVATION_STATUS.CANCELLED,
  RESERVATION_STATUS.COMPLETED,
  RESERVATION_STATUS.REFUNDED,
];
