const axios = require('axios');
const crypto = require('crypto');
const logger = require('../utils/logger');
const Payout = require('../models/payout.model');

/**
 * Service CinetPay Transfer - Gestion des payouts aux partners
 * API Documentation: https://client.cinetpay.com/v1/
 * 
 * Fonctionnalités:
 * - Authentification et gestion de token (5min TTL)
 * - Vérification solde compte
 * - Ajout de contacts
 * - Transfert d'argent vers mobile money/wallets
 * - Suivi statut des transferts
 */
class CinetPayTransferService {
    constructor() {
        // Configuration depuis variables d'environnement
        this.apiKey = process.env.CINETPAY_TRANSFER_API_KEY || process.env.CINETPAY_API_KEY;
        this.password = process.env.CINETPAY_TRANSFER_PASSWORD || 'default_password'; // ⚠️ À configurer
        this.baseUrl = 'https://client.cinetpay.com/v1';
        this.mode = process.env.NODE_ENV === 'production' ? 'production' : 'test';
        
        // Cache token en mémoire
        this.tokenCache = {
            token: null,
            expiresAt: null
        };
        
        // Configuration retry
        this.maxRetries = 3;
        this.retryDelay = 2000; // 2 secondes
        
        // Validation configuration
        if (!this.apiKey || !this.password) {
            logger.error('CinetPay Transfer mal configuré: API Key ou Password manquant');
            throw new Error('Configuration CinetPay Transfer incomplète');
        }
        
        logger.info(`CinetPay Transfer Service initialisé en mode ${this.mode}`);
    }

    // ===============================
    // AUTHENTIFICATION & TOKEN
    // ===============================

    /**
     * Générer ou récupérer un token valide
     * @returns {string} Token d'authentification
     */
    async getValidToken() {
        try {
            // Vérifier si token en cache est encore valide
            if (this.tokenCache.token && this.tokenCache.expiresAt > Date.now()) {
                logger.debug('Utilisation token en cache');
                return this.tokenCache.token;
            }

            // Générer nouveau token
            const token = await this.generateToken();
            
            // Mettre en cache (durée 4min pour sécurité, au lieu de 5min)
            this.tokenCache.token = token;
            this.tokenCache.expiresAt = Date.now() + (4 * 60 * 1000);
            
            logger.info('Nouveau token CinetPay généré et mis en cache');
            return token;
            
        } catch (error) {
            logger.error('Erreur génération token CinetPay:', error);
            throw error;
        }
    }

    /**
     * Générer un nouveau token d'authentification
     * @returns {string} Token
     */
    async generateToken() {
        try {
            const response = await axios({
                method: 'POST',
                url: `${this.baseUrl}/auth/login`,
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                params: {
                    lang: 'fr'
                },
                data: new URLSearchParams({
                    apikey: this.apiKey,
                    password: this.password
                }),
                timeout: 10000
            });

            const result = response.data;
            
            if (result.code === 0 && result.data && result.data.token) {
                logger.info('Token CinetPay généré avec succès');
                return result.data.token;
            } else {
                const errorMsg = result.message || 'Erreur génération token';
                throw new Error(`CinetPay Auth Error: ${errorMsg} (Code: ${result.code})`);
            }
            
        } catch (error) {
            if (error.response) {
                const errorData = error.response.data;
                const errorMsg = errorData.description || errorData.message || 'Erreur API';
                throw new Error(`CinetPay Auth Failed: ${errorMsg} (Code: ${errorData.code})`);
            }
            throw error;
        }
    }

    // ===============================
    // GESTION DU SOLDE
    // ===============================

