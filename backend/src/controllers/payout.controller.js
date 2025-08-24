const Payout = require('../models/payout.model');
const Reservation = require('../models/reservation.model');
const Partner = require('../models/partner.model');
const payoutService = require('../services/payout.service');
const cinetPayTransferService = require('../services/cinetpay-transfer.service');
const wavePayoutService = require('../services/wave-payout.service');
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

// -----------------------------------------------------------
// Handlers CinetPay Transfer manquants (stubs pour éviter crash)
// -----------------------------------------------------------

/**
 * Initier un transfert CinetPay
 * POST /api/payouts/cinetpay/transfer
 */
exports.initiateCinetPayTransfer = async (req, res) => {
    try {
        logger.info('Handler initiateCinetPayTransfer appelé', { 
            body: req.body, 
            user: req.user?.email,
            hasUser: !!req.user 
        });
        
        const {
            payout_id,
            amount,
            phone_number,
            phone_prefix = '225',
            first_name,
            last_name,
            email,
            channel = 'cinetpay_transfer'
        } = req.body;

        // Validation des champs requis
        if (!payout_id || !amount || !phone_number) {
            return res.status(400).json({
                success: false,
                message: "Champs requis: payout_id, amount, phone_number"
            });
        }

        // Rechercher le payout existant
        const payout = await Payout.findOne({ payout_id });
        if (!payout) {
            return res.status(404).json({
                success: false,
                message: "Payout non trouvé"
            });
        }

        // Vérifier que le payout peut être traité
        if (payout.status !== 'PENDING') {
            return res.status(400).json({
                success: false,
                message: `Payout déjà traité (statut: ${payout.status})`
            });
        }

        // Préparer les informations du destinataire
        payout.recipient_info = {
            phone_number,
            phone_prefix,
            first_name: first_name || 'Partner',
            last_name: last_name || 'ChapeChape',
            email: email || `partner_${payout_id}@chapechape.com`
        };

        // Générer un ID de transaction client unique
        payout.cinetpay_info.client_transaction_id = `CP_${payout_id}_${Date.now()}`;
        payout.channel = channel;
        payout.net_amount = amount;

        // Effectuer le transfert via CinetPay
        const result = await cinetPayTransferService.sendMoney(payout);

        if (result.success) {
            await payout.save();
            
            logger.info(`Transfert CinetPay initié: ${result.transaction_id} (${amount} XOF)`);
            
            res.status(201).json({
                success: true,
                message: "Transfert initié avec succès",
                data: {
                    payout_id: payout.payout_id,
                    transaction_id: result.transaction_id,
                    client_transaction_id: payout.cinetpay_info.client_transaction_id,
                    lot_id: result.lot_id,
                    status: result.status,
                    amount: payout.net_amount,
                    requires_confirmation: result.requires_confirmation
                }
            });
        } else {
            res.status(400).json({
                success: false,
                message: "Échec du transfert CinetPay",
                error: result.error || 'Erreur inconnue'
            });
        }

    } catch (error) {
        logger.error('Erreur initiation transfert CinetPay:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

/**
 * Statut d'un transfert CinetPay
 * GET /api/payouts/cinetpay/transfer/:transferId/status
 */
exports.getCinetPayTransferStatus = async (req, res) => {
    try {
        const { transferId } = req.params;
        const { type = 'transaction_id' } = req.query; // 'transaction_id', 'client_transaction_id', 'lot'

        if (!transferId) {
            return res.status(400).json({
                success: false,
                message: "ID de transfert requis"
            });
        }

        // Vérifier le statut via CinetPay
        const result = await cinetPayTransferService.checkTransferStatus(transferId, type);

        if (result.success) {
            // Essayer de synchroniser avec le payout local si possible
            if (result.client_transaction_id) {
                try {
                    const payout = await Payout.findOne({
                        'cinetpay_info.client_transaction_id': result.client_transaction_id
                    });
                    
                    if (payout) {
                        await cinetPayTransferService.syncPayoutStatus(payout);
                        logger.info(`Payout ${payout.payout_id} synchronisé avec CinetPay`);
                    }
                } catch (syncError) {
                    logger.warn('Erreur synchronisation payout:', syncError.message);
                }
            }

            res.json({
                success: true,
                data: {
                    transaction_id: result.transaction_id,
                    client_transaction_id: result.client_transaction_id,
                    lot: result.lot,
                    amount: result.amount,
                    receiver: result.receiver,
                    operator: result.operator,
                    treatment_status: result.treatment_status,
                    sending_status: result.sending_status,
                    transfer_valid: result.transfer_valid,
                    comment: result.comment,
                    validated_at: result.validated_at
                }
            });
        } else {
            res.status(404).json({
                success: false,
                message: "Transfert non trouvé ou erreur CinetPay",
                error: result.error
            });
        }

    } catch (error) {
        logger.error('Erreur récupération statut CinetPay:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

/**
 * Annuler un transfert CinetPay
 * POST /api/payouts/cinetpay/transfer/:transferId/cancel
 */
exports.cancelCinetPayTransfer = async (req, res) => {
    try {
        const { transferId } = req.params;
        const { reason = 'Annulation manuelle' } = req.body;

        // Seuls les admins peuvent annuler
        if (req.user.role !== 'admin' && req.user.role !== 'superadmin') {
            return res.status(403).json({
                success: false,
                message: "Seuls les admins peuvent annuler des transferts"
            });
        }

        if (!transferId) {
            return res.status(400).json({
                success: false,
                message: "ID de transfert requis"
            });
        }

        // Rechercher le payout correspondant
        const payout = await Payout.findOne({
            $or: [
                { 'cinetpay_info.transaction_id': transferId },
                { 'cinetpay_info.client_transaction_id': transferId },
                { 'cinetpay_info.lot_id': transferId }
            ]
        });

        if (!payout) {
            return res.status(404).json({
                success: false,
                message: "Payout correspondant non trouvé"
            });
        }

        // Vérifier si le transfert peut être annulé
        if (payout.status === 'PAYOUT_SUCCESS') {
            return res.status(400).json({
                success: false,
                message: "Impossible d'annuler un transfert déjà réussi"
            });
        }

        if (payout.status === 'PAYOUT_CANCELLED' || payout.status === 'PAYOUT_FAILED') {
            return res.status(400).json({
                success: false,
                message: `Transfert déjà ${payout.status === 'PAYOUT_CANCELLED' ? 'annulé' : 'échoué'}`
            });
        }

        // Note: CinetPay ne semble pas avoir d'API d'annulation directe
        // On marque le payout comme annulé côté ChapeChape
        payout.status = 'PAYOUT_CANCELLED';
        payout.failure_reason = `Annulé par ${req.user.email}: ${reason}`;
        payout.cancelled_at = new Date();
        
        await payout.save();

        logger.info(`Transfert CinetPay annulé par ${req.user.email}: ${transferId}`);

        res.json({
            success: true,
            message: "Transfert marqué comme annulé",
            data: {
                payout_id: payout.payout_id,
                status: payout.status,
                cancelled_at: payout.cancelled_at,
                reason: payout.failure_reason
            }
        });

    } catch (error) {
        logger.error('Erreur annulation transfert CinetPay:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

/**
 * Historique des transferts CinetPay
 * GET /api/payouts/cinetpay/transfer/history
 */
exports.getCinetPayTransferHistory = async (req, res) => {
    try {
        const {
            page = 1,
            limit = 20,
            status,
            partner_id,
            start_date,
            end_date
        } = req.query;

        // Construction du filtre
        const filter = {
            channel: { $in: ['cinetpay_transfer', 'orange_money', 'mtn_money', 'moov_money'] },
            'cinetpay_info.transaction_id': { $exists: true }
        };

        // Filtres optionnels
        if (status) {
            filter.status = status;
        }

        if (partner_id) {
            filter.partner_id = partner_id;
        }

        if (start_date || end_date) {
            filter.created_at = {};
            if (start_date) filter.created_at.$gte = new Date(start_date);
            if (end_date) filter.created_at.$lte = new Date(end_date);
        }

        // Pagination
        const skip = (parseInt(page) - 1) * parseInt(limit);
        const limitNum = parseInt(limit);

        // Requête avec agrégation pour inclure les infos partner
        const pipeline = [
            { $match: filter },
            {
                $lookup: {
                    from: 'partners',
                    localField: 'partner_id',
                    foreignField: 'partner_id',
                    as: 'partner_info'
                }
            },
            {
                $addFields: {
                    partner_name: { $arrayElemAt: ['$partner_info.business_name', 0] },
                    partner_email: { $arrayElemAt: ['$partner_info.email', 0] }
                }
            },
            { $sort: { created_at: -1 } },
            { $skip: skip },
            { $limit: limitNum },
            {
                $project: {
                    payout_id: 1,
                    partner_id: 1,
                    partner_name: 1,
                    partner_email: 1,
                    gross_amount: 1,
                    net_amount: 1,
                    status: 1,
                    channel: 1,
                    'cinetpay_info.transaction_id': 1,
                    'cinetpay_info.client_transaction_id': 1,
                    'cinetpay_info.treatment_status': 1,
                    'cinetpay_info.sending_status': 1,
                    'recipient_info.phone_number': 1,
                    created_at: 1,
                    processed_at: 1,
                    failure_reason: 1
                }
            }
        ];

        const [transfers, totalCount] = await Promise.all([
            Payout.aggregate(pipeline),
            Payout.countDocuments(filter)
        ]);

        // Statistiques rapides
        const stats = await Payout.aggregate([
            { $match: filter },
            {
                $group: {
                    _id: '$status',
                    count: { $sum: 1 },
                    total_amount: { $sum: '$net_amount' }
                }
            }
        ]);

        res.json({
            success: true,
            data: {
                transfers,
                pagination: {
                    current_page: parseInt(page),
                    per_page: limitNum,
                    total_items: totalCount,
                    total_pages: Math.ceil(totalCount / limitNum)
                },
                stats: stats.reduce((acc, stat) => {
                    acc[stat._id] = {
                        count: stat.count,
                        total_amount: stat.total_amount
                    };
                    return acc;
                }, {})
            }
        });

    } catch (error) {
        logger.error('Erreur récupération historique CinetPay:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

/**
 * Statistiques des transferts CinetPay
 * GET /api/payouts/cinetpay/transfer/stats
 */
exports.getCinetPayTransferStats = async (req, res) => {
    try {
        const {
            period = '30d', // 7d, 30d, 90d, 1y
            partner_id
        } = req.query;

        // Calculer la date de début selon la période
        const now = new Date();
        let startDate;
        
        switch (period) {
            case '7d':
                startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
                break;
            case '30d':
                startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
                break;
            case '90d':
                startDate = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
                break;
            case '1y':
                startDate = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);
                break;
            default:
                startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
        }

        // Filtre de base
        const baseFilter = {
            channel: { $in: ['cinetpay_transfer', 'orange_money', 'mtn_money', 'moov_money'] },
            created_at: { $gte: startDate }
        };

        if (partner_id) {
            baseFilter.partner_id = partner_id;
        }

        // Statistiques globales
        const globalStats = await Payout.aggregate([
            { $match: baseFilter },
            {
                $group: {
                    _id: null,
                    total_transfers: { $sum: 1 },
                    total_amount: { $sum: '$net_amount' },
                    avg_amount: { $avg: '$net_amount' },
                    min_amount: { $min: '$net_amount' },
                    max_amount: { $max: '$net_amount' }
                }
            }
        ]);

        // Répartition par statut
        const statusStats = await Payout.aggregate([
            { $match: baseFilter },
            {
                $group: {
                    _id: '$status',
                    count: { $sum: 1 },
                    total_amount: { $sum: '$net_amount' },
                    avg_amount: { $avg: '$net_amount' }
                }
            },
            { $sort: { count: -1 } }
        ]);

        // Répartition par canal (mobile money)
        const channelStats = await Payout.aggregate([
            { $match: baseFilter },
            {
                $group: {
                    _id: '$channel',
                    count: { $sum: 1 },
                    total_amount: { $sum: '$net_amount' },
                    success_count: {
                        $sum: { $cond: [{ $eq: ['$status', 'PAYOUT_SUCCESS'] }, 1, 0] }
                    }
                }
            },
            {
                $addFields: {
                    success_rate: {
                        $multiply: [
                            { $divide: ['$success_count', '$count'] },
                            100
                        ]
                    }
                }
            },
            { $sort: { count: -1 } }
        ]);

        // Évolution quotidienne (derniers 30 jours)
        const dailyStats = await Payout.aggregate([
            { $match: baseFilter },
            {
                $group: {
                    _id: {
                        year: { $year: '$created_at' },
                        month: { $month: '$created_at' },
                        day: { $dayOfMonth: '$created_at' }
                    },
                    count: { $sum: 1 },
                    total_amount: { $sum: '$net_amount' },
                    success_count: {
                        $sum: { $cond: [{ $eq: ['$status', 'PAYOUT_SUCCESS'] }, 1, 0] }
                    }
                }
            },
            {
                $addFields: {
                    date: {
                        $dateFromParts: {
                            year: '$_id.year',
                            month: '$_id.month',
                            day: '$_id.day'
                        }
                    }
                }
            },
            { $sort: { date: 1 } },
            {
                $project: {
                    _id: 0,
                    date: 1,
                    count: 1,
                    total_amount: 1,
                    success_count: 1,
                    success_rate: {
                        $multiply: [
                            { $divide: ['$success_count', '$count'] },
                            100
                        ]
                    }
                }
            }
        ]);

        // Top partners (si pas de filtre partner_id)
        let topPartners = [];
        if (!partner_id) {
            topPartners = await Payout.aggregate([
                { $match: baseFilter },
                {
                    $group: {
                        _id: '$partner_id',
                        count: { $sum: 1 },
                        total_amount: { $sum: '$net_amount' }
                    }
                },
                {
                    $lookup: {
                        from: 'partners',
                        localField: '_id',
                        foreignField: 'partner_id',
                        as: 'partner_info'
                    }
                },
                {
                    $addFields: {
                        partner_name: { $arrayElemAt: ['$partner_info.business_name', 0] }
                    }
                },
                { $sort: { total_amount: -1 } },
                { $limit: 10 },
                {
                    $project: {
                        partner_id: '$_id',
                        partner_name: 1,
                        count: 1,
                        total_amount: 1,
                        _id: 0
                    }
                }
            ]);
        }

        // Vérifier le solde CinetPay actuel
        let currentBalance = null;
        try {
            currentBalance = await cinetPayTransferService.checkBalance();
        } catch (balanceError) {
            logger.warn('Impossible de récupérer le solde CinetPay:', balanceError.message);
        }

        res.json({
            success: true,
            data: {
                period,
                date_range: {
                    start: startDate,
                    end: now
                },
                global: globalStats[0] || {
                    total_transfers: 0,
                    total_amount: 0,
                    avg_amount: 0,
                    min_amount: 0,
                    max_amount: 0
                },
                by_status: statusStats,
                by_channel: channelStats,
                daily_evolution: dailyStats,
                top_partners: topPartners,
                current_balance: currentBalance
            }
        });

    } catch (error) {
        logger.error('Erreur récupération statistiques CinetPay:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

// ===============================
// HANDLERS WAVE PAYOUTS
// ===============================

/**
 * Initier un transfert Wave
 * POST /api/payouts/wave/transfer
 */
exports.initiateWaveTransfer = async (req, res) => {
    try {
        logger.info('Handler initiateWaveTransfer appelé', { 
            body: req.body, 
            user: req.user?.email,
            hasUser: !!req.user,
            headers: req.headers.authorization ? 'Present' : 'Missing'
        });
        
        // Debug des variables d'environnement
        logger.info('Variables Wave Payout:', {
            hasApiKey: !!process.env.WAVE_PAYOUT_API_KEY,
            baseUrl: process.env.WAVE_PAYOUT_BASE_URL,
            apiKeyPrefix: process.env.WAVE_PAYOUT_API_KEY?.substring(0, 10) + '...'
        });
        
        const { amount, mobile, name, payment_reason, national_id } = req.body;
        
        // Vérifier permissions
        if (!req.user) {
            logger.error('Utilisateur non authentifié');
            return res.status(401).json({
                success: false,
                message: "Authentification requise"
            });
        }
        
        if (req.user.role !== 'admin' && req.user.role !== 'superadmin' && req.user.role !== 'partner') {
            logger.error('Permissions insuffisantes', { userRole: req.user.role });
            return res.status(403).json({
                success: false,
                message: "Accès non autorisé"
            });
        }

        // Générer une référence client unique
        const client_reference = `PAYOUT_${Date.now()}_${req.user._id.toString().slice(-6)}`;
        
        const transferData = {
            amount,
            mobile,
            name,
            client_reference,
            payment_reason: payment_reason || 'Reversement ChapeChape',
            national_id
        };

        logger.info('Tentative initiation transfert Wave', { client_reference, amount, mobile: mobile.substring(0, 8) + '***' });

        const result = await wavePayoutService.createPayout(transferData);
        
        if (result.success) {
            logger.info(`Transfert Wave initié par ${req.user.email}: ${result.data.wave_id}`);
            
            res.status(201).json({
                success: true,
                message: "Transfert Wave initié avec succès",
                data: {
                    wave_id: result.data.wave_id,
                    status: result.data.status,
                    amount: result.data.amount,
                    fee: result.data.fee,
                    client_reference: result.data.client_reference,
                    timestamp: result.data.timestamp
                }
            });
        } else {
            res.status(400).json({
                success: false,
                message: result.error.message || 'Erreur lors de l\'initiation du transfert',
                error_code: result.error.code,
                retry_recommended: result.retry_recommended
            });
        }
        
    } catch (error) {
        logger.error('Erreur initiation transfert Wave:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

/**
 * Vérifier le statut d'un transfert Wave
 * GET /api/payouts/wave/transfer/:waveId/status
 */
exports.getWaveTransferStatus = async (req, res) => {
    try {
        const { waveId } = req.params;
        
        const result = await wavePayoutService.getPayoutStatus(waveId);
        
        if (result.success) {
            res.json({
                success: true,
                data: result.data
            });
        } else {
            res.status(404).json({
                success: false,
                message: result.error.message || 'Transfert non trouvé',
                error_code: result.error.code
            });
        }
        
    } catch (error) {
        logger.error('Erreur récupération statut Wave:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

/**
 * Rechercher des transferts Wave
 * GET /api/payouts/wave/search
 */
exports.searchWaveTransfers = async (req, res) => {
    try {
        const { client_reference } = req.query;
        
        if (!client_reference) {
            return res.status(400).json({
                success: false,
                message: "Référence client requise"
            });
        }
        
        const result = await wavePayoutService.searchPayouts(client_reference);
        
        if (result.success) {
            res.json({
                success: true,
                data: result.data
            });
        } else {
            res.status(500).json({
                success: false,
                message: result.error.message || 'Erreur lors de la recherche'
            });
        }
        
    } catch (error) {
        logger.error('Erreur recherche transferts Wave:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

/**
 * Créer un batch de transferts Wave
 * POST /api/payouts/wave/batch
 */
exports.createWaveBatch = async (req, res) => {
    try {
        const { transfers } = req.body;
        
        // Seuls les admins peuvent créer des batches
        if (req.user.role !== 'admin' && req.user.role !== 'superadmin') {
            return res.status(403).json({
                success: false,
                message: "Seuls les admins peuvent créer des batches"
            });
        }
        
        // Ajouter des références client uniques
        const payoutsWithRefs = transfers.map((transfer, index) => ({
            ...transfer,
            client_reference: `BATCH_${Date.now()}_${index + 1}`
        }));
        
        const result = await wavePayoutService.createPayoutBatch(payoutsWithRefs);
        
        if (result.success) {
            logger.info(`Batch Wave créé par ${req.user.email}: ${result.data.batch_id}`);
            
            res.status(201).json({
                success: true,
                message: "Batch de transferts créé avec succès",
                data: result.data
            });
        } else {
            res.status(400).json({
                success: false,
                message: result.error.message || 'Erreur lors de la création du batch',
                error_code: result.error.code,
                retry_recommended: result.retry_recommended
            });
        }
        
    } catch (error) {
        logger.error('Erreur création batch Wave:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

/**
 * Statut d'un batch Wave
 * GET /api/payouts/wave/batch/:batchId/status
 */
exports.getWaveBatchStatus = async (req, res) => {
    try {
        const { batchId } = req.params;
        
        const result = await wavePayoutService.getPayoutBatchStatus(batchId);
        
        if (result.success) {
            res.json({
                success: true,
                data: result.data
            });
        } else {
            res.status(404).json({
                success: false,
                message: result.error.message || 'Batch non trouvé',
                error_code: result.error.code
            });
        }
        
    } catch (error) {
        logger.error('Erreur récupération batch Wave:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

/**
 * Annuler un transfert Wave
 * POST /api/payouts/wave/transfer/:waveId/reverse
 */
exports.reverseWaveTransfer = async (req, res) => {
    try {
        const { waveId } = req.params;
        
        // Seuls les admins peuvent annuler
        if (req.user.role !== 'admin' && req.user.role !== 'superadmin') {
            return res.status(403).json({
                success: false,
                message: "Seuls les admins peuvent annuler des transferts"
            });
        }
        
        const result = await wavePayoutService.reversePayout(waveId);
        
        if (result.success) {
            logger.info(`Transfert Wave annulé par ${req.user.email}: ${waveId}`);
            
            res.json({
                success: true,
                message: "Transfert annulé avec succès",
                data: result.data
            });
        } else {
            res.status(400).json({
                success: false,
                message: result.error.message || 'Erreur lors de l\'annulation',
                error_code: result.error.code
            });
        }
        
    } catch (error) {
        logger.error('Erreur annulation transfert Wave:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

/**
 * Webhook Wave Payout
 * POST /api/payouts/wave/webhook
 */
exports.handleWavePayoutWebhook = async (req, res) => {
    try {
        const signature = req.headers['x-wave-signature'] || req.headers['wave-signature'];
        const rawBody = req.body; // Buffer brut depuis express.raw()
        
        // Convertir le corps brut en objet JSON APRÈS vérification de signature
        let webhookData;
        try {
            webhookData = JSON.parse(rawBody.toString('utf8'));
        } catch (parseError) {
            logger.error('Erreur parsing webhook Wave Payout:', parseError);
            return res.status(400).json({
                success: false,
                message: 'Corps de requête JSON invalide'
            });
        }

        logger.info('Webhook Wave Payout reçu:', webhookData);

        // Vérifier la signature si configurée
        if (process.env.WAVE_PAYOUT_WEBHOOK_SECRET && signature) {
            const isValid = wavePayoutService.verifyWebhookSignature(rawBody, signature);
            if (!isValid) {
                logger.error('Signature Wave Payout invalide');
                return res.status(400).json({
                    success: false,
                    message: 'Signature invalide'
                });
            }
        }

        // Traiter la notification via le service Wave
        const result = await wavePayoutService.processWebhook(webhookData);

        if (result.success) {
            // TODO: Mettre à jour le modèle Payout correspondant
            // Rechercher le payout par client_reference ou wave_id
            // Mettre à jour le statut selon result.data.status
            
            logger.info(`Webhook Wave Payout traité: ${result.data.wave_id} -> ${result.data.status}`);
        }

        res.json({ received: true });

    } catch (error) {
        logger.error('Erreur webhook Wave Payout:', error);
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};
