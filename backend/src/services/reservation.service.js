const mongoose = require('mongoose');
const ApiError = require('../utils/apiError');
const Reservation = require('../models/reservation.model');
const Residence = require('../models/residence.model');
const Availability = require('../models/availability.model');
const User = require('../models/user.model');
const CancellationPolicy = require('../models/cancellationPolicy.model');
const emailService = require('./email.service');
const availabilityService = require('./availability.service');

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
      throw new apiError('Résidence non trouvée', 404);
    }

    // Si la résidence n'a pas de politique d'annulation, utiliser la politique par défaut existante
    let cancellationPolicyId;
    if (!residence.cancellationPolicy) {
      // Récupérer la vraie politique par défaut depuis la base
      const defaultPolicy = await CancellationPolicy.findOne({ isDefault: true });
      
      if (!defaultPolicy) {
        throw new apiError('Aucune politique d\'annulation par défaut trouvée. Veuillez configurer les politiques d\'annulation.', 500);
      }
      
      cancellationPolicyId = defaultPolicy._id;
      console.log('INFO: Utilisation de la politique d\'annulation par défaut existante:', defaultPolicy.name, 'pour la résidence', residence._id);
    } else {
      cancellationPolicyId = residence.cancellationPolicy._id;
    }

    // Vérifier la disponibilité
    const isAvailable = await residence.isAvailableForDates(
      reservationBody.checkIn,
      reservationBody.checkOut
    );

    if (!isAvailable) {
      throw new apiError('La résidence n\'est pas disponible pour ces dates', 400);
    }

    // Calculer le prix total
    const totalPrice = await residence.calculateTotalPrice(
      reservationBody.checkIn,
      reservationBody.checkOut
    );

    // Vérifier si la résidence a un partenaire associé et gérer ce cas de façon robuste
    let partnerId = null;
    
    if (!residence.partner) {
      console.error(`ERREUR: La résidence ${residence._id} n'a pas de partenaire défini`);
      
      // Rechercher le propriétaire de la résidence ou un admin comme partenaire de secours
      try {
        // Si nous sommes en environnement de dev/test, permettre un fallback
        if (process.env.NODE_ENV !== 'production') {
          console.warn('ATTENTION: Tentative de récupération d\'un partenaire de secours (NON RECOMMANDÉ en production)');
          
          // Chercher un utilisateur avec le rôle 'partner' pour l'associer
          const fallbackPartner = await User.findOne({ role: 'partner' }).select('_id');
          
          if (fallbackPartner) {
            partnerId = fallbackPartner._id;
            console.log(`Partenaire de secours trouvé: ${partnerId}`);
          } else {
            // En dernier recours, utiliser l'ID de l'utilisateur (créateur de la réservation)
            partnerId = reservationBody.user;
            console.log(`Aucun partenaire trouvé, utilisation de l'utilisateur comme fallback: ${partnerId}`);
          }
        } else {
          // En production, rejeter la création si aucun partenaire n'est défini
          throw new ApiError('Cette résidence n\'a pas de partenaire associé. Réservation impossible.', 400);
        }
      } catch (error) {
        if (error instanceof ApiError) throw error;
        console.error('Erreur lors de la recherche d\'un partenaire de secours:', error);
        // En cas d'erreur dans la recherche, utiliser l'ID utilisateur en dernier recours
        partnerId = reservationBody.user;
      }
    } else {
      partnerId = residence.partner;
    }
    
    console.log(`Création de réservation avec partenaire: ${partnerId}`);
    
    // Créer la réservation avec tous les champs requis et un partenaire valide
    const reservation = await Reservation.create([{
      ...reservationBody,
      // Utiliser le partenaire déterminé par la logique ci-dessus
      partner: partnerId,
      user: reservationBody.user || reservationBody.client, // Assurer la compatibilité entre user/client
      totalPrice,
      cancellationPolicy: cancellationPolicyId,
      status: 'pending'
    }], { session });
    
    // Journaliser les IDs pour faciliter le débogage
    console.log('Réservation créée:', {
      reservationId: reservation[0]._id,
      userId: reservation[0].user,
      partnerId: reservation[0].partner,
      residenceId: residence._id
    });

    // Mettre à jour la disponibilité
    await availabilityService.updateAvailabilityForReservation(
      residence._id,
      reservationBody.checkIn,
      reservationBody.checkOut,
      reservation[0]._id,
      'reserved'
    );

    // Valider la transaction
    await session.commitTransaction();
    
    // Fermer la session avant de poursuivre avec les opérations non transactionnelles
    session.endSession();

    // Envoyer les emails de confirmation (hors transaction)
    // Récupérer le client à partir de user ou client selon la propriété disponible
    const clientId = reservation[0].client || reservation[0].user;
    console.log(`DEBUG: ID du client pour la réservation: ${clientId}`);
    
    try {
      // Rechercher l'utilisateur et le partenaire séparément pour gérer les cas null
      const user = clientId ? await User.findById(clientId) : null;
      const partner = residence.owner ? await User.findById(residence.owner) : null;
      
      console.log(`DEBUG: Utilisateur trouvé: ${user ? 'Oui' : 'Non'}, Partenaire trouvé: ${partner ? 'Oui' : 'Non'}`);
      
      // Envoyer les emails seulement si les destinataires existent
      const emailPromises = [];
      
      if (user && user.email) {
        console.log(`DEBUG: Envoi d'email de confirmation à l'utilisateur: ${user.email}`);
        emailPromises.push(emailService.sendBookingConfirmation(user.email, reservation[0]));
      } else {
        console.log('ATTENTION: Impossible d\'envoyer l\'email de confirmation - utilisateur ou email manquant');
      }
      
      if (partner) {
        console.log(`DEBUG: Envoi de notification au partenaire: ${partner.email || 'email inconnu'}`);
        emailPromises.push(emailService.sendPartnerNotification(partner, 'new_booking', {
          checkIn: reservation[0].checkIn,
          checkOut: reservation[0].checkOut,
          guests: reservation[0].numberOfGuests
        }));
      } else {
        console.log('ATTENTION: Impossible d\'envoyer l\'email au partenaire - partenaire manquant');
      }
      
      if (emailPromises.length > 0) {
        await Promise.all(emailPromises);
      }
    } catch (emailError) {
      console.error('Erreur lors de l\'envoi des emails de confirmation:', emailError);
      // Ne pas faire échouer la réservation si l'envoi d'email échoue
    }

    return reservation[0];
  } catch (error) {
    // Seulement abandonner la transaction si elle est encore active
    if (session.inTransaction()) {
      await session.abortTransaction();
    }
    
    // S'assurer que la session est fermée dans tous les cas
    if (session) {
      session.endSession();
    }
    
    throw error;
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
      throw new apiError('Réservation non trouvée', 404);
    }

    // Vérifier si l'annulation est possible
    const canCancel = await reservation.canBeCancelled();
    if (!canCancel) {
      throw new apiError('Cette réservation ne peut plus être annulée', 400);
    }

    // Vérifier les permissions
    if (
      reservation.client.toString() !== userId &&
      reservation.residence.owner.toString() !== userId
    ) {
      throw new apiError('Non autorisé', 403);
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
    await availabilityService.updateAvailabilityForReservation(
      reservation.residence._id,
      reservation.checkIn,
      reservation.checkOut,
      reservation._id,
      'available'
    );

    // Valider la transaction
    await session.commitTransaction();
    
    // Fermer la session avant de poursuivre avec les opérations non transactionnelles
    session.endSession();

    // Envoyer les emails de notification (hors transaction)
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
    // Seulement abandonner la transaction si elle est encore active
    if (session.inTransaction()) {
      await session.abortTransaction();
    }
    
    // S'assurer que la session est fermée dans tous les cas
    if (session) {
      session.endSession();
    }
    
    throw error;
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
      throw new apiError('Réservation non trouvée', 404);
    }

    // Vérifier si la modification est possible
    const canModify = await reservation.canBeModified();
    if (!canModify) {
      throw new apiError('Cette réservation ne peut plus être modifiée', 400);
    }

    // Vérifier les permissions
    if (reservation.client.toString() !== userId) {
      throw new apiError('Non autorisé', 403);
    }

    // Vérifier la disponibilité pour les nouvelles dates
    if (updateBody.checkIn || updateBody.checkOut) {
      const isAvailable = await reservation.residence.isAvailableForDates(
        updateBody.checkIn || reservation.checkIn,
        updateBody.checkOut || reservation.checkOut,
        reservation._id // Exclure la réservation actuelle
      );

      if (!isAvailable) {
        throw new apiError('La résidence n\'est pas disponible pour ces dates', 400);
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
      await availabilityService.updateAvailabilityForReservation(
        reservation.residence._id,
        updateBody.checkIn || reservation.checkIn,
        updateBody.checkOut || reservation.checkOut,
        reservation._id,
        'reserved'
      );
    }

    // Valider la transaction
    await session.commitTransaction();
    
    // Fermer la session avant de poursuivre avec les opérations non transactionnelles
    session.endSession();

    // Envoyer les notifications par email (hors transaction)
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
    // Seulement abandonner la transaction si elle est encore active
    if (session.inTransaction()) {
      await session.abortTransaction();
    }
    
    // S'assurer que la session est fermée dans tous les cas
    if (session) {
      session.endSession();
    }
    
    throw error;
  }
};

module.exports = {
  createReservation,
  cancelReservation,
  modifyReservation
};