    /**
     * Vérifier le solde du compte transfert
     * @returns {Object} Informations du solde
     */
    async checkBalance() {
        try {
            const token = await this.getValidToken();
            
            const response = await axios({
                method: 'GET',
                url: `${this.baseUrl}/transfer/check/balance`,
                params: {
                    token: token,
                    lang: 'fr'
                },
                timeout: 10000
            });

            const result = response.data;
            
            if (result.code === 0 && result.data) {
                const balanceInfo = {
                    total: result.data.amount || 0,
                    inUsing: result.data.inUsing || 0,
                    available: result.data.available || 0,
                    currency: 'XOF'
                };
                
                logger.info(`Solde CinetPay: ${balanceInfo.available} XOF disponible`);
                return balanceInfo;
            } else {
                throw new Error(`Erreur récupération solde: ${result.message} (Code: ${result.code})`);
            }
            
        } catch (error) {
            logger.error('Erreur vérification solde CinetPay:', error);
            throw error;
        }
    }

    /**
     * Vérifier si le solde est suffisant pour un payout
     * @param {number} amount Montant requis
     * @returns {boolean} Solde suffisant
     */
    async hasSufficientBalance(amount) {
        try {
            const balance = await this.checkBalance();
            const issufficient = balance.available >= amount;
            
            if (!issufficient) {
                logger.warn(`Solde insuffisant: ${balance.available} XOF disponible, ${amount} XOF requis`);
            }
            
            return isufficient;
            
        } catch (error) {
            logger.error('Erreur vérification solde suffisant:', error);
            return false;
        }
    }

    // ===============================
    // GESTION DES CONTACTS
    // ===============================

    /**
     * Ajouter un contact CinetPay (requis avant transfert)
     * @param {Object} contactInfo Informations du contact
     * @returns {Object} Résultat de l'ajout
     */
    async addContact(contactInfo) {
        try {
            const token = await this.getValidToken();
            
            const contactData = [{
                prefix: contactInfo.phone_prefix || '225', // Côte d'Ivoire par défaut
                phone: contactInfo.phone_number,
                name: contactInfo.last_name || 'Partner',
                surname: contactInfo.first_name || 'ChapeChape',
                email: contactInfo.email
            }];

            const response = await axios({
                method: 'POST',
                url: `${this.baseUrl}/transfer/contact`,
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                params: {
                    token: token,
                    lang: 'fr'
                },
                data: new URLSearchParams({
                    data: JSON.stringify(contactData)
                }),
                timeout: 15000
            });

            const result = response.data;
            
            if (result.code === 0 && result.data && result.data.length > 0) {
                const contact = result.data[0];
                if (contact.status === 'success') {
                    logger.info(`Contact ajouté avec succès: ${contactInfo.phone_number} (Lot: ${contact.lot})`);
                    return {
                        success: true,
                        contact: contact,
                        lot: contact.lot
                    };
                } else {
                    throw new Error(`Erreur ajout contact: ${contact.message || 'Échec'}`);
                }
            } else {
                throw new Error(`Erreur API ajout contact: ${result.message} (Code: ${result.code})`);
            }
            
        } catch (error) {
            logger.error('Erreur ajout contact CinetPay:', error);
            throw error;
        }
    }

    // ===============================
    // TRANSFERT D'ARGENT
    // ===============================

