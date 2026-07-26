const Payment = require('../models/payment.model');
const Reservation = require('../models/reservation.model');
const { Conversation, Message } = require('../models/message.model');
const WebhookEvent = require('../models/webhook-event.model');
const logger = require('../utils/logger');

/**
 * Réclame un événement webhook pour traitement.
 * - Nouveau → status processing, claimed=true
 * - Déjà completed → claimed=false
 * - failed → reprise possible (claimed=true)
 * - processing récent → claimed=false (évite double traitement concurrent)
 *
 * @returns {{ claimed: boolean, alreadyCompleted: boolean }}
 */
async function claimWebhookEvent(provider, eventId, payloadHash = null) {
  try {
    await WebhookEvent.create({
      provider,
      eventId,
      payloadHash,
      status: 'processing',
    });
    return { claimed: true, alreadyCompleted: false };
  } catch (err) {
    if (err.code !== 11000) throw err;

    const existing = await WebhookEvent.findOne({ provider, eventId });
    if (!existing) {
      return { claimed: false, alreadyCompleted: false };
    }

    if (existing.status === 'completed') {
      logger.info(`Webhook déjà traité: ${provider}/${eventId}`);
      return { claimed: false, alreadyCompleted: true };
    }

    if (existing.status === 'failed') {
      const updated = await WebhookEvent.findOneAndUpdate(
        { provider, eventId, status: 'failed' },
        {
          $set: {
            status: 'processing',
            lastError: null,
            payloadHash: payloadHash || existing.payloadHash,
          },
        },
        { new: true }
      );
      if (updated) {
        logger.info(`Webhook retry après échec: ${provider}/${eventId}`);
        return { claimed: true, alreadyCompleted: false };
      }
    }

    // processing en cours (ou course concurrente)
    logger.info(`Webhook déjà en cours: ${provider}/${eventId}`);
    return { claimed: false, alreadyCompleted: false };
  }
}

/**
 * Marque l'événement comme traité avec succès (après applyPaymentPaid etc.)
 */
async function completeWebhookEvent(provider, eventId) {
  await WebhookEvent.updateOne(
    { provider, eventId },
    { $set: { status: 'completed', processedAt: new Date(), lastError: null } }
  );
}

/**
 * Marque l'événement en échec pour permettre un retry PSP
 */
async function failWebhookEvent(provider, eventId, errorMessage) {
  await WebhookEvent.updateOne(
    { provider, eventId },
    {
      $set: {
        status: 'failed',
        lastError: (errorMessage || 'unknown').toString().slice(0, 500),
        processedAt: new Date(),
      },
    }
  );
}

/**
 * @deprecated Préférer claimWebhookEvent + completeWebhookEvent
 * Conservé pour compat : crée l'événement ; true si nouveau.
 */
async function registerWebhookEvent(provider, eventId, payloadHash = null) {
  const result = await claimWebhookEvent(provider, eventId, payloadHash);
  return result.claimed;
}

/**
 * Confirme un paiement et la réservation de façon idempotente.
 * @returns {{ applied: boolean, alreadyPaid: boolean, payment: object|null }}
 */
async function applyPaymentPaid(payment, options = {}) {
  // allowExpired: webhooks PSP uniquement — un paiement localement « expired »
  // peut encore être validé si le client a payé côté PSP avant/après le cutoff.
  const { providerResponse, triggerPayout = true, allowExpired = false } = options;

  if (!payment) {
    return { applied: false, alreadyPaid: false, payment: null };
  }

  if (payment.status === 'paid') {
    return { applied: false, alreadyPaid: true, payment };
  }

  const updateFields = {
    status: 'paid',
    providerStatus: 'validated',
  };
  if (providerResponse !== undefined) {
    updateFields['paymentDetails.providerResponse'] = providerResponse;
  }

  const allowedStatuses = allowExpired
    ? ['pending', 'failed', 'expired']
    : ['pending', 'failed'];

  const updatedPayment = await Payment.findOneAndUpdate(
    {
      _id: payment._id,
      status: { $in: allowedStatuses },
    },
    { $set: updateFields },
    { new: true }
  );

  if (!updatedPayment) {
    const current = await Payment.findById(payment._id);
    const alreadyPaid = current?.status === 'paid';
    return { applied: false, alreadyPaid, payment: current };
  }

  const reservationId = updatedPayment.reservation;

  // payment_pending / awaiting_approval / pending → confirmed (filtre source)
  await Reservation.updateOne(
    {
      _id: reservationId,
      paymentStatus: { $ne: 'paid' },
      status: { $in: ['pending', 'awaiting_approval', 'payment_pending', 'confirmed'] },
    },
    {
      $set: {
        paymentStatus: 'paid',
        status: 'confirmed',
        messagingEnabled: true,
        paymentDeadline: null,
      },
      $push: {
        statusHistory: {
          status: 'confirmed',
          paymentStatus: 'paid',
          changedAt: new Date(),
          reason: 'Paiement confirmé (webhook/PSP)',
        },
      },
    }
  );

  await ensureReservationConversation(reservationId);

  // Annuler expiration + rappels paiement (webhooks / PSP)
  try {
    const { cancelReservationExpiration } = require('./agenda.service');
    await cancelReservationExpiration(reservationId);
  } catch (cancelErr) {
    logger.error('Annulation jobs paiement échouée:', cancelErr);
  }

  // Notifications Client + Partner (idempotentes) — chemin canonique webhook/PSP
  try {
    const reservationForNotif = await Reservation.findById(reservationId)
      .populate('user residence partner');
    if (reservationForNotif) {
      const notificationService = require('./notification.service');
      await notificationService.sendPaymentConfirmationNotification(reservationForNotif);
    }
  } catch (notifError) {
    logger.error('Notification confirmation paiement non envoyée:', notifError);
  }

  if (triggerPayout) {
    try {
      const reservation = await Reservation.findById(reservationId).populate('partner');
      const AutomaticPayoutService = require('./automatic-payout.service');
      await AutomaticPayoutService.triggerAutomaticPayout(updatedPayment, reservation);
    } catch (payoutError) {
      logger.error('Payout automatique non déclenché:', payoutError);
    }
  }

  return { applied: true, alreadyPaid: false, payment: updatedPayment };
}

async function ensureReservationConversation(reservationId) {
  const existing = await Conversation.findOne({ reservationId });
  if (existing) return;

  const populated = await Reservation.findById(reservationId).populate('user partner residence');
  if (!populated?.user || !populated?.partner) return;

  const conversation = await Conversation.create({
    participants: [populated.user._id, populated.partner._id],
    reservationId: populated._id,
    residenceId: populated.residence._id,
    createdAt: Date.now(),
    updatedAt: Date.now(),
  });

  const residenceName =
    populated.residence?.title || populated.residence?.name || 'votre résidence';

  const message = await Message.create({
    conversation: conversation._id,
    sender: populated.partner._id,
    content: `Merci pour votre réservation de "${residenceName}" ! N'hésitez pas à me contacter pour toute question concernant votre séjour.`,
  });

  conversation.lastMessage = message._id;
  await conversation.save();
}

module.exports = {
  registerWebhookEvent,
  claimWebhookEvent,
  completeWebhookEvent,
  failWebhookEvent,
  applyPaymentPaid,
};
