const logger = require('../utils/logger');

/**
 * Service de Pricing Dynamique ChapeChape
 * Optimise la tarification selon les frais CinetPay par canal
 */
class PricingService {
    
    /**
     * Configuration des frais par méthode de paiement (Côte d'Ivoire)
     * Source: Grille tarifaire CinetPay officielle
     */
    static PAYMENT_FEES_CI = {
        'mtn_money': { 
            payinFee: 0.018,     // 1,8% (MEILLEUR pay-in)
            payoutFee: 0.013,    // 1,3% (MEILLEUR payout)  
            serviceFee: 0.015,   // 1,5% frais service client (optimisé)
            priority: 1          // Canal prioritaire
        },
        'wave': { 
            payinFee: 0.020,     // 2,0%
            payoutFee: 0.020,    // 2,0%
            serviceFee: 0.018,   // 1,8% frais service client
            priority: 2
        },
        'orange_money': { 
            payinFee: 0.030,     // 3,0%
            payoutFee: 0.015,    // 1,5%
            serviceFee: 0.025,   // 2,5% frais service client
            priority: 3
        },
        'moov_money': { 
            payinFee: 0.025,     // 2,5%
            payoutFee: 0.018,    // 1,8%
            serviceFee: 0.023,   // 2,3% frais service client
            priority: 4
        },
        'card': { 
            payinFee: 0.035,     // 3,5% (PLUS CHER)
            payoutFee: 0.030,    // 3,0% (estimation carte)
            serviceFee: 0.035,   // 3,5% frais service client
            priority: 5          // Dernier recours
        }
    };

    /**
     * Configuration générale
     */
    static CONFIG = {
        PARTNER_COMMISSION_RATE: 0.10,    // 10% commission sur partner
        MIN_SERVICE_FEE_RATE: 0.015,      // Frais service minimum (MTN)
        MAX_SERVICE_FEE_RATE: 0.035,      // Frais service maximum (Carte)
        DEFAULT_PAYMENT_METHOD: 'mtn_money' // Canal par défaut (le moins cher)
    };

    /**
     * Calculer le pricing optimisé pour une réservation
     * @param {number} basePrice Prix de base de la résidence (XOF)
     * @param {string} paymentMethod Méthode de paiement choisie
     * @param {string} payoutMethod Méthode de payout partner (optionnel)
     * @returns {Object} Détails de pricing complets
     */
    static calculateOptimalPricing(basePrice, paymentMethod = null, payoutMethod = null) {
        try {
            // Utiliser le canal par défaut si non spécifié
            const selectedPayinMethod = paymentMethod || this.CONFIG.DEFAULT_PAYMENT_METHOD;
            const selectedPayoutMethod = payoutMethod || this.getOptimalPayoutMethod();
            
            // Vérifier que les méthodes existent
            const payinConfig = this.PAYMENT_FEES_CI[selectedPayinMethod];
            const payoutConfig = this.PAYMENT_FEES_CI[selectedPayoutMethod];
            
            if (!payinConfig || !payoutConfig) {
                throw new Error(`Méthode de paiement non supportée: ${selectedPayinMethod} ou ${selectedPayoutMethod}`);
            }

            // 1. Calculer le prix client avec frais service optimisés
            const serviceAmount = Math.round(basePrice * payinConfig.serviceFee);
            const totalClientPrice = basePrice + serviceAmount;
            
            // 2. Calculer les frais CinetPay pay-in
            const cinetpayPayinFee = Math.round(totalClientPrice * payinConfig.payinFee);
            const netReceivedAfterPayin = totalClientPrice - cinetpayPayinFee;
            
            // 3. Calculer le reversement partner
            const partnerCommissionAmount = Math.round(basePrice * this.CONFIG.PARTNER_COMMISSION_RATE);
            const partnerBaseAmount = basePrice - partnerCommissionAmount;
            
            // 4. Calculer les frais payout
            const cinetpayPayoutFee = Math.round(partnerBaseAmount * payoutConfig.payoutFee);
            const partnerNetAmount = partnerBaseAmount - cinetpayPayoutFee;
            
            // 5. Calculer la recette ChapeChape finale
            const chapeChapeRevenue = netReceivedAfterPayin - partnerNetAmount;
            const totalCinetpayFees = cinetpayPayinFee + cinetpayPayoutFee;
            
            // 6. Calculer les économies vs canal le plus cher
            const expensiveMethodPricing = this.calculateWithMethod(basePrice, 'card', 'card');
            const savings = expensiveMethodPricing.totalFees - totalCinetpayFees;

            const result = {
                // Prix et montants
                basePrice: basePrice,
                serviceAmount: serviceAmount,
                totalClientPrice: totalClientPrice,
                partnerNetAmount: partnerNetAmount,
                chapeChapeRevenue: chapeChapeRevenue,
                
                // Frais détaillés
                cinetpayPayinFee: cinetpayPayinFee,
                cinetpayPayoutFee: cinetpayPayoutFee,
                totalFees: totalCinetpayFees,
                partnerCommissionAmount: partnerCommissionAmount,
                
                // Méthodes utilisées
                paymentMethod: selectedPayinMethod,
                payoutMethod: selectedPayoutMethod,
                
                // Optimisations
                serviceFeeRate: payinConfig.serviceFee,
                savingsVsExpensive: Math.max(0, savings),
                
                // Métriques business
                chapeChapeMarginRate: chapeChapeRevenue / totalClientPrice,
                partnerReceiveRate: partnerNetAmount / basePrice,
                totalFeesRate: totalCinetpayFees / totalClientPrice,
                
                // Metadata
                calculatedAt: new Date(),
                isOptimized: selectedPayinMethod === this.CONFIG.DEFAULT_PAYMENT_METHOD
            };

            logger.info(`Pricing calculé: ${basePrice} XOF → Client: ${totalClientPrice}, Partner: ${partnerNetAmount}, ChapeChape: ${chapeChapeRevenue}`);
            return result;

        } catch (error) {
            logger.error('Erreur calcul pricing:', error);
            throw error;
        }
    }

