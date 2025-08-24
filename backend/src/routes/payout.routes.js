const express = require('express');
const router = express.Router();
const payoutController = require('../controllers/payout.controller');
const authMiddleware = require('../middlewares/auth.middleware');
const logger = require('../utils/logger');
const { validationResult } = require('express-validator');

logger.info('🔧 Routes payout chargées avec succès');

const { body, param, query } = require('express-validator');

// Middleware de validation pour express-validator
const validate = (req, res, next) => {
    logger.info('Middleware de validation express-validator appelé', { 
        url: req.originalUrl, 
        method: req.method 
    });
    
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        const errorMessage = errors.array().map(err => err.msg).join(', ');
        logger.error('Erreur de validation', { errors: errors.array(), body: req.body });
        return res.status(400).json({
            success: false,
            message: errorMessage,
            errors: errors.array()
        });
    }
    
    logger.info('Validation réussie, passage au contrôleur');
    next();
};

/**
 * Routes Payout - Gestion des reversements aux partners
 * 
 * Toutes les routes nécessitent une authentification
 * Certaines routes nécessitent des permissions admin/superadmin
 */

// ===============================
// MIDDLEWARE GLOBAL
// ===============================
router.use(authMiddleware.protect);

// ===============================
// VALIDATION SCHEMAS
// ===============================

const createPayoutValidation = [
    param('reservationId')
        .isMongoId()
        .withMessage('ID de réservation invalide'),
    body('scheduleDelayHours')
        .optional()
        .isInt({ min: 0, max: 168 }) // Max 1 semaine
        .withMessage('Délai de programmation invalide (0-168 heures)'),
    validate
];

const batchCreateValidation = [
    body('reservationIds')
        .isArray({ min: 1, max: 100 })
        .withMessage('Liste de réservations requise (1-100 éléments)'),
    body('reservationIds.*')
        .isMongoId()
        .withMessage('ID de réservation invalide'),
    body('scheduleDelayHours')
        .optional()
        .isInt({ min: 0, max: 168 })
        .withMessage('Délai de programmation invalide'),
    validate
];

const partnerPayoutsValidation = [
    param('partnerId')
        .isMongoId()
        .withMessage('ID partner invalide'),
    query('status')
        .optional()
        .isIn(['PAYOUT_SCHEDULED', 'PAYOUT_PENDING', 'PAYOUT_SUCCESS', 'PAYOUT_FAILED', 'PAYOUT_CANCELLED'])
        .withMessage('Statut invalide'),
    query('limit')
        .optional()
        .isInt({ min: 1, max: 100 })
        .withMessage('Limite invalide (1-100)'),
    query('offset')
        .optional()
        .isInt({ min: 0 })
        .withMessage('Offset invalide'),
    query('startDate')
        .optional()
        .isISO8601()
        .withMessage('Date de début invalide'),
    query('endDate')
        .optional()
        .isISO8601()
        .withMessage('Date de fin invalide'),
    query('sortBy')
        .optional()
        .isIn(['createdAt', 'scheduled_for', 'executed_at', 'net_amount', 'status'])
        .withMessage('Champ de tri invalide'),
    query('sortOrder')
        .optional()
        .isIn(['asc', 'desc'])
        .withMessage('Ordre de tri invalide'),
    validate
];

const payoutIdValidation = [
    param('payoutId')
        .matches(/^PAYOUT_/)
        .withMessage('Format ID payout invalide'),
    validate
];

const executePayoutValidation = [
    param('payoutId')
        .matches(/^PAYOUT_/)
        .withMessage('Format ID payout invalide'),
    body('force')
        .optional()
        .isBoolean()
        .withMessage('Force doit être un booléen'),
    validate
];

const statsValidation = [
    param('partnerId')
        .isMongoId()
        .withMessage('ID partner invalide'),
    query('startDate')
        .optional()
        .isISO8601()
        .withMessage('Date de début invalide'),
    query('endDate')
        .optional()
        .isISO8601()
        .withMessage('Date de fin invalide'),
    validate
];

// ===============================
// ROUTES DE CRÉATION
// ===============================

/**
 * Créer un payout pour une réservation
 * POST /api/payouts/create/:reservationId
 * 
 * Permissions: Partner (propriétaire), Admin, SuperAdmin
 * Body: { scheduleDelayHours?: number }
 */
router.post('/create/:reservationId', 
    createPayoutValidation,
    payoutController.createPayoutForReservation
);

/**
 * Créer des payouts en batch
 * POST /api/payouts/create/batch
 * 
 * Permissions: Admin, SuperAdmin uniquement
 * Body: { reservationIds: string[], scheduleDelayHours?: number }
 */
router.post('/create/batch',
    batchCreateValidation,
    payoutController.createBatchPayouts
);

// ===============================
// ROUTES DE CONSULTATION
// ===============================