    /**
     * Effectuer un transfert d'argent (payout)
     * @param {Object} payout Instance du modèle Payout
     * @returns {Object} Résultat du transfert
     */
    async sendMoney(payout) {
        try {
            // Validation préalable
            const validation = payout.validateAmount();
            if (!validation.valid) {
                throw new Error(validation.error);
            }

            // Vérifier solde suffisant
            const hasSufficient = await this.hasSufficientBalance(payout.net_amount);
            if (!hasSufficient) {
                throw new Error('INSUFFICIENT_BALANCE: Solde insuffisant pour ce transfert');
            }

            const token = await this.getValidToken();
            
            // S'assurer que le contact existe
            try {
                await this.addContact(payout.recipient_info);
                logger.debug(`Contact vérifié/ajouté pour ${payout.recipient_info.phone_number}`);
            } catch (contactError) {
                logger.warn('Contact déjà existant ou erreur mineure:', contactError.message);
                // Continuer même si contact existe déjà
            }

            // Déterminer le wallet selon le channel
            const paymentMethod = this.getPaymentMethodFromChannel(payout.channel);
            
            // Préparer données de transfert
            const transferData = [{
                prefix: payout.recipient_info.phone_prefix || '225',
                phone: payout.recipient_info.phone_number,
                amount: payout.net_amount,
                client_transaction_id: payout.cinetpay_info.client_transaction_id,
                notify_url: payout.notify_url || `${process.env.APP_URL}/api/payouts/cinetpay/webhook`,
                ...(paymentMethod && { payment_method: paymentMethod })
            }];

            const response = await axios({
                method: 'POST',
                url: `${this.baseUrl}/transfer/money/send/contact`,
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                params: {
                    token: token,
                    lang: 'fr'
                },
                data: new URLSearchParams({
                    data: JSON.stringify(transferData)
                }),
                timeout: 20000
            });

            const result = response.data;
            
            if (result.code === 0 && result.data && result.data.length > 0) {
                const transfer = result.data[0];
                
                if (transfer.status === 'success') {
                    // Mise à jour du payout avec les infos CinetPay
                    payout.status = 'PAYOUT_PENDING';
                    payout.cinetpay_info.transaction_id = transfer.transaction_id;
                    payout.cinetpay_info.lot_id = transfer.lot;
                    payout.cinetpay_info.treatment_status = transfer.treatment_status || 'NEW';
                    payout.cinetpay_info.sending_status = 'PENDING'; // Nécessite confirmation mail
                    
                    logger.info(`Transfert initié avec succès: ${transfer.transaction_id} (Montant: ${payout.net_amount} XOF)`);
                    
                    return {
                        success: true,
                        transaction_id: transfer.transaction_id,
                        lot_id: transfer.lot,
                        status: 'PENDING',
                        treatment_status: transfer.treatment_status,
                        requires_confirmation: true // Mail confirmation requise
                    };
                    
                } else {
                    throw new Error(`Transfert échoué: ${transfer.message || 'Erreur inconnue'} (Code: ${transfer.code})`);
                }
                
            } else {
                throw new Error(`Erreur API transfert: ${result.message} (Code: ${result.code})`);
            }
            
        } catch (error) {
            // Gestion d'erreurs spécifiques
            if (error.message.includes('INSUFFICIENT_BALANCE')) {
                payout.markAsFailed('Solde insuffisant', '602');
            } else if (error.message.includes('INVALID_TOKEN')) {
                // Invalider le cache token et réessayer
                this.tokenCache.token = null;
                throw new Error('Token expiré, veuillez réessayer');
            } else {
                payout.markAsFailed(error.message);
            }
            
            logger.error('Erreur transfert CinetPay:', error);
            throw error;
        }
    }

    // ===============================
    // SUIVI DES TRANSFERTS
    // ===============================

    /**
     * Vérifier le statut d'un transfert
     * @param {string} identifier Transaction ID, Client Transaction ID ou Lot ID
     * @param {string} type Type d'identifiant ('transaction_id', 'client_transaction_id', 'lot')
     * @returns {Object} Statut du transfert
     */
    async checkTransferStatus(identifier, type = 'transaction_id') {
        try {
            const token = await this.getValidToken();
            
            const params = {
                token: token,
                lang: 'fr',
                [type]: identifier
            };

            const response = await axios({
                method: 'GET',
                url: `${this.baseUrl}/transfer/check/money`,
                params: params,
                timeout: 10000
            });

            const result = response.data;
            
            if (result.code === 0 && result.data && result.data.length > 0) {
                const transfer = result.data[0];
                
                logger.info(`Statut transfert ${identifier}: ${transfer.treatment_status}`);
                
                return {
                    success: true,
                    transaction_id: transfer.transaction_id,
                    client_transaction_id: transfer.client_transaction_id,
                    lot: transfer.lot,
                    amount: parseFloat(transfer.amount),
                    receiver: transfer.receiver,
                    operator: transfer.operator,
                    treatment_status: transfer.treatment_status, // NEW, PENDING, VAL, REJECT
                    sending_status: transfer.sending_status,     // PENDING, CONFIRM
                    transfer_valid: transfer.transfer_valid,     // Y/N
                    comment: transfer.comment,
                    validated_at: transfer.validated_at
                };
                
            } else {
                throw new Error(`Transfert non trouvé: ${result.message} (Code: ${result.code})`);
            }
            
        } catch (error) {
            logger.error('Erreur vérification statut transfert:', error);
            throw error;
        }
    }

