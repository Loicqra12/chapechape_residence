const Residence = require('../../models/residence.model');
const ApiError = require('../../utils/apiError');
const asyncHandler = require('../../middlewares/async');
const fs = require('fs');
const path = require('path');

// @desc    Créer une nouvelle résidence
// @route   POST /api/residences
// @access  Private (Partner only)
exports.createResidence = asyncHandler(async (req, res) => {
    let residenceData;
    
    console.log('==== CRÉATION DE RÉSIDENCE ====');
    console.log('Headers:', req.headers);
    console.log('Request body keys:', Object.keys(req.body));
    console.log('Request body raw:', req.body);
    console.log('Files:', req.files?.length || 'None');

    // Vérifier si les données sont envoyées via le champ residenceData (approche JSON)
    if (req.body.residenceData) {
        try {
            console.log('Données reçues (format JSON):');
            console.log('residenceData (raw):', req.body.residenceData);
            
            residenceData = JSON.parse(req.body.residenceData);
            console.log('Données JSON parsées:', Object.keys(residenceData));
            console.log('Contenu complet:', residenceData);
            
            // Assigner l'id du partenaire
            residenceData.partner = req.user.id;
            console.log(`Partenaire assigné: ${req.user.id}`);
        } catch (error) {
            console.error('Erreur de parsing JSON:', error);
            throw new ApiError('Format de données invalide: ' + error.message, 400);
        }
    } else {
        // Approche traditionnelle (champs individuels)
        residenceData = req.body;
        residenceData.partner = req.user.id;
        console.log('Données reçues (format direct):', Object.keys(residenceData));
        console.log('Contenu complet:', residenceData);
    }
    
    // Validation manuelle des champs requis
    const requiredFields = ['title', 'description', 'price', 'type', 'address', 'city', 'bedrooms', 'bathrooms', 'area'];
    const missingFields = requiredFields.filter(field => residenceData[field] === undefined || residenceData[field] === null);
    
    if (missingFields.length > 0) {
        console.error('Champs manquants:', missingFields);
        throw new ApiError(`Champs requis manquants: ${missingFields.join(', ')}`, 400);
    }

    try {
        // Créer la résidence de base
        console.log('Création de la résidence avec les données:', residenceData);
        const residence = await Residence.create(residenceData);
        console.log(`Résidence créée avec succès: ${residence._id}`);
        
        // Si des fichiers sont présents, traiter les images
        if (req.files && req.files.length > 0) {
            console.log(`Traitement de ${req.files.length} images`);
            
            const images = req.files.map(file => `/uploads/residences/${file.filename}`);
            
            console.log('Images avant sauvegarde:', images);
            console.log('Images existantes:', residence.images);
            
            residence.images = [...residence.images, ...images];
            await residence.save();

            console.log('Images après sauvegarde:', residence.images);
        } else {
            console.log('Aucune image reçue avec la requête');
        }

        res.status(201).json({
            success: true,
            data: residence.toObject()
        });
    } catch (error) {
        console.error('Erreur lors de la création de la résidence:', error);
        throw new ApiError(`Échec de la création de la résidence: ${error.message}`, 500);
    }
});

// @desc    Obtenir toutes les résidences
// @route   GET /api/residences
// @access  Public
exports.getResidences = asyncHandler(async (req, res) => {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;
    const sortBy = req.query.sortBy || 'createdAt';
    const order = req.query.order || 'desc';

    const query = Residence.find()
        .populate('partner', 'firstName lastName email phoneNumber')
        .skip(skip)
        .limit(limit)
        .sort({ [sortBy]: order })
        .lean();

    const [residences, total] = await Promise.all([
        query,
        Residence.countDocuments()
    ]);

    res.json({
        success: true,
        count: residences.length,
        total,
        data: residences,
        pagination: {
            currentPage: page,
            totalPages: Math.ceil(total / limit),
            limit
        }
    });
});

// @desc    Obtenir toutes les résidences (format liste)
// @route   GET /api/residences/all
// @access  Public
exports.getAllResidences = asyncHandler(async (req, res) => {
    try {
        console.log('Récupération de toutes les résidences (format liste sans wrapper)');
        
        // Utiliser lean() pour des performances optimales
        const residences = await Residence.find()
            .populate('partner', 'firstName lastName email phoneNumber')
            .lean();
        
        console.log(`${residences.length} résidences trouvées au total`);
        
        // Renvoyer directement la liste sans wrapper success/data
        // Compatible avec les attentes du client mobile
        res.json(residences);
    } catch (error) {
        console.error('Erreur lors de la récupération des résidences (format liste):', error);
        throw new Error(`Erreur serveur: ${error.message}`);
    }
});

