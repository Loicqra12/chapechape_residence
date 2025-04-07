const Partner = require('../../models/partner.model');
const User = require('../../models/user.model');
const Residence = require('../../models/residence.model');
const Booking = require('../../models/booking.model');
const Payment = require('../../models/payment.model');
const statsService = require('../../services/stats.service');
const dashboardService = require('../../services/dashboard.service');
const ApiError = require('../../utils/apiError');
const asyncHandler = require('../../middlewares/async.middleware');

// Obtenir le profil du partenaire
exports.getPartnerProfile = asyncHandler(async (req, res) => {
    const user = await User.findById(req.user.id).select('-password');
    res.status(200).json({
        success: true,
        data: user
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
        
        // Gérer l'upload de photo de profil avec une meilleure gestion d'erreur
        if (req.files) {
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
        if (updateData.phone) user.phoneNumber = updateData.phone;
        if (updateData.address) user.address = updateData.address;
        if (updateData.profileImage) user.profileImage = updateData.profileImage;

        // Sauvegarder les modifications
        await user.save();

        // Construire les URLs complètes pour les fichiers
        if (user.profileImage && user.profileImage !== 'default.jpg') {
            user.profileImage = `/uploads/profiles/${user.profileImage}`;
        }
        
        res.status(200).json({
            success: true,
            data: user
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
        
        // Récupérer le partenaire actuel
        const partner = await Partner.findById(req.user.id);
        
        // Créer un nouveau document
        const newDocument = {
            type: documentType,
            url: req.file.filename,
            verified: false,
            uploadedAt: new Date()
        };
        
        // Ajouter le document à la liste
        const existingDocs = partner.documents || [];
        partner.documents = [...existingDocs, newDocument];
        
        // Sauvegarder le partenaire
        await partner.save();
        
        // URL du document
        const documentUrl = `/uploads/documents/${req.file.filename}`;
        
        res.status(200).json({
            success: true,
            data: {
                document: {
                    ...newDocument.toObject(),
                    url: documentUrl
                },
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

// Obtenir les réservations des résidences du partenaire
exports.getPartnerBookings = asyncHandler(async (req, res) => {
    const residences = await Residence.find({ partner: req.user.id });
    const residenceIds = residences.map(residence => residence._id);

    const bookings = await Booking.find({
        residence: { $in: residenceIds }
    }).populate('residence user');

    res.status(200).json({
        success: true,
        data: bookings
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

// Revenus
exports.getEarnings = asyncHandler(async (req, res) => {
    const partnerId = req.user.id;
    const { startDate, endDate } = req.query;

    const earnings = await Payment.aggregate([
        {
            $match: {
                partner: partnerId,
                status: 'completed',
                createdAt: {
                    ...(startDate && { $gte: new Date(startDate) }),
                    ...(endDate && { $lte: new Date(endDate) })
                }
            }
        },
        {
            $group: {
                _id: {
                    year: { $year: '$createdAt' },
                    month: { $month: '$createdAt' }
                },
                totalEarnings: { $sum: '$amount' },
                count: { $sum: 1 }
            }
        },
        {
            $sort: { '_id.year': -1, '_id.month': -1 }
        }
    ]);

    res.status(200).json({
        success: true,
        data: earnings
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
