const express = require('express');
const router = express.Router();
const payoutController = require('../controllers/payout.controller');
const authMiddleware = require('../middlewares/auth.middleware');
const { validate } = require('../middlewares/validation.middleware');
const { body, param, query } = require('express-validator');

/**
 * Routes Payout - Gestion des reversements aux partners
 * 
 * Toutes les routes nécessitent une authentification
 * Certaines routes nécessitent des permissions admin/superadmin
 */

// ===============================
// MIDDLEWARE GLOBAL
// ===============================
router.use(authMiddleware);

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
// ROUTES CINETPAY
// ===============================

/**
 * Vérifier le solde CinetPay
 * GET /api/payouts/balance
 * 
 * Permissions: Admin, SuperAdmin uniquement
 */
router.get('/balance',
    payoutController.getCinetPayBalance
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
