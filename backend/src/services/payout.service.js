const Payout = require('../models/payout.model');
const Payment = require('../models/payment.model');
const Reservation = require('../models/reservation.model');
const Partner = require('../models/partner.model');
const cinetPayTransferService = require('./cinetpay-transfer.service');
const notificationService = require('./notification.service');
const { agenda } = require('./agenda.service');
const logger = require('../utils/logger');

/**
 * Service Payout - Orchestrateur des reversements aux partners
 * 
 * Fonctionnalités:
 * - Calcul automatique des payouts
 * - Scheduling des transferts 
 * - Exécution via CinetPay Transfer API
 * - Gestion des erreurs et retry
 * - Notifications multi-canal
 */
class PayoutService {
    constructor() {
        this.defaultCommissionRate = parseFloat(process.env.DEFAULT_COMMISSION_RATE || '0.10'); // 10%
        this.minPayoutAmount = 5; // XOF minimum CinetPay
        this.maxRetries = 5;
        this.retryDelays = [30, 60, 180, 360, 720]; // minutes
        
        logger.info(`PayoutService initialisé - Commission: ${this.defaultCommissionRate * 100}%`);
    }

    isScheduledStatus(status) {
        return status === 'PAYOUT_SCHEDULED' || status === 'scheduled';
    }

    // ===============================
    // CRÉATION DE PAYOUTS
    // ===============================

    /**
     * Créer un payout pour une réservation payée
     * @param {string} reservationId ID de la réservation
     * @returns {Object} Payout créé
     */
    async createPayoutForReservation(reservationId) {
        try {
            // Récupérer la réservation avec payment
            const reservation = await Reservation.findById(reservationId)
                .populate('partner')
                .populate({
                    path: 'payments',
                    match: { status: 'completed' }
                });

            if (!reservation) {
                throw new Error('Réservation non trouvée');
            }

            if (reservation.paymentStatus !== 'paid') {
                throw new Error('Réservation pas encore payée');
            }

            if (!reservation.partner) {
                throw new Error('Partner non trouvé pour cette réservation');
            }

            // Vérifier si payout déjà créé
            const existingPayout = await Payout.findOne({
                source_transactions: { $in: reservation.payments.map(p => p._id) }
            });

            if (existingPayout) {
                logger.warn(`Payout déjà existant pour réservation ${reservationId}`);
                return existingPayout;
            }

            // Calculer les montants
            const paymentIds = reservation.payments.map(p => p._id);
            const totalAmount = reservation.payments.reduce((sum, p) => sum + p.amount, 0);
            
            const commissionRate = reservation.partner.commissionRate || this.defaultCommissionRate;
            const commissionAmount = Math.round(totalAmount * commissionRate);
            const netAmount = this.roundToPayoutConstraints(totalAmount - commissionAmount);

            // Validation montant minimum
            if (netAmount < this.minPayoutAmount) {
                logger.warn(`Montant payout trop faible: ${netAmount} XOF (min: ${this.minPayoutAmount})`);
                throw new Error(`Montant payout insuffisant: ${netAmount} XOF`);
            }

            // Récupérer infos partner pour le transfert
            const partnerInfo = await this.getPartnerPayoutInfo(reservation.partner);

            // Créer le payout
            const payout = new Payout({
                partner: reservation.partner._id,
                source_transactions: paymentIds,
                gross_amount: totalAmount,
                commission_amount: commissionAmount,
                commission_rate: commissionRate,
                net_amount: netAmount,
                currency: 'XOF',
                channel: partnerInfo.preferred_channel || 'orange_money',
                recipient_info: partnerInfo.recipient_info,
                scheduled_for: this.calculateScheduledTime(), // Programmé dans 1h par défaut
                notify_url: `${process.env.APP_URL}/api/payouts/cinetpay/webhook`,
                metadata: new Map([
                    ['reservation_id', reservationId],
                    ['partner_id', reservation.partner._id.toString()],
                    ['residence_title', reservation.residence?.title || '']
                ])
            });

            await payout.save();
            
            // Programmer l'exécution
            await this.schedulePayoutExecution(payout);
            
            // Notification partner
            await this.notifyPayoutCreated(payout);
            
            logger.info(`Payout créé: ${payout.payout_id} (${netAmount} XOF pour ${reservation.partner.businessName})`);
            return payout;

        } catch (error) {
            logger.error('Erreur création payout:', error);
            throw error;
        }
    }

