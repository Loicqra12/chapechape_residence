const mongoose = require('mongoose');
const { ApiError } = require('../utils/apiError');
const Reservation = require('../models/reservation.model');
const Residence = require('../models/residence.model');
const Availability = require('../models/availability.model');
const User = require('../models/user.model');
const CancellationPolicy = require('../models/cancellationPolicy.model');
const emailService = require('./email.service');

/**
 * Créer une nouvelle réservation
 * @param {Object} reservationBody
 * @returns {Promise<Reservation>}
 */
const createReservation = async (reservationBody) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const residence = await Residence.findById(reservationBody.residence)
      .populate('cancellationPolicy');

    if (!residence) {
      throw new ApiError('Résidence non trouvée', 404);
    }

    if (!residence.cancellationPolicy) {
      throw new ApiError('La résidence n\'a pas de politique d\'annulation définie', 400);
    }

    // Vérifier la disponibilité
    const isAvailable = await residence.isAvailableForDates(
      reservationBody.checkIn,
      reservationBody.checkOut
    );

    if (!isAvailable) {
      throw new ApiError('La résidence n\'est pas disponible pour ces dates', 400);
    }

    // Calculer le prix total
    const totalPrice = await residence.calculateTotalPrice(
      reservationBody.checkIn,
      reservationBody.checkOut
    );

    // Créer la réservation
    const reservation = await Reservation.create([{
      ...reservationBody,
      totalPrice,
      cancellationPolicy: residence.cancellationPolicy._id,
      status: 'pending'
    }], { session });

    // Mettre à jour la disponibilité
    await Availability.updateAvailabilityForReservation(
      residence._id,
      reservation[0]._id,
      reservationBody.checkIn,
      reservationBody.checkOut,
      'reserved',
      session
    );

    await session.commitTransaction();

    // Envoyer les emails de confirmation
    const [user, partner] = await Promise.all([
      User.findById(reservation[0].client),
      User.findById(residence.owner)
    ]);

    await Promise.all([
      emailService.sendBookingConfirmation(user.email, reservation[0]),
      emailService.sendPartnerNotification(partner, 'new_booking', {
        checkIn: reservation[0].checkIn,
        checkOut: reservation[0].checkOut,
        guests: reservation[0].numberOfGuests
      })
    ]);

    return reservation[0];
  } catch (error) {
    await session.abortTransaction();
    throw error;
  } finally {
    session.endSession();
  }
};

/**
 * Annuler une réservation
 * @param {string} reservationId
 * @param {string} userId - ID de l'utilisateur qui annule
 * @param {string} reason - Raison de l'annulation
 * @returns {Promise<Reservation>}
 */
const cancelReservation = async (reservationId, userId, reason = '') => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const reservation = await Reservation.findById(reservationId)
      .populate({
        path: 'residence',
        populate: { path: 'cancellationPolicy' }
      });

    if (!reservation) {
      throw new ApiError('Réservation non trouvée', 404);
    }

    // Vérifier si l'annulation est possible
    const canCancel = await reservation.canBeCancelled();
    if (!canCancel) {
      throw new ApiError('Cette réservation ne peut plus être annulée', 400);
    }

    // Vérifier les permissions
    if (
      reservation.client.toString() !== userId &&
      reservation.residence.owner.toString() !== userId
    ) {
      throw new ApiError('Non autorisé', 403);
    }

    // Calculer le remboursement
    const now = new Date();
    const hoursBeforeCheckIn = (reservation.checkIn - now) / (1000 * 60 * 60);
    const refundAmount = await reservation.residence.cancellationPolicy.calculateRefund(
      reservation.totalPrice,
      hoursBeforeCheckIn
    );

    // Mettre à jour le statut et les détails d'annulation
    reservation.status = 'cancelled';
    reservation.cancellationDetails = {
      cancelledAt: now,
      cancelledBy: userId,
      reason,
      refundAmount,
      refundStatus: refundAmount > 0 ? 'pending' : 'completed'
    };

    await reservation.save({ session });

    // Libérer la disponibilité
    await Availability.updateAvailabilityForReservation(
      reservation.residence._id,
      reservation._id,
      reservation.checkIn,
      reservation.checkOut,
      'available',
      session
    );

    await session.commitTransaction();

    // Envoyer les emails de notification
    const [user, partner] = await Promise.all([
      User.findById(reservation.client),
      User.findById(reservation.residence.owner)
    ]);

    await Promise.all([
      emailService.sendBookingCancellation(user.email, reservation),
      emailService.sendPartnerNotification(partner, 'booking_cancelled', {
        checkIn: reservation.checkIn,
        checkOut: reservation.checkOut
      })
    ]);

    return reservation;
  } catch (error) {
    await session.abortTransaction();
    throw error;
  } finally {
    session.endSession();
  }
};

