const asyncHandler = require('../../middlewares/async.middleware');
const twilioService = require('../../services/twilio.service');
const User = require('../../models/user.model');
const VerificationCode = require('../../models/verification_code.model');
const apiError = require('../../utils/apiError');
const logger = require('../../utils/logger');
const { v4: uuidv4 } = require('uuid');

// @desc    Demander un code de vérification par SMS ou WhatsApp
// @route   POST /api/auth/request-verification-code
// @access  Public
exports.requestVerificationCode = asyncHandler(async (req, res) => {
  const { phoneNumber, channel = 'sms', countryCode = 'CI' } = req.body;
  
  // Normaliser le numéro de téléphone
  const { normalizePhoneToE164, isValidE164 } = require('../../utils/phone.util');
  const normalizedPhone = normalizePhoneToE164(phoneNumber, countryCode);
  
  if (!isValidE164(normalizedPhone)) {
    throw new apiError(`Numéro de téléphone invalide pour le pays ${countryCode}. Formats acceptés: +225..., 07..., 77...`, 400);
  }
  
  if (!phoneNumber) {
    throw new apiError('Numéro de téléphone requis', 400);
  }
  
  // Vérifier si un utilisateur existe déjà avec ce numéro (utiliser le numéro normalisé)
  const existingUser = await User.findOne({ phoneNumber: normalizedPhone });
  
  // Générer un code à 6 chiffres
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
  const codeId = uuidv4();
  
  // Sauvegarder le code dans la base de données (utiliser le numéro normalisé)
  await VerificationCode.create({
    code,
    phoneNumber: normalizedPhone,
    expiresAt,
    codeId
  });
  
  // Message personnalisé selon le canal et l'utilisateur
  let messageBody;
  if (channel === 'whatsapp') {
    if (existingUser) {
      messageBody = `🏠 *ChapeChape Résidence*\n\n🔐 *Code de vérification*\n\nVotre code de vérification est : *${code}*\n\n⏰ Ce code expirera dans 10 minutes.\n\n🔒 Ne partagez jamais ce code avec personne.`;
    } else {
      messageBody = `🏠 *ChapeChape Résidence*\n\n🎉 *Bienvenue !*\n\nVotre code de vérification est : *${code}*\n\n⏰ Ce code expirera dans 10 minutes.\n\n🔒 Ne partagez jamais ce code avec personne.`;
    }
  } else {
    if (existingUser) {
      messageBody = `ChapeChape: Votre code de vérification est ${code}. Ce code expirera dans 10 minutes.`;
    } else {
      messageBody = `ChapeChape: Bienvenue! Votre code de vérification est ${code}. Ce code expirera dans 10 minutes.`;
    }
  }
  
  try {
    // Vérifier si Twilio est configuré
    if (!twilioService.isConfigured) {
      logger.error('Service Twilio non configuré');
      throw new apiError('Service SMS non disponible', 500);
    }
    
    // Log des variables d'environnement Twilio (masquées pour la sécurité)
    logger.info(`Twilio Account SID: ${process.env.TWILIO_ACCOUNT_SID ? 'CONFIGURÉ' : 'MANQUANT'}`);
    logger.info(`Twilio Auth Token: ${process.env.TWILIO_AUTH_TOKEN ? 'CONFIGURÉ' : 'MANQUANT'}`);
    logger.info(`Twilio Phone Number: ${process.env.TWILIO_PHONE_NUMBER || 'MANQUANT'}`);
    
    // Envoyer le message selon le canal choisi
    let message;
    if (channel === 'whatsapp') {
      if (!twilioService.isWhatsAppConfigured) {
        throw new apiError('WhatsApp Business non configuré', 500);
      }
      message = await twilioService.sendWhatsAppMessage(normalizedPhone, messageBody);
      logger.info(`Code de vérification WhatsApp envoyé à ${normalizedPhone}. SID: ${message.sid}`);
    } else {
      message = await twilioService.sendSMS(normalizedPhone, messageBody);
      logger.info(`Code de vérification SMS envoyé à ${normalizedPhone}. SID: ${message.sid}`);
    }
    
    res.status(200).json({
      success: true,
      data: {
        codeId,
        expiresAt,
        channel: channel,
        ...(process.env.NODE_ENV === 'development' ? { devCode: code } : {})
      }
    });
  } catch (error) {
    // En cas d'erreur d'envoi de SMS, supprimer le code
    await VerificationCode.deleteOne({ codeId });
    
    logger.error(`Erreur lors de l'envoi du code de vérification à ${phoneNumber}: ${error.message}`);
    
    // En mode développement, simuler l'envoi réussi si c'est une erreur d'authentification Twilio
    if (process.env.NODE_ENV === 'development' && error.message.includes('Authentication Error')) {
      logger.warn('Mode développement: Simulation de l\'envoi de SMS réussi');
      // Recréer le code afin que la vérification fonctionne réellement en DEV
      try {
        await VerificationCode.create({
          code,
          phoneNumber: normalizedPhone,
          expiresAt,
          codeId
        });
      } catch (e) {
        logger.error(`Impossible de recréer le code de vérification en DEV: ${e.message}`);
      }
      
      res.status(200).json({
        success: true,
        data: {
          codeId,
          expiresAt,
          devCode: code
        },
        message: 'Code de vérification simulé en mode développement'
      });
      return;
    }
    
    throw new apiError('Erreur lors de l\'envoi du SMS. Veuillez réessayer.', 500);
  }
});

