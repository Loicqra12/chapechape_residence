const Partner = require('../../models/partner.model');
const User = require('../../models/user.model');
const Residence = require('../../models/residence.model');
const Reservation = require('../../models/reservation.model');
const Payment = require('../../models/payment.model');
const Review = require('../../models/review.model');
const statsService = require('../../services/stats.service');
const dashboardService = require('../../services/dashboard.service');
const ApiError = require('../../utils/apiError');
const asyncHandler = require('../../middlewares/async.middleware');
const axios = require('axios');

// Clé API Google Maps pour le géocodage inverse
const GOOGLE_MAPS_API_KEY = process.env.GOOGLE_MAPS_API_KEY || 'YOUR_GOOGLE_MAPS_API_KEY';

// Obtenir le profil du partenaire (User + documents depuis Partner pour l'app)
exports.getPartnerProfile = asyncHandler(async (req, res) => {
    const user = await User.findById(req.user.id).select('-password');
    const userObj = user.toObject ? user.toObject() : { ...user };
    const partner = await Partner.findById(req.user.id);
    if (partner && partner.documents && partner.documents.length) {
        userObj.documents = partner.documents.map((d) => ({
            _id: d._id,
            id: d._id,
            type: d.type,
            documentUrl: d.url || '',
            url: d.url,
            uploadDate: d.uploadedAt,
            uploadedAt: d.uploadedAt,
            status: d.verified ? 'approved' : 'pending',
            verified: d.verified
        }));
    } else {
        userObj.documents = userObj.documents || [];
    }
    const { publicAuthView } = require('../../security/partner-capabilities');
    res.status(200).json({
        success: true,
        data: {
            ...userObj,
            ...publicAuthView(user),
        }
    });
});

// Mettre à jour le profil du partenaire
exports.updatePartnerProfile = asyncHandler(async (req, res) => {
    try {
        // Log pour déboguer
        console.log('Requête reçue pour mise à jour du profil');
        console.log('req.body:', req.body);
        console.log('req.files:', req.files);
        
        // Récupérer les données du formulaire
        const { firstName, lastName, email, phone, address } = req.body;
        
        // Créer l'objet de mise à jour
        const updateData = { 
            firstName, 
            lastName, 
            email, 
            phone, 
            address 
        };
        
        // Vérifier si une URL d'image Cloudinary a été fournie directement
        if (req.body.profileImage && typeof req.body.profileImage === 'string' && 
            (req.body.profileImage.startsWith('http://') || req.body.profileImage.startsWith('https://'))) {
            // C'est une URL Cloudinary
            console.log('URL Cloudinary détectée pour l\'image de profil:', req.body.profileImage);
            updateData.profileImage = req.body.profileImage;
            updateData.profileImageSource = 'cloudinary';
        }
        // Sinon, gérer l'upload de photo de profil traditionnelle
        else if (req.files) {
            // Chercher le fichier quel que soit le nom du champ
            let profileImage = null;
            
            // Vérifier plusieurs noms possibles de champs
            if (req.files.profileImage && req.files.profileImage.length > 0) {
                profileImage = req.files.profileImage[0];
                console.log('Trouvé image avec champ profileImage');
            } else if (req.files.profileimage && req.files.profileimage.length > 0) {
                profileImage = req.files.profileimage[0];
                console.log('Trouvé image avec champ profileimage');
            } else {
                // Parcourir tous les champs pour trouver un fichier image
                Object.keys(req.files).forEach(fieldName => {
                    if (!profileImage && req.files[fieldName].length > 0) {
                        console.log(`Trouvé image potentielle dans le champ ${fieldName}`);
                        profileImage = req.files[fieldName][0];
                    }
                });
            }
            
            if (profileImage) {
                // Créer une URL relative pour l'image
                updateData.profileImage = profileImage.filename;
                updateData.profileImageSource = 'local';
                console.log('Photo de profil mise à jour:', profileImage.filename);
            }
        }
        
        // Éviter l'erreur "Cannot read properties of null"
        if (!updateData.profileImage) {
            console.log('Aucune image de profil fournie ou image non reconnue');
        }
        
        // Mettre à jour l'utilisateur
        console.log('ID utilisateur:', req.user.id);
        console.log('Données de mise à jour:', updateData);

        const user = await User.findById(req.user.id);
        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'Utilisateur non trouvé'
            });
        }

        // Mettre à jour les champs
        if (updateData.firstName) user.firstName = updateData.firstName;
        if (updateData.lastName) user.lastName = updateData.lastName;
        if (updateData.email) user.email = updateData.email;
        if (updateData.phone && updateData.phone !== user.phoneNumber) {
            user.phoneNumber = updateData.phone;
            user.isPhoneVerified = false;
        }
        if (updateData.address) user.address = updateData.address;
        if (updateData.profileImage) user.profileImage = updateData.profileImage;

        // Sauvegarder les modifications
        await user.save();

        // Construire les URLs complètes pour les fichiers selon la source
        if (user.profileImage) {
            // Si c'est une URL Cloudinary, la laisser telle quelle
            if (user.profileImageSource === 'cloudinary' || 
                user.profileImage.startsWith('http://') || 
                user.profileImage.startsWith('https://')) {
                // Ne rien faire, c'est déjà une URL complète
                console.log('Utilisation de l\'URL Cloudinary existante:', user.profileImage);
            } else {
                // C'est un fichier local, construire l'URL complète
                user.profileImage = `/uploads/profiles/${user.profileImage}`;
                console.log('URL locale construite:', user.profileImage);
            }
        }
        
        res.status(200).json({
            success: true,
            data: {
                ...(user.toObject ? user.toObject() : user),
                ...require('../../security/partner-capabilities').publicAuthView(user),
            }
        });
    } catch (error) {
        console.error('Erreur lors de la mise à jour du profil:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la mise à jour du profil',
            error: error.message,
            stack: error.stack
        });
    }
});

