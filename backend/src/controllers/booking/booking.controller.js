const Booking = require('../../models/booking.model');
const asyncHandler = require('../../middlewares/async.middleware');
const ApiError = require('../../utils/apiError');
const notificationService = require('../../services/notification.service');
const paymentService = require('../../services/payment.service');
const emailService = require('../../services/email.service');
const Residence = require('../../models/residence.model');
const Payment = require('../../models/payment.model');
const { validateBookingDates } = require('../../utils/validation');
const bookingService = require('../../services/booking.service');
const availabilityService = require('../../services/availability.service');
const Review = require('../../models/review.model');

// Obtenir toutes les réservations (admin seulement)
exports.getAllBookings = asyncHandler(async (req, res) => {
    const { page = 1, limit = 10, sort, status, search, startDate, endDate, residence, partner } = req.query;

    // Construire le filtre
    const filter = {};
    
    if (status) {
        filter.status = status;
    }
    
    if (startDate) {
        filter.visitDate = { $gte: new Date(startDate) };
    }
    
    if (endDate) {
        filter.visitDate = { ...filter.visitDate, $lte: new Date(endDate) };
    }
    
    if (residence) {
        filter.residence = residence;
    }
    
    if (partner) {
        filter.partner = partner;
    }

    // Construire le tri
    let sortQuery = { visitDate: -1 }; // Par défaut, trier par date de visite décroissante
    if (sort) {
        const [field, direction] = sort.split(':');
        sortQuery = { [field]: direction === 'desc' ? -1 : 1 };
    }

    // Effectuer la requête avec pagination
    const skip = (page - 1) * limit;
    
    const bookings = await Booking.find(filter)
        .populate({
            path: 'residence',
            select: 'name images location',
            transform: doc => ({
                ...doc.toObject(),
                imageUrl: doc.images?.[0] || '/placeholder.jpg',
                title: doc.name,
                status: doc.isAvailable ? 'available' : 'unavailable'
            })
        })
        .populate('client', 'firstName lastName email')
        .populate('partner', 'name email')
        .sort(sortQuery)
        .skip(skip)
        .limit(parseInt(limit));

    // Obtenir le nombre total de réservations
    const total = await Booking.countDocuments(filter);

    res.status(200).json({
        success: true,
        data: bookings,
        pagination: {
            total,
            pages: Math.ceil(total / limit),
            page: parseInt(page),
            limit: parseInt(limit)
        }
    });
});

/**
 * @desc    Créer une nouvelle réservation
 * @route   POST /api/bookings
 * @access  Privé
 */
exports.createBooking = asyncHandler(async (req, res) => {
    const booking = await bookingService.createBooking(req.body, req.user._id);
    
    res.status(201).json({
        success: true,
        data: booking
    });
});

/**
 * @desc    Obtenir toutes les réservations de l'utilisateur
 * @route   GET /api/bookings
 * @access  Privé
 */
exports.getUserBookings = asyncHandler(async (req, res) => {
    const filter = {};
    
    // Appliquer les filtres de la requête
    if (req.query.status) {
        filter.status = req.query.status;
    }
    
    // Date future ou passée
    if (req.query.upcoming === 'true') {
        filter.checkIn = { $gte: new Date() };
    } else if (req.query.upcoming === 'false') {
        filter.checkIn = { $lt: new Date() };
    }
    
    const bookings = await bookingService.getUserBookings(req.user._id, filter);
    
    res.status(200).json({
        success: true,
        count: bookings.length,
        data: bookings
    });
});

/**
 * @desc    Obtenir les réservations d'une résidence
 * @route   GET /api/residences/:residenceId/bookings
 * @access  Privé - Propriétaire ou Admin
 */
exports.getResidenceBookings = asyncHandler(async (req, res) => {
    const filter = {};
    
    // Appliquer les filtres de la requête
    if (req.query.status) {
        filter.status = req.query.status;
    }
    
    // Filtre par date
    if (req.query.startDate) {
        filter.checkIn = { $gte: new Date(req.query.startDate) };
    }
    
    if (req.query.endDate) {
        filter.checkOut = { ...(filter.checkOut || {}), $lte: new Date(req.query.endDate) };
    }
    
    const isAdmin = req.user.role === 'admin';
    const bookings = await bookingService.getResidenceBookings(
        req.params.residenceId,
        filter,
        isAdmin
    );
    
    res.status(200).json({
        success: true,
        count: bookings.length,
        data: bookings
    });
});

