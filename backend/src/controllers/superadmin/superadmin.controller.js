const User = require('../../models/user.model');
const Client = require('../../models/user.model');  // Les clients sont des utilisateurs avec role: 'client'
const Partner = require('../../models/user.model');  // Les partenaires sont des utilisateurs avec role: 'partner'
const SystemSetting = require('../../models/systemSetting.model');
const ActivityLog = require('../../models/activityLog.model');
const LoginAttempt = require('../../models/loginAttempt.model');
const BlockedIP = require('../../models/blockedIP.model');
const superAdminService = require('../../services/superadmin.service');
const asyncHandler = require('../../middlewares/async.middleware');

// Gestion des administrateurs
exports.getAllAdmins = asyncHandler(async (req, res) => {
    const admins = await superAdminService.getAllAdmins();
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
    const admin = await superAdminService.getAdminById(req.params.id);
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
    const admin = await superAdminService.deleteAdmin(req.params.id, req.user, req);
    if (!admin) {
        return res.status(404).json({
            success: false,
            message: 'Administrateur non trouvé'
        });
    }
    res.status(200).json({
        success: true,
        data: {}
    });
});

// Gestion des clients et partenaires
exports.getAllClients = asyncHandler(async (req, res) => {
    const clients = await User.find({ role: 'client' }).select('-password');
    res.status(200).json({
        success: true,
        data: clients
    });
});

exports.getAllPartners = asyncHandler(async (req, res) => {
    const partners = await User.find({ role: 'partner' }).select('-password');
    res.status(200).json({
        success: true,
        data: partners
    });
});

// Gestion des paramètres système
exports.getSystemSettings = asyncHandler(async (req, res) => {
    const settings = await SystemSetting.find();
    res.status(200).json({
        success: true,
        data: settings
    });
});

exports.changeUserRole = asyncHandler(async (req, res) => {
    const { role, reason } = req.body;
    const user = await superAdminService.changeUserRole(
        req.params.id,
        role,
        reason,
        req.user,
        req
    );
    res.status(200).json({
        success: true,
        data: user,
    });
});

exports.updateSystemSettings = asyncHandler(async (req, res) => {
    const updatedSettings = await superAdminService.applySettingsPatch(req.body, req.user, req);

    res.status(200).json({
        success: true,
        data: updatedSettings
    });
});

// Gestion des journaux d'activité
exports.getActivityLogs = asyncHandler(async (req, res) => {
    const { page = 1, limit = 10, startDate, endDate, type } = req.query;
    const query = {};

    if (startDate && endDate) {
        query.createdAt = {
            $gte: new Date(startDate),
            $lte: new Date(endDate)
        };
    }

    if (type) {
        query.type = type;
    }

    const logs = await ActivityLog.find(query)
        .sort({ createdAt: -1 })
        .limit(limit * 1)
        .skip((page - 1) * limit);

    const count = await ActivityLog.countDocuments(query);

    res.status(200).json({
        success: true,
        data: logs,
        pagination: {
            total: count,
            pages: Math.ceil(count / limit),
            page: page,
            limit: limit
        }
    });
});

exports.clearActivityLogs = asyncHandler(async (req, res) => {
    await ActivityLog.deleteMany({});
    res.status(200).json({
        success: true,
        message: 'Tous les journaux d\'activité ont été supprimés'
    });
});

// Gestion des tentatives de connexion
exports.getLoginAttempts = asyncHandler(async (req, res) => {
    const { page = 1, limit = 10 } = req.query;
    
    const attempts = await LoginAttempt.find()
        .sort({ attemptedAt: -1 })
        .limit(limit * 1)
        .skip((page - 1) * limit);

    const count = await LoginAttempt.countDocuments();

    res.status(200).json({
        success: true,
        data: attempts,
        pagination: {
            total: count,
            pages: Math.ceil(count / limit),
            page: page,
            limit: limit
        }
    });
});

exports.clearLoginAttempts = asyncHandler(async (req, res) => {
    await LoginAttempt.deleteMany({});
    res.status(200).json({
        success: true,
        message: 'Toutes les tentatives de connexion ont été supprimées'
    });
});

// Gestion des IP bloquées
exports.getBlockedIPs = asyncHandler(async (req, res) => {
    const blockedIPs = await BlockedIP.find()
        .sort({ blockedAt: -1 });

    res.status(200).json({
        success: true,
        data: blockedIPs
    });
});

exports.blockIP = asyncHandler(async (req, res) => {
    const { ip, reason } = req.body;

    const blockedIP = await BlockedIP.create({
        ip,
        reason,
        blockedAt: Date.now()
    });

    res.status(201).json({
        success: true,
        data: blockedIP
    });
});

exports.unblockIP = asyncHandler(async (req, res) => {
    const ip = await BlockedIP.findOneAndDelete({ ip: req.params.ip });

    if (!ip) {
        return res.status(404).json({
            success: false,
            message: 'IP non trouvée'
        });
    }

    res.status(200).json({
        success: true,
        data: {}
    });
});

// Rapports système
exports.getSystemReport = asyncHandler(async (req, res) => {
    const report = await superAdminService.getSystemReport();
    res.status(200).json({
        success: true,
        data: report
    });
});

exports.getSecurityReport = asyncHandler(async (req, res) => {
    const report = await superAdminService.getSecurityReport();
    res.status(200).json({
        success: true,
        data: report
    });
});

exports.getPerformanceReport = asyncHandler(async (req, res) => {
    const report = await superAdminService.getPerformanceReport();
    res.status(200).json({
        success: true,
        data: report
    });
});
