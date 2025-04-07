const Booking = require('../models/booking.model');
const Residence = require('../models/residence.model');
const Payment = require('../models/payment.model');
const Availability = require('../models/availability.model');
const CancellationPolicy = require('../models/cancellationPolicy.model');
const { ApiError } = require('../utils/ApiError');
const availabilityService = require('./availability.service');
const paymentService = require('./payment.service');
const notificationService = require('./notification.service');
const emailService = require('./email.service');
const moment = require('moment');

class BookingService {
  /**
   * Créer une nouvelle réservation
   */
  async createBooking(bookingData, userId) {
    try {
      // Vérifier si la résidence existe
      const residence = await Residence.findById(bookingData.residenceId);
      if (!residence) {
        throw new ApiError('Résidence non trouvée', 404);
      }

      // Vérifier la disponibilité pour les dates demandées
      const availability = await availabilityService.checkAvailability(
        bookingData.residenceId,
        bookingData.checkIn,
        bookingData.checkOut
      );

      if (!availability.available) {
        throw new ApiError('La résidence n\'est pas disponible pour ces dates', 400);
      }

      // Calculer le prix total
      const priceDetails = availability.priceDetails || {
        finalTotal: residence.price * moment(bookingData.checkOut).diff(moment(bookingData.checkIn), 'days')
      };

      // Créer la réservation
      const booking = await Booking.create({
        residence: bookingData.residenceId,
        user: userId,
        checkIn: bookingData.checkIn,
        checkOut: bookingData.checkOut,
        guests: bookingData.guests,
        totalPrice: priceDetails.finalTotal,
        specialRequests: bookingData.specialRequests,
        status: 'pending'
      });

      // Mettre à jour les disponibilités
      await this._updateAvailabilityForBooking(booking, 'booked');

      // Envoyer les notifications
      await notificationService.sendBookingNotification(booking);
      await emailService.sendBookingConfirmation(userId, booking);

      return booking;
    } catch (error) {
      if (error instanceof ApiError) throw error;
      throw new ApiError('Erreur lors de la création de la réservation', 500);
    }
  }

  /**
   * Obtenir une réservation par son ID
   */
  async getBookingById(bookingId, userId, isAdmin = false) {
    try {
      const booking = await Booking.findById(bookingId)
        .populate('residence', 'name address images price type')
        .populate('user', 'firstName lastName email phoneNumber');

      if (!booking) {
        throw new ApiError('Réservation non trouvée', 404);
      }

      // Vérifier les permissions d'accès
      if (!isAdmin && booking.user._id.toString() !== userId.toString()) {
        throw new ApiError('Non autorisé à accéder à cette réservation', 403);
      }

      return booking;
    } catch (error) {
      if (error instanceof ApiError) throw error;
      throw new ApiError('Erreur lors de la récupération de la réservation', 500);
    }
  }

  /**
   * Obtenir les réservations d'un utilisateur
   */
  async getUserBookings(userId, filter = {}) {
    try {
      const query = { user: userId, ...filter };
      
      const bookings = await Booking.find(query)
        .populate('residence', 'name address images price type')
        .sort({ createdAt: -1 });

      return bookings;
    } catch (error) {
      throw new ApiError('Erreur lors de la récupération des réservations', 500);
    }
  }

  /**
   * Obtenir les réservations pour une résidence
   */
  async getResidenceBookings(residenceId, filter = {}, isAdmin = false) {
    try {
      // Vérifier si la résidence existe
      const residence = await Residence.findById(residenceId);
      if (!residence) {
        throw new ApiError('Résidence non trouvée', 404);
      }

      const query = { residence: residenceId, ...filter };
      
      const bookings = await Booking.find(query)
        .populate('user', 'firstName lastName email phoneNumber')
        .sort({ checkIn: 1 });

      return bookings;
    } catch (error) {
      if (error instanceof ApiError) throw error;
      throw new ApiError('Erreur lors de la récupération des réservations', 500);
    }
  }

