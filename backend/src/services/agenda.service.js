const Agenda = require('agenda');
const mongoose = require('mongoose');
const logger = require('../utils/logger');
const twilioService = require('./twilio.service');
const Booking = require('../models/booking.model');
const Reservation = require('../models/reservation.model');
const Payout = require('../models/payout.model');
const SMSMetrics = require('../models/sms_metrics.model');
const payoutService = require('./payout.service');

// Initialiser Agenda avec la même connexion MongoDB que l'application
const agenda = new Agenda({
  mongo: mongoose.connection,
  processEvery: '1 minute',
  defaultConcurrency: 5,
  maxConcurrency: 20
});

// Définir les types de jobs
agenda.define('sendBookingReminder', async (job) => {
  try {
    const { bookingId } = job.attrs.data;

    const booking = await Booking.findById(bookingId)
      .populate('client', 'phoneNumber firstName lastName')
      .populate('residence', 'title address');

    if (!booking) {
      logger.warn(`Réservation ${bookingId} non trouvée pour l'envoi du rappel SMS`);
      return;
    }

    // Vérifier que la réservation est toujours confirmée
    if (booking.status !== 'confirmed') {
      logger.info(`Rappel SMS non envoyé pour la réservation ${bookingId} car son statut est ${booking.status}`);
      return;
    }

    // Envoyer le SMS de rappel
    const message = await twilioService.sendBookingNotification(booking, 'reminder');

    // Enregistrer les métriques
    await SMSMetrics.create({
      type: 'booking_reminder',
      recipient: booking.client._id,
      booking: bookingId,
      messageId: message?.sid || null,
      status: message?.status || 'failed',
      content: `Rappel pour la réservation à ${booking.residence.title}`
    });

    logger.info(`Rappel SMS envoyé pour la réservation ${bookingId}`);
  } catch (error) {
    logger.error(`Erreur lors de l'envoi du rappel SMS: ${error.message}`, error);
  }
});

agenda.define('sendStatusChangeNotification', async (job) => {
  try {
    const { bookingId, oldStatus, newStatus } = job.attrs.data;

    const booking = await Booking.findById(bookingId)
      .populate('client', 'phoneNumber firstName lastName')
      .populate('residence', 'title address');

    if (!booking) {
      logger.warn(`Réservation ${bookingId} non trouvée pour l'envoi de la notification de changement de statut`);
      return;
    }

    // Déterminer le type de notification en fonction du changement de statut
    let notificationType;

    switch (newStatus) {
      case 'confirmed':
        notificationType = 'confirmation';
        break;
      case 'cancelled':
        notificationType = 'cancellation';
        break;
      case 'completed':
        notificationType = 'completed';
        break;
      default:
        notificationType = 'status_change';
    }

    // Envoyer le SMS de notification
    const message = await twilioService.sendBookingNotification(booking, notificationType);

    // Enregistrer les métriques
    await SMSMetrics.create({
      type: `booking_${notificationType}`,
      recipient: booking.client._id,
      booking: bookingId,
      messageId: message?.sid || null,
      status: message?.status || 'failed',
      content: `Notification de changement de statut (${oldStatus} → ${newStatus}) pour la réservation à ${booking.residence.title}`
    });

    logger.info(`Notification SMS de changement de statut envoyée pour la réservation ${bookingId} (${oldStatus} → ${newStatus})`);
  } catch (error) {
    logger.error(`Erreur lors de l'envoi de la notification de changement de statut: ${error.message}`, error);
  }
});

