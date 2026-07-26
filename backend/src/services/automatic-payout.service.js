const Payout = require('../models/payout.model');
const Residence = require('../models/residence.model');
const Partner = require('../models/partner.model');
const { getInstance: getWavePayoutService } = require('./wave-payout.service');
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

            // Claim anti-doublon atomique avant création
            const existingForPayment = await Payout.findOne({
                source_transactions: payment._id,
            });
            if (existingForPayment) {
                logger.warn(
                    `Payout déjà existant pour payment ${payment._id}: ${existingForPayment.payout_id}`
                );
                return existingForPayment;
            }

            const payoutChannel = this.determinePayoutChannel(partner);
            let netAmount = grossAmount - commissionAmount;
            if (payoutChannel !== 'wave') {
                netAmount = Math.floor(netAmount / 5) * 5;
                logger.info(
                    `Montant arrondi pour CinetPay: ${grossAmount - commissionAmount} → ${netAmount} XOF`
                );
            }

            const minPayoutAmount = parseInt(process.env.MIN_PAYOUT_AMOUNT) || 1000;
            if (netAmount < minPayoutAmount) {
                logger.warn(`Montant net ${netAmount} inférieur au minimum ${minPayoutAmount}`);
                await this.createManualPayout(
                    payment,
                    reservation,
                    `Montant inférieur au minimum (${minPayoutAmount} XOF)`
                );
                return null;
            }

            const provider =
                payoutChannel === 'wave'
                    ? 'wave'
                    : payoutChannel === 'manual'
                      ? 'manual'
                      : 'cinetpay';

            // Créer l'enregistrement payout
            const payoutId = `auto_${Date.now()}_${partner._id.toString().slice(-6)}`;
            let payout;
            try {
                payout = await Payout.create({
                    payout_id: payoutId,
                    partner: partner._id,
                    source_transactions: [payment._id],
                    gross_amount: grossAmount,
                    commission_amount: commissionAmount,
                    commission_rate: commissionRate,
                    net_amount: netAmount,
                    currency: 'XOF',
                    channel: payoutChannel,
                    recipient_info: {
                        phone_prefix: this.extractPhonePrefix(partner.phoneNumber),
                        phone_number: this.extractPhoneNumber(partner.phoneNumber),
                        full_name:
                            partner.company?.name ||
                            partner.firstName + ' ' + partner.lastName,
                        email: partner.email,
                    },
                    status: 'scheduled',
                    trigger_type: 'automatic',
                    provider,
                    scheduled_for: new Date(
                        Date.now() +
                            (parseInt(process.env.AUTO_PAYOUT_DELAY_MINUTES) || 5) * 60 * 1000
                    ),
                    metadata: {
                        source_payment_id: payment._id,
                        source_reservation_id: reservation._id,
                        auto_generated: true,
                        created_by_webhook: true,
                    },
                });
            } catch (createErr) {
                if (createErr?.code === 11000) {
                    const raced = await Payout.findOne({
                        source_transactions: payment._id,
                    });
                    if (raced) {
                        logger.warn(`Race anti-doublon payout: réutilise ${raced.payout_id}`);
                        return raced;
                    }
                }
                throw createErr;
            }

            logger.info(
                `Payout automatique créé: ${payoutId} - ${netAmount} XOF vers ${partner.company?.name || partner.firstName}`
            );

            // Déclencher le transfert immédiatement si configuré
            if (process.env.AUTO_PAYOUT_IMMEDIATE === 'true' && payoutChannel !== 'manual') {
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
     * Exécute un payout automatique selon le canal (Wave ou CinetPay Transfer)
     * @param {Object} payout - Objet Payout à exécuter
     */
    static async executeAutomaticPayout(payout) {
        try {
            logger.info(`Exécution du payout automatique ${payout.payout_id} via ${payout.channel}`);

            if (payout.channel === 'wave') {
                payout.status = 'processing';
                payout.processed_date = new Date();
                await payout.save();

                const fullPhoneNumber = `${payout.recipient_info.phone_prefix}${payout.recipient_info.phone_number}`;
                const wavePayoutService = getWavePayoutService();
                const waveResult = await wavePayoutService.createPayout({
                    amount: payout.net_amount,
                    mobile: fullPhoneNumber,
                    name: payout.recipient_info.full_name,
                    client_reference: payout.payout_id,
                });

                if (waveResult.success && waveResult.data) {
                    payout.cinetpay_info = {
                        transaction_id: waveResult.data.wave_id,
                        client_transaction_id: waveResult.data.client_reference,
                        status: waveResult.data.status,
                        provider_response: waveResult.data,
                    };
                    payout.status = 'completed';
                    payout.provider = 'wave';
                    logger.info(`Payout automatique Wave ${payout.payout_id} exécuté avec succès`);
                } else {
                    payout.status = 'failed';
                    const errDetail =
                        typeof waveResult.error === 'string'
                            ? waveResult.error
                            : waveResult.error?.message;
                    payout.failure_reason = errDetail || 'Échec du transfert Wave';
                    logger.error(
                        `Échec du payout automatique ${payout.payout_id}: ${payout.failure_reason}`
                    );
                }

                await payout.save();
                return payout;
            }

            // Mobile money / CinetPay Transfer — même rail que payout.service
            // Note: CinetPay peut renvoyer PENDING_EMAIL_CONFIRMATION (confirmation manuelle compte)
            const payoutService = require('./payout.service');
            if (payout.status !== 'scheduled' && payout.status !== 'PAYOUT_SCHEDULED') {
                payout.status = 'scheduled';
                await payout.save();
            }
            await payoutService.executePayout(payout);
            const Payout = require('../models/payout.model');
            return await Payout.findById(payout._id);
        } catch (error) {
            logger.error(`Erreur lors de l'exécution du payout ${payout.payout_id}:`, error);

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
            const existing = await Payout.findOne({ source_transactions: payment._id });
            if (existing) {
                logger.warn(`Payout déjà existant (skip manuel): ${existing.payout_id}`);
                return existing;
            }

            const residence = await Residence.findById(reservation.residence).populate('partner');
            const partner = residence.partner;
            
            const grossAmount = payment.amount;
            const commissionRate = parseFloat(process.env.DEFAULT_COMMISSION_RATE) || 0.10;
            const commissionAmount = Math.round(grossAmount * commissionRate);
            const netAmount = grossAmount - commissionAmount;
            
            const payoutId = `manual_${Date.now()}_${partner._id.toString().slice(-6)}`;
            
            let manualPayout;
            try {
                manualPayout = await Payout.create({
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
                scheduled_for: new Date(),
                failure_reason: `Payout automatique échoué: ${reason}`,
                metadata: {
                    source_payment_id: payment._id,
                    source_reservation_id: reservation._id,
                    auto_generated: true,
                    manual_fallback: true,
                    fallback_reason: reason
                }
            });
            } catch (createErr) {
                if (createErr?.code === 11000) {
                    return await Payout.findOne({ source_transactions: payment._id });
                }
                throw createErr;
            }
            
            logger.info(`Payout manuel créé en fallback: ${payoutId} - Raison: ${reason}`);
            return manualPayout;
            
        } catch (error) {
            logger.error('Erreur lors de la création du payout manuel:', error);
            throw error;
        }
    }
    
    /**
     * Détermine le canal de payout (préfixes opérateurs CI uniquement).
     * Hors CI → wave (multi-opérateur) plutôt qu'un mapping OM/MTN/Moov incorrect.
     */
    static determinePayoutChannel(partner) {
        if (!partner.phoneNumber) return 'manual';

        const digits = String(partner.phoneNumber).replace(/\D/g, '');
        let national = digits;
        let isCI = false;

        if (digits.startsWith('225') && digits.length >= 12) {
            national = digits.slice(3);
            isCI = true;
        } else if (/^0[0-9]{9}$/.test(digits)) {
            national = digits.slice(1);
            isCI = true;
        } else if (/^[0-9]{8,10}$/.test(digits)) {
            // Format local sans indicatif — traité comme CI (marché actuel)
            national = digits.startsWith('0') ? digits.slice(1) : digits;
            isCI = true;
        }

        if (!isCI) {
            return 'wave';
        }

        if (national.startsWith('07')) return 'orange_money';
        if (national.startsWith('05')) return 'mtn_money';
        if (national.startsWith('01')) return 'moov_money';

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
        if (cleaned.startsWith('+')) {
            const m = cleaned.match(/^\+(\d{1,3})/);
            return m ? `+${m[1]}` : '+225';
        }
        const digits = cleaned.replace(/\D/g, '');
        if (digits.startsWith('225')) return '+225';

        return '+225';
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

        const digits = cleaned.replace(/\D/g, '');
        if (digits.startsWith('225') && digits.length >= 12) return digits.slice(3);
        if (digits.startsWith('0') && digits.length === 10) return digits.slice(1);

        return digits || cleaned;
    }

    /**
     * Traite les payouts programmés (à exécuter via cron job)
     */
    static async processScheduledPayouts() {
        try {
            const now = new Date();
            const scheduledPayouts = await Payout.find({
                status: { $in: ['scheduled', 'PAYOUT_SCHEDULED'] },
                trigger_type: 'automatic',
                scheduled_for: { $lte: now },
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
