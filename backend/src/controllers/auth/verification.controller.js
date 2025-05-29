const asyncHandler = require('../../middlewares/async.middleware');
const twilioService = require('../../services/twilio.service');
const User = require('../../models/user.model');
const VerificationCode = require('../../models/verification_code.model');
const apiError = require('../../utils/apiError');
const logger = require('../../utils/logger');
const { v4: uuidv4 } = require('uuid');

// @desc    Demander un code de vérification par SMS
// @route   POST /api/auth/request-verification-code
// @access  Public
exports.requestVerificationCode = asyncHandler(async (req, res) => {
  const { phoneNumber } = req.body;
  
  if (!phoneNumber) {
    throw new apiError('Numéro de téléphone requis', 400);
  }
  
  // Vérifier si un utilisateur existe déjà avec ce numéro
  const existingUser = await User.findOne({ phoneNumber });
  
  // Générer un code à 6 chiffres
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
  const codeId = uuidv4();
  
  // Sauvegarder le code dans la base de données
  await VerificationCode.create({
    code,
    phoneNumber,
    expiresAt,
    codeId
  });
  
  // Message personnalisé selon que l'utilisateur existe ou non
  let messageBody;
  if (existingUser) {
    messageBody = `ChapeChape: Votre code de vérification est ${code}. Ce code expirera dans 10 minutes.`;
  } else {
    messageBody = `ChapeChape: Bienvenue! Votre code de vérification est ${code}. Ce code expirera dans 10 minutes.`;
  }
  
  try {
    // Envoyer le SMS avec le code
    const message = await twilioService.sendSMS(phoneNumber, messageBody);
    
    logger.info(`Code de vérification envoyé à ${phoneNumber}. SID: ${message.sid}`);
    
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
    
    logger.error(`Erreur lors de l'envoi du code de vérification à ${phoneNumber}: ${error.message}`);
    throw new apiError('Erreur lors de l\'envoi du SMS. Veuillez réessayer.', 500);
  }
});

// @desc    Vérifier un code reçu par SMS
// @route   POST /api/auth/verify-code
// @access  Public
exports.verifyCode = asyncHandler(async (req, res) => {
  const { phoneNumber, code, codeId } = req.body;
  
  if (!phoneNumber || !code) {
    throw new apiError('Numéro de téléphone et code requis', 400);
  }
  
  // Trouver le code de vérification
  const query = { phoneNumber };
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
  
  res.status(200).json({
    success: true,
    message: 'Numéro de téléphone vérifié avec succès',
    data: {
      phoneNumber,
      verified: true
    }
  });
});

// @desc    Renvoyer un code de vérification
// @route   POST /api/auth/resend-verification-code
// @access  Public
exports.resendVerificationCode = asyncHandler(async (req, res) => {
  const { phoneNumber } = req.body;
  
  if (!phoneNumber) {
    throw new apiError('Numéro de téléphone requis', 400);
  }
  
  // Supprimer tout ancien code pour ce numéro
  await VerificationCode.deleteMany({ phoneNumber });
  
  // Générer un nouveau code
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
  const codeId = uuidv4();
  
  // Sauvegarder le code dans la base de données
  await VerificationCode.create({
    code,
    phoneNumber,
    expiresAt,
    codeId
  });
  
  // Envoyer le SMS avec le code
  const messageBody = `ChapeChape: Votre nouveau code de vérification est ${code}. Ce code expirera dans 10 minutes.`;
  
  try {
    const message = await twilioService.sendSMS(phoneNumber, messageBody);
    
    logger.info(`Nouveau code de vérification envoyé à ${phoneNumber}. SID: ${message.sid}`);
    
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
    
    logger.error(`Erreur lors de l'envoi du nouveau code de vérification à ${phoneNumber}: ${error.message}`);
    throw new apiError('Erreur lors de l\'envoi du SMS. Veuillez réessayer.', 500);
  }
});
