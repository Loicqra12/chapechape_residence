const asyncHandler = require('../middlewares/async.middleware');
const countryExpansionService = require('../services/country-expansion.service');
const phoneLogger = require('../utils/phoneLogger');
const apiError = require('../utils/apiError');

// @desc    Obtenir tous les pays supportés
// @route   GET /api/countries
// @access  Public
exports.getAllCountries = asyncHandler(async (req, res) => {
    const { status } = req.query;
    
    try {
        const countries = countryExpansionService.getAllCountries(status);
        
        res.status(200).json({
            success: true,
            count: countries.length,
            data: countries
        });
    } catch (error) {
        throw new apiError('Erreur récupération pays', 500);
    }
});

// @desc    Obtenir la configuration d'un pays spécifique
// @route   GET /api/countries/:countryCode
// @access  Public
exports.getCountryConfig = asyncHandler(async (req, res) => {
    const { countryCode } = req.params;
    
    const config = countryExpansionService.getCountryConfig(countryCode);
    
    if (!config) {
        throw new apiError('Pays non supporté', 404);
    }
    
    res.status(200).json({
        success: true,
        data: config
    });
});

// @desc    Détecter le pays depuis un numéro de téléphone
// @route   POST /api/countries/detect
// @access  Public
exports.detectCountryFromPhone = asyncHandler(async (req, res) => {
    const { phoneNumber } = req.body;
    
    if (!phoneNumber) {
        throw new apiError('Numéro de téléphone requis', 400);
    }
    
    try {
        const detection = countryExpansionService.detectCountryFromPhone(phoneNumber);
        
        // Logger la détection
        phoneLogger.log({
            action: 'country_detection',
            phoneNumber: phoneNumber,
            detectedCountry: detection.countryCode,
            confidence: detection.confidence,
            timestamp: new Date()
        });
        
        res.status(200).json({
            success: true,
            data: detection
        });
    } catch (error) {
        throw new apiError('Erreur détection pays', 500);
    }
});

// @desc    Vérifier si un pays supporte une fonctionnalité
// @route   GET /api/countries/:countryCode/support/:feature
// @access  Public
exports.checkCountrySupport = asyncHandler(async (req, res) => {
    const { countryCode, feature } = req.params;
    
    const isSupported = countryExpansionService.isCountrySupported(countryCode, feature);
    const config = countryExpansionService.getCountryConfig(countryCode);
    
    res.status(200).json({
        success: true,
        data: {
            countryCode: countryCode,
            feature: feature,
            isSupported: isSupported,
            supportLevel: config?.status || 'unsupported',
            details: config ? {
                name: config.name,
                callingCode: config.code,
                currency: config.currency,
                operatorCount: Object.keys(config.operators || {}).length
            } : null
        }
    });
});

// @desc    Obtenir les pays par phase de déploiement
// @route   GET /api/countries/phases/:phase
// @access  Public
exports.getCountriesByPhase = asyncHandler(async (req, res) => {
    const { phase } = req.params;
    
    const countries = countryExpansionService.getCountriesByPhase(phase);
    
    if (countries.length === 0) {
        throw new apiError('Phase non trouvée', 404);
    }
    
    // Enrichir avec les détails
    const enrichedCountries = countries.map(countryCode => {
        const config = countryExpansionService.getCountryConfig(countryCode);
        return {
            code: countryCode,
            ...config
        };
    });
    
    res.status(200).json({
        success: true,
        phase: phase,
        count: countries.length,
        data: enrichedCountries
    });
});

// @desc    Proposer l'expansion vers un nouveau pays
// @route   POST /api/countries/propose-expansion
// @access  Private (Admin uniquement)
exports.proposeExpansion = asyncHandler(async (req, res) => {
    const { countryCode, marketData } = req.body;
    
    if (!countryCode) {
        throw new apiError('Code pays requis', 400);
    }
    
    // Vérifier les permissions admin
    if (req.user.role !== 'admin' && req.user.role !== 'superadmin') {
        throw new apiError('Accès réservé aux administrateurs', 403);
    }
    
    try {
        const proposal = countryExpansionService.proposeCountryExpansion(countryCode, marketData);
        
        res.status(201).json({
            success: true,
            message: 'Proposition d\'expansion créée',
            data: proposal
        });
    } catch (error) {
        throw new apiError('Erreur création proposition', 500);
    }
});

