const phoneLogger = require('../utils/phoneLogger');
const User = require('../models/user.model');
const twilioService = require('./twilio.service');

/**
 * Service de validation renforcée pour les numéros de paiement
 * Spécialement conçu pour sécuriser les transactions monétaires
 */
class PaymentPhoneValidationService {
    constructor() {
        // Cache des validations récentes (Redis recommandé en production)
        this.validationCache = new Map();
        
        // Règles de validation par pays et opérateur
        this.validationRules = {
            'CI': { // Côte d'Ivoire
                'Orange': {
                    patterns: [/^(\+225)?(07|47|67)\d{6}$/],
                    minAmount: 100, // CFA
                    maxAmount: 1000000, // CFA
                    dailyLimit: 2000000,
                    requiresVerification: true,
                    supportedServices: ['orange_money', 'wave']
                },
                'MTN': {
                    patterns: [/^(\+225)?(05|45|65)\d{6}$/],
                    minAmount: 100,
                    maxAmount: 1000000,
                    dailyLimit: 2000000,
                    requiresVerification: true,
                    supportedServices: ['mtn_money', 'wave']
                },
                'Moov': {
                    patterns: [/^(\+225)?(01|41|61)\d{6}$/],
                    minAmount: 100,
                    maxAmount: 500000,
                    dailyLimit: 1000000,
                    requiresVerification: true,
                    supportedServices: ['moov_money', 'wave']
                }
            },
            'SN': { // Sénégal
                'Orange': {
                    patterns: [/^(\+221)?(77|78)\d{7}$/],
                    minAmount: 500, // CFA
                    maxAmount: 2000000,
                    dailyLimit: 5000000,
                    requiresVerification: true,
                    supportedServices: ['orange_money', 'wave']
                },
                'Free': {
                    patterns: [/^(\+221)?(70|76)\d{7}$/],
                    minAmount: 500,
                    maxAmount: 1000000,
                    dailyLimit: 3000000,
                    requiresVerification: true,
                    supportedServices: ['wave']
                }
            }
        };
        
        // Seuils de sécurité pour déclenchement de vérifications supplémentaires
        this.securityThresholds = {
            highAmount: 100000, // CFA
            suspiciousPattern: 5, // Nombre de tentatives en 1h
            crossCarrierLimit: 3, // Changements d'opérateur par jour
            internationalAlert: 1 // Transaction internationale
        };
    }

    /**
     * Valider un numéro pour les paiements avec vérifications de sécurité
     * @param {Object} validationData - Données de validation
     */
    async validatePaymentPhone(validationData) {
        const {
            phoneNumber,
            amount,
            currency = 'CFA',
            paymentMethod,
            partnerId,
            transactionType = 'payout', // payout, commission, refund
            clientIP,
            userAgent
        } = validationData;

        try {
            // Logger la demande de validation
            phoneLogger.log({
                action: 'payment_phone_validation_request',
                phoneNumber: phoneNumber,
                amount: amount,
                currency: currency,
                paymentMethod: paymentMethod,
                partnerId: partnerId,
                transactionType: transactionType,
                clientIP: clientIP,
                timestamp: new Date()
            });

            // Étape 1: Validation de format basique
            const formatValidation = this.validatePhoneFormat(phoneNumber);
            if (!formatValidation.isValid) {
                return this.createValidationResult(false, formatValidation.reason);
            }

            // Étape 2: Analyse du numéro et détection opérateur
            const phoneAnalysis = this.analyzePhoneNumber(phoneNumber);
            
            // Étape 3: Vérifier les règles de l'opérateur
            const operatorValidation = this.validateOperatorRules(
                phoneAnalysis, amount, paymentMethod
            );
            if (!operatorValidation.isValid) {
                return this.createValidationResult(false, operatorValidation.reason);
            }

            // Étape 4: Vérifications de sécurité
            const securityValidation = await this.performSecurityChecks(
                phoneNumber, amount, partnerId, transactionType
            );
            if (!securityValidation.isValid) {
                return this.createValidationResult(false, securityValidation.reason, {
                    requiresAdditionalVerification: true,
                    securityLevel: securityValidation.level
                });
            }

            // Étape 5: Vérifier l'historique du partner
            const historyValidation = await this.validatePartnerHistory(
                partnerId, phoneNumber, amount
            );
            if (!historyValidation.isValid) {
                return this.createValidationResult(false, historyValidation.reason);
            }

            // Étape 6: Test de connectivité opérateur (optionnel)
            const connectivityTest = await this.testOperatorConnectivity(phoneAnalysis);
            
            // Succès - Mettre en cache la validation
            const validationResult = this.createValidationResult(true, 'Numéro validé pour paiement', {
                phoneAnalysis: phoneAnalysis,
                operatorSupport: operatorValidation.supportedServices,
                recommendedMethod: this.getRecommendedPaymentMethod(phoneAnalysis, amount),
                estimatedFee: this.calculateEstimatedFee(amount, paymentMethod),
                connectivityStatus: connectivityTest.status,
                securityScore: securityValidation.score
            });

            this.cacheValidation(phoneNumber, partnerId, validationResult);

            // Logger le succès
            phoneLogger.log({
                action: 'payment_phone_validated',
                phoneNumber: phoneNumber,
                partnerId: partnerId,
                amount: amount,
                recommendedMethod: validationResult.data.recommendedMethod,
                securityScore: validationResult.data.securityScore,
                timestamp: new Date()
            });

            return validationResult;

        } catch (error) {
            // Logger l'erreur
            phoneLogger.log({
                action: 'payment_validation_error',
                phoneNumber: phoneNumber,
                partnerId: partnerId,
                error: error.message,
                timestamp: new Date()
            });

            return this.createValidationResult(false, 'Erreur de validation', {
                error: error.message
            });
        }
    }

