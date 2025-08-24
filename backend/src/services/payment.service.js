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
        const provider = this.providers[paymentData.paymentProvider];
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

    // Simulateur de requête de paiement (à remplacer par de vraies intégrations API)
    async simulatePaymentRequest(provider, paymentData) {
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

    // Vérifier le statut d'un paiement
    async checkPaymentStatus(transactionId, provider) {
        // Pour la démo, on simule un succès immédiat après confirmation OTP
        return new Promise((resolve) => {
            setTimeout(() => {
                resolve({
                    status: 'paid', // ✅ HARMONISÉ - était 'completed'
                    message: 'Paiement confirmé avec succès'
                });
            }, 1000);
        });
    }
}

module.exports = new PaymentService();