    /**
     * Créer des payouts en batch pour plusieurs réservations
     * @param {Array} reservationIds IDs des réservations
     * @returns {Array} Payouts créés
     */
    async createBatchPayouts(reservationIds) {
        const results = [];
        
        for (const reservationId of reservationIds) {
            try {
                const payout = await this.createPayoutForReservation(reservationId);
                results.push({ success: true, payout, reservationId });
            } catch (error) {
                logger.error(`Erreur payout pour réservation ${reservationId}:`, error);
                results.push({ success: false, error: error.message, reservationId });
            }
        }
        
        logger.info(`Batch payouts: ${results.filter(r => r.success).length}/${results.length} réussis`);
        return results;
    }

    // ===============================
    // EXÉCUTION DE PAYOUTS  
    // ===============================

    /**
     * Exécuter un payout via CinetPay
     * @param {Object} payout Instance du payout
     * @returns {Object} Résultat de l'exécution
     */
    async executePayout(payout) {
        try {
            logger.info(`Exécution payout ${payout.payout_id} (${payout.net_amount} XOF)`);
            
            // Vérifier que le payout est exécutable
            if (!this.isScheduledStatus(payout.status)) {
                throw new Error(`Payout pas en statut SCHEDULED: ${payout.status}`);
            }

            if (payout.attempts >= this.maxRetries) {
                throw new Error('Nombre maximum de tentatives atteint');
            }

            // Marquer comme en cours
            payout.status = 'PAYOUT_PENDING';
            payout.attempts += 1;
            await payout.save();

            // Exécuter via CinetPay Transfer
            const transferResult = await cinetPayTransferService.sendMoney(payout);
            
            if (transferResult.success) {
                logger.info(`Transfert CinetPay initié: ${transferResult.transaction_id}`);
                
                // Notification succès (initiation)
                await this.notifyPayoutInitiated(payout, transferResult);
                
                return {
                    success: true,
                    status: 'PENDING',
                    transaction_id: transferResult.transaction_id,
                    requires_confirmation: transferResult.requires_confirmation
                };
                
            } else {
                throw new Error(`Échec transfert CinetPay: ${transferResult.error}`);
            }

        } catch (error) {
            logger.error(`Erreur exécution payout ${payout.payout_id}:`, error);
            
            // Gestion d'erreur selon le type
            if (error.message.includes('INSUFFICIENT_BALANCE')) {
                payout.markAsFailed('Solde CinetPay insuffisant', '602');
                await this.notifyPayoutFailed(payout, 'Solde insuffisant sur le compte CinetPay');
            } else if (error.message.includes('INVALID_TOKEN')) {
                // Retry dans 5 minutes pour token expiré
                payout.scheduleRetry(5);
            } else {
                // Programmer retry avec délai progressif
                const retryDelay = this.retryDelays[payout.attempts - 1] || 720; // max 12h
                if (payout.scheduleRetry(retryDelay)) {
                    await this.schedulePayoutExecution(payout, retryDelay);
                } else {
                    await this.notifyPayoutFailed(payout, error.message);
                }
            }
            
            await payout.save();
            throw error;
        }
    }

