const Reservation = require('../../models/reservation.model');
const Residence = require('../../models/residence.model');
const SocketService = require('../../services/socket.service');

// Créer une nouvelle réservation
exports.createReservation = async (req, res) => {
    try {
        const { residenceId, checkIn, checkOut, numberOfGuests, specialRequests } = req.body;

        // Vérifier si la résidence existe
        const residence = await Residence.findById(residenceId);
        if (!residence) {
            return res.status(404).json({
                success: false,
                message: "Résidence non trouvée"
            });
        }

        // Vérifier si les dates sont disponibles
        const conflictingReservation = await Reservation.findOne({
            residence: residenceId,
            status: { $nin: ['cancelled'] },
            $or: [
                {
                    checkIn: { $lte: new Date(checkOut) },
                    checkOut: { $gte: new Date(checkIn) }
                }
            ]
        });

        if (conflictingReservation) {
            return res.status(400).json({
                success: false,
                message: "Ces dates ne sont pas disponibles"
            });
        }

        // Calculer le prix total
        const numberOfDays = Math.ceil((new Date(checkOut) - new Date(checkIn)) / (1000 * 60 * 60 * 24));
        const totalPrice = residence.price * numberOfDays;

        // Créer la réservation
        const reservation = new Reservation({
            residence: residenceId,
            user: req.user._id,
            checkIn: new Date(checkIn),
            checkOut: new Date(checkOut),
            numberOfGuests,
            totalPrice,
            specialRequests,
            status: 'pending'
        });

        await reservation.save();

        // Notifier les clients connectés
        await SocketService.notifyBlockedDatesUpdate(residenceId);
        await SocketService.notifyNewReservation(reservation);

        res.status(201).json({
            success: true,
            data: reservation
        });

    } catch (error) {
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

// Obtenir toutes les réservations d'un utilisateur
exports.getUserReservations = async (req, res) => {
    try {
        const reservations = await Reservation.find({ user: req.user._id })
            .populate('residence')
            .sort('-createdAt');

        res.status(200).json({
            success: true,
            data: reservations
        });
    } catch (error) {
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

// Obtenir toutes les réservations d'une résidence (pour le propriétaire)
exports.getResidenceReservations = async (req, res) => {
    try {
        const residence = await Residence.findOne({
            _id: req.params.residenceId,
            partner: req.user._id
        });

        if (!residence) {
            return res.status(404).json({
                success: false,
                message: "Résidence non trouvée ou vous n'êtes pas autorisé"
            });
        }

        const reservations = await Reservation.find({ residence: req.params.residenceId })
            .populate('user', 'name email')
            .sort('-createdAt');

        res.status(200).json({
            success: true,
            data: reservations
        });
    } catch (error) {
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

// Mettre à jour le statut d'une réservation
exports.updateReservationStatus = async (req, res) => {
    try {
        const { status } = req.body;
        const reservation = await Reservation.findById(req.params.id);

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: "Réservation non trouvée"
            });
        }

        // Vérifier que c'est bien le propriétaire de la résidence
        const residence = await Residence.findOne({
            _id: reservation.residence,
            partner: req.user._id
        });

        if (!residence) {
            return res.status(403).json({
                success: false,
                message: "Vous n'êtes pas autorisé à modifier cette réservation"
            });
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
    } catch (error) {
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

// Annuler une réservation
exports.cancelReservation = async (req, res) => {
    try {
        const reservation = await Reservation.findById(req.params.id);

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: "Réservation non trouvée"
            });
        }

        // Vérifier que c'est bien l'utilisateur qui a fait la réservation
        if (reservation.user.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: "Vous n'êtes pas autorisé à annuler cette réservation"
            });
        }

        // Vérifier si l'annulation est possible (par exemple, pas trop proche de la date)
        const today = new Date();
        const checkIn = new Date(reservation.checkIn);
        
        // Calculer la différence en millisecondes et prendre la valeur absolue
        const differenceInTime = Math.abs(checkIn.getTime() - today.getTime());
        
        // Convertir en heures
        const differenceInHours = differenceInTime / (1000 * 3600);
        
        console.log('Différence en heures (absolue):', differenceInHours);
        
        // Si moins de 48h avant le check-in
        if (differenceInHours < 48) {
            return res.status(400).json({
                success: false,
                message: "Impossible d'annuler une réservation moins de 48h avant"
            });
        }

        // Annuler la réservation
        reservation.status = 'cancelled';
        reservation.cancellationReason = 'Utilisateur';
        reservation.cancelledAt = new Date();
        await reservation.save();

        // Notifier les clients connectés
        await SocketService.notifyBlockedDatesUpdate(reservation.residence);
        await SocketService.notifyReservationCancellation(reservation);

        res.status(200).json({
            success: true,
            data: reservation
        });
    } catch (error) {
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};
