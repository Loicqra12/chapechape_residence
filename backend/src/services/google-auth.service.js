const { OAuth2Client } = require('google-auth-library');
const User = require('../models/user.model');
const apiError = require('../utils/apiError');
const jwt = require('../utils/jwt');

// ID client Google
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID || '150162865149-m6q57o1f68t73o8lfiumb0671qcj55da.apps.googleusercontent.com';

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
    // 🔍 DEBUG: Inspecter le token reçu
    console.log("🟢 ID Token reçu :", idToken?.substring(0, 50) + "...");
    
    const headerBase64 = idToken.split('.')[0];
    const header = JSON.parse(Buffer.from(headerBase64, 'base64').toString());
    console.log("📋 Header JWT :", header);
    console.log("🔑 Key ID (kid) :", header.kid);
    
    // 🔍 DEBUG: Décoder le payload pour voir l'audience
    const payloadBase64 = idToken.split('.')[1];
    const payload = JSON.parse(Buffer.from(payloadBase64, 'base64').toString());
    console.log("🎯 Audience dans le token :", payload.aud);
    console.log("🎯 Client ID attendu :", GOOGLE_CLIENT_ID);
    
    // Configuration avec gestion des certificats
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
    console.error('Erreur de vérification du token Google:', error);
    
    // Gestion spécifique de l'erreur PEM
    if (error.message && error.message.includes('No pem found')) {
      console.log('Tentative de rechargement des certificats Google...');
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
        console.error('Échec de la tentative de retry:', retryError);
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
    console.error('Erreur d\'authentification Google:', error);
    throw new apiError('Erreur d\'authentification avec Google', 500);
  }
};

module.exports = {
  verifyGoogleToken,
  authenticateWithGoogle
};