agenda.define('sendPaymentReminderAfricaSpecific', async (job) => {
  try {
    const { bookingId, paymentMethod } = job.attrs.data;

    const booking = await Booking.findById(bookingId)
      .populate('client', 'phoneNumber firstName lastName')
      .populate('residence', 'title address');

    if (!booking) {
      logger.warn(`Réservation ${bookingId} non trouvée pour l'envoi du rappel de paiement`);
      return;
    }

    // Personnaliser le message selon la méthode de paiement africaine
    let paymentInstructions = '';

    switch (paymentMethod) {
      case 'wave':
        paymentInstructions = `Pour payer avec Wave, envoyez ${booking.amount} FCFA au numéro +225 XX XX XX XX en utilisant le code de référence: CHAPE${booking._id.toString().substring(0, 6)}`;
        break;
      case 'orange_money':
        paymentInstructions = `Pour payer avec Orange Money, envoyez ${booking.amount} FCFA au numéro #144*72# et utilisez le code marchand: CHAP${booking._id.toString().substring(0, 4)}`;
        break;
      case 'mtn_money':
        paymentInstructions = `Pour payer avec MTN Money, composez *133# et choisissez "Payer facture". Utilisez le code marchand CHAPECHAPE et la référence: ${booking._id.toString().substring(0, 8)}`;
        break;
      case 'moov_money':
        paymentInstructions = `Pour payer avec Moov Money, composez *155# et choisissez "Payer facture". Code: CHAPE${booking._id.toString().substring(0, 6)}`;
        break;
      default:
        paymentInstructions = `Pour finaliser votre réservation, merci de procéder au paiement de ${booking.amount} FCFA. Pour toute assistance, contactez-nous au +225 XX XX XX XX.`;
    }

    // Message complet
    const messageBody = `ChapeChape: Rappel de paiement pour votre réservation à "${booking.residence.title}" le ${new Date(booking.visitDate).toLocaleDateString('fr-FR')}. ${paymentInstructions}`;

    // Envoyer le SMS personnalisé
    const message = await twilioService.sendSMS(booking.client.phoneNumber, messageBody);

    // Enregistrer les métriques
    await SMSMetrics.create({
      type: 'payment_reminder',
      recipient: booking.client._id,
      booking: bookingId,
      messageId: message?.sid || null,
      status: message?.status || 'failed',
      content: messageBody,
      metadata: {
        paymentMethod
      }
    });

    logger.info(`Rappel de paiement ${paymentMethod} envoyé pour la réservation ${bookingId}`);
  } catch (error) {
    logger.error(`Erreur lors de l'envoi du rappel de paiement: ${error.message}`, error);
  }
});

// Fonction pour planifier un rappel de réservation
const scheduleBookingReminder = async (bookingId, visitDate) => {
  try {
    // Calculer la date du rappel (la veille de la visite à 18h)
    const reminderDate = new Date(visitDate);
    reminderDate.setDate(reminderDate.getDate() - 1);
    reminderDate.setHours(18, 0, 0, 0);

    // Vérifier que la date de rappel est dans le futur
    if (reminderDate <= new Date()) {
      logger.warn(`La date de rappel pour la réservation ${bookingId} est déjà passée`);
      return;
    }

    // Planifier le job
    await agenda.schedule(reminderDate, 'sendBookingReminder', { bookingId });

    logger.info(`Rappel SMS planifié pour la réservation ${bookingId} le ${reminderDate.toISOString()}`);
    return true;
  } catch (error) {
    logger.error(`Erreur lors de la planification du rappel SMS: ${error.message}`);
    return false;
  }
};

// Fonction pour notifier un changement de statut de réservation
const notifyBookingStatusChange = async (bookingId, oldStatus, newStatus) => {
  try {
    // Envoyer immédiatement la notification
    await agenda.now('sendStatusChangeNotification', { bookingId, oldStatus, newStatus });

    logger.info(`Notification de changement de statut programmée pour la réservation ${bookingId} (${oldStatus} → ${newStatus})`);
    return true;
  } catch (error) {
    logger.error(`Erreur lors de la programmation de la notification de changement de statut: ${error.message}`);
    return false;
  }
};

// Fonction pour envoyer un rappel de paiement avec instructions spécifiques aux méthodes africaines
const sendPaymentReminderAfricaSpecific = async (bookingId, paymentMethod) => {
  try {
    // Envoyer immédiatement le rappel de paiement
    await agenda.now('sendPaymentReminderAfricaSpecific', { bookingId, paymentMethod });

    logger.info(`Rappel de paiement ${paymentMethod} programmé pour la réservation ${bookingId}`);
    return true;
  } catch (error) {
    logger.error(`Erreur lors de la programmation du rappel de paiement: ${error.message}`);
    return false;
  }
};

// Démarrer le service Agenda
const startAgenda = async () => {
  try {
    await agenda.start();

    // ✅ Démarrer les jobs périodiques payout
    startPayoutPeriodicJobs();

    logger.info('Service Agenda démarré avec succès pour les notifications automatiques et payouts');
    return agenda;
  } catch (error) {
    logger.error(`Erreur lors du démarrage du service Agenda: ${error.message}`);
    throw error;
  }
};

// ✅ PHASE 0 BIS : Support Reservation model pour jobs automatiques

