/**
 * Documentation Swagger pour les endpoints de vérification des partenaires
 *
 * @swagger
 * tags:
 *   name: Partner Verification
 *   description: Vérification téléphonique des partenaires via SMS/OTP
 */

/**
 * @swagger
 * /api/partners/verify-phone/request:
 *   post:
 *     summary: Demander un code de vérification SMS pour partenaire
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
 *                 description: "Numéro de téléphone à vérifier (E.164 ou format local)"
 *                 example: "+2250789123456"
 *               countryCode:
 *                 type: string
 *                 description: "Code pays ISO alpha-2 (optionnel si numéro E.164)"
 *                 example: "CI"
 *               channel:
 *                 type: string
 *                 enum: [sms, whatsapp]
 *                 default: sms
 *                 description: "Canal d'envoi du code"
 *     responses:
 *       200:
 *         description: Code de vérification envoyé avec succès
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: object
 *                   properties:
 *                     verificationId:
 *                       type: string
 *                       description: "ID de la vérification pour le suivi"
 *                       example: "VER_12345"
 *                     phoneNumber:
 *                       type: string
 *                       description: "Numéro normalisé"
 *                       example: "+2250789123456"
 *                     expiresAt:
 *                       type: string
 *                       format: date-time
 *                       description: "Date d'expiration du code"
 *                     channel:
 *                       type: string
 *                       example: "sms"
 *                     remainingAttempts:
 *                       type: integer
 *                       example: 5
 *                 message:
 *                   type: string
 *                   example: "Code de vérification envoyé par SMS"
 *       400:
 *         description: Données invalides ou numéro déjà vérifié
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: "Numéro de téléphone invalide"
 *                 error:
 *                   type: string
 *                   example: "INVALID_PHONE_NUMBER"
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès réservé aux partenaires
 *       429:
 *         description: Trop de tentatives, réessayez plus tard
 *       500:
 *         description: Erreur serveur ou service SMS
 */

/**
 * @swagger
 * /api/partners/verify-phone/confirm:
 *   post:
 *     summary: Confirmer le code de vérification SMS pour partenaire
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
 *               - verificationCode
 *             properties:
 *               phoneNumber:
 *                 type: string
 *                 description: "Numéro de téléphone à vérifier"
 *                 example: "+2250789123456"
 *               verificationCode:
 *                 type: string
 *                 description: "Code à 6 chiffres reçu par SMS"
 *                 example: "123456"
 *               verificationId:
 *                 type: string
 *                 description: "ID de vérification (optionnel)"
 *                 example: "VER_12345"
 *     responses:
 *       200:
 *         description: Numéro vérifié avec succès
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: object
 *                   properties:
 *                     phoneNumber:
 *                       type: string
 *                       example: "+2250789123456"
 *                     verifiedAt:
 *                       type: string
 *                       format: date-time
 *                     isPhoneVerified:
 *                       type: boolean
 *                       example: true
 *                     partnerId:
 *                       type: string
 *                       description: "ID du partenaire"
 *                     statusUpdate:
 *                       type: object
 *                       properties:
 *                         previousStatus:
 *                           type: string
 *                           example: "partner_pending"
 *                         newStatus:
 *                           type: string
 *                           example: "partner"
 *                         message:
 *                           type: string
 *                           example: "Statut partenaire activé avec succès"
 *                 message:
 *                   type: string
 *                   example: "Numéro de téléphone vérifié avec succès"
 *       400:
 *         description: Code invalide ou expiré
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: "Code de vérification invalide ou expiré"
 *                 error:
 *                   type: string
 *                   example: "INVALID_CODE"
 *                 remainingAttempts:
 *                   type: integer
 *                   example: 2
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès réservé aux partenaires
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/partners/verify-phone/history:
 *   get:
 *     summary: Obtenir l'historique des vérifications du partenaire
 *     tags: [Partner Verification]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: days
 *         schema:
 *           type: integer
 *           default: 30
 *           minimum: 1
 *           maximum: 90
 *         description: Nombre de jours d'historique à récupérer
 *       - in: query
 *         name: action
 *         schema:
 *           type: string
 *           enum: [partner_verification_request, partner_phone_verified, partner_sms_sent, api_request]
 *         description: Filtrer par type d'action
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 50
 *           maximum: 100
 *         description: Nombre maximum d'entrées à retourner
 *     responses:
 *       200:
 *         description: Historique récupéré avec succès
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: object
 *                   properties:
 *                     history:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           action:
 *                             type: string
 *                             example: "partner_verification_request"
 *                           endpoint:
 *                             type: string
 *                             example: "/api/partners/verify-phone/request"
 *                           method:
 *                             type: string
 *                             example: "POST"
 *                           originalInput:
 *                             type: string
 *                             example: "0789123456"
 *                           normalizedPhone:
 *                             type: string
 *                             example: "+2250789123456"
 *                           partnerId:
 *                             type: string
 *                           status:
 *                             type: string
 *                             enum: [success, failed, pending]
 *                             example: "success"
 *                           errorCode:
 *                             type: string
 *                             nullable: true
 *                           channel:
 *                             type: string
 *                             example: "sms"
 *                           ip:
 *                             type: string
 *                             example: "192.168.1.1"
 *                           userAgent:
 *                             type: string
 *                             example: "ChapeChape-Partner-App/1.0.0"
 *                           timestamp:
 *                             type: string
 *                             format: date-time
 *                     totalFound:
 *                       type: integer
 *                       example: 15
 *                     summary:
 *                       type: object
 *                       properties:
 *                         totalRequests:
 *                           type: integer
 *                           example: 12
 *                         successfulVerifications:
 *                           type: integer
 *                           example: 8
 *                         failedAttempts:
 *                           type: integer
 *                           example: 4
 *                         lastVerification:
 *                           type: string
 *                           format: date-time
 *                           nullable: true
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès réservé aux partenaires
 *       500:
 *         description: Erreur serveur ou récupération historique
 */

// Ce fichier sert uniquement à documenter les endpoints pour Swagger
// Il n'exporte rien car il est uniquement lu par swagger-jsdoc