    /**
     * Synchroniser le statut d'un payout avec CinetPay
     * @param {Object} payout Instance du modèle Payout
     * @returns {boolean} Statut mis à jour
     */
    async syncPayoutStatus(payout) {
        try {
            if (!payout.cinetpay_info.transaction_id && !payout.cinetpay_info.client_transaction_id) {
                logger.warn(`Payout ${payout.payout_id}: Pas d'ID CinetPay pour synchronisation`);
                return false;
            }

            // Utiliser client_transaction_id en priorité
            const identifier = payout.cinetpay_info.client_transaction_id || payout.cinetpay_info.transaction_id;
            const type = payout.cinetpay_info.client_transaction_id ? 'client_transaction_id' : 'transaction_id';
            
            const status = await this.checkTransferStatus(identifier, type);
            
            // Mise à jour du payout selon le statut CinetPay
            let statusUpdated = false;
            
            switch (status.treatment_status) {
                case 'VAL': // Validé = Succès
                    if (payout.status !== 'PAYOUT_SUCCESS') {
                        payout.markAsSuccess(status);
                        statusUpdated = true;
                    }
                    break;
                    
                case 'REJECT': // Rejeté = Échec
                    if (payout.status !== 'PAYOUT_FAILED') {
                        payout.markAsFailed(`Transfert rejeté: ${status.comment}`);
                        statusUpdated = true;
                    }
                    break;
                    
                case 'NEW':
                case 'PENDING':
                    // En cours, pas de changement nécessaire
                    payout.cinetpay_info.treatment_status = status.treatment_status;
                    payout.cinetpay_info.sending_status = status.sending_status;
                    break;
            }
            
            if (statusUpdated) {
                await payout.save();
                logger.info(`Payout ${payout.payout_id} synchronisé: ${payout.status}`);
            }
            
            return statusUpdated;
            
        } catch (error) {
            logger.error(`Erreur sync payout ${payout.payout_id}:`, error);
            return false;
        }
    }

    // ===============================
    // UTILITAIRES
    // ===============================

    /**
     * Mapper le channel ChapeChape vers payment_method CinetPay
     * @param {string} channel Channel du payout
     * @returns {string|null} Payment method CinetPay
     */
    getPaymentMethodFromChannel(channel) {
        const mapping = {
            'wave': 'WAVECI',           // Wave Côte d'Ivoire
            'orange_money': 'OM',       // Orange Money
            'mtn_money': 'MTN',         // MTN Money
            'moov_money': 'MOOV',       // Moov Money
            'bank_transfer': null,      // Pas de wallet spécifique
            'manual': null              // Manuel
        };
        
        return mapping[channel] || null;
    }

    /**
     * Valider le numéro de téléphone selon le pays
     * @param {string} prefix Préfixe pays
     * @param {string} phone Numéro de téléphone
     * @returns {boolean} Numéro valide
     */
    validatePhoneNumber(prefix, phone) {
        const patterns = {
            '225': /^[0-9]{8,10}$/, // Côte d'Ivoire
            '221': /^[0-9]{8,9}$/,  // Sénégal
            '226': /^[0-9]{8}$/,    // Burkina Faso
            '223': /^[0-9]{8}$/     // Mali
        };
        
        const pattern = patterns[prefix];
        return pattern ? pattern.test(phone) : /^[0-9]{8,10}$/.test(phone);
    }

    /**
     * Arrondir le montant aux contraintes CinetPay (multiple de 5)
     * @param {number} amount Montant original
     * @returns {number} Montant arrondi
     */
    roundAmount(amount) {
        return Math.floor(amount / 5) * 5;
    }
}

module.exports = new CinetPayTransferService();
