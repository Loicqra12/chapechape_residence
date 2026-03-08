const ActivityLog = require('../models/activityLog.model');
const LoginAttempt = require('../models/loginAttempt.model');
const BlockedIP = require('../models/blockedIP.model');
const User = require('../models/user.model');
const logger = require('../utils/logger');
const axios = require('axios');

/**
 * Service d'audit et de sécurité avancé
 * Gère la journalisation des activités sensibles et la détection d'activités suspectes
 */
class AuditService {
    constructor() {
        this.suspiciousPatterns = {
            multipleFailedLogins: 5, // Nombre de tentatives échouées avant alerte
            unusualLocation: true,   // Détecter les connexions depuis des lieux inhabituels
            rapidActions: 10,        // Nombre d'actions rapides avant alerte
            highRiskActions: ['password_change', 'bank_account_change', 'payout_initiated']
        };
    }

    /**
     * Enregistrer une activité dans l'audit trail
     * @param {Object} params - Paramètres de l'activité
     */
    async logActivity({
        userId,
        action,
        module,
        description,
        ipAddress,
        userAgent,
        metadata = {},
        status = 'success',
        severity = 'low'
    }) {
        try {
            // Calculer le score de risque
            const riskScore = await this.calculateRiskScore({
                userId,
                action,
                ipAddress,
                userAgent,
                metadata
            });

            // Détecter les activités suspectes
            const isSuspicious = await this.detectSuspiciousActivity({
                userId,
                action,
                ipAddress,
                riskScore
            });

            // Obtenir les informations de localisation
            const location = await this.getLocationInfo(ipAddress);

            // Analyser l'appareil
            const device = this.analyzeDevice(userAgent);

            const activityLog = new ActivityLog({
                user: userId,
                action,
                module,
                description,
                ipAddress,
                userAgent,
                location,
                device,
                metadata,
                status,
                severity,
                riskScore,
                isSuspicious
            });

            await activityLog.save();

            // Si activité suspecte, déclencher une alerte
            if (isSuspicious) {
                await this.triggerSecurityAlert(userId, action, ipAddress, riskScore);
            }

            logger.info(`Activity logged: ${action} for user ${userId}`, {
                action,
                userId,
                riskScore,
                isSuspicious
            });

            return activityLog;
        } catch (error) {
            logger.error('Error logging activity:', error);
            throw error;
        }
    }

    /**
     * Calculer le score de risque d'une activité
     */
    async calculateRiskScore({ userId, action, ipAddress, userAgent, metadata }) {
        let riskScore = 0;

        // Actions à haut risque
        if (this.suspiciousPatterns.highRiskActions.includes(action)) {
            riskScore += 30;
        }

        // Vérifier les tentatives de connexion échouées récentes
        const recentFailedLogins = await LoginAttempt.countDocuments({
            ip: ipAddress,
            success: false,
            lastAttempt: { $gte: new Date(Date.now() - 24 * 60 * 60 * 1000) }
        });

        if (recentFailedLogins >= 3) {
            riskScore += 25;
        }

        // Vérifier si l'IP est bloquée
        const isBlocked = await BlockedIP.findOne({ ip: ipAddress });
        if (isBlocked) {
            riskScore += 50;
        }

        // Vérifier les activités récentes de l'utilisateur
        const recentActivities = await ActivityLog.countDocuments({
            user: userId,
            createdAt: { $gte: new Date(Date.now() - 60 * 60 * 1000) } // Dernière heure
        });

        if (recentActivities > 20) {
            riskScore += 20;
        }

        // Vérifier les changements de localisation
        const lastActivity = await ActivityLog.findOne({
            user: userId,
            ipAddress: { $ne: ipAddress }
        }).sort({ createdAt: -1 });

        if (lastActivity) {
            const timeDiff = Date.now() - lastActivity.createdAt.getTime();
            if (timeDiff < 60 * 60 * 1000) { // Moins d'une heure
                riskScore += 15;
            }
        }

        return Math.min(riskScore, 100);
    }

    /**
     * Détecter les activités suspectes
     */
    async detectSuspiciousActivity({ userId, action, ipAddress, riskScore }) {
        // Score de risque élevé
        if (riskScore >= 70) {
            return true;
        }

        // Actions critiques
        if (['password_change', 'bank_account_change', 'payout_initiated'].includes(action)) {
            return riskScore >= 40;
        }

        // Connexions depuis des IP inhabituelles
        const userActivities = await ActivityLog.find({
            user: userId,
            action: 'login',
            ipAddress: { $ne: ipAddress }
        }).sort({ createdAt: -1 }).limit(5);

        if (userActivities.length >= 3) {
            return true;
        }

        return false;
    }

