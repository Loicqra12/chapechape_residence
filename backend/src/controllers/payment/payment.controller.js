const Payment = require('../../models/payment.model');
const Reservation = require('../../models/reservation.model');
const User = require('../../models/user.model');
const { Conversation, Message } = require('../../models/message.model');
const PaymentService = require('../../services/payment.service');
const waveService = require('../../services/wave.service');
const logger = require('../../utils/logger');
const cinetPayService = require('../../services/cinetpay.service');

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

        let paymentProvider;
        if (paymentMethod === 'card') {
            paymentProvider = 'stripe';
        } else if (paymentMethod === 'wave') {
            paymentProvider = 'wave';
        } else if (paymentMethod === 'cinetpay' || paymentMethod === 'mobile_money' || paymentMethod === 'om' || paymentMethod === 'momo') {
            paymentProvider = 'cinetpay';
        } else {
            return res.status(400).json({
                success: false,
                message: 'Méthode de paiement non supportée'
            });
        }

        // Vérifier le numéro de téléphone pour les méthodes mobiles avec regex plus souple
        // Accepte les formats internationaux comme +225... et des longueurs variables (8-15 chiffres)
        if (paymentMethod !== 'card' && (!phoneNumber || !/^\+?\d{8,15}$/.test(phoneNumber))) {
            return res.status(400).json({
                success: false,
                message: 'Numéro de téléphone invalide. Format attendu: chiffres avec ou sans préfixe +'
            });
        }

        // Initialiser le paiement via le service approprié en passant les objets complets
        const paymentResponse = await PaymentService.initiatePayment({
            amount: reservation.totalPrice,
            paymentMethod,
            paymentProvider,
            phoneNumber,
            reservation: reservation, // Passer l'objet complet
            user: req.user // Passer l'objet utilisateur complet
        });

        // Créer l'enregistrement de paiement
        const payment = await Payment.create({
            reservation: reservationId,
            amount: reservation.totalPrice,
            paymentMethod,
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

        // Vérifier le statut du paiement auprès du fournisseur
        const statusResponse = await PaymentService.checkPaymentStatus(
            payment.transactionId,
            payment.paymentProvider
        );

        // Mettre à jour le statut du paiement
        payment.status = statusResponse.status;
        if (otp) {
            payment.paymentDetails.otp = otp;
        }
        await payment.save();

        // Si le paiement est complété, mettre à jour la réservation
        if (statusResponse.status === 'paid') { // ✅ HARMONISÉ - était 'completed'
            const reservation = await Reservation.findById(payment.reservation);
            if (reservation) {
                // Vérifier s'il n'y a pas d'autres paiements complétés
                const otherCompletedPayments = await Payment.find({
                    reservation: payment.reservation,
                    status: 'paid', // ✅ HARMONISÉ - était 'completed'
                    _id: { $ne: paymentId }
                });

                if (otherCompletedPayments.length === 0) {
                    // Utiliser updateOne pour éviter les problèmes de validation sur les anciens documents
                    await Reservation.updateOne(
                        { _id: payment.reservation },
                        { 
                            $set: {
                                paymentStatus: 'paid',
                                status: 'confirmed',
                                messagingEnabled: true
                            }
                        }
                    );
                    
                    // Créer une conversation entre le client et le partenaire si elle n'existe pas déjà
                    const existingConversation = await Conversation.findOne({
                        reservationId: reservation._id
                    });
                    
                    if (!existingConversation) {
                        // Obtenir les informations de l'utilisateur et du partenaire
                        const populatedReservation = await Reservation.findById(reservation._id)
                            .populate('user partner residence');
                        
                        // Vérifier que les participants existent avant de créer la conversation
                        if (populatedReservation && populatedReservation.user && populatedReservation.partner) {
                            const conversation = await Conversation.create({
                                participants: [populatedReservation.user._id, populatedReservation.partner._id],
                                reservationId: populatedReservation._id,
                                residenceId: populatedReservation.residence._id,
                                createdAt: Date.now(),
                                updatedAt: Date.now()
                            });
                        
                            // Envoyer un message automatique de bienvenue
                            const message = await Message.create({
                                conversation: conversation._id,
                                sender: populatedReservation.partner._id,
                                content: `Merci pour votre réservation de "${populatedReservation.residence.name}" ! N'hésitez pas à me contacter pour toute question concernant votre séjour.`
                            });
                            
                            // Mettre à jour le dernier message de la conversation
                            conversation.lastMessage = message._id;
                            await conversation.save();
                        }
                    }
                }
            }
        }

        res.status(200).json({
            success: true,
            data: payment
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
        const payments = await Payment.find({})
            .populate({
                path: 'reservation',
                match: { user: req.user._id }
            })
            .sort({ createdAt: -1 });

        const validPayments = payments.filter(payment => payment.reservation);

        res.status(200).json({
            success: true,
            data: validPayments
        });
    } catch (error) {
        res.status(400).json({
            success: false,
            message: error.message
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
        // Un seul paiement complété et des remboursements
        reservation.status = 'confirmed';
        reservation.paymentStatus = 'paid';
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
        const { reason } = req.body;

        const payment = await Payment.findById(paymentId);
        if (!payment) {
            return res.status(404).json({
                success: false,
                message: "Paiement non trouvé"
            });
        }

        // Vérifier si le paiement peut être remboursé
        if (payment.status === 'refunded') {
            return res.status(400).json({
                success: false,
                message: "Ce paiement a déjà été remboursé"
            });
        }

        // Simuler le remboursement
        payment.status = 'refunded';
        payment.refundAmount = payment.amount;
        payment.refundReason = reason;
        await payment.save();

        // Mettre à jour le statut de la réservation
        await updateReservationStatus(payment.reservation);

        res.status(200).json({
            success: true,
            data: payment
        });
    } catch (error) {
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

// Webhook pour les événements de paiement Stripe
exports.handleStripeWebhook = async (req, res) => {
    try {
        const event = req.body;

        // Traiter différents types d'événements
        switch (event.type) {
            case 'payment_intent.succeeded':
                // Traitement du succès du paiement
                break;
            case 'payment_intent.payment_failed':
                // Traitement de l'échec du paiement
                break;
            default:
                console.log(`Événement non géré : ${event.type}`);
        }

        res.json({ received: true });
    } catch (error) {
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

// Webhook pour les événements de paiement CinetPay
exports.handleCinetPayWebhook = async (req, res) => {
    try {
        const cinetPayService = require('../../services/cinetpay.service');
        const webhookData = req.body;

        // Log de la notification CinetPay
        console.log('Webhook CinetPay reçu:', webhookData);

        // Traiter la notification via le service CinetPay
        const result = await cinetPayService.processWebhook(webhookData);

        if (result.success) {
            // Rechercher le paiement correspondant
            const payment = await Payment.findOne({ 
                transactionId: result.transactionId 
            }).populate('reservation');

            if (payment) {
                // Mettre à jour le statut du paiement
                payment.status = result.status;
                payment.providerResponse = result.webhookData;
                await payment.save();

                // Mettre à jour le statut de la réservation si paiement confirmé
                if (result.status === 'paid' && payment.reservation) { // ✅ HARMONISÉ - était 'completed'
                    payment.reservation.paymentStatus = 'paid';
                    payment.reservation.status = 'confirmed';
                    await payment.reservation.save();

                    console.log(`Paiement CinetPay confirmé pour réservation ${payment.reservation._id}`);
                    
                    // 🚀 NOUVEAU : Déclencher payout automatique
                    try {
                        const AutomaticPayoutService = require('../../services/automatic-payout.service');
                        await AutomaticPayoutService.triggerAutomaticPayout(payment, payment.reservation);
                        logger.info(`Payout automatique déclenché pour payment ${payment._id}`);
                    } catch (payoutError) {
                        logger.error('Erreur lors du déclenchement du payout automatique:', payoutError);
                        // Ne pas faire échouer le webhook pour une erreur de payout
                    }
                }
            }

            res.json({ 
                success: true, 
                message: 'Webhook traité avec succès' 
            });
        } else {
            throw new Error(result.error || 'Erreur traitement webhook');
        }

    } catch (error) {
        console.error('Erreur webhook CinetPay:', error);
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
        const rawBody = req.body; // Buffer brut depuis express.raw()
        
        // Convertir le corps brut en objet JSON APRÈS vérification de signature
        let webhookData;
        try {
            webhookData = JSON.parse(rawBody.toString('utf8'));
        } catch (parseError) {
            console.error('Erreur parsing webhook Wave:', parseError);
            return res.status(400).json({
                success: false,
                message: 'Corps de requête JSON invalide'
            });
        }

        // Log de la notification Wave
        logger.info('Webhook Wave reçu:', webhookData);

        // Vérifier la signature si configurée
        if (process.env.WAVE_SIGNING_SECRET && signature) {
            const isValid = waveService.verifySignature(rawBody, signature);
            if (!isValid) {
                logger.error('Signature Wave invalide');
                return res.status(400).json({
                    success: false,
                    message: 'Signature invalide'
                });
            }
        }

        // Traiter la notification via le service Wave
        const result = await waveService.processWebhook(webhookData);

        if (result.success) {
            // Rechercher le paiement correspondant
            const payment = await Payment.findOne({ 
                transactionId: result.transactionId 
            }).populate('reservation');

            if (payment) {
                // Mettre à jour le statut du paiement
                payment.status = result.status;
                payment.providerResponse = result.webhookData;
                await payment.save();

                // Mettre à jour la réservation si paiement réussi
                if (result.status === 'paid' && payment.reservation) {
                    payment.reservation.paymentStatus = 'paid';
                    payment.reservation.status = 'confirmed';
                    await payment.reservation.save();

                    console.log(`Paiement Wave confirmé pour la réservation ${payment.reservation._id}`);
                    
                    // 🚀 NOUVEAU : Déclencher payout automatique
                    try {
                        const AutomaticPayoutService = require('../../services/automatic-payout.service');
                        await AutomaticPayoutService.triggerAutomaticPayout(payment, payment.reservation);
                        logger.info(`Payout automatique déclenché pour payment ${payment._id}`);
                    } catch (payoutError) {
                        logger.error('Erreur lors du déclenchement du payout automatique:', payoutError);
                        // Ne pas faire échouer le webhook pour une erreur de payout
                    }
                }
            } else {
                console.warn('Aucun paiement trouvé pour la transaction Wave:', result.transactionId);
            }
        }

        res.json({ received: true });

    } catch (error) {
        console.error('Erreur webhook Wave:', error);
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};
