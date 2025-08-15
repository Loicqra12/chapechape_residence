const express = require('express');
const { body, query, param } = require('express-validator');
const auth = require('../middlewares/auth.middleware');
const { validate } = require('../middlewares/validation.middleware');
const PricingService = require('../services/pricing.service');
const asyncHandler = require('../middlewares/async');
const ApiError = require('../utils/apiError');

const router = express.Router();

// ===============================
// VALIDATION SCHEMAS
// ===============================

const calculatePricingValidation = [
    body('basePrice')
        .isFloat({ min: 1000, max: 1000000 })
        .withMessage('Prix de base doit être entre 1,000 et 1,000,000 XOF'),
    body('paymentMethod')
        .optional()
        .isIn(['mtn_money', 'orange_money', 'wave', 'moov_money', 'card'])
        .withMessage('Méthode de paiement non supportée'),
    body('payoutMethod')
        .optional()
        .isIn(['mtn_money', 'orange_money', 'wave', 'moov_money', 'card'])
        .withMessage('Méthode de payout non supportée'),
    validate
];

const optimizationAnalysisValidation = [
    query('basePrice')
        .isFloat({ min: 1000, max: 1000000 })
        .withMessage('Prix de base doit être entre 1,000 et 1,000,000 XOF'),
    validate
];

// ===============================
// ROUTES PUBLIQUES (pour devis frontend)
// ===============================

/**
 * Calculer le pricing dynamique optimisé
 * POST /api/pricing/calculate
 * 
 * Body: { basePrice, paymentMethod?, payoutMethod? }
 */
router.post('/calculate', 
    calculatePricingValidation,
    asyncHandler(async (req, res) => {
        const { basePrice, paymentMethod, payoutMethod } = req.body;
        
        try {
            const pricing = PricingService.calculateOptimalPricing(
                basePrice, 
                paymentMethod, 
                payoutMethod
            );
            
            res.json({
                success: true,
                data: pricing,
                message: 'Pricing calculé avec succès'
            });
            
        } catch (error) {
            throw new ApiError(error.message, 400);
        }
    })
);

/**
 * Obtenir toutes les méthodes de paiement ordonnées par coût
 * GET /api/pricing/payment-methods
 */
router.get('/payment-methods',
    asyncHandler(async (req, res) => {
        const methods = PricingService.getPaymentMethodsByOptimization();
        
        res.json({
            success: true,
            data: methods,
            message: 'Méthodes de paiement ordonnées par optimisation'
        });
    })
);

/**
 * Analyser les économies potentielles pour un prix donné
 * GET /api/pricing/savings-analysis?basePrice=10000
 */
router.get('/savings-analysis',
    optimizationAnalysisValidation,
    asyncHandler(async (req, res) => {
        const { basePrice } = req.query;
        
        try {
            const analysis = PricingService.calculateSavingsOpportunity(parseFloat(basePrice));
            
            // Ajouter comparaisons détaillées par méthode
            const comparisons = {};
            const methods = ['mtn_money', 'orange_money', 'wave', 'moov_money', 'card'];
            
            for (const method of methods) {
                comparisons[method] = PricingService.calculateOptimalPricing(
                    parseFloat(basePrice), 
                    method
                );
            }
            
            res.json({
                success: true,
                data: {
                    ...analysis,
                    detailedComparisons: comparisons
                },
                message: 'Analyse d\'économies calculée'
            });
            
        } catch (error) {
            throw new ApiError(error.message, 400);
        }
    })
);

// ===============================
// ROUTES PROTÉGÉES (Admin/Partner)
// ===============================

/**
 * Valider une configuration de pricing (Admin seulement)
 * POST /api/pricing/validate
 * 
 * Body: { basePrice, paymentMethod }
 */
router.post('/validate',
    auth.protect,
    calculatePricingValidation,
    asyncHandler(async (req, res) => {
        // Seuls admin/superadmin peuvent valider
        if (!['admin', 'superadmin'].includes(req.user.role)) {
            throw new ApiError('Accès réservé aux administrateurs', 403);
        }
        
        const { basePrice, paymentMethod } = req.body;
        
        try {
            const pricing = PricingService.validatePricingConfig(basePrice, paymentMethod);
            
            res.json({
                success: true,
                data: pricing,
                message: 'Configuration de pricing validée',
                warnings: pricing.chapeChapeRevenue <= 0 ? 
                    ['Marge négative détectée'] : []
            });
            
        } catch (error) {
            throw new ApiError(error.message, 400);
        }
    })
);

/**
 * Obtenir les stats de pricing pour un partner
 * GET /api/pricing/partner/:partnerId/stats
 */
