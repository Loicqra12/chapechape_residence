const asyncHandler = require('../../middlewares/async.middleware');
const apiError = require('../../utils/apiError');
const googleAuthService = require('../../services/google-auth.service');

/**
 * @desc    Authentification avec Google
 * @route   POST /api/auth/google
 * @access  Public
 */
exports.googleAuth = asyncHandler(async (req, res) => {
  try {
    const { idToken } = req.body;
    
    if (!idToken) {
      throw new apiError('Token ID Google non fourni', 400);
    }
    
    // Utiliser le service pour authentifier avec Google
    const authResult = await googleAuthService.authenticateWithGoogle(idToken);
    
    res.status(200).json({
      success: true,
      token: authResult.token,
      refreshToken: authResult.refreshToken,
      user: authResult.user
    });
  } catch (error) {
    console.error('Erreur Google Auth:', error);
    throw new apiError(error.message || 'Erreur lors de l\'authentification Google', error.statusCode || 500);
  }
});