// Upload d'un document
exports.uploadDocument = asyncHandler(async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({
                success: false,
                message: 'Aucun document fourni'
            });
        }

        const documentType = req.body.documentType || 'identity';
        const partner = await Partner.findById(req.user.id);

        if (!partner) {
            return res.status(404).json({
                success: false,
                message: 'Profil partenaire non trouvé'
            });
        }

        const newDocument = {
            type: documentType,
            url: req.file.filename,
            verified: false,
            uploadedAt: new Date()
        };

        const existingDocs = partner.documents || [];
        partner.documents = [...existingDocs, newDocument];
        await partner.save();

        const documentUrl = `/uploads/documents/${req.file.filename}`;

        res.status(200).json({
            success: true,
            data: {
                document: { ...newDocument, url: documentUrl },
                url: documentUrl
            }
        });
    } catch (error) {
        console.error('Erreur lors de l\'upload du document:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'upload du document',
            error: error.message
        });
    }
});

// Obtenir les résidences du partenaire
exports.getPartnerResidences = asyncHandler(async (req, res) => {
    const residences = await Residence.find({ partner: req.user.id });
    res.status(200).json({
        success: true,
        data: residences
    });
});

// Obtenir les réservations du partenaire (MIGRÉ vers Reservation)
exports.getPartnerBookings = asyncHandler(async (req, res) => {
    const reservations = await Reservation.find({
        partner: req.user.id
    }).populate('residence user cancellationPolicy');

    res.status(200).json({
        success: true,
        data: reservations
    });
});

// Statistiques du partenaire
exports.getPartnerStats = asyncHandler(async (req, res) => {
    const partnerId = req.user.id;
    const stats = await statsService.getPartnerStats(partnerId);
    
    res.status(200).json({
        success: true,
        data: stats
    });
});

// Statistiques par résidence
exports.getResidenceStats = asyncHandler(async (req, res) => {
    const partnerId = req.user.id;
    const { startDate, endDate } = req.query;
    
    const residences = await Residence.find({ partner: partnerId });
    const residenceIds = residences.map(r => r._id);

    const stats = await Promise.all(residenceIds.map(async (residenceId) => {
        const residenceStats = await statsService.getResidenceStats(residenceId, startDate, endDate);
        return {
            ...residenceStats,
            residence: await Residence.findById(residenceId).select('title location images')
        };
    }));

    res.status(200).json({
        success: true,
        data: stats
    });
});

// Tendances
exports.getTrends = asyncHandler(async (req, res) => {
    const partnerId = req.user.id;
    const { period = 'monthly', startDate, endDate } = req.query;

    const trends = await statsService.getTrends(partnerId, period, startDate, endDate);

    res.status(200).json({
        success: true,
        data: trends
    });
});

