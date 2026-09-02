const Payment = require('../../models/payment.model');
const Reservation = require('../../models/reservation.model');
const PaymentService = require('../../services/payment.service');
const waveService = require('../../services/wave.service');
const logger = require('../../utils/logger');
const cinetPayService = require('../../services/cinetpay.service');
const {
    claimWebhookEvent,
    completeWebhookEvent,
    failWebhookEvent,
    applyPaymentPaid,
} = require('../../services/payment-confirmation.service');
const { getWavePaymentWebhookSecret } = require('../../utils/wave-webhook-signature.util');
const { canAccessPayment } = require('../../security/resource-access');

/**
 * Clé d'idempotence stable par événement Wave (type + session), pas seulement par session.
 */
function extractWaveWebhookEventId(webhookData) {
    const transactionId = webhookData?.data?.id || webhookData?.id;
    if (webhookData?.event && transactionId) {
        return `wave:${webhookData.event}:${transactionId}`;
    }
    if (transactionId) {
        return `wave:${transactionId}`;
    }
    return `wave:${JSON.stringify(webhookData || {}).slice(0, 120)}`;
}

let stripe;
try {
    if (process.env.STRIPE_SECRET_KEY) {
        stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
    }
} catch (_) {
    stripe = null;
}

// Créer une intention de paiement
exports.createPaymentIntent = async (req, res) => {
    try {
        const { reservationId, paymentMethod, phoneNumber } = req.body;

        // Vérifier si la réservation existe
        const reservation = await Reservation.findById(reservationId);
        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: "Réservation non trouvée"
            });
        }

        // Vérifier si la réservation n'est pas déjà payée
        if (reservation.paymentStatus === 'paid') {
            return res.status(400).json({
                success: false,
                message: "Cette réservation a déjà été payée"
            });
        }

        // Vérifier si la réservation n'est pas annulée
        if (reservation.status === 'cancelled') {
            return res.status(400).json({
                success: false,
                message: "Impossible de payer une réservation annulée"
            });
        }

        // Vérifier si l'utilisateur est autorisé
        if (reservation.user.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: "Vous n'êtes pas autorisé à payer cette réservation"
            });
        }

        // Normalisation des aliases vers formats canoniques
        let normalizedPaymentMethod = paymentMethod;
        if (paymentMethod === 'om') {
            normalizedPaymentMethod = 'orange_money';
            logger.debug('⚠️ DEPRECATED: "om" alias utilisé, normalisé vers "orange_money"');
        } else if (paymentMethod === 'momo') {
            normalizedPaymentMethod = 'mtn_money';
            logger.debug('⚠️ DEPRECATED: "momo" alias utilisé, normalisé vers "mtn_money"');
        }

        let paymentProvider;
        if (normalizedPaymentMethod === 'card') {
            paymentProvider = 'stripe';
        } else if (normalizedPaymentMethod === 'wave') {
            paymentProvider = 'wave';
        } else if (normalizedPaymentMethod === 'cinetpay' || normalizedPaymentMethod === 'mobile_money' ||
            normalizedPaymentMethod === 'orange_money' || normalizedPaymentMethod === 'mtn_money' || normalizedPaymentMethod === 'moov_money') {
            paymentProvider = 'cinetpay';
        } else {
            return res.status(400).json({
                success: false,
                message: 'Méthode de paiement non supportée'
            });
        }

        // ✅ VÉRIFICATION ANTI-DOUBLON : Chercher un paiement actif existant
        const existingPayment = await Payment.findOne({
            reservation: reservationId,
            status: 'pending',
            paymentMethod: normalizedPaymentMethod,
        }).sort({ createdAt: -1 });

        if (existingPayment) {
            logger.debug(`🔄 Paiement actif existant trouvé: ${existingPayment.transactionId}`);

            const amountMatches =
                Number(existingPayment.amount) === Number(reservation.totalPrice);
            const thirtyMinutesAgo = new Date(Date.now() - 30 * 60 * 1000);
            const stillFresh = existingPayment.createdAt > thirtyMinutesAgo;

            if (stillFresh && amountMatches) {
                // Retourner le paiement existant (idempotence)
                return res.status(200).json({
                    success: true,
                    data: {
                        paymentId: existingPayment._id,
                        transactionId: existingPayment.transactionId,
                        status: existingPayment.status,
                        paymentUrl: existingPayment.paymentDetails?.providerResponse?.paymentUrl,
                        expiresAt: new Date(existingPayment.createdAt.getTime() + 30 * 60 * 1000).toISOString()
                    }
                });
            }

            // Montant divergé ou trop vieux → invalider et recréer
            existingPayment.status = 'expired';
            await existingPayment.save();
            logger.debug(
                amountMatches
                    ? `⏰ Paiement expiré marqué: ${existingPayment.transactionId}`
                    : `💱 Montant divergé (${existingPayment.amount} ≠ ${reservation.totalPrice}) — intent invalidé: ${existingPayment.transactionId}`
            );
        }

        // Vérifier le numéro de téléphone pour les méthodes mobiles avec regex plus souple
        // Accepte les formats internationaux comme +225... et des longueurs variables (8-15 chiffres)
        if (normalizedPaymentMethod !== 'card' && (!phoneNumber || !/^\+?\d{8,15}$/.test(phoneNumber))) {
            return res.status(400).json({
                success: false,
                message: 'Numéro de téléphone invalide. Format attendu: chiffres avec ou sans préfixe +'
            });
        }

        // Initialiser le paiement via le service approprié en passant les objets complets
        const paymentResponse = await PaymentService.initiatePayment({
            amount: reservation.totalPrice,
            paymentMethod: normalizedPaymentMethod,
            paymentProvider,
            phoneNumber,
            reservation: reservation, // Passer l'objet complet
            user: req.user // Passer l'objet utilisateur complet
        });

        // Créer l'enregistrement de paiement
        const payment = await Payment.create({
            reservation: reservationId,
            amount: reservation.totalPrice,
            paymentMethod: normalizedPaymentMethod,
            paymentProvider,
            phoneNumber,
            transactionId: paymentResponse.transactionId,
            status: paymentResponse.status,
            paymentDetails: {
                reference: paymentResponse.reference,
                providerResponse: paymentResponse.providerResponse
            }
        });

        res.status(200).json({
            success: true,
            data: {
                paymentId: payment._id,
                ...paymentResponse
            }
        });
    } catch (error) {
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

// Confirmer un paiement
exports.confirmPayment = async (req, res) => {
    try {
        const { paymentId } = req.params;
        const { otp } = req.body;

        const payment = await Payment.findById(paymentId);
        if (!payment) {
            return res.status(404).json({
                success: false,
                message: "Paiement non trouvé"
            });
        }

        // Vérifier que la réservation appartient à l'utilisateur connecté
        const reservation = await Reservation.findById(payment.reservation);
        if (!reservation || reservation.user.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: "Non autorisé à confirmer ce paiement"
            });
        }

        const statusResponse = await PaymentService.checkPaymentStatus(
            payment.transactionId,
            payment.paymentProvider
        );

        if (otp) {
            payment.paymentDetails = payment.paymentDetails || {};
            payment.paymentDetails.otp = otp;
            await payment.save();
        }

        let resultPayment = payment;
        if (statusResponse.status === 'paid') {
            const confirmation = await applyPaymentPaid(payment, { triggerPayout: true });
            resultPayment = confirmation.payment || payment;
        } else if (statusResponse.status === 'failed' || statusResponse.status === 'cancelled') {
            payment.status = statusResponse.status;
            await payment.save();
            resultPayment = payment;
        } else {
            payment.status = 'pending';
            payment.providerStatus = 'processing';
            await payment.save();
            resultPayment = payment;
        }

        res.status(200).json({
            success: true,
            data: resultPayment,
            providerStatus: statusResponse.status,
            message: statusResponse.message,
        });
    } catch (error) {
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};


