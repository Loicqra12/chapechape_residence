const phoneLogger = require('../utils/phoneLogger');

/**
 * Service d'expansion géographique pour supporter de nouveaux pays
 * Architecture extensible pour ajouter facilement de nouveaux marchés
 */
class CountryExpansionService {
    constructor() {
        // Configuration des pays supportés
        this.supportedCountries = {
            // Pays actuellement actifs
            'CI': {
                name: 'Côte d\'Ivoire',
                code: '+225',
                currency: 'CFA',
                status: 'active',
                priority: 1,
                operators: this.getIvoryCoastOperators(),
                regulations: this.getIvoryCoastRegulations(),
                localPartners: ['Wave', 'CinetPay'],
                languages: ['fr', 'en'],
                timeZone: 'GMT+0'
            },
            'SN': {
                name: 'Sénégal',
                code: '+221',
                currency: 'CFA',
                status: 'active',
                priority: 2,
                operators: this.getSenegalOperators(),
                regulations: this.getSenegalRegulations(),
                localPartners: ['Wave', 'CinetPay'],
                languages: ['fr', 'wo'],
                timeZone: 'GMT+0'
            },
            
            // Pays en expansion (beta)
            'ML': {
                name: 'Mali',
                code: '+223',
                currency: 'CFA',
                status: 'beta',
                priority: 3,
                operators: this.getMaliOperators(),
                regulations: this.getMaliRegulations(),
                localPartners: ['Wave'],
                languages: ['fr', 'bm'],
                timeZone: 'GMT+0'
            },
            'BF': {
                name: 'Burkina Faso',
                code: '+226',
                currency: 'CFA',
                status: 'beta',
                priority: 4,
                operators: this.getBurkinaOperators(),
                regulations: this.getBurkinaRegulations(),
                localPartners: ['Wave'],
                languages: ['fr', 'mos'],
                timeZone: 'GMT+0'
            },
            'GN': {
                name: 'Guinée',
                code: '+224',
                currency: 'GNF',
                status: 'beta',
                priority: 5,
                operators: this.getGuineaOperators(),
                regulations: this.getGuineaRegulations(),
                localPartners: ['Wave'],
                languages: ['fr'],
                timeZone: 'GMT+0'
            },
            
            // Pays planifiés
            'TG': {
                name: 'Togo',
                code: '+228',
                currency: 'CFA',
                status: 'planned',
                priority: 6,
                operators: this.getTogoOperators(),
                regulations: this.getTogoRegulations(),
                localPartners: [],
                languages: ['fr', 'ee'],
                timeZone: 'GMT+0'
            },
            'BJ': {
                name: 'Bénin',
                code: '+229',
                currency: 'CFA',
                status: 'planned',
                priority: 7,
                operators: this.getBeninOperators(),
                regulations: this.getBeninRegulations(),
                localPartners: [],
                languages: ['fr', 'fon'],
                timeZone: 'GMT+1'
            },
            'NE': {
                name: 'Niger',
                code: '+227',
                currency: 'CFA',
                status: 'planned',
                priority: 8,
                operators: this.getNigerOperators(),
                regulations: this.getNigerRegulations(),
                localPartners: [],
                languages: ['fr', 'ha'],
                timeZone: 'GMT+1'
            },
            'TD': {
                name: 'Tchad',
                code: '+235',
                currency: 'CFA',
                status: 'planned',
                priority: 9,
                operators: this.getChadOperators(),
                regulations: this.getChadRegulations(),
                localPartners: [],
                languages: ['fr', 'ar'],
                timeZone: 'GMT+1'
            }
        };
        
        // Configuration des phases de déploiement
        this.deploymentPhases = {
            phase1: ['CI', 'SN'], // Actuellement actifs
            phase2: ['ML', 'BF', 'GN'], // En cours d'expansion
            phase3: ['TG', 'BJ'], // Prochaine vague
            phase4: ['NE', 'TD'] // Expansion future
        };
    }

    /**
     * Obtenir la configuration d'un pays
     */
    getCountryConfig(countryCode) {
        const config = this.supportedCountries[countryCode.toUpperCase()];
        if (!config) {
            phoneLogger.log({
                action: 'unsupported_country_requested',
                countryCode: countryCode,
                timestamp: new Date()
            });
            return null;
        }
        
        return config;
    }

    /**
     * Vérifier si un pays est supporté pour une fonctionnalité
     */
    isCountrySupported(countryCode, feature = 'basic') {
        const config = this.getCountryConfig(countryCode);
        if (!config) return false;
        
        const supportLevels = {
            'basic': ['active', 'beta', 'planned'],
            'payments': ['active', 'beta'],
            'verification': ['active', 'beta'],
            'full': ['active']
        };
        
        return supportLevels[feature]?.includes(config.status) || false;
    }

