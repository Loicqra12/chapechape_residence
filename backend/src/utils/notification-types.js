/**
 * Types de notifications pour l'application
 * Ces constantes sont utilisées à la fois pour identifier le type de notification
 * et pour déterminer le contenu et le comportement de ces notifications.
 */

// Types communs
const COMMON = {
  SYSTEM: 'system',
  NEW_MESSAGE: 'new_message',
  GENERAL: 'general',
};

// Types pour les partenaires
const PARTNER = {
  NEW_BOOKING: 'partner_new_booking',           // 🏠 Nouvelle réservation
  BOOKING_MODIFIED: 'partner_booking_modified', // ⚠️ Modification de réservation
  BOOKING_CANCELED: 'partner_booking_canceled', // ⚠️ Annulation de réservation
  PAYMENT_RECEIVED: 'partner_payment_received', // 💵 Paiement reçu
  DEPOSIT_RECEIVED: 'partner_deposit_received', // 💵 Dépôt de garantie reçu
  MONTHLY_STATS: 'partner_monthly_stats',       // 📈 Statistiques mensuelles
  NEW_REVIEW: 'partner_new_review',             // 📈 Nouvelle évaluation
  
  // Notifications de payout et transfert
  PAYOUT_INITIATED: 'partner_payout_initiated', // 💸 Payout initié
  PAYOUT_SUCCESS: 'partner_payout_success',     // ✅ Payout réussi
  PAYOUT_FAILED: 'partner_payout_failed',       // ❌ Payout échoué
  TRANSFER_INITIATED: 'partner_transfer_initiated', // 💸 Transfert initié
  TRANSFER_SUCCESS: 'partner_transfer_success', // ✅ Transfert réussi
  TRANSFER_FAILED: 'partner_transfer_failed',   // ❌ Transfert échoué
  
  // Notifications de sécurité et vérification
  PHONE_CHANGED: 'partner_phone_changed',       // 📞 Numéro changé
  VERIFICATION_SENT: 'partner_verification_sent', // 🔐 Code envoyé
  VERIFICATION_SUCCESS: 'partner_verification_success', // ✅ Vérification réussie
  VERIFICATION_FAILED: 'partner_verification_failed', // ❌ Vérification échouée
  SECURITY_ALERT: 'partner_security_alert',     // 🛡️ Alerte sécurité
  LOGIN_ALERT: 'partner_login_alert',           // 🔐 Nouvelle connexion
};

// Types pour les clients
const CLIENT = {
  BOOKING_CONFIRMED: 'client_booking_confirmed',   // ✅ Confirmation de réservation
  ARRIVAL_REMINDER: 'client_arrival_reminder',     // 🕓 Rappel d'arrivée
  DEPARTURE_REMINDER: 'client_departure_reminder', // 🕓 Rappel de départ
  SPECIAL_OFFER: 'client_special_offer',           // 📢 Offre spéciale
  DISCOUNT: 'client_discount',                     // 📢 Remise
  POPULAR_RESIDENCE: 'client_popular_residence',   // 🔥 Résidence populaire
  LIMITED_AVAILABILITY: 'client_limited_availability', // 🔥 Disponibilité limitée
  NEARBY_RESIDENCE: 'client_nearby_residence',     // 📍 Résidence à proximité
  
  // Nouveaux types pour reservationMode
  PAYMENT_PENDING: 'client_payment_pending',       // 💳 Paiement en attente (mode instant)
  AWAITING_APPROVAL: 'client_awaiting_approval',   // ⏳ En attente d'approbation (mode approval_required)
  BOOKING_APPROVED: 'client_booking_approved',     // ✅ Réservation approuvée par l'hôte
  BOOKING_REJECTED: 'client_booking_rejected',     // ❌ Réservation refusée par l'hôte
  PAYMENT_EXPIRED: 'client_payment_expired',       // ⏰ Délai de paiement expiré
  CHECKIN_READY: 'client_checkin_ready',           // 🏠 Prêt pour le check-in
  CHECKOUT_REMINDER: 'client_checkout_reminder',   // 🚪 Rappel de check-out
  
  // Notifications de sécurité et vérification
  PHONE_CHANGED: 'client_phone_changed',           // 📞 Numéro changé
  VERIFICATION_SENT: 'client_verification_sent',   // 🔐 Code envoyé
  VERIFICATION_SUCCESS: 'client_verification_success', // ✅ Vérification réussie
  VERIFICATION_FAILED: 'client_verification_failed', // ❌ Vérification échouée
  SECURITY_ALERT: 'client_security_alert',         // 🛡️ Alerte sécurité
  LOGIN_ALERT: 'client_login_alert',               // 🔐 Nouvelle connexion
};

