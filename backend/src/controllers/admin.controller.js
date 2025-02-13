const User = require('../models/user.model');
const Partner = require('../models/partner.model');
const Residence = require('../models/residence.model');
const Reservation = require('../models/reservation.model');
const Payment = require('../models/payment.model');
const ActivityLog = require('../models/activityLog.model'); // Added this line
const statsService = require('../services/stats.service');
const availabilityService = require('../services/availability.service');
const asyncHandler = require('../middlewares/async.middleware');

// Dashboard et statistiques
exports.getDashboardStats = asyncHandler(async (req, res) => {
    const stats = await statsService.getAdminStats();
    
    res.status(200).json({
        success: true,
        data: stats
    });
});

// Statistiques avancées
exports.getAdvancedStats = asyncHandler(async (req, res) => {
    const { startDate, endDate } = req.query;
    
    const [mostViewed, mostBooked, revenue] = await Promise.all([
        statsService.getMostViewedResidences(5),
        statsService.getMostBookedResidences(5),
        statsService.getGlobalRevenue(startDate, endDate)
    ]);

    res.status(200).json({
        success: true,
        data: {
            mostViewedResidences: mostViewed,
            mostBookedResidences: mostBooked,
            revenueStats: revenue
        }
    });
});

// Gestion des disponibilités
exports.getResidenceAvailability = asyncHandler(async (req, res) => {
    const { residenceId } = req.params;
    const { startDate, endDate } = req.query;

    const availability = await availabilityService.getBlockedDates(
        residenceId,
        startDate,
        endDate
    );

    res.status(200).json({
        success: true,
        data: availability
    });
});

exports.blockResidenceDates = asyncHandler(async (req, res) => {
    const { residenceId } = req.params;
    const { startDate, endDate } = req.body;

    if (!startDate || !endDate) {
        return res.status(400).json({
            success: false,
            message: 'Les dates de début et de fin sont requises'
        });
    }

    const residence = await availabilityService.blockDates(residenceId, { startDate, endDate });

    res.status(200).json({
        success: true,
        data: residence,
        message: 'Dates bloquées avec succès'
    });
});

exports.unblockResidenceDates = asyncHandler(async (req, res) => {
    const { residenceId } = req.params;
    const { startDate, endDate } = req.body;

    if (!startDate || !endDate) {
        return res.status(400).json({
            success: false,
            message: 'Les dates de début et de fin sont requises'
        });
    }

    const residence = await availabilityService.unblockDates(residenceId, { startDate, endDate });

    res.status(200).json({
        success: true,
        data: residence,
        message: 'Dates débloquées avec succès'
    });
});

// Gestion des utilisateurs
exports.getAllUsers = asyncHandler(async (req, res) => {
    const users = await User.find({ role: 'user' }).select('-password');
    res.status(200).json({
        success: true,
        data: users
    });
});

exports.getUser = asyncHandler(async (req, res) => {
    const user = await User.findById(req.params.id).select('-password');
    
    if (!user) {
        return res.status(404).json({
            success: false,
            message: 'Utilisateur non trouvé'
        });
    }

    res.status(200).json({
        success: true,
        data: user
    });
});

exports.updateUser = asyncHandler(async (req, res) => {
    const user = await User.findByIdAndUpdate(
        req.params.id,
        { $set: req.body },
        { new: true, runValidators: true }
    ).select('-password');

    if (!user) {
        return res.status(404).json({
            success: false,
            message: 'Utilisateur non trouvé'
        });
    }

    res.status(200).json({
        success: true,
        data: user
    });
});

exports.deleteUser = asyncHandler(async (req, res) => {
    const user = await User.findByIdAndDelete(req.params.id);

    if (!user) {
        return res.status(404).json({
            success: false,
            message: 'Utilisateur non trouvé'
        });
    }

    res.status(200).json({
        success: true,
        data: {}
    });
});

// Gestion des administrateurs
exports.getAllAdmins = asyncHandler(async (req, res) => {
    const admins = await User.find({ role: 'admin' }).select('-password');
    res.status(200).json({
        success: true,
        data: admins
    });
});

