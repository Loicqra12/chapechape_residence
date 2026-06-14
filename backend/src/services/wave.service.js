const axios = require('axios');
const logger = require('../utils/logger');
const {
    getWavePaymentWebhookSecret,
    verifyWaveWebhookHmac,
} = require('../utils/wave-webhook-signature.util');

/**
 * Service d'intégration Wave pour ChapeChape Residence
 * Support des paiements Wave en Côte d'Ivoire
 */
class WaveService {
    constructor() {
        // Configuration Wave depuis variables d'environnement
        this.apiKey = process.env.WAVE_API_KEY;
        this.baseUrl = process.env.WAVE_BASE_URL || 'https://api.wave.com';
        this.successUrl = process.env.WAVE_SUCCESS_URL || `${process.env.CLIENT_URL}/payment/success`;
        this.errorUrl = process.env.WAVE_ERROR_URL || `${process.env.CLIENT_URL}/payment/error`;
        this.webhookUrl = process.env.WAVE_WEBHOOK_URL || `${process.env.APP_URL}/api/payments/wave/webhook`;
        // Supporte les deux noms de variable d'environnement pour compatibilité
        this.signingSecret = getWavePaymentWebhookSecret();

        // Flag d'activation pour éviter de faire crasher l'app si la config est incomplète
        this.enabled = true;

        // Validation des paramètres obligatoires (sans throw pour ne pas tuer le serveur)
        if (!this.apiKey) {
            logger.error('Wave mal configuré : WAVE_API_KEY manquante');
            this.enabled = false;
        }

        if (!this.baseUrl) {
            logger.error('Wave mal configuré : WAVE_BASE_URL manquante');
            this.baseUrl = 'https://api.wave.com';
        }

        logger.info('Wave Service initialisé', {
            baseUrl: this.baseUrl,
            enabled: this.enabled,
            hasApiKey: !!this.apiKey,
            hasSigningSecret: !!this.signingSecret
        });
    }

    /**
     * Valider les données de paiement
     * @param {Object} paymentData - Données du paiement
     * @param {Object} user - Utilisateur
     * @param {Object} reservation - Réservation
     * @returns {Object} Validation result
     */
    validatePaymentData(paymentData, user, reservation) {
        if (!paymentData.amount || paymentData.amount <= 0) {
            return { valid: false, error: 'Montant invalide' };
        }

        if (!paymentData.phoneNumber) {
            return { valid: false, error: 'Numéro de téléphone requis' };
        }

        if (!user || !user._id) {
            return { valid: false, error: 'Utilisateur invalide' };
        }

        if (!reservation || !reservation._id) {
            return { valid: false, error: 'Réservation invalide' };
        }

        return { valid: true };
    }

    /**
     * Formater le numéro de téléphone pour Wave
     * @param {string} phoneNumber - Numéro brut
     * @returns {string} Numéro formaté
     */
    formatPhoneNumber(phoneNumber) {
        if (!phoneNumber) return null; // Pas de fallback fictif — laisser Wave gérer
        
        // Nettoyer le numéro
        let clean = phoneNumber.replace(/\D/g, '');
        
        // Ajouter le préfixe ivoirien si nécessaire
        if (clean.length === 10 && clean.startsWith('0')) {
            clean = '225' + clean.substring(1);
        } else if (clean.length === 8) {
            clean = '225' + clean;
        }
        
        return '+' + clean;
    }

    // Initialiser un paiement Wave
    async initiatePayment(paymentData, user, reservation) {
        try {
            // Vérifier que le service est correctement configuré
            if (!this.enabled) {
                logger.error('Initiation Wave impossible: service désactivé (configuration manquante)');
                return {
                    success: false,
                    error: 'Service Wave désactivé: configuration manquante',
                    provider: 'wave'
                };
            }

            // Validation des données d'entrée
            const validation = this.validatePaymentData(paymentData, user, reservation);
            if (!validation.valid) {
                logger.error('Validation Wave échouée:', validation.error);
                return {
                    success: false,
                    error: validation.error
                };
            }

            // Construction du payload Wave selon la documentation officielle
            const payload = {
                // Champs obligatoires selon la doc Wave
                amount: paymentData.amount.toString(), // DOIT être string selon la doc
                currency: paymentData.currency || 'XOF',
                success_url: this.successUrl,
                error_url: this.errorUrl,
                
                // Champ optionnel mais recommandé pour traçabilité
                client_reference: reservation._id.toString()
            };

            // Log de la requête (sans apikey pour sécurité)
            logger.info('Initiation paiement Wave', {
                amount: payload.amount,
                currency: payload.currency,
                client_reference: payload.client_reference
            });

            const response = await axios({
                method: 'post',
                url: `${this.baseUrl}/v1/checkout/sessions`, // ✅ Endpoint correct selon la doc
                headers: {
                    'Authorization': `Bearer ${this.apiKey}`,
                    'Content-Type': 'application/json',
                    'User-Agent': 'ChapeChape-Backend/1.0'
                },
                data: payload,
                timeout: 30000 // 30 secondes timeout
            });

            if (response.data && response.data.wave_launch_url) {
                logger.info('Paiement Wave créé avec succès', {
                    transactionId: response.data.id || response.data.session_id,
                    client_reference: payload.client_reference
                });

                return {
                    success: true,
                    transactionId: response.data.id || response.data.session_id,
                    status: 'pending',
                    paymentUrl: response.data.wave_launch_url,
                    paymentToken: response.data.id || response.data.session_id,
                    provider: 'wave',
                    providerResponse: response.data
                };
            } else {
                throw new Error(`Réponse Wave inattendue: ${JSON.stringify(response.data)}`);
            }
        } catch (error) {
            logger.error('Erreur lors de l\'initiation du paiement Wave:', {
                error: error.message,
                reservationId: (reservation && reservation._id) ? reservation._id : (paymentData && paymentData.reservation ? paymentData.reservation : null),
                amount: paymentData && paymentData.amount,
                response: error.response?.data
            });

            // Gestion des erreurs spécifiques Wave
            if (error.response?.data) {
                const waveError = error.response.data;
                return {
                    success: false,
                    error: this.mapWaveError(waveError),
                    errorCode: waveError.code || error.response.status,
                    provider: 'wave'
                };
            }

            return {
                success: false,
                error: error.message || 'Erreur de connexion Wave',
                provider: 'wave'
            };
        }
    }

