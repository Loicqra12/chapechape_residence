const express = require('express');
const router = express.Router();
const { protect, restrictTo } = require('../middlewares/auth.middleware');
const verificationController = require('../controllers/partner/verification.controller');
const phoneLogger = require('../utils/phoneLogger');

// Middleware pour logger automatiquement les requêtes de vérification
const logPhoneRequest = (req, res, next) => {
    // Logger la requête entrante
    phoneLogger.log({
        action: 'api_request',
        endpoint: req.originalUrl,
        method: req.method,
        originalInput: req.body.phoneNumber,
        partnerId: req.user?.id,
        userAgent: req.get('User-Agent'),
        ip: req.ip,
        timestamp: new Date()
    });
    next();
};

// @desc    Demander un code de vérification SMS pour partner
// @route   POST /api/partners/verify-phone/request
// @access  Private (Partner uniquement)
router.post('/request', 
    protect, 
    restrictTo('partner', 'partner_pending'),
    logPhoneRequest,
    verificationController.requestPartnerPhoneVerification
);

// @desc    Confirmer le code de vérification SMS pour partner
// @route   POST /api/partners/verify-phone/confirm  
// @access  Private (Partner uniquement)
router.post('/confirm',
    protect,
    restrictTo('partner', 'partner_pending'), 
    logPhoneRequest,
    verificationController.confirmPartnerPhoneVerification
);

// @desc    Obtenir l'historique des vérifications du partner
// @route   GET /api/partners/verify-phone/history
// @access  Private (Partner uniquement)
router.get('/history', protect, restrictTo('partner', 'partner_pending'), async (req, res) => {
    try {
        const partnerId = req.user.id;
        const days = parseInt(req.query.days) || 30;
        
        // Récupérer l'historique depuis les logs
        const history = [];
        const now = new Date();
        
        for (let i = 0; i < days; i++) {
            const date = new Date(now - i * 24 * 60 * 60 * 1000);
            const dateStr = date.toISOString().split('T')[0];
            const logs = await phoneLogger.getLogsByDate(dateStr);
            
            // Filtrer les logs de ce partner
            const partnerLogs = logs.filter(log => 
                log.partnerId === partnerId && 
                (log.action === 'partner_verification_request' || 
                 log.action === 'partner_phone_verified' ||
                 log.action === 'partner_sms_sent')
            );
            
            history.push(...partnerLogs);
        }
        
        // Trier par date décroissante
        history.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
        
        res.status(200).json({
            success: true,
            data: {
                history: history.slice(0, 50), // Limiter à 50 entrées
                totalFound: history.length
            }
        });
        
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Erreur récupération historique',
            error: error.message
        });
    }
});

module.exports = router;
