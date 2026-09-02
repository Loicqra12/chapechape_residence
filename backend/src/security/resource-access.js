/**
 * Accès ressource (IDOR) — ownership, pas le moteur métier.
 */
const { isStaff, isPartnerAccount } = require('./roles');

function idOf(value) {
  if (!value) return null;
  if (typeof value === 'string') return value;
  if (value._id) return String(value._id);
  return String(value);
}

function isConversationParticipant(conversation, user) {
  if (!conversation || !user) return false;
  const uid = idOf(user._id || user.id);
  return (conversation.participants || []).some((p) => idOf(p) === uid);
}

function canAccessConversation(conversation, user) {
  if (!conversation || !user) return false;
  if (isStaff(user.role)) return true;
  return isConversationParticipant(conversation, user);
}

function canAccessReservation(reservation, user) {
  if (!reservation || !user) return false;
  if (isStaff(user.role)) return true;
  const uid = idOf(user._id || user.id);
  return uid === idOf(reservation.user)
    || uid === idOf(reservation.client)
    || uid === idOf(reservation.partner);
}

function canAccessPayment(payment, reservation, user) {
  if (!user) return false;
  if (isStaff(user.role)) return true;
  const res = reservation
    || (payment && payment.reservation && payment.reservation.user ? payment.reservation : null);
  if (!res) return false;
  return canAccessReservation(res, user);
}

function canManageResidence(residence, user) {
  if (!residence || !user) return false;
  if (isStaff(user.role)) return true;
  if (!isPartnerAccount(user.role)) return false;
  return idOf(residence.partner) === idOf(user._id || user.id);
}

module.exports = {
  idOf,
  isConversationParticipant,
  canAccessConversation,
  canAccessReservation,
  canAccessPayment,
  canManageResidence,
};
