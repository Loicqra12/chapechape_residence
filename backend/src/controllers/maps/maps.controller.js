const asyncHandler = require('../../middlewares/async');
const apiError = require('../../utils/apiError');
const Residence = require('../../models/residence.model');
const axios = require('axios');

// Clé API Google Maps - À stocker idéalement dans les variables d'environnement
const GOOGLE_MAPS_API_KEY = process.env.GOOGLE_MAPS_API_KEY || 'YOUR_GOOGLE_MAPS_API_KEY';

/**
 * @desc    Rechercher des résidences à proximité
 * @route   GET /api/maps/nearby
 * @access  Public
 * @params  lat - Latitude (obligatoire)
 * @params  lng - Longitude (obligatoire)
 * @params  radius - Rayon de recherche en km (optionnel, défaut: 5km)
 * @params  limit - Nombre max de résultats (optionnel, défaut: 10)
 */
exports.getNearbyResidences = asyncHandler(async (req, res) => {
    const { lat, lng, radius = 5, limit = 10 } = req.query;
    
    console.log('Recherche de résidences à proximité:', { lat, lng, radius, limit });
    
    // Validation des paramètres obligatoires
    if (!lat || !lng) {
        throw new apiError('Les paramètres lat et lng sont obligatoires', 400);
    }
    
    // Convertir les paramètres en nombres
    const latitude = parseFloat(lat);
    const longitude = parseFloat(lng);
    const radiusKm = parseFloat(radius);
    const limitNumber = parseInt(limit);
    
    // Validation des valeurs numériques
    if (isNaN(latitude) || isNaN(longitude) || isNaN(radiusKm)) {
        throw new apiError('Les paramètres lat, lng et radius doivent être des nombres valides', 400);
    }
    
    try {
        // Recherche des résidences à proximité en utilisant les coordonnées standards (latitude, longitude)
        // Compatible avec l'ancienne structure et la nouvelle (locationData)
        const publication = require('../../services/residence-publication.service');
        const residences = await Residence.find(publication.applyPublicCatalogFilter({
            $or: [
                {
                    latitude: { $gte: latitude - 0.05, $lte: latitude + 0.05 },
                    longitude: { $gte: longitude - 0.05, $lte: longitude + 0.05 }
                },
                {
                    'locationData.coordinates.latitude': { $gte: latitude - 0.05, $lte: latitude + 0.05 },
                    'locationData.coordinates.longitude': { $gte: longitude - 0.05, $lte: longitude + 0.05 }
                }
            ]
        }))
        .limit(limitNumber)
        .sort({ createdAt: -1 })
        .populate('partner', 'firstName lastName email phoneNumber')
        .lean();
        
        console.log(`${residences.length} résidences trouvées à proximité`);
        
        // Calculer la distance approximative pour chaque résidence
        const residencesWithDistance = residences.map(residence => {
            // Utiliser les coordonnées de locationData si disponibles, sinon utiliser les champs standards
            const resLat = residence.locationData?.coordinates?.latitude || residence.latitude;
            const resLng = residence.locationData?.coordinates?.longitude || residence.longitude;
            
            // Calcul simple de la distance en km (approximation)
            const distance = calculateDistance(latitude, longitude, resLat, resLng);
            
            return {
                ...residence,
                distance: parseFloat(distance.toFixed(2)) // Distance en km avec 2 décimales
            };
        });
        
        // Filtrer les résidences par distance maximale et trier par distance
        const filteredResidences = residencesWithDistance
            .filter(res => res.distance <= radiusKm)
            .sort((a, b) => a.distance - b.distance);
        
        res.json({
            success: true,
            count: filteredResidences.length,
            data: filteredResidences
        });
    } catch (error) {
        console.error('Erreur lors de la recherche des résidences à proximité:', error);
        throw new apiError(`Erreur lors de la recherche: ${error.message}`, 500);
    }
});

/**
 * @desc    Géocodage: convertir une adresse en coordonnées GPS
 * @route   POST /api/maps/geocode
 * @access  Private
 */
exports.geocodeAddress = asyncHandler(async (req, res) => {
    const { address } = req.body;
    
    if (!address) {
        throw new apiError('L\'adresse est obligatoire', 400);
    }
    
    try {
        // Pour debug: afficher la clé API utilisée (masquée partiellement)
        const maskedKey = GOOGLE_MAPS_API_KEY ? `${GOOGLE_MAPS_API_KEY.substring(0, 6)}...` : 'non définie';
        console.log(`Tentative de géocodage pour: "${address}" avec clé API: ${maskedKey}`);
        
        // Appel à l'API Google Maps Geocoding
        const response = await axios.get('https://maps.googleapis.com/maps/api/geocode/json', {
            params: {
                address: address,
                key: GOOGLE_MAPS_API_KEY
            }
        });
        
        // Pour debug: afficher la réponse complète
        console.log('Réponse API de Google:', JSON.stringify(response.data, null, 2));
        
        // Vérifier si la requête a réussi
        if (response.data.status !== 'OK') {
            console.error('Erreur API Google Maps:', response.data.status, response.data.error_message || 'Pas de message d\'erreur');
            throw new apiError(`Erreur de géocodage: ${response.data.status} - ${response.data.error_message || 'Vérifiez votre clé API'}`, 400);
        }
        
        // Extraire les résultats
        const result = response.data.results[0];
        const formattedAddress = result.formatted_address;
        const { lat, lng } = result.geometry.location;
        
        // Récupérer les composants d'adresse (ville, pays, etc.)
        const addressComponents = {};
        result.address_components.forEach(component => {
            const types = component.types;
            if (types.includes('locality')) addressComponents.city = component.long_name;
            if (types.includes('country')) addressComponents.country = component.short_name;
            if (types.includes('administrative_area_level_1')) addressComponents.state = component.long_name;
            if (types.includes('postal_code')) addressComponents.postalCode = component.long_name;
        });
        
        res.json({
            success: true,
            data: {
                latitude: lat,
                longitude: lng,
                formattedAddress,
                components: addressComponents
            }
        });
    } catch (error) {
        console.error('Erreur détaillée lors du géocodage:', error);
        // Récupérer plus d'informations sur l'erreur
        const errorDetails = error.response ? 
            `Status: ${error.response.status}, Message: ${JSON.stringify(error.response.data)}` : 
            error.message;
            
        throw new apiError(`Erreur lors du géocodage: ${errorDetails}`, 500);
    }
});

