const axios = require('axios');
const logger = require('../utils/logger');
const waveService = require('./wave.service');
const cinetpayService = require('./cinetpay.service');
const cinetpayTransferService = require('./cinetpay-transfer.service');

/**
 * Service de vérification de santé (health check) pour les composants de paiement
 * Permet de vérifier l'état des services externes sans effectuer d'opérations avec effets secondaires
 */
class HealthService {
    constructor() {
        this.services = {
            wave: {
                name: 'Wave',
                isConfigured: !!process.env.WAVE_API_KEY,
                timeout: 10000 // 10s timeout
            },
            cinetpay: {
                name: 'CinetPay',
                isConfigured: !!process.env.CINETPAY_API_KEY && !!process.env.CINETPAY_SITE_ID,
                timeout: 10000
            },
            cinetpayTransfer: {
                name: 'CinetPay Transfer',
                isConfigured: !!process.env.CINETPAY_TRANSFER_API_KEY && !!process.env.CINETPAY_TRANSFER_APP_ID,
                timeout: 10000
            }
        };

        logger.info('Service Health Check initialisé');
    }

    /**
     * Vérifie la santé globale du système de paiement
     * @returns {Promise<Object>} Statut de santé global et détaillé
     */
    async checkPaymentSystemHealth() {
        const results = {
            wave: await this.checkWaveHealth(),
            cinetpay: await this.checkCinetPayHealth(),
            cinetpayTransfer: await this.checkCinetPayTransferHealth()
        };

        // Déterminer le statut global
        const allOperational = Object.values(results).every(result => result.status === 'operational');
        const anyDegraded = Object.values(results).some(result => result.status === 'degraded');
        const anyDown = Object.values(results).some(result => result.status === 'down');

        let globalStatus = 'operational';
        if (anyDown) {
            globalStatus = 'down';
        } else if (anyDegraded) {
            globalStatus = 'degraded';
        }

        return {
            timestamp: new Date().toISOString(),
            status: globalStatus,
            services: results
        };
    }