    /**
     * Détecter automatiquement le pays depuis un numéro
     */
    detectCountryFromPhone(phoneNumber) {
        const normalized = phoneNumber.replace(/[\s\-\(\)]/g, '');
        
        for (const [code, config] of Object.entries(this.supportedCountries)) {
            if (normalized.startsWith(config.code)) {
                return {
                    countryCode: code,
                    countryName: config.name,
                    callingCode: config.code,
                    isSupported: config.status !== 'planned',
                    supportLevel: config.status,
                    confidence: 1.0
                };
            }
        }
        
        // Essayer de détecter sans le +
        const withoutPlus = normalized.startsWith('+') ? normalized.substring(1) : normalized;
        
        for (const [code, config] of Object.entries(this.supportedCountries)) {
            const countryCodeDigits = config.code.substring(1); // Enlever le +
            if (withoutPlus.startsWith(countryCodeDigits)) {
                return {
                    countryCode: code,
                    countryName: config.name,
                    callingCode: config.code,
                    isSupported: config.status !== 'planned',
                    supportLevel: config.status,
                    confidence: 0.85
                };
            }
        }
        
        return {
            countryCode: null,
            countryName: 'Unknown',
            callingCode: null,
            isSupported: false,
            supportLevel: 'unsupported',
            confidence: 0
        };
    }

    /**
     * Obtenir les pays actifs pour une phase donnée
     */
    getCountriesByPhase(phase) {
        return this.deploymentPhases[phase] || [];
    }

    /**
     * Obtenir tous les pays avec leur statut
     */
    getAllCountries(includeStatus = null) {
        const countries = Object.entries(this.supportedCountries)
            .map(([code, config]) => ({
                code: code,
                name: config.name,
                callingCode: config.code,
                currency: config.currency,
                status: config.status,
                priority: config.priority,
                operatorCount: Object.keys(config.operators || {}).length,
                paymentOptions: config.localPartners?.length || 0
            }));
        
        if (includeStatus) {
            return countries.filter(country => country.status === includeStatus);
        }
        
        return countries.sort((a, b) => a.priority - b.priority);
    }

    /**
     * Proposer l'expansion vers un nouveau pays
     */
    proposeCountryExpansion(countryCode, marketData) {
        const proposal = {
            countryCode: countryCode,
            proposedAt: new Date(),
            marketData: marketData,
            requirements: this.analyzeExpansionRequirements(countryCode, marketData),
            timeline: this.estimateExpansionTimeline(marketData),
            risks: this.assessExpansionRisks(countryCode, marketData),
            opportunities: this.identifyOpportunities(marketData)
        };
        
        phoneLogger.log({
            action: 'country_expansion_proposed',
            countryCode: countryCode,
            proposal: proposal,
            timestamp: new Date()
        });
        
        return proposal;
    }

    // ===============================
    // CONFIGURATION PAR PAYS
    // ===============================

    getIvoryCoastOperators() {
        return {
            'Orange': {
                name: 'Orange CI',
                prefixes: ['07', '47', '67'],
                services: ['orange_money', 'wave'],
                marketShare: 0.45,
                reliability: 0.95,
                apiEndpoint: 'https://api.orange.ci',
                fees: { min: 0.01, max: 0.015 }
            },
            'MTN': {
                name: 'MTN CI',
                prefixes: ['05', '45', '65'],
                services: ['mtn_money', 'wave'],
                marketShare: 0.35,
                reliability: 0.93,
                apiEndpoint: 'https://api.mtn.ci',
                fees: { min: 0.015, max: 0.02 }
            },
            'Moov': {
                name: 'Moov CI',
                prefixes: ['01', '41', '61'],
                services: ['moov_money', 'wave'],
                marketShare: 0.20,
                reliability: 0.88,
                apiEndpoint: 'https://api.moov.ci',
                fees: { min: 0.02, max: 0.025 }
            }
        };
    }

    getSenegalOperators() {
        return {
            'Orange': {
                name: 'Orange SN',
                prefixes: ['77', '78'],
                services: ['orange_money', 'wave'],
                marketShare: 0.55,
                reliability: 0.96,
                apiEndpoint: 'https://api.orange.sn',
                fees: { min: 0.01, max: 0.015 }
            },
            'Free': {
                name: 'Free SN',
                prefixes: ['70', '76'],
                services: ['wave'],
                marketShare: 0.30,
                reliability: 0.90,
                apiEndpoint: 'https://api.free.sn',
                fees: { min: 0.015, max: 0.02 }
            },
            'Expresso': {
                name: 'Expresso SN',
                prefixes: ['75'],
                services: ['wave'],
                marketShare: 0.15,
                reliability: 0.85,
                apiEndpoint: 'https://api.expresso.sn',
                fees: { min: 0.02, max: 0.03 }
            }
        };
    }