// @desc    Obtenir une résidence
// @route   GET /api/residences/:id
// @access  Public
exports.getResidence = asyncHandler(async (req, res) => {
    const residence = await Residence.findById(req.params.id)
        .populate('partner', 'firstName lastName email phoneNumber')
        .lean();

    if (!residence) {
        throw new ApiError('Résidence non trouvée', 404);
    }

    console.log('Résidence récupérée - ID:', req.params.id);
    console.log('Images dans la résidence:', residence.images);

    res.json({
        success: true,
        data: residence
    });
});

// @desc    Mettre à jour une résidence
// @route   PUT /api/residences/:id
// @access  Private (Partner only)
exports.updateResidence = asyncHandler(async (req, res) => {
    let residence = await Residence.findById(req.params.id);

    if (!residence) {
        throw new ApiError('Résidence non trouvée', 404);
    }

    // Vérifier si l'utilisateur est le propriétaire
    if (residence.partner.toString() !== req.user.id && req.user.role !== 'admin') {
        throw new ApiError('Non autorisé à modifier cette résidence', 403);
    }

    residence = await Residence.findByIdAndUpdate(
        req.params.id,
        req.body,
        {
            new: true,
            runValidators: true
        }
    ).populate('partner', 'firstName lastName email phoneNumber')
     .lean();

    res.status(200).json({
        success: true,
        data: residence
    });
});

// @desc    Supprimer une résidence
// @route   DELETE /api/residences/:id
// @access  Private (Partner only)
exports.deleteResidence = asyncHandler(async (req, res) => {
    const residence = await Residence.findById(req.params.id);

    if (!residence) {
        throw new ApiError('Résidence non trouvée', 404);
    }

    if (residence.partner.toString() !== req.user.id && req.user.role !== 'admin') {
        throw new ApiError('Non autorisé à supprimer cette résidence', 403);
    }

    // Faire une suppression douce au lieu d'une suppression réelle
    // Mettre à jour la résidence avec le flag 'deleted' à true
    residence.deleted = true;
    residence.deletedAt = new Date();
    await residence.save();

    console.log(`Résidence ${req.params.id} marquée comme supprimée (soft delete)`);

    res.status(200).json({
        success: true,
        message: 'Résidence supprimée avec succès'
    });
});

// @desc    Rechercher des résidences
// @route   GET /api/residences/search
// @access  Public
exports.searchResidences = asyncHandler(async (req, res) => {
    const { 
        query, 
        location, 
        minPrice, 
        maxPrice, 
        features,
        type,
        bedrooms,
        bathrooms,
        page = 1,
        limit = 10,
        sortBy = 'createdAt',
        order = 'desc'
    } = req.query;

    const searchQuery = {
        deleted: { $ne: true } // Exclure les résidences supprimées
    };

    if (query) {
        searchQuery.$or = [
            { title: { $regex: query, $options: 'i' } },
            { description: { $regex: query, $options: 'i' } }
        ];
    }

    if (location) {
        searchQuery['location.city'] = { $regex: location, $options: 'i' };
    }

    if (minPrice || maxPrice) {
        searchQuery.price = {};
        if (minPrice) searchQuery.price.$gte = Number(minPrice);
        if (maxPrice) searchQuery.price.$lte = Number(maxPrice);
    }

    if (features) {
        const featuresList = features.split(',');
        searchQuery.features = { $all: featuresList };
    }

    if (type) {
        searchQuery.type = type;
    }

    if (bedrooms) {
        searchQuery.bedrooms = Number(bedrooms);
    }

    if (bathrooms) {
        searchQuery.bathrooms = Number(bathrooms);
    }

    const skip = (page - 1) * limit;

    const [residences, total] = await Promise.all([
        Residence.find(searchQuery)
            .populate('partner', 'firstName lastName email phoneNumber')
            .skip(skip)
            .limit(limit)
            .sort({ [sortBy]: order })
            .lean(),
        Residence.countDocuments(searchQuery)
    ]);

    const response = {
        success: true,
        count: residences.length,
        total,
        data: residences,
        pagination: {
            currentPage: page,
            totalPages: Math.ceil(total / limit),
            limit
        }
    };

    res.status(200).json(response);
});

