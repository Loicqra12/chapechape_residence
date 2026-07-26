const axios = require('axios');
const crypto = require('crypto');
const logger = require('../utils/logger');

/**
 * Service d'intégration CinetPay pour ChapeChape Residence
 * Support des paiements mobile money africains via CinetPay
 * 
 * Documentation: https://docs.cinetpay.com/
 * API Endpoint: https://api-checkout.cinetpay.com/v2/payment
 */
class CinetPayService {
    constructor() {
        // Configuration CinetPay depuis variables d'environnement (aucun fallback pour éviter d'exposer des clés)
        this.apiKey = process.env.CINETPAY_API_KEY;
        this.siteId = process.env.CINETPAY_SITE_ID;
        this.secretKey = process.env.CINETPAY_SECRET_KEY;
        this.baseUrl = process.env.CINETPAY_BASE_URL || 'https://api-checkout.cinetpay.com/v2';
        this.mode = process.env.NODE_ENV === 'production' ? 'PRODUCTION' : 'TEST';

        // URLs de callback
        this.notifyUrl = process.env.CINETPAY_NOTIFY_URL || `${process.env.APP_URL}/api/payments/cinetpay/webhook`;
        this.returnUrl = process.env.CINETPAY_RETURN_URL || `${process.env.CLIENT_URL}/payment/success`;

        // Validation des paramètres obligatoires
        if (!this.apiKey || !this.siteId || !this.secretKey) {
            logger.error('CinetPay mal configuré : variables d\'environnement manquantes (CINETPAY_API_KEY, CINETPAY_SITE_ID, CINETPAY_SECRET_KEY)');
            this.enabled = false;
            return; // Désactiver le service sans planter le serveur
        }

        this.enabled = true;
        logger.info(`CinetPay Service initialisé en mode ${this.mode}`);
    }

    /**
     * Générer un ID de transaction unique
     * Évite les caractères spéciaux (#,/,$,_,&) comme recommandé par CinetPay
     */
    generateTransactionId() {
        const timestamp = Date.now().toString();
        const random = Math.floor(Math.random() * 100000).toString();
        return `CHAPE${timestamp}${random}`;
    }

    /**
     * Validation du montant selon les contraintes CinetPay
     * @param {number} amount - Montant en XOF
     * @returns {boolean} - Validité du montant
     */
    validateAmount(amount) {
        // Le montant doit être un multiple de 5 (sauf USD)
        if (amount < 5) {
            return { valid: false, error: 'Montant minimum : 5 XOF' };
        }
        if (amount % 5 !== 0) {
            return { valid: false, error: 'Le montant doit être un multiple de 5' };
        }
        return { valid: true };
    }

