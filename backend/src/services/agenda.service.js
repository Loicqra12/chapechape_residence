const Agenda = require('agenda');
const mongoose = require('mongoose');
const logger = require('../utils/logger');
const twilioService = require('./twilio.service');
const Reservation = require('../models/reservation.model');
const Payout = require('../models/payout.model');
const User = require('../models/user.model');
const SMSMetrics = require('../models/sms_metrics.model');
const { isPrimaryScheduler, workerLabel, saveUniqueScheduledJob, FINANCIAL_JOB_OPTIONS } = require('../runtime/agenda-cluster');
const readiness = require('../runtime/readiness');
const { attachAgendaEnvelope } = require('../observability/agenda-envelope');

function createNoopAgenda() {
  const noop = async () => undefined;
  const fakeJob = {
    unique() { return this; },
    schedule() { return this; },
    save: noop,
  };
  const instance = {
    define() {},
    start: noop,
    stop: noop,
    schedule: noop,
    now: noop,
    every: noop,
    cancel: async () => 0,
    create() { return fakeJob; },
    __isNoopAgenda: true,
  };
  return instance;
}

let agendaInstance;

function shouldUseNoopAgenda() {
  return process.env.NODE_ENV === 'test' && mongoose.connection.readyState !== 1;
}

function getAgenda() {
  if (agendaInstance) {
    if (!shouldUseNoopAgenda() && agendaInstance.__isNoopAgenda) {
      agendaInstance = null;
    } else {
      return agendaInstance;
    }
  }
  if (shouldUseNoopAgenda()) {
    agendaInstance = createNoopAgenda();
    return agendaInstance;
  }
  agendaInstance = new Agenda({
    mongo: mongoose.connection,
    processEvery: '30 seconds',
    defaultConcurrency: 5,
    maxConcurrency: 20,
    defaultLockLifetime: 10 * 60 * 1000,
  });
  return agendaInstance;
}

/** Proxy : `const { agenda } = require(...)` n'instancie Mongo qu'au premier appel réel. */
const agenda = new Proxy({}, {
  get(_target, prop) {
    if (prop === 'then') return undefined;
    const real = getAgenda();
    const val = real[prop];
    return typeof val === 'function' ? val.bind(real) : val;
  },
});

// Démarrer le service Agenda
const startAgenda = async () => {
  try {
    const realAgenda = getAgenda();
    attachAgendaEnvelope(realAgenda);
    await agenda.start();
    readiness.markAgendaStarted(true);

    if (isPrimaryScheduler()) {
      startPayoutPeriodicJobs();
      startEngagementPeriodicJobs();
      startRefundPeriodicJobs();
      startHostApprovalPeriodicJobs();
      logger.info('Service Agenda: scheduler primaire (every jobs)', { worker: workerLabel() });
    } else {
      logger.info('Service Agenda: worker secondaire (exécution only, pas de every)', { worker: workerLabel() });
    }

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

    // Push OneSignal (en plus du SMS)
    try {
      const notificationService = require('./notification.service');
      const arrivalDate = reservation.checkIn
        ? new Date(reservation.checkIn).toLocaleDateString('fr-FR')
        : undefined;
      await notificationService.notifyClient(
        reservation.user._id,
        notificationTypes.CLIENT.ARRIVAL_REMINDER,
        {
          reservationId,
          residenceName: reservation.residence?.title,
          arrivalDate,
          deepLink: `/booking-details/${reservationId}`,
        }
      );
    } catch (pushErr) {
      logger.error(`Push rappel arrivée échoué pour ${reservationId}:`, pushErr);
    }

    logger.info(`Rappel SMS+push envoyé pour réservation ${reservationId}`);
  } catch (error) {
    logger.error(`Erreur lors de l'envoi du rappel SMS pour réservation ${job.attrs.data.reservationId}:`, error);
  }
});