// Job pour les rappels de réservation (Partner system)
agenda.define('sendReservationReminder', async (job) => {
  try {
    const { reservationId } = job.attrs.data;

    const reservation = await Reservation.findById(reservationId)
      .populate('user', 'phoneNumber firstName lastName')
      .populate('residence', 'title address')
      .populate('partner', 'phoneNumber firstName lastName companyName');

    if (!reservation) {
      logger.warn(`Réservation ${reservationId} non trouvée pour l'envoi du rappel SMS`);
      return;
    }

    // Vérifier que la réservation est confirmée
    if (!['confirmed', 'in_stay'].includes(reservation.status)) {
      logger.info(`Rappel SMS non envoyé pour réservation ${reservationId} car statut = ${reservation.status}`);
      return;
    }

    // Envoyer le SMS de rappel au client
    const message = await twilioService.sendReservationNotification(reservation, 'reminder');

    // Enregistrer les métriques
    await SMSMetrics.create({
      type: 'reservation_reminder',
      recipient: reservation.user._id,
      reservation: reservationId,
      messageId: message?.sid || null,
      status: message?.status || 'failed',
      content: `Rappel pour la réservation à ${reservation.residence.title}`
    });

    logger.info(`Rappel SMS envoyé pour réservation ${reservationId}`);
  } catch (error) {
    logger.error(`Erreur lors de l'envoi du rappel SMS pour réservation ${job.attrs.data.reservationId}:`, error);
  }
});

// Job pour la notification des partenaires sur les changements de statut
agenda.define('notifyPartnerReservationChange', async (job) => {
  try {
    const { reservationId, oldStatus, newStatus } = job.attrs.data;

    const reservation = await Reservation.findById(reservationId)
      .populate('user', 'firstName lastName phoneNumber')
      .populate('residence', 'title')
      .populate('partner', 'phoneNumber firstName lastName companyName');

    if (!reservation || !reservation.partner) {
      logger.warn(`Réservation ${reservationId} ou partenaire non trouvé pour notification changement statut`);
      return;
    }

    // Message spécifique selon le changement de statut
    let messageType = 'status_change';
    let message = '';

    if (newStatus === 'confirmed' && oldStatus === 'pending_payment') {
      messageType = 'payment_confirmed';
      message = `✅ Paiement confirmé ! Réservation de ${reservation.user.firstName} pour ${reservation.residence.title}`;
    } else if (newStatus === 'cancelled') {
      messageType = 'cancelled';
      message = `❌ Réservation annulée. ${reservation.user.firstName} a annulé sa réservation pour ${reservation.residence.title}`;
    } else if (newStatus === 'expired') {
      messageType = 'expired';
      message = `⏰ Réservation expirée. Délai de paiement dépassé pour ${reservation.residence.title}`;
    }

    if (message && reservation.partner.phoneNumber) {
      const twilioMessage = await twilioService.sendSMS(reservation.partner.phoneNumber, message);

      await SMSMetrics.create({
        type: `partner_${messageType}`,
        recipient: reservation.partner._id,
        reservation: reservationId,
        messageId: twilioMessage?.sid || null,
        status: twilioMessage?.status || 'failed',
        content: message
      });
    }

    logger.info(`Notification partenaire envoyée pour réservation ${reservationId} (${oldStatus} → ${newStatus})`);
  } catch (error) {
    logger.error(`Erreur notification partenaire réservation ${job.attrs.data.reservationId}:`, error);
  }
});

// Fonction pour planifier un rappel de réservation (Partner system)
const scheduleReservationReminder = async (reservationId, checkInDate) => {
  try {
    const reminderDate = new Date(checkInDate);
    reminderDate.setHours(reminderDate.getHours() - 24); // 24h avant

    if (reminderDate <= new Date()) {
      logger.info(`Date de rappel déjà passée pour réservation ${reservationId}`);
      return null;
    }

    const job = await agenda.schedule(reminderDate, 'sendReservationReminder', { reservationId });
    logger.info(`Rappel de réservation programmé pour ${reservationId} à ${reminderDate}`);
    return job;
  } catch (error) {
    logger.error(`Erreur lors de la programmation du rappel pour réservation ${reservationId}:`, error);
    throw error;
  }
};

// Fonction pour notifier un changement de statut de réservation
const notifyReservationStatusChange = async (reservationId, oldStatus, newStatus) => {
  try {
    await agenda.now('notifyPartnerReservationChange', { reservationId, oldStatus, newStatus });
    logger.info(`Notification de changement de statut programmée pour réservation ${reservationId}`);
  } catch (error) {
    logger.error(`Erreur lors de la programmation de la notification pour réservation ${reservationId}:`, error);
    throw error;
  }
};

// ===============================
// ✅ RESERVATION EXPIRATION JOB - Expiration automatique
// ===============================

/**
 * Job pour expirer automatiquement une réservation après délai de paiement
 */