    /**
     * Initier un paiement CinetPay
     * @param {Object} paymentData - Données du paiement
     * @param {Object} user - Données utilisateur
     * @param {Object} reservation - Données réservation
     * @returns {Object} Réponse CinetPay avec payment_url
     */
    async initiatePayment(paymentData, user, reservation) {
        try {
            // Vérifier que le service est configuré
            if (!this.enabled) {
                logger.error('CinetPay désactivé — variables d\'environnement manquantes');
                return {
                    success: false,
                    error: 'Service CinetPay non configuré. Contactez l\'administrateur.',
                    provider: 'cinetpay'
                };
            }

            // Validation du montant
            const amountValidation = this.validateAmount(paymentData.amount);
            if (!amountValidation.valid) {
                throw new Error(amountValidation.error);
            }

            // Générer un ID de transaction unique
            const transactionId = this.generateTransactionId();

            // Construction du payload CinetPay
            const payload = {
                // Paramètres obligatoires
                apikey: this.apiKey,
                site_id: this.siteId,
                transaction_id: transactionId,
                amount: paymentData.amount,
                currency: paymentData.currency || 'XOF',
                description: `Réservation ChapeChape - ${reservation.residence?.title || 'Résidence'}`,
                notify_url: this.notifyUrl,
                return_url: this.returnUrl,
                channels: this.determineChannels(paymentData.paymentMethod),
                lang: 'FR',

                // Métadonnées pour traçabilité
                metadata: JSON.stringify({
                    reservationId: reservation._id.toString(),
                    userId: user._id.toString(),
                    appVersion: 'ChapeChape-v1.0'
                }),

                // Informations client (requises pour carte bancaire)
                customer_id: user._id.toString(),
                customer_name: user.lastName || 'Client',
                customer_surname: user.firstName || 'ChapeChape',
                customer_email: user.email,
                customer_phone_number: this.formatPhoneNumber(user.phoneNumber || paymentData.phoneNumber),
                customer_address: user.address || 'Abidjan',
                customer_city: user.city || 'Abidjan',
                customer_country: 'CI', // Côte d'Ivoire
                customer_state: 'CI',
                customer_zip_code: '00225',

                // Données de facture (optionnel)
                invoice_data: {
                    'Réservation': reservation._id.toString(),
                    'Résidence': reservation.residence?.title || 'N/A',
                    'Période': `${new Date(reservation.checkIn).toLocaleDateString()} - ${new Date(reservation.checkOut).toLocaleDateString()}`
                }
            };

            // Log de la requête (sans apikey pour sécurité)
            logger.info('Initiation paiement CinetPay', {
                transactionId,
                amount: payload.amount,
                currency: payload.currency,
                channels: payload.channels,
                customer: payload.customer_email
            });

            // Appel API CinetPay avec headers anti-Cloudflare
            const response = await axios({
                method: 'post',
                url: `${this.baseUrl}/payment`,
                headers: {
                    'Content-Type': 'application/json',
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                    'Accept': 'application/json, text/plain, */*',
                    'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
                    'Accept-Encoding': 'gzip, deflate, br',
                    'Connection': 'keep-alive',
                    'Origin': 'https://chapechaperesidence.com',
                    'Referer': 'https://chapechaperesidence.com/',
                    'Sec-Fetch-Dest': 'empty',
                    'Sec-Fetch-Mode': 'cors',
                    'Sec-Fetch-Site': 'cross-site'
                },
                data: payload,
                timeout: 30000 // 30 secondes timeout
            });

            // Gestion de la réponse
            if (response.data.code === '201' && response.data.data.payment_url) {
                logger.info('Paiement CinetPay créé avec succès', {
                    transactionId,
                    paymentToken: response.data.data.payment_token
                });

                return {
                    success: true,
                    transactionId,
                    paymentUrl: response.data.data.payment_url,
                    paymentToken: response.data.data.payment_token,
                    provider: 'cinetpay',
                    status: 'pending',
                    metadata: {
                        cinetpay_response_id: response.data.api_response_id,
                        amount: payload.amount,
                        currency: payload.currency
                    }
                };
            } else {
                throw new Error(`Erreur CinetPay: ${response.data.message || 'Réponse inattendue'}`);
            }

        } catch (error) {
            logger.error('Erreur lors de l\'initiation du paiement CinetPay:', {
                error: error.message,
                reservationId: reservation._id.toString(),
                amount: paymentData.amount,
                cinetpayResponse: error.response?.data,
                statusCode: error.response?.status
            });

            // Gestion des erreurs spécifiques CinetPay
            if (error.response?.data) {
                const cinetpayError = error.response.data;
                return {
                    success: false,
                    error: this.mapCinetPayError(cinetpayError),
                    errorCode: cinetpayError.code,
                    provider: 'cinetpay'
                };
            }

            return {
                success: false,
                error: error.message || 'Erreur de connexion CinetPay',
                provider: 'cinetpay'
            };
        }
    }

    /**
     * Déterminer les canaux de paiement selon la méthode sélectionnée
     * @param {string} paymentMethod - Méthode de paiement
     * @returns {string} Channels CinetPay
     */
    determineChannels(paymentMethod) {
        switch (paymentMethod?.toLowerCase()) {
            case 'card':
            case 'credit_card':
                return 'CREDIT_CARD';
            case 'orange_money':
            case 'mtn_money':
            case 'moov_money':
                return 'MOBILE_MONEY';
            case 'wallet':
                return 'WALLET';
            default:
                return 'ALL'; // Tous les canaux disponibles
        }
    }

    /**
     * Formater le numéro de téléphone pour CinetPay
     * @param {string} phoneNumber - Numéro brut
     * @returns {string} Numéro formaté avec préfixe
     */
    formatPhoneNumber(phoneNumber) {
        if (!phoneNumber || !String(phoneNumber).trim()) {
            throw new Error('Numéro de téléphone requis pour le paiement Mobile Money');
        }
        let phone = String(phoneNumber).trim().replace(/\s+/g, '');
        // Normaliser vers E.164 approximatif CI
        if (phone.startsWith('00')) phone = `+${phone.slice(2)}`;
        if (/^0[0-9]{9}$/.test(phone)) phone = `+225${phone.slice(1)}`;
        if (/^[0-9]{10}$/.test(phone)) phone = `+225${phone}`;
        if (!phone.startsWith('+')) phone = `+${phone}`;
        if (!/^\+[1-9][0-9]{7,14}$/.test(phone)) {
            throw new Error(`Numéro de téléphone invalide: ${phoneNumber}`);
        }
        return phone;
    }

    /**
     * Mapper les erreurs CinetPay vers des messages utilisateur
     * @param {Object} cinetpayError - Erreur CinetPay
     * @returns {string} Message d'erreur utilisateur
     */
    mapCinetPayError(cinetpayError) {
        const errorMappings = {
            '608': 'Paramètres de paiement invalides',
            '609': 'Clé API invalide',
            '613': 'Identifiant site invalide',
            '624': 'Erreur de traitement du paiement',
            '403': 'Requête non autorisée',
            '429': 'Trop de requêtes, veuillez réessayer plus tard',
            '1010': 'Restriction de sécurité'
        };

        const errorCode = cinetpayError.code?.toString();
        return errorMappings[errorCode] || cinetpayError.message || 'Erreur de paiement inconnue';
    }