exports.createAdmin = asyncHandler(async (req, res) => {
    const admin = await User.create({
        ...req.body,
        role: 'admin'
    });
    res.status(201).json({
        success: true,
        data: admin
    });
});

exports.getAdmin = asyncHandler(async (req, res) => {
    const admin = await User.findOne({ 
        _id: req.params.id,
        role: 'admin'
    }).select('-password');

    if (!admin) {
        return res.status(404).json({
            success: false,
            message: 'Administrateur non trouvé'
        });
    }

    res.status(200).json({
        success: true,
        data: admin
    });
});

exports.updateAdmin = asyncHandler(async (req, res) => {
    const admin = await User.findOneAndUpdate(
        { _id: req.params.id, role: 'admin' },
        req.body,
        { new: true }
    ).select('-password');

    if (!admin) {
        return res.status(404).json({
            success: false,
            message: 'Administrateur non trouvé'
        });
    }

    res.status(200).json({
        success: true,
        data: admin
    });
});

exports.deleteAdmin = asyncHandler(async (req, res) => {
    const admin = await User.findOneAndDelete({
        _id: req.params.id,
        role: 'admin'
    });

    if (!admin) {
        return res.status(404).json({
            success: false,
            message: 'Administrateur non trouvé'
        });
    }

    res.status(200).json({
        success: true,
        message: 'Administrateur supprimé avec succès'
    });
});

// Gestion des partenaires
exports.getAllPartners = asyncHandler(async (req, res) => {
    const partners = await Partner.find();
    res.status(200).json({
        success: true,
        data: partners
    });
});

exports.getPartner = asyncHandler(async (req, res) => {
    const partner = await Partner.findById(req.params.id);
    
    if (!partner) {
        return res.status(404).json({
            success: false,
            message: 'Partenaire non trouvé'
        });
    }

    res.status(200).json({
        success: true,
        data: partner
    });
});

exports.updatePartner = asyncHandler(async (req, res) => {
    const partner = await Partner.findByIdAndUpdate(
        req.params.id,
        req.body,
        { new: true }
    );

    if (!partner) {
        return res.status(404).json({
            success: false,
            message: 'Partenaire non trouvé'
        });
    }

    res.status(200).json({
        success: true,
        data: partner
    });
});

exports.deletePartner = asyncHandler(async (req, res) => {
    const partner = await Partner.findByIdAndDelete(req.params.id);

    if (!partner) {
        return res.status(404).json({
            success: false,
            message: 'Partenaire non trouvé'
        });
    }

    res.status(200).json({
        success: true,
        data: {}
    });
});

exports.verifyPartner = asyncHandler(async (req, res) => {
    const partner = await Partner.findByIdAndUpdate(
        req.params.id,
        { verificationStatus: 'verified' },
        { new: true }
    );

    if (!partner) {
        return res.status(404).json({
            success: false,
            message: 'Partenaire non trouvé'
        });
    }

    res.status(200).json({
        success: true,
        data: partner
    });
});

// Gestion des résidences
exports.getResidences = asyncHandler(async (req, res) => {
    const residences = await Residence.find()
        .sort({ createdAt: -1 });

    res.status(200).json({
        success: true,
        data: residences
    });
});

exports.getResidenceById = asyncHandler(async (req, res) => {
    const residence = await Residence.findById(req.params.id);

    if (!residence) {
        return res.status(404).json({
            success: false,
            message: 'Résidence non trouvée'
        });
    }

    res.status(200).json(residence);
});

exports.createResidence = asyncHandler(async (req, res) => {
    const {
        title,
        description,
        address,
        city,
        price,
        bedrooms,
        bathrooms,
        surface,
        isAvailable
    } = req.body;

    // Créer un log d'activité
    await ActivityLog.create({
        user: req.user._id,
        action: 'Création',
        module: 'residence',
        description: `Création de la résidence: ${title}`,
        status: 'success'
    });

    const residence = await Residence.create({
        title,
        description,
        address,
        city,
        price,
        bedrooms,
        bathrooms,
        surface,
        isAvailable,
        createdBy: req.user._id
    });

    res.status(201).json({
        success: true,
        data: residence
    });
});