// Revenus (via réservations — Payment n'a pas de champ partner)
exports.getEarnings = asyncHandler(async (req, res) => {
    const mongoose = require('mongoose');
    const partnerId = req.user.id || req.user._id;
    const { startDate, endDate } = req.query;

    const partnerOid = new mongoose.Types.ObjectId(String(partnerId));
    const createdAtMatch = {};
    if (startDate) createdAtMatch.$gte = new Date(startDate);
    if (endDate) createdAtMatch.$lte = new Date(endDate);

    const earnings = await Payment.aggregate([
        {
            $lookup: {
                from: 'reservations',
                localField: 'reservation',
                foreignField: '_id',
                as: 'reservationDoc',
            },
        },
        { $unwind: '$reservationDoc' },
        {
            $match: {
                'reservationDoc.partner': partnerOid,
                status: 'paid',
                ...(Object.keys(createdAtMatch).length
                    ? { createdAt: createdAtMatch }
                    : {}),
            },
        },
        {
            $group: {
                _id: {
                    year: { $year: '$createdAt' },
                    month: { $month: '$createdAt' },
                },
                totalEarnings: { $sum: '$amount' },
                count: { $sum: 1 },
            },
        },
        { $sort: { '_id.year': -1, '_id.month': -1 } },
    ]);

    const periods = earnings.map((e) => ({
        date: new Date(Date.UTC(e._id.year, e._id.month - 1, 1)).toISOString(),
        amount: e.totalEarnings,
        count: e.count,
    }));

    const totalEarnings = periods.reduce((sum, p) => sum + Number(p.amount || 0), 0);
    const averagePerPeriod = periods.length ? totalEarnings / periods.length : 0;
    let growth = 0;
    if (periods.length >= 2) {
        const [latest, previous] = periods;
        growth =
            Number(previous.amount) === 0
                ? 0
                : ((Number(latest.amount) - Number(previous.amount)) / Number(previous.amount)) * 100;
    }

    res.status(200).json({
        success: true,
        data: {
            earnings: periods,
            total_earnings: totalEarnings,
            average_per_period: averagePerPeriod,
            growth,
        },
    });
});

// Vue d'ensemble du dashboard
exports.getDashboardOverview = asyncHandler(async (req, res) => {
    const partnerId = req.user.id;
    const overview = await dashboardService.getOverview(partnerId);
    
    res.status(200).json({
        success: true,
        data: overview
    });
});

// Statistiques financières détaillées
exports.getDashboardFinances = asyncHandler(async (req, res) => {
    const partnerId = req.user.id;
    const financialStats = await dashboardService.getFinancialStats(partnerId);
    
    res.status(200).json({
        success: true,
        data: financialStats
    });
});

// Analytics en temps réel
exports.getDashboardRealtime = asyncHandler(async (req, res) => {
    const partnerId = req.user.id;
    const realtimeStats = await dashboardService.getRealTimeAnalytics(partnerId);
    
    res.status(200).json({
        success: true,
        data: realtimeStats
    });
});

/**
 * Helper function pour obtenir le nom réel de la ville via géocodage inverse
 * @param {number} latitude - Latitude GPS
 * @param {number} longitude - Longitude GPS
 * @returns {Promise<string|null>} - Nom de la ville ou null si erreur
 */
async function _reverseGeocodeCity(latitude, longitude) {
    if (!latitude || !longitude || latitude === 0 || longitude === 0) {
        return null;
    }
    
    try {
        const response = await axios.get('https://maps.googleapis.com/maps/api/geocode/json', {
            params: {
                latlng: `${latitude},${longitude}`,
                key: GOOGLE_MAPS_API_KEY,
                language: 'fr' // Langue française pour les résultats
            }
        });
        
        if (response.data.status !== 'OK' || !response.data.results || response.data.results.length === 0) {
            console.warn(`Géocodage inverse échoué pour ${latitude},${longitude}: ${response.data.status}`);
            return null;
        }
        
        // Extraire le nom de la ville depuis les composants d'adresse
        const result = response.data.results[0];
        const addressComponents = result.address_components || [];
        
        // Chercher le composant "locality" (ville) ou "administrative_area_level_2" (département/région)
        for (const component of addressComponents) {
            if (component.types.includes('locality')) {
                return component.long_name; // Ex: "Cocody", "Yamoussoukro"
            }
            // Fallback sur le niveau administratif si pas de locality
            if (component.types.includes('administrative_area_level_2')) {
                return component.long_name;
            }
        }
        
        // Si aucun composant de ville trouvé, essayer d'extraire depuis formatted_address
        if (result.formatted_address) {
            const parts = result.formatted_address.split(',');
            if (parts.length > 0) {
                return parts[parts.length - 2]?.trim() || null; // Avant-dernier élément (généralement la ville)
            }
        }
        
        return null;
    } catch (error) {
        console.error(`Erreur lors du géocodage inverse pour ${latitude},${longitude}:`, error.message);
        return null;
    }
}

