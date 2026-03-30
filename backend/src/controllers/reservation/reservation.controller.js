const ApiError = require('../../utils/apiError');
const reservationService = require('../../services/reservation.service');
const SocketService = require('../../services/socket.service');
const PricingService = require('../../services/pricing.service'); // TEMPORAIREMENT DÉSACTIVÉ POUR DEBUG
const asyncHandler = require('../../middlewares/async');
const Reservation = require('../../models/reservation.model');
const Residence = require('../../models/residence.model');

/**
 * Créer une nouvelle réservation
 * @route POST /api/reservations
 */
exports.createReservation = asyncHandler(async (req, res) => {
    console.log('DEBUG: Création de réservation avec l\'utilisateur:', req.user._id);
    
    // Utiliser l'ID utilisateur à la fois comme user et client pour garantir la compatibilité
    const reservation = await reservationService.createReservation({
        ...req.body,
        user: req.user._id,
        client: req.user._id  // Assurer la cohérence avec le modèle de données
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
 * Obtenir toutes les réservations d'un utilisateur (filtrées selon le rôle)
 * @route GET /api/reservations/my-reservations
 */
exports.getUserReservations = asyncHandler(async (req, res) => {
    let filter = {};
    
    // Filtrage dynamique selon le rôle utilisateur
    switch (req.user.role) {
        case 'client':
            // Client voit ses propres réservations
            filter = { user: req.user._id };
            console.log('INFO: Filtrage CLIENT - user:', req.user._id);
            break;
            
        case 'partner':
            // Partner voit uniquement les réservations associées à son ID partenaire
            filter = { partner: req.user._id };
            console.log('INFO: Filtrage PARTNER - partner:', req.user._id);
            break;
            
        case 'admin':
        case 'superadmin':
        case 'owner':
            // Admins voient toutes les réservations
            filter = {};
            console.log('INFO: Filtrage ADMIN/SUPERADMIN/OWNER - aucune restriction');
            break;
            
        default:
            // Par défaut, comportement client (sécurité)
            filter = { user: req.user._id };
            console.log('WARN: Rôle non reconnu, filtrage par défaut CLIENT');
    }

    const reservations = await Reservation.find(filter)
        .populate({
            path: 'residence',
            select: 'title images location address city',
            populate: { path: 'cancellationPolicy' }
        })
        .populate('user', 'firstName lastName phoneNumber email')
        .populate('cancellationPolicy')
        .sort('-createdAt');

    console.log(`INFO: ${reservations.length} réservations trouvées pour le rôle ${req.user.role}`);

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

    // Extraction d'ID sécurisée - prend en charge tous les formats possibles d'ID
    const getIdValue = (input) => {
        // Cas null/undefined
        if (!input) return null;
        
        // Pour les objets MongoDB avec _id
        if (input && typeof input === 'object' && input._id) {
            // Extraction directe de l'ID sans récursion
            if (typeof input._id === 'string' && /^[0-9a-f]{24}$/i.test(input._id)) {
                return input._id;
            } else if (input._id && typeof input._id === 'object' && input._id.toString && typeof input._id.toString === 'function') {
                return input._id.toString();
            }
        }
        
        // Pour les ObjectId MongoDB natifs
        if (input && typeof input === 'object' && input.toString && typeof input.toString === 'function') {
            // L'ObjectId de MongoDB a une méthode toString() qui retourne l'id hexadécimal
            const idString = input.toString();
            
            // Vérifier s'il s'agit d'un ID MongoDB valide (24 caractères hexadécimaux)
            if (/^[0-9a-f]{24}$/i.test(idString)) {
                return idString;
            }
            
            // Essayer d'extraire l'ID d'une chaîne plus complexe (comme un objet sérialisé)
            const match = idString.match(/['"]*([0-9a-f]{24})['"]*/);
            if (match && match[1]) {
                return match[1];
            }
        }
        
        // Pour les chaînes
        if (typeof input === 'string') {
            // Vérifier si c'est déjà un ID MongoDB valide
            if (/^[0-9a-f]{24}$/i.test(input)) {
                return input;
            }
            
            // Essayer d'extraire l'ID d'une chaîne plus complexe
            const match = input.match(/['"]*([0-9a-f]{24})['"]*/);
            if (match && match[1]) {
                return match[1];
            }
        }
        
        console.log(`❌ Impossible d'extraire l'ID de:`, input);
        return null;
    };

    // Extraire tous les IDs pertinents
    const currentUserId = getIdValue(req.user._id);
    let reservationUserId = getIdValue(reservation.user);
    const reservationPartnerId = getIdValue(reservation.partner);
    const reservationClientId = getIdValue(reservation.client);
    const userRole = req.user.role;

    // Si la réservation a été créée par un client, vérifier aussi le champ 'client'
    if (!reservationUserId && reservationClientId) {
        reservationUserId = reservationClientId;
    }

    // Logs pour le débogage
    console.log('DEBUG - Analyse des IDs (v2):', {
        currentUserId,
        reservationUserId,
        reservationClientId, 
        reservationPartnerId,
        userRole,
        // Informations pour déboguer les types et formats
        types: {
            currentUser: typeof req.user._id,
            reservationUser: typeof reservation.user,
            reservationClient: typeof reservation.client,
            reservationPartner: typeof reservation.partner
        },
        // Versions brutes pour vérification
        raw: {
            user: reservation.user,
            client: reservation.client,
            partner: reservation.partner
        }
    });

    // Vérification simplifiée des permissions
    const isAdmin = userRole === 'admin';
    const isClient = userRole === 'client';
    
    // NOUVEAU: Déterminer si l'utilisateur a un rôle qui lui donne accès
    const isOwnerOfReservation = currentUserId === reservationUserId || currentUserId === reservationClientId;
    const isPartnerOfReservation = currentUserId === reservationPartnerId;
    
    // Afficher les résultats de vérification
    console.log('Vérification d\'accès:', {
        isOwnerOfReservation,
        isPartnerOfReservation,
        isAdmin,
        isClient,
        // Pour faciliter le débogage
        idEquality: {
            userMatchesReservationUser: currentUserId === reservationUserId,
            userMatchesReservationClient: currentUserId === reservationClientId,
            userMatchesReservationPartner: currentUserId === reservationPartnerId
        }
    });

    // Autorisation simplifiée: 3 cas d'accès légitimes
    const accessAllowed = isOwnerOfReservation || isPartnerOfReservation || isAdmin;

    if (!accessAllowed) {
        console.log('Accès refusé: aucun critère d\'autorisation valide');
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
    const ReservationStateService = require('../../services/reservation-state.service');
    
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

    // ✅ Utiliser le service de transition atomique
    const updatedReservation = await ReservationStateService.updateStatus(
        req.params.id,
        status,
        req.user._id,
        { reason: req.body.reason }
    );

    // Notifier les clients connectés
    await SocketService.notifyBlockedDatesUpdate(reservation.residence);

    res.status(200).json({
        success: true,
        data: updatedReservation
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

// ✅ NOUVEAUX CONTRÔLEURS - INTEGRATION RESERVATIONMODE
/**
 * Approuver une réservation
 * @route PATCH /api/reservations/:id/approve
 */
exports.approveReservation = asyncHandler(async (req, res) => {
    const reservation = await Reservation.findById(req.params.id)
        .populate('residence')
        .populate('user');

    if (!reservation) {
        throw new ApiError('Réservation non trouvée', 404);
    }

    // Vérifier que le partner est propriétaire de la résidence
    const getIdValue = (input) => {
        if (typeof input === 'string') return input;
        return input?._id?.toString() || input?.toString();
    };

    const currentPartnerId = getIdValue(req.user._id);
    const reservationPartnerId = getIdValue(reservation.partner);
    const residencePartnerId = getIdValue(reservation.residence.partner);

    if (currentPartnerId !== reservationPartnerId && currentPartnerId !== residencePartnerId) {
        throw new ApiError('Accès non autorisé à cette réservation', 403);
    }

    // Vérifier que la réservation est en attente d'approbation
    if (reservation.status !== 'awaiting_approval') {
        throw new ApiError('Cette réservation ne peut pas être approuvée dans son état actuel', 400);
    }

    // Mettre à jour le statut
    const oldStatus = reservation.status;
    reservation.status = 'confirmed';
    reservation.paymentStatus = 'pending'; // Le client doit maintenant payer
    await reservation.save();

    // ✅ PHASE 1 : Activer timer de paiement après approbation
    try {
        // Populate pour notifications
        const populatedReservation = await Reservation.findById(reservation._id)
            .populate('user', 'phoneNumber firstName lastName')
            .populate('residence', 'title')
            .populate('partner', 'phoneNumber firstName lastName');

        // Démarrer timer de paiement (TTL depuis snapshot ou défaut)
        const paymentTTL = reservation.ttlSnapshot?.paymentTTLMinutes || 30;
        await paymentTimerService.startPaymentTimer(reservation._id, paymentTTL);

        // Notifications agenda service
        await agendaService.notifyReservationStatusChange(reservation._id, oldStatus, 'confirmed');

        // WebSocket notifications avec nouvelles méthodes
        await SocketService.emitReservationStatusChange(populatedReservation, oldStatus, 'confirmed');

    } catch (timerError) {
        // Log sans bloquer la réponse
        console.error('Erreur activation timers après approbation:', timerError);
    }

    res.status(200).json({
        success: true,
        message: 'Réservation approuvée avec succès',
        data: reservation
    });
});

/**
 * Rejeter une réservation
 * @route PATCH /api/reservations/:id/reject
 */
exports.rejectReservation = asyncHandler(async (req, res) => {
    const { reason } = req.body; // Motif optionnel du rejet

    const reservation = await Reservation.findById(req.params.id)
        .populate('residence')
        .populate('user');

    if (!reservation) {
        throw new ApiError('Réservation non trouvée', 404);
    }

    // Vérifier l'ownership comme pour l'approbation
    const getIdValue = (input) => {
        if (typeof input === 'string') return input;
        return input?._id?.toString() || input?.toString();
    };

    const currentPartnerId = getIdValue(req.user._id);
    const reservationPartnerId = getIdValue(reservation.partner);
    const residencePartnerId = getIdValue(reservation.residence.partner);

    if (currentPartnerId !== reservationPartnerId && currentPartnerId !== residencePartnerId) {
        throw new ApiError('Accès non autorisé à cette réservation', 403);
    }

    // Vérifier que la réservation peut être rejetée
    if (!['awaiting_approval', 'pending'].includes(reservation.status)) {
        throw new ApiError('Cette réservation ne peut pas être rejetée dans son état actuel', 400);
    }

    // Mettre à jour le statut
    const oldStatus = reservation.status;
    reservation.status = 'cancelled';
    if (reason) {
        reservation.cancellationDetails = {
            ...reservation.cancellationDetails,
            reason: reason,
            cancelledBy: 'partner',
            cancelledAt: new Date()
        };
    }
    await reservation.save();

    // ✅ PHASE 1 : Libérer inventaire et notifier après rejet
    try {
        // Populate pour notifications complètes
        const populatedReservation = await Reservation.findById(reservation._id)
            .populate('user', 'phoneNumber firstName lastName')
            .populate('residence', 'title')
            .populate('partner', 'phoneNumber firstName lastName');

        // Libérer les dates (disponibilité → 'available')
        await availabilityService.updateAvailabilityForReservation(
            reservation.residence,
            reservation.checkIn,
            reservation.checkOut,
            reservation._id,
            'available'
        );

        // Notifications agenda service
        await agendaService.notifyReservationStatusChange(reservation._id, oldStatus, 'cancelled');

        // WebSocket notifications
        await SocketService.emitReservationStatusChange(populatedReservation, oldStatus, 'cancelled');

    } catch (cleanupError) {
        // Log sans bloquer la réponse
        console.error('Erreur nettoyage après rejet:', cleanupError);
    }

    res.status(200).json({
        success: true,
        message: 'Réservation rejetée avec succès',
        data: reservation
    });
});

/**
 * ✅ PHASE 1 : Confirmer le paiement d'une réservation
 * @route PATCH /api/reservations/:id/confirm-payment
 */
exports.confirmPayment = asyncHandler(async (req, res) => {
    const { paymentMethod, transactionId, paymentData } = req.body;

    const reservation = await Reservation.findById(req.params.id)
        .populate('residence')
        .populate('user')
        .populate('partner');

    if (!reservation) {
        throw new ApiError('Réservation non trouvée', 404);
    }

    // Vérifier ownership (client ou admin peuvent confirmer paiement)
    const getIdValue = (input) => {
        if (typeof input === 'string') return input;
        return input?._id?.toString() || input?.toString();
    };

    const currentUserId = getIdValue(req.user._id);
    const reservationUserId = getIdValue(reservation.user._id || reservation.user);

    // Seuls le client propriétaire ou admin/superadmin peuvent confirmer
    if (currentUserId !== reservationUserId && !['admin', 'superadmin'].includes(req.user.role)) {
        throw new ApiError('Accès non autorisé pour confirmer le paiement', 403);
    }

    // Vérifier que la réservation nécessite un paiement
    if (reservation.paymentStatus !== 'pending') {
        throw new ApiError('Cette réservation ne nécessite pas de confirmation de paiement', 400);
    }

    // Vérifier que la réservation n'a pas expiré
    if (reservation.status === 'expired') {
        throw new ApiError('Cette réservation a expiré, impossible de confirmer le paiement', 400);
    }

    // ✅ PHASE 1 : Logique de confirmation avec timer integration
    try {
        const oldPaymentStatus = reservation.paymentStatus;
        
        // Arrêter le timer de paiement et confirmer
        const timerResult = await paymentTimerService.confirmPaymentAndStopTimer(reservation._id, {
            method: paymentMethod,
            transactionId,
            ...paymentData
        });

        // Recharger la réservation mise à jour par le timer service
        const updatedReservation = await Reservation.findById(reservation._id)
            .populate('user', 'phoneNumber firstName lastName')
            .populate('residence', 'title')
            .populate('partner', 'phoneNumber firstName lastName');

        // Notifications agenda service
        await agendaService.notifyReservationStatusChange(
            reservation._id, 
            oldPaymentStatus, 
            updatedReservation.paymentStatus
        );

        // WebSocket notifications
        await SocketService.emitReservationStatusChange(
            updatedReservation, 
            `payment_${oldPaymentStatus}`, 
            `payment_${updatedReservation.paymentStatus}`
        );

        // Programmer rappel check-in si nécessaire
        if (updatedReservation.status === 'confirmed' && updatedReservation.checkIn) {
            await agendaService.scheduleReservationReminder(reservation._id, updatedReservation.checkIn);
        }

        res.status(200).json({
            success: true,
            message: 'Paiement confirmé avec succès',
            data: updatedReservation,
            timerInfo: timerResult
        });

    } catch (timerError) {
        console.error('Erreur confirmation paiement avec timer:', timerError);
        throw new ApiError('Erreur lors de la confirmation du paiement', 500);
    }
});

/**
 * Effectuer le check-in d'une réservation
 * @route PATCH /api/reservations/:id/checkin
 */
exports.performCheckin = asyncHandler(async (req, res) => {
    const reservation = await Reservation.findById(req.params.id)
        .populate('residence')
        .populate('user');

    if (!reservation) {
        throw new ApiError('Réservation non trouvée', 404);
    }

    // Vérifier l'ownership
    const getIdValue = (input) => {
        if (typeof input === 'string') return input;
        return input?._id?.toString() || input?.toString();
    };

    const currentPartnerId = getIdValue(req.user._id);
    const reservationPartnerId = getIdValue(reservation.partner);
    const residencePartnerId = getIdValue(reservation.residence.partner);

    if (currentPartnerId !== reservationPartnerId && currentPartnerId !== residencePartnerId) {
        throw new ApiError('Accès non autorisé à cette réservation', 403);
    }

    // Vérifier que la réservation peut être check-in
    if (reservation.status !== 'confirmed' || reservation.paymentStatus !== 'paid') {
        throw new ApiError('Cette réservation ne peut pas être check-in (statut ou paiement incorrect)', 400);
    }

    // Vérifier que c'est le bon moment pour check-in (tolérance de 2h avant)
    const now = new Date();
    const checkInTime = new Date(reservation.checkIn);
    const twoHoursBefore = new Date(checkInTime.getTime() - 2 * 60 * 60 * 1000);

    if (now < twoHoursBefore) {
        throw new ApiError('Le check-in ne peut être effectué que 2 heures avant l\'heure prévue', 400);
    }

    // Effectuer le check-in
    // Statut après check-in réel (phase 1 : séjour en cours)
    reservation.status = 'in_stay';
    reservation.actualCheckIn = now;
    await reservation.save();

    // Notifier via websocket
    await SocketService.notifyReservationStatusUpdate(reservation);

    res.status(200).json({
        success: true,
        message: 'Check-in effectué avec succès',
        data: reservation
    });
});

/**
 * Effectuer le check-out d'une réservation
 * @route PATCH /api/reservations/:id/checkout
 */
exports.performCheckout = asyncHandler(async (req, res) => {
    const reservation = await Reservation.findById(req.params.id)
        .populate('residence')
        .populate('user');

    if (!reservation) {
        throw new ApiError('Réservation non trouvée', 404);
    }

    // Vérifier l'ownership
    const getIdValue = (input) => {
        if (typeof input === 'string') return input;
        return input?._id?.toString() || input?.toString();
    };

    const currentPartnerId = getIdValue(req.user._id);
    const reservationPartnerId = getIdValue(reservation.partner);
    const residencePartnerId = getIdValue(reservation.residence.partner);

    if (currentPartnerId !== reservationPartnerId && currentPartnerId !== residencePartnerId) {
        throw new ApiError('Accès non autorisé à cette réservation', 403);
    }

    // Vérifier que la réservation peut être check-out
    if (!['confirmed', 'in_stay'].includes(reservation.status) || !reservation.actualCheckIn) {
        throw new ApiError('Cette réservation ne peut pas être check-out (doit être confirmée avec check-in effectué)', 400);
    }

    // Effectuer le check-out
    reservation.status = 'completed';
    reservation.actualCheckOut = new Date();
    await reservation.save();

    // Notifier via websocket
    await SocketService.notifyReservationStatusUpdate(reservation);

    res.status(200).json({
        success: true,
        message: 'Check-out effectué avec succès',
        data: reservation
    });
});