    /**
     * Validation de format basique
     */
    validatePhoneFormat(phoneNumber) {
        if (!phoneNumber || typeof phoneNumber !== 'string') {
            return { isValid: false, reason: 'Numéro manquant ou invalide' };
        }

        // Nettoyer le numéro
        const cleaned = phoneNumber.replace(/[\s\-\(\)]/g, '');
        
        // Vérifier la longueur
        if (cleaned.length < 8 || cleaned.length > 15) {
            return { isValid: false, reason: 'Longueur de numéro invalide' };
        }

        // Vérifier les caractères
        if (!/^[\+]?[0-9]+$/.test(cleaned)) {
            return { isValid: false, reason: 'Caractères invalides dans le numéro' };
        }

        return { isValid: true, cleaned: cleaned };
    }

    /**
     * Analyser le numéro pour détecter pays et opérateur
     */
    analyzePhoneNumber(phoneNumber) {
        const analysis = {
            originalNumber: phoneNumber,
            normalizedNumber: this.normalizePhoneNumber(phoneNumber),
            country: null,
            countryCode: null,
            carrier: null,
            isValid: false,
            confidence: 0
        };

        // Détecter le pays
        if (analysis.normalizedNumber.startsWith('+225')) {
            analysis.country = 'CI';
            analysis.countryCode = '+225';
            analysis.carrier = this.detectIvoryCoastCarrier(analysis.normalizedNumber);
            analysis.confidence = 0.95;
        } else if (analysis.normalizedNumber.startsWith('+221')) {
            analysis.country = 'SN';
            analysis.countryCode = '+221';
            analysis.carrier = this.detectSenegalCarrier(analysis.normalizedNumber);
            analysis.confidence = 0.95;
        } else if (analysis.normalizedNumber.startsWith('+223')) {
            analysis.country = 'ML';
            analysis.countryCode = '+223';
            analysis.confidence = 0.8; // Moins de règles définies
        }

        analysis.isValid = analysis.country !== null && analysis.carrier !== null;
        return analysis;
    }

    /**
     * Normaliser le numéro au format E.164
     */
    normalizePhoneNumber(phoneNumber) {
        let cleaned = phoneNumber.replace(/[\s\-\(\)]/g, '');
        
        // Si déjà en E.164
        if (cleaned.startsWith('+')) {
            return cleaned;
        }
        
        // Supprimer le zéro initial
        if (cleaned.startsWith('0')) {
            cleaned = cleaned.substring(1);
        }
        
        // Détecter le pays et ajouter le code
        if (cleaned.length === 8) {
            // Probablement Côte d'Ivoire
            return `+225${cleaned}`;
        } else if (cleaned.length === 9 && cleaned.startsWith('7')) {
            // Probablement Sénégal
            return `+221${cleaned}`;
        } else if (cleaned.length === 11 && cleaned.startsWith('225')) {
            return `+${cleaned}`;
        } else if (cleaned.length === 11 && cleaned.startsWith('221')) {
            return `+${cleaned}`;
        }
        
        // Par défaut Côte d'Ivoire
        return `+225${cleaned}`;
    }

