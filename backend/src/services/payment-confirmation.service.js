const Payment = require('../models/payment.model');
const Reservation = require('../models/reservation.model');
const { Conversation, Message } = require('../models/message.model');
const WebhookEvent = require('../models/webhook-event.model');
const logger = require('../utils/logger');

/**
 * Enregistre un événement webhook ; retourne false si déjà traité.
 */
async function registerWebhookEvent(provider, eventId, payloadHash = null) {
  try {
    await WebhookEvent.create({ provider, eventId, payloadHash });
    return true;
  } catch (err) {
    if (err.code === 11000) {
      logger.info(`Webhook déjà traité: ${provider}/${eventId}`);
      return false;
    }
    throw err;
  }
}

/**
 * Confirme un paiement et la réservation de façon idempotente.
 * @returns {{ applied: boolean, alreadyPaid: boolean, payment: object|null }}
 */
async function applyPaymentPaid(payment, options = {}) {
  const { providerResponse, triggerPayout = true } = options;

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

  const updatedPayment = await Payment.findOneAndUpdate(
    {
      _id: payment._id,
      status: { $in: ['pending', 'failed', 'expired'] },
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

  await Reservation.updateOne(
    {
      _id: reservationId,
      paymentStatus: { $ne: 'paid' },
    },
    {
      $set: {
        paymentStatus: 'paid',
        status: 'confirmed',
        messagingEnabled: true,
      },
    }
  );

  await ensureReservationConversation(reservationId);

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

  const message = await Message.create({
    conversation: conversation._id,
    sender: populated.partner._id,
    content: `Merci pour votre réservation de "${populated.residence.name}" ! N'hésitez pas à me contacter pour toute question concernant votre séjour.`,
  });

  conversation.lastMessage = message._id;
  await conversation.save();
}

module.exports = {
  registerWebhookEvent,
  applyPaymentPaid,
};
