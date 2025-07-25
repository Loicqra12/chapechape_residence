/**
 * @swagger
 * tags:
 *   name: SMS
 *   description: Services d'envoi de SMS et notifications mobiles
 */

/**
 * @swagger
 * /api/sms/send:
 *   post:
 *     summary: Envoyer un SMS personnalisé
 *     tags: [SMS]
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
 *               - message
 *             properties:
 *               phoneNumber:
 *                 type: string
 *                 description: Numéro de téléphone du destinataire (format international)
 *                 example: "+33612345678"
 *               message:
 *                 type: string
 *                 description: Contenu du message SMS
 *                 maxLength: 160
 *               priority:
 *                 type: string
 *                 enum: [low, normal, high]
 *                 default: normal
 *                 description: Priorité du message
 *               scheduledAt:
 *                 type: string
 *                 format: date-time
 *                 description: Date et heure programmée pour l'envoi (optionnel)
 *     responses:
 *       200:
 *         description: SMS envoyé avec succès
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: "SMS envoyé avec succès"
 *                 data:
 *                   type: object
 *                   properties:
 *                     messageId:
 *                       type: string
 *                       description: ID unique du message envoyé
 *                     status:
 *                       type: string
 *                       enum: [sent, pending, failed]
 *                       description: Statut de l'envoi
 *                     cost:
 *                       type: number
 *                       description: Coût du SMS en crédits
 *       400:
 *         description: Données invalides (numéro incorrect, message trop long)
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       401:
 *         description: Non autorisé
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       403:
 *         description: Accès refusé (réservé aux admins et partenaires)
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       429:
 *         description: Limite de taux dépassée
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       500:
 *         description: Erreur serveur ou échec d'envoi SMS
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 */

/**
 * @swagger
 * /api/sms/booking:
 *   post:
 *     summary: Envoyer une notification SMS liée à une réservation
 *     tags: [SMS]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - bookingId
 *               - notificationType
 *             properties:
 *               bookingId:
 *                 type: string
 *                 description: ID de la réservation concernée
 *               notificationType:
 *                 type: string
 *                 enum: [confirmation, reminder, cancellation, modification, check-in, check-out]
 *                 description: Type de notification de réservation
 *               customMessage:
 *                 type: string
 *                 description: Message personnalisé (optionnel)
 *               language:
 *                 type: string
 *                 enum: [fr, en, es]
 *                 default: fr
 *                 description: Langue du message
 *     responses:
 *       200:
 *         description: Notification SMS de réservation envoyée
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: "Notification de réservation envoyée"
 *                 data:
 *                   type: object
 *                   properties:
 *                     messageId:
 *                       type: string
 *                       description: ID du message envoyé
 *                     recipient:
 *                       type: string
 *                       description: Numéro du destinataire
 *                     bookingReference:
 *                       type: string
 *                       description: Référence de la réservation
 *       400:
 *         description: Données invalides ou réservation non trouvée
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       401:
 *         description: Non autorisé
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       403:
 *         description: Accès refusé (réservé aux admins et partenaires)
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       404:
 *         description: Réservation non trouvée
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       500:
 *         description: Erreur serveur
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 */

/**
 * @swagger
 * /api/sms/payment-instructions:
 *   post:
 *     summary: Envoyer des instructions de paiement par SMS (spécifique Afrique)
 *     tags: [SMS]
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
 *               - paymentMethod
 *               - amount
 *             properties:
 *               phoneNumber:
 *                 type: string
 *                 description: Numéro de téléphone du client
 *                 example: "+225012345678"
 *               paymentMethod:
 *                 type: string
 *                 enum: [orange-money, mtn-money, moov-money, wave, mobile-money]
 *                 description: Méthode de paiement mobile
 *               amount:
 *                 type: number
 *                 description: Montant à payer
 *               currency:
 *                 type: string
 *                 enum: [XOF, XAF, USD, EUR]
 *                 default: XOF
 *                 description: Devise du paiement
 *               bookingReference:
 *                 type: string
 *                 description: Référence de la réservation
 *               merchantCode:
 *                 type: string
 *                 description: Code marchand pour le paiement
 *               language:
 *                 type: string
 *                 enum: [fr, en]
 *                 default: fr
 *                 description: Langue des instructions
 *     responses:
 *       200:
 *         description: Instructions de paiement envoyées
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: "Instructions de paiement envoyées"
 *                 data:
 *                   type: object
 *                   properties:
 *                     messageId:
 *                       type: string
 *                       description: ID du message envoyé
 *                     paymentCode:
 *                       type: string
 *                       description: Code de paiement généré
 *                     expiresAt:
 *                       type: string
 *                       format: date-time
 *                       description: Date d'expiration du code
 *                     instructions:
 *                       type: string
 *                       description: Instructions complètes envoyées
 *       400:
 *         description: Données invalides ou méthode de paiement non supportée
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       401:
 *         description: Non autorisé
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       403:
 *         description: Accès refusé (réservé aux admins et partenaires)
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       500:
 *         description: Erreur serveur ou échec d'envoi
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 */

// Ce fichier sert uniquement à documenter les endpoints pour Swagger
// Il n'exporte rien car il est uniquement lu par swagger-jsdoc