    /**
     * Traiter les payouts en attente d'exécution
     * @returns {Object} Statistiques de traitement
     */
    async processScheduledPayouts() {
        try {
            const readyPayouts = await Payout.findReadyForExecution();
            
            logger.info(`${readyPayouts.length} payouts prêts pour exécution`);
            
            const results = {
                processed: 0,
                successful: 0,
                failed: 0,
                errors: []
            };

            for (const payout of readyPayouts) {
                results.processed++;
                
                try {
                    await this.executePayout(payout);
                    results.successful++;
                } catch (error) {
                    results.failed++;
                    results.errors.push({
                        payout_id: payout.payout_id,
                        error: error.message
                    });
                }
            }
            
            logger.info(`Traitement payouts terminé: ${results.successful}/${results.processed} réussis`);
            return results;
            
        } catch (error) {
            logger.error('Erreur traitement payouts schedulés:', error);
            throw error;
        }
    }

    // ===============================
    // SYNCHRONISATION STATUTS
    // ===============================

    /**
     * Synchroniser tous les payouts en cours avec CinetPay
     * @returns {Object} Résultats de synchronisation
     */
    async syncAllPendingPayouts() {
        try {
            const pendingPayouts = await Payout.find({
                status: 'PAYOUT_PENDING',
                'cinetpay_info.transaction_id': { $exists: true, $ne: null }
            });

            logger.info(`Synchronisation de ${pendingPayouts.length} payouts en cours`);
            
            const results = {
                synced: 0,
                completed: 0,
                failed: 0,
                still_pending: 0
            };

            for (const payout of pendingPayouts) {
                try {
                    const wasUpdated = await cinetPayTransferService.syncPayoutStatus(payout);
                    
                    if (wasUpdated) {
                        results.synced++;
                        
                        if (payout.status === 'PAYOUT_SUCCESS') {
                            results.completed++;
                            await this.notifyPayoutCompleted(payout);
                        } else if (payout.status === 'PAYOUT_FAILED') {
                            results.failed++;
                            await this.notifyPayoutFailed(payout, payout.failure_reason);
                        }
                    } else {
                        results.still_pending++;
                    }
                    
                } catch (error) {
                    logger.error(`Erreur sync payout ${payout.payout_id}:`, error);
                    results.failed++;
                }
            }
            
            logger.info(`Sync terminée: ${results.completed} complétés, ${results.failed} échecs`);
            return results;
            
        } catch (error) {
            logger.error('Erreur synchronisation payouts:', error);
            throw error;
        }
    }

    // ===============================
    // UTILITAIRES
    // ===============================

    /**
     * Récupérer les informations de payout d'un partner
     * @param {Object} partner Instance du partner
     * @returns {Object} Informations de payout
     */
    async getPartnerPayoutInfo(partner) {
        // Informations depuis le profil partner
        const payoutInfo = {
            preferred_channel: partner.payoutPreferences?.channel || 'orange_money',
            recipient_info: {
                phone_prefix: partner.payoutPreferences?.phonePrefix || '225',
                phone_number: partner.payoutPreferences?.phoneNumber || partner.phone,
                full_name: partner.businessName || `${partner.firstName} ${partner.lastName}`,
                email: partner.email
            }
        };

        // Validation
        if (!payoutInfo.recipient_info.phone_number) {
            throw new Error('Numéro de téléphone partner manquant pour payout');
        }

        return payoutInfo;
    }

    /**
     * Calculer le moment d'exécution programmée
     * @param {number} delayHours Délai en heures (défaut: 1h)
     * @returns {Date} Date d'exécution
     */
    calculateScheduledTime(delayHours = 1) {
        return new Date(Date.now() + delayHours * 60 * 60 * 1000);
    }

    /**
     * Arrondir aux contraintes CinetPay (multiple de 5)
     * @param {number} amount Montant original
     * @returns {number} Montant arrondi
     */
    roundToPayoutConstraints(amount) {
        return Math.floor(amount / 5) * 5;
    }

    /**
     * Programmer l'exécution d'un payout
     * @param {Object} payout Instance du payout
     * @param {number} delayMinutes Délai en minutes (optionnel)
     */
    async schedulePayoutExecution(payout, delayMinutes = null) {
        const executeAt = delayMinutes ? 
            new Date(Date.now() + delayMinutes * 60 * 1000) : 
            payout.scheduled_for;

        await agenda.schedule(executeAt, 'process payout', {
            payoutId: payout._id.toString()
        });

        logger.debug(`Payout ${payout.payout_id} programmé pour ${executeAt.toISOString()}`);
    }