// @desc    Ajouter des images à une résidence
// @route   POST /api/residences/:id/images
// @access  Private (Partner only)
exports.uploadImages = asyncHandler(async (req, res) => {
    const residence = await Residence.findById(req.params.id);

    if (!residence) {
        // Supprimer les fichiers uploadés si la résidence n'existe pas
        if (req.files) {
            req.files.forEach(file => {
                fs.unlinkSync(file.path);
            });
        }
        throw new ApiError('Résidence non trouvée', 404);
    }

    if (residence.partner.toString() !== req.user.id && req.user.role !== 'admin') {
        // Supprimer les fichiers uploadés si non autorisé
        if (req.files) {
            req.files.forEach(file => {
                fs.unlinkSync(file.path);
            });
        }
        throw new ApiError('Non autorisé à modifier cette résidence', 403);
    }

    if (!req.files) {
        throw new ApiError('Veuillez télécharger des images', 400);
    }

    const images = req.files.map(file => `/uploads/residences/${file.filename}`);

    residence.images = [...residence.images, ...images];
    await residence.save();

    res.status(200).json({
        success: true,
        data: residence.toObject()
    });
});

// @desc    Ajouter des points d'intérêt à proximité d'une résidence
// @route   POST /api/residences/:id/nearby-places
// @access  Private (Partner only)
exports.addNearbyPlace = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { name, type, distance, description } = req.body;

    // Validation des données
    if (!name || !type || !distance) {
        throw new ApiError('Veuillez fournir le nom, le type et la distance du lieu à proximité', 400);
    }

    // Vérifier que le type est valide
    const validTypes = ['restaurant', 'bar', 'shop', 'market', 'other'];
    if (!validTypes.includes(type)) {
        throw new ApiError(`Type invalide. Les types valides sont: ${validTypes.join(', ')}`, 400);
    }

    // Récupérer la résidence
    const residence = await Residence.findById(id);
    if (!residence) {
        throw new ApiError('Résidence non trouvée', 404);
    }

    // Vérifier que l'utilisateur est le propriétaire de la résidence
    if (residence.partner.toString() !== req.user.id) {
        throw new ApiError('Vous n\'êtes pas autorisé à modifier cette résidence', 403);
    }

    // Créer le nouveau lieu à proximité
    const nearbyPlace = {
        name,
        type,
        distance,
        description: description || ''
    };

    // Ajouter à la liste des lieux à proximité
    residence.nearbyPlaces = residence.nearbyPlaces || [];
    residence.nearbyPlaces.push(nearbyPlace);
    await residence.save();

    res.status(201).json({
        success: true,
        data: nearbyPlace
    });
});

// @desc    Ajouter une FAQ à une résidence
// @route   POST /api/residences/:id/faqs
// @access  Private (Partner only)
exports.addFaq = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { question, answer } = req.body;

    // Validation des données
    if (!question || !answer) {
        throw new ApiError('Veuillez fournir la question et la réponse', 400);
    }

    // Récupérer la résidence
    const residence = await Residence.findById(id);
    if (!residence) {
        throw new ApiError('Résidence non trouvée', 404);
    }

    // Vérifier que l'utilisateur est le propriétaire de la résidence
    if (residence.partner.toString() !== req.user.id) {
        throw new ApiError('Vous n\'êtes pas autorisé à modifier cette résidence', 403);
    }

    // Créer la nouvelle FAQ
    const faq = {
        question,
        answer
    };

    // Ajouter à la liste des FAQs
    residence.faqs = residence.faqs || [];
    residence.faqs.push(faq);
    await residence.save();

    res.status(201).json({
        success: true,
        data: faq
    });
});

