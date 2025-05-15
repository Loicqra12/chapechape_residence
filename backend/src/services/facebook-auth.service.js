/**
 * Service d'authentification Facebook
 */
const jwt = require('jsonwebtoken');
const axios = require('axios');
const User = require('../models/user.model');
const jwtService = require('../utils/jwt');
const logger = require('../utils/logger');

/**
 * Vérifie le token d'accès Facebook et récupère les informations de l'utilisateur
 * @param {string} accessToken - Token d'accès Facebook
 * @returns {Promise<Object>} - Les informations de l'utilisateur Facebook validées
 */
const verifyFacebookToken = async (accessToken) => {
  try {
    // Vérifier que le token est valide auprès de Facebook
    const fbResponse = await axios.get(`https://graph.facebook.com/v19.0/me?fields=id,name,email,picture&access_token=${accessToken}`);
    
    if (!fbResponse.data || !fbResponse.data.id) {
      throw new Error('Token Facebook invalide');
    }
    
    return {
      facebookId: fbResponse.data.id,
      email: fbResponse.data.email,
      name: fbResponse.data.name,
      picture: fbResponse.data.picture?.data?.url
    };
  } catch (error) {
    logger.error(`Erreur de vérification du token Facebook: ${error.message}`);
    throw new Error('Échec de la vérification du token Facebook');
  }
};

/**
 * Authentifie un utilisateur avec Facebook ou crée un nouveau compte
 * @param {Object} userData - Données de l'utilisateur Facebook
 * @returns {Promise<Object>} - Utilisateur et token d'authentification
 */
const authenticateWithFacebook = async (userData) => {
  try {
    const { accessToken, email, displayName, photoUrl, uid } = userData;
    
    // Vérifier le token Facebook et obtenir les données validées
    const facebookData = await verifyFacebookToken(accessToken);
    
    // Chercher l'utilisateur par son email ou son ID Facebook
    let user = await User.findOne({
      $or: [
        { email: email || facebookData.email },
        { facebookId: facebookData.facebookId }
      ]
    });
    
    if (!user) {
      // Créer un nouvel utilisateur s'il n'existe pas
      const names = (displayName || facebookData.name || '').split(' ');
      const firstName = names[0] || '';
      const lastName = names.length > 1 ? names.slice(1).join(' ') : '';
      
      user = await User.create({
        email: email || facebookData.email,
        firstName,
        lastName,
        facebookId: facebookData.facebookId,
        role: 'client',
        profilePicture: photoUrl || facebookData.picture,
        verified: true // Les comptes Facebook sont considérés comme vérifiés
      });
    } else {
      // Mettre à jour les informations Facebook si nécessaire
      if (!user.facebookId) {
        user.facebookId = facebookData.facebookId;
        user.verified = true;
        
        // Mettre à jour la photo de profil si l'utilisateur n'en a pas
        if (!user.profilePicture && (photoUrl || facebookData.picture)) {
          user.profilePicture = photoUrl || facebookData.picture;
        }
        
        await user.save();
      }
    }
    
    // Générer un token JWT pour l'utilisateur
    const token = jwtService.generateToken(user);
    
    return { user, token };
  } catch (error) {
    logger.error(`Erreur d'authentification Facebook: ${error.message}`);
    throw error;
  }
};

module.exports = {
  verifyFacebookToken,
  authenticateWithFacebook
};