// Job rappel départ (24h avant check-out)
agenda.define('sendReservationDepartureReminder', async (job) => {
  try {
    const { reservationId } = job.attrs.data;

    const reservation = await Reservation.findById(reservationId)
      .populate('user', 'phoneNumber firstName lastName')
      .populate('residence', 'title address');

    if (!reservation) {
      logger.warn(`Réservation ${reservationId} non trouvée pour rappel départ`);
      return;
    }

    if (!['confirmed', 'in_stay'].includes(reservation.status)) {
      logger.info(`Rappel départ ignoré pour ${reservationId} (statut=${reservation.status})`);
      return;
    }

    try {
      const notificationService = require('./notification.service');
      const departureDate = reservation.checkOut
        ? new Date(reservation.checkOut).toLocaleDateString('fr-FR')
        : undefined;
      await notificationService.notifyClient(
        reservation.user._id,
        notificationTypes.CLIENT.DEPARTURE_REMINDER,
        {
          reservationId,
          residenceName: reservation.residence?.title,
          departureDate,
          deepLink: `/booking-details/${reservationId}`,
        }
      );
    } catch (pushErr) {
      logger.error(`Push rappel départ échoué pour ${reservationId}:`, pushErr);
    }

    logger.info(`Rappel départ push envoyé pour réservation ${reservationId}`);
  } catch (error) {
    logger.error(`Erreur rappel départ réservation ${job.attrs.data.reservationId}:`, error);
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
    let partnerPushType = null;

    const { normalizeReservationStatusInput } = require('../constants/reservation-status');
    const previousStatus = normalizeReservationStatusInput(oldStatus);
    if (newStatus === 'confirmed' && (previousStatus === 'payment_pending' || previousStatus === 'pending')) {
      messageType = 'payment_confirmed';
      message = `✅ Paiement confirmé ! Réservation de ${reservation.user.firstName} pour ${reservation.residence.title}`;
      // Push paiement déjà géré par applyPaymentPaid (idempotent) — SMS seulement ici
      partnerPushType = null;
    } else if (newStatus === 'cancelled') {
      messageType = 'cancelled';
      message = `❌ Réservation annulée. ${reservation.user.firstName} a annulé sa réservation pour ${reservation.residence.title}`;
      partnerPushType = notificationTypes.PARTNER.BOOKING_CANCELED;
    } else if (newStatus === 'expired') {
      messageType = 'expired';
      message = `⏰ Réservation expirée. Délai de paiement dépassé pour ${reservation.residence.title}`;
      partnerPushType = notificationTypes.PARTNER.BOOKING_EXPIRED;
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

    if (partnerPushType) {
      try {
        const notificationService = require('./notification.service');
        await notificationService.notifyPartner(
          reservation.partner._id,
          partnerPushType,
          {
            reservationId,
            residenceName: reservation.residence?.title,
            clientName: reservation.user?.firstName || 'Client',
            event: `status_${oldStatus}_to_${newStatus}`,
            deepLink: `/reservations/${reservationId}`,
          }
        );
      } catch (pushErr) {
        logger.error(`Push partner statut échoué pour ${reservationId}:`, pushErr);
      }
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

    const rid = String(reservationId);

    const job = await saveUniqueScheduledJob(
      agenda,
      'sendReservationReminder',
      reminderDate,
      { reservationId: rid },
      'reservationId'
    );
    logger.info(`Rappel de réservation programmé pour ${reservationId} à ${reminderDate}`);
    return job;
  } catch (error) {
    logger.error(`Erreur lors de la programmation du rappel pour réservation ${reservationId}:`, error);
    throw error;
  }
};

const scheduleReservationDepartureReminder = async (reservationId, checkOutDate) => {
  try {
    const reminderDate = new Date(checkOutDate);
    reminderDate.setHours(reminderDate.getHours() - 24);

    if (reminderDate <= new Date()) {
      logger.info(`Date rappel départ déjà passée pour réservation ${reservationId}`);
      return null;
    }

    const job = await agenda.schedule(reminderDate, 'sendReservationDepartureReminder', { reservationId });
    logger.info(`Rappel départ programmé pour ${reservationId} à ${reminderDate}`);
    return job;
  } catch (error) {
    logger.error(`Erreur programmation rappel départ ${reservationId}:`, error);
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
agenda.define('expire reservation', FINANCIAL_JOB_OPTIONS, async (job) => {
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
      await saveUniqueScheduledJob(
        agenda,
        'expire reservation',
        reservation.paymentDeadline,
        { reservationId: String(reservationId) },
        'reservationId'
      );
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

agenda.define('expire host approval', FINANCIAL_JOB_OPTIONS, async (job) => {
  try {
    const { reservationId } = job.attrs.data || {};
    if (!reservationId) return;
    const hostApprovalService = require('./host-approval.service');
    await hostApprovalService.expireHostApproval(reservationId);
  } catch (error) {
    logger.error(`Erreur job expire host approval ${job.attrs.data?.reservationId}:`, error);
    throw error;
  }
});

agenda.define('sweep host approval expirations', async () => {
  const hostApprovalService = require('./host-approval.service');
  await hostApprovalService.sweepExpiredHostApprovals();
});

function startHostApprovalPeriodicJobs() {
  agenda.every('1 minute', 'sweep host approval expirations');
  logger.info('Job sweep host approval expirations démarré (toutes les 1 min)');
}

/**
 * Programmer l'expiration automatique d'une réservation
 * @param {string} reservationId ID de la réservation
 * @param {Date} deadline Date limite de paiement
 */
async function scheduleReservationExpiration(reservationId, deadline) {
  try {
    // Annuler les jobs d'expiration existants pour cette réservation
    await agenda.cancel({ name: 'expire reservation', 'data.reservationId': reservationId });
    const job = await saveUniqueScheduledJob(
      agenda,
      'expire reservation',
      deadline,
      { reservationId: String(reservationId) },
      'reservationId'
    );

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
    const cancelledExpire = await agenda.cancel({ name: 'expire reservation', 'data.reservationId': reservationId });
    const cancelledReminders = await agenda.cancel({
      name: 'reservation payment reminder',
      'data.reservationId': reservationId,
    });
    logger.info(
      `${cancelledExpire} expiration + ${cancelledReminders} rappel(s) paiement annulé(s) pour réservation ${reservationId}`
    );
    return cancelledExpire + cancelledReminders;
  } catch (error) {
    logger.error(`Erreur lors de l'annulation de l'expiration pour réservation ${reservationId}:`, error);
    throw error;
  }
}

/**
 * Rappels paiement Client — adaptés à la durée du timer (souvent 30 min).
 * - rappel milieu de fenêtre
 * - rappel final (~5 min avant deadline)
 * Idempotents + annulés au paiement.
 */
agenda.define('reservation payment reminder', async (job) => {
  try {
    const { reservationId, stage } = job.attrs.data;
    const reservation = await Reservation.findById(reservationId)
      .populate('user', 'firstName lastName phoneNumber notificationSettings deviceTokens')
      .populate('residence', 'title');

    if (!reservation) return;
    if (reservation.status !== 'payment_pending' || reservation.paymentStatus === 'paid') {
      logger.info(`Rappel paiement ${stage} ignoré — résa ${reservationId} plus en payment_pending`);
      return;
    }

    const notificationService = require('./notification.service');
    const minutesLeft = reservation.paymentDeadline
      ? Math.max(0, Math.ceil((new Date(reservation.paymentDeadline) - Date.now()) / 60000))
      : null;

    const residenceName = reservation.residence?.title || 'votre résidence';
    const message = stage === 'final'
      ? `⏰ Plus que ${minutesLeft ?? 'quelques'} min pour payer "${residenceName}" — finalisez avant expiration.`
      : `💳 Paiement toujours en attente pour "${residenceName}". Montant: ${reservation.totalPrice || 0} XOF.`;

    await notificationService.createNotification(
      reservation.user._id,
      notificationTypes.CLIENT.PAYMENT_PENDING,
      message,
      {
        reservationId,
        stage,
        event: `payment_reminder_${stage}`,
        minutesLeft,
        amount: reservation.totalPrice,
        deepLink: `/booking-details/${reservationId}`,
      }
    );

    logger.info(`Rappel paiement ${stage} envoyé pour réservation ${reservationId}`);
  } catch (error) {
    logger.error(`Erreur rappel paiement réservation ${job.attrs.data?.reservationId}:`, error);
  }
});

async function schedulePaymentReminders(reservationId, deadline, durationMinutes = 30) {
  try {
    await agenda.cancel({
      name: 'reservation payment reminder',
      'data.reservationId': reservationId,
    });

    const now = Date.now();
    const end = new Date(deadline).getTime();
    const durationMs = Math.max(end - now, 0);
    if (durationMs < 8 * 60 * 1000) {
      logger.info(`Fenêtre paiement trop courte pour rappels (${reservationId})`);
      return { scheduled: 0 };
    }

    let scheduled = 0;

    // Milieu de fenêtre (ex. 30 min → ~15 min)
    const midAt = new Date(now + durationMs * 0.5);
    if (midAt.getTime() > now + 5 * 60 * 1000 && midAt.getTime() < end - 6 * 60 * 1000) {
      await agenda.schedule(midAt, 'reservation payment reminder', {
        reservationId,
        stage: 'mid',
      });
      scheduled += 1;
    }

    // Final : ~5 min avant deadline
    const finalOffsetMs = Math.min(5 * 60 * 1000, Math.floor(durationMs * 0.2));
    const finalAt = new Date(end - Math.max(finalOffsetMs, 3 * 60 * 1000));
    if (finalAt.getTime() > now + 2 * 60 * 1000 && finalAt.getTime() < end - 60 * 1000) {
      await agenda.schedule(finalAt, 'reservation payment reminder', {
        reservationId,
        stage: 'final',
      });
      scheduled += 1;
    }

    logger.info(`Rappels paiement programmés (${scheduled}) pour réservation ${reservationId}`);
    return { scheduled };
  } catch (error) {
    logger.error(`Erreur programmation rappels paiement ${reservationId}:`, error);
    throw error;
  }
}

// ===============================
// ✅ PAYOUT JOBS - Gestion automatique des reversements
// ===============================

/**
 * Job pour exécuter un payout spécifique
 */
agenda.define('process payout', FINANCIAL_JOB_OPTIONS, async (job) => {
  try {
    const { payoutId } = job.attrs.data;

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
    const payoutService = require('./payout.service');
    await payoutService.executePayout(payout);

    logger.info(`Payout ${payoutId} exécuté avec succès via job`);

  } catch (error) {
    logger.error(`Erreur job payout ${job.attrs.data.payoutId}:`, error);

    // Reprogrammer le job en cas d'erreur (retry automatique) — unique par payoutId
    const retryDelay = new Date(Date.now() + 30 * 60 * 1000); // 30 minutes
    await saveUniqueScheduledJob(
      agenda,
      'process payout',
      retryDelay,
      { payoutId: String(job.attrs.data?.payoutId || '') },
      'payoutId'
    );

    throw error; // Marquer le job comme échoué
  }
});

/**
 * Job périodique pour traiter tous les payouts programmés
 */
agenda.define('process scheduled payouts', FINANCIAL_JOB_OPTIONS, async (job) => {
  try {
    logger.info('Traitement périodique des payouts programmés');

    const payoutService = require('./payout.service');
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

    const payoutService = require('./payout.service');
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
    const payoutService = require('./payout.service');
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
    logger.info('Archivage des payouts anciens');

    const cutoffDate = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const stale = await Payout.find({
      status: { $in: ['PAYOUT_FAILED', 'PAYOUT_CANCELLED'] },
      updatedAt: { $lt: cutoffDate },
      attempts: { $gte: 5 },
    }).limit(500);

    let archived = 0;
    for (const payout of stale) {
      const from = payout.status;
      payout.status = 'PAYOUT_ARCHIVED';
      payout.history = payout.history || [];
      payout.history.push({
        status_from: from,
        status_to: 'PAYOUT_ARCHIVED',
        timestamp: new Date(),
        reason: 'Archivage automatique (>30j, tentatives épuisées)',
      });
      await payout.save();
      archived += 1;
    }

    logger.info(`${archived} payouts archivés (traçabilité conservée)`);
  } catch (error) {
    logger.error('Erreur archivage payouts:', error);
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

  return saveUniqueScheduledJob(
    agenda,
    'process payout',
    scheduledDate,
    { payoutId: String(payoutId) },
    'payoutId'
  );
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

// ===============================
// PHASE 2 — Messages non lus + digest Partner
// ===============================

/**
 * Rappel si un message est toujours non lu après délai.
 * Push immédiat éventuel déjà géré dans message.controller (si offline).
 */
agenda.define('remind unread message', async (job) => {
  try {
    const { messageId, recipientId, deepLink } = job.attrs.data;
    const { Message } = require('../models/message.model');

    const message = await Message.findById(messageId).populate('sender', 'firstName lastName name');
    if (!message || message.read === true) {
      logger.info(`Rappel message ignoré (lu ou absent): ${messageId}`);
      return;
    }

    if (message.sender && message.sender._id.toString() === String(recipientId)) {
      return;
    }

    const Notification = require('../models/notification.model');
    const existing = await Notification.findOne({
      user: recipientId,
      type: notificationTypes.COMMON.NEW_MESSAGE,
      'data.messageId': String(messageId),
      'data.event': 'unread_message_reminder',
    });
    if (existing) {
      logger.info(`Rappel message déjà envoyé (idempotent): ${messageId}`);
      return;
    }

    const senderName =
      message.sender?.firstName ||
      message.sender?.name ||
      'Quelqu\'un';
    const preview = (message.content || '').substring(0, 50);
    const notificationService = require('./notification.service');

    await notificationService.createNotification(
      recipientId,
      notificationTypes.COMMON.NEW_MESSAGE,
      `${senderName} attend votre réponse: ${preview}${(message.content || '').length > 50 ? '...' : ''}`,
      {
        messageId: String(messageId),
        conversationId: message.conversation?.toString?.() || message.conversation,
        event: 'unread_message_reminder',
        deepLink: deepLink || '/notifications',
      }
    );

    logger.info(`Rappel message non lu envoyé à ${recipientId} (msg ${messageId})`);
  } catch (error) {
    logger.error(`Erreur rappel message non lu:`, error);
  }
});

async function scheduleUnreadMessageReminder(messageId, recipientId, delayMinutes = 60, deepLink = '/notifications') {
  try {
    await agenda.cancel({
      name: 'remind unread message',
      'data.messageId': String(messageId),
      'data.recipientId': String(recipientId),
    });

    const when = new Date(Date.now() + delayMinutes * 60 * 1000);
    await agenda.schedule(when, 'remind unread message', {
      messageId: String(messageId),
      recipientId: String(recipientId),
      deepLink,
    });

    logger.info(`Rappel message programmé dans ${delayMinutes} min pour ${recipientId}`);
  } catch (error) {
    logger.error(`Erreur programmation rappel message:`, error);
  }
}

/**
 * Digest matinal Partner : actions en attente uniquement si count > 0
 * Cron 09:00 (serveur UTC = Abidjan GMT)
 */
agenda.define('partner pending actions digest', async () => {
  try {
    const { Message, Conversation } = require('../models/message.model');
    const notificationService = require('./notification.service');
    const Notification = require('../models/notification.model');

    const partners = await User.find({
      role: { $in: ['partner', 'partner_pending'] },
      isActive: { $ne: false },
      'notificationSettings.pushEnabled': { $ne: false },
    }).select('_id firstName');

    const todayKey = new Date().toISOString().slice(0, 10);

    for (const partner of partners) {
      try {
        const awaitingApproval = await Reservation.countDocuments({
          partner: partner._id,
          status: 'awaiting_approval',
        });

        const conversations = await Conversation.find({
          participants: partner._id,
        }).select('_id');

        const conversationIds = conversations.map((c) => c._id);
        const unreadMessages = conversationIds.length
          ? await Message.countDocuments({
              conversation: { $in: conversationIds },
              sender: { $ne: partner._id },
              read: false,
            })
          : 0;

        if (awaitingApproval + unreadMessages <= 0) continue;

        const existingDigest = await Notification.findOne({
          user: partner._id,
          'data.event': 'partner_pending_digest',
          'data.day': todayKey,
        });
        if (existingDigest) continue;

        const parts = [];
        if (awaitingApproval > 0) parts.push(`${awaitingApproval} réservation(s) en attente`);
        if (unreadMessages > 0) parts.push(`${unreadMessages} message(s) non lus`);

        await notificationService.notifyPartner(
          partner._id,
          notificationTypes.PARTNER.PENDING_DIGEST,
          {
            event: 'partner_pending_digest',
            day: todayKey,
            awaitingApproval,
            unreadMessages,
            summary: parts.join(', '),
            deepLink: '/notifications',
          }
        );
      } catch (partnerErr) {
        logger.error(`Digest partner échoué pour ${partner._id}:`, partnerErr);
      }
    }

    logger.info('Digest Partner pending actions terminé');
  } catch (error) {
    logger.error('Erreur digest Partner:', error);
  }
});

/**
 * Phase 3 — Relance clients inactifs 7 jours (engagement doux, max 1 / 14 j)
 * Cron 10:00 UTC
 */
agenda.define('client reengage inactive', async () => {
  try {
    const notificationService = require('./notification.service');
    const Notification = require('../models/notification.model');

    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const fourteenDaysAgo = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000);

    const clients = await User.find({
      role: 'client',
      isActive: { $ne: false },
      'notificationSettings.pushEnabled': { $ne: false },
      'notificationSettings.categories.promotions': { $ne: false },
      $or: [
        { lastAppActivity: { $lt: sevenDaysAgo } },
        {
          lastAppActivity: { $exists: false },
          lastLogin: { $lt: sevenDaysAgo },
        },
        {
          lastAppActivity: { $exists: false },
          lastLogin: { $exists: false },
          createdAt: { $lt: sevenDaysAgo },
        },
      ],
    })
      .select('_id firstName lastAppActivity lastLogin')
      .limit(200);

    let sent = 0;

    for (const client of clients) {
      try {
        const lastActivity = client.lastAppActivity || client.lastLogin;
        if (lastActivity && lastActivity > sevenDaysAgo) continue;

        const activeStay = await Reservation.countDocuments({
          user: client._id,
          status: { $in: ['confirmed', 'in_stay', 'payment_pending', 'awaiting_approval'] },
        });
        if (activeStay > 0) continue;

        const recentReengage = await Notification.findOne({
          user: client._id,
          type: notificationTypes.CLIENT.REENGAGE,
          createdAt: { $gte: fourteenDaysAgo },
        });
        if (recentReengage) continue;

        await notificationService.notifyClient(
          client._id,
          notificationTypes.CLIENT.REENGAGE,
          {
            event: 'client_reengage_7d',
            deepLink: '/',
          }
        );
        sent += 1;
      } catch (clientErr) {
        logger.error(`Reengage échoué pour ${client._id}:`, clientErr);
      }
    }

    logger.info(`Reengage 7j terminé — ${sent} notification(s) envoyée(s)`);
  } catch (error) {
    logger.error('Erreur job client reengage inactive:', error);
  }
});

/**
 * Phase 3 — Demande d'avis ~24 h après check-out
 */
agenda.define('client review reminder', async (job) => {
  try {
    const { reservationId } = job.attrs.data || {};
    if (!reservationId) return;

    const Review = require('../models/review.model');
    const notificationService = require('./notification.service');
    const Notification = require('../models/notification.model');

    const reservation = await Reservation.findById(reservationId)
      .populate('residence', 'title')
      .populate('user', '_id role');

    if (!reservation || reservation.status !== 'completed') {
      logger.info(`Review reminder ignoré (résa absente ou non completed): ${reservationId}`);
      return;
    }

    const userId = reservation.user?._id || reservation.user;
    if (!userId) return;

    const existingReview = await Review.findOne({
      $or: [
        { reservation: reservation._id },
        {
          user: userId,
          residence: reservation.residence?._id || reservation.residence,
        },
      ],
    });
    if (existingReview) {
      logger.info(`Review reminder ignoré (avis déjà créé): ${reservationId}`);
      return;
    }

    const alreadySent = await Notification.findOne({
      user: userId,
      type: notificationTypes.CLIENT.REVIEW_REQUEST,
      'data.reservationId': String(reservationId),
    });
    if (alreadySent) return;

    const residenceId = (reservation.residence?._id || reservation.residence)?.toString();
    const residenceName = reservation.residence?.title;

    await notificationService.notifyClient(
      userId,
      notificationTypes.CLIENT.REVIEW_REQUEST,
      {
        event: 'post_stay_review',
        reservationId: String(reservationId),
        residenceId,
        residenceName,
        deepLink: residenceId ? `/reviews/${residenceId}` : '/',
      }
    );

    logger.info(`Review reminder envoyé pour réservation ${reservationId}`);
  } catch (error) {
    logger.error('Erreur job client review reminder:', error);
  }
});

async function scheduleReviewReminder(reservationId, delayHours = 24) {
  try {
    const id = String(reservationId);
    await agenda.cancel({
      name: 'client review reminder',
      'data.reservationId': id,
    });

    const when = new Date(Date.now() + delayHours * 60 * 60 * 1000);
    await agenda.schedule(when, 'client review reminder', { reservationId: id });
    logger.info(`Review reminder programmé dans ${delayHours}h pour ${id}`);
  } catch (error) {
    logger.error(`Erreur programmation review reminder:`, error);
  }
}

/**
 * Phase 3 — Recherche abandonnée : vue résidence sans résa sous 24 h
 */
agenda.define('client abandoned residence view', async (job) => {
  try {
    const { userId, residenceId, viewId } = job.attrs.data || {};
    if (!userId || !residenceId) return;

    const ResidenceView = require('../models/residence-view.model');
    const Residence = require('../models/residence.model');
    const notificationService = require('./notification.service');
    const Notification = require('../models/notification.model');

    const view = viewId
      ? await ResidenceView.findById(viewId)
      : await ResidenceView.findOne({ user: userId, residence: residenceId });

    if (!view || view.remindedAt) {
      logger.info(`Abandoned search ignoré (vue absente ou déjà relancée): ${userId}/${residenceId}`);
      return;
    }

    const booked = await Reservation.exists({
      user: userId,
      residence: residenceId,
      createdAt: { $gte: view.viewedAt },
      status: { $nin: ['cancelled', 'expired'] },
    });
    if (booked) {
      logger.info(`Abandoned search ignoré (réservation créée): ${userId}/${residenceId}`);
      return;
    }

    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const recentAbandoned = await Notification.findOne({
      user: userId,
      type: notificationTypes.CLIENT.ABANDONED_SEARCH,
      createdAt: { $gte: sevenDaysAgo },
    });
    if (recentAbandoned) {
      logger.info(`Abandoned search throttled (max 1/7j): ${userId}`);
      return;
    }

    const residence = await Residence.findById(residenceId).select('title status isAvailable');
    if (!residence) return;

    await notificationService.notifyClient(
      userId,
      notificationTypes.CLIENT.ABANDONED_SEARCH,
      {
        event: 'abandoned_residence_view',
        residenceId: String(residenceId),
        residenceName: residence.title,
        deepLink: `/residence/${residenceId}`,
      }
    );

    view.remindedAt = new Date();
    await view.save();

    logger.info(`Abandoned search envoyé: user ${userId} résidence ${residenceId}`);
  } catch (error) {
    logger.error('Erreur job client abandoned residence view:', error);
  }
});

/**
 * Enregistre une vue client et programme la relance +24 h (idempotent).
 */
async function trackResidenceViewForEngagement(userId, residenceId) {
  try {
    if (!userId || !residenceId) return;

    const user = await User.findById(userId).select('role notificationSettings');
    if (!user || user.role !== 'client') return;
    if (user.notificationSettings?.pushEnabled === false) return;
    if (user.notificationSettings?.categories?.promotions === false) return;

    const ResidenceView = require('../models/residence-view.model');
    const now = new Date();

    const view = await ResidenceView.findOneAndUpdate(
      { user: userId, residence: residenceId },
      {
        $set: { viewedAt: now },
        $setOnInsert: { user: userId, residence: residenceId },
      },
      { upsert: true, new: true }
    );

    // Ne pas reprogrammer si déjà relancé récemment (< 7 j) sur cette vue
    if (view.remindedAt && Date.now() - view.remindedAt.getTime() < 7 * 24 * 60 * 60 * 1000) {
      return;
    }

    await agenda.cancel({
      name: 'client abandoned residence view',
      'data.userId': String(userId),
      'data.residenceId': String(residenceId),
    });

    const when = new Date(Date.now() + 24 * 60 * 60 * 1000);
    await agenda.schedule(when, 'client abandoned residence view', {
      userId: String(userId),
      residenceId: String(residenceId),
      viewId: String(view._id),
    });

    view.reminderScheduledAt = when;
    await view.save();
    if (view.remindedAt) {
      await ResidenceView.updateOne({ _id: view._id }, { $unset: { remindedAt: 1 } });
    }

    logger.info(`Vue résidence trackée + relance 24h: ${userId}/${residenceId}`);
  } catch (error) {
    logger.error('Erreur trackResidenceViewForEngagement:', error);
  }
}

function startEngagementPeriodicJobs() {
  // 09:00 UTC (= 09:00 Abidjan) — Phase 2
  agenda.every('0 9 * * *', 'partner pending actions digest');
  // 10:00 UTC — Phase 3 reengage
  agenda.every('0 10 * * *', 'client reengage inactive');
  logger.info('Jobs engagement Phase 2+3 démarrés (digest 09:00, reengage 10:00)');
}

function startRefundPeriodicJobs() {
  agenda.every('5 minutes', 'sweep payment refunds');
  logger.info('Job sweep payment refunds démarré (toutes les 5 min)');
}

agenda.define('process payment refund', FINANCIAL_JOB_OPTIONS, async (job) => {
  const { paymentId } = job.attrs.data || {};
  if (!paymentId) return;
  const refundService = require('./refund.service');
  await refundService.processPaymentRefund(paymentId);
});

agenda.define('sweep payment refunds', FINANCIAL_JOB_OPTIONS, async () => {
  const refundService = require('./refund.service');
  await refundService.sweepDueRefunds();
});

module.exports = {
  agenda,
  startAgenda,
  // Reservation methods
  scheduleReservationReminder,
  scheduleReservationDepartureReminder,
  notifyReservationStatusChange,
  // Reservation expiration
  scheduleReservationExpiration,
  cancelReservationExpiration,
  schedulePaymentReminders,
  scheduleUnreadMessageReminder,
  scheduleReviewReminder,
  trackResidenceViewForEngagement,
  // Payout methods
  schedulePayoutExecution,
  scheduleAutoPayoutCreation,
  startPayoutPeriodicJobs,
  startEngagementPeriodicJobs,
  startRefundPeriodicJobs,
  startHostApprovalPeriodicJobs,
  saveUniqueScheduledJob,
};
