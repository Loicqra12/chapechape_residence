const express = require('express');
const router = express.Router();
const { protect, restrictTo } = require('../middlewares/auth.middleware');
const auditService = require('../services/audit.service');
const asyncHandler = require('../middlewares/async.middleware');

/**
 * @swagger
 * tags:
 *   name: Audit
 *   description: API pour l'audit et la sécurité
 */

/**
 * @swagger
 * /api/audit/security-history:
 *   get:
 *     summary: Obtenir l'historique de sécurité d'un utilisateur
 *     tags: [Audit]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 50
 *         description: Nombre d'activités à retourner
 *     responses:
 *       200:
 *         description: Historique de sécurité récupéré avec succès
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       action:
 *                         type: string
 *                       description:
 *                         type: string
 *                       ipAddress:
 *                         type: string
 *                       location:
 *                         type: object
 *                       device:
 *                         type: object
 *                       status:
 *                         type: string
 *                       severity:
 *                         type: string
 *                       riskScore:
 *                         type: number
 *                       isSuspicious:
 *                         type: boolean
 *                       createdAt:
 *                         type: string
 *                         format: date-time
 */
router.get('/security-history', protect, asyncHandler(async (req, res) => {
    const { limit = 50 } = req.query;
    const userId = req.user.id;

    const history = await auditService.getSecurityHistory(userId, parseInt(limit));

    res.status(200).json({
        success: true,
        data: history
    });
}));

/**
 * @swagger
 * /api/audit/security-stats:
 *   get:
 *     summary: Obtenir les statistiques de sécurité d'un utilisateur
 *     tags: [Audit]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: days
 *         schema:
 *           type: integer
 *           default: 30
 *         description: Nombre de jours à analyser
 *     responses:
 *       200:
 *         description: Statistiques de sécurité récupérées avec succès
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     totalActivities:
 *                       type: integer
 *                     suspiciousActivities:
 *                       type: integer
 *                     failedLogins:
 *                       type: integer
 *                     highRiskActivities:
 *                       type: integer
 *                     averageRiskScore:
 *                       type: number
 */
router.get('/security-stats', protect, asyncHandler(async (req, res) => {
    const { days = 30 } = req.query;
    const userId = req.user.id;

    const stats = await auditService.getSecurityStats(userId, parseInt(days));

    res.status(200).json({
        success: true,
        data: stats
    });
}));

/**
 * @swagger
 * /api/audit/activity-log:
 *   get:
 *     summary: Obtenir le journal d'activité complet d'un utilisateur
 *     tags: [Audit]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Numéro de page
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *         description: Nombre d'activités par page
 *       - in: query
 *         name: module
 *         schema:
 *           type: string
 *           enum: [auth, profile, payment, residence, reservation, security, verification]
 *         description: Filtrer par module
 *       - in: query
 *         name: action
 *         schema:
 *           type: string
 *         description: Filtrer par action
 *       - in: query
 *         name: severity
 *         schema:
 *           type: string
 *           enum: [low, medium, high, critical]
 *         description: Filtrer par niveau de gravité
 *     responses:
 *       200:
 *         description: Journal d'activité récupéré avec succès
 */
router.get('/activity-log', protect, asyncHandler(async (req, res) => {
    const { 
        page = 1, 
        limit = 20, 
        module, 
        action, 
        severity 
    } = req.query;
    const userId = req.user.id;

    // Construire le filtre
    const filter = { user: userId };
    if (module) filter.module = module;
    if (action) filter.action = action;
    if (severity) filter.severity = severity;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const ActivityLog = require('../models/activityLog.model');
    
    const [activities, total] = await Promise.all([
        ActivityLog.find(filter)
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(parseInt(limit))
            .populate('user', 'firstName lastName email'),
        ActivityLog.countDocuments(filter)
    ]);

    res.status(200).json({
        success: true,
        data: {
            activities,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                pages: Math.ceil(total / parseInt(limit))
            }
        }
    });
}));

module.exports = router;


