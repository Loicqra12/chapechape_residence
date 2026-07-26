const Reservation = require('../models/reservation.model');
const Payment = require('../models/payment.model');
const ApiError = require('../utils/apiError');
const logger = require('../utils/logger');
const errorCodes = require('../utils/errorCodes');

/**
 * Machine à états réelle pour les réservations.
 * Transitions autorisées + update atomique (filtre sur statut source).
 */
class ReservationStateService {
  /** Statuts nécessitant paymentStatus === 'paid' */
  static PAYMENT_REQUIRED_STATUSES = ['confirmed', 'in_stay', 'completed'];

  /**
   * Graphe des transitions autorisées (from → [to...])
   * Aligné sur l'enum reservation.model.js
   */
  static ALLOWED_TRANSITIONS = {
    pending: ['awaiting_approval', 'payment_pending', 'confirmed', 'cancelled', 'expired'],
    awaiting_approval: ['payment_pending', 'cancelled'],
    payment_pending: ['confirmed', 'expired', 'cancelled'],
    confirmed: ['in_stay', 'cancelled', 'completed', 'refunded'],
    in_stay: ['completed', 'cancelled'],
    expired: [],
    cancelled: ['refunded'],
    completed: ['refunded'],
    refunded: [],
  };

  /** Statuts sources possibles pour atteindre newStatus */
  static getAllowedSourceStatuses(newStatus) {
    return Object.entries(this.ALLOWED_TRANSITIONS)
      .filter(([, targets]) => targets.includes(newStatus))
      .map(([from]) => from);
  }

  static isTransitionAllowed(fromStatus, toStatus) {
    const allowed = this.ALLOWED_TRANSITIONS[fromStatus];
    return Array.isArray(allowed) && allowed.includes(toStatus);
  }

  /**
   * Transition atomique avec validation du graphe d'états
   */
  static async updateStatus(reservationId, newStatus, userId, options = {}) {
    const { reason = null } = options;

    logger.info(`Transition atomique: ${reservationId} -> ${newStatus}`, {
      userId,
      reason,
    });

    const sourceStatuses = this.getAllowedSourceStatuses(newStatus);
    if (sourceStatuses.length === 0) {
      throw new ApiError(
        `Aucune transition autorisée vers le statut ${newStatus}`,
        400,
        errorCodes.RESERVATION.INVALID_STATE_TRANSITION
      );
    }

    const atomicFilter = {
      _id: reservationId,
      status: { $in: sourceStatuses },
    };

    if (this.PAYMENT_REQUIRED_STATUSES.includes(newStatus)) {
      atomicFilter.paymentStatus = 'paid';
    }

    const updateData = {
      status: newStatus,
      $push: {
        statusHistory: {
          status: newStatus,
          changedAt: new Date(),
          changedBy: userId,
          reason: reason,
        },
      },
    };

    if (newStatus === 'in_stay') {
      updateData.actualCheckIn = new Date();
    } else if (newStatus === 'completed') {
      updateData.actualCheckOut = new Date();
    } else if (newStatus === 'cancelled') {
      updateData.cancelledAt = new Date();
      updateData.cancellationReason = reason;
    }

    const updatedReservation = await Reservation.findOneAndUpdate(
      atomicFilter,
      updateData,
      {
        new: true,
        runValidators: true,
        context: 'query',
      }
    ).populate(['residence', 'user', 'partner']);

    if (!updatedReservation) {
      const currentReservation = await Reservation.findById(
        reservationId,
        'status paymentStatus'
      );

      if (!currentReservation) {
        throw new ApiError(
          'Réservation non trouvée',
          404,
          errorCodes.RESERVATION.NOT_FOUND
        );
      }

      if (
        this.PAYMENT_REQUIRED_STATUSES.includes(newStatus) &&
        currentReservation.paymentStatus !== 'paid'
      ) {
        throw new ApiError(
          `Impossible de passer au statut ${newStatus} : paiement requis (statut actuel: ${currentReservation.paymentStatus})`,
          400,
          errorCodes.RESERVATION.PAYMENT_REQUIRED
        );
      }

      if (!this.isTransitionAllowed(currentReservation.status, newStatus)) {
        throw new ApiError(
          `Transition interdite: ${currentReservation.status} → ${newStatus}`,
          400,
          errorCodes.RESERVATION.INVALID_STATE_TRANSITION
        );
      }

      throw new ApiError(
        `Échec de la transition atomique vers ${newStatus}. État actuel: ${currentReservation.status}`,
        409,
        errorCodes.RESERVATION.CONCURRENT_MODIFICATION
      );
    }

    logger.info(`Transition réussie: ${updatedReservation.status}`, {
      reservationId,
      userId,
    });

    // Phase 3 — post-séjour : programmer demande d'avis
    if (newStatus === 'completed') {
      try {
        const { scheduleReviewReminder } = require('./agenda.service');
        await scheduleReviewReminder(updatedReservation._id, 24);
      } catch (err) {
        logger.warn('scheduleReviewReminder échoué:', err?.message);
      }
    }

    return updatedReservation;
  }

  /**
   * Valide le statut de paiement depuis la source de vérité (Payment)
   */
  static async validatePaymentStatus(reservationId) {
    const latestPayment = await Payment.findOne({
      reservation: reservationId,
    }).sort({ createdAt: -1 });

    if (!latestPayment) {
      return 'pending';
    }

    // Aligné sur les statuts métier Payment (paid, pas completed)
    if (latestPayment.status === 'paid' || latestPayment.status === 'completed') {
      return 'paid';
    }
    return latestPayment.status;
  }
}

module.exports = ReservationStateService;