    /**
     * Obtenir les informations de localisation depuis l'IP
     */
    async getLocationInfo(ipAddress) {
        try {
            const response = await axios.get(
                `http://ip-api.com/json/${ipAddress}?fields=country,regionName,city`,
                { timeout: 5000 }
            );
            
            if (response.data && response.data.country) {
                return {
                    country: response.data.country,
                    region: response.data.regionName,
                    city: response.data.city
                };
            }
        } catch (error) {
            logger.warn('Failed to get location info:', error.message);
        }

        return {
            country: 'Unknown',
            region: 'Unknown',
            city: 'Unknown'
        };
    }

    /**
     * Analyser les informations de l'appareil
     */
    analyzeDevice(userAgent) {
        if (!userAgent) {
            return { type: 'unknown', os: 'unknown', browser: 'unknown' };
        }

        const ua = userAgent.toLowerCase();
        
        // Type d'appareil
        let type = 'desktop';
        if (ua.includes('mobile') || ua.includes('android') || ua.includes('iphone')) {
            type = 'mobile';
        } else if (ua.includes('tablet') || ua.includes('ipad')) {
            type = 'tablet';
        }

        // OS
        let os = 'unknown';
        if (ua.includes('windows')) os = 'Windows';
        else if (ua.includes('mac')) os = 'macOS';
        else if (ua.includes('linux')) os = 'Linux';
        else if (ua.includes('android')) os = 'Android';
        else if (ua.includes('ios') || ua.includes('iphone')) os = 'iOS';

        // Navigateur
        let browser = 'unknown';
        if (ua.includes('chrome')) browser = 'Chrome';
        else if (ua.includes('firefox')) browser = 'Firefox';
        else if (ua.includes('safari')) browser = 'Safari';
        else if (ua.includes('edge')) browser = 'Edge';

        return { type, os, browser };
    }

    /**
     * Déclencher une alerte de sécurité
     */
    async triggerSecurityAlert(userId, action, ipAddress, riskScore) {
        try {
            const user = await User.findById(userId);
            if (!user) return;

            // Enregistrer l'alerte
            await this.logActivity({
                userId,
                action: 'security_alert',
                module: 'security',
                description: `Alerte de sécurité: ${action} depuis ${ipAddress}`,
                ipAddress,
                userAgent: 'System',
                metadata: { riskScore, originalAction: action },
                status: 'warning',
                severity: riskScore >= 80 ? 'critical' : 'high'
            });

            // Envoyer notification au partenaire
            const notificationService = require('./notification.service');
            await notificationService.notifySecurityAlert(
                userId,
                `Alerte de sécurité: Activité suspecte détectée`,
                {
                    action,
                    ipAddress,
                    riskScore,
                    timestamp: new Date()
                }
            );

            logger.warn(`Security alert triggered for user ${userId}: ${action}`, {
                userId,
                action,
                ipAddress,
                riskScore
            });
        } catch (error) {
            logger.error('Error triggering security alert:', error);
        }
    }

    /**
     * Obtenir l'historique de sécurité d'un utilisateur
     */
    async getSecurityHistory(userId, limit = 50) {
        try {
            const activities = await ActivityLog.find({
                user: userId,
                $or: [
                    { action: { $in: ['login', 'logout', 'login_failed', 'password_change', 'security_alert'] } },
                    { isSuspicious: true },
                    { severity: { $in: ['high', 'critical'] } }
                ]
            })
            .sort({ createdAt: -1 })
            .limit(limit)
            .populate('user', 'firstName lastName email');

            return activities;
        } catch (error) {
            logger.error('Error getting security history:', error);
            throw error;
        }
    }

    /**
     * Obtenir les statistiques de sécurité
     */
    async getSecurityStats(userId, days = 30) {
        try {
            const startDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000);

            const stats = await ActivityLog.aggregate([
                {
                    $match: {
                        user: userId,
                        createdAt: { $gte: startDate }
                    }
                },
                {
                    $group: {
                        _id: null,
                        totalActivities: { $sum: 1 },
                        suspiciousActivities: {
                            $sum: { $cond: [{ $eq: ['$isSuspicious', true] }, 1, 0] }
                        },
                        failedLogins: {
                            $sum: { $cond: [{ $eq: ['$action', 'login_failed'] }, 1, 0] }
                        },
                        highRiskActivities: {
                            $sum: { $cond: [{ $in: ['$severity', ['high', 'critical']] }, 1, 0] }
                        },
                        averageRiskScore: { $avg: '$riskScore' }
                    }
                }
            ]);

            return stats[0] || {
                totalActivities: 0,
                suspiciousActivities: 0,
                failedLogins: 0,
                highRiskActivities: 0,
                averageRiskScore: 0
            };
        } catch (error) {
            logger.error('Error getting security stats:', error);
            throw error;
        }
    }
}

module.exports = new AuditService();


