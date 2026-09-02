const asyncHandler = require('../../middlewares/async.middleware');
const twilioService = require('../../services/twilio.service');
const User = require('../../models/user.model');
const apiError = require('../../utils/apiError');
const phoneLogger = require('../../utils/phoneLogger');
const notificationService = require('../../services/notification.service');

// Stockage temporaire des codes de vérification partners (Redis recommandé en production)
const partnerVerificationCodes = new Map();

// @desc    Demander un code de vérification SMS ou WhatsApp pour partner
// @route   POST /api/partners/verify-phone/request
// @access  Private (Partner uniquement)
exports.requestPartnerPhoneVerification = asyncHandler(async (req, res) => {
    const { phoneNumber, reason = 'profile_update', channel = 'sms' } = req.body;
    const partnerId = req.user.id;
    
    // Validation du rôle
    if (req.user.role !== 'partner') {
        throw new apiError('Accès réservé aux partenaires', 403);
    }

    // Normalisation E.164
    const normalizedPhone = normalizePhoneToE164(phoneNumber);
    
    // Log de la demande
    phoneLogger.log({
        originalInput: phoneNumber,
        normalizedOutput: normalizedPhone,
        action: 'partner_verification_request',
        reason: reason,
        partnerId: partnerId,
        timestamp: new Date()
    });

    // Vérifier les limites (3 tentatives par jour)
    const today = new Date().toDateString();
    const attemptKey = `${partnerId}_${today}`;
    const attempts = partnerVerificationCodes.get(attemptKey) || { count: 0, codes: [] };
    
    if (attempts.count >= 3) {
        throw new apiError('Limite de 3 tentatives par jour atteinte', 429);
    }

    // Vérifier que le numéro n'est pas déjà utilisé par un autre partner
    const existingPartner = await User.findOne({ 
        phoneNumber: normalizedPhone, 
        role: 'partner',
        _id: { $ne: partnerId }
    });
    
    if (existingPartner) {
        throw new apiError('Ce numéro est déjà utilisé par un autre partenaire', 409);
    }

    // Générer un code à 6 chiffres (plus sécurisé pour partners)
    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Message personnalisé selon le canal
    let messageBody;
    if (channel === 'whatsapp') {
        messageBody = `🏠 *ChapeChape Partner*\n\n🔐 *Code de vérification*\n\nVotre code de vérification est : *${verificationCode}*\n\n💼 Ce code est requis pour sécuriser votre compte business et vos commissions.\n\n⏰ Valide 5 minutes.\n\n🔒 Ne partagez jamais ce code avec personne.`;
    } else {
        messageBody = `ChapeChape Partner - Code de vérification: ${verificationCode}\n\nCe code est requis pour sécuriser votre compte business et vos commissions.\n\nValide 5 minutes.`;
    }

    try {
        // Envoyer le message selon le canal choisi
        if (channel === 'whatsapp') {
            if (!twilioService.isWhatsAppConfigured) {
                throw new apiError('WhatsApp Business non configuré', 500);
            }
            await twilioService.sendWhatsAppMessage(normalizedPhone, messageBody);
        } else {
            await twilioService.sendSMS(normalizedPhone, messageBody);
        }
        
        // Stocker le code avec expiration réduite (5 min)
        const codeData = {
            code: verificationCode,
            phoneNumber: normalizedPhone,
            partnerId: partnerId,
            reason: reason,
            expiresAt: new Date(Date.now() + 5 * 60 * 1000), // 5 minutes
            attempts: 0
        };
        
        partnerVerificationCodes.set(`${partnerId}_current`, codeData);
        
        // Mettre à jour les tentatives quotidiennes
        attempts.count += 1;
        attempts.codes.push({
            time: new Date(),
            phone: normalizedPhone,
            reason: reason
        });
        partnerVerificationCodes.set(attemptKey, attempts);
        
        // Log succès
        phoneLogger.log({
            action: 'partner_sms_sent',
            phoneNumber: normalizedPhone,
            partnerId: partnerId,
            reason: reason,
            timestamp: new Date()
        });

        // Envoyer notification de vérification envoyée
        try {
            await notificationService.notifyVerificationSent(
                partnerId,
                normalizedPhone,
                channel
            );
        } catch (notificationError) {
            console.error('Erreur notification vérification envoyée:', notificationError);
        }

        res.status(200).json({
            success: true,
            message: `Code de vérification envoyé par ${channel.toUpperCase()}`,
            expiresIn: 300, // 5 minutes en secondes
            attemptsRemaining: 3 - attempts.count,
            channel: channel
        });

    } catch (error) {
        // Log erreur
        phoneLogger.log({
            action: 'partner_sms_failed',
            phoneNumber: normalizedPhone,
            partnerId: partnerId,
            error: error.message,
            timestamp: new Date()
        });
        
        throw new apiError('Erreur lors de l\'envoi du SMS', 500);
    }
});

