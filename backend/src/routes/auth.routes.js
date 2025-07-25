const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth/auth.controller');
const googleAuthController = require('../controllers/auth/google-auth.controller');
const facebookAuthController = require('../controllers/auth/facebook-auth.controller');
const validate = require('../middlewares/validate.middleware');
const authValidation = require('../validations/auth.validation');
const {
    register,
    login,
    logout,
    getMe,
    forgotPassword,
    resetPassword,
    refreshToken
} = require('../controllers/auth/auth.controller');
const { protect, authorize, validateRefreshToken } = require('../middlewares/auth.middleware');

const {
    requestVerificationCode,
    verifyCode,
    resendVerificationCode
} = require('../controllers/auth/verification.controller');

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Register a new user
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - firstName
 *               - lastName
 *               - email
 *               - password
 *               - phoneNumber
 *             properties:
 *               firstName:
 *                 type: string
 *                 description: User's first name
 *               lastName:
 *                 type: string
 *                 description: User's last name
 *               email:
 *                 type: string
 *                 format: email
 *                 description: User's email address
 *               password:
 *                 type: string
 *                 format: password
 *                 description: User's password (min 6 characters)
 *               phoneNumber:
 *                 type: string
 *                 description: User's phone number
 *     responses:
 *       201:
 *         description: User registered successfully
 *       400:
 *         description: Invalid input or email already exists
 */
router.post('/register', validate(authValidation.register), register);

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: Login user
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *               password:
 *                 type: string
 *                 format: password
 *     responses:
 *       200:
 *         description: Login successful
 *       401:
 *         description: Invalid credentials
 */
router.post('/login', validate(authValidation.login), login);

/**
 * @swagger
 * /api/auth/logout:
 *   post:
 *     summary: Logout user
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Logged out successfully
 *       401:
 *         description: Not authorized
 */
router.post('/logout', protect, logout);

/**
 * @swagger
 * /api/auth/forgot-password:
 *   post:
 *     summary: Request password reset
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *     responses:
 *       200:
 *         description: Reset email sent
 *       404:
 *         description: User not found
 */
router.post('/forgot-password', validate(authValidation.forgotPassword), forgotPassword);

/**
 * @swagger
 * /api/auth/reset-password/{resetToken}:
 *   put:
 *     summary: Reset password with token
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - password
 *             properties:
 *               password:
 *                 type: string
 *                 format: password
 *     responses:
 *       200:
 *         description: Password reset successful
 *       400:
 *         description: Invalid or expired token
 */
router.put('/reset-password/:resetToken', validate(authValidation.resetPassword), resetPassword);

/**
 * @swagger
 * /api/auth/refresh-token:
 *   post:
 *     summary: Refresh access token
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - refreshToken
 *             properties:
 *               refreshToken:
 *                 type: string
 *                 description: Refresh token received during login
 *     responses:
 *       200:
 *         description: New access token generated successfully
 *       400:
 *         description: No refresh token provided
 *       401:
 *         description: Invalid or expired refresh token
 */
router.post('/refresh-token', validateRefreshToken, refreshToken);

// Routes protégées
router.get('/me', protect, getMe);

/**
 * @swagger
 * /api/auth/google:
 *   post:
 *     summary: Authentification avec Google
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - idToken
 *             properties:
 *               idToken:
 *                 type: string
 *                 description: Token ID fourni par Google
 *               email:
 *                 type: string
 *                 description: Email de l'utilisateur
 *               displayName:
 *                 type: string
 *                 description: Nom complet
 *               photoUrl:
 *                 type: string
 *                 description: URL de la photo de profil
 *               uid:
 *                 type: string
 *                 description: ID unique Google
 *     responses:
 *       200:
 *         description: Authentification réussie
 *       400:
 *         description: Token manquant ou invalide
 *       401:
 *         description: Authentification échouée
 */
router.post('/google', validate(authValidation.googleAuth), googleAuthController.googleAuth);

/**
 * @swagger
 * /api/auth/facebook:
 *   post:
 *     summary: Authentification avec Facebook
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - accessToken
 *             properties:
 *               accessToken:
 *                 type: string
 *                 description: Token d'accès fourni par Facebook
 *               email:
 *                 type: string
 *                 description: Email de l'utilisateur
 *               displayName:
 *                 type: string
 *                 description: Nom complet
 *               photoUrl:
 *                 type: string
 *                 description: URL de la photo de profil
 *               uid:
 *                 type: string
 *                 description: ID unique Facebook
 *     responses:
 *       200:
 *         description: Authentification réussie
 *       400:
 *         description: Token manquant ou invalide
 *       401:
 *         description: Authentification échouée
 */
router.post('/facebook', validate(authValidation.facebookAuth), facebookAuthController.handleFacebookAuth);

// Vérification de numéro de téléphone par SMS
router.post('/request-verification-code', validate(authValidation.requestVerificationCode), requestVerificationCode);
router.post('/verify-code', validate(authValidation.verifyCode), verifyCode);
router.post('/resend-verification-code', validate(authValidation.resendVerificationCode), resendVerificationCode);

module.exports = router;