router.get('/partner/:partnerId/stats',
    auth.protect,
    param('partnerId').isMongoId().withMessage('ID partner invalide'),
    validate,
    asyncHandler(async (req, res) => {
        const { partnerId } = req.params;
        
        // Vérifier les permissions
        if (req.user.role === 'partner' && req.user._id.toString() !== partnerId) {
            throw new ApiError('Accès refusé', 403);
        }
        
        if (!['partner', 'admin', 'superadmin'].includes(req.user.role)) {
            throw new ApiError('Accès refusé', 403);
        }
        
        // Récupérer les réservations avec pricing dynamique du partner
        const Reservation = require('../models/reservation.model');
        
        const reservations = await Reservation.find({
            partner: partnerId,
            'dynamicPricing.basePrice': { $exists: true }
        }).select('dynamicPricing createdAt');
        
        // Calculer les statistiques
        let totalRevenue = 0;
        let totalSavings = 0;
        let optimizedCount = 0;
        const methodStats = {};
        
        reservations.forEach(reservation => {
            const pricing = reservation.dynamicPricing;
            
            totalRevenue += pricing.partnerNetAmount || 0;
            totalSavings += pricing.optimization?.savingsVsExpensive || 0;
            
            if (pricing.optimization?.isOptimized) {
                optimizedCount++;
            }
            
            const method = pricing.paymentMethod;
            if (!methodStats[method]) {
                methodStats[method] = { count: 0, revenue: 0 };
            }
            methodStats[method].count++;
            methodStats[method].revenue += pricing.partnerNetAmount || 0;
        });
        
        res.json({
            success: true,
            data: {
                totalReservations: reservations.length,
                totalRevenue: Math.round(totalRevenue),
                totalSavings: Math.round(totalSavings),
                optimizationRate: reservations.length > 0 ? 
                    Math.round((optimizedCount / reservations.length) * 100) : 0,
                methodStats: methodStats,
                avgRevenuePerReservation: reservations.length > 0 ? 
                    Math.round(totalRevenue / reservations.length) : 0
            },
            message: 'Statistiques de pricing récupérées'
        });
    })
);

/**
 * Simuler l'impact d'un changement de tarification
 * POST /api/pricing/simulate
 * 
 * Body: { currentPrices: [10000, 15000], newCommissionRate?: 0.12 }
 */
router.post('/simulate',
    auth.protect,
    body('currentPrices')
        .isArray({ min: 1, max: 10 })
        .withMessage('Liste de prix requis (max 10)'),
    body('currentPrices.*')
        .isFloat({ min: 1000 })
        .withMessage('Prix individuels invalides'),
    body('newCommissionRate')
        .optional()
        .isFloat({ min: 0.05, max: 0.30 })
        .withMessage('Taux de commission entre 5% et 30%'),
    validate,
    asyncHandler(async (req, res) => {
        // Admin seulement
        if (!['admin', 'superadmin'].includes(req.user.role)) {
            throw new ApiError('Accès réservé aux administrateurs', 403);
        }
        
        const { currentPrices, newCommissionRate } = req.body;
        
        // Simuler avec configuration actuelle vs optimisée
        const simulations = currentPrices.map(price => {
            const current = PricingService.calculateOptimalPricing(price, 'orange_money');
            const optimized = PricingService.calculateOptimalPricing(price, 'mtn_money');
            
            return {
                basePrice: price,
                current: {
                    clientPays: current.totalClientPrice,
                    partnerReceives: current.partnerNetAmount,
                    chapeChapeRevenue: current.chapeChapeRevenue
                },
                optimized: {
                    clientPays: optimized.totalClientPrice,
                    partnerReceives: optimized.partnerNetAmount,
                    chapeChapeRevenue: optimized.chapeChapeRevenue
                },
                improvements: {
                    clientSavings: current.totalClientPrice - optimized.totalClientPrice,
                    chapeChapeGain: optimized.chapeChapeRevenue - current.chapeChapeRevenue,
                    partnerImpact: optimized.partnerNetAmount - current.partnerNetAmount
                }
            };
        });
        
        res.json({
            success: true,
            data: {
                simulations: simulations,
                summary: {
                    totalClientSavings: simulations.reduce((sum, s) => sum + s.improvements.clientSavings, 0),
                    totalRevenueGain: simulations.reduce((sum, s) => sum + s.improvements.chapeChapeGain, 0),
                    avgOptimization: simulations.reduce((sum, s) => sum + (s.improvements.clientSavings / s.current.clientPays), 0) / simulations.length * 100
                }
            },
            message: 'Simulation de tarification calculée'
        });
    })
);

module.exports = router;
