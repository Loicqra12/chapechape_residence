const axios = require('axios');
const logger = require('../utils/logger');
const { v4: uuidv4 } = require('uuid');
const {
    getWavePayoutWebhookSecret,
    verifyWaveWebhookHmac,
} = require('../utils/wave-webhook-signature.util');

/**
 * Service Wave Payout - Gestion des transferts sortants via Wave API
 * 
 * Endpoints Wave:
 * - POST /v1/payout - Créer un transfert
 * - GET /v1/payout/:id - Statut d'un transfert
 * - GET /v1/payouts/search - Rechercher des transferts
 * - POST /v1/payout-batch - Créer un batch de transferts
 * - GET /v1/payout-batch/:id - Statut d'un batch
 * - POST /v1/payout/:id/reverse - Annuler un transfert
 */

class WavePayoutService {
    constructor() {
        // Clé API Wave Payout (WAVE_PAYOUT_API_KEY dans le .env DigitalOcean)
        // ⚠️  NE PAS utiliser de caractères accentués dans les noms de variables Linux
        this.apiKey = process.env.WAVE_PAYOUT_API_KEY;
        this.baseUrl = process.env.WAVE_BASE_URL || process.env.WAVE_PAYOUT_BASE_URL || 'https://api.wave.com';
        this.webhookSecret = getWavePayoutWebhookSecret();
        
        if (!this.apiKey) {
            logger.warn('WAVE_PAYOUT_CONFIG_MISSING', { reason: 'WAVE_PAYOUT_API_KEY' });
            // Ne pas faire planter le serveur, juste désactiver le service
            this.isEnabled = false;
            return; // Sortir du constructeur sans erreur
        } else {
            this.isEnabled = true;
            logger.info('WAVE_PAYOUT_INITIALIZED');
        }
    }

