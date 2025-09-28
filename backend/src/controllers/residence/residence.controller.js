const Residence = require('../../models/residence.model');
const apiError = require('../../utils/apiError');
const asyncHandler = require('../../middlewares/async');
const fs = require('fs');
const path = require('path');
const { CloudinaryService } = require('../../config/cloudinary');

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
            throw new apiError('Format de données invalide: ' + error.message, 400);
        }
    } else {
        // Approche traditionnelle (champs individuels)
        residenceData = req.body;
        residenceData.partner = req.user.id;
        console.log('Données reçues (format direct):', Object.keys(residenceData));
        console.log('Contenu complet:', residenceData);
    }
    
    // Validation manuelle des champs requis (NOUVEAU SCHÉMA)
    const requiredFields = ['title', 'description', 'price', 'type', 'bedrooms', 'bathrooms', 'maxOccupancy', 'location'];
    const missingFields = requiredFields.filter(field => {
        if (field === 'location') {
            // Vérifier la structure complète de location
            return !residenceData.location || 
                   !residenceData.location.coordinates || 
                   typeof residenceData.location.coordinates.latitude !== 'number' ||
                   typeof residenceData.location.coordinates.longitude !== 'number';
        }
        return residenceData[field] === undefined || residenceData[field] === null;
    });
    
    if (missingFields.length > 0) {
        console.error('Champs manquants (nouveau schéma):', missingFields);
        throw new apiError(`Champs requis manquants: ${missingFields.join(', ')}`, 400);
    }
    
    // MIGRATION AUTOMATIQUE : Extraire address/city/area depuis la nouvelle structure si nécessaire
    if (residenceData.location && !residenceData.address) {
        residenceData.address = residenceData.location.address || '';
        residenceData.city = residenceData.location.city || '';
        console.log('Migration automatique: address/city extraits de location');
    }
    
    // Gérer area vs surface
    if (!residenceData.area && residenceData.surface) {
        residenceData.area = residenceData.surface;
        console.log('Migration automatique: surface -> area');
    } else if (!residenceData.area) {
        residenceData.area = 0; // Valeur par défaut
    }

    try {
        // Préparer la structure de géolocalisation (NOUVEAU SCHÉMA)
        if (residenceData.location && residenceData.location.coordinates) {
            console.log('Nouvelle structure de géolocalisation détectée:', residenceData.location);
            
            // Construire la structure locationData pour MongoDB
            residenceData.locationData = {
                coordinates: {
                    latitude: parseFloat(residenceData.location.coordinates.latitude),
                    longitude: parseFloat(residenceData.location.coordinates.longitude)
                },
                formattedAddress: residenceData.location.formattedAddress || residenceData.location.address || '',
                address: residenceData.location.address || '',
                city: residenceData.location.city || '',
                country: residenceData.location.country || 'CI'
            };
            
            // Également définir les champs racine pour compatibilité avec le modèle actuel
            residenceData.latitude = parseFloat(residenceData.location.coordinates.latitude);
            residenceData.longitude = parseFloat(residenceData.location.coordinates.longitude);
            
            console.log('Structure locationData construite depuis location:', residenceData.locationData);
        } else if (residenceData.latitude !== undefined && residenceData.longitude !== undefined) {
            // Fallback pour l'ancien format (rétrocompatibilité)
            console.log('Ancien format de géolocalisation détecté (rétrocompatibilité)');
            residenceData.locationData = {
                coordinates: {
                    latitude: parseFloat(residenceData.latitude),
                    longitude: parseFloat(residenceData.longitude)
                },
                formattedAddress: residenceData.formattedAddress || '',
                address: residenceData.address || '',
                city: residenceData.city || '',
                country: residenceData.country || 'CI'
            };
        }
        
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
        throw new apiError(`Échec de la création de la résidence: ${error.message}`, 500);
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
        throw new apiError('Résidence non trouvée', 404);
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
        throw new apiError('Résidence non trouvée', 404);
    }

    // Vérifier si l'utilisateur est le propriétaire
    if (residence.partner.toString() !== req.user.id && req.user.role !== 'admin') {
        throw new apiError('Non autorisé à modifier cette résidence', 403);
    }

    // Préparer les données de mise à jour
    const updateData = { ...req.body };
    
    // Gérer la structure de géolocalisation
    console.log('Données de géolocalisation reçues:', {
        latitude: updateData.latitude,
        longitude: updateData.longitude,
        formattedAddress: updateData.formattedAddress,
        address: updateData.address,
        city: updateData.city
    });

    // Si nous avons reçu des coordonnées GPS, mettre à jour la structure locationData
    if (updateData.latitude !== undefined && updateData.longitude !== undefined) {
        // Créer/mettre à jour la structure locationData complète
        updateData.locationData = {
            coordinates: {
                latitude: parseFloat(updateData.latitude),
                longitude: parseFloat(updateData.longitude)
            },
            formattedAddress: updateData.formattedAddress || residence.locationData?.formattedAddress,
            address: updateData.address || residence.address,
            city: updateData.city || residence.city,
            country: updateData.country || residence.locationData?.country || 'CI'
        };
        
        console.log('Structure locationData mise à jour:', updateData.locationData);
    }

    residence = await Residence.findByIdAndUpdate(
        req.params.id,
        updateData,
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
        throw new apiError('Résidence non trouvée', 404);
    }

    if (residence.partner.toString() !== req.user.id && req.user.role !== 'admin') {
        throw new apiError('Non autorisé à supprimer cette résidence', 403);
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

// @desc    Ajouter des images à une résidence (supporte les fichiers physiques et les URLs Cloudinary)
// @route   POST /api/residences/:id/images
// @access  Private (Partner only)
exports.uploadImages = asyncHandler(async (req, res) => {
    console.log('==== UPLOAD IMAGES ====');
    console.log('Content-Type:', req.headers['content-type']);
    console.log('Body:', req.body);
    console.log('Files:', req.files ? req.files.length : 'Aucun');
    
    const residence = await Residence.findById(req.params.id);

    if (!residence) {
        // Supprimer les fichiers uploadés si la résidence n'existe pas
        if (req.files) {
            req.files.forEach(file => {
                if (file.path && fs.existsSync(file.path)) {
                    fs.unlinkSync(file.path);
                }
            });
        }
        throw new apiError('Résidence non trouvée', 404);
    }

    if (residence.partner.toString() !== req.user.id && req.user.role !== 'admin') {
        // Supprimer les fichiers uploadés si non autorisé
        if (req.files) {
            req.files.forEach(file => {
                if (file.path && fs.existsSync(file.path)) {
                    fs.unlinkSync(file.path);
                }
            });
        }
        throw new apiError('Non autorisé à modifier cette résidence', 403);
    }

    // Deux modes de fonctionnement :
    // 1. Upload de fichiers traditionnels (multipart/form-data)
    // 2. Envoi d'URLs Cloudinary (application/json)
    
    let newImages = [];
    
    // Mode 1: Upload de fichiers (multipart/form-data)
    if (req.files && req.files.length > 0) {
        console.log(`Traitement de ${req.files.length} fichiers uploadés`);
        
        // Si nous utilisons le stockage Cloudinary via multer, les fichiers ont déjà une URL Cloudinary
        if (req.files[0].path && req.files[0].path.startsWith('http')) {
            // Images déjà sur Cloudinary via multer-storage-cloudinary
            newImages = req.files.map(file => file.path);
            console.log('Images Cloudinary via multer:', newImages);
        } else {
            // Stockage local classique
            newImages = req.files.map(file => `/uploads/residences/${file.filename}`);
            console.log('Images locales:', newImages);
        }
    }
    // Mode 2: Envoi d'URLs (application/json)
    else if (req.body.images && Array.isArray(req.body.images)) {
        console.log(`Traitement de ${req.body.images.length} URLs d'images`);
        newImages = req.body.images;
        console.log('URLs reçues:', newImages);
    }
    // Aucune image reçue
    else {
        throw new apiError('Veuillez fournir des images (fichiers ou URLs)', 400);
    }
    
    if (newImages.length === 0) {
        throw new apiError('Aucune image valide reçue', 400);
    }

    // Ajouter les nouvelles images au tableau existant
    residence.images = [...residence.images, ...newImages];
    await residence.save();
    
    console.log(`${newImages.length} images ajoutées à la résidence ${residence._id}`);
    console.log('Total images dans la résidence:', residence.images.length);

    res.status(200).json({
        success: true,
        data: residence.toObject()
    });
});

// @desc    Supprimer une image d'une résidence
// @route   DELETE /api/residences/:id/images/:imageIndex
// @access  Private (Partner only)
exports.deleteImage = asyncHandler(async (req, res) => {
    const { id, imageIndex } = req.params;
    
    // Validation des données
    if (isNaN(imageIndex) || parseInt(imageIndex) < 0) {
        throw new apiError('Index d\'image invalide', 400);
    }
    
    const index = parseInt(imageIndex);
    
    // Récupérer la résidence
    const residence = await Residence.findById(id);
    if (!residence) {
        throw new apiError('Résidence non trouvée', 404);
    }
    
    // Vérifier l'autorisation
    if (residence.partner.toString() !== req.user.id && req.user.role !== 'admin') {
        throw new apiError('Non autorisé à modifier cette résidence', 403);
    }
    
    // Vérifier que l'index existe
    if (index >= residence.images.length) {
        throw new apiError('Image non trouvée à cet index', 404);
    }
    
    // Récupérer l'URL de l'image
    const imageUrl = residence.images[index];
    
    try {
        // Si c'est une URL Cloudinary, supprimer l'image du cloud
        if (imageUrl.includes('cloudinary.com')) {
            console.log(`Suppression de l'image Cloudinary: ${imageUrl}`);
            const publicId = CloudinaryService.getPublicIdFromUrl(imageUrl);
            
            if (publicId) {
                console.log(`PublicId extrait: ${publicId}`);
                await CloudinaryService.deleteImage(publicId);
                console.log('Image supprimée de Cloudinary avec succès');
            }
        } 
        // Si c'est un fichier local, supprimer le fichier du serveur
        else if (imageUrl.startsWith('/uploads/')) {
            const filePath = path.join(__dirname, '../../../', imageUrl);
            console.log(`Suppression du fichier local: ${filePath}`);
            
            if (fs.existsSync(filePath)) {
                fs.unlinkSync(filePath);
                console.log('Fichier local supprimé avec succès');
            }
        }
        
        // Supprimer l'URL de l'image du tableau
        residence.images.splice(index, 1);
        await residence.save();
        
        res.status(200).json({
            success: true,
            message: 'Image supprimée avec succès',
            data: residence.images
        });
    } catch (error) {
        console.error('Erreur lors de la suppression de l\'image:', error);
        throw new apiError(`Erreur lors de la suppression de l'image: ${error.message}`, 500);
    }
});

// @desc    Ajouter des points d'intérêt à proximité d'une résidence
// @route   POST /api/residences/:id/nearby-places
// @access  Private (Partner only)
exports.addNearbyPlace = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { name, type, distance, description } = req.body;

    // Validation des données
    if (!name || !type || !distance) {
        throw new apiError('Veuillez fournir le nom, le type et la distance du lieu à proximité', 400);
    }

    // Vérifier que le type est valide
    const validTypes = ['restaurant', 'bar', 'shop', 'market', 'other'];
    if (!validTypes.includes(type)) {
        throw new apiError(`Type invalide. Les types valides sont: ${validTypes.join(', ')}`, 400);
    }

    // Récupérer la résidence
    const residence = await Residence.findById(id);
    if (!residence) {
        throw new apiError('Résidence non trouvée', 404);
    }

    // Vérifier que l'utilisateur est le propriétaire de la résidence
    if (residence.partner.toString() !== req.user.id) {
        throw new apiError('Vous n\'êtes pas autorisé à modifier cette résidence', 403);
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
        throw new apiError('Veuillez fournir la question et la réponse', 400);
    }

    // Récupérer la résidence
    const residence = await Residence.findById(id);
    if (!residence) {
        throw new apiError('Résidence non trouvée', 404);
    }

    // Vérifier que l'utilisateur est le propriétaire de la résidence
    if (residence.partner.toString() !== req.user.id) {
        throw new apiError('Vous n\'êtes pas autorisé à modifier cette résidence', 403);
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
        throw new apiError('Résidence non trouvée', 404);
    }

    // Vérifier que l'utilisateur est le propriétaire de la résidence
    if (residence.partner.toString() !== req.user.id) {
        throw new apiError('Vous n\'êtes pas autorisé à modifier cette résidence', 403);
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
        throw new apiError('Veuillez fournir un tableau de méthodes de paiement', 400);
    }

    // Vérifier que les méthodes de paiement sont valides
    const validMethods = ['cash', 'wave', 'orange_money', 'moov_money', 'mtn_money', 'credit_card', 'bank_transfer'];
    const invalidMethods = paymentMethods.filter(method => !validMethods.includes(method));
    if (invalidMethods.length > 0) {
        throw new apiError(`Méthodes de paiement invalides: ${invalidMethods.join(', ')}. Les méthodes valides sont: ${validMethods.join(', ')}`, 400);
    }

    // Récupérer la résidence
    const residence = await Residence.findById(id);
    if (!residence) {
        throw new apiError('Résidence non trouvée', 404);
    }

    // Vérifier que l'utilisateur est le propriétaire de la résidence
    if (residence.partner.toString() !== req.user.id) {
        throw new apiError('Vous n\'êtes pas autorisé à modifier cette résidence', 403);
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
        throw new apiError('Veuillez fournir un tableau de points d\'intérêt', 400);
    }

    // Valider chaque point d'intérêt
    const validTypes = ['restaurant', 'bar', 'shop', 'market', 'other'];
    for (const place of nearbyPlaces) {
        if (!place.name || !place.type || place.distance === undefined) {
            throw new apiError('Chaque point d\'intérêt doit avoir un nom, un type et une distance', 400);
        }
        
        if (!validTypes.includes(place.type)) {
            throw new apiError(`Type de point d'intérêt invalide: ${place.type}. Les types valides sont: ${validTypes.join(', ')}`, 400);
        }
    }

    // Récupérer la résidence
    const residence = await Residence.findById(id);
    if (!residence) {
        throw new apiError('Résidence non trouvée', 404);
    }

    // Vérifier que l'utilisateur est le propriétaire de la résidence
    if (residence.partner.toString() !== req.user.id) {
        throw new apiError('Vous n\'êtes pas autorisé à modifier cette résidence', 403);
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
        throw new apiError('Veuillez fournir un nombre d\'étoiles valide (entre 0 et 5)', 400);
    }

    // Vérifier que l'utilisateur est un administrateur
    if (req.user.role !== 'admin') {
        throw new apiError('Seuls les administrateurs peuvent mettre à jour le nombre d\'étoiles', 403);
    }

    // Récupérer la résidence
    const residence = await Residence.findById(id);
    if (!residence) {
        throw new apiError('Résidence non trouvée', 404);
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
        throw new apiError('Veuillez fournir une note globale valide (entre 0 et 5)', 400);
    }

    // Validation des notes optionnelles
    if ((cleanliness !== undefined && (cleanliness < 0 || cleanliness > 5)) ||
        (comfort !== undefined && (comfort < 0 || comfort > 5)) ||
        (facilities !== undefined && (facilities < 0 || facilities > 5))) {
        throw new apiError('Toutes les notes doivent être comprises entre 0 et 5', 400);
    }

    // Récupérer la résidence
    const residence = await Residence.findById(id);
    if (!residence) {
        throw new apiError('Résidence non trouvée', 404);
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
        throw new apiError('Veuillez fournir un tableau de FAQs', 400);
    }

    // Valider chaque FAQ
    for (const faq of faqs) {
        if (!faq.question || !faq.answer) {
            throw new apiError('Chaque FAQ doit avoir une question et une réponse', 400);
        }
    }

    // Récupérer la résidence
    const residence = await Residence.findById(id);
    if (!residence) {
        throw new apiError('Résidence non trouvée', 404);
    }

    // Vérifier que l'utilisateur est le propriétaire de la résidence
    if (residence.partner.toString() !== req.user.id) {
        throw new apiError('Vous n\'êtes pas autorisé à modifier cette résidence', 403);
    }

    // Mettre à jour les FAQs
    residence.faqs = faqs;
    await residence.save();

    res.status(200).json({
        success: true,
        data: residence.faqs
    });
});