  /**
   * Annuler une réservation
   */
  async cancelBooking(bookingId, userId, reason, isAdmin = false) {
    try {
      const booking = await this.getBookingById(bookingId, userId, isAdmin);

      // Vérifier si la réservation peut être annulée
      if (booking.status === 'cancelled') {
        throw new ApiError('Cette réservation est déjà annulée', 400);
      }

      if (booking.status === 'completed') {
        throw new ApiError('Impossible d\'annuler une réservation déjà complétée', 400);
      }

      // Récupérer la politique d'annulation associée à cette résidence
      const residence = await Residence.findById(booking.residence._id);
      const cancellationPolicyId = residence.cancellationPolicy || null;
      
      let cancellationPolicy;
      
      if (cancellationPolicyId) {
        cancellationPolicy = await CancellationPolicy.findById(cancellationPolicyId);
      } else {
        // Utiliser la politique par défaut basée sur le type de résidence
        cancellationPolicy = await CancellationPolicy.findOne({
          residenceTypes: residence.type,
          isDefault: true
        });
      }
      
      if (!cancellationPolicy) {
        // Utiliser la politique "Flexible" par défaut
        cancellationPolicy = await CancellationPolicy.findOne({ name: 'Flexible' });
      }
      
      // Calculer le temps restant avant le check-in
      const now = new Date();
      const checkIn = new Date(booking.checkIn);
      const hoursUntilCheckIn = Math.max(0, (checkIn - now) / (1000 * 60 * 60));
      
      // Calculer le montant à rembourser
      const refundAmount = cancellationPolicy.calculateRefund(booking.totalPrice, hoursUntilCheckIn);
      
      // Mettre à jour la réservation
      booking.status = 'cancelled';
      booking.cancellationReason = reason;
      booking.cancelledBy = userId;
      booking.cancelledAt = new Date();
      booking.refundAmount = refundAmount;
      
      await booking.save();
      
      // Mettre à jour les disponibilités
      await this._updateAvailabilityForBooking(booking, 'available');
      
      // Traiter le remboursement si un paiement a été fait
      const payment = await Payment.findOne({ booking: booking._id });
      if (payment && payment.status === 'completed') {
        await paymentService.processRefund(payment._id, refundAmount, 'Annulation de réservation');
      }
      
      // Envoyer les notifications
      await notificationService.sendCancellationNotification(booking);
      await emailService.sendCancellationConfirmation(booking.user.email, booking);
      
      return {
        booking,
        refundAmount,
        refundPercentage: (refundAmount / booking.totalPrice) * 100
      };
    } catch (error) {
      if (error instanceof ApiError) throw error;
      throw new ApiError('Erreur lors de l\'annulation de la réservation', 500);
    }
  }

