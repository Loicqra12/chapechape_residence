const mongoose = require('mongoose');
const Reservation = require('../models/reservation.model');
const notificationService = require('./notification.service');
const availabilityService = require('./availability.service');
const { scheduleReservationExpiration, cancelReservationExpiration } = require('./agenda.service');

/**

 * Gère l'expiration automatique des réservations en attente de paiement
 */

/**
 * ✅ Démarrer le timer de paiement pour une réservation
 * @param {string} reservationId - ID de la réservation
 * @param {number} durationMinutes - Durée en minutes (défaut: 30)
 * @returns {Promise<Object>} - Résultat du timer
 */
const startPaymentTimer = async (reservationId, durationMinutes = 30) => {
  try {
    const deadline = new Date(Date.now() + durationMinutes * 60 * 1000);

    const reservation = await Reservation.findByIdAndUpdate(
      reservationId,
      {
        $set: {
          status: 'payment_pending',
          paymentDeadline: deadline,
          paymentTimerDuration: durationMinutes
        },
        $push: {
          statusHistory: {
            status: 'payment_pending',
            paymentStatus: 'pending',
            changedAt: new Date(),
            reason: `Timer de paiement démarré (${durationMinutes} minutes)`
          }
        }
      },
      { new: true }
    ).populate('user residence');

    if (!reservation) {
      throw new Error('Réservation non trouvée');
    }

    // ✅ Envoyer notification SMS/Push de délai de paiement
    await notificationService.sendPaymentDeadlineNotification(reservation, deadline);

    // ✅ Programmer l'expiration automatique via Agenda (persistant au restart)
    await scheduleReservationExpiration(reservationId, deadline);

    console.log(`Timer de paiement démarré pour réservation ${reservationId}: ${durationMinutes} min (via Agenda)`);
    return {
      success: true,
      reservationId,
      deadline,
      durationMinutes
    };

  } catch (error) {
    console.error('Erreur démarrage timer paiement:', error);
    throw error;
  }
};

/**
 * ✅ Vérifier et expirer une réservation si nécessaire
 * @param {string} reservationId - ID de la réservation
 * @returns {Promise<Object>} - Résultat de l'expiration
 */
const checkAndExpireReservation = async (reservationId) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const reservation = await Reservation.findById(reservationId)
      .populate('user residence partner')
      .session(session);

    if (!reservation) {
      await session.abortTransaction();
      return { expired: false, reason: 'Réservation non trouvée' };
    }

    // Vérifier si la réservation est toujours en attente de paiement
    if (reservation.status !== 'payment_pending' || reservation.paymentStatus === 'paid') {
      await session.abortTransaction();
      return { expired: false, reason: 'Réservation déjà traitée' };
    }

    // Vérifier si le délai est dépassé
    const now = new Date();
    if (!reservation.paymentDeadline || now < reservation.paymentDeadline) {
      await session.abortTransaction();
      return { expired: false, reason: 'Délai non expiré' };
    }

    // ✅ Expirer la réservation
    await Reservation.findByIdAndUpdate(
      reservationId,
      {
        $set: {
          status: 'expired',
          paymentStatus: 'expired'
        },
        $push: {
          statusHistory: {
            status: 'expired',
            paymentStatus: 'expired',
            changedAt: now,
            reason: 'Délai de paiement expiré'
          }
        }
      },
      { session }
    );

    // ✅ Libérer la disponibilité
    await availabilityService.updateAvailabilityForReservation(
      reservation.residence._id,
      reservation.checkIn,
      reservation.checkOut,
      reservationId,
      'available'
    );

    // ✅ Envoyer notifications d'expiration
    await notificationService.sendReservationExpiredNotification(reservation);

    await session.commitTransaction();
    console.log(`Réservation ${reservationId} expirée automatiquement`);

    return {
      expired: true,
      reservationId,
      expiredAt: now,
      reason: 'Délai de paiement dépassé'
    };

  } catch (error) {
    await session.abortTransaction();
    console.error('Erreur expiration réservation:', error);
    throw error;
  } finally {
    session.endSession();
  }
};