// @desc    Vérifier un code reçu par SMS
// @route   POST /api/auth/verify-code
// @access  Public
exports.verifyCode = asyncHandler(async (req, res) => {
  const { phoneNumber, code, codeId, countryCode = 'CI' } = req.body;
  
  if (!phoneNumber || !code) {
    throw new apiError('Numéro de téléphone et code requis', 400);
  }
  
  // Normaliser le numéro de téléphone
  const { normalizePhoneToE164, isValidE164 } = require('../../utils/phone.util');
  const normalizedPhone = normalizePhoneToE164(phoneNumber, countryCode);
  if (!isValidE164(normalizedPhone)) {
    throw new apiError(`Numéro de téléphone invalide pour le pays ${countryCode}.`, 400);
  }
  
  // Trouver le code de vérification avec le numéro normalisé
  const query = { phoneNumber: normalizedPhone };
  if (codeId) {
    query.codeId = codeId;
  }
  
  const verificationCode = await VerificationCode.findOne(query);
  
  // Vérifier si le code existe
  if (!verificationCode) {
    throw new apiError('Code de vérification invalide ou expiré', 400);
  }
  
  // Vérifier si le code est expiré
  if (verificationCode.expiresAt < new Date()) {
    await VerificationCode.deleteOne({ _id: verificationCode._id });
    throw new apiError('Code de vérification expiré', 400);
  }
  
  // Vérifier si le code correspond
  if (verificationCode.code !== code) {
    // Incrémenter le compteur de tentatives
    verificationCode.attempts += 1;
    
    // Si trop de tentatives, supprimer le code
    if (verificationCode.attempts >= 3) {
      await VerificationCode.deleteOne({ _id: verificationCode._id });
      throw new apiError('Trop de tentatives incorrectes. Veuillez demander un nouveau code.', 400);
    }
    
    await verificationCode.save();
    throw new apiError('Code de vérification incorrect', 400);
  }
  
  // Le code est valide, le marquer comme utilisé
  verificationCode.isVerified = true;
  await verificationCode.save();

  // Mettre à jour le statut de vérification du téléphone côté utilisateur
  try {
    const user = await User.findOne({ phoneNumber: normalizedPhone });
    if (user) {
      let updates = { isPhoneVerified: true };
      // Promotion automatique si l'utilisateur est en attente d'activation partenaire
      if (user.role === 'partner_pending') {
        updates.role = 'partner';
      }
      await User.updateOne({ _id: user._id }, { $set: updates });
    }
  } catch (e) {
    logger.error(`Erreur lors de la mise à jour de l'utilisateur après vérification: ${e.message}`);
  }
  
  res.status(200).json({
    success: true,
    message: 'Numéro de téléphone vérifié avec succès',
    data: {
      phoneNumber: normalizedPhone,
      verified: true
    }
  });
});

// @desc    Renvoyer un code de vérification
// @route   POST /api/auth/resend-verification-code
// @access  Public
exports.resendVerificationCode = asyncHandler(async (req, res) => {
  const { phoneNumber, countryCode = 'CI' } = req.body;
  
  if (!phoneNumber) {
    throw new apiError('Numéro de téléphone requis', 400);
  }
  
  // Normaliser le numéro
  const { normalizePhoneToE164, isValidE164 } = require('../../utils/phone.util');
  const normalizedPhone = normalizePhoneToE164(phoneNumber, countryCode);
  if (!isValidE164(normalizedPhone)) {
    throw new apiError(`Numéro de téléphone invalide pour le pays ${countryCode}.`, 400);
  }
  
  // Supprimer tout ancien code pour ce numéro
  await VerificationCode.deleteMany({ phoneNumber: normalizedPhone });
  
  // Générer un nouveau code
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
  const codeId = uuidv4();
  
  // Sauvegarder le code dans la base de données
  await VerificationCode.create({
    code,
    phoneNumber: normalizedPhone,
    expiresAt,
    codeId
  });
  
  // Envoyer le SMS avec le code
  const messageBody = `ChapeChape: Votre nouveau code de vérification est ${code}. Ce code expirera dans 10 minutes.`;
  
  try {
    const message = await twilioService.sendSMS(normalizedPhone, messageBody);
    
    logger.info(`Nouveau code de vérification envoyé à ${normalizedPhone}. SID: ${message.sid}`);
    
    res.status(200).json({
      success: true,
      data: {
        codeId,
        expiresAt
      }
    });
  } catch (error) {
    // En cas d'erreur d'envoi de SMS, supprimer le code
    await VerificationCode.deleteOne({ codeId });
    
    logger.error(`Erreur lors de l'envoi du nouveau code de vérification à ${normalizedPhone}: ${error.message}`);
    throw new apiError('Erreur lors de l\'envoi du SMS. Veuillez réessayer.', 500);
  }
});
