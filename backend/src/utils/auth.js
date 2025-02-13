const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

/**
 * Génère un token JWT pour un utilisateur
 * @param {string} userId - ID de l'utilisateur
 * @returns {string} Token JWT
 */
const generateToken = (userId) => {
    return jwt.sign(
        { id: userId },
        process.env.JWT_SECRET || 'your-secret-key',
        { expiresIn: '24h' }
    );
};

/**
 * Vérifie si un token JWT est valide
 * @param {string} token - Token JWT à vérifier
 * @returns {Object} Données décodées du token
 */
const verifyToken = (token) => {
    return jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
};

/**
 * Hash un mot de passe
 * @param {string} password - Mot de passe à hasher
 * @returns {Promise<string>} Mot de passe hashé
 */
const hashPassword = async (password) => {
    const salt = await bcrypt.genSalt(10);
    return bcrypt.hash(password, salt);
};

/**
 * Compare un mot de passe avec sa version hashée
 * @param {string} password - Mot de passe à vérifier
 * @param {string} hashedPassword - Version hashée du mot de passe
 * @returns {Promise<boolean>} True si les mots de passe correspondent
 */
const comparePassword = async (password, hashedPassword) => {
    return bcrypt.compare(password, hashedPassword);
};

module.exports = {
    generateToken,
    verifyToken,
    hashPassword,
    comparePassword
};