/**
 * @desc    Obtenir une réservation spécifique
 * @route   GET /api/bookings/:bookingId
 * @access  Privé
 */
exports.getBooking = asyncHandler(async (req, res) => {
    const isAdmin = req.user.role === 'admin';
    const booking = await bookingService.getBookingById(
        req.params.bookingId,
        req.user._id,
        isAdmin
    );
    
    res.status(200).json({
        success: true,
        data: booking
    });
});

/**
 * @desc    Modifier une réservation
 * @route   PUT /api/bookings/:bookingId
 * @access  Privé
 */
exports.updateBooking = asyncHandler(async (req, res) => {
    const isAdmin = req.user.role === 'admin';
    const booking = await bookingService.updateBooking(
        req.params.bookingId,
        req.user._id,
        req.body,
        isAdmin
    );
    
    res.status(200).json({
        success: true,
        data: booking
    });
});

/**
 * @desc    Annuler une réservation
 * @route   DELETE /api/bookings/:bookingId
 * @access  Privé
 */
exports.cancelBooking = asyncHandler(async (req, res) => {
    const isAdmin = req.user.role === 'admin';
    const result = await bookingService.cancelBooking(
        req.params.bookingId,
        req.user._id,
        req.body.reason || 'Annulation par l\'utilisateur',
        isAdmin
    );
    
    res.status(200).json({
        success: true,
        data: result.booking,
        refundAmount: result.refundAmount,
        refundPercentage: result.refundPercentage
    });
});

/**
 * @desc    Mettre à jour le statut d'une réservation
 * @route   PATCH /api/bookings/:bookingId/status
 * @access  Privé - Admin ou Propriétaire
 */
exports.updateBookingStatus = asyncHandler(async (req, res) => {
    const isAdmin = req.user.role === 'admin';
    const booking = await bookingService.updateBookingStatus(
        req.params.bookingId,
        req.body.status,
        req.user._id,
        isAdmin
    );
    
    res.status(200).json({
        success: true,
        data: booking
    });
});

/**
 * @desc    Ajouter un avis à une réservation
 * @route   POST /api/bookings/:bookingId/review
 * @access  Privé
 */
exports.addBookingReview = asyncHandler(async (req, res) => {
    const { rating, comment } = req.body;

    // Validation
    if (!rating) {
        throw new ApiError('Une note est requise', 400);
    }

    // Créer l'objet de notation
    let ratingObject;
    if (typeof rating === 'number') {
        // Compatibilité avec l'ancien format
        ratingObject = {
            overall: rating,
            cleanliness: 0,
            comfort: 0,
            facilities: 0,
            value: 0,
            location: 0
        };
    } else if (typeof rating === 'object') {
        // Nouveau format détaillé
        ratingObject = {
            overall: rating.overall || 0,
            cleanliness: rating.cleanliness || 0,
            comfort: rating.comfort || 0,
            facilities: rating.facilities || 0,
            value: rating.value || 0,
            location: rating.location || 0
        };
    } else {
        throw new ApiError('Format de notation invalide', 400);
    }

    // Créer l'avis
    const booking = await Booking.findById(req.params.bookingId);
    const review = await Review.create({
        user: req.user.id,
        residence: booking.residence,
        reservation: booking._id,
        rating: ratingObject,
        comment
    });

    res.status(200).json({
        success: true,
        data: review
    });
});

/**
 * @desc    Vérifier si une modification de réservation est possible
 * @route   GET /api/bookings/:bookingId/check-modification
 * @access  Privé
 */
exports.checkBookingModification = asyncHandler(async (req, res) => {
    const { startDate, endDate } = req.query;
    
    if (!startDate || !endDate) {
        throw new ApiError('Les dates de début et de fin sont requises', 400);
    }
    
    const result = await availabilityService.checkBookingModification(
        req.params.bookingId,
        startDate,
        endDate
    );
    
    res.status(200).json({
        success: true,
        data: result
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
