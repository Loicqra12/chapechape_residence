const express = require('express');
const bookingController = require('../controllers/booking/booking.controller');
const validate = require('../middlewares/validate.middleware');
const bookingValidation = require('../validations/booking.validation');
const { protect, authorize } = require('../middlewares/auth.middleware');

const router = express.Router();

// Routes protégées
router.use(protect);

// Routes pour tous les utilisateurs authentifiés
router.route('/')
    .post(validate(bookingValidation.createBooking), bookingController.createBooking)
    .get(validate(bookingValidation.getBookings), bookingController.getUserBookings);

router.route('/:bookingId')
    .get(validate(bookingValidation.getBooking), bookingController.getBooking)
    .put(validate(bookingValidation.updateBooking), bookingController.updateBooking)
    .delete(validate(bookingValidation.deleteBooking), bookingController.cancelBooking);

// Routes pour les administrateurs
router.use(authorize('admin'));

router.get('/all', validate(bookingValidation.getBookings), bookingController.getAllBookings);

module.exports = router;
