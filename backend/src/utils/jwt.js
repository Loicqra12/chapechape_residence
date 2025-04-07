const jwt = require('jsonwebtoken');
const keyRotation = require('./keyRotation');
const logger = require('./logger');

/**
 * Générer un token d'accès JWT
 * @param {string} userId - ID de l'utilisateur
 * @param {string} role - Rôle de l'utilisateur
 * @returns {string} - Token JWT généré
 */
const generateAccessToken = (userId, role) => {
    // Utiliser la clé active pour la signature
    const secret = keyRotation.getActiveKey('JWT_SECRET');
    
    return jwt.sign(
        { id: userId, role },
        secret,
        { expiresIn: parseInt(process.env.JWT_EXPIRE) * 3600 } // Convert hours to seconds
    );
};

/**
 * Générer un token de rafraîchissement
 * @param {string} userId - ID de l'utilisateur
 * @returns {string} - Token de rafraîchissement
 */
const generateRefreshToken = (userId) => {
    // Utiliser la clé active pour la signature
    const secret = keyRotation.getActiveKey('JWT_REFRESH_SECRET');
    
    return jwt.sign(
        { id: userId },
        secret,
        { expiresIn: parseInt(process.env.JWT_REFRESH_EXPIRE) * 24 * 3600 } // Convert days to seconds
    );
};

/**
 * Vérifier un token JWT
 * @param {string} token - Token à vérifier
 * @param {string} keyType - Type de clé à utiliser (JWT_SECRET ou JWT_REFRESH_SECRET)
 * @returns {object} - Payload décodé du token
 */
const verifyToken = (token, keyType = 'JWT_SECRET') => {
    try {
        // Essayer d'abord avec la clé active
        const activeSecret = keyRotation.getActiveKey(keyType);
        return jwt.verify(token, activeSecret);
    } catch (error) {
        // Si le token n'est pas valide avec la clé active, essayer avec la clé précédente
        try {
            const previousSecret = keyRotation.getPreviousKey(keyType);
            if (previousSecret) {
                logger.info(`Tentative de validation du token avec la clé ${keyType} précédente`);
                return jwt.verify(token, previousSecret);
            }
        } catch (prevError) {
            // Si cela échoue aussi, le token est réellement invalide
            logger.error(`Token invalide, erreur: ${error.message}`);
        }
        
        // Relancer l'erreur originale si la validation a échoué avec les deux clés
        throw error;
    }
};

module.exports = {
    generateAccessToken,
    generateRefreshToken,
    verifyToken
};