agenda.define('expire reservation', async (job) => {
  try {
    const { reservationId } = job.attrs.data;

    logger.info(`Vérification expiration réservation: ${reservationId}`);

    const reservation = await Reservation.findById(reservationId)
      .populate('user residence partner');

    if (!reservation) {
      logger.warn(`Réservation ${reservationId} non trouvée pour expiration`);
      return;
    }

    // Vérifier si la réservation est toujours en attente de paiement
    if (reservation.status !== 'payment_pending' || reservation.paymentStatus === 'paid') {
      logger.info(`Réservation ${reservationId} déjà traitée (status: ${reservation.status}, payment: ${reservation.paymentStatus})`);
      return;
    }

    // Vérifier si le délai est vraiment dépassé
    const now = new Date();
    if (reservation.paymentDeadline && now < reservation.paymentDeadline) {
      logger.info(`Délai non expiré pour réservation ${reservationId}, reprogrammation...`);
      // Reprogrammer à la vraie deadline
      await agenda.schedule(reservation.paymentDeadline, 'expire reservation', { reservationId });
      return;
    }

    // Importer le service payment-timer pour la logique d'expiration
    const { checkAndExpireReservation } = require('./payment-timer.service');

    const result = await checkAndExpireReservation(reservationId);

    if (result.expired) {
      logger.info(`Réservation ${reservationId} expirée automatiquement via Agenda`);
    } else {
      logger.info(`Réservation ${reservationId} non expirée: ${result.reason}`);
    }

  } catch (error) {
    logger.error(`Erreur job expire reservation ${job.attrs.data.reservationId}:`, error);
    throw error;
  }
});

/**
 * Programmer l'expiration automatique d'une réservation
 * @param {string} reservationId ID de la réservation
 * @param {Date} deadline Date limite de paiement
 */
async function scheduleReservationExpiration(reservationId, deadline) {
  try {
    // Annuler les jobs d'expiration existants pour cette réservation
    await agenda.cancel({ name: 'expire reservation', 'data.reservationId': reservationId });

    // Programmer le nouveau job
    const job = await agenda.schedule(deadline, 'expire reservation', { reservationId });

    logger.info(`Expiration programmée pour réservation ${reservationId} à ${deadline.toISOString()}`);
    return job;
  } catch (error) {
    logger.error(`Erreur lors de la programmation de l'expiration pour réservation ${reservationId}:`, error);
    throw error;
  }
}

/**
 * Annuler l'expiration programmée (quand paiement reçu)
 * @param {string} reservationId ID de la réservation
 */
async function cancelReservationExpiration(reservationId) {
  try {
    const cancelled = await agenda.cancel({ name: 'expire reservation', 'data.reservationId': reservationId });
    logger.info(`${cancelled} job(s) d'expiration annulé(s) pour réservation ${reservationId}`);
    return cancelled;
  } catch (error) {
    logger.error(`Erreur lors de l'annulation de l'expiration pour réservation ${reservationId}:`, error);
    throw error;
  }
}

// ===============================
// ✅ PAYOUT JOBS - Gestion automatique des reversements
// ===============================

/**
 * Job pour exécuter un payout spécifique
 */
agenda.define('process payout', async (job) => {
  try {
    const { payoutId } = job.attrs.data;

    logger.info(`Exécution job payout: ${payoutId}`);

    const payout = await Payout.findById(payoutId);

    if (!payout) {
      logger.warn(`Payout ${payoutId} non trouvé pour exécution`);
      return;
    }

    // Vérifier que le payout est toujours exécutable
    if (!['PAYOUT_SCHEDULED', 'scheduled'].includes(payout.status)) {
      logger.info(`Payout ${payoutId} pas en statut SCHEDULED: ${payout.status}`);
      return;
    }

    // Exécuter le payout via le service
    await payoutService.executePayout(payout);

    logger.info(`Payout ${payoutId} exécuté avec succès via job`);

  } catch (error) {
    logger.error(`Erreur job payout ${job.attrs.data.payoutId}:`, error);

    // Reprogrammer le job en cas d'erreur (retry automatique)
    const retryDelay = new Date(Date.now() + 30 * 60 * 1000); // 30 minutes
    await agenda.schedule(retryDelay, 'process payout', job.attrs.data);

    throw error; // Marquer le job comme échoué
  }
});

/**
 * Job périodique pour traiter tous les payouts programmés
 */
agenda.define('process scheduled payouts', async (job) => {
  try {
    logger.info('Traitement périodique des payouts programmés');

    const results = await payoutService.processScheduledPayouts();

    logger.info(`Payouts traités: ${results.successful}/${results.processed} réussis`);

    // Si des erreurs, les logger pour monitoring
    if (results.errors.length > 0) {
      logger.warn('Erreurs dans le traitement des payouts:', results.errors);
    }

  } catch (error) {
    logger.error('Erreur traitement payouts programmés:', error);
    throw error;
  }
});

