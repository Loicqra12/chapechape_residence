const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');
const {
    createReservation,
    getUserReservations,
    getResidenceReservations,
    updateReservationStatus,
    cancelReservation
} = require('../controllers/reservation/reservation.controller');

// Routes nécessitant une authentification
router.use(protect);

// Créer une nouvelle réservation
router.post('/', createReservation);

// Obtenir les réservations de l'utilisateur connecté
router.get('/my-reservations', getUserReservations);

// Obtenir les réservations d'une résidence (pour le propriétaire)
router.get('/residence/:residenceId', getResidenceReservations);

// Mettre à jour le statut d'une réservation (pour le propriétaire)
router.patch('/:id/status', updateReservationStatus);

// Annuler une réservation (pour l'utilisateur)
router.patch('/:id/cancel', cancelReservation);

module.exports = router;
