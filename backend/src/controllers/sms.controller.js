const asyncHandler = require('../middlewares/async.middleware');
const twilioService = require('../services/twilio.service');
const Booking = require('../models/booking.model');
const notificationService = require('../services/notification.service');
const { NOTIFICATION_TYPES } = require('../utils/constants');
const apiError = require('../utils/apiError');

// @desc    Envoyer un SMS simple
// @route   POST /api/sms/send
// @access  Private (Admin et Partenaire uniquement)
exports.sendSMS = asyncHandler(async (req, res) => {
    const { to, body } = req.body;

    if (!to || !body) {
        throw new apiError('Numéro de téléphone et message requis', 400);
    }

    const message = await twilioService.sendSMS(to, body);

    res.status(200).json({
        success: true,
        data: {
            sid: message.sid,
            status: message.status
        }
    });
});

// @desc    Envoyer une notification SMS pour une réservation
// @route   POST /api/sms/booking
// @access  Private (Admin et Partenaire uniquement)
exports.sendBookingNotification = asyncHandler(async (req, res) => {
    const { bookingId, notificationType } = req.body;
    
    if (!bookingId || !notificationType) {
        throw new apiError('ID de réservation et type de notification requis', 400);
    }
    
    const booking = await Booking.findById(bookingId)
        .populate('client', 'phoneNumber firstName lastName')
        .populate('residence', 'title address');
        
    if (!booking) {
        throw new apiError('Réservation non trouvée', 404);
    }
    
    // Vérifier l'autorisation (seul le partenaire associé ou un admin peut envoyer)
    if (booking.partner.toString() !== req.user.id && req.user.role !== 'admin') {
        throw new apiError('Non autorisé à envoyer des notifications pour cette réservation', 403);
    }
    
    const message = await twilioService.sendBookingNotification(booking, notificationType);
    
    // Créer également une notification dans le système
    if (booking.client && booking.client._id) {
        await notificationService.createNotification({
            recipient: booking.client._id,
            type: NOTIFICATION_TYPES.BOOKING_UPDATE,
            title: `Mise à jour de votre réservation`,
            message: `Votre réservation pour "${booking.residence.title}" a été mise à jour.`,
            data: {
                bookingId: booking._id,
                updateType: notificationType
            }
        });
    }
    
    res.status(200).json({
        success: true,
        data: {
            sid: message?.sid,
            status: message?.status || 'not_sent',
            booking: bookingId,
            type: notificationType,
            smsSuccess: !!message
        }
    });
});

// @desc    Envoyer des instructions de paiement par SMS pour une méthode africaine
// @route   POST /api/sms/payment-instructions
// @access  Private (Admin et Partenaire uniquement)
exports.sendPaymentInstructions = asyncHandler(async (req, res) => {
    const { bookingId, paymentMethod } = req.body;
    
    if (!bookingId || !paymentMethod) {
        throw new apiError('ID de réservation et méthode de paiement requis', 400);
    }
    
    // Vérifier que la méthode de paiement est valide
    const validPaymentMethods = ['wave', 'orange_money', 'mtn_money', 'moov_money', 'cash', 'other'];
    if (!validPaymentMethods.includes(paymentMethod)) {
        throw new apiError('Méthode de paiement non prise en charge', 400);
    }
    
    const booking = await Booking.findById(bookingId)
        .populate('client', 'phoneNumber firstName lastName')
        .populate('residence', 'title address');
        
    if (!booking) {
        throw new apiError('Réservation non trouvée', 404);
    }
    
    // Vérifier l'autorisation (seul le partenaire associé ou un admin peut envoyer)
    if (booking.partner.toString() !== req.user.id && req.user.role !== 'admin') {
        throw new apiError('Non autorisé à envoyer des instructions de paiement pour cette réservation', 403);
    }
    
    const message = await twilioService.sendPaymentInstructions(booking, paymentMethod);
    
    // Créer également une notification dans le système
    if (booking.client && booking.client._id) {
        await notificationService.createNotification({
            recipient: booking.client._id,
            type: NOTIFICATION_TYPES.PAYMENT_REQUIRED,
            title: `Instructions de paiement`,
            message: `Veuillez finaliser le paiement pour votre réservation à "${booking.residence.title}".`,
            data: {
                bookingId: booking._id,
                paymentMethod
            }
        });
    }
    
    res.status(200).json({
        success: true,
        data: {
            sid: message?.sid,
            status: message?.status || 'not_sent',
            booking: bookingId,
            paymentMethod,
            smsSuccess: !!message
        }
    });
});