// Obtenir l'historique des paiements d'un utilisateur
exports.getUserPayments = async (req, res) => {
    try {
        const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
        const limit = Math.min(parseInt(req.query.limit, 10) || 20, 100);
        const skip = (page - 1) * limit;

        const reservationIds = await Reservation.find({ user: req.user._id })
            .select('_id')
            .lean();

        const ids = reservationIds.map((r) => r._id);

        const [payments, total] = await Promise.all([
            Payment.find({ reservation: { $in: ids } })
                .populate('reservation')
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limit),
            Payment.countDocuments({ reservation: { $in: ids } }),
        ]);

        res.status(200).json({
            success: true,
            data: payments,
            payments,
            pagination: {
                page,
                limit,
                total,
                hasNext: skip + payments.length < total,
            },
        });
    } catch (error) {
        res.status(400).json({
            success: false,
            message: error.message,
        });
    }
};

// Mettre à jour le statut de la réservation en fonction des paiements
async function updateReservationStatus(reservationId) {
    const reservation = await Reservation.findById(reservationId);
    if (!reservation) return;

    const payments = await Payment.find({ reservation: reservationId });

    const completedPayments = payments.filter(p => p.status === 'paid'); // ✅ HARMONISÉ - était 'completed'
    const refundedPayments = payments.filter(p => p.status === 'refunded');

    if (completedPayments.length === 1 && refundedPayments.length > 0) {
        // Ne jamais promouvoir vers confirmed ici (bypass approval / inventaire).
        if (reservation.paymentStatus !== 'paid') {
            reservation.paymentStatus = 'paid';
        }
    } else if (completedPayments.length === 0 && refundedPayments.length === payments.length) {
        // Tous les paiements sont remboursés
        reservation.status = 'refunded';
        reservation.paymentStatus = 'refunded';
    }

    await reservation.save();
}

