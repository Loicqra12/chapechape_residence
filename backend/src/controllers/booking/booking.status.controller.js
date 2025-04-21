/**
 * Contrôleur pour les opérations de changement de statut des réservations
 * Utilise les classes d'erreurs de domaine et le service de journalisation
 */

const asyncHandler = require('../../middlewares/async.middleware');
const Booking = require('../../models/booking.model');
const User = require('../../models/user.model');
const notificationService = require('../../services/notification.service');
const emailService = require('../../services/email.service');
const { BookingErrors } = require('../../utils/domainErrors');
const errorService = require('../../services/error.service');
const errorCodes = require('../../utils/errorCodes');

/**
 * @desc    Confirmer une réservation
 * @route   POST /api/bookings/:id/confirm
 * @access  Privé - Partner ou Admin
 */
exports.confirmBooking = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const isAdmin = req.user.role === 'admin';
    const isPartner = req.user.role === 'partner';

    try {
        // Vérifier si la réservation existe
        const booking = await Booking.findById(id);
        if (!booking) {
            throw BookingErrors.notFound(id);
        }

        // Vérifier l'autorisation
        if (!isAdmin && (!isPartner || booking.partner.toString() !== req.user._id.toString())) {
            throw BookingErrors.unauthorizedAction(
                req.user._id,
                id,
                'confirmer'
            );
        }

        // Vérifier si la réservation peut être confirmée
        if (booking.status === 'confirmed') {
            throw BookingErrors.alreadyInStatus(id, 'confirmed');
        }

        if (booking.status !== 'pending') {
            throw BookingErrors.invalidStatusChange(
                id,
                booking.status,
                'confirmed'
            );
        }

        // Mettre à jour le statut
        booking.status = 'confirmed';
        booking.confirmedAt = new Date();
        booking.confirmedBy = req.user._id;
        await booking.save();

        // Récupérer les informations du client pour les notifications
        const client = await User.findById(booking.client);

        // Envoyer les notifications
        await notificationService.sendNotification({
            user: booking.client,
            title: 'Réservation confirmée',
            message: `Votre réservation a été confirmée par le partenaire`,
            type: 'booking_confirmed',
            data: { bookingId: booking._id }
        });

        // Envoyer un email
        await emailService.sendBookingConfirmation(
            client.email,
            {
                firstName: client.firstName,
                bookingRef: booking._id.toString().slice(-6).toUpperCase(),
                bookingDate: booking.visitDate
            }
        );

        // Renvoyer la réponse
        return res.status(200).json({
            success: true,
            message: 'Réservation confirmée avec succès',
            data: booking
        });
    } catch (error) {
        // Journalisation de l'erreur
        errorService.logBookingError(error, 
            { _id: id }, 
            req.user
        );
        
        // Propager l'erreur au middleware de gestion d'erreurs
        throw error;
    }
});

/**
 * @desc    Annuler une réservation
 * @route   POST /api/bookings/:id/cancel
 * @access  Privé - Propriétaire de la réservation, Partner ou Admin
 */