    getMaliOperators() {
        return {
            'Orange': {
                name: 'Orange Mali',
                prefixes: ['77', '78'],
                services: ['orange_money', 'wave'],
                marketShare: 0.50,
                reliability: 0.92,
                apiEndpoint: 'https://api.orange.ml',
                fees: { min: 0.015, max: 0.02 },
                status: 'testing'
            },
            'Malitel': {
                name: 'Malitel',
                prefixes: ['66', '67'],
                services: ['wave'],
                marketShare: 0.35,
                reliability: 0.88,
                apiEndpoint: 'https://api.malitel.ml',
                fees: { min: 0.02, max: 0.025 },
                status: 'planned'
            }
        };
    }

    getBurkinaOperators() {
        return {
            'Orange': {
                name: 'Orange BF',
                prefixes: ['07', '77'],
                services: ['orange_money', 'wave'],
                marketShare: 0.45,
                reliability: 0.90,
                apiEndpoint: 'https://api.orange.bf',
                fees: { min: 0.015, max: 0.02 },
                status: 'testing'
            },
            'Moov': {
                name: 'Moov BF',
                prefixes: ['01', '61'],
                services: ['moov_money', 'wave'],
                marketShare: 0.40,
                reliability: 0.87,
                apiEndpoint: 'https://api.moov.bf',
                fees: { min: 0.02, max: 0.025 },
                status: 'planned'
            }
        };
    }

    getGuineaOperators() {
        return {
            'Orange': {
                name: 'Orange Guinée',
                prefixes: ['62', '66'],
                services: ['orange_money', 'wave'],
                marketShare: 0.40,
                reliability: 0.85,
                apiEndpoint: 'https://api.orange.gn',
                fees: { min: 0.02, max: 0.03 },
                status: 'research'
            },
            'MTN': {
                name: 'MTN Guinée',
                prefixes: ['65', '67'],
                services: ['mtn_money', 'wave'],
                marketShare: 0.35,
                reliability: 0.83,
                apiEndpoint: 'https://api.mtn.gn',
                fees: { min: 0.025, max: 0.03 },
                status: 'research'
            }
        };
    }

    getTogoOperators() {
        return {
            'Togocel': {
                name: 'Togocel',
                prefixes: ['90', '91'],
                services: ['t_money'],
                marketShare: 0.50,
                reliability: 0.80,
                status: 'research'
            },
            'Moov': {
                name: 'Moov Togo',
                prefixes: ['92', '93'],
                services: ['moov_money'],
                marketShare: 0.35,
                reliability: 0.78,
                status: 'research'
            }
        };
    }

    getBeninOperators() {
        return {
            'MTN': {
                name: 'MTN Bénin',
                prefixes: ['96', '97'],
                services: ['mtn_money'],
                marketShare: 0.45,
                reliability: 0.82,
                status: 'research'
            },
            'Moov': {
                name: 'Moov Bénin',
                prefixes: ['94', '95'],
                services: ['moov_money'],
                marketShare: 0.40,
                reliability: 0.80,
                status: 'research'
            }
        };
    }

    getNigerOperators() {
        return {
            'Orange': {
                name: 'Orange Niger',
                prefixes: ['96', '97'],
                services: ['orange_money'],
                marketShare: 0.40,
                reliability: 0.75,
                status: 'research'
            },
            'Airtel': {
                name: 'Airtel Niger',
                prefixes: ['94', '95'],
                services: ['airtel_money'],
                marketShare: 0.35,
                reliability: 0.73,
                status: 'research'
            }
        };
    }

    getChadOperators() {
        return {
            'Airtel': {
                name: 'Airtel Tchad',
                prefixes: ['66', '77'],
                services: ['airtel_money'],
                marketShare: 0.45,
                reliability: 0.70,
                status: 'research'
            },
            'Tigo': {
                name: 'Tigo Tchad',
                prefixes: ['99', '95'],
                services: ['tigo_cash'],
                marketShare: 0.30,
                reliability: 0.68,
                status: 'research'
            }
        };
    }

    // ===============================
    // RÉGLEMENTATIONS PAR PAYS
    // ===============================

    getIvoryCoastRegulations() {
        return {
            maxTransactionAmount: 1000000, // CFA
            dailyLimit: 2000000,
            monthlyLimit: 50000000,
            kycRequired: true,
            antiMoneyLaundering: 'strict',
            taxOnTransactions: 0.001, // 0.1%
            licenses: ['BCEAO_APPROVAL']
        };
    }