// Demander un remboursement
exports.requestRefund = async (req, res) => {
    try {
        const { paymentId } = req.params;
        const { reason, amount, markExternalRefund = false } = req.body;
        const isAdmin = ['admin', 'superadmin'].includes(req.user.role);

        const payment = await Payment.findById(paymentId).populate('reservation');
        if (!payment) {
            return res.status(404).json({
                success: false,
                message: 'Paiement non trouvé',
            });
        }

        if (!isAdmin) {
            if (
                !payment.reservation ||
                payment.reservation.user?.toString() !== req.user._id.toString()
            ) {
                return res.status(403).json({
                    success: false,
                    message: 'Non autorisé à demander un remboursement',
                });
            }
            return res.status(501).json({
                success: false,
                message:
                    'Le remboursement automatique n’est pas encore disponible. Contactez le support.',
            });
        }

        if (payment.status === 'refunded') {
            return res.status(400).json({
                success: false,
                message: 'Ce paiement a déjà été remboursé',
            });
        }

        if (payment.status !== 'paid') {
            return res.status(400).json({
                success: false,
                message: 'Seuls les paiements confirmés peuvent être remboursés',
            });
        }

        const refundAmount = amount != null ? Number(amount) : payment.amount;
        if (refundAmount <= 0 || refundAmount > payment.amount) {
            return res.status(400).json({
                success: false,
                message: 'Montant de remboursement invalide',
            });
        }

        let pspRefund = null;

        // Stripe : remboursement PSP réel
        if (payment.paymentProvider === 'stripe') {
            if (!stripe) {
                return res.status(503).json({
                    success: false,
                    message: 'Stripe non configuré (STRIPE_SECRET_KEY manquant)',
                });
            }
            const intentId = payment.transactionId;
            if (!intentId) {
                return res.status(400).json({
                    success: false,
                    message: 'transactionId Stripe manquant sur le paiement',
                });
            }
            pspRefund = await stripe.refunds.create({
                payment_intent: intentId,
                amount: Math.round(refundAmount), // XOF = pas de décimales
                reason: 'requested_by_customer',
                metadata: {
                    paymentId: String(payment._id),
                    adminId: String(req.user._id),
                    reason: String(reason).slice(0, 400),
                },
            });
        } else if (!markExternalRefund) {
            // Wave / CinetPay : pas d’API refund auto — sync admin après dashboard PSP
            logger.warn('Remboursement admin bloqué — PSP sans API auto', {
                paymentId,
                provider: payment.paymentProvider,
                adminId: req.user._id,
                reason,
            });
            return res.status(501).json({
                success: false,
                message:
                    'Remboursement automatique indisponible pour ce PSP. Remboursez via le dashboard, puis rappelez avec markExternalRefund: true.',
                action_required: 'refund_via_psp_dashboard_then_mark',
                paymentId,
                paymentProvider: payment.paymentProvider,
                amount: payment.amount,
            });
        }

        payment.status = 'refunded';
        payment.refundAmount = refundAmount;
        payment.refundReason = reason;
        payment.paymentDetails = payment.paymentDetails || {};
        payment.paymentDetails.providerResponse = {
            ...(payment.paymentDetails.providerResponse || {}),
            refund: pspRefund || {
                mode: 'external',
                markedBy: req.user._id,
                markedAt: new Date().toISOString(),
                reason,
            },
        };
        await payment.save();

        await updateReservationStatus(payment.reservation._id || payment.reservation);

        // Libérer les dates si réservation passée en refunded
        try {
            const reservation = await Reservation.findById(payment.reservation);
            if (reservation && reservation.status === 'refunded') {
                const availabilityService = require('../../services/availability.service');
                await availabilityService.updateAvailabilityForReservation(
                    reservation.residence,
                    reservation.checkIn,
                    reservation.checkOut,
                    reservation._id,
                    'available',
                    reservation.bookingType || 'day'
                );
            }
        } catch (availErr) {
            logger.warn('Libération dispo après refund échouée:', availErr?.message);
        }

        return res.status(200).json({
            success: true,
            message: pspRefund
                ? 'Remboursement Stripe effectué'
                : 'Paiement marqué remboursé (sync externe)',
            data: {
                payment,
                pspRefund: pspRefund
                    ? { id: pspRefund.id, status: pspRefund.status, amount: pspRefund.amount }
                    : null,
            },
        });
    } catch (error) {
        logger.error('Erreur requestRefund:', error);
        res.status(400).json({
            success: false,
            message: error.message,
        });
    }
};