    /**
     * Détecter l'opérateur en Côte d'Ivoire
     */
    detectIvoryCoastCarrier(phoneNumber) {
        const number = phoneNumber.replace('+225', '');
        
        if (/^(07|47|67)/.test(number)) return 'Orange';
        if (/^(05|45|65)/.test(number)) return 'MTN';
        if (/^(01|41|61)/.test(number)) return 'Moov';
        
        return null;
    }

    /**
     * Détecter l'opérateur au Sénégal
     */
    detectSenegalCarrier(phoneNumber) {
        const number = phoneNumber.replace('+221', '');
        
        if (/^(77|78)/.test(number)) return 'Orange';
        if (/^(70|76)/.test(number)) return 'Free';
        if (/^75/.test(number)) return 'Expresso';
        
        return null;
    }

    /**
     * Valider selon les règles de l'opérateur
     */
    validateOperatorRules(phoneAnalysis, amount, paymentMethod) {
        const { country, carrier } = phoneAnalysis;
        
        if (!country || !carrier) {
            return { isValid: false, reason: 'Opérateur non supporté' };
        }

        const rules = this.validationRules[country]?.[carrier];
        if (!rules) {
            return { isValid: false, reason: 'Règles opérateur non définies' };
        }

        // Vérifier le pattern
        const isPatternValid = rules.patterns.some(pattern => 
            pattern.test(phoneAnalysis.normalizedNumber)
        );
        if (!isPatternValid) {
            return { isValid: false, reason: 'Format numéro incorrect pour cet opérateur' };
        }

        // Vérifier les limites de montant
        if (amount < rules.minAmount) {
            return { 
                isValid: false, 
                reason: `Montant minimum: ${rules.minAmount} CFA` 
            };
        }
        if (amount > rules.maxAmount) {
            return { 
                isValid: false, 
                reason: `Montant maximum: ${rules.maxAmount} CFA pour ${carrier}` 
            };
        }

        // Vérifier si la méthode de paiement est supportée
        if (paymentMethod && !rules.supportedServices.includes(paymentMethod)) {
            return { 
                isValid: false, 
                reason: `${paymentMethod} non supporté par ${carrier}` 
            };
        }

        return { 
            isValid: true, 
            supportedServices: rules.supportedServices,
            limits: {
                min: rules.minAmount,
                max: rules.maxAmount,
                daily: rules.dailyLimit
            }
        };
    }

    /**
     * Effectuer les vérifications de sécurité
     */
    async performSecurityChecks(phoneNumber, amount, partnerId, transactionType) {
        const securityIssues = [];
        let securityScore = 100;

        // Vérifier les montants élevés
        if (amount > this.securityThresholds.highAmount) {
            securityIssues.push('Montant élevé détecté');
            securityScore -= 20;
        }

        // Vérifier l'historique récent des tentatives
        const recentAttempts = await this.getRecentValidationAttempts(phoneNumber, partnerId);
        if (recentAttempts > this.securityThresholds.suspiciousPattern) {
            securityIssues.push('Pattern suspect détecté');
            securityScore -= 30;
        }

        // Vérifier les changements d'opérateur
        const carrierChanges = await this.getCarrierChangesToday(partnerId);
        if (carrierChanges > this.securityThresholds.crossCarrierLimit) {
            securityIssues.push('Trop de changements d\'opérateur');
            securityScore -= 25;
        }

        // Vérifier si c'est un numéro international non habituel
        if (!phoneNumber.startsWith('+225') && !phoneNumber.startsWith('+221')) {
            securityIssues.push('Numéro international détecté');
            securityScore -= 15;
        }

        // Déterminer le niveau de sécurité requis
        let securityLevel = 'low';
        if (securityScore < 70) securityLevel = 'high';
        else if (securityScore < 85) securityLevel = 'medium';

        const isValid = securityScore >= 50; // Seuil minimum

        return {
            isValid: isValid,
            reason: securityIssues.length > 0 ? securityIssues.join(', ') : 'Vérifications sécurité OK',
            score: securityScore,
            level: securityLevel,
            issues: securityIssues
        };
    }

