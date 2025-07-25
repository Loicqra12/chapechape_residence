/**
 * Utilitaires d'authentification pour les tests
 */
const jwt = require('jsonwebtoken');

// Constantes pour les tests
const JWT_SECRET = process.env.JWT_SECRET || 'chapechaperesidencessecret';
const JWT_EXPIRATION = '24h';

/**
 * Génère un token JWT pour les tests
 * @param {string} userId - ID de l'utilisateur 
 * @param {Object} additionalClaims - Claims additionnels à inclure dans le token
 * @returns {string} Token JWT
 */
const generateToken = (userId, additionalClaims = {}) => {
  const payload = {
    sub: userId.toString(),
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + (24 * 60 * 60), // 24 heures
    ...additionalClaims
  };

  return jwt.sign(
    payload,
    JWT_SECRET
  );
};

/**
 * Décode un token JWT
 * @param {string} token - Token JWT à décoder
 * @returns {Object} Payload du token
 */
const decodeToken = (token) => {
  return jwt.verify(
    token,
    JWT_SECRET
  );
};

module.exports = {
  generateToken,
  decodeToken
};
