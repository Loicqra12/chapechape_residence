const { OAuth2Client } = require('google-auth-library');
const User = require('../models/user.model');
const apiError = require('../utils/apiError');
const jwt = require('../utils/jwt');

// ID client Google
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID || '150162865149-m6q57o1f68t73o8lfiumb0671qcj55da.apps.googleusercontent.com';

// Créer un client OAuth2 avec l'ID client Google
const client = new OAuth2Client(GOOGLE_CLIENT_ID);

/**
 * Vérifie un token ID Google et renvoie les informations de l'utilisateur
 * @param {string} idToken - Le token ID fourni par Google 
 * @returns {Object} - Les informations extraites du token
 */
const verifyGoogleToken = async (idToken) => {
  try {
    const ticket = await client.verifyIdToken({
      idToken,
      audience: GOOGLE_CLIENT_ID,
    });
    
    const payload = ticket.getPayload();
    
    return {
      email: payload.email,
      firstName: payload.given_name,
      lastName: payload.family_name,
      googleId: payload.sub,
      picture: payload.picture
    };
  } catch (error) {
    console.error('Erreur de vérification du token Google:', error);
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