    /**
     * Calculer avec une méthode spécifique (pour comparaisons)
     */
    static calculateWithMethod(basePrice, payinMethod, payoutMethod) {
        const payinConfig = this.PAYMENT_FEES_CI[payinMethod];
        const payoutConfig = this.PAYMENT_FEES_CI[payoutMethod];
        
        const serviceAmount = Math.round(basePrice * payinConfig.serviceFee);
        const totalClientPrice = basePrice + serviceAmount;
        const cinetpayPayinFee = Math.round(totalClientPrice * payinConfig.payinFee);
        
        const partnerBaseAmount = basePrice * (1 - this.CONFIG.PARTNER_COMMISSION_RATE);
        const cinetpayPayoutFee = Math.round(partnerBaseAmount * payoutConfig.payoutFee);
        
        return {
            totalFees: cinetpayPayinFee + cinetpayPayoutFee
        };
    }

    /**
     * Obtenir la méthode de payout optimale (MTN Money = moins cher)
     */
    static getOptimalPayoutMethod() {
        return 'mtn_money'; // 1,3% payout fee
    }

    /**
     * Obtenir toutes les méthodes de paiement ordonnées par coût
     */
    static getPaymentMethodsByOptimization() {
        return Object.entries(this.PAYMENT_FEES_CI)
            .sort((a, b) => a[1].priority - b[1].priority)
            .map(([method, config]) => ({
                method,
                serviceFeeRate: config.serviceFee,
                totalFeesRate: config.payinFee + config.payoutFee,
                priority: config.priority
            }));
    }

    /**
     * Calculer les économies potentielles pour un client
     */
    static calculateSavingsOpportunity(basePrice) {
        const optimalPricing = this.calculateOptimalPricing(basePrice, 'mtn_money');
        const expensivePricing = this.calculateOptimalPricing(basePrice, 'card');
        
        return {
            optimalPrice: optimalPricing.totalClientPrice,
            expensivePrice: expensivePricing.totalClientPrice,
            savings: expensivePricing.totalClientPrice - optimalPricing.totalClientPrice,
            savingsRate: (expensivePricing.totalClientPrice - optimalPricing.totalClientPrice) / expensivePricing.totalClientPrice
        };
    }

    /**
     * Valider une configuration de pricing
     */
    static validatePricingConfig(basePrice, paymentMethod) {
        if (basePrice <= 0) {
            throw new Error('Prix de base doit être positif');
        }
        
        if (paymentMethod && !this.PAYMENT_FEES_CI[paymentMethod]) {
            throw new Error(`Méthode de paiement non supportée: ${paymentMethod}`);
        }
        
        const pricing = this.calculateOptimalPricing(basePrice, paymentMethod);
        
        if (pricing.chapeChapeRevenue <= 0) {
            logger.warn(`Marge négative détectée pour ${basePrice} XOF avec ${paymentMethod}`);
        }
        
        return pricing;
    }
}

module.exports = PricingService;
