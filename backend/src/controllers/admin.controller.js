const User = require('../models/user.model');
const Partner = require('../models/partner.model');
const Residence = require('../models/residence.model');
const { normalizeResidenceType } = require('../constants/residenceTypes.manifest');
const Reservation = require('../models/reservation.model');
const Payment = require('../models/payment.model');
const ActivityLog = require('../models/activityLog.model'); // Added this line
const statsService = require('../services/stats.service');
const availabilityService = require('../services/availability.service');
const asyncHandler = require('../middlewares/async.middleware');
const { pickUserSafePatch } = require('../security/roles');
const { isStaff, assertCanRevokeSuperadmin } = require('../security/staff-guard');
const superAdminService = require('../services/superadmin.service');
const ApiError = require('../utils/apiError');

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

    const block = await availabilityService.blockDates(
        residenceId,
        { startDate, endDate },
        null,
        null,
        req.user
    );

    res.status(200).json({
        success: true,
        data: block,
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

    const released = await availabilityService.unblockDates(
        residenceId,
        { startDate, endDate },
        req.user
    );

    res.status(200).json({
        success: true,
        data: released,
        message: 'Dates débloquées avec succès'
    });
});

// Gestion des utilisateurs
exports.getAllUsers = asyncHandler(async (req, res) => {
    // Les "clients" côté admin panel correspondent au role 'client' (et non 'user')
    const users = await User.find({ role: 'client' }).select('-password');
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
    const target = await User.findById(req.params.id);
    if (!target) {
        throw new ApiError('Utilisateur non trouvé', 404);
    }
    if (isStaff(target.role) && req.user.role !== 'superadmin') {
        throw new ApiError('Les comptes staff se gèrent via les endpoints Superadmin', 403);
    }

    const allowActive = req.user && req.user.role === 'superadmin';
    const patch = pickUserSafePatch(req.body, { allowActive });
    if (patch.isActive === false) {
        await assertCanRevokeSuperadmin(target);
    }
    const user = await User.findByIdAndUpdate(
        req.params.id,
        { $set: patch },
        { new: true, runValidators: true }
    ).select('-password');

    res.status(200).json({
        success: true,
        data: user
    });
});

exports.deleteUser = asyncHandler(async (req, res) => {
    const target = await User.findById(req.params.id);
    if (!target) {
        throw new ApiError('Utilisateur non trouvé', 404);
    }
    if (isStaff(target.role)) {
        throw new ApiError('Les comptes staff se suppriment via DELETE /admins/:id (Superadmin)', 403);
    }

    await User.findByIdAndDelete(req.params.id);

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
    const admin = await superAdminService.createAdmin(req.body, req.user, req);
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
    const admin = await superAdminService.updateAdmin(req.params.id, req.body, req.user, req);
    if (!admin) {
        throw new ApiError('Administrateur non trouvé', 404);
    }
    res.status(200).json({
        success: true,
        data: admin
    });
});

exports.deleteAdmin = asyncHandler(async (req, res) => {
    const admin = await superAdminService.deleteAdmin(req.params.id, req.user, req);
    if (!admin) {
        throw new ApiError('Administrateur non trouvé', 404);
    }
    res.status(200).json({
        success: true,
        message: 'Administrateur supprimé avec succès'
    });
});