/**
 * Récupérer les payouts d'un partner
 * GET /api/payouts/partner/:partnerId
 * 
 * Permissions: Partner (lui-même), Admin, SuperAdmin
 * Query: status?, limit?, offset?, startDate?, endDate?, sortBy?, sortOrder?
 */
router.get('/partner/:partnerId',
    partnerPayoutsValidation,
    payoutController.getPartnerPayouts
);

/**
 * Récupérer un payout spécifique
 * GET /api/payouts/:payoutId
 * 
 * Permissions: Partner (propriétaire), Admin, SuperAdmin
 */
router.get('/:payoutId',
    payoutIdValidation,
    payoutController.getPayoutById
);

// ===============================
// ROUTES D'EXÉCUTION
// ===============================

/**
 * Exécuter un payout manuellement
 * POST /api/payouts/execute/:payoutId
 * 
 * Permissions: Admin, SuperAdmin uniquement
 * Body: { force?: boolean }
 */
router.post('/execute/:payoutId',
    executePayoutValidation,
    payoutController.executePayoutManually
);

/**
 * Traiter tous les payouts programmés
 * POST /api/payouts/process/scheduled
 * 
 * Permissions: Admin, SuperAdmin uniquement
 */
router.post('/process/scheduled',
    payoutController.processScheduledPayouts
);

// ===============================
// ROUTES DE SYNCHRONISATION
// ===============================

/**
 * Synchroniser les payouts en cours avec CinetPay
 * POST /api/payouts/sync/pending
 * 
 * Permissions: Admin, SuperAdmin uniquement
 */
router.post('/sync/pending',
    payoutController.syncPendingPayouts
);

// ===============================
// ROUTES STATISTIQUES
// ===============================

/**
 * Statistiques payout d'un partner
 * GET /api/payouts/stats/:partnerId
 * 
 * Permissions: Partner (lui-même), Admin, SuperAdmin
 * Query: startDate?, endDate?
 */
router.get('/stats/:partnerId',
    statsValidation,
    payoutController.getPartnerPayoutStats
);

// ===============================
// ROUTES WAVE PAYOUTS
// ===============================

/**
 * Initier un transfert Wave
 * POST /api/payouts/wave/transfer
 * 
 * Permissions: Partner, Admin, SuperAdmin
 */
router.post('/wave/transfer',
    [
        body('amount').isFloat({ min: 100 }).withMessage('Montant minimum 100 FCFA'),
        body('mobile').matches(/^\+[1-9]\d{1,14}$/).withMessage('Numéro de téléphone invalide (format: +XXXXXXXXXXX)'),
        body('name').isLength({ min: 2, max: 255 }).withMessage('Nom requis (2-255 caractères)'),
        body('payment_reason').optional().isLength({ max: 40 }).withMessage('Motif max 40 caractères'),
        body('national_id').optional().isLength({ max: 255 }).withMessage('ID national max 255 caractères'),
        validate
    ],
    payoutController.initiateWaveTransfer
);

/**
 * Vérifier le statut d'un transfert Wave
 * GET /api/payouts/wave/transfer/:waveId/status
 * 
 * Permissions: Partner, Admin, SuperAdmin
 */
router.get('/wave/transfer/:waveId/status',
    [
        param('waveId').matches(/^pt-/).withMessage('ID Wave invalide (format: pt-xxx)'),
        validate
    ],
    payoutController.getWaveTransferStatus
);

/**
 * Rechercher des transferts Wave
 * GET /api/payouts/wave/search
 * 
 * Permissions: Partner, Admin, SuperAdmin
 */
router.get('/wave/search',
    [
        query('client_reference').optional().isLength({ min: 1 }).withMessage('Référence client requise'),
        validate
    ],
    payoutController.searchWaveTransfers
);

/**
 * Créer un batch de transferts Wave
 * POST /api/payouts/wave/batch
 * 
 * Permissions: Admin, SuperAdmin uniquement
 */
router.post('/wave/batch',
    [
        body('transfers').isArray({ min: 1, max: 100 }).withMessage('Liste de transferts requise (1-100)'),
        body('transfers.*.amount').isFloat({ min: 100 }).withMessage('Montant minimum 100 FCFA'),
        body('transfers.*.mobile').matches(/^\+[1-9]\d{1,14}$/).withMessage('Numéro invalide'),
        body('transfers.*.name').isLength({ min: 2, max: 255 }).withMessage('Nom requis'),
        validate
    ],
    payoutController.createWaveBatch
);

/**
 * Statut d'un batch Wave
 * GET /api/payouts/wave/batch/:batchId/status
 * 
 * Permissions: Admin, SuperAdmin
 */
router.get('/wave/batch/:batchId/status',
    [
        param('batchId').matches(/^pb-/).withMessage('ID batch invalide (format: pb-xxx)'),
        validate
    ],
    payoutController.getWaveBatchStatus
);