/**
 * ✅ Prolonger le délai de paiement d'une réservation
 * @param {string} reservationId - ID de la réservation
 * @param {number} additionalMinutes - Minutes supplémentaires
 * @returns {Promise<Object>} - Nouvelle échéance
 */
const extendPaymentDeadline = async (reservationId, additionalMinutes = 15) => {
  try {
    const reservation = await Reservation.findById(reservationId);

    if (!reservation || reservation.status !== 'payment_pending') {
      throw new Error('Réservation non éligible à une extension');
    }

    const currentDeadline = reservation.paymentDeadline || new Date();
    const newDeadline = new Date(currentDeadline.getTime() + additionalMinutes * 60 * 1000);

    await Reservation.findByIdAndUpdate(
      reservationId,
      {
        $set: {
          paymentDeadline: newDeadline
        },
        $push: {
          statusHistory: {
            status: 'payment_pending',
            paymentStatus: 'pending',
            changedAt: new Date(),
            reason: `Délai prolongé de ${additionalMinutes} minutes`
          }
        }
      }
    );

    console.log(`Délai prolongé pour réservation ${reservationId}: +${additionalMinutes} min`);
    return {
      success: true,
      reservationId,
      newDeadline,
      additionalMinutes
    };

  } catch (error) {
    console.error('Erreur prolongation délai:', error);
    throw error;
  }
};

/**
 * ✅ Vérifier toutes les réservations expirées (tâche cron)
 * @returns {Promise<Array>} - Liste des réservations expirées
 */
const checkAllExpiredReservations = async () => {
  try {
    const now = new Date();

    // Trouver toutes les réservations en attente avec délai dépassé
    const expiredReservations = await Reservation.find({
      status: 'payment_pending',
      paymentDeadline: { $lt: now },
      paymentStatus: { $ne: 'paid' }
    });

    console.log(`Vérification expiration: ${expiredReservations.length} réservations à traiter`);

    const results = [];
    for (const reservation of expiredReservations) {
      try {
        const result = await checkAndExpireReservation(reservation._id);
        results.push(result);
      } catch (error) {
        console.error(`Erreur expiration ${reservation._id}:`, error);
        results.push({ expired: false, reservationId: reservation._id, error: error.message });
      }
    }

    return results;

  } catch (error) {
    console.error('Erreur vérification massive expiration:', error);
    throw error;
  }
};

/**
 * ✅ Confirmer le paiement et arrêter le timer
 * @param {string} reservationId - ID de la réservation
 * @param {Object} paymentData - Données de paiement
 * @returns {Promise<Object>} - Résultat de la confirmation
 */
const confirmPaymentAndStopTimer = async (reservationId, paymentData = {}) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const reservation = await Reservation.findByIdAndUpdate(
      reservationId,
      {
        $set: {
          status: 'confirmed',
          paymentStatus: 'paid',
          paymentDeadline: null // Arrêter le timer
        },
        $push: {
          statusHistory: {
            status: 'confirmed',
            paymentStatus: 'paid',
            changedAt: new Date(),
            reason: 'Paiement confirmé - Timer arrêté'
          }
        }
      },
      { new: true, session }
    ).populate('user residence partner');

    if (!reservation) {
      throw new Error('Réservation non trouvée');
    }

    // ✅ Annuler le job d'expiration Agenda
    await cancelReservationExpiration(reservationId);

    // ✅ Envoyer confirmations de paiement
    await notificationService.sendPaymentConfirmationNotification(reservation);

    await session.commitTransaction();
    console.log(`Paiement confirmé et timer Agenda annulé pour réservation ${reservationId}`);

    return {
      success: true,
      reservationId,
      status: 'confirmed',
      paymentStatus: 'paid',
      confirmedAt: new Date()
    };

  } catch (error) {
    await session.abortTransaction();
    console.error('Erreur confirmation paiement:', error);
    throw error;
  } finally {
    session.endSession();
  }
};

module.exports = {
  startPaymentTimer,
  checkAndExpireReservation,
  extendPaymentDeadline,
  checkAllExpiredReservations,
  confirmPaymentAndStopTimer
};