    /**
     * Configuration des headers pour les requêtes Wave
     */
    getHeaders(idempotencyKey = null) {
        const headers = {
            'Authorization': `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json'
        };
        
        if (idempotencyKey) {
            headers['Idempotency-Key'] = idempotencyKey;
        }
        
        return headers;
    }

    /**
     * Générer une clé d'idempotence unique
     */
    generateIdempotencyKey() {
        return uuidv4();
    }

    /**
     * Créer un transfert Wave
     * POST /v1/payout
     */
    async createPayout(payoutData) {
        if (!this.isEnabled) {
            throw new Error('Service Wave Payout désactivé - Clé API manquante');
        }
        
        try {
            const {
                amount,
                currency = 'XOF',
                mobile,
                name,
                client_reference,
                payment_reason,
                national_id
            } = payoutData;

            const idempotencyKey = this.generateIdempotencyKey();
            
            const payload = {
                currency,
                receive_amount: amount.toString(),
                mobile,
                name,
                client_reference,
                payment_reason,
                ...(national_id && { national_id })
            };

            logger.info('Initiation transfert Wave', {
                client_reference,
                amount,
                currency,
                mobile: mobile.substring(0, 8) + '***' // Masquer le numéro
            });

            const response = await axios.post(
                `${this.baseUrl}/v1/payout`,
                payload,
                { 
                    headers: this.getHeaders(idempotencyKey),
                    timeout: 30000 // 30 secondes timeout
                }
            );

            logger.info('Transfert Wave créé avec succès', {
                client_reference,
                wave_id: response.data.id,
                status: response.data.status
            });

            return {
                success: true,
                data: {
                    wave_id: response.data.id,
                    status: response.data.status,
                    amount: response.data.receive_amount,
                    fee: response.data.fee,
                    currency: response.data.currency,
                    timestamp: response.data.timestamp,
                    client_reference: response.data.client_reference,
                    idempotency_key: idempotencyKey
                }
            };

        } catch (error) {
            logger.error('Erreur création transfert Wave:', error.response?.data || error.message);
            
            return {
                success: false,
                error: this.formatError(error),
                retry_recommended: this.shouldRetry(error)
            };
        }
    }

    /**
     * Récupérer le statut d'un transfert
     * GET /v1/payout/:id
     */
    async getPayoutStatus(waveId) {
        try {
            const response = await axios.get(
                `${this.baseUrl}/v1/payout/${waveId}`,
                { headers: this.getHeaders() }
            );

            return {
                success: true,
                data: {
                    wave_id: response.data.id,
                    status: response.data.status,
                    amount: response.data.receive_amount,
                    fee: response.data.fee,
                    currency: response.data.currency,
                    mobile: response.data.mobile,
                    name: response.data.name,
                    timestamp: response.data.timestamp,
                    client_reference: response.data.client_reference,
                    payout_error: response.data.payout_error
                }
            };

        } catch (error) {
            logger.error(`Erreur récupération statut Wave ${waveId}:`, error.response?.data || error.message);
            
            return {
                success: false,
                error: this.formatError(error)
            };
        }
    }

    /**
     * Rechercher des transferts par client_reference
     * GET /v1/payouts/search
     */
    async searchPayouts(client_reference) {
        try {
            const response = await axios.get(
                `${this.baseUrl}/v1/payouts/search`,
                { 
                    headers: this.getHeaders(),
                    params: { client_reference }
                }
            );

            return {
                success: true,
                data: response.data.result || []
            };

        } catch (error) {
            logger.error(`Erreur recherche transferts Wave:`, error.response?.data || error.message);
            
            return {
                success: false,
                error: this.formatError(error)
            };
        }
    }

    /**
     * Créer un batch de transferts
     * POST /v1/payout-batch
     */
    async createPayoutBatch(payouts) {
        try {
            const idempotencyKey = this.generateIdempotencyKey();
            
            const payload = {
                payouts: payouts.map(payout => ({
                    currency: payout.currency || 'XOF',
                    receive_amount: payout.amount.toString(),
                    mobile: payout.mobile,
                    name: payout.name,
                    client_reference: payout.client_reference,
                    payment_reason: payout.payment_reason,
                    ...(payout.national_id && { national_id: payout.national_id })
                }))
            };

            logger.info('Initiation batch transferts Wave', {
                count: payouts.length,
                total_amount: payouts.reduce((sum, p) => sum + p.amount, 0)
            });

            const response = await axios.post(
                `${this.baseUrl}/v1/payout-batch`,
                payload,
                { headers: this.getHeaders(idempotencyKey) }
            );

            logger.info('Batch transferts Wave créé', {
                batch_id: response.data.id
            });

            return {
                success: true,
                data: {
                    batch_id: response.data.id,
                    idempotency_key: idempotencyKey
                }
            };

        } catch (error) {
            logger.error('Erreur création batch transferts Wave:', error.response?.data || error.message);
            
            return {
                success: false,
                error: this.formatError(error),
                retry_recommended: this.shouldRetry(error)
            };
        }
    }

    /**
     * Récupérer le statut d'un batch
     * GET /v1/payout-batch/:id
     */
    async getPayoutBatchStatus(batchId) {
        try {
            const response = await axios.get(
                `${this.baseUrl}/v1/payout-batch/${batchId}`,
                { headers: this.getHeaders() }
            );

            return {
                success: true,
                data: {
                    batch_id: response.data.id,
                    status: response.data.status,
                    payouts: response.data.payouts || []
                }
            };

        } catch (error) {
            logger.error(`Erreur récupération batch Wave ${batchId}:`, error.response?.data || error.message);
            
            return {
                success: false,
                error: this.formatError(error)
            };
        }
    }

    /**
     * Annuler un transfert
     * POST /v1/payout/:id/reverse
     */
    async reversePayout(waveId) {
        try {
            const idempotencyKey = this.generateIdempotencyKey();
            
            await axios.post(
                `${this.baseUrl}/v1/payout/${waveId}/reverse`,
                {},
                { headers: this.getHeaders(idempotencyKey) }
            );

            logger.info(`Transfert Wave annulé: ${waveId}`);

            return {
                success: true,
                data: {
                    wave_id: waveId,
                    status: 'reversed',
                    idempotency_key: idempotencyKey
                }
            };

        } catch (error) {
            logger.error(`Erreur annulation transfert Wave ${waveId}:`, error.response?.data || error.message);
            
            return {
                success: false,
                error: this.formatError(error)
            };
        }
    }

    /**
     * Vérifier la signature HMAC du webhook
     */
    verifyWebhookSignature(rawBody, signature) {
        return verifyWaveWebhookHmac(rawBody, signature, this.webhookSecret);
    }

    /**
     * Traiter un webhook Wave Payout
     */
    async processWebhook(webhookData) {
        try {
            logger.info('Traitement webhook Wave Payout:', webhookData);

            // Extraire les informations du webhook
            const {
                id: wave_id,
                status,
                client_reference,
                receive_amount,
                fee,
                currency,
                mobile,
                name,
                timestamp,
                payout_error
            } = webhookData;

            return {
                success: true,
                data: {
                    wave_id,
                    status,
                    client_reference,
                    amount: receive_amount,
                    fee,
                    currency,
                    mobile,
                    name,
                    timestamp,
                    error: payout_error,
                    webhookData
                }
            };

        } catch (error) {
            logger.error('Erreur traitement webhook Wave Payout:', error);
            
            return {
                success: false,
                error: error.message
            };
        }
    }

    /**
     * Mapper les statuts Wave vers les statuts ChapeChape
     */
    mapWaveStatusToChapeChape(waveStatus) {
        const statusMap = {
            'processing': 'PAYOUT_PENDING',
            'succeeded': 'PAYOUT_SUCCESS',
            'failed': 'PAYOUT_FAILED',
            'reversed': 'PAYOUT_CANCELLED'
        };

        return statusMap[waveStatus] || 'PAYOUT_PENDING';
    }

    /**
     * Formater les erreurs Wave
     */
    formatError(error) {
        if (error.response?.data) {
            const errorData = error.response.data;
            
            if (errorData.code && errorData.message) {
                return {
                    code: errorData.code,
                    message: errorData.message,
                    details: errorData.details
                };
            }
            
            if (errorData.error_code && errorData.error_message) {
                return {
                    code: errorData.error_code,
                    message: errorData.error_message
                };
            }
        }

        return {
            code: 'unknown_error',
            message: error.message || 'Erreur inconnue'
        };
    }

    /**
     * Déterminer si une erreur justifie une nouvelle tentative
     */
    shouldRetry(error) {
        if (!error.response) {
            return true; // Erreur réseau
        }

        const status = error.response.status;
        const errorCode = error.response.data?.code || error.response.data?.error_code;

        // Erreurs système à réessayer
        const retryableStatuses = [408, 429, 500, 502, 503, 504];
        const retryableErrorCodes = [
            'internal-server-error',
            'service-unavailable',
            'too-many-requests'
        ];

        return retryableStatuses.includes(status) || 
               retryableErrorCodes.includes(errorCode);
    }
}

// Export de la classe pour éviter les erreurs lors de l'instanciation
// L'instance sera créée seulement quand nécessaire
let wavePayoutService = null;

function getInstance() {
    if (!wavePayoutService) {
        try {
            wavePayoutService = new WavePayoutService();
        } catch (error) {
            logger.warn('WAVE_PAYOUT_INIT_FAILED', { err: error.message });
            // Retourner un service mock qui ne fait rien
            wavePayoutService = {
                isEnabled: false,
                createPayout: async () => { throw new Error('Service Wave Payout non disponible'); },
                getPayoutStatus: async () => { throw new Error('Service Wave Payout non disponible'); },
                cancelPayout: async () => { throw new Error('Service Wave Payout non disponible'); },
                verifyWebhookSignature: () => false
            };
        }
    }
    return wavePayoutService;
}

module.exports = {
    WavePayoutService,
    getInstance
};