// @desc    Mettre à jour les équipements améliorés d'une résidence
// @route   PUT /api/residences/:id/enhanced-amenities
// @access  Private (Partner only)
exports.updateEnhancedAmenities = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { 
        water, 
        electricity, 
        internet, 
        kitchen, 
        cooling, 
        security,
        extras
    } = req.body;

    // Récupérer la résidence
    const residence = await Residence.findById(id);
    if (!residence) {
        throw new ApiError('Résidence non trouvée', 404);
    }

    // Vérifier que l'utilisateur est le propriétaire de la résidence
    if (residence.partner.toString() !== req.user.id) {
        throw new ApiError('Vous n\'êtes pas autorisé à modifier cette résidence', 403);
    }

    // Initialiser les équipements améliorés si nécessaire
    residence.enhancedAmenities = residence.enhancedAmenities || {};

    // Mettre à jour les équipements améliorés
    if (water) residence.enhancedAmenities.water = water;
    if (electricity) residence.enhancedAmenities.electricity = electricity;
    if (internet) residence.enhancedAmenities.internet = internet;
    if (kitchen) residence.enhancedAmenities.kitchen = kitchen;
    if (cooling) residence.enhancedAmenities.cooling = cooling;
    if (security) residence.enhancedAmenities.security = security;
    if (extras) residence.enhancedAmenities.extras = extras;

    await residence.save();

    res.status(200).json({
        success: true,
        data: residence.enhancedAmenities
    });
});

// @desc    Mettre à jour les méthodes de paiement acceptées pour une résidence
// @route   PUT /api/residences/:id/payment-methods
// @access  Private (Partner only)
exports.updatePaymentMethods = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { paymentMethods } = req.body;

    // Validation des données
    if (!paymentMethods || !Array.isArray(paymentMethods)) {
        throw new ApiError('Veuillez fournir un tableau de méthodes de paiement', 400);
    }

    // Vérifier que les méthodes de paiement sont valides
    const validMethods = ['cash', 'wave', 'orange_money', 'moov_money', 'mtn_money', 'credit_card', 'bank_transfer'];
    const invalidMethods = paymentMethods.filter(method => !validMethods.includes(method));
    if (invalidMethods.length > 0) {
        throw new ApiError(`Méthodes de paiement invalides: ${invalidMethods.join(', ')}. Les méthodes valides sont: ${validMethods.join(', ')}`, 400);
    }

    // Récupérer la résidence
    const residence = await Residence.findById(id);
    if (!residence) {
        throw new ApiError('Résidence non trouvée', 404);
    }

    // Vérifier que l'utilisateur est le propriétaire de la résidence
    if (residence.partner.toString() !== req.user.id) {
        throw new ApiError('Vous n\'êtes pas autorisé à modifier cette résidence', 403);
    }

    // Mettre à jour les méthodes de paiement
    residence.paymentMethods = paymentMethods;
    await residence.save();

    res.status(200).json({
        success: true,
        data: residence.paymentMethods
    });
});

// @desc    Ajouter ou mettre à jour un point d'intérêt à proximité d'une résidence
// @route   PUT /api/residences/:id/nearby-places
// @access  Private (Partner only)
exports.updateNearbyPlaces = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { nearbyPlaces } = req.body;

    // Validation des données
    if (!nearbyPlaces || !Array.isArray(nearbyPlaces)) {
        throw new ApiError('Veuillez fournir un tableau de points d\'intérêt', 400);
    }

    // Valider chaque point d'intérêt
    const validTypes = ['restaurant', 'bar', 'shop', 'market', 'other'];
    for (const place of nearbyPlaces) {
        if (!place.name || !place.type || place.distance === undefined) {
            throw new ApiError('Chaque point d\'intérêt doit avoir un nom, un type et une distance', 400);
        }
        
        if (!validTypes.includes(place.type)) {
            throw new ApiError(`Type de point d'intérêt invalide: ${place.type}. Les types valides sont: ${validTypes.join(', ')}`, 400);
        }
    }

    // Récupérer la résidence
    const residence = await Residence.findById(id);
    if (!residence) {
        throw new ApiError('Résidence non trouvée', 404);
    }

    // Vérifier que l'utilisateur est le propriétaire de la résidence
    if (residence.partner.toString() !== req.user.id) {
        throw new ApiError('Vous n\'êtes pas autorisé à modifier cette résidence', 403);
    }

    // Mettre à jour les points d'intérêt
    residence.nearbyPlaces = nearbyPlaces;
    await residence.save();

    res.status(200).json({
        success: true,
        data: residence.nearbyPlaces
    });
});

