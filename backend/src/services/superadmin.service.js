const User = require('../models/user.model');
const SystemSetting = require('../models/systemSetting.model');
const ActivityLog = require('../models/activityLog.model');
const LoginAttempt = require('../models/loginAttempt.model');
const BlockedIP = require('../models/blockedIP.model');
const mongoose = require('mongoose');
const Residence = require('../models/residence.model');
const Reservation = require('../models/reservation.model');
const Payment = require('../models/payment.model');
const {
    pickAdminCreateFields,
    pickUserSafePatch,
    pickSettingsPatch,
    SETTINGS_WHITELIST,
    withSuperadminMutex,
    assertCanRevokeSuperadmin,
    assertValidRole,
} = require('../security/staff-guard');
const { ROLES } = require('../security/roles');
const { logStaffAction } = require('./staff-audit.service');
const ApiError = require('../utils/apiError');

class SuperAdminService {
    async getAllAdmins() {
        return await User.find({ role: { $in: ['admin', 'superadmin'] } }).select('-password');
    }

    async createAdmin(adminData, actor, req) {
        const fields = pickAdminCreateFields(adminData);
        if (!fields.email || !fields.password || !fields.firstName || !fields.lastName) {
            throw new ApiError('email, password, firstName et lastName requis', 400);
        }
        const admin = await User.create(fields);
        await logStaffAction({
            actor,
            action: 'admin_created',
            entityType: 'user',
            entityId: admin._id,
            reason: adminData.reason,
            before: {},
            after: { role: admin.role, email: admin.email },
            req,
        });
        return User.findById(admin._id).select('-password');
    }

    async getAdminById(id) {
        return await User.findOne({ _id: id, role: { $in: ['admin', 'superadmin'] } }).select('-password');
    }

    async updateAdmin(id, updateData, actor, req) {
        return withSuperadminMutex(async (session) => {
            const target = await User.findOne({ _id: id, role: { $in: ['admin', 'superadmin'] } }).session(session);
            if (!target) return null;
            const patch = pickUserSafePatch(updateData, { allowActive: true });
            if (patch.isActive === false) {
                await assertCanRevokeSuperadmin(target, session);
            }
            const before = { isActive: target.isActive };
            Object.assign(target, patch);
            await target.save({ session });
            if (patch.isActive === false) {
                await logStaffAction({
                    actor,
                    action: 'admin_disabled',
                    entityType: 'user',
                    entityId: target._id,
                    reason: updateData.reason,
                    before,
                    after: { isActive: false },
                    req,
                });
            }
            return User.findById(target._id).session(session).select('-password');
        });
    }

    async deleteAdmin(id, actor, req) {
        return withSuperadminMutex(async (session) => {
            const target = await User.findById(id).session(session);
            if (!target || !['admin', 'superadmin'].includes(target.role)) {
                return null;
            }
            await assertCanRevokeSuperadmin(target, session);
            await User.deleteOne({ _id: id }).session(session);
            await logStaffAction({
                actor,
                action: 'admin_deleted',
                entityType: 'user',
                entityId: target._id,
                reason: 'delete_admin',
                before: { role: target.role, email: target.email },
                after: {},
                req,
            });
            return target;
        });
    }

    async changeUserRole(id, nextRole, reason, actor, req) {
        assertValidRole(nextRole);
        return withSuperadminMutex(async (session) => {
            const target = await User.findById(id).session(session);
            if (!target) {
                throw new ApiError('Utilisateur introuvable', 404);
            }
            if (target.role === ROLES.SUPERADMIN && nextRole !== ROLES.SUPERADMIN) {
                await assertCanRevokeSuperadmin(target, session);
            }
            const before = { role: target.role };
            target.role = nextRole;
            await target.save({ session });
            await logStaffAction({
                actor,
                action: 'role_changed',
                entityType: 'user',
                entityId: target._id,
                reason,
                before,
                after: { role: nextRole },
                req,
            });
            return User.findById(target._id).session(session).select('-password');
        });
    }

    async applySettingsPatch(body, actor, req) {
        const { allowed, rejected } = pickSettingsPatch(body);
        if (rejected.length) {
            throw new ApiError(`Clés settings non autorisées: ${rejected.join(', ')}`, 400);
        }
        const updatedSettings = [];
        for (const [key, value] of Object.entries(allowed)) {
            const meta = SETTINGS_WHITELIST[key];
            const beforeDoc = await SystemSetting.findOne({ key });
            const setting = await SystemSetting.findOneAndUpdate(
                { key },
                {
                    value,
                    description: beforeDoc?.description || key,
                    type: meta.type,
                    category: meta.category,
                    updatedBy: actor._id,
                },
                { new: true, upsert: true, setDefaultsOnInsert: true }
            );
            updatedSettings.push(setting);
            await logStaffAction({
                actor,
                action: 'settings_changed',
                entityType: 'setting',
                entityId: setting._id,
                reason: body.reason,
                before: { key, value: beforeDoc?.value },
                after: { key, value },
                req,
            });
        }
        return updatedSettings;
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