// @desc    Obtenir les opérateurs d'un pays avec détails complets
// @route   GET /api/countries/:countryCode/operators
// @access  Public
exports.getCountryOperators = asyncHandler(async (req, res) => {
    const { countryCode } = req.params;
    const { includeInactive } = req.query;
    
    const config = countryExpansionService.getCountryConfig(countryCode);
    
    if (!config) {
        throw new apiError('Pays non supporté', 404);
    }
    
    let operators = config.operators || {};
    
    // Filtrer les opérateurs inactifs si demandé
    if (!includeInactive) {
        operators = Object.fromEntries(
            Object.entries(operators).filter(([_, op]) => 
                !op.status || op.status !== 'inactive'
            )
        );
    }
    
    // Enrichir avec des statistiques
    const enrichedOperators = Object.entries(operators).map(([key, operator]) => ({
        code: key,
        ...operator,
        estimatedUsers: Math.floor((operator.marketShare || 0) * (config.estimatedPopulation || 1000000)),
        supportedFeatures: {
            payments: operator.services?.length > 0,
            verification: operator.reliability > 0.8,
            api: !!operator.apiEndpoint
        }
    }));
    
    res.status(200).json({
        success: true,
        country: {
            code: countryCode,
            name: config.name,
            status: config.status
        },
        operators: enrichedOperators,
        summary: {
            total: enrichedOperators.length,
            active: enrichedOperators.filter(op => !op.status || op.status !== 'inactive').length,
            withApi: enrichedOperators.filter(op => !!op.apiEndpoint).length,
            avgReliability: (enrichedOperators.reduce((sum, op) => sum + (op.reliability || 0), 0) / enrichedOperators.length).toFixed(2)
        }
    });
});

// @desc    Obtenir les réglementations d'un pays
// @route   GET /api/countries/:countryCode/regulations
// @access  Private
exports.getCountryRegulations = asyncHandler(async (req, res) => {
    const { countryCode } = req.params;
    
    const config = countryExpansionService.getCountryConfig(countryCode);
    
    if (!config) {
        throw new apiError('Pays non supporté', 404);
    }
    
    const regulations = config.regulations || {};
    
    // Masquer certaines informations sensibles pour les non-admins
    if (req.user.role !== 'admin' && req.user.role !== 'superadmin') {
        delete regulations.licenses;
        delete regulations.specialRequirements;
        delete regulations.taxOnTransactions;
    }
    
    res.status(200).json({
        success: true,
        country: {
            code: countryCode,
            name: config.name
        },
        data: regulations
    });
});

// @desc    Statistiques globales des pays
// @route   GET /api/countries/stats
// @access  Private (Admin)
exports.getCountriesStats = asyncHandler(async (req, res) => {
    if (req.user.role !== 'admin' && req.user.role !== 'superadmin') {
        throw new apiError('Accès réservé aux administrateurs', 403);
    }
    
    try {
        const allCountries = countryExpansionService.getAllCountries();
        
        const stats = {
            overview: {
                total: allCountries.length,
                byStatus: {},
                totalOperators: 0,
                totalPaymentOptions: 0
            },
            phases: {},
            topCountries: allCountries
                .filter(c => c.status === 'active')
                .sort((a, b) => b.operatorCount - a.operatorCount)
                .slice(0, 5),
            expansion: {
                nextPhase: countryExpansionService.getCountriesByPhase('phase3'),
                inDevelopment: allCountries.filter(c => c.status === 'beta').length,
                planned: allCountries.filter(c => c.status === 'planned').length
            }
        };
        
        // Statistiques par statut
        allCountries.forEach(country => {
            stats.overview.byStatus[country.status] = 
                (stats.overview.byStatus[country.status] || 0) + 1;
            stats.overview.totalOperators += country.operatorCount;
            stats.overview.totalPaymentOptions += country.paymentOptions;
        });
        
        // Statistiques par phase
        Object.entries(countryExpansionService.deploymentPhases).forEach(([phase, countries]) => {
            stats.phases[phase] = {
                count: countries.length,
                countries: countries
            };
        });
        
        res.status(200).json({
            success: true,
            data: stats
        });
    } catch (error) {
        throw new apiError('Erreur calcul statistiques', 500);
    }
});

module.exports = {
    getAllCountries: exports.getAllCountries,
    getCountryConfig: exports.getCountryConfig,
    detectCountryFromPhone: exports.detectCountryFromPhone,
    checkCountrySupport: exports.checkCountrySupport,
    getCountriesByPhase: exports.getCountriesByPhase,
    proposeExpansion: exports.proposeExpansion,
    getCountryOperators: exports.getCountryOperators,
    getCountryRegulations: exports.getCountryRegulations,
    getCountriesStats: exports.getCountriesStats
};
