const Payout = require('../models/payout.model');
const Residence = require('../models/residence.model');
const Partner = require('../models/partner.model');
const wavePayoutService = require('./wave-payout.service');
const logger = require('../utils/logger');

/**
 * Service de Payout Automatique
 * Gère les reversements automatiques aux partners après paiement client
 */
class AutomaticPayoutService {
    
    /**
     * Déclenche un payout automatique après confirmation de paiement
     * @param {Object} payment - Objet Payment confirmé
     * @param {Object} reservation - Objet Reservation associé
     */
    static async triggerAutomaticPayout(payment, reservation) {
        try {
            logger.info(`Déclenchement payout automatique pour payment ${payment._id}`);
            
            // Vérifier si les payouts automatiques sont activés
            if (!process.env.AUTO_PAYOUT_ENABLED || process.env.AUTO_PAYOUT_ENABLED !== 'true') {
                logger.info('Payouts automatiques désactivés');
                return null;
            }
            
            // Récupérer les informations complètes de la résidence et du partner
            const residence = await Residence.findById(reservation.residence).populate('partner');
            if (!residence || !residence.partner) {
                throw new Error('Résidence ou partner introuvable');
            }
            
            const partner = residence.partner;
            
            // Vérifier que le partner a les informations nécessaires pour le payout
            if (!partner.phoneNumber) {
                logger.warn(`Partner ${partner._id} n'a pas de numéro de téléphone pour le payout`);
                await this.createManualPayout(payment, reservation, 'Numéro de téléphone manquant');
                return null;
            }
            
            // Calculer les montants avec la commission
            const grossAmount = payment.amount;
            const commissionRate = parseFloat(process.env.DEFAULT_COMMISSION_RATE) || 0.10;
            const commissionAmount = Math.round(grossAmount * commissionRate);
            let netAmount = grossAmount - commissionAmount;
            
            // Pour CinetPay : arrondir au multiple de 5 inférieur (contrainte API)
            const payoutChannel = this.determinePayoutChannel(await Partner.findById(reservation.partner || (await Residence.findById(reservation.residence)).partner));
            if (payoutChannel !== 'wave') {
                netAmount = Math.floor(netAmount / 5) * 5;
                logger.info(`Montant arrondi pour CinetPay: ${grossAmount - commissionAmount} → ${netAmount} XOF`);
            }
            
            // Vérifier le montant minimum
            const minPayoutAmount = parseInt(process.env.MIN_PAYOUT_AMOUNT) || 1000;
            if (netAmount < minPayoutAmount) {
                logger.warn(`Montant net ${netAmount} inférieur au minimum ${minPayoutAmount}`);
                await this.createManualPayout(payment, reservation, `Montant inférieur au minimum (${minPayoutAmount} XOF)`);
                return null;
            }
            
            // Créer l'enregistrement payout
            const payoutId = `auto_${Date.now()}_${partner._id.toString().slice(-6)}`;
            const payout = await Payout.create({
                payout_id: payoutId,
                partner: partner._id,
                source_transactions: [payment._id],
                gross_amount: grossAmount,
                commission_amount: commissionAmount,
                commission_rate: commissionRate,
                net_amount: netAmount,
                currency: 'XOF',
                channel: this.determinePayoutChannel(partner),
                recipient_info: {
                    phone_prefix: this.extractPhonePrefix(partner.phoneNumber),
                    phone_number: this.extractPhoneNumber(partner.phoneNumber),
                    full_name: partner.company?.name || partner.firstName + ' ' + partner.lastName,
                    email: partner.email
                },
                status: 'scheduled',
                trigger_type: 'automatic',
                provider: 'cinetpay',
                scheduled_date: new Date(Date.now() + (parseInt(process.env.AUTO_PAYOUT_DELAY_MINUTES) || 5) * 60 * 1000),
                metadata: {
                    source_payment_id: payment._id,
                    source_reservation_id: reservation._id,
                    auto_generated: true,
                    created_by_webhook: true
                }
            });
            
            logger.info(`Payout automatique créé: ${payoutId} - ${netAmount} XOF vers ${partner.company?.name || partner.firstName}`);
            
            // Déclencher le transfert immédiatement si configuré
            if (process.env.AUTO_PAYOUT_IMMEDIATE === 'true') {
                await this.executeAutomaticPayout(payout);
            }
            
            return payout;
            
        } catch (error) {
            logger.error('Erreur lors du payout automatique:', error);
            
            // Créer un payout manuel en fallback
            try {
                await this.createManualPayout(payment, reservation, error.message);
            } catch (fallbackError) {
                logger.error('Erreur lors de la création du payout manuel de fallback:', fallbackError);
            }
            
            throw error;
        }
    }
    
