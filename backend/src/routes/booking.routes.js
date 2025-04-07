const express = require('express');
const bookingController = require('../controllers/booking/booking.controller');
const validate = require('../middlewares/validate.middleware');
const bookingValidation = require('../validations/booking.validation');
const { protect, authorize } = require('../middlewares/auth.middleware');

const router = express.Router();

// Toutes les routes nécessitent une authentification
router.use(protect);

// Routes pour obtenir et créer des réservations
router.route('/')
    .get(validate(bookingValidation.getBookings), bookingController.getUserBookings)
    .post(validate(bookingValidation.createBooking), bookingController.createBooking);

// Route pour obtenir, modifier ou annuler une réservation spécifique
router.route('/:bookingId')
    .get(validate(bookingValidation.getBooking), bookingController.getBooking)
    .put(validate(bookingValidation.updateBooking), bookingController.updateBooking)
    .delete(validate(bookingValidation.deleteBooking), bookingController.cancelBooking);

// Routes pour les opérations spécifiques sur une réservation
router.route('/:bookingId/status')
    .patch(validate(bookingValidation.updateBookingStatus), bookingController.updateBookingStatus);

router.route('/:bookingId/review')
    .post(validate(bookingValidation.addBookingReview), bookingController.addBookingReview);

// Route pour vérifier si une modification est possible
router.route('/:bookingId/check-modification')
    .get(validate(bookingValidation.checkBookingModification), bookingController.checkBookingModification);

// Route pour les réservations d'une résidence (accessible seulement aux propriétaires et admins)
router.route('/residence/:residenceId')
    .get(
        authorize('partner', 'admin'),
        validate(bookingValidation.getResidenceBookings),
        bookingController.getResidenceBookings
    );

module.exports = router;
