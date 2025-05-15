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
};

module.exports = {
  COMMON,
  PARTNER,
  CLIENT,
  
  // Mappings pour la notification push OneSignal
  getTitleByType: (type) => {
    const titleMap = {
      // Titres pour les partenaires
      [PARTNER.NEW_BOOKING]: '🏠 Nouvelle réservation',
      [PARTNER.BOOKING_MODIFIED]: '⚠️ Réservation modifiée',
      [PARTNER.BOOKING_CANCELED]: '⚠️ Réservation annulée',
      [PARTNER.PAYMENT_RECEIVED]: '💵 Paiement reçu',
      [PARTNER.DEPOSIT_RECEIVED]: '💵 Dépôt de garantie reçu',
      [PARTNER.MONTHLY_STATS]: '📈 Vos statistiques du mois',
      [PARTNER.NEW_REVIEW]: '📈 Nouvelle évaluation reçue',
      
      // Titres pour les clients
      [CLIENT.BOOKING_CONFIRMED]: '✅ Réservation confirmée',
      [CLIENT.ARRIVAL_REMINDER]: '🕓 Rappel d\'arrivée',
      [CLIENT.DEPARTURE_REMINDER]: '🕓 Rappel de départ',
      [CLIENT.SPECIAL_OFFER]: '📢 Offre spéciale pour vous',
      [CLIENT.DISCOUNT]: '📢 Remise exclusive',
      [CLIENT.POPULAR_RESIDENCE]: '🔥 Résidence populaire',
      [CLIENT.LIMITED_AVAILABILITY]: '🔥 Places limitées',
      [CLIENT.NEARBY_RESIDENCE]: '📍 Résidences à proximité',
      
      // Titres communs
      [COMMON.NEW_MESSAGE]: '💬 Nouveau message',
      [COMMON.SYSTEM]: 'Information ChapeChape',
      [COMMON.GENERAL]: 'ChapeChape Residence',
    };
    
    return titleMap[type] || 'ChapeChape Notification';
  }
};
