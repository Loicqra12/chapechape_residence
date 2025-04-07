const { ApiError } = require('../../utils/apiError');
const reservationService = require('../../services/reservation.service');
const SocketService = require('../../services/socket.service');
const asyncHandler = require('../../middlewares/async');
const Reservation = require('../../models/reservation.model');
const Residence = require('../../models/residence.model');

/**
 * Créer une nouvelle réservation
 * @route POST /api/reservations
 */
exports.createReservation = asyncHandler(async (req, res) => {
    const reservation = await reservationService.createReservation({
        ...req.body,
        user: req.user._id
    });

    // Notifier via websocket
    await SocketService.notifyBlockedDatesUpdate(reservation.residence);
    await SocketService.notifyNewReservation(reservation);

    res.status(201).json({
        success: true,
        data: reservation
    });
});

/**
 * Obtenir toutes les réservations d'un utilisateur
 * @route GET /api/reservations/my-reservations
 */
exports.getUserReservations = asyncHandler(async (req, res) => {
    const reservations = await Reservation.find({ user: req.user._id })
        .populate({
            path: 'residence',
            select: 'title images location address city',
            populate: { path: 'cancellationPolicy' }
        })
        .sort('-createdAt');

    res.status(200).json({
        success: true,
        data: reservations
    });
});

/**
 * Obtenir toutes les réservations d'une résidence
 * @route GET /api/reservations/residence/:residenceId
 */
exports.getResidenceReservations = asyncHandler(async (req, res) => {
    const residence = await Residence.findOne({
        _id: req.params.residenceId,
        partner: req.user._id
    });

    if (!residence) {
        throw new ApiError('Résidence non trouvée ou vous n\'êtes pas autorisé', 404);
    }

    const reservations = await Reservation.find({ 
        residence: req.params.residenceId,
        partner: req.user._id 
    })
        .populate('user', 'firstName lastName phoneNumber email')
        .populate('cancellationPolicy')
        .sort('-createdAt');

    res.status(200).json({
        success: true,
        data: reservations
    });
});

/**
 * Obtenir une réservation par son ID
 * @route GET /api/reservations/:id
 */
exports.getReservationById = asyncHandler(async (req, res) => {
    const reservation = await Reservation.findById(req.params.id)
        .populate({
            path: 'residence',
            select: 'title images location address city',
            populate: { path: 'cancellationPolicy' }
        })
        .populate('user', 'firstName lastName phoneNumber email');

    if (!reservation) {
        throw new ApiError('Réservation non trouvée', 404);
    }

    // Vérifier les permissions
    if (
        reservation.user.toString() !== req.user._id.toString() &&
        reservation.partner.toString() !== req.user._id.toString()
    ) {
        throw new ApiError('Non autorisé', 403);
    }

    res.status(200).json({
        success: true,
        data: reservation
    });
});

/**
 * Annuler une réservation
 * @route PATCH /api/reservations/:id/cancel
 */
exports.cancelReservation = asyncHandler(async (req, res) => {
    const { reason } = req.body;
    const reservation = await reservationService.cancelReservation(
        req.params.id,
        req.user._id,
        reason
    );

    // Notifier via websocket
    await SocketService.notifyBlockedDatesUpdate(reservation.residence);
    await SocketService.notifyReservationCancellation(reservation);

    res.status(200).json({
        success: true,
        data: reservation
    });
});

/**
 * Modifier une réservation
 * @route PATCH /api/reservations/:id
 */
exports.modifyReservation = asyncHandler(async (req, res) => {
    const reservation = await reservationService.modifyReservation(
        req.params.id,
        req.body,
        req.user._id
    );

    // Notifier via websocket
    await SocketService.notifyBlockedDatesUpdate(reservation.residence);
    await SocketService.notifyReservationModification(reservation);

    res.status(200).json({
        success: true,
        data: reservation
    });
});

/**
 * Mettre à jour le statut d'une réservation
 * @route PATCH /api/reservations/:id/status
 */
exports.updateReservationStatus = asyncHandler(async (req, res) => {
    const { status } = req.body;
    const reservation = await Reservation.findById(req.params.id);

    if (!reservation) {
        throw new ApiError('Réservation non trouvée', 404);
    }

    // Vérifier que c'est bien le propriétaire de la résidence
    const residence = await Residence.findOne({
        _id: reservation.residence,
        partner: req.user._id
    });

    if (!residence) {
        throw new ApiError('Vous n\'êtes pas autorisé à modifier cette réservation', 403);
    }

    // Mettre à jour le statut
    reservation.status = status;
    await reservation.save();

    // Notifier les clients connectés
    await SocketService.notifyBlockedDatesUpdate(reservation.residence);

    res.status(200).json({
        success: true,
        data: reservation
    });
});

/**
 * Calculer les frais de modification d'une réservation
 * @route POST /api/reservations/:id/modification-fees
 */
exports.calculateModificationFees = asyncHandler(async (req, res) => {
    const { newCheckIn, newCheckOut, newNumberOfGuests } = req.body;
    const reservation = await Reservation.findById(req.params.id)
        .populate({
            path: 'residence',
            populate: { path: 'cancellationPolicy' }
        });

    if (!reservation) {
        throw new ApiError('Réservation non trouvée', 404);
    }

    // Vérifier les permissions
    if (reservation.user.toString() !== req.user._id.toString()) {
        throw new ApiError('Non autorisé', 403);
    }

    // Vérifier que la réservation est modifiable
    const canModify = await reservation.canBeModified();
    if (!canModify) {
        throw new ApiError('Cette réservation ne peut plus être modifiée', 400);
    }

    // Calculer le nouveau prix total si les dates changent
    let newTotalPrice = reservation.totalPrice;
    if (newCheckIn || newCheckOut) {
        newTotalPrice = await reservation.residence.calculateTotalPrice(
            newCheckIn || reservation.checkIn,
            newCheckOut || reservation.checkOut
        );
    }

    // Calculer les frais de modification basés sur la politique d'annulation
    const modificationFee = reservation.residence.cancellationPolicy
        .calculateModificationFee(newTotalPrice, reservation.totalPrice);

    // Calculer la différence de prix
    const priceDifference = newTotalPrice - reservation.totalPrice;

    res.status(200).json({
        success: true,
        data: {
            baseFee: modificationFee,
            priceDifference: priceDifference,
            totalFee: modificationFee + (priceDifference > 0 ? priceDifference : 0),
            currency: 'FCFA'
        }
    });
});

/**
 * Vérifier la disponibilité pour une modification de réservation
 * @route GET /api/reservations/:id/check-availability
 */
exports.checkAvailability = asyncHandler(async (req, res) => {
    const { checkIn, checkOut } = req.query;
    const reservation = await Reservation.findById(req.params.id)
        .populate('residence');

    if (!reservation) {
        throw new ApiError('Réservation non trouvée', 404);
    }

    // Vérifier les permissions
    if (reservation.user.toString() !== req.user._id.toString()) {
        throw new ApiError('Non autorisé', 403);
    }

    // Vérifier que la réservation est modifiable
    const canModify = await reservation.canBeModified();
    if (!canModify) {
        throw new ApiError('Cette réservation ne peut plus être modifiée', 400);
    }

    // Vérifier la disponibilité
    const isAvailable = await reservation.residence.isAvailableForDates(
        new Date(checkIn),
        new Date(checkOut),
        reservation._id // Exclure la réservation actuelle
    );

    res.status(200).json({
        success: true,
        data: {
            isAvailable
        }
    });
});