/**
 * Annuler un transfert Wave
 * POST /api/payouts/wave/transfer/:waveId/reverse
 * 
 * Permissions: Admin, SuperAdmin uniquement
 */
router.post('/wave/transfer/:waveId/reverse',
    [
        param('waveId').matches(/^pt-/).withMessage('ID Wave invalide'),
        validate
    ],
    payoutController.reverseWaveTransfer
);

/**
 * Webhook Wave Payout (pas d'authentification)
 * POST /api/payouts/wave/webhook
 * 
 * Appelé par Wave lors des notifications de transfert
 * Note: express.raw sera géré au niveau de app.js pour cette route
 */

// Créer un router spécial pour webhook sans auth
const webhookRouter = express.Router();
webhookRouter.post('/wave/webhook',
    payoutController.handleWavePayoutWebhook
);

// Exporter le webhook router séparément
module.exports.webhookRouter = webhookRouter;

// ===============================
// ROUTES CINETPAY
// ===============================

/**
 * Récupérer le solde CinetPay
 * GET /api/payouts/cinetpay/balance
 * 
 * Permissions: Partner, Admin, SuperAdmin
 */
router.get('/cinetpay/balance',
    payoutController.getCinetPayBalance
);

/**
 * Initier un transfert CinetPay
 * POST /api/payouts/cinetpay/transfer
 * 
 * Permissions: Partner, Admin, SuperAdmin
 */
router.post('/cinetpay/transfer',
    [
        body('payout_id').notEmpty().withMessage('ID payout requis'),
        body('amount').isFloat({ min: 100 }).withMessage('Montant minimum 100 FCFA'),
        body('phone_number').matches(/^\+[1-9]\d{1,14}$/).withMessage('Numéro de téléphone invalide (format: +XXXXXXXXXXX)'),
        body('first_name').optional().isString().withMessage('Prénom invalide'),
        body('last_name').optional().isString().withMessage('Nom invalide'),
        body('email').optional().isEmail().withMessage('Email invalide'),
        body('channel').optional().isIn(['orange_money', 'mtn_money', 'moov_money']).withMessage('Canal invalide'),
        validate
    ],
    payoutController.initiateCinetPayTransfer
);

/**
 * Vérifier le statut d'un transfert CinetPay
 * GET /api/payouts/cinetpay/transfer/:transferId/status
 * 
 * Permissions: Partner, Admin, SuperAdmin
 */
router.get('/cinetpay/transfer/:transferId/status',
    [
        param('transferId').notEmpty().withMessage('ID de transfert requis'),
        validate
    ],
    payoutController.getCinetPayTransferStatus
);

/**
 * Annuler un transfert CinetPay
 * POST /api/payouts/cinetpay/transfer/:transferId/cancel
 * 
 * Permissions: Partner (propriétaire), Admin, SuperAdmin
 */
router.post('/cinetpay/transfer/:transferId/cancel',
    [
        param('transferId').notEmpty().withMessage('ID de transfert requis'),
        validate
    ],
    payoutController.cancelCinetPayTransfer
);

/**
 * Récupérer l'historique des transferts CinetPay
 * GET /api/payouts/cinetpay/transfer/history
 * 
 * Permissions: Partner, Admin, SuperAdmin
 */
router.get('/cinetpay/transfer/history',
    [
        query('page').optional().isInt({ min: 1 }).withMessage('Page invalide'),
        query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limite invalide'),
        query('status').optional().isIn(['pending', 'completed', 'failed', 'cancelled']).withMessage('Statut invalide'),
        validate
    ],
    payoutController.getCinetPayTransferHistory
);

/**
 * Récupérer les statistiques des transferts CinetPay
 * GET /api/payouts/cinetpay/transfer/stats
 * 
 * Permissions: Partner, Admin, SuperAdmin
 */
router.get('/cinetpay/transfer/stats',
    [
        query('startDate').optional().isISO8601().withMessage('Date de début invalide'),
        query('endDate').optional().isISO8601().withMessage('Date de fin invalide'),
        validate
    ],
    payoutController.getCinetPayTransferStats
);

/**
 * Webhook CinetPay Transfer (pas d'authentification)
 * POST /api/payouts/cinetpay/webhook
 * 
 * Appelé par CinetPay lors des notifications de transfert
 */
router.post('/cinetpay/webhook',
    express.urlencoded({ extended: true }), // Parser form-data si nécessaire
    payoutController.handleCinetPayTransferWebhook
);

// ===============================
// ROUTES UTILITAIRES ADMIN
// ===============================

/**
 * Réinitialiser un payout échoué
 * POST /api/payouts/reset/:payoutId
 * 
 * Permissions: Admin, SuperAdmin uniquement
 */
router.post('/reset/:payoutId',
    payoutIdValidation,
    payoutController.resetFailedPayout
);

module.exports = router;