/**
 * Job périodique pour synchroniser les payouts en cours avec CinetPay
 */
agenda.define('sync pending payouts', async (job) => {
  try {
    logger.info('Synchronisation payouts en cours avec CinetPay');

    const results = await payoutService.syncAllPendingPayouts();

    logger.info(`Payouts synchronisés: ${results.completed} complétés, ${results.failed} échecs`);

  } catch (error) {
    logger.error('Erreur synchronisation payouts:', error);
    throw error;
  }
});

/**
 * Job pour créer automatiquement un payout après paiement
 */
agenda.define('auto create payout', async (job) => {
  try {
    const { reservationId, delayHours = 1 } = job.attrs.data;

    logger.info(`Création automatique payout pour réservation: ${reservationId}`);

    // Vérifier que la réservation est toujours payée
    const reservation = await Reservation.findById(reservationId);

    if (!reservation) {
      logger.warn(`Réservation ${reservationId} non trouvée pour création payout`);
      return;
    }

    if (reservation.paymentStatus !== 'paid') {
      logger.info(`Payout non créé: réservation ${reservationId} pas encore payée (${reservation.paymentStatus})`);
      return;
    }

    // Créer le payout avec délai personnalisé
    const payout = await payoutService.createPayoutForReservation(reservationId, delayHours);

    logger.info(`Payout créé automatiquement: ${payout.payout_id} pour réservation ${reservationId}`);

  } catch (error) {
    logger.error(`Erreur création auto payout pour réservation ${job.attrs.data.reservationId}:`, error);
    throw error;
  }
});

/**
 * Job de nettoyage des payouts anciens/expirés
 */
agenda.define('cleanup old payouts', async (job) => {
  try {
    logger.info('Nettoyage des payouts anciens');

    // Supprimer les payouts échoués de plus de 30 jours
    const cutoffDate = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

    const result = await Payout.deleteMany({
      status: { $in: ['PAYOUT_FAILED', 'PAYOUT_CANCELLED'] },
      updatedAt: { $lt: cutoffDate },
      attempts: { $gte: 5 } // Seulement ceux qui ont épuisé leurs tentatives
    });

    logger.info(`${result.deletedCount} payouts anciens supprimés`);

  } catch (error) {
    logger.error('Erreur nettoyage payouts:', error);
    throw error;
  }
});

// ===============================
// FONCTIONS UTILITAIRES PAYOUT
// ===============================

/**
 * Programmer l'exécution d'un payout
 * @param {string} payoutId ID du payout
 * @param {Date} executeAt Date d'exécution
 */
function schedulePayoutExecution(payoutId, executeAt = null) {
  const scheduledDate = executeAt || new Date(Date.now() + 60 * 60 * 1000); // 1h par défaut

  return agenda.schedule(scheduledDate, 'process payout', {
    payoutId: payoutId
  });
}

/**
 * Programmer la création automatique d'un payout après paiement
 * @param {string} reservationId ID de la réservation
 * @param {number} delayHours Délai en heures avant création payout
 */
function scheduleAutoPayoutCreation(reservationId, delayHours = 1) {
  const executeAt = new Date(Date.now() + delayHours * 60 * 60 * 1000);

  return agenda.schedule(executeAt, 'auto create payout', {
    reservationId: reservationId,
    delayHours: delayHours
  });
}

/**
 * Démarrer les jobs périodiques de payout
 */
function startPayoutPeriodicJobs() {
  // Traiter les payouts programmés toutes les 5 minutes
  agenda.every('5 minutes', 'process scheduled payouts');

  // Synchroniser avec CinetPay toutes les 10 minutes
  agenda.every('10 minutes', 'sync pending payouts');

  // Nettoyage hebdomadaire des anciens payouts
  agenda.every('1 week', 'cleanup old payouts');

  logger.info('Jobs périodiques payout démarrés');
}

module.exports = {
  agenda,
  startAgenda,
  // Booking methods (existing)
  scheduleBookingReminder,
  notifyBookingStatusChange,
  sendPaymentReminderAfricaSpecific,
  // ✅ NEW: Reservation methods (Phase 0 bis)
  scheduleReservationReminder,
  notifyReservationStatusChange,
  // ✅ NEW: Reservation expiration
  scheduleReservationExpiration,
  cancelReservationExpiration,
  // ✅ NEW: Payout methods
  schedulePayoutExecution,
  scheduleAutoPayoutCreation,
  startPayoutPeriodicJobs
};