// Webhook pour les événements de paiement Stripe
exports.handleStripeWebhook = async (req, res) => {
    try {
        if (!stripe || !process.env.STRIPE_WEBHOOK_SECRET) {
            logger.error('Webhook Stripe: STRIPE_SECRET_KEY ou STRIPE_WEBHOOK_SECRET manquant');
            return res.status(503).json({ success: false, message: 'Stripe webhook non configuré' });
        }

        const signature = req.headers['stripe-signature'];
        if (!signature) {
            return res.status(401).json({ success: false, message: 'Signature Stripe requise' });
        }

        // req.body doit être un Buffer (route montée avant express.json)
        const event = stripe.webhooks.constructEvent(
            req.body,
            signature,
            process.env.STRIPE_WEBHOOK_SECRET
        );

        const claim = await claimWebhookEvent('stripe', event.id);
        if (!claim.claimed) {
            return res.json({ received: true, duplicate: true });
        }

        try {
            if (event.type === 'payment_intent.succeeded') {
                const intent = event.data.object;
                const payment = await Payment.findOne({ transactionId: intent.id });
                if (payment) {
                    await applyPaymentPaid(payment, {
                        providerResponse: intent,
                        triggerPayout: true,
                        allowExpired: true,
                    });
                }
            } else if (event.type === 'payment_intent.payment_failed') {
                const intent = event.data.object;
                await Payment.updateOne(
                    { transactionId: intent.id },
                    { $set: { status: 'failed', providerStatus: 'processing' } }
                );
            }

            await completeWebhookEvent('stripe', event.id);
            res.json({ received: true });
        } catch (processError) {
            await failWebhookEvent('stripe', event.id, processError.message);
            throw processError;
        }
    } catch (error) {
        logger.error('Erreur webhook Stripe:', error);
        res.status(400).json({
            success: false,
            message: error.message,
        });
    }
};

