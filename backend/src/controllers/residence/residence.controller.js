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
            
            const images = req.files.map(file => `/uploads/${file.filename}`);
            
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

    const images = req.files.map(file => `/uploads/${file.filename}`);

    residence.images = [...residence.images, ...images];
    await residence.save();

    res.status(200).json({
        success: true,
        data: residence.toObject()
    });
});
