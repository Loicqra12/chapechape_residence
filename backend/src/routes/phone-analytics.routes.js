const express = require('express');
const router = express.Router();
const { protect, restrictTo } = require('../middlewares/auth.middleware');
const phoneLogger = require('../utils/phoneLogger');

// @desc    Obtenir les statistiques globales des numéros de téléphone
// @route   GET /api/admin/phone-analytics/stats
// @access  Private (Admin uniquement)
router.get('/stats', protect, restrictTo('admin', 'superadmin'), async (req, res) => {
    try {
        const stats = phoneLogger.getStats();
        
        res.status(200).json({
            success: true,
            data: stats
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Erreur récupération statistiques',
            error: error.message
        });
    }
});

// @desc    Obtenir les erreurs fréquentes
// @route   GET /api/admin/phone-analytics/errors
// @access  Private (Admin uniquement)
router.get('/errors', protect, restrictTo('admin', 'superadmin'), async (req, res) => {
    try {
        const days = parseInt(req.query.days) || 7;
        const commonErrors = await phoneLogger.analyzeCommonErrors(days);
        
        res.status(200).json({
            success: true,
            data: {
                period: `${days} derniers jours`,
                errors: commonErrors
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Erreur analyse erreurs',
            error: error.message
        });
    }
});

// @desc    Obtenir les logs d'une date spécifique
// @route   GET /api/admin/phone-analytics/logs/:date
// @access  Private (Admin uniquement)
router.get('/logs/:date', protect, restrictTo('admin', 'superadmin'), async (req, res) => {
    try {
        const { date } = req.params;
        const { action, country, partner } = req.query;
        
        let logs = await phoneLogger.getLogsByDate(date);
        
        // Filtrer si nécessaire
        if (action) {
            logs = logs.filter(log => log.action === action);
        }
        
        if (country) {
            logs = logs.filter(log => 
                log.normalizedAnalysis?.detectedCountry === country ||
                log.analysis?.detectedCountry === country
            );
        }
        
        if (partner) {
            logs = logs.filter(log => log.partnerId === partner);
        }
        
        res.status(200).json({
            success: true,
            data: {
                date: date,
                filters: { action, country, partner },
                logs: logs,
                total: logs.length
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Erreur récupération logs',
            error: error.message
        });
    }
});

// @desc    Rapport détaillé par pays
// @route   GET /api/admin/phone-analytics/countries
// @access  Private (Admin uniquement)
router.get('/countries', protect, restrictTo('admin', 'superadmin'), async (req, res) => {
    try {
        const days = parseInt(req.query.days) || 30;
        const countryStats = {};
        const now = new Date();
        
        // Analyser les logs des derniers jours
        for (let i = 0; i < days; i++) {
            const date = new Date(now - i * 24 * 60 * 60 * 1000);
            const dateStr = date.toISOString().split('T')[0];
            const logs = await phoneLogger.getLogsByDate(dateStr);
            
            logs.forEach(log => {
                const country = log.normalizedAnalysis?.detectedCountry || 
                              log.analysis?.detectedCountry || 'Unknown';
                const carrier = log.normalizedAnalysis?.detectedCarrier || 
                              log.analysis?.detectedCarrier || 'Unknown';
                
                if (!countryStats[country]) {
                    countryStats[country] = {
                        totalNumbers: 0,
                        carriers: {},
                        actions: {},
                        errors: 0,
                        successfulVerifications: 0
                    };
                }
                
                countryStats[country].totalNumbers++;
                countryStats[country].carriers[carrier] = 
                    (countryStats[country].carriers[carrier] || 0) + 1;
                countryStats[country].actions[log.action] = 
                    (countryStats[country].actions[log.action] || 0) + 1;
                
                if (log.error) {
                    countryStats[country].errors++;
                }
                
                if (log.action === 'partner_phone_verified') {
                    countryStats[country].successfulVerifications++;
                }
            });
        }
        
        res.status(200).json({
            success: true,
            data: {
                period: `${days} derniers jours`,
                countries: countryStats
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Erreur analyse pays',
            error: error.message
        });
    }
});

// @desc    Dashboard en temps réel
// @route   GET /api/admin/phone-analytics/dashboard
// @access  Private (Admin uniquement)
router.get('/dashboard', protect, restrictTo('admin', 'superadmin'), async (req, res) => {
    try {
        const stats = phoneLogger.getStats();
        const recentErrors = await phoneLogger.analyzeCommonErrors(1); // Dernières 24h
        
        // Calculer des métriques supplémentaires
        const dashboard = {
            overview: {
                totalLogs: stats.totalLogs,
                lastUpdate: stats.lastUpdated,
                topCountry: stats.topCountries[0] || ['Unknown', 0],
                errorRate: (stats.errors.length / stats.totalLogs * 100).toFixed(2)
            },
            countries: stats.topCountries.slice(0, 5),
            actions: stats.topActions.slice(0, 8),
            recentErrors: stats.recentErrors.slice(0, 5),
            todayErrors: recentErrors.slice(0, 5),
            healthScore: calculateHealthScore(stats)
        };
        
        res.status(200).json({
            success: true,
            data: dashboard
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Erreur dashboard',
            error: error.message
        });
    }
});

// Fonction pour calculer un score de santé du système
function calculateHealthScore(stats) {
    const totalLogs = stats.totalLogs || 1;
    const totalErrors = stats.errors.length;
    const errorRate = totalErrors / totalLogs;
    
    let score = 100;
    
    // Pénaliser selon le taux d'erreur
    if (errorRate > 0.1) score -= 30; // Plus de 10% d'erreurs
    else if (errorRate > 0.05) score -= 15; // Plus de 5% d'erreurs
    else if (errorRate > 0.01) score -= 5; // Plus de 1% d'erreurs
    
    // Bonus pour volume d'activité
    if (totalLogs > 1000) score += 5;
    if (totalLogs > 10000) score += 5;
    
    return Math.max(0, Math.min(100, score));
}

module.exports = router;