exports.cancelBooking = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { reason } = req.body;
    const isAdmin = req.user.role === 'admin';
    const isPartner = req.user.role === 'partner';

    try {
        // Vérifier si la réservation existe
        const booking = await Booking.findById(id);
        if (!booking) {
            throw BookingErrors.notFound(id);
        }

        // Vérifier l'autorisation
        const isClient = booking.client.toString() === req.user._id.toString();
        const isBookingPartner = isPartner && booking.partner.toString() === req.user._id.toString();
        
        if (!isAdmin && !isClient && !isBookingPartner) {
            throw BookingErrors.unauthorizedAction(
                req.user._id,
                id,
                'annuler'
            );
        }

        // Vérifier si la réservation peut être annulée
        if (booking.status === 'cancelled') {
            throw BookingErrors.alreadyInStatus(id, 'cancelled');
        }

        if (booking.status === 'completed') {
            throw BookingErrors.invalidStatusChange(
                id,
                booking.status,
                'cancelled'
            );
        }

        // Mettre à jour le statut
        booking.status = 'cancelled';
        booking.cancellationReason = reason || 'Annulation à la demande';
        booking.cancelledAt = new Date();
        booking.cancelledBy = req.user._id;
        await booking.save();

        // Récupérer les informations du client pour les notifications
        const client = await User.findById(booking.client);

        // Envoyer des notifications appropriées
        if (isClient) {
            // Notifier le partenaire
            await notificationService.sendNotification({
                user: booking.partner,
                title: 'Réservation annulée',
                message: `Réservation annulée par le client`,
                type: 'booking_cancelled',
                data: { bookingId: booking._id, reason }
            });
        } else {
            // Notifier le client
            await notificationService.sendNotification({
                user: booking.client,
                title: 'Réservation annulée',
                message: isPartner ? 
                    `Votre réservation a été annulée par le partenaire` : 
                    `Votre réservation a été annulée par l'administration`,
                type: 'booking_cancelled',
                data: { bookingId: booking._id, reason }
            });
        }

        // Envoyer un email de confirmation d'annulation
        await emailService.sendBookingCancellation(
            client.email,
            {
                firstName: client.firstName,
                bookingRef: booking._id.toString().slice(-6).toUpperCase(),
                reason: reason || 'Annulation à la demande'
            }
        );

        // Renvoyer la réponse
        return res.status(200).json({
            success: true,
            message: 'Réservation annulée avec succès',
            data: booking
        });
    } catch (error) {
        // Journalisation de l'erreur
        errorService.logBookingError(error, 
            { _id: id }, 
            req.user
        );
        
        // Propager l'erreur au middleware de gestion d'erreurs
        throw error;
    }
});

/**
 * @desc    Marquer une réservation comme terminée
 * @route   POST /api/bookings/:id/complete
 * @access  Privé - Partner ou Admin
 */
exports.completeBooking = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { notes } = req.body;
    const isAdmin = req.user.role === 'admin';
    const isPartner = req.user.role === 'partner';

    try {
        // Vérifier si la réservation existe
        const booking = await Booking.findById(id);
        if (!booking) {
            throw BookingErrors.notFound(id);
        }

        // Vérifier l'autorisation
        if (!isAdmin && (!isPartner || booking.partner.toString() !== req.user._id.toString())) {
            throw BookingErrors.unauthorizedAction(
                req.user._id,
                id,
                'marquer comme terminée'
            );
        }

        // Vérifier si la réservation peut être marquée comme terminée
        if (booking.status === 'completed') {
            throw BookingErrors.alreadyInStatus(id, 'completed');
        }

        if (booking.status !== 'confirmed') {
            throw BookingErrors.invalidStatusChange(
                id,
                booking.status,
                'completed'
            );
        }

        // Mettre à jour le statut
        booking.status = 'completed';
        booking.completedAt = new Date();
        booking.completedBy = req.user._id;
        booking.notes = notes || booking.notes;
        await booking.save();

        // Envoyer des notifications
        await notificationService.sendNotification({
            user: booking.client,
            title: 'Visite terminée',
            message: `Votre visite a été marquée comme terminée`,
            type: 'booking_completed',
            data: { bookingId: booking._id }
        });

        // Récupérer les informations du client
        const client = await User.findById(booking.client);

        // Envoyer un email demandant une évaluation
        await emailService.sendReviewRequest(
            client.email,
            {
                firstName: client.firstName,
                bookingRef: booking._id.toString().slice(-6).toUpperCase(),
                reviewLink: `${process.env.FRONTEND_URL}/bookings/${booking._id}/review`
            }
        );

        // Renvoyer la réponse
        return res.status(200).json({
            success: true,
            message: 'Réservation marquée comme terminée avec succès',
            data: booking
        });
    } catch (error) {
        // Journalisation de l'erreur
        errorService.logBookingError(error, 
            { _id: id }, 
            req.user
        );
        
        // Propager l'erreur au middleware de gestion d'erreurs
        throw error;
    }
});

module.exports = exports;