/**
 * Helper function pour déterminer si une valeur est un code de ville (court, 2-3 caractères)
 * @param {string} cityValue - Valeur à vérifier
 * @returns {boolean} - True si c'est probablement un code
 */
function _isCityCode(cityValue) {
    if (!cityValue || typeof cityValue !== 'string') {
        return false;
    }
    // Codes de ville typiques en Côte d'Ivoire : CO, YM, AB, etc. (2-3 caractères, majuscules)
    return cityValue.length <= 3 && cityValue === cityValue.toUpperCase() && /^[A-Z]+$/.test(cityValue);
}

// Statistiques par ville (mes villes)
exports.getMyCitiesStats = asyncHandler(async (req, res) => {
    const partnerId = req.user.id;
    const { startDate, endDate } = req.query;
    
    try {
        // Récupérer toutes les résidences du partenaire avec les coordonnées GPS
        const residences = await Residence.find({ 
            partner: partnerId,
            deleted: { $ne: true }
        }).select('location locationData city address images isAvailable latitude longitude');
        
        if (residences.length === 0) {
            return res.status(200).json({
                success: true,
                data: {
                    myCities: [],
                    opportunities: []
                }
            });
        }
        
        // Grouper par ville et calculer les stats
        const cityMap = new Map();
        
        // Cache pour éviter les appels API répétés pour les mêmes coordonnées
        const geocodeCache = new Map();
        
        for (const residence of residences) {
            // Extraire la ville depuis location.city ou city ou address
            let city = 'Non spécifiée';
            let needsGeocoding = false;
            
            // Priorité 1: location.city (peut être un code)
            if (residence.location?.city) {
                city = residence.location.city;
                needsGeocoding = _isCityCode(city);
            }
            // Priorité 2: city (peut être un code)
            else if (residence.city) {
                city = residence.city;
                needsGeocoding = _isCityCode(city);
            }
            // Priorité 3: address (parsing texte)
            else if (residence.address) {
                const addressParts = residence.address.split(',');
                if (addressParts.length > 0) {
                    city = addressParts[addressParts.length - 1].trim();
                }
            }
            
            // Si c'est un code ou vide, utiliser le géocodage inverse si coordonnées GPS disponibles
            if (needsGeocoding || city === 'Non spécifiée' || !city) {
                // Récupérer les coordonnées GPS
                let lat = null;
                let lng = null;
                
                if (residence.locationData?.coordinates) {
                    lat = residence.locationData.coordinates.latitude;
                    lng = residence.locationData.coordinates.longitude;
                } else if (residence.latitude && residence.longitude) {
                    lat = residence.latitude;
                    lng = residence.longitude;
                }
                
                // Utiliser le géocodage inverse si coordonnées disponibles
                if (lat && lng && lat !== 0 && lng !== 0) {
                    const cacheKey = `${lat.toFixed(4)},${lng.toFixed(4)}`;
                    
                    // Vérifier le cache
                    if (geocodeCache.has(cacheKey)) {
                        const cachedCity = geocodeCache.get(cacheKey);
                        if (cachedCity) {
                            city = cachedCity;
                        }
                    } else {
                        // Appel API pour géocodage inverse
                        const geocodedCity = await _reverseGeocodeCity(lat, lng);
                        geocodeCache.set(cacheKey, geocodedCity);
                        
                        if (geocodedCity) {
                            city = geocodedCity;
                        }
                    }
                }
            }
            
            if (!cityMap.has(city)) {
                cityMap.set(city, {
                    city: city,
                    residences: [],
                    totalRevenue: 0,
                    totalBookings: 0,
                    availableResidences: 0
                });
            }
            
            const cityData = cityMap.get(city);
            cityData.residences.push(residence._id);
            if (residence.isAvailable) {
                cityData.availableResidences++;
            }
        }
        
        // Calculer les stats détaillées pour chaque ville
        const myCities = await Promise.all(Array.from(cityMap.entries()).map(async ([city, cityData]) => {
            const residenceIds = cityData.residences;
            
            // Calculer les revenus depuis les paiements
            const revenueMatch = {
                partner: partnerId,
                status: 'completed',
                residence: { $in: residenceIds }
            };
            
            if (startDate || endDate) {
                revenueMatch.createdAt = {};
                if (startDate) revenueMatch.createdAt.$gte = new Date(startDate);
                if (endDate) revenueMatch.createdAt.$lte = new Date(endDate);
            }
            
            const revenueStats = await Payment.aggregate([
                { $match: revenueMatch },
                {
                    $group: {
                        _id: null,
                        totalRevenue: { $sum: '$amount' },
                        totalBookings: { $sum: 1 }
                    }
                }
            ]);
            
            const totalRevenue = revenueStats.length > 0 ? revenueStats[0].totalRevenue : 0;
            const totalBookings = revenueStats.length > 0 ? revenueStats[0].totalBookings : 0;
            
            // Calculer le taux d'occupation moyen
            let avgOccupancyRate = 0;
            if (residenceIds.length > 0) {
                const occupancyStats = await Promise.all(residenceIds.map(async (resId) => {
                    const stats = await statsService.getResidenceStats(resId, startDate, endDate);
                    return stats.occupancyRate || 0;
                }));
                avgOccupancyRate = occupancyStats.reduce((sum, rate) => sum + rate, 0) / occupancyStats.length;
            }
            
            // Trouver la meilleure résidence de la ville
            let bestResidence = null;
            if (residenceIds.length > 0) {
                const bestResidenceStats = await Promise.all(residenceIds.map(async (resId) => {
                    const stats = await statsService.getResidenceStats(resId, startDate, endDate);
                    return {
                        id: resId.toString(),
                        revenue: stats.revenue || 0
                    };
                }));
                
                bestResidence = bestResidenceStats.reduce((best, current) => 
                    current.revenue > best.revenue ? current : best
                , bestResidenceStats[0] || { id: '', revenue: 0 });
            }
            
            // Récupérer une image représentative (première résidence avec image)
            const sampleResidence = residences.find(r => 
                cityData.residences.some(id => id.equals(r._id)) && 
                r.images && r.images.length > 0
            );
            const imageUrl = sampleResidence?.images?.[0] || null;
            
            return {
                city: city,
                totalResidences: cityData.residences.length,
                availableResidences: cityData.availableResidences,
                totalRevenue: totalRevenue,
                averageOccupancyRate: avgOccupancyRate,
                totalBookings: totalBookings,
                bestPerformingResidence: bestResidence,
                imageUrl: imageUrl
            };
        }));
        
        // Trier par revenu décroissant
        myCities.sort((a, b) => b.totalRevenue - a.totalRevenue);
        
        // TODO: Opportunités d'expansion (peut être ajouté plus tard)
        // Pour l'instant, on retourne juste les villes du partenaire
        
        res.status(200).json({
            success: true,
            data: {
                myCities: myCities,
                opportunities: [] // À implémenter plus tard
            }
        });
        
    } catch (error) {
        console.error('Erreur lors du calcul des stats par ville:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors du calcul des statistiques par ville',
            error: error.message
        });
    }
});

// Obtenir les avis des résidences du partenaire
exports.getPartnerReviews = asyncHandler(async (req, res) => {
    const { page = 1, limit = 10, residenceId } = req.query;
    
    // Récupérer les résidences du partenaire
    const partnerResidences = await Residence.find({ partner: req.user.id }).select('_id');
    const residenceIds = partnerResidences.map(r => r._id);
    
    // Construire la requête de filtrage
    let query = { residence: { $in: residenceIds } };
    if (residenceId) {
        query.residence = residenceId;
    }
    
    // Récupérer les avis avec pagination
    const reviews = await Review.find(query)
        .populate('user', 'firstName lastName profilePicture')
        .populate('residence', 'title images')
        .sort({ createdAt: -1 })
        .limit(limit * 1)
        .skip((page - 1) * limit);
    
    // Compter le total pour la pagination
    const total = await Review.countDocuments(query);
    
    res.status(200).json({
        success: true,
        data: {
            reviews,
            pagination: {
                total,
                pages: Math.ceil(total / limit),
                currentPage: parseInt(page),
                perPage: parseInt(limit)
            }
        }
    });
});