    /**
     * Vérifie la santé du service Wave
     * @returns {Promise<Object>} Statut de santé Wave
     */
    async checkWaveHealth() {
        const service = this.services.wave;
        
        if (!service.isConfigured) {
            return {
                name: service.name,
                status: 'unconfigured',
                message: 'Service non configuré (WAVE_API_KEY manquante)',
                timestamp: new Date().toISOString()
            };
        }

        try {
            // Utiliser une simple requête OPTIONS pour vérifier la disponibilité sans créer d'effets secondaires
            const response = await axios({
                method: 'options',
                url: `${process.env.WAVE_BASE_URL || 'https://api.wave.com'}/v1/checkout/sessions`,
                timeout: service.timeout,
                headers: {
                    'User-Agent': 'ChapeChape-Backend-HealthCheck/1.0'
                }
            });

            // Options devrait retourner un 200 OK pour les CORS
            return {
                name: service.name,
                status: 'operational',
                responseTime: response.headers['x-response-time'] || 'N/A',
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            // Si l'erreur est due à CORS/OPTIONS non supporté mais le serveur répond
            if (error.response) {
                // Le serveur a répondu avec un code d'état en dehors de la plage 2xx
                return {
                    name: service.name,
                    status: 'degraded',
                    message: `API accessible mais a répondu avec ${error.response.status}`,
                    timestamp: new Date().toISOString()
                };
            } else if (error.request) {
                // La requête a été faite mais aucune réponse n'a été reçue
                return {
                    name: service.name,
                    status: 'down',
                    message: 'Erreur de connexion ou timeout',
                    timestamp: new Date().toISOString()
                };
            } else {
                // Une erreur s'est produite lors de la configuration de la requête
                return {
                    name: service.name,
                    status: 'error',
                    message: error.message,
                    timestamp: new Date().toISOString()
                };
            }
        }
    }

    /**
     * Vérifie la santé du service CinetPay
     * @returns {Promise<Object>} Statut de santé CinetPay
     */
    async checkCinetPayHealth() {
        const service = this.services.cinetpay;
        
        if (!service.isConfigured) {
            return {
                name: service.name,
                status: 'unconfigured',
                message: 'Service non configuré (CINETPAY_API_KEY ou CINETPAY_SITE_ID manquante)',
                timestamp: new Date().toISOString()
            };
        }

        try {
            // CinetPay ne propose pas d'endpoint de vérification, utiliser un endpoint qui ne modifie pas l'état
            const response = await axios({
                method: 'options',
                url: 'https://api-checkout.cinetpay.com/v2/payment',
                timeout: service.timeout,
                headers: {
                    'User-Agent': 'ChapeChape-Backend-HealthCheck/1.0'
                }
            });

            return {
                name: service.name,
                status: 'operational',
                responseTime: response.headers['x-response-time'] || 'N/A',
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            // Même logique que pour Wave
            if (error.response) {
                return {
                    name: service.name,
                    status: 'degraded',
                    message: `API accessible mais a répondu avec ${error.response.status}`,
                    timestamp: new Date().toISOString()
                };
            } else if (error.request) {
                return {
                    name: service.name,
                    status: 'down',
                    message: 'Erreur de connexion ou timeout',
                    timestamp: new Date().toISOString()
                };
            } else {
                return {
                    name: service.name,
                    status: 'error',
                    message: error.message,
                    timestamp: new Date().toISOString()
                };
            }
        }
    }

    /**
     * Vérifie la santé du service CinetPay Transfer
     * @returns {Promise<Object>} Statut de santé CinetPay Transfer
     */
    async checkCinetPayTransferHealth() {
        const service = this.services.cinetpayTransfer;
        
        if (!service.isConfigured) {
            return {
                name: service.name,
                status: 'unconfigured',
                message: 'Service non configuré (CINETPAY_TRANSFER_API_KEY ou CINETPAY_TRANSFER_APP_ID manquante)',
                timestamp: new Date().toISOString()
            };
        }

        try {
            // CinetPay Transfer ne propose pas d'endpoint de vérification sans authentification
            // On utilise un simple OPTIONS ou HEAD pour vérifier si le service est accessible
            const response = await axios({
                method: 'options',
                url: 'https://client.cinetpay.com/v1/auth/login',
                timeout: service.timeout,
                headers: {
                    'User-Agent': 'ChapeChape-Backend-HealthCheck/1.0'
                }
            });

            return {
                name: service.name,
                status: 'operational',
                responseTime: response.headers['x-response-time'] || 'N/A',
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            // Même logique que précédemment
            if (error.response) {
                return {
                    name: service.name,
                    status: 'degraded',
                    message: `API accessible mais a répondu avec ${error.response.status}`,
                    timestamp: new Date().toISOString()
                };
            } else if (error.request) {
                return {
                    name: service.name,
                    status: 'down',
                    message: 'Erreur de connexion ou timeout',
                    timestamp: new Date().toISOString()
                };
            } else {
                return {
                    name: service.name,
                    status: 'error',
                    message: error.message,
                    timestamp: new Date().toISOString()
                };
            }
        }
    }

    /**
     * Vérifie l'état du système de paiement timer
     * @returns {Promise<Object>} Statut du service payment timer
     */
    async checkPaymentTimerHealth() {
        // Vérifier si les variables d'environnement nécessaires sont définies
        const isConfigured = !!process.env.PAYMENT_EXPIRE_AFTER_HOURS && 
                             !!process.env.PAYMENT_REMINDER_BEFORE_HOURS;

        if (!isConfigured) {
            return {
                name: "Payment Timer",
                status: 'unconfigured',
                message: 'Service non configuré (variables PAYMENT_* manquantes)',
                timestamp: new Date().toISOString()
            };
        }

        // Vérifier si le service agenda est en cours d'exécution
        // C'est une vérification indirecte car nous n'avons pas d'accès direct à agenda
        try {
            // Cette vérification est simple et indique seulement que le service est configuré
            return {
                name: "Payment Timer",
                status: 'operational',
                config: {
                    expireAfterHours: process.env.PAYMENT_EXPIRE_AFTER_HOURS,
                    reminderBeforeHours: process.env.PAYMENT_REMINDER_BEFORE_HOURS
                },
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                name: "Payment Timer",
                status: 'error',
                message: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }
}

module.exports = new HealthService();