    /**
     * Mapper les erreurs Wave vers des messages utilisateur
     * @param {Object} waveError - Erreur Wave
     * @returns {string} Message d'erreur utilisateur
     */
    mapWaveError(waveError) {
        const errorMappings = {
            '400': 'Paramètres de paiement invalides',
            '401': 'Clé API Wave invalide',
            '403': 'Accès non autorisé',
            '404': 'Service Wave indisponible',
            '429': 'Trop de requêtes, veuillez réessayer plus tard',
            '500': 'Erreur serveur Wave'
        };

        const errorCode = waveError.code?.toString() || waveError.status?.toString();
        return errorMappings[errorCode] || waveError.message || 'Erreur de paiement Wave inconnue';
    }

    // Vérifier la signature du webhook
    verifySignature(payloadBuffer, signature) {
        if (!this.signingSecret) {
            console.warn('WAVE_SIGNING_SECRET/WAVE_WEBHOOK_SECRET non configuré');
            return false;
        }
        return verifyWaveWebhookHmac(payloadBuffer, signature, this.signingSecret);
    }

    /**
     * Traiter une notification webhook Wave
     * Selon la doc Wave, les webhooks ont des événements checkout.session.*
     * @param {Object} webhookData - Données du webhook
     * @returns {Object} Résultat du traitement
     */
    async processWebhook(webhookData) {
        try {
            logger.info('Traitement webhook Wave:', webhookData);

            // Récupérer l'ID de transaction selon la structure Wave
            const transactionId = webhookData.data?.id || webhookData.id;
            
            if (!transactionId) {
                throw new Error('ID de transaction manquant dans la notification');
            }

            // Déterminer le statut selon les événements Wave documentés
            let status;
            switch(webhookData.event) {
                case 'checkout.session.completed':
                    // Vérifier également payment_status dans les données
                    if (webhookData.data?.payment_status === 'succeeded') {
                        status = 'paid';
                    } else {
                        status = 'pending';
                    }
                    break;
                case 'checkout.session.failed':
                case 'checkout.session.expired':
                    status = 'failed';
                    break;
                default:
                    status = 'pending';
            }

            return {
                success: true,
                transactionId: transactionId,
                status: status,
                webhookData: webhookData
            };
        } catch (error) {
            logger.error('Erreur de traitement webhook Wave:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }

    /**
     * Vérifier le statut d'un paiement Wave
     * @param {string} transactionId - ID de transaction
     * @returns {Object} Statut du paiement
     */
    async checkPaymentStatus(transactionId) {
        try {
            if (!this.enabled) {
                return {
                    success: false,
                    error: 'Service Wave désactivé: configuration manquante'
                };
            }
            if (!transactionId) {
                throw new Error('ID de transaction requis');
            }

            const response = await axios({
                method: 'get',
                url: `${this.baseUrl}/v1/checkout/sessions/${transactionId}`, // ✅ Endpoint correct selon la doc
                headers: {
                    'Authorization': `Bearer ${this.apiKey}`,
                    'Content-Type': 'application/json',
                    'User-Agent': 'ChapeChape-Backend/1.0'
                },
                timeout: 15000
            });

            let status = 'pending';
            // Selon la doc Wave, le statut est dans payment_status, pas status
            const paymentStatus = response.data && response.data.payment_status;
            if (paymentStatus) {
                switch(paymentStatus.toLowerCase()) {
                    case 'succeeded':
                        status = 'paid';
                        break;
                    case 'failed':
                    case 'canceled':
                    case 'cancelled':
                    case 'expired':
                        status = 'failed';
                        break;
                    case 'processing':
                    case 'pending':
                    default:
                        status = 'pending';
                }
            }

            logger.info('Vérification statut Wave', {
                transactionId,
                payment_status: response.data?.payment_status,
                mappedStatus: status
            });

            return {
                success: true,
                status: status,
                data: response.data
            };
        } catch (error) {
            logger.error('Erreur vérification statut Wave:', {
                error: error.message,
                transactionId,
                response: error.response?.data
            });

            return {
                success: false,
                error: error.response?.data?.message || error.message || 'Erreur de vérification statut'
            };
        }
    }
}

module.exports = new WaveService();
