// Initialisation conditionnelle de Stripe
let stripe;
try {
    if (process.env.STRIPE_SECRET_KEY) {
        stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
    }
} catch (error) {
    console.log('Stripe non configuré');
}

// Import du service CinetPay
const cinetPayService = require('./cinetpay.service');

// Import du service Wave
const waveService = require('./wave.service');

/** Fournisseurs sans intégration PSP réelle (simulation dev uniquement). */
const SIMULATED_PAYMENT_PROVIDERS = new Set(['orange', 'mtn', 'moov', 'djamo']);

class PaymentService {
    constructor() {
        this.providers = {
            stripe: this.stripePayment,
            orange: this.orangeMoneyPayment,
            mtn: this.mtnMoneyPayment,
            moov: this.moovMoneyPayment,
            wave: this.wavePayment,
            djamo: this.djamoPayment,
            cinetpay: this.cinetPayPayment
        };
    }

    async initiatePayment(paymentData) {
        const providerKey = paymentData.paymentProvider;
        if (
            process.env.NODE_ENV === 'production' &&
            SIMULATED_PAYMENT_PROVIDERS.has(providerKey)
        ) {
            throw new Error(
                `Fournisseur « ${providerKey} » désactivé en production. Utilisez cinetpay ou wave.`
            );
        }
        const provider = this.providers[providerKey];
        if (!provider) {
            throw new Error('Méthode de paiement non supportée');
        }
        return await provider.call(this, paymentData);
    }

    // Stripe Payment
    async stripePayment(paymentData) {
        if (!stripe) {
            throw new Error('Stripe n\'est pas configuré');
        }
        const paymentIntent = await stripe.paymentIntents.create({
            amount: paymentData.amount,
            currency: 'xof',
            metadata: {
                reservationId: paymentData.reservation.toString()
            }
        });
        return {
            transactionId: paymentIntent.id,
            status: 'pending',
            clientSecret: paymentIntent.client_secret
        };
    }

    // Orange Money Payment
    async orangeMoneyPayment(paymentData) {
        // Simulation d'une requête à l'API Orange Money
        const response = await this.simulatePaymentRequest('orange', paymentData);
        return {
            transactionId: response.transactionId,
            status: 'processing',
            reference: response.reference,
            providerResponse: response
        };
    }

    // MTN Mobile Money Payment
    async mtnMoneyPayment(paymentData) {
        // Simulation d'une requête à l'API MTN Money
        const response = await this.simulatePaymentRequest('mtn', paymentData);
        return {
            transactionId: response.transactionId,
            status: 'processing',
            reference: response.reference,
            providerResponse: response
        };
    }

    // Moov Money Payment
    async moovMoneyPayment(paymentData) {
        // Simulation d'une requête à l'API Moov Money
        const response = await this.simulatePaymentRequest('moov', paymentData);
        return {
            transactionId: response.transactionId,
            status: 'processing',
            reference: response.reference,
            providerResponse: response
        };
    }

    // Wave Payment - Intégration API réelle
    async wavePayment(paymentData) {
        try {
            const response = await waveService.initiatePayment(
                paymentData, 
                paymentData.user, 
                paymentData.reservation
            );
            
            if (response.success) {
                return {
                    transactionId: response.transactionId,
                    status: response.status,
                    paymentUrl: response.paymentUrl,
                    paymentToken: response.paymentToken,
                    provider: 'wave',
                    providerResponse: response
                };
            } else {
                throw new Error(response.error || 'Erreur Wave');
            }
        } catch (error) {
            throw new Error(`Wave: ${error.message}`);
        }
    }

    // Djamo Payment
    async djamoPayment(paymentData) {
        // Simulation d'une requête à l'API Djamo
        const response = await this.simulatePaymentRequest('djamo', paymentData);
        return {
            transactionId: response.transactionId,
            status: 'processing',
            reference: response.reference,
            providerResponse: response
        };
    }

    // CinetPay Payment - Intégration API réelle
    async cinetPayPayment(paymentData) {
        try {
            const response = await cinetPayService.initiatePayment(
                paymentData, 
                paymentData.user, 
                paymentData.reservation
            );
            
            if (response.success) {
                return {
                    transactionId: response.transactionId,
                    status: response.status,
                    paymentUrl: response.paymentUrl,
                    paymentToken: response.paymentToken,
                    provider: 'cinetpay',
                    providerResponse: response
                };
            } else {
                throw new Error(response.error || 'Erreur CinetPay');
            }
        } catch (error) {
            throw new Error(`CinetPay: ${error.message}`);
        }
    }

    // Simulateur de requête de paiement (dev/test uniquement)
    async simulatePaymentRequest(provider, paymentData) {
        if (process.env.NODE_ENV === 'production') {
            throw new Error(
                `Paiement simulé interdit en production (provider=${provider})`
            );
        }
        return new Promise((resolve) => {
            setTimeout(() => {
                resolve({
                    transactionId: `${provider}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
                    reference: `REF_${Math.random().toString(36).substr(2, 9)}`,
                    status: 'processing',
                    message: `Paiement ${provider} initié avec succès`,
                    phoneNumber: paymentData.phoneNumber,
                    amount: paymentData.amount
                });
            }, 1000);
        });
    }

    /**
     * Vérifier le statut auprès du PSP (jamais de simulation en production).
     */
    async checkPaymentStatus(transactionId, provider) {
        if (!transactionId) {
            throw new Error('ID de transaction requis');
        }

        const normalized = (provider || '').toLowerCase();

        if (normalized === 'wave') {
            const result = await waveService.checkPaymentStatus(transactionId);
            if (!result.success) {
                throw new Error(result.error || 'Impossible de vérifier le paiement Wave');
            }
            return {
                status: result.status,
                message: result.status === 'paid' ? 'Paiement confirmé' : 'Paiement en attente',
            };
        }

        if (normalized === 'cinetpay' || normalized === 'orange' || normalized === 'mtn' || normalized === 'moov' || normalized === 'djamo') {
            const result = await cinetPayService.checkPaymentStatus(transactionId);
            if (!result.success) {
                throw new Error(result.error || 'Impossible de vérifier le paiement CinetPay');
            }
            return {
                status: result.status,
                message: result.status === 'paid' ? 'Paiement confirmé' : 'Paiement en attente',
            };
        }

        if (normalized === 'stripe') {
            if (!stripe) {
                throw new Error('Stripe non configuré');
            }
            const intent = await stripe.paymentIntents.retrieve(transactionId);
            const statusMap = {
                succeeded: 'paid',
                processing: 'pending',
                requires_payment_method: 'failed',
                canceled: 'cancelled',
            };
            return {
                status: statusMap[intent.status] || 'pending',
                message: `Statut Stripe: ${intent.status}`,
            };
        }

        if (process.env.NODE_ENV !== 'production') {
            console.warn(`[DEV] checkPaymentStatus fallback pour provider=${provider}`);
            return { status: 'pending', message: 'Vérification PSP non disponible pour ce fournisseur' };
        }

        throw new Error(`Vérification de paiement non supportée pour: ${provider}`);
    }
}

module.exports = new PaymentService();