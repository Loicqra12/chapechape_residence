const { OAuth2Client } = require('google-auth-library');
const User = require('../models/user.model');
const apiError = require('../utils/apiError');
const jwt = require('../utils/jwt');
const emailService = require('./email.service');
const logger = require('../utils/logger');

// ID client Google — doit correspondre au serverClientId passé à GoogleSignIn() côté Flutter.
// Les deux utilisent le projet Firebase chapchapresi (39884732136).
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID || '39884732136-952k7nbb1gucreafp9h33pmq4m5mnfu5.apps.googleusercontent.com';

// Créer un client OAuth2 avec configuration complète
const client = new OAuth2Client({
  clientId: GOOGLE_CLIENT_ID,
  clientSecret: process.env.GOOGLE_CLIENT_SECRET
});

/**
 * Vérifie un token ID Google et renvoie les informations de l'utilisateur
 * @param {string} idToken - Le token ID fourni par Google 
 * @returns {Object} - Les informations extraites du token
 */
const verifyGoogleToken = async (idToken) => {
  try {
    logger.debug('GOOGLE_TOKEN_VERIFY_START', {
      hasToken: Boolean(idToken),
      expectedAudienceConfigured: Boolean(GOOGLE_CLIENT_ID),
    });

    const ticket = await client.verifyIdToken({
      idToken: idToken,
      audience: GOOGLE_CLIENT_ID,
      // Forcer le rechargement des certificats si nécessaire
      maxExpiry: 86400, // 24 heures
    });

    const verifiedPayload = ticket.getPayload();

    // Validation supplémentaire
    if (!verifiedPayload || !verifiedPayload.email || !verifiedPayload.sub) {
      throw new Error('Payload du token invalide');
    }

    return {
      email: verifiedPayload.email,
      firstName: verifiedPayload.given_name || '',
      lastName: verifiedPayload.family_name || '',
      googleId: verifiedPayload.sub,
      picture: verifiedPayload.picture || ''
    };
  } catch (error) {
    logger.warn('GOOGLE_TOKEN_VERIFY_FAILED', { err: error.message });

    // Gestion spécifique de l'erreur PEM
    if (error.message && error.message.includes('No pem found')) {
      logger.info('GOOGLE_CERT_RELOAD', { reason: 'no_pem_found' });
      // Forcer un nouveau client pour recharger les certificats
      const freshClient = new OAuth2Client({
        clientId: GOOGLE_CLIENT_ID,
        clientSecret: process.env.GOOGLE_CLIENT_SECRET
      });

      try {
        const retryTicket = await freshClient.verifyIdToken({
          idToken: idToken,
          audience: GOOGLE_CLIENT_ID,
        });

        const retryPayload = retryTicket.getPayload();
        return {
          email: retryPayload.email,
          firstName: retryPayload.given_name || '',
          lastName: retryPayload.family_name || '',
          googleId: retryPayload.sub,
          picture: retryPayload.picture || ''
        };
      } catch (retryError) {
        logger.error('GOOGLE_TOKEN_RETRY_FAILED', { err: retryError.message });
        throw new apiError('Erreur de certificats Google - Veuillez réessayer', 401);
      }
    }

    throw new apiError('Token Google invalide ou expiré', 401);
  }
};

/**
 * Authentifie un utilisateur avec Google et renvoie un token JWT
 * @param {string} idToken - Le token ID fourni par Google 
 * @returns {Object} - Les informations utilisateur et tokens JWT
 */
const authenticateWithGoogle = async (idToken) => {
  try {
    // Vérifier le token Google
    const googleUserInfo = await verifyGoogleToken(idToken);

    // Chercher l'utilisateur par email ou googleId
    let user = await User.findOne({
      $or: [
        { email: googleUserInfo.email },
        { googleId: googleUserInfo.googleId }
      ]
    });

    if (!user) {
      // Créer un nouvel utilisateur s'il n'existe pas
      user = await User.create({
        email: googleUserInfo.email,
        firstName: googleUserInfo.firstName,
        lastName: googleUserInfo.lastName,
        googleId: googleUserInfo.googleId,
        profilePicture: googleUserInfo.picture,
        password: Math.random().toString(36).slice(-8) + Math.random().toString(36).slice(-8), // Mot de passe aléatoire
        role: 'client'
      });

      // Envoyer l'email de bienvenue après la création du compte via Google
      emailService.sendWelcome(user).catch(e => logger.error('GOOGLE_AUTH_WELCOME_EMAIL_FAILED', { err: e?.message }));
    } else if (!user.googleId) {
      // Si l'utilisateur existe mais n'a pas de googleId, le mettre à jour
      user.googleId = googleUserInfo.googleId;

      // Mettre à jour la photo de profil si elle n'existe pas
      if (!user.profilePicture && googleUserInfo.picture) {
        user.profilePicture = googleUserInfo.picture;
      }

      await user.save();
    }

    // Mettre à jour la dernière connexion
    user.lastLogin = Date.now();
    await user.save();

    // Générer les tokens JWT
    const accessToken = jwt.generateAccessToken(user._id, user.role);
    const refreshToken = jwt.generateRefreshToken(user._id);

    return {
      user: {
        id: user._id.toString(),
        email: user.email,
        firstName: user.firstName || '',
        lastName: user.lastName || '',
        role: user.role || 'client',
        phoneNumber: user.phoneNumber || '',
        profilePicture: user.profilePicture || ''
      },
      token: accessToken,
      refreshToken
    };
  } catch (error) {
    logger.error('GOOGLE_AUTH_FAILED', { err: error.message });
    throw new apiError('Erreur d\'authentification avec Google', 500);
  }
};

module.exports = {
  verifyGoogleToken,
  authenticateWithGoogle
};