  /**
   * Modifier une réservation
   */
  async updateBooking(bookingId, userId, updateData, isAdmin = false) {
    try {
      const booking = await this.getBookingById(bookingId, userId, isAdmin);

      // Vérifier si la réservation peut être modifiée
      if (booking.status === 'cancelled') {
        throw new ApiError('Cette réservation est annulée et ne peut pas être modifiée', 400);
      }

      if (booking.status === 'completed') {
        throw new ApiError('Cette réservation est déjà complétée et ne peut pas être modifiée', 400);
      }

      // Si les dates sont modifiées, vérifier la disponibilité
      let dateChanged = false;
      let oldCheckIn = new Date(booking.checkIn);
      let oldCheckOut = new Date(booking.checkOut);
      
      if (updateData.checkIn || updateData.checkOut) {
        dateChanged = true;
        const newCheckIn = updateData.checkIn ? new Date(updateData.checkIn) : oldCheckIn;
        const newCheckOut = updateData.checkOut ? new Date(updateData.checkOut) : oldCheckOut;
        
        // Vérifier si la modification est possible
        const result = await availabilityService.checkBookingModification(
          bookingId,
          newCheckIn,
          newCheckOut
        );
        
        if (!result.modificationPossible) {
          throw new ApiError('Les nouvelles dates ne sont pas disponibles', 400);
        }
        
        // Vérifier si la modification est autorisée par la politique d'annulation
        const residence = await Residence.findById(booking.residence._id);
        const cancellationPolicyId = residence.cancellationPolicy || null;
        
        let cancellationPolicy;
        
        if (cancellationPolicyId) {
          cancellationPolicy = await CancellationPolicy.findById(cancellationPolicyId);
        } else {
          // Utiliser la politique par défaut basée sur le type de résidence
          cancellationPolicy = await CancellationPolicy.findOne({
            residenceTypes: residence.type,
            isDefault: true
          });
        }
        
        if (!cancellationPolicy) {
          // Utiliser la politique "Flexible" par défaut
          cancellationPolicy = await CancellationPolicy.findOne({ name: 'Flexible' });
        }
        
        // Calculer le temps restant avant le check-in
        const now = new Date();
        const checkIn = new Date(booking.checkIn);
        const hoursUntilCheckIn = Math.max(0, (checkIn - now) / (1000 * 60 * 60));
        
        if (!cancellationPolicy.isModificationAllowed(hoursUntilCheckIn)) {
          throw new ApiError(`Les modifications ne sont pas autorisées moins de ${cancellationPolicy.modificationTimeLimit} heures avant l'arrivée`, 400);
        }
        
        // Mettre à jour les disponibilités
        // D'abord libérer les anciennes dates
        await this._updateAvailabilityForBooking(booking, 'available');
      }
      
      // Mettre à jour les détails de la réservation
      Object.keys(updateData).forEach(key => {
        if (key !== 'residence' && key !== 'user' && key !== 'status' && key !== 'totalPrice') {
          booking[key] = updateData[key];
        }
      });
      
      // Si les dates ont changé, recalculer le prix et mettre à jour les disponibilités
      if (dateChanged) {
        const newCheckIn = updateData.checkIn ? new Date(updateData.checkIn) : oldCheckIn;
        const newCheckOut = updateData.checkOut ? new Date(updateData.checkOut) : oldCheckOut;
        
        const availability = await availabilityService.checkAvailability(
          booking.residence._id,
          newCheckIn,
          newCheckOut
        );
        
        const priceDetails = availability.priceDetails || {
          finalTotal: booking.residence.price * moment(newCheckOut).diff(moment(newCheckIn), 'days')
        };
        
        // Calculer les frais de modification
        const residence = await Residence.findById(booking.residence._id);
        const cancellationPolicyId = residence.cancellationPolicy || null;
        
        let cancellationPolicy;
        
        if (cancellationPolicyId) {
          cancellationPolicy = await CancellationPolicy.findById(cancellationPolicyId);
        } else {
          // Utiliser la politique par défaut
          cancellationPolicy = await CancellationPolicy.findOne({
            residenceTypes: residence.type,
            isDefault: true
          }) || await CancellationPolicy.findOne({ name: 'Flexible' });
        }
        
        const modificationFee = cancellationPolicy.calculateModificationFee(
          priceDetails.finalTotal,
          booking.totalPrice
        );
        
        booking.totalPrice = priceDetails.finalTotal + modificationFee;
        booking.modificationFee = modificationFee;
        booking.modifiedAt = new Date();
        
        // Marquer les nouvelles dates comme réservées
        await this._updateAvailabilityForBooking(booking, 'booked');
      }
      
      await booking.save();
      
      // Si un paiement supplémentaire est nécessaire, créer une transaction
      if (dateChanged && booking.totalPrice > booking.paidAmount) {
        const additionalPayment = booking.totalPrice - (booking.paidAmount || 0);
        // Créer une demande de paiement supplémentaire
        await paymentService.createAdditionalPaymentRequest(booking._id, additionalPayment);
      }
      
      // Envoyer les notifications
      await notificationService.sendBookingUpdateNotification(booking);
      await emailService.sendBookingUpdateConfirmation(booking.user.email, booking);
      
      return booking;
    } catch (error) {
      if (error instanceof ApiError) throw error;
      throw new ApiError('Erreur lors de la mise à jour de la réservation', 500);
    }
  }