    /**
     * Exécute un payout automatique via Wave
     * @param {Object} payout - Objet Payout à exécuter
     */
    static async executeAutomaticPayout(payout) {
        try {
            logger.info(`Exécution du payout automatique ${payout.payout_id}`);
            
            // Mettre à jour le statut
            payout.status = 'processing';
            payout.processed_date = new Date();
            await payout.save();
            
            // Préparer les informations pour Wave
            const fullPhoneNumber = `${payout.recipient_info.phone_prefix}${payout.recipient_info.phone_number}`;
            
            // Exécuter le transfert Wave
            const waveResult = await wavePayoutService.createPayout({
                amount: payout.net_amount,
                mobile: fullPhoneNumber,
                name: payout.recipient_info.full_name,
                reference: payout.payout_id
            });
            
            // Mettre à jour avec les informations Wave
            payout.cinetpay_info = {
                transaction_id: waveResult.transactionId,
                client_transaction_id: waveResult.clientTransactionId,
                status: waveResult.status,
                provider_response: waveResult
            };
            
            if (waveResult.success) {
                payout.status = 'completed';
                logger.info(`Payout automatique ${payout.payout_id} exécuté avec succès`);
            } else {
                payout.status = 'failed';
                payout.failure_reason = waveResult.message || 'Échec du transfert Wave';
                logger.error(`Échec du payout automatique ${payout.payout_id}: ${payout.failure_reason}`);
            }
            
            await payout.save();
            return payout;
            
        } catch (error) {
            logger.error(`Erreur lors de l'exécution du payout ${payout.payout_id}:`, error);
            
            // Marquer comme échoué
            payout.status = 'failed';
            payout.failure_reason = error.message;
            await payout.save();
            
            throw error;
        }
    }
    
    /**
     * Crée un payout manuel en cas d'échec du payout automatique
     * @param {Object} payment - Paiement source
     * @param {Object} reservation - Réservation associée
     * @param {String} reason - Raison du fallback
     */
    static async createManualPayout(payment, reservation, reason) {
        try {
            const residence = await Residence.findById(reservation.residence).populate('partner');
            const partner = residence.partner;
            
            const grossAmount = payment.amount;
            const commissionRate = parseFloat(process.env.DEFAULT_COMMISSION_RATE) || 0.10;
            const commissionAmount = Math.round(grossAmount * commissionRate);
            const netAmount = grossAmount - commissionAmount;
            
            const payoutId = `manual_${Date.now()}_${partner._id.toString().slice(-6)}`;
            
            const manualPayout = await Payout.create({
                payout_id: payoutId,
                partner: partner._id,
                source_transactions: [payment._id],
                gross_amount: grossAmount,
                commission_amount: commissionAmount,
                commission_rate: commissionRate,
                net_amount: netAmount,
                currency: 'XOF',
                channel: 'manual',
                recipient_info: {
                    phone_prefix: partner.phoneNumber ? this.extractPhonePrefix(partner.phoneNumber) : '',
                    phone_number: partner.phoneNumber ? this.extractPhoneNumber(partner.phoneNumber) : '',
                    full_name: partner.company?.name || partner.firstName + ' ' + partner.lastName,
                    email: partner.email
                },
                status: 'scheduled',
                trigger_type: 'automatic',
                provider: 'manual',
                scheduled_date: new Date(),
                failure_reason: `Payout automatique échoué: ${reason}`,
                metadata: {
                    source_payment_id: payment._id,
                    source_reservation_id: reservation._id,
                    auto_generated: true,
                    manual_fallback: true,
                    fallback_reason: reason
                }
            });
            
            logger.info(`Payout manuel créé en fallback: ${payoutId} - Raison: ${reason}`);
            return manualPayout;
            
        } catch (error) {
            logger.error('Erreur lors de la création du payout manuel:', error);
            throw error;
        }
    }
    
    /**
     * Détermine le canal de payout optimal pour un partner
     * @param {Object} partner - Objet Partner
     * @returns {String} Canal de payout
     */
    static determinePayoutChannel(partner) {
        if (!partner.phoneNumber) return 'manual';
        
        const phone = partner.phoneNumber.replace(/\s+/g, '');
        
        // Détection basée sur les préfixes ivoiriens
        if (phone.includes('07') || phone.includes('+22507')) return 'orange_money';
        if (phone.includes('05') || phone.includes('+22505')) return 'mtn_money';
        if (phone.includes('01') || phone.includes('+22501')) return 'moov_money';
        
        // Par défaut, utiliser Wave qui supporte plusieurs opérateurs
        return 'wave';
    }
    
    /**
     * Extrait le préfixe du numéro de téléphone
     * @param {String} phoneNumber - Numéro complet
     * @returns {String} Préfixe
     */
    static extractPhonePrefix(phoneNumber) {
        if (!phoneNumber) return '';
        
        const cleaned = phoneNumber.replace(/\s+/g, '');
        if (cleaned.startsWith('+225')) return '+225';
        if (cleaned.startsWith('225')) return '+225';
        
        return '+225'; // Par défaut Côte d'Ivoire
    }
    
    /**
     * Extrait le numéro sans préfixe
     * @param {String} phoneNumber - Numéro complet
     * @returns {String} Numéro sans préfixe
     */
    static extractPhoneNumber(phoneNumber) {
        if (!phoneNumber) return '';
        
        const cleaned = phoneNumber.replace(/\s+/g, '');
        if (cleaned.startsWith('+225')) return cleaned.substring(4);
        if (cleaned.startsWith('225')) return cleaned.substring(3);
        
        return cleaned;
    }
    
    /**
     * Traite les payouts programmés (à exécuter via cron job)
     */
    static async processScheduledPayouts() {
        try {
            const now = new Date();
            const scheduledPayouts = await Payout.find({
                status: 'scheduled',
                trigger_type: 'automatic',
                scheduled_date: { $lte: now }
            }).populate('partner');
            
            logger.info(`Traitement de ${scheduledPayouts.length} payouts programmés`);
            
            for (const payout of scheduledPayouts) {
                try {
                    await this.executeAutomaticPayout(payout);
                } catch (error) {
                    logger.error(`Erreur lors du traitement du payout ${payout.payout_id}:`, error);
                }
            }
            
        } catch (error) {
            logger.error('Erreur lors du traitement des payouts programmés:', error);
        }
    }
}

module.exports = AutomaticPayoutService;