exports.updateResidence = asyncHandler(async (req, res) => {
    let residence = await Residence.findById(req.params.id);

    if (!residence) {
        return res.status(404).json({
            success: false,
            message: 'Résidence non trouvée'
        });
    }

    residence = await Residence.findByIdAndUpdate(
        req.params.id,
        req.body,
        {
            new: true,
            runValidators: true
        }
    );

    // Créer un log d'activité
    await ActivityLog.create({
        user: req.user._id,
        action: 'Mise à jour',
        module: 'residence',
        description: `Mise à jour de la résidence: ${residence.title}`,
        status: 'success'
    });

    res.status(200).json({
        success: true,
        data: residence
    });
});

exports.deleteResidence = asyncHandler(async (req, res) => {
    const residence = await Residence.findById(req.params.id);

    if (!residence) {
        return res.status(404).json({
            success: false,
            message: 'Résidence non trouvée'
        });
    }

    // Créer un log d'activité avant la suppression
    await ActivityLog.create({
        user: req.user._id,
        action: 'Suppression',
        module: 'residence',
        description: `Suppression de la résidence: ${residence.title}`,
        status: 'success'
    });

    await residence.remove();

    res.status(200).json({
        success: true,
        message: 'Résidence supprimée avec succès'
    });
});

exports.getAllResidences = asyncHandler(async (req, res) => {
    const residences = await Residence.find().populate('partner', 'name email');
    
    res.status(200).json({
        success: true,
        data: residences
    });
});

exports.getPendingResidences = asyncHandler(async (req, res) => {
    const residences = await Residence.find({ status: 'pending' })
        .populate('partner', 'name email');
    
    res.status(200).json({
        success: true,
        data: residences
    });
});

exports.getResidence = asyncHandler(async (req, res) => {
    const residence = await Residence.findById(req.params.id)
        .populate('partner', 'name email');

    if (!residence) {
        return res.status(404).json({
            success: false,
            message: 'Résidence non trouvée'
        });
    }

    res.status(200).json({
        success: true,
        data: residence
    });
});

exports.validateResidence = asyncHandler(async (req, res) => {
    const residence = await Residence.findByIdAndUpdate(
        req.params.id,
        { status: 'approved' },
        { new: true }
    );

    if (!residence) {
        return res.status(404).json({
            success: false,
            message: 'Résidence non trouvée'
        });
    }

    res.status(200).json({
        success: true,
        data: residence
    });
});

exports.rejectResidence = asyncHandler(async (req, res) => {
    const { reason } = req.body;
    const residence = await Residence.findByIdAndUpdate(
        req.params.id,
        { 
            status: 'rejected',
            rejectionReason: reason
        },
        { new: true }
    );

    if (!residence) {
        return res.status(404).json({
            success: false,
            message: 'Résidence non trouvée'
        });
    }

    res.status(200).json({
        success: true,
        data: residence
    });
});

exports.verifyResidence = asyncHandler(async (req, res) => {
    const residence = await Residence.findByIdAndUpdate(
        req.params.id,
        { 
            status: 'verified',
            verifiedAt: Date.now(),
            verifiedBy: req.user.id
        },
        { new: true }
    );

    if (!residence) {
        return res.status(404).json({
            success: false,
            message: 'Résidence non trouvée'
        });
    }

    res.status(200).json({
        success: true,
        data: residence
    });
});

// Récupérer les logs d'activité
exports.getActivityLogs = asyncHandler(async (req, res) => {
    const activityLogs = await ActivityLog.find()
        .populate('user', 'firstName lastName email')
        .sort({ createdAt: -1 })
        .limit(5);

    const formattedLogs = activityLogs.map(log => ({
        id: log._id,
        type: log.module,
        title: log.description,
        description: log.action,
        timestamp: log.createdAt,
        metadata: log.metadata
    }));

    res.status(200).json(formattedLogs);
});
