const Payout = require('../models/payout.model');
const Reservation = require('../models/reservation.model');
const Partner = require('../models/partner.model');
const payoutService = require('../services/payout.service');
const cinetPayTransferService = require('../services/cinetpay-transfer.service');
const logger = require('../utils/logger');

/**
 * Contrôleur Payout - Gestion des reversements aux partners
 * 
 * Endpoints:
 * - POST /api/payouts/create/:reservationId - Créer payout pour réservation
 * - GET /api/payouts/partner/:partnerId - Liste payouts d'un partner
 * - POST /api/payouts/execute/:payoutId - Exécuter payout manuellement
 * - GET /api/payouts/stats/:partnerId - Statistiques payout partner
 * - POST /api/payouts/cinetpay/webhook - Webhook CinetPay Transfer
 * - GET /api/payouts/balance - Solde compte CinetPay
 */

// ===============================
// CRÉATION DE PAYOUTS
// ===============================

/**
 * Créer un payout pour une réservation payée
 * POST /api/payouts/create/:reservationId
 */
exports.createPayoutForReservation = async (req, res) => {
    try {
        const { reservationId } = req.params;
        const { scheduleDelayHours } = req.body; // Optionnel

        // Vérifier les permissions (admin/superadmin ou partner propriétaire)
        const reservation = await Reservation.findById(reservationId).populate('partner');
        
        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: "Réservation non trouvée"
            });
        }

        // Vérifier authorization
        if (req.user.role !== 'admin' && req.user.role !== 'superadmin') {
            if (req.user.role === 'partner' && reservation.partner._id.toString() !== req.user._id.toString()) {
                return res.status(403).json({
                    success: false,
                    message: "Vous n'êtes pas autorisé à créer ce payout"
                });
            }
        }

        // Créer le payout
        const payout = await payoutService.createPayoutForReservation(
            reservationId, 
            scheduleDelayHours
        );

        logger.info(`Payout créé par ${req.user.email}: ${payout.payout_id}`);

        res.status(201).json({
            success: true,
            message: "Payout créé avec succès",
            data: {
                payout: {
                    payout_id: payout.payout_id,
                    status: payout.status,
                    net_amount: payout.net_amount,
                    currency: payout.currency,
                    scheduled_for: payout.scheduled_for,
                    partner: payout.partner,
                    channel: payout.channel
                }
            }
        });

    } catch (error) {
        logger.error('Erreur création payout:', error);
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

/**
 * Créer des payouts en batch pour plusieurs réservations
 * POST /api/payouts/create/batch
 */
exports.createBatchPayouts = async (req, res) => {
    try {
        const { reservationIds, scheduleDelayHours } = req.body;

        // Validation
        if (!Array.isArray(reservationIds) || reservationIds.length === 0) {
            return res.status(400).json({
                success: false,
                message: "Liste de réservations requise"
            });
        }

        // Vérifier permissions admin
        if (req.user.role !== 'admin' && req.user.role !== 'superadmin') {
            return res.status(403).json({
                success: false,
                message: "Seuls les admins peuvent créer des payouts en batch"
            });
        }

        const results = await payoutService.createBatchPayouts(reservationIds, scheduleDelayHours);

        const successful = results.filter(r => r.success);
        const failed = results.filter(r => !r.success);

        logger.info(`Batch payouts créés: ${successful.length}/${results.length} réussis`);

        res.json({
            success: true,
            message: `${successful.length}/${results.length} payouts créés`,
            data: {
                successful: successful.length,
                failed: failed.length,
                results: results
            }
        });

    } catch (error) {
        logger.error('Erreur création batch payouts:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

// ===============================
// CONSULTATION DE PAYOUTS
// ===============================

/**
 * Récupérer les payouts d'un partner
 * GET /api/payouts/partner/:partnerId
 */
exports.getPartnerPayouts = async (req, res) => {
    try {
        const { partnerId } = req.params;
        const { 
            status, 
            limit = 20, 
            offset = 0, 
            startDate, 
            endDate,
            sortBy = 'createdAt',
            sortOrder = 'desc'
        } = req.query;

        // Vérifier authorization
        if (req.user.role !== 'admin' && req.user.role !== 'superadmin') {
            if (req.user.role === 'partner' && req.user._id.toString() !== partnerId) {
                return res.status(403).json({
                    success: false,
                    message: "Vous ne pouvez voir que vos propres payouts"
                });
            }
        }

        // Construction du filtre
        const filter = { partner: partnerId };
        
        if (status) {
            filter.status = status;
        }
        
        if (startDate || endDate) {
            filter.createdAt = {};
            if (startDate) filter.createdAt.$gte = new Date(startDate);
            if (endDate) filter.createdAt.$lte = new Date(endDate);
        }

        // Exécution de la requête
        const payouts = await Payout.find(filter)
            .populate('partner', 'businessName email phone')
            .populate('source_transactions', 'amount transactionId createdAt')
            .sort({ [sortBy]: sortOrder === 'desc' ? -1 : 1 })
            .limit(parseInt(limit))
            .skip(parseInt(offset));

        const total = await Payout.countDocuments(filter);

        res.json({
            success: true,
            data: {
                payouts,
                pagination: {
                    total,
                    limit: parseInt(limit),
                    offset: parseInt(offset),
                    hasNext: total > (parseInt(offset) + parseInt(limit))
                }
            }
        });

    } catch (error) {
        logger.error('Erreur récupération payouts partner:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

/**
 * Récupérer un payout spécifique
 * GET /api/payouts/:payoutId
 */
exports.getPayoutById = async (req, res) => {
    try {
        const { payoutId } = req.params;

        const payout = await Payout.findOne({ payout_id: payoutId })
            .populate('partner', 'businessName email phone payoutPreferences')
            .populate('source_transactions');

        if (!payout) {
            return res.status(404).json({
                success: false,
                message: "Payout non trouvé"
            });
        }

        // Vérifier authorization
        if (req.user.role !== 'admin' && req.user.role !== 'superadmin') {
            if (req.user.role === 'partner' && payout.partner._id.toString() !== req.user._id.toString()) {
                return res.status(403).json({
                    success: false,
                    message: "Accès non autorisé à ce payout"
                });
            }
        }

        res.json({
            success: true,
            data: { payout }
        });

    } catch (error) {
        logger.error('Erreur récupération payout:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

// ===============================
// EXÉCUTION DE PAYOUTS
// ===============================

/**
 * Exécuter un payout manuellement
 * POST /api/payouts/execute/:payoutId
 */
exports.executePayoutManually = async (req, res) => {
    try {
        const { payoutId } = req.params;
        const { force = false } = req.body;

        // Seuls les admins peuvent forcer l'exécution
        if (req.user.role !== 'admin' && req.user.role !== 'superadmin') {
            return res.status(403).json({
                success: false,
                message: "Seuls les admins peuvent exécuter des payouts manuellement"
            });
        }

        const payout = await Payout.findOne({ payout_id: payoutId });

        if (!payout) {
            return res.status(404).json({
                success: false,
                message: "Payout non trouvé"
            });
        }

        // Vérifications de statut
        if (!force && payout.status !== 'PAYOUT_SCHEDULED') {
            return res.status(400).json({
                success: false,
                message: `Payout pas en statut SCHEDULED: ${payout.status}. Utilisez force=true pour ignorer.`
            });
        }

        if (!force && payout.attempts >= 5) {
            return res.status(400).json({
                success: false,
                message: "Nombre maximum de tentatives atteint. Utilisez force=true pour réinitialiser."
            });
        }

        // Réinitialiser si forcé
        if (force && payout.attempts >= 5) {
            payout.attempts = 0;
            payout.status = 'PAYOUT_SCHEDULED';
            await payout.save();
        }

        // Exécuter le payout
        const result = await payoutService.executePayout(payout);

        logger.info(`Payout exécuté manuellement par ${req.user.email}: ${payoutId}`);

        res.json({
            success: true,
            message: "Payout exécuté avec succès",
            data: {
                payout_id: payoutId,
                status: result.status,
                transaction_id: result.transaction_id,
                requires_confirmation: result.requires_confirmation
            }
        });

    } catch (error) {
        logger.error('Erreur exécution payout manuelle:', error);
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

/**
 * Traiter tous les payouts en attente
 * POST /api/payouts/process/scheduled
 */
exports.processScheduledPayouts = async (req, res) => {
    try {
        // Seuls les admins
        if (req.user.role !== 'admin' && req.user.role !== 'superadmin') {
            return res.status(403).json({
                success: false,
                message: "Accès réservé aux admins"
            });
        }

        const results = await payoutService.processScheduledPayouts();

        logger.info(`Traitement payouts schedulés par ${req.user.email}: ${results.successful}/${results.processed}`);

        res.json({
            success: true,
            message: `${results.successful}/${results.processed} payouts traités avec succès`,
            data: results
        });

    } catch (error) {
        logger.error('Erreur traitement payouts schedulés:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

// ===============================
// SYNCHRONISATION
// ===============================

/**
 * Synchroniser les payouts en cours avec CinetPay
 * POST /api/payouts/sync/pending
 */
exports.syncPendingPayouts = async (req, res) => {
    try {
        // Seuls les admins
        if (req.user.role !== 'admin' && req.user.role !== 'superadmin') {
            return res.status(403).json({
                success: false,
                message: "Accès réservé aux admins"
            });
        }

        const results = await payoutService.syncAllPendingPayouts();

        logger.info(`Sync payouts par ${req.user.email}: ${results.completed} complétés, ${results.failed} échecs`);

        res.json({
            success: true,
            message: `Synchronisation terminée: ${results.completed} complétés`,
            data: results
        });

    } catch (error) {
        logger.error('Erreur sync payouts:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

// ===============================
// STATISTIQUES
// ===============================

/**
 * Récupérer les statistiques de payout d'un partner
 * GET /api/payouts/stats/:partnerId
 */
exports.getPartnerPayoutStats = async (req, res) => {
    try {
        const { partnerId } = req.params;
        const { startDate, endDate } = req.query;

        // Vérifier authorization
        if (req.user.role !== 'admin' && req.user.role !== 'superadmin') {
            if (req.user.role === 'partner' && req.user._id.toString() !== partnerId) {
                return res.status(403).json({
                    success: false,
                    message: "Accès non autorisé"
                });
            }
        }

        const stats = await payoutService.getPartnerPayoutStats(
            partnerId,
            startDate ? new Date(startDate) : null,
            endDate ? new Date(endDate) : null
        );

        res.json({
            success: true,
            data: { stats }
        });

    } catch (error) {
        logger.error('Erreur stats payout:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

// ===============================
// GESTION CINETPAY
// ===============================

/**
 * Vérifier le solde du compte CinetPay Transfer
 * GET /api/payouts/balance
 */
exports.getCinetPayBalance = async (req, res) => {
    try {
        // Seuls les admins
        if (req.user.role !== 'admin' && req.user.role !== 'superadmin') {
            return res.status(403).json({
                success: false,
                message: "Accès réservé aux admins"
            });
        }

        const balance = await cinetPayTransferService.checkBalance();

        res.json({
            success: true,
            message: "Solde récupéré avec succès",
            data: { balance }
        });

    } catch (error) {
        logger.error('Erreur récupération solde CinetPay:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

/**
 * Webhook CinetPay Transfer pour les notifications de transfert
 * POST /api/payouts/cinetpay/webhook
 */
exports.handleCinetPayTransferWebhook = async (req, res) => {
    try {
        const webhookData = req.body;
        
        logger.info('Webhook CinetPay Transfer reçu:', JSON.stringify(webhookData));

        // Validation basique du webhook
        if (!webhookData.transaction_id && !webhookData.client_transaction_id) {
            return res.status(400).json({
                success: false,
                message: "Webhook invalide: transaction_id manquant"
            });
        }

        // Rechercher le payout correspondant
        const identifier = webhookData.client_transaction_id || webhookData.transaction_id;
        const fieldName = webhookData.client_transaction_id ? 
            'cinetpay_info.client_transaction_id' : 
            'cinetpay_info.transaction_id';

        const payout = await Payout.findOne({ [fieldName]: identifier });

        if (!payout) {
            logger.warn(`Payout non trouvé pour ${fieldName}: ${identifier}`);
            return res.status(404).json({
                success: false,
                message: "Payout non trouvé"
            });
        }

        // Mettre à jour le statut selon les données CinetPay
        let statusUpdated = false;

        if (webhookData.treatment_status) {
            payout.cinetpay_info.treatment_status = webhookData.treatment_status;
            
            switch (webhookData.treatment_status) {
                case 'VAL': // Validé = Succès
                    if (payout.status !== 'PAYOUT_SUCCESS') {
                        payout.markAsSuccess(webhookData);
                        statusUpdated = true;
                    }
                    break;
                    
                case 'REJECT': // Rejeté = Échec
                    if (payout.status !== 'PAYOUT_FAILED') {
                        payout.markAsFailed(`Transfert rejeté: ${webhookData.comment || 'Raison inconnue'}`);
                        statusUpdated = true;
                    }
                    break;
            }
        }

        if (webhookData.sending_status) {
            payout.cinetpay_info.sending_status = webhookData.sending_status;
        }

        await payout.save();

        if (statusUpdated) {
            logger.info(`Payout ${payout.payout_id} mis à jour via webhook: ${payout.status}`);
            
            // Déclencher notifications selon le nouveau statut
            if (payout.status === 'PAYOUT_SUCCESS') {
                await payoutService.notifyPayoutCompleted(payout);
            } else if (payout.status === 'PAYOUT_FAILED') {
                await payoutService.notifyPayoutFailed(payout, payout.failure_reason);
            }
        }

        res.json({
            success: true,
            message: "Webhook traité avec succès"
        });

    } catch (error) {
        logger.error('Erreur webhook CinetPay Transfer:', error);
        res.status(500).json({
            success: false,
            message: "Erreur traitement webhook"
        });
    }
};

// ===============================
// UTILITAIRES ADMIN
// ===============================

/**
 * Réinitialiser un payout échoué (admin seulement)
 * POST /api/payouts/reset/:payoutId
 */
exports.resetFailedPayout = async (req, res) => {
    try {
        const { payoutId } = req.params;

        // Seuls les admins
        if (req.user.role !== 'admin' && req.user.role !== 'superadmin') {
            return res.status(403).json({
                success: false,
                message: "Accès réservé aux admins"
            });
        }

        const payout = await Payout.findOne({ payout_id: payoutId });

        if (!payout) {
            return res.status(404).json({
                success: false,
                message: "Payout non trouvé"
            });
        }

        // Réinitialiser le payout
        payout.status = 'PAYOUT_SCHEDULED';
        payout.attempts = 0;
        payout.failure_reason = null;
        payout.last_error = null;
        payout.scheduled_for = new Date(Date.now() + 5 * 60 * 1000); // Dans 5 minutes

        payout.addHistoryEntry('PAYOUT_SCHEDULED', `Réinitialisé par ${req.user.email}`);
        await payout.save();

        logger.info(`Payout réinitialisé par ${req.user.email}: ${payoutId}`);

        res.json({
            success: true,
            message: "Payout réinitialisé avec succès",
            data: {
                payout_id: payoutId,
                status: payout.status,
                scheduled_for: payout.scheduled_for
            }
        });

    } catch (error) {
        logger.error('Erreur réinitialisation payout:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};
