/**
 * Documentation Swagger pour les endpoints de paiement
 * 
 * @swagger
 * tags:
 *   name: Paiements
 *   description: Gestion des paiements et des transactions
 */

/**
 * @swagger
 * /api/payments/cinetpay/verify/{transactionId}:
 *   get:
 *     summary: Vérifier le statut d'un paiement CinetPay
 *     tags: [Paiements]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: transactionId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de transaction CinetPay
 *     responses:
 *       200:
 *         description: Statut du paiement récupéré
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 payment:
 *                   $ref: '#/components/schemas/Payment'
 *                 cinetpayData:
 *                   type: object
 *       404:
 *         description: Paiement introuvable
 *       400:
 *         description: Erreur de vérification CinetPay
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/payments/cinetpay/webhook:
 *   post:
 *     summary: Webhook CinetPay (appelé par CinetPay)
 *     tags: [Paiements]
 *     description: Endpoint appelé par CinetPay pour notifier les statuts de paiement. Ne pas appeler directement depuis un client.
 *     requestBody:
 *       content:
 *         application/x-www-form-urlencoded:
 *           schema:
 *             type: object
 *     responses:
 *       200:
 *         description: Webhook traité avec succès
 *       400:
 *         description: Erreur traitement webhook
 */

/**
 * @swagger
 * /api/payments/wave/webhook:
 *   post:
 *     summary: Webhook Wave (appelé par Wave)
 *     tags: [Paiements]
 *     description: Endpoint appelé par Wave pour notifier les statuts de paiement. Ne pas appeler directement depuis un client.
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *     responses:
 *       200:
 *         description: Webhook reçu
 *       400:
 *         description: Signature invalide ou corps invalide
 */

/**
 * @swagger
 * /api/payments/create-payment-intent:
 *   post:
 *     summary: Créer une intention de paiement
 *     tags: [Paiements]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - reservationId
 *               - paymentMethod
 *             properties:
 *               reservationId:
 *                 type: string
 *                 description: ID de la réservation à payer
 *               paymentMethod:
 *                 type: string
 *                 enum: [orange_money, mtn_money, moov_money, wave, om, momo]
 *                 description: Méthode de paiement (om=même que orange_money, momo=même que mtn_money)
 *               phoneNumber:
 *                 type: string
 *                 description: Numéro de téléphone (requis pour les méthodes de paiement mobile)
 *               firstName:
 *                 type: string
 *                 description: Prénom du payeur
 *               lastName:
 *                 type: string
 *                 description: Nom de famille du payeur
 *     responses:
 *       200:
 *         description: Intention de paiement créée
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
 *                     paymentId:
 *                       type: string
 *                       description: ID du paiement créé
 *                     clientSecret:
 *                       type: string
 *                       description: Secret client pour Stripe (pour les paiements par carte)
 *                     status:
 *                       type: string
 *                       description: Statut du paiement
 *                     transactionId:
 *                       type: string
 *                       description: ID de transaction du fournisseur de paiement
 *       400:
 *         description: Données invalides
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
 *         description: Accès interdit
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
 * /api/payments/{paymentId}/confirm:
 *   post:
 *     summary: Confirmer un paiement
 *     tags: [Paiements]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: paymentId
 *         schema:
 *           type: string
 *         required: true
 *         description: ID du paiement à confirmer
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               otp:
 *                 type: string
 *                 description: Code OTP pour les paiements mobiles
 *     responses:
 *       200:
 *         description: Paiement confirmé
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/Payment'
 *       400:
 *         description: Données invalides
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
 *       404:
 *         description: Paiement non trouvé
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
 * /api/payments/{paymentId}/refund:
 *   post:
 *     summary: Demander un remboursement
 *     tags: [Paiements]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: paymentId
 *         schema:
 *           type: string
 *         required: true
 *         description: ID du paiement à rembourser
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - reason
 *             properties:
 *               reason:
 *                 type: string
 *                 description: Raison du remboursement
 *               amount:
 *                 type: number
 *                 description: Montant à rembourser (si remboursement partiel)
 *     responses:
 *       200:
 *         description: Demande de remboursement traitée
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
 *                     refundId:
 *                       type: string
 *                       description: ID du remboursement
 *                     status:
 *                       type: string
 *                       enum: [pending, processed, failed]
 *                       description: Statut du remboursement
 *       400:
 *         description: Données invalides
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
 *         description: Accès interdit
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       404:
 *         description: Paiement non trouvé
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
 * /api/payments/my-payments:
 *   get:
 *     summary: Obtenir l'historique des paiements de l'utilisateur connecté
 *     tags: [Paiements]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, paid, failed, cancelled, refunded]
 *         description: Filtrer par statut de paiement (optionnel)
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *         description: Nombre maximum de résultats à retourner
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Numéro de page pour la pagination
 *     responses:
 *       200:
 *         description: Liste des paiements récupérée
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Payment'
 *                 pagination:
 *                   type: object
 *                   properties:
 *                     total:
 *                       type: integer
 *                       description: Nombre total de paiements
 *                     limit:
 *                       type: integer
 *                       description: Limite par page
 *                     page:
 *                       type: integer
 *                       description: Page actuelle
 *                     pages:
 *                       type: integer
 *                       description: Nombre total de pages
 *       401:
 *         description: Non autorisé
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
 * /api/payments/webhook:
 *   post:
 *     summary: Webhook pour les événements de paiement Stripe
 *     tags: [Paiements]
 *     description: Endpoint appelé par Stripe pour notifier des événements de paiement. Ne pas appeler directement.
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *     responses:
 *       200:
 *         description: Événement traité
 *       400:
 *         description: Signature invalide
 */