// @desc    Mettre à jour le nombre d'étoiles d'une résidence
// @route   PUT /api/residences/:id/stars
// @access  Private (Admin only)
exports.updateStars = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { stars } = req.body;

    // Validation des données
    if (stars === undefined || stars < 0 || stars > 5) {
        throw new ApiError('Veuillez fournir un nombre d\'étoiles valide (entre 0 et 5)', 400);
    }

    // Vérifier que l'utilisateur est un administrateur
    if (req.user.role !== 'admin') {
        throw new ApiError('Seuls les administrateurs peuvent mettre à jour le nombre d\'étoiles', 403);
    }

    // Récupérer la résidence
    const residence = await Residence.findById(id);
    if (!residence) {
        throw new ApiError('Résidence non trouvée', 404);
    }

    // Mettre à jour le nombre d'étoiles
    residence.stars = stars;
    await residence.save();

    res.status(200).json({
        success: true,
        data: { stars: residence.stars }
    });
});

// @desc    Ajouter ou mettre à jour les notations d'une résidence
// @route   PUT /api/residences/:id/ratings
// @access  Private (Les clients authentifiés avec une réservation confirmée)
exports.updateRatings = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { overall, cleanliness, comfort, facilities } = req.body;

    // Validation des données
    if (overall === undefined || overall < 0 || overall > 5) {
        throw new ApiError('Veuillez fournir une note globale valide (entre 0 et 5)', 400);
    }

    // Validation des notes optionnelles
    if ((cleanliness !== undefined && (cleanliness < 0 || cleanliness > 5)) ||
        (comfort !== undefined && (comfort < 0 || comfort > 5)) ||
        (facilities !== undefined && (facilities < 0 || facilities > 5))) {
        throw new ApiError('Toutes les notes doivent être comprises entre 0 et 5', 400);
    }

    // Récupérer la résidence
    const residence = await Residence.findById(id);
    if (!residence) {
        throw new ApiError('Résidence non trouvée', 404);
    }

    // TODO: Vérifier que l'utilisateur a bien une réservation confirmée pour cette résidence
    // Cette vérification nécessiterait un accès au modèle Reservation
    // Pour le moment, nous autorisons tous les utilisateurs authentifiés

    // Initialiser le champ rating s'il n'existe pas
    if (!residence.rating) {
        residence.rating = {
            overall: 0,
            cleanliness: 0,
            comfort: 0,
            facilities: 0,
            reviewCount: 0
        };
    }

    // Calculer les nouvelles moyennes
    const currentCount = residence.rating.reviewCount || 0;
    const newCount = currentCount + 1;

    // Mettre à jour chaque note
    residence.rating.overall = ((residence.rating.overall * currentCount) + overall) / newCount;
    
    if (cleanliness !== undefined) {
        residence.rating.cleanliness = ((residence.rating.cleanliness * currentCount) + cleanliness) / newCount;
    }
    
    if (comfort !== undefined) {
        residence.rating.comfort = ((residence.rating.comfort * currentCount) + comfort) / newCount;
    }
    
    if (facilities !== undefined) {
        residence.rating.facilities = ((residence.rating.facilities * currentCount) + facilities) / newCount;
    }

    // Incrémenter le nombre d'avis
    residence.rating.reviewCount = newCount;

    await residence.save();

    res.status(200).json({
        success: true,
        data: residence.rating
    });
});

// @desc    Mettre à jour la liste complète des FAQs d'une résidence
// @route   PUT /api/residences/:id/faqs
// @access  Private (Partner only)
exports.updateFaqs = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { faqs } = req.body;

    // Validation des données
    if (!faqs || !Array.isArray(faqs)) {
        throw new ApiError('Veuillez fournir un tableau de FAQs', 400);
    }

    // Valider chaque FAQ
    for (const faq of faqs) {
        if (!faq.question || !faq.answer) {
            throw new ApiError('Chaque FAQ doit avoir une question et une réponse', 400);
        }
    }

    // Récupérer la résidence
    const residence = await Residence.findById(id);
    if (!residence) {
        throw new ApiError('Résidence non trouvée', 404);
    }

    // Vérifier que l'utilisateur est le propriétaire de la résidence
    if (residence.partner.toString() !== req.user.id) {
        throw new ApiError('Vous n\'êtes pas autorisé à modifier cette résidence', 403);
    }

    // Mettre à jour les FAQs
    residence.faqs = faqs;
    await residence.save();

    res.status(200).json({
        success: true,
        data: residence.faqs
    });
});
