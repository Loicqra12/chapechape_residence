const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');
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
    .get(async (req, res, next) => {
        if (req.user.role !== 'partner') {
            return next(new ApiError('Accès réservé aux partenaires', 403));
        }
        next();
    }, reservationController.getUserReservations);

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

module.exports = router;