    // ===============================
    // NOTIFICATIONS
    // ===============================

    /**
     * Notifier la création d'un payout
     */
    async notifyPayoutCreated(payout) {
        try {
            const partner = await Partner.findById(payout.partner);
            
            await notificationService.sendPayoutCreated(partner, {
                amount: payout.net_amount,
                currency: payout.currency,
                scheduled_for: payout.scheduled_for,
                payout_id: payout.payout_id
            });
            
        } catch (error) {
            logger.error('Erreur notification payout créé:', error);
        }
    }

    /**
     * Notifier l'initiation d'un payout
     */
    async notifyPayoutInitiated(payout, transferResult) {
        try {
            const partner = await Partner.findById(payout.partner);
            
            await notificationService.sendPayoutInitiated(partner, {
                amount: payout.net_amount,
                currency: payout.currency,
                transaction_id: transferResult.transaction_id,
                requires_confirmation: transferResult.requires_confirmation
            });
            
        } catch (error) {
            logger.error('Erreur notification payout initié:', error);
        }
    }

    /**
     * Notifier la finalisation d'un payout
     */
    async notifyPayoutCompleted(payout) {
        try {
            const partner = await Partner.findById(payout.partner);
            
            await notificationService.sendPayoutCompleted(partner, {
                amount: payout.net_amount,
                currency: payout.currency,
                completed_at: payout.executed_at,
                transaction_id: payout.cinetpay_info.transaction_id
            });
            
        } catch (error) {
            logger.error('Erreur notification payout complété:', error);
        }
    }

    /**
     * Notifier l'échec d'un payout
     */
    async notifyPayoutFailed(payout, reason) {
        try {
            const partner = await Partner.findById(payout.partner);
            
            await notificationService.sendPayoutFailed(partner, {
                amount: payout.net_amount,
                currency: payout.currency,
                reason: reason,
                payout_id: payout.payout_id,
                will_retry: payout.attempts < this.maxRetries
            });
            
        } catch (error) {
            logger.error('Erreur notification payout échoué:', error);
        }
    }

    // ===============================
    // STATISTIQUES & REPORTING
    // ===============================

    /**
     * Obtenir les statistiques de payout pour un partner
     * @param {string} partnerId ID du partner
     * @param {Date} startDate Date de début (optionnel)
     * @param {Date} endDate Date de fin (optionnel)
     * @returns {Object} Statistiques
     */
    async getPartnerPayoutStats(partnerId, startDate = null, endDate = null) {
        try {
            const stats = await Payout.getPartnerStats(partnerId, startDate, endDate);
            
            const summary = {
                total_payouts: 0,
                total_amount: 0,
                successful: 0,
                successful_amount: 0,
                failed: 0,
                failed_amount: 0,
                pending: 0,
                pending_amount: 0
            };

            stats.forEach(stat => {
                summary.total_payouts += stat.count;
                summary.total_amount += stat.total_amount;

                switch (stat._id) {
                    case 'PAYOUT_SUCCESS':
                        summary.successful = stat.count;
                        summary.successful_amount = stat.total_amount;
                        break;
                    case 'PAYOUT_FAILED':
                    case 'PAYOUT_CANCELLED':
                        summary.failed += stat.count;
                        summary.failed_amount += stat.total_amount;
                        break;
                    case 'PAYOUT_PENDING':
                    case 'PAYOUT_SCHEDULED':
                        summary.pending += stat.count;
                        summary.pending_amount += stat.total_amount;
                        break;
                }
            });

            return summary;

        } catch (error) {
            logger.error('Erreur récupération stats payout:', error);
            throw error;
        }
    }
}

module.exports = new PayoutService();