const getTitleByType = (type) => {
    const titleMap = {
      // Titres pour les partenaires
      [PARTNER.NEW_BOOKING]: '🏠 Nouvelle réservation',
      [PARTNER.BOOKING_MODIFIED]: '⚠️ Réservation modifiée',
      [PARTNER.BOOKING_CANCELED]: '⚠️ Réservation annulée',
      [PARTNER.PAYMENT_RECEIVED]: '💵 Paiement reçu',
      [PARTNER.DEPOSIT_RECEIVED]: '💵 Dépôt de garantie reçu',
      [PARTNER.MONTHLY_STATS]: '📈 Vos statistiques du mois',
      [PARTNER.NEW_REVIEW]: '📈 Nouvelle évaluation reçue',
      
      // Titres pour les nouveaux types partenaires
      [PARTNER.PAYOUT_INITIATED]: '💸 Payout initié',
      [PARTNER.PAYOUT_SUCCESS]: '✅ Payout réussi',
      [PARTNER.PAYOUT_FAILED]: '❌ Payout échoué',
      [PARTNER.TRANSFER_INITIATED]: '💸 Transfert initié',
      [PARTNER.TRANSFER_SUCCESS]: '✅ Transfert réussi',
      [PARTNER.TRANSFER_FAILED]: '❌ Transfert échoué',
      [PARTNER.PHONE_CHANGED]: '📞 Numéro de téléphone changé',
      [PARTNER.VERIFICATION_SENT]: '🔐 Code de vérification envoyé',
      [PARTNER.VERIFICATION_SUCCESS]: '✅ Vérification réussie',
      [PARTNER.VERIFICATION_FAILED]: '❌ Vérification échouée',
      [PARTNER.SECURITY_ALERT]: '🛡️ Alerte de sécurité',
      [PARTNER.LOGIN_ALERT]: '🔐 Nouvelle connexion détectée',
      
      // Titres pour les clients
      [CLIENT.BOOKING_CONFIRMED]: '✅ Réservation confirmée',
      [CLIENT.ARRIVAL_REMINDER]: '🕓 Rappel d\'arrivée',
      [CLIENT.DEPARTURE_REMINDER]: '🕓 Rappel de départ',
      [CLIENT.SPECIAL_OFFER]: '📢 Offre spéciale pour vous',
      [CLIENT.DISCOUNT]: '📢 Remise exclusive',
      [CLIENT.POPULAR_RESIDENCE]: '🔥 Résidence populaire',
      [CLIENT.LIMITED_AVAILABILITY]: '🔥 Places limitées',
      [CLIENT.NEARBY_RESIDENCE]: '📍 Résidences à proximité',
      [CLIENT.PAYMENT_PENDING]: '💳 Paiement en attente',
      [CLIENT.AWAITING_APPROVAL]: '⏳ En attente d\'approbation',
      [CLIENT.BOOKING_APPROVED]: '✅ Réservation approuvée',
      [CLIENT.BOOKING_REJECTED]: '❌ Réservation refusée',
      [CLIENT.PAYMENT_EXPIRED]: '⏰ Délai de paiement expiré',
      [CLIENT.CHECKIN_READY]: '🏠 Prêt pour le check-in',
      [CLIENT.CHECKOUT_REMINDER]: '🚪 Rappel de check-out',
      
      // Titres pour les nouveaux types clients
      [CLIENT.PHONE_CHANGED]: '📞 Numéro de téléphone changé',
      [CLIENT.VERIFICATION_SENT]: '🔐 Code de vérification envoyé',
      [CLIENT.VERIFICATION_SUCCESS]: '✅ Vérification réussie',
      [CLIENT.VERIFICATION_FAILED]: '❌ Vérification échouée',
      [CLIENT.SECURITY_ALERT]: '🛡️ Alerte de sécurité',
      [CLIENT.LOGIN_ALERT]: '🔐 Nouvelle connexion détectée',
      
      // Titres communs
      [COMMON.NEW_MESSAGE]: '💬 Nouveau message',
      [COMMON.SYSTEM]: 'Information ChapeChape',
      [COMMON.GENERAL]: 'ChapeChape Residence',
    };
    
    return titleMap[type] || 'ChapeChape Notification';
};

const getPushTypeByNotificationType = (type) => {
  if (!type || typeof type !== 'string') return 'system_update';

  if (type === COMMON.NEW_MESSAGE || type.includes('message')) {
    return 'new_message';
  }

  if (
    type.includes('booking') ||
    type.includes('arrival') ||
    type.includes('departure') ||
    type.includes('checkin') ||
    type.includes('checkout') ||
    type.includes('approval')
  ) {
    return 'booking_update';
  }

  if (
    type.includes('payment') ||
    type.includes('deposit') ||
    type.includes('payout') ||
    type.includes('transfer')
  ) {
    return 'payment_update';
  }

  if (
    type.includes('verification') ||
    type.includes('security') ||
    type.includes('login') ||
    type.includes('phone_changed')
  ) {
    return 'security_alert';
  }

  if (
    type.includes('offer') ||
    type.includes('discount') ||
    type.includes('popular') ||
    type.includes('nearby') ||
    type.includes('availability')
  ) {
    return 'promotion';
  }

  return 'system_update';
};

const getDeepLinkByNotificationType = (type, data = {}) => {
  if (data.deepLink && typeof data.deepLink === 'string') {
    return data.deepLink;
  }

  const isPartnerNotification = typeof type === 'string' && type.startsWith('partner_');
  const bookingId = data.bookingId || data.reservationId;
  const paymentId = data.paymentId || data.payoutId;

  const pushType = getPushTypeByNotificationType(type);

  if (pushType === 'new_message') {
    return isPartnerNotification ? '/messages/support' : '/chat';
  }

  if (pushType === 'booking_update') {
    if (bookingId) {
      return isPartnerNotification ? `/reservations/${bookingId}` : `/booking-details/${bookingId}`;
    }
    return isPartnerNotification ? '/notifications' : '/bookings';
  }

  if (pushType === 'payment_update') {
    if (isPartnerNotification) {
      return paymentId ? `/payouts/${paymentId}` : '/payouts';
    }
    return paymentId ? `/payment/${paymentId}` : '/bookings';
  }

  return '/notifications';
};

module.exports = {
  COMMON,
  PARTNER,
  CLIENT,
  getTitleByType,
  getPushTypeByNotificationType,
  getDeepLinkByNotificationType
};