// @desc    Vérifier le code SMS pour partner
// @route   POST /api/partners/verify-phone/confirm
// @access  Private (Partner uniquement)
exports.confirmPartnerPhoneVerification = asyncHandler(async (req, res) => {
    const { code, setupPayouts = false } = req.body;
    const partnerId = req.user.id;
    
    // Récupérer les données de vérification
    const verificationData = partnerVerificationCodes.get(`${partnerId}_current`);
    
    if (!verificationData) {
        throw new apiError('Aucune vérification en cours', 400);
    }
    
    // Vérifier l'expiration
    if (new Date() > verificationData.expiresAt) {
        partnerVerificationCodes.delete(`${partnerId}_current`);
        throw new apiError('Code expiré', 400);
    }
    
    // Vérifier les tentatives
    if (verificationData.attempts >= 3) {
        partnerVerificationCodes.delete(`${partnerId}_current`);
        throw new apiError('Trop de tentatives incorrectes', 400);
    }
    
    // Vérifier le code
    if (verificationData.code !== code) {
        verificationData.attempts += 1;
        partnerVerificationCodes.set(`${partnerId}_current`, verificationData);
        
        throw new apiError(`Code incorrect (${verificationData.attempts}/3)`, 400);
    }
    
    try {
        // Mettre à jour le partner avec le numéro vérifié
        const partner = await User.findByIdAndUpdate(
            partnerId,
            {
                phoneNumber: verificationData.phoneNumber,
                isPhoneVerified: true,
                phoneVerifiedAt: new Date()
            },
            { new: true, runValidators: true }
        ).select('-password');
        
        // Nettoyer le code utilisé
        partnerVerificationCodes.delete(`${partnerId}_current`);
        
        // Configuration automatique des canaux de paiement si demandé
        let payoutChannels = [];
        if (setupPayouts) {
            payoutChannels = await setupPartnerPayoutChannels(partner);
        }
        
        // Log succès
        phoneLogger.log({
            action: 'partner_phone_verified',
            phoneNumber: verificationData.phoneNumber,
            partnerId: partnerId,
            reason: verificationData.reason,
            payoutChannelsSetup: payoutChannels,
            timestamp: new Date()
        });

        // Envoyer notification de vérification réussie
        try {
            await notificationService.notifyVerificationSuccess(
                partnerId,
                verificationData.phoneNumber
            );
        } catch (notificationError) {
            console.error('Erreur notification vérification réussie:', notificationError);
        }

        const { publicAuthView } = require('../../security/partner-capabilities');
        res.status(200).json({
            success: true,
            message: 'Numéro vérifié avec succès',
            partner: {
                id: partner._id,
                phoneNumber: partner.phoneNumber,
                isPhoneVerified: partner.isPhoneVerified,
                phoneVerifiedAt: partner.phoneVerifiedAt
            },
            ...publicAuthView(partner),
            payoutChannels: payoutChannels
        });

    } catch (error) {
        phoneLogger.log({
            action: 'partner_verification_failed',
            partnerId: partnerId,
            error: error.message,
            timestamp: new Date()
        });
        
        throw new apiError('Erreur lors de la vérification', 500);
    }
});

// Fonction utilitaire pour normaliser les numéros de téléphone
const normalizePhoneToE164 = (phoneNumber) => {
    if (!phoneNumber) return phoneNumber;
    
    // Si déjà en format E.164, retourner tel quel
    if (phoneNumber.startsWith('+')) {
        return phoneNumber;
    }
    
    // Nettoyer le numéro
    const clean = phoneNumber.replace(/\D/g, '');
    
    // Détection automatique du pays basée sur la longueur et préfixes
    if (clean.length === 10 && clean.startsWith('0')) {
        // Format local ivoirien
        return `+225${clean.substring(1)}`;
    } else if (clean.length === 8) {
        // Côte d'Ivoire sans le 0
        return `+225${clean}`;
    } else if (clean.length === 9 && clean.startsWith('7')) {
        // Sénégal
        return `+221${clean}`;
    } else if (clean.length === 11 && clean.startsWith('225')) {
        // Déjà avec code pays ivoirien
        return `+${clean}`;
    } else if (clean.length === 11 && clean.startsWith('221')) {
        // Déjà avec code pays sénégalais
        return `+${clean}`;
    }
    
    // Par défaut, ajouter le code pays de la Côte d'Ivoire
    return `+225${clean}`;
};

// Fonction pour configurer automatiquement les canaux de paiement
const setupPartnerPayoutChannels = async (partner) => {
    const phoneNumber = partner.phoneNumber;
    const supportedChannels = [];
    
    // Détection automatique des canaux supportés
    if (phoneNumber.includes('+225')) {
        // Côte d'Ivoire
        if (phoneNumber.includes('07') || phoneNumber.includes('05')) {
            supportedChannels.push('orange_money');
        }
        if (phoneNumber.includes('05') || phoneNumber.includes('01')) {
            supportedChannels.push('mtn_money');
        }
        if (phoneNumber.includes('01') || phoneNumber.includes('02')) {
            supportedChannels.push('moov_money');
        }
        // Wave supporte plusieurs opérateurs
        supportedChannels.push('wave');
    } else if (phoneNumber.includes('+221')) {
        // Sénégal
        supportedChannels.push('wave');
        if (phoneNumber.includes('77') || phoneNumber.includes('78')) {
            supportedChannels.push('orange_money');
        }
    }
    
    // Mettre à jour les préférences de payout du partner
    if (supportedChannels.length > 0) {
        await User.findByIdAndUpdate(partner._id, {
            'payoutPreferences.supportedChannels': supportedChannels,
            'payoutPreferences.preferredChannel': supportedChannels[0],
            'payoutPreferences.phoneNumber': phoneNumber,
            'payoutPreferences.setupAt': new Date()
        });
    }
    
    return supportedChannels;
};

module.exports = {
    requestPartnerPhoneVerification: exports.requestPartnerPhoneVerification,
    confirmPartnerPhoneVerification: exports.confirmPartnerPhoneVerification
};
