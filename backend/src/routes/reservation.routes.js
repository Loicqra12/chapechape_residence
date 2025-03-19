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
const Reservation = require('../models/reservation.model');

// Routes nécessitant une authentification
router.use(protect);

// Créer une nouvelle réservation
router.post('/', createReservation);

// Obtenir les réservations de l'utilisateur connecté
router.get('/my-reservations', getUserReservations);

// Nouvel endpoint pour les partenaires
router.get('/partner-reservations', async (req, res) => {
  try {
    // Vérifier si l'utilisateur est un partenaire
    if (req.user.role !== 'partner') {
      return res.status(403).json({
        success: false,
        message: 'Seuls les partenaires peuvent accéder à cette ressource'
      });
    }

    // Trouver toutes les réservations où le partenaire est l'utilisateur connecté
    const reservations = await Reservation.find({ partner: req.user._id })
      .populate('residence', 'title images location address city')
      .populate('user', 'firstName lastName phoneNumber email')
      .sort('-createdAt');
    
    console.log(`Réservations trouvées pour le partenaire ${req.user._id}: ${reservations.length}`);
    
    res.status(200).json({
      success: true,
      data: reservations
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des réservations du partenaire:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Erreur lors de la récupération des réservations',
      error: error.message
    });
  }
});

// Obtenir les réservations d'une résidence (pour le propriétaire)
router.get('/residence/:residenceId', getResidenceReservations);

// Mettre à jour le statut d'une réservation (pour le propriétaire)
router.patch('/:id/status', updateReservationStatus);

// Annuler une réservation (pour l'utilisateur)
router.patch('/:id/cancel', cancelReservation);

// Récupérer une réservation par ID
router.get('/:id', async (req, res) => {
  try {
    const reservation = await Reservation.findById(req.params.id)
      .populate('residence', 'title images location address city') // Populate avec des infos de la résidence
      .populate('user', 'firstName lastName phoneNumber email'); // Populate avec des infos de l'utilisateur
    
    if (!reservation) {
      return res.status(404).json({ success: false, message: 'Réservation non trouvée' });
    }
    
    res.json({ success: true, data: reservation });
  } catch (error) {
    console.error('Erreur lors de la récupération de la réservation:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de la récupération de la réservation' });
  }
});

module.exports = router;