// Gestion des partenaires
exports.getAllPartners = asyncHandler(async (req, res) => {
    // Les partenaires sont stockés dans la collection User via role ('partner' / 'partner_pending').
    // Partner.find() peut retourner vide si les docs ne sont pas créés avec le discriminator.
    const partners = await User.find({
        role: { $in: ['partner', 'partner_pending', 'owner'] }
    }).select('-password');
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
    const patch = pickUserSafePatch(req.body, { allowActive: req.user && req.user.role === 'superadmin' });
    const partner = await Partner.findByIdAndUpdate(
        req.params.id,
        { $set: patch },
        { new: true, runValidators: true }
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
    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limit = Math.min(100, Math.max(1, parseInt(req.query.limit, 10) || 50));

    const filter = { deleted: { $ne: true } };

    if (req.query.type) {
        const canonical = normalizeResidenceType(String(req.query.type));
        if (canonical) filter.type = canonical;
    }
    if (req.query.status && String(req.query.status).trim()) {
        filter.status = String(req.query.status).trim();
    }

    const minBedrooms = req.query.minBedrooms;
    if (minBedrooms !== undefined && minBedrooms !== null && String(minBedrooms).trim() !== '') {
        const n = Number(minBedrooms);
        if (!Number.isNaN(n)) filter.bedrooms = { $gte: n };
    }

    const priceCond = {};
    const minPrice = req.query.minPrice;
    const maxPrice = req.query.maxPrice;
    if (minPrice !== undefined && minPrice !== null && String(minPrice).trim() !== '') {
        const n = Number(minPrice);
        if (!Number.isNaN(n)) priceCond.$gte = n;
    }
    if (maxPrice !== undefined && maxPrice !== null && String(maxPrice).trim() !== '') {
        const n = Number(maxPrice);
        if (!Number.isNaN(n)) priceCond.$lte = n;
    }
    if (Object.keys(priceCond).length) filter.price = priceCond;

    const and = [];

    const cityQ = req.query.city;
    if (cityQ && String(cityQ).trim()) {
        const esc = String(cityQ).trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        const rx = new RegExp(esc, 'i');
        and.push({ $or: [{ city: rx }, { 'locationData.city': rx }] });
    }

    const searchQ = req.query.search;
    if (searchQ && String(searchQ).trim()) {
        const esc = String(searchQ).trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        const rx = new RegExp(esc, 'i');
        and.push({
            $or: [
                { title: rx },
                { description: rx },
                { address: rx },
                { city: rx },
                { 'locationData.city': rx },
            ],
        });
    }

    if (and.length) filter.$and = and;

    const skip = (page - 1) * limit;

    const [data, total] = await Promise.all([
        Residence.find(filter)
            .populate('partner', 'name email')
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit)
            .lean(),
        Residence.countDocuments(filter),
    ]);

    res.status(200).json({
        success: true,
        data,
        pagination: {
            page,
            limit,
            total,
            pages: Math.max(1, Math.ceil(total / limit)),
        },
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
        // Le modèle de résidence n'accepte que 'available'/'unavailable'/'maintenance'
        { status: 'available' },
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
            // Pas d'enum 'rejected' sur Residence.status — indisponible + motif
            status: 'unavailable',
            rejectionReason: reason
        },
        { new: true, runValidators: true }
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
    // Ne pas écrire status:'verified' (invalide) — champ booléen dédié
    const residence = await Residence.findById(req.params.id);

    if (!residence) {
        return res.status(404).json({
            success: false,
            message: 'Résidence non trouvée'
        });
    }

    const publication = require('../services/residence-publication.service');
    await publication.markPublished(residence, req.user);

    // Réparer un status corrompu éventuel (ex. "verified" / "rejected")
    if (!['available', 'unavailable', 'maintenance'].includes(residence.status)) {
        residence.status = 'available';
    }

    await residence.save();

    res.status(200).json({
        success: true,
        data: residence
    });
});

// Récupérer les logs d'activité
/**
 * Liste des paiements (admin) — source de vérité collection Payment
 * GET /api/admin/payments
 */
exports.getPayments = asyncHandler(async (req, res) => {
    const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
    const limit = Math.min(parseInt(req.query.limit, 10) || 20, 100);
    const skip = (page - 1) * limit;
    const filter = {};

    if (req.query.status) {
        const statusMap = {
            completed: 'paid',
            paid: 'paid',
            pending: 'pending',
            failed: 'failed',
            refunded: 'refunded',
        };
        filter.status = statusMap[req.query.status] || req.query.status;
    }

    if (req.query.paymentMethod) {
        filter.paymentMethod = req.query.paymentMethod;
    }

    const [payments, total] = await Promise.all([
        Payment.find(filter)
            .populate({
                path: 'reservation',
                populate: [{ path: 'user', select: 'firstName lastName email phone' }, { path: 'residence', select: 'title name' }],
            })
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit),
        Payment.countDocuments(filter),
    ]);

    res.status(200).json({
        success: true,
        data: payments,
        pagination: {
            page,
            limit,
            total,
            hasNext: skip + payments.length < total,
        },
    });
});

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
