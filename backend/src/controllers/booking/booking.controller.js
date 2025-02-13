const Booking = require('../../models/booking.model');
const asyncHandler = require('../../middlewares/async.middleware');
const ApiError = require('../../utils/apiError');
const notificationService = require('../../services/notification.service');
const paymentService = require('../../services/payment.service');
const emailService = require('../../services/email.service');
const Residence = require('../../models/residence.model');
const Payment = require('../../models/payment.model');
const { validateBookingDates } = require('../../utils/validation');

// Créer une nouvelle réservation
exports.createBooking = asyncHandler(async (req, res) => {
    const { residenceId, checkIn, checkOut, guests } = req.body;

    // Valider les dates
    if (!validateBookingDates(checkIn, checkOut)) {
        throw new ApiError('Dates de réservation invalides', 400);
    }

    // Vérifier la disponibilité
    const isAvailable = await Booking.checkAvailability(residenceId, checkIn, checkOut);
    if (!isAvailable) {
        throw new ApiError('La résidence n\'est pas disponible pour ces dates', 400);
    }

    // Calculer le prix total
    const residence = await Residence.findById(residenceId);
    const numberOfDays = Math.ceil((new Date(checkOut) - new Date(checkIn)) / (1000 * 60 * 60 * 24));
    const totalAmount = residence.pricePerNight * numberOfDays;

    // Créer la réservation
    const booking = await Booking.create({
        user: req.user._id,
        residence: residenceId,
        checkIn,
        checkOut,
        guests,
        totalAmount,
        status: 'pending'
    });

    // Envoyer les notifications
    await Promise.all([
        notificationService.sendBookingNotification(booking),
        emailService.sendBookingConfirmation(req.user.email, booking)
    ]);

    res.status(201).json({
        success: true,
        data: booking
    });
});

// Obtenir les réservations de l'utilisateur
exports.getUserBookings = asyncHandler(async (req, res) => {
    const bookings = await Booking.find({ user: req.user._id })
        .populate('residence', 'name address images')
        .sort('-createdAt');

    res.status(200).json({
        success: true,
        data: bookings
    });
});

// Obtenir une réservation spécifique
exports.getBooking = asyncHandler(async (req, res) => {
    const booking = await Booking.findById(req.params.id)
        .populate('residence', 'name address images')
        .populate('user', 'firstName lastName email');

    if (!booking) {
        throw new ApiError('Réservation non trouvée', 404);
    }

    // Vérifier que l'utilisateur a le droit d'accéder à cette réservation
    if (booking.user.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
        throw new ApiError('Non autorisé', 403);
    }

    res.status(200).json({
        success: true,
        data: booking
    });
});

// Annuler une réservation
exports.cancelBooking = asyncHandler(async (req, res) => {
    const booking = await Booking.findById(req.params.id);

    if (!booking) {
        throw new ApiError('Réservation non trouvée', 404);
    }

    // Vérifier que l'utilisateur a le droit d'annuler cette réservation
    if (booking.user.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
        throw new ApiError('Non autorisé', 403);
    }

    // Vérifier si l'annulation est possible selon les règles
    const checkIn = new Date(booking.checkIn);
    const now = new Date();
    const hoursUntilCheckIn = (checkIn - now) / (1000 * 60 * 60);

    if (hoursUntilCheckIn < 24) {
        throw new ApiError('Impossible d\'annuler moins de 24h avant l\'arrivée', 400);
    }

    booking.status = 'cancelled';
    await booking.save();

    // Traiter le remboursement si nécessaire
    const payment = await Payment.findOne({ booking: booking._id });
    if (payment) {
        payment.status = 'refunded';
        await payment.save();
    }

    // Envoyer les notifications
    await Promise.all([
        notificationService.sendCancellationNotification(booking),
        emailService.sendCancellationConfirmation(req.user.email, booking)
    ]);

    res.status(200).json({
        success: true,
        data: booking
    });
});

// Fonction utilitaire pour vérifier la disponibilité
async function checkAvailability(residenceId, checkIn, checkOut) {
    const overlappingBookings = await Booking.find({
        residence: residenceId,
        status: { $ne: 'cancelled' },
        $or: [
            {
                checkIn: { $lte: checkIn },
                checkOut: { $gte: checkIn }
            },
            {
                checkIn: { $lte: checkOut },
                checkOut: { $gte: checkOut }
            }
        ]
    });

    return overlappingBookings.length === 0;
}