    getSenegalRegulations() {
        return {
            maxTransactionAmount: 2000000, // CFA
            dailyLimit: 5000000,
            monthlyLimit: 100000000,
            kycRequired: true,
            antiMoneyLaundering: 'strict',
            taxOnTransactions: 0.0015, // 0.15%
            licenses: ['BCEAO_APPROVAL']
        };
    }

    getMaliRegulations() {
        return {
            maxTransactionAmount: 500000, // CFA
            dailyLimit: 1000000,
            monthlyLimit: 25000000,
            kycRequired: true,
            antiMoneyLaundering: 'moderate',
            taxOnTransactions: 0.002, // 0.2%
            licenses: ['BCEAO_APPROVAL'],
            additionalRequirements: ['local_partner_mandatory']
        };
    }

    getBurkinaRegulations() {
        return {
            maxTransactionAmount: 750000, // CFA
            dailyLimit: 1500000,
            monthlyLimit: 30000000,
            kycRequired: true,
            antiMoneyLaundering: 'moderate',
            taxOnTransactions: 0.0015, // 0.15%
            licenses: ['BCEAO_APPROVAL']
        };
    }

    getGuineaRegulations() {
        return {
            maxTransactionAmount: 10000000, // GNF
            dailyLimit: 25000000,
            monthlyLimit: 500000000,
            kycRequired: true,
            antiMoneyLaundering: 'moderate',
            taxOnTransactions: 0.003, // 0.3%
            licenses: ['CENTRAL_BANK_APPROVAL'],
            specialRequirements: ['government_partnership']
        };
    }

    getTogoRegulations() {
        return {
            maxTransactionAmount: 500000, // CFA
            dailyLimit: 1000000,
            monthlyLimit: 20000000,
            kycRequired: true,
            antiMoneyLaundering: 'moderate',
            taxOnTransactions: 0.002, // 0.2%
            licenses: ['BCEAO_APPROVAL']
        };
    }

    getBeninRegulations() {
        return {
            maxTransactionAmount: 750000, // CFA
            dailyLimit: 1500000,
            monthlyLimit: 30000000,
            kycRequired: true,
            antiMoneyLaundering: 'strict',
            taxOnTransactions: 0.0015, // 0.15%
            licenses: ['BCEAO_APPROVAL']
        };
    }

    getNigerRegulations() {
        return {
            maxTransactionAmount: 400000, // CFA
            dailyLimit: 800000,
            monthlyLimit: 15000000,
            kycRequired: true,
            antiMoneyLaundering: 'strict',
            taxOnTransactions: 0.0025, // 0.25%
            licenses: ['BCEAO_APPROVAL', 'MINISTRY_APPROVAL']
        };
    }

    getChadRegulations() {
        return {
            maxTransactionAmount: 300000, // CFA
            dailyLimit: 600000,
            monthlyLimit: 12000000,
            kycRequired: true,
            antiMoneyLaundering: 'strict',
            taxOnTransactions: 0.003, // 0.3%
            licenses: ['BEAC_APPROVAL', 'MINISTRY_APPROVAL'],
            specialRequirements: ['security_clearance']
        };
    }

    // ===============================
    // MÉTHODES D'ANALYSE
    // ===============================

    analyzeExpansionRequirements(countryCode, marketData) {
        return {
            legal: ['business_license', 'financial_service_permit', 'data_protection_compliance'],
            technical: ['local_servers', 'operator_integrations', 'localization'],
            financial: ['initial_investment', 'operational_costs', 'compliance_costs'],
            human: ['local_team', 'legal_counsel', 'technical_support'],
            partnerships: ['payment_providers', 'local_banks', 'government_relations']
        };
    }

    estimateExpansionTimeline(marketData) {
        return {
            research: '2-3 months',
            legal_setup: '3-6 months',
            technical_integration: '4-6 months',
            testing: '2-3 months',
            launch: '1-2 months',
            total: '12-20 months'
        };
    }

    assessExpansionRisks(countryCode, marketData) {
        return {
            regulatory: 'medium',
            technical: 'low',
            financial: 'medium',
            political: 'low',
            competition: 'high',
            currency: 'low'
        };
    }

    identifyOpportunities(marketData) {
        return {
            marketSize: marketData?.population || 'unknown',
            digitalAdoption: 'growing',
            competition: 'moderate',
            partnershipPotential: 'high',
            scalabilityFactor: 0.8
        };
    }
}

module.exports = new CountryExpansionService();
