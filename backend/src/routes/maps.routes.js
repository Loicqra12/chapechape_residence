const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');
const mapsController = require('../controllers/maps/maps.controller');

// Routes publiques
router.get('/nearby', mapsController.getNearbyResidences);
router.get('/autocomplete', mapsController.autocompleteAddress);

// Routes protégées (nécessitent une authentification)
router.post('/geocode', protect, mapsController.geocodeAddress);
router.post('/reverse-geocode', protect, mapsController.reverseGeocodeCoordinates);

module.exports = router;