// Webhook pour les événements de paiement CinetPay
exports.handleCinetPayWebhook = async (req, res) => {
    let eventId = null;
    try {
        const webhookData = req.body || {};
        const xToken = req.get('x-token') || req.headers['x-token'];

        if (process.env.CINETPAY_WEBHOOK_DISABLE_SIGNATURE_CHECK === 'true') {
            if (process.env.NODE_ENV === 'production') {
                return res.status(403).json({
                    success: false,
                    message: 'Vérification HMAC obligatoire en production',
                });
            }
            logger.warn('Webhook CinetPay: HMAC désactivé (dev uniquement)');
        } else {
            if (!xToken) {
                logger.warn('Webhook CinetPay: header x-token absent');
                return res.status(401).json({
                    success: false,
                    message: 'Non autorisé'
                });
            }
            if (!cinetPayService.verifyNotificationHmac(webhookData, xToken)) {
                logger.error('Webhook CinetPay: x-token HMAC invalide', { cpm_trans_id: webhookData.cpm_trans_id });
                return res.status(403).json({
                    success: false,
                    message: 'Signature invalide'
                });
            }
        }

        eventId = String(
            webhookData.cpm_trans_id ||
            webhookData.transaction_id ||
            `${webhookData.cpm_custom}_${webhookData.cpm_amount}`
        );

        const claim = await claimWebhookEvent('cinetpay', eventId);
        if (!claim.claimed) {
            return res.json({ success: true, message: 'Événement déjà traité', duplicate: true });
        }

        logger.info('Webhook CinetPay reçu (HMAC valide)', { cpm_trans_id: webhookData.cpm_trans_id });

        try {
            const result = await cinetPayService.processWebhook(webhookData);

            if (!result.success) {
                throw new Error(result.error || 'Erreur traitement webhook');
            }

            const payment = await Payment.findOne({
                transactionId: result.transactionId,
            });

            if (payment && result.status === 'paid') {
                await applyPaymentPaid(payment, {
                    providerResponse: result.webhookData,
                    triggerPayout: true,
                    allowExpired: true,
                });
            } else if (payment && result.status) {
                payment.status = result.status;
                payment.paymentDetails = payment.paymentDetails || {};
                payment.paymentDetails.providerResponse = result.webhookData;
                await payment.save();
            }

            await completeWebhookEvent('cinetpay', eventId);
            res.json({
                success: true,
                message: 'Webhook traité avec succès',
            });
        } catch (processError) {
            await failWebhookEvent('cinetpay', eventId, processError.message);
            throw processError;
        }

    } catch (error) {
        logger.error('Erreur webhook CinetPay:', error);
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

// Webhook pour les événements de paiement Wave
exports.handleWaveWebhook = async (req, res) => {
    try {
        const signature = req.headers['x-wave-signature'] || req.headers['wave-signature'];
        const rawBody = req.body;

        const waveSigningSecret = getWavePaymentWebhookSecret();

        if (!waveSigningSecret) {
            if (process.env.NODE_ENV === 'production') {
                logger.error('Webhook Wave: WAVE_SIGNING_SECRET ou WAVE_WEBHOOK_SECRET manquant en production');
                return res.status(503).json({
                    success: false,
                    message: 'Webhook Wave non configuré',
                });
            }
            logger.warn('Webhook Wave accepté sans signature (environnement non production)');
        } else {
            if (!signature) {
                return res.status(401).json({
                    success: false,
                    message: 'Signature Wave requise',
                });
            }
            if (!Buffer.isBuffer(rawBody)) {
                logger.warn('Webhook Wave paiement: corps non Buffer');
                return res.status(400).json({
                    success: false,
                    message: 'Format de requête incompatible avec la vérification de signature',
                });
            }
            const isValid = waveService.verifySignature(rawBody, signature);
            if (!isValid) {
                logger.error('Signature Wave invalide');
                return res.status(400).json({
                    success: false,
                    message: 'Signature invalide',
                });
            }
        }

        let webhookData;
        try {
            if (Buffer.isBuffer(rawBody)) {
                webhookData = JSON.parse(rawBody.toString('utf8'));
            } else if (rawBody && typeof rawBody === 'object') {
                webhookData = rawBody;
            } else if (typeof rawBody === 'string') {
                webhookData = JSON.parse(rawBody);
            } else {
                return res.status(400).json({
                    success: false,
                    message: 'Corps de requête invalide'
                });
            }
        } catch (parseError) {
            logger.error('Erreur parsing webhook Wave:', parseError);
            return res.status(400).json({
                success: false,
                message: 'Corps de requête JSON invalide'
            });
        }

        const waveEventId = String(extractWaveWebhookEventId(webhookData));
        const claim = await claimWebhookEvent('wave', waveEventId);
        if (!claim.claimed) {
            // Déjà traité ou en cours — ACK 200 pour éviter retries inutiles
            return res.json({ received: true, duplicate: true });
        }

        // ⚠️ TOUJOURS répondre 200 à Wave après claim (retries indéfinis sinon).
        try {
            const result = await waveService.processWebhook(webhookData);

            if (result.success) {
                const payment = await Payment.findOne({
                    transactionId: result.transactionId,
                });

                if (payment && result.status === 'paid') {
                    await applyPaymentPaid(payment, {
                        providerResponse: result.webhookData,
                        triggerPayout: true,
                        allowExpired: true,
                    });
                } else if (payment && result.status) {
                    payment.status = result.status;
                    payment.paymentDetails = payment.paymentDetails || {};
                    payment.paymentDetails.providerResponse = result.webhookData;
                    await payment.save();
                } else {
                    logger.warn('Aucun paiement pour transaction Wave:', result.transactionId);
                }
            }

            await completeWebhookEvent('wave', waveEventId);
            res.json({ received: true });
        } catch (processError) {
            await failWebhookEvent('wave', waveEventId, processError.message);
            logger.error('Erreur traitement webhook Wave (ACK 200, retry possible):', {
                error: processError.message,
                eventId: waveEventId,
            });
            res.json({ received: true, processingError: true });
        }

    } catch (error) {
        logger.error('Erreur webhook Wave:', error);
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

// Vérifier le statut d'un paiement CinetPay en temps réel
exports.verifyCinetPayPayment = async (req, res) => {
    try {
        const { transactionId } = req.params;
        const cinetPayService = require('../../services/cinetpay.service');

        const payment = await Payment.findOne({ transactionId }).populate('reservation');
        if (!payment || !payment.reservation) {
            return res.status(404).json({
                success: false,
                error: 'Paiement introuvable',
                code: 'PAYMENT_NOT_FOUND',
                message: 'Aucun paiement trouvé avec cet ID de transaction',
            });
        }

        if (!canAccessPayment(payment, payment.reservation, req.user)) {
            return res.status(403).json({
                success: false,
                message: 'Non autorisé',
            });
        }

        const cinetPayStatus = await cinetPayService.checkPaymentStatus(transactionId);

        if (cinetPayStatus.success) {
            let nextPayment = payment;
            if (payment.status !== cinetPayStatus.status) {
                if (cinetPayStatus.status === 'paid') {
                    await applyPaymentPaid(payment, {
                        providerResponse: cinetPayStatus.data,
                        triggerPayout: true,
                        allowExpired: true,
                    });
                } else {
                    payment.status = cinetPayStatus.status;
                    payment.paymentDetails = payment.paymentDetails || {};
                    payment.paymentDetails.providerResponse = cinetPayStatus.data;
                    await payment.save();
                }
                nextPayment = await Payment.findById(payment._id).populate('reservation');
            }

            const responsePayment = {
                _id: nextPayment._id,
                transactionId: nextPayment.transactionId,
                status: nextPayment.status,
                amount: nextPayment.amount,
                paymentMethod: nextPayment.paymentMethod,
                paymentProvider: nextPayment.paymentProvider,
                createdAt: nextPayment.createdAt,
                updatedAt: nextPayment.updatedAt,
            };

            const response = {
                success: true,
                payment: responsePayment,
            };

            if (nextPayment.status === 'pending') {
                response.statusInfo = {
                    message: 'Paiement en cours de traitement',
                    nextCheck: 'Recommandé dans 5-10 secondes',
                    maxWaitTime: '5 minutes',
                    canRetry: true
                };
            } else if (nextPayment.status === 'paid') {
                response.statusInfo = {
                    message: 'Paiement confirmé avec succès',
                    finalStatus: true
                };
            } else if (nextPayment.status === 'failed') {
                response.statusInfo = {
                    message: 'Paiement échoué',
                    finalStatus: true,
                    canRetry: true
                };
            }

            return res.json(response);
        }

        return res.status(400).json({
            success: false,
            error: 'Erreur de vérification CinetPay',
            code: 'CINETPAY_VERIFICATION_ERROR',
            message: 'Impossible de vérifier le statut du paiement auprès de CinetPay',
            transactionId: transactionId,
            canRetry: true,
            retryAfter: '10 secondes'
        });
    } catch (error) {
        logger.error('Erreur vérification CinetPay:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur serveur lors de la vérification',
        });
    }
};

// Vérifier le statut d'un paiement par transactionId (lookup direct — rapide)
exports.getPaymentStatus = async (req, res) => {
    try {
        const { transactionId } = req.params;

        if (!transactionId) {
            return res.status(400).json({ success: false, message: 'transactionId requis' });
        }

        // Une seule requête incluant reservation pour éviter le bypass d'autorisation
        const payment = await Payment.findOne({ transactionId })
            .select('_id transactionId status providerStatus amount currency paymentMethod paymentProvider reservation createdAt updatedAt')
            .lean();

        if (!payment) {
            return res.status(404).json({
                success: false,
                message: 'Paiement non trouvé',
                transactionId,
            });
        }

        // Vérification obligatoire : le paiement doit avoir une réservation
        if (!payment.reservation) {
            return res.status(403).json({ success: false, message: 'Non autorisé' });
        }

        // Vérifier que la réservation appartient à l'utilisateur connecté
        const Reservation = require('../../models/reservation.model');
        const reservation = await Reservation.findById(payment.reservation)
            .select('user partner client')
            .lean();

        if (!reservation || !canAccessPayment(payment, reservation, req.user)) {
            return res.status(403).json({ success: false, message: 'Non autorisé' });
        }

        // Retourner sans le champ reservation pour ne pas exposer l'ID
        const { reservation: _omit, ...paymentData } = payment;

        res.status(200).json({
            success: true,
            payment: paymentData,
        });
    } catch (error) {
        logger.error('Erreur getPaymentStatus:', error);
        res.status(500).json({ success: false, message: error.message });
    }
};
