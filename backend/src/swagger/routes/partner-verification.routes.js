/**
 * Documentation Swagger pour les endpoints de vérification téléphonique partenaire
 *
 * @swagger
 * tags:
 *   name: Partner Verification
 *   description: Vérification du numéro de téléphone des partenaires par SMS
 */

/**
 * @swagger
 * /api/partners/verify-phone/request:
 *   post:
 *     summary: Demander un code de vérification SMS (partenaire uniquement)
 *     tags: [Partner Verification]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - phoneNumber
 *             properties:
 *               phoneNumber:
 *                 type: string
 *                 description: "Numéro de téléphone à vérifier (E.164 ou format local CI)"
 *                 example: "+2250700000000"
 *     responses:
 *       200:
 *         description: Code SMS envoyé avec succès
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *                 data:
 *                   type: object
 *                   properties:
 *                     codeId:
 *                       type: string
 *                     expiresAt:
 *                       type: string
 *                       format: date-time
 *       400:
 *         description: Numéro invalide
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux partenaires
 *       429:
 *         description: Trop de demandes (rate limit OTP)
 *
 * /api/partners/verify-phone/confirm:
 *   post:
 *     summary: Confirmer le code de vérification SMS (partenaire uniquement)
 *     tags: [Partner Verification]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - phoneNumber
 *               - code
 *             properties:
 *               phoneNumber:
 *                 type: string
 *                 description: Numéro de téléphone à vérifier
 *               code:
 *                 type: string
 *                 description: Code à 6 chiffres reçu par SMS
 *                 example: "123456"
 *               codeId:
 *                 type: string
 *                 description: ID du code (optionnel, renvoyé par /request)
 *     responses:
 *       200:
 *         description: Numéro vérifié avec succès — isPhoneVerified passe à true
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *                 data:
 *                   type: object
 *                   properties:
 *                     isPhoneVerified:
 *                       type: boolean
 *                       example: true
 *       400:
 *         description: Code invalide ou expiré
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux partenaires
 *
 * /api/partners/verify-phone/history:
 *   get:
 *     summary: Historique des vérifications du partenaire
 *     tags: [Partner Verification]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: days
 *         schema:
 *           type: integer
 *           default: 30
 *         description: Nombre de jours d'historique (défaut 30)
 *     responses:
 *       200:
 *         description: Historique des vérifications
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     history:
 *                       type: array
 *                       items:
 *                         type: object
 *                     totalFound:
 *                       type: integer
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux partenaires
 */

// Ce fichier sert uniquement à documenter les endpoints pour Swagger
// Il n'exporte rien car il est uniquement lu par swagger-jsdoc