    /**
     * Vérifier le statut d'un paiement CinetPay
     * @param {string} transactionId - ID de transaction
     * @returns {Object} Statut du paiement
     */
    async checkPaymentStatus(transactionId) {
        try {
            if (!this.enabled) {
                return { success: false, error: 'Service CinetPay non configuré' };
            }
            const payload = {
                apikey: this.apiKey,
                site_id: this.siteId,
                transaction_id: transactionId
            };

            const response = await axios({
                method: 'post',
                url: `${this.baseUrl}/payment/check`,
                headers: {
                    'Content-Type': 'application/json',
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                    'Accept': 'application/json, text/plain, */*',
                    'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
                    'Accept-Encoding': 'gzip, deflate, br',
                    'Connection': 'keep-alive',
                    'Origin': 'https://chapechaperesidence.com',
                    'Referer': 'https://chapechaperesidence.com/',
                    'Sec-Fetch-Dest': 'empty',
                    'Sec-Fetch-Mode': 'cors',
                    'Sec-Fetch-Site': 'cross-site'
                },
                data: payload,
                timeout: 15000
            });

            logger.info('Vérification statut CinetPay', {
                transactionId,
                status: response.data.data?.status
            });

            // Mapper les statuts CinetPay vers les valeurs enum du modèle
            const cinetpayStatus = response.data.data?.status;
            const mappedStatus = this.mapCinetPayStatusToModel(cinetpayStatus);

            return {
                success: true,
                status: mappedStatus,
                data: response.data.data
            };

        } catch (error) {
            logger.error('Erreur vérification statut CinetPay:', {
                error: error.message,
                transactionId
            });

            return {
                success: false,
                error: error.message
            };
        }
    }

    /**
     * Mapper les statuts CinetPay vers les valeurs enum du modèle Payment
     * @param {string} cinetpayStatus - Statut retourné par CinetPay
     * @returns {string} Statut mappé pour le modèle
     */
    mapCinetPayStatusToModel(cinetpayStatus) {
        const statusMapping = {
            'PENDING': 'pending',
            'ACCEPTED': 'paid',
            'REFUSED': 'failed',
            'CANCELLED': 'cancelled',
            'EXPIRED': 'failed'
        };

        return statusMapping[cinetpayStatus] || 'pending';
    }

    /**
     * Vérifie le header `x-token` (HMAC-SHA256) des notifications checkout CinetPay.
     * @see https://docs.cinetpay.com/api/1.0-en/checkout/hmac
     * @param {Object} body - req.body (application/x-www-form-urlencoded)
     * @param {string} receivedXToken - valeur du header x-token
     * @returns {boolean}
     */
    verifyNotificationHmac(body, receivedXToken) {
        if (!this.secretKey || !receivedXToken || typeof receivedXToken !== 'string') {
            return false;
        }
        const get = (keys) => {
            for (const k of keys) {
                if (body[k] !== undefined && body[k] !== null) {
                    return String(body[k]);
                }
            }
            return '';
        };
        const parts = [
            ['cpm_site_id'],
            ['cpm_trans_id'],
            ['cpm_trans_date'],
            ['cpm_amount'],
            ['cpm_currency'],
            ['signature'],
            ['payment_method'],
            ['cel_phone_num'],
            ['cpm_phone_prefixe'],
            ['cpm_language'],
            ['cpm_version'],
            ['cpm_payment_config'],
            ['cpm_page_action'],
            ['cpm_custom'],
            ['cpm_designation'],
            ['cpm_error_message']
        ];
        const data = parts.map((keys) => get(keys)).join('');

        const expected = crypto
            .createHmac('sha256', this.secretKey)
            .update(data, 'utf8')
            .digest('hex');

        const recv = String(receivedXToken).trim();
        try {
            if (recv.length !== expected.length) {
                return false;
            }
            return crypto.timingSafeEqual(Buffer.from(recv, 'utf8'), Buffer.from(expected, 'utf8'));
        } catch {
            return false;
        }
    }

    /**
     * Traiter une notification webhook CinetPay
     * @param {Object} webhookData - Données du webhook
     * @returns {Object} Résultat du traitement
     */
    async processWebhook(webhookData) {
        try {
            logger.info('Traitement webhook CinetPay:', webhookData);

            const transactionId = webhookData.cpm_trans_id;
            const status = webhookData.cpm_result;
            const amount = webhookData.cpm_amount;

            return {
                success: true,
                transactionId,
                status: status === '00' ? 'paid' : 'failed', // ✅ HARMONISÉ - était 'completed'
                amount: parseFloat(amount),
                provider: 'cinetpay',
                webhookData
            };

        } catch (error) {
            logger.error('Erreur traitement webhook CinetPay:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }
}

module.exports = new CinetPayService();