  /**
   * Mettre à jour le statut d'une réservation
   */
  async updateBookingStatus(bookingId, status, userId, isAdmin = false) {
    try {
      const booking = await this.getBookingById(bookingId, userId, isAdmin);
      
      // Vérifier les transitions de statut autorisées
      const allowedTransitions = {
        'pending': ['confirmed', 'cancelled'],
        'confirmed': ['completed', 'cancelled'],
        'cancelled': [], // Aucune transition autorisée depuis cancelled
        'completed': [] // Aucune transition autorisée depuis completed
      };
      
      if (!allowedTransitions[booking.status].includes(status)) {
        throw new ApiError(`Transition de statut de ${booking.status} à ${status} non autorisée`, 400);
      }
      
      // Mettre à jour le statut
      booking.status = status;
      
      if (status === 'completed') {
        booking.completedAt = new Date();
      }
      
      await booking.save();
      
      // Envoyer les notifications
      switch (status) {
        case 'confirmed':
          await notificationService.sendBookingConfirmedNotification(booking);
          await emailService.sendBookingStatusUpdate(booking.user.email, booking, 'confirmed');
          break;
        case 'cancelled':
          await this.cancelBooking(bookingId, userId, 'Annulation administrative', isAdmin);
          break;
        case 'completed':
          await notificationService.sendBookingCompletedNotification(booking);
          await emailService.sendBookingStatusUpdate(booking.user.email, booking, 'completed');
          break;
      }
      
      return booking;
    } catch (error) {
      if (error instanceof ApiError) throw error;
      throw new ApiError('Erreur lors de la mise à jour du statut de la réservation', 500);
    }
  }

  /**
   * Ajouter un avis à une réservation
   */
  async addBookingReview(bookingId, userId, rating, comment) {
    try {
      const booking = await this.getBookingById(bookingId, userId);
      
      // Vérifier si la réservation est terminée
      if (booking.status !== 'completed') {
        throw new ApiError('Impossible d\'ajouter un avis à une réservation non complétée', 400);
      }
      
      // Vérifier si un avis existe déjà
      if (booking.review) {
        throw new ApiError('Un avis existe déjà pour cette réservation', 400);
      }
      
      // Ajouter l'avis
      booking.review = {
        rating,
        comment,
        createdAt: new Date()
      };
      
      await booking.save();
      
      // Mettre à jour la note moyenne de la résidence
      const residence = await Residence.findById(booking.residence._id);
      const allBookings = await Booking.find({
        residence: booking.residence._id,
        'review.rating': { $exists: true }
      });
      
      const totalRating = allBookings.reduce((sum, booking) => sum + booking.review.rating, 0);
      const averageRating = totalRating / allBookings.length;
      
      residence.rating = averageRating;
      residence.reviewCount = allBookings.length;
      
      await residence.save();
      
      return booking;
    } catch (error) {
      if (error instanceof ApiError) throw error;
      throw new ApiError('Erreur lors de l\'ajout de l\'avis', 500);
    }
  }

  /**
   * Mettre à jour les disponibilités pour une réservation
   * @private
   */
  async _updateAvailabilityForBooking(booking, status) {
    const checkIn = new Date(booking.checkIn);
    const checkOut = new Date(booking.checkOut);
    
    // Créer des entrées pour chaque jour de la réservation
    const currentDate = moment(checkIn);
    const endDate = moment(checkOut);
    
    const updates = [];
    
    while (currentDate.isBefore(endDate, 'day')) {
      updates.push({
        residenceId: booking.residence._id || booking.residence,
        date: currentDate.toDate(),
        status,
        bookingId: status === 'booked' ? booking._id : null
      });
      
      currentDate.add(1, 'day');
    }
    
    // Mettre à jour les disponibilités
    if (updates.length > 0) {
      await Availability.upsertBulk(updates);
    }
  }
}

module.exports = new BookingService(); 