/**
 * @desc    Géocodage inverse: convertir des coordonnées GPS en adresse
 * @route   POST /api/maps/reverse-geocode
 * @access  Private
 */
exports.reverseGeocodeCoordinates = asyncHandler(async (req, res) => {
    const { latitude, longitude } = req.body;
    
    if (!latitude || !longitude) {
        throw new apiError('Les coordonnées (latitude, longitude) sont obligatoires', 400);
    }
    
    try {
        // Appel à l'API Google Maps Geocoding (reverse)
        const response = await axios.get('https://maps.googleapis.com/maps/api/geocode/json', {
            params: {
                latlng: `${latitude},${longitude}`,
                key: GOOGLE_MAPS_API_KEY
            }
        });
        
        // Vérifier si la requête a réussi
        if (response.data.status !== 'OK') {
            throw new apiError(`Erreur de géocodage inverse: ${response.data.status}`, 400);
        }
        
        // Extraire les résultats
        const result = response.data.results[0];
        const formattedAddress = result.formatted_address;
        
        // Récupérer les composants d'adresse (ville, pays, etc.)
        const addressComponents = {};
        result.address_components.forEach(component => {
            const types = component.types;
            if (types.includes('locality')) addressComponents.city = component.long_name;
            if (types.includes('country')) addressComponents.country = component.short_name;
            if (types.includes('administrative_area_level_1')) addressComponents.state = component.long_name;
            if (types.includes('administrative_area_level_2')) addressComponents.commune = component.long_name;
            if (types.includes('postal_code')) addressComponents.postalCode = component.long_name;
            if (types.includes('route')) addressComponents.street = component.long_name;
            if (types.includes('street_number')) addressComponents.streetNumber = component.long_name;
            if (types.includes('neighborhood')) addressComponents.neighborhood = component.long_name;
            if (types.includes('sublocality')) addressComponents.sublocality = component.long_name;
        });
        
        res.json({
            success: true,
            data: {
                formattedAddress,
                components: addressComponents
            }
        });
    } catch (error) {
        console.error('Erreur lors du géocodage inverse:', error.message);
        throw new apiError('Erreur lors du géocodage inverse', 500);
    }
});

/**
 * @desc    Autocomplétion d'adresses
 * @route   GET /api/maps/autocomplete
 * @access  Public
 */
exports.autocompleteAddress = asyncHandler(async (req, res) => {
    const { query } = req.query;
    
    if (!query) {
        throw new apiError('Le paramètre query est obligatoire', 400);
    }
    
    try {
        // Appel à l'API Google Places Autocomplete
        const response = await axios.get('https://maps.googleapis.com/maps/api/place/autocomplete/json', {
            params: {
                input: query,
                key: GOOGLE_MAPS_API_KEY,
                language: 'fr', // Langue française
                components: 'country:ci' // Limiter à la Côte d'Ivoire par défaut
            }
        });
        
        // Vérifier si la requête a réussi
        if (response.data.status !== 'OK' && response.data.status !== 'ZERO_RESULTS') {
            throw new apiError(`Erreur d'autocomplétion: ${response.data.status}`, 400);
        }
        
        // Transformer les résultats dans un format plus simple
        const predictions = response.data.predictions.map(prediction => ({
            placeId: prediction.place_id,
            description: prediction.description,
            mainText: prediction.structured_formatting?.main_text || '',
            secondaryText: prediction.structured_formatting?.secondary_text || ''
        }));
        
        res.json({
            success: true,
            data: predictions
        });
    } catch (error) {
        console.error('Erreur lors de l\'autocomplétion:', error.message);
        throw new apiError('Erreur lors de l\'autocomplétion', 500);
    }
});

/**
 * Fonction utilitaire: calculer la distance entre deux points géographiques (formule de Haversine)
 * @param {Number} lat1 Latitude du point 1
 * @param {Number} lng1 Longitude du point 1
 * @param {Number} lat2 Latitude du point 2
 * @param {Number} lng2 Longitude du point 2
 * @returns {Number} Distance en kilomètres
 */
function calculateDistance(lat1, lng1, lat2, lng2) {
    const R = 6371; // Rayon de la Terre en km
    const dLat = deg2rad(lat2 - lat1);
    const dLng = deg2rad(lng2 - lng1);
    const a = 
        Math.sin(dLat/2) * Math.sin(dLat/2) +
        Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * 
        Math.sin(dLng/2) * Math.sin(dLng/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    const distance = R * c; // Distance en km
    return distance;
}

/**
 * Convertir les degrés en radians
 */
function deg2rad(deg) {
    return deg * (Math.PI/180);
}
