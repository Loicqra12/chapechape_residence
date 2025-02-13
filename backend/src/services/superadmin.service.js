const User = require('../models/user.model');
const SystemSetting = require('../models/systemSetting.model');
const ActivityLog = require('../models/activityLog.model');
const LoginAttempt = require('../models/loginAttempt.model');
const BlockedIP = require('../models/blockedIP.model');
const mongoose = require('mongoose');
const Residence = require('../models/residence.model');
const Reservation = require('../models/reservation.model');
const Payment = require('../models/payment.model');

class SuperAdminService {
    // Gestion des administrateurs
    async getAllAdmins() {
        return await User.find({ role: 'admin' }).select('-password');
    }

    async createAdmin(adminData) {
        return await User.create({ ...adminData, role: 'admin' });
    }

    async getAdminById(id) {
        return await User.findOne({ _id: id, role: 'admin' }).select('-password');
    }

    async updateAdmin(id, updateData) {
        return await User.findOneAndUpdate(
            { _id: id, role: 'admin' },
            updateData,
            { new: true }
        ).select('-password');
    }

    async deleteAdmin(id) {
        return await User.findOneAndDelete({ _id: id, role: 'admin' });
    }

    // Configuration système
    async getSystemSettings() {
        return await SystemSetting.find();
    }

    async updateSystemSetting(key, value, description, type, category) {
        const setting = await SystemSetting.findOne({ key });
        
        if (!setting) {
            // Créer un nouveau paramètre s'il n'existe pas
            return await SystemSetting.create({
                key,
                value,
                description,
                type,
                category,
                isPublic: false
            });
        }

        // Mettre à jour le paramètre existant
        setting.value = value;
        if (description) setting.description = description;
        if (type) setting.type = type;
        if (category) setting.category = category;
        
        return await setting.save();
    }

    // Sécurité
    async getActivityLogs(filters = {}) {
        const query = {};
        if (filters.startDate) query.createdAt = { $gte: new Date(filters.startDate) };
        if (filters.endDate) query.createdAt = { ...query.createdAt, $lte: new Date(filters.endDate) };
        if (filters.status) query.status = filters.status;
        if (filters.module) query.module = filters.module;

        return await ActivityLog.find(query)
            .sort({ createdAt: -1 })
            .populate('user', 'firstName lastName email');
    }

    async getLoginAttempts(filters = {}) {
        const query = {};
        if (filters.startDate) query.createdAt = { $gte: new Date(filters.startDate) };
        if (filters.endDate) query.createdAt = { ...query.createdAt, $lte: new Date(filters.endDate) };
        if (filters.status) query.status = filters.status;

        return await LoginAttempt.find(query).sort({ createdAt: -1 });
    }

    async getBlockedIPs() {
        return await BlockedIP.find().sort({ createdAt: -1 });
    }

    async blockIP(data) {
        const { ip, reason, blockedBy } = data;
        return await BlockedIP.create({
            ip,
            reason,
            blockedBy
        });
    }

    async unblockIP(ip) {
        return await BlockedIP.findOneAndDelete({ ip });
    }

    // Rapports
    async getSystemReport() {
        const [
            usersCount,
            adminsCount,
            residencesCount,
            reservationsCount,
            settings
        ] = await Promise.all([
            User.countDocuments({ role: 'user' }),
            User.countDocuments({ role: 'admin' }),
            Residence.countDocuments(),
            Reservation.countDocuments(),
            SystemSetting.find()
        ]);

        return {
            users: {
                total: usersCount,
                admins: adminsCount
            },
            residences: {
                total: residencesCount
            },
            reservations: {
                total: reservationsCount
            },
            settings: settings,
            systemInfo: {
                version: process.env.npm_package_version || '1.0.0',
                nodeVersion: process.version,
                platform: process.platform,
                uptime: process.uptime()
            }
        };
    }

    async getSecurityReport() {
        const [
            loginAttempts,
            blockedIPs,
            activityLogs
        ] = await Promise.all([
            LoginAttempt.countDocuments(),
            BlockedIP.countDocuments(),
            ActivityLog.countDocuments()
        ]);

        return {
            loginAttempts: {
                total: loginAttempts
            },
            blockedIPs: {
                total: blockedIPs
            },
            activityLogs: {
                total: activityLogs
            },
            lastActivities: await ActivityLog.find()
                .sort('-createdAt')
                .limit(5)
                .populate('user', 'firstName lastName email')
        };
    }

    async getPerformanceReport() {
        const startDate = new Date();
        startDate.setDate(startDate.getDate() - 7);

        const [
            avgResponseTime,
            errorRate,
            activeUsers
        ] = await Promise.all([
            ActivityLog.aggregate([
                {
                    $match: {
                        createdAt: { $gte: startDate }
                    }
                },
                {
                    $group: {
                        _id: null,
                        avgTime: { $avg: "$responseTime" }
                    }
                }
            ]),
            ActivityLog.aggregate([
                {
                    $match: {
                        createdAt: { $gte: startDate },
                        status: "error"
                    }
                },
                {
                    $group: {
                        _id: null,
                        count: { $sum: 1 }
                    }
                }
            ]),
            User.countDocuments({
                lastLogin: { $gte: startDate }
            })
        ]);

        return {
            performance: {
                avgResponseTime: avgResponseTime[0]?.avgTime || 0,
                errorRate: errorRate[0]?.count || 0,
                activeUsers
            },
            period: {
                start: startDate,
                end: new Date()
            }
        };
    }
}

module.exports = new SuperAdminService();
