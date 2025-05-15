/**
 * Contrôleur d'authentification Facebook
 */
const httpStatus = require('http-status');
const catchAsync = require('../../utils/catchAsync');
const facebookAuthService = require('../../services/facebook-auth.service');
const logger = require('../../utils/logger');

/**
 * Gestion de l'authentification avec Facebook
 */
const handleFacebookAuth = catchAsync(async (req, res) => {
  try {
    const { accessToken, email, displayName, photoUrl, uid } = req.body;
    
    if (!accessToken) {
      return res.status(httpStatus.BAD_REQUEST).send({
        success: false,
        message: 'Token Facebook requis',
        status: 'fail'
      });
    }
    
    const { user, token } = await facebookAuthService.authenticateWithFacebook({
      accessToken,
      email,
      displayName,
      photoUrl,
      uid
    });
    
    // Retourner les informations de l'utilisateur avec le token JWT
    return res.status(httpStatus.OK).send({
      success: true,
      message: 'Authentification Facebook réussie',
      user,
      token
    });
  } catch (error) {
    logger.error(`Erreur d'authentification Facebook: ${error.message}`);
    
    return res.status(httpStatus.UNAUTHORIZED).send({
      success: false,
      message: `Échec de l'authentification Facebook: ${error.message}`,
      status: 'fail'
    });
  }
});

module.exports = {
  handleFacebookAuth
};
