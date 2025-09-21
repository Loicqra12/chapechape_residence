const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate.middleware');
const reservationController = require('../controllers/reservation/reservation.controller');
const {
    createReservationSchema,
    modifyReservationSchema,
    updateStatusSchema,
    calculateModificationFeesSchema,
    checkAvailabilitySchema
} = require('../validations/reservation.validation');
const ApiError = require('../utils/apiError');

// Routes nécessitant une authentification
router.use(protect);

// Routes pour les réservations
router.route('/')
    .post(validate(createReservationSchema), reservationController.createReservation);

router.route('/my-reservations')
    .get(reservationController.getUserReservations);

router.route('/partner-reservations')
    .get(authorize('partner'), reservationController.getUserReservations);

router.route('/residence/:residenceId')
    .get(reservationController.getResidenceReservations);

router.route('/:id')
    .get(reservationController.getReservationById)
    .patch(validate(modifyReservationSchema), reservationController.modifyReservation);

router.route('/:id/status')
    .patch(validate(updateStatusSchema), reservationController.updateReservationStatus);

router.route('/:id/cancel')
    .patch(reservationController.cancelReservation);

router.route('/:id/check-availability')
    .get(validate(checkAvailabilitySchema), reservationController.checkAvailability);

router.route('/:id/modification-fees')
    .post(validate(calculateModificationFeesSchema), reservationController.calculateModificationFees);

// ✅ NOUVELLES ROUTES - INTEGRATION RESERVATIONMODE
// Routes d'approbation (Partner seulement)
router.route('/:id/approve')
    .patch(authorize('partner'), reservationController.approveReservation);

router.route('/:id/reject')
    .patch(authorize('partner'), reservationController.rejectReservation);

// Routes de check-in/out (Partner seulement)
router.route('/:id/checkin')
    .patch(authorize('partner'), reservationController.performCheckin);

router.route('/:id/checkout')
    .patch(authorize('partner'), reservationController.performCheckout);

module.exports = router;