    /**
     * Valider l'historique du partner
     */
    async validatePartnerHistory(partnerId, phoneNumber, amount) {
        try {
            const partner = await User.findById(partnerId);
            if (!partner) {
                return { isValid: false, reason: 'Partner non trouvé' };
            }

            // Vérifier que le numéro est vérifié
            if (!partner.isPhoneVerified) {
                return { isValid: false, reason: 'Numéro non vérifié' };
            }

            // Vérifier que c'est bien le numéro du partner
            if (partner.phoneNumber !== phoneNumber) {
                return { isValid: false, reason: 'Numéro différent du profil partner' };
            }

            // Vérifier les suspensions
            if (partner.payoutSuspension?.suspended) {
                const suspendedUntil = partner.payoutSuspension.suspendedUntil;
                if (!suspendedUntil || new Date() < suspendedUntil) {
                    return { 
                        isValid: false, 
                        reason: 'Virements suspendus temporairement' 
                    };
                }
            }

            return { isValid: true };

        } catch (error) {
            return { isValid: false, reason: 'Erreur validation historique' };
        }
    }

    /**
     * Tester la connectivité avec l'opérateur
     */
    async testOperatorConnectivity(phoneAnalysis) {
        try {
            // Test basique en envoyant un SMS de test (optionnel)
            // En production, ceci pourrait être un ping vers l'API de l'opérateur
            
            const { country, carrier } = phoneAnalysis;
            
            // Simuler un test de connectivité
            const isConnected = Math.random() > 0.1; // 90% de succès
            
            return {
                status: isConnected ? 'connected' : 'disconnected',
                testedAt: new Date(),
                carrier: carrier,
                country: country
            };
        } catch (error) {
            return {
                status: 'error',
                error: error.message,
                testedAt: new Date()
            };
        }
    }

    /**
     * Recommander la meilleure méthode de paiement
     */
    getRecommendedPaymentMethod(phoneAnalysis, amount) {
        const { country, carrier } = phoneAnalysis;
        
        // Logique de recommandation basée sur l'opérateur et le montant
        if (country === 'CI' || country === 'SN') {
            if (amount < 50000) {
                // Petits montants : Wave souvent moins cher
                return 'wave';
            } else {
                // Gros montants : Opérateur direct souvent plus fiable
                switch (carrier) {
                    case 'Orange': return 'orange_money';
                    case 'MTN': return 'mtn_money';
                    case 'Moov': return 'moov_money';
                    default: return 'wave';
                }
            }
        }
        
        return 'wave'; // Fallback
    }

    /**
     * Calculer les frais estimés
     */
    calculateEstimatedFee(amount, paymentMethod) {
        const feeRates = {
            'wave': 0.01, // 1%
            'orange_money': 0.015, // 1.5%
            'mtn_money': 0.015, // 1.5%
            'moov_money': 0.02 // 2%
        };
        
        const rate = feeRates[paymentMethod] || 0.015;
        const baseFee = amount * rate;
        
        return {
            percentage: rate * 100,
            amount: Math.round(baseFee),
            total: amount + Math.round(baseFee)
        };
    }

    /**
     * Créer un résultat de validation standardisé
     */
    createValidationResult(isValid, message, data = {}) {
        return {
            isValid: isValid,
            message: message,
            timestamp: new Date(),
            data: data
        };
    }

    /**
     * Mettre en cache une validation
     */
    cacheValidation(phoneNumber, partnerId, result) {
        const key = `${partnerId}_${phoneNumber}`;
        const cacheEntry = {
            result: result,
            cachedAt: new Date(),
            expiresAt: new Date(Date.now() + 5 * 60 * 1000) // 5 minutes
        };
        
        this.validationCache.set(key, cacheEntry);
        
        // Nettoyer le cache périodiquement
        this.cleanupCache();
    }

    /**
     * Obtenir une validation depuis le cache
     */
    getCachedValidation(phoneNumber, partnerId) {
        const key = `${partnerId}_${phoneNumber}`;
        const cached = this.validationCache.get(key);
        
        if (cached && new Date() < cached.expiresAt) {
            return cached.result;
        }
        
        this.validationCache.delete(key);
        return null;
    }

    /**
     * Nettoyer le cache expiré
     */
    cleanupCache() {
        const now = new Date();
        for (const [key, entry] of this.validationCache.entries()) {
            if (now >= entry.expiresAt) {
                this.validationCache.delete(key);
            }
        }
    }

    /**
     * Obtenir les tentatives récentes
     */
    async getRecentValidationAttempts(phoneNumber, partnerId) {
        // En production, ceci devrait interroger la base de données
        // Pour l'instant, simulation avec un nombre aléatoire
        return Math.floor(Math.random() * 3);
    }

    /**
     * Obtenir les changements d'opérateur aujourd'hui
     */
    async getCarrierChangesToday(partnerId) {
        // En production, ceci devrait interroger les logs
        // Pour l'instant, simulation
        return Math.floor(Math.random() * 2);
    }
}

module.exports = new PaymentPhoneValidationService();