/**
 * Modifier une réservation
 * @param {string} reservationId
 * @param {Object} updateBody
 * @param {string} userId - ID de l'utilisateur qui modifie
 * @returns {Promise<Reservation>}
 */
const modifyReservation = async (reservationId, updateBody, userId) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const reservation = await Reservation.findById(reservationId)
      .populate({
        path: 'residence',
        populate: { path: 'cancellationPolicy' }
      });

    if (!reservation) {
      throw new ApiError('Réservation non trouvée', 404);
    }

    // Vérifier si la modification est possible
    const canModify = await reservation.canBeModified();
    if (!canModify) {
      throw new ApiError('Cette réservation ne peut plus être modifiée', 400);
    }

    // Vérifier les permissions
    if (reservation.client.toString() !== userId) {
      throw new ApiError('Non autorisé', 403);
    }

    // Vérifier la disponibilité pour les nouvelles dates
    if (updateBody.checkIn || updateBody.checkOut) {
      const isAvailable = await reservation.residence.isAvailableForDates(
        updateBody.checkIn || reservation.checkIn,
        updateBody.checkOut || reservation.checkOut,
        reservation._id // Exclure la réservation actuelle
      );

      if (!isAvailable) {
        throw new ApiError('La résidence n\'est pas disponible pour ces dates', 400);
      }
    }

    // Calculer le nouveau prix total si les dates changent
    let newTotalPrice = reservation.totalPrice;
    if (updateBody.checkIn || updateBody.checkOut) {
      newTotalPrice = await reservation.residence.calculateTotalPrice(
        updateBody.checkIn || reservation.checkIn,
        updateBody.checkOut || reservation.checkOut
      );
    }

    // Calculer les frais de modification
    const modificationFee = reservation.residence.cancellationPolicy
      .calculateModificationFee(newTotalPrice, reservation.totalPrice);

    // Créer l'entrée de modification
    const modification = {
      modifiedAt: new Date(),
      modifiedBy: userId,
      changes: new Map(),
      fee: modificationFee,
      status: 'pending'
    };

    // Enregistrer les changements
    Object.keys(updateBody).forEach(key => {
      if (updateBody[key] !== reservation[key]) {
        modification.changes.set(key, {
          from: reservation[key],
          to: updateBody[key]
        });
      }
    });

    // Mettre à jour la réservation
    reservation.modifications = [...(reservation.modifications || []), modification];
    Object.assign(reservation, updateBody);
    reservation.totalPrice = newTotalPrice + modificationFee;

    await reservation.save({ session });

    // Mettre à jour la disponibilité si les dates ont changé
    if (updateBody.checkIn || updateBody.checkOut) {
      await Availability.updateAvailabilityForReservation(
        reservation.residence._id,
        reservation._id,
        updateBody.checkIn || reservation.checkIn,
        updateBody.checkOut || reservation.checkOut,
        'reserved',
        session
      );
    }

    await session.commitTransaction();

    // Envoyer les notifications par email
    const [user, partner] = await Promise.all([
      User.findById(reservation.client),
      User.findById(reservation.residence.owner)
    ]);

    await Promise.all([
      emailService.sendEmail({
        email: user.email,
        subject: 'Modification de votre réservation',
        html: `
          <h1>Votre réservation a été modifiée</h1>
          <p>Les modifications ont été enregistrées avec succès.</p>
          <h2>Détails:</h2>
          <ul>
            <li>Nouveau prix total: ${reservation.totalPrice} €</li>
            <li>Frais de modification: ${modificationFee} €</li>
          </ul>
        `
      }),
      emailService.sendPartnerNotification(partner, 'booking_modified', {
        checkIn: reservation.checkIn,
        checkOut: reservation.checkOut,
        modifications: modification.changes
      })
    ]);

    return reservation;
  } catch (error) {
    await session.abortTransaction();
    throw error;
  } finally {
    session.endSession();
  }
};

module.exports = {
  createReservation,
  cancelReservation,
  modifyReservation
};
