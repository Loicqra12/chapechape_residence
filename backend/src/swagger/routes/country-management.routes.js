/**
 * Documentation Swagger pour les endpoints de gestion des pays
 *
 * @swagger
 * tags:
 *   name: Countries
 *   description: Gestion des pays supportés et configuration internationale
 */

/**
 * @swagger
 * /api/countries:
 *   get:
 *     summary: Obtenir tous les pays supportés
 *     tags: [Countries]
 *     responses:
 *       200:
 *         description: Liste des pays supportés
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
 *                     type: object
 *                     properties:
 *                       code:
 *                         type: string
 *                         example: "CI"
 *                       name:
 *                         type: string
 *                         example: "Côte d'Ivoire"
 *                       dialCode:
 *                         type: string
 *                         example: "+225"
 *                       flag:
 *                         type: string
 *                         example: "🇨🇮"
 *                       currency:
 *                         type: string
 *                         example: "XOF"
 *                       phase:
 *                         type: string
 *                         enum: [beta, production, expansion]
 *                         example: "production"
 *                       isActive:
 *                         type: boolean
 *                         example: true
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/countries/{countryCode}:
 *   get:
 *     summary: Obtenir la configuration d'un pays
 *     tags: [Countries]
 *     parameters:
 *       - in: path
 *         name: countryCode
 *         required: true
 *         schema:
 *           type: string
 *           example: "CI"
 *         description: Code pays ISO alpha-2
 *     responses:
 *       200:
 *         description: Configuration du pays
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
 *                     code:
 *                       type: string
 *                       example: "CI"
 *                     name:
 *                       type: string
 *                       example: "Côte d'Ivoire"
 *                     dialCode:
 *                       type: string
 *                       example: "+225"
 *                     phoneNumberFormat:
 *                       type: object
 *                       properties:
 *                         pattern:
 *                           type: string
 *                           example: "^(\\+225|225|0)?[0-9]{8}$"
 *                         example:
 *                           type: string
 *                           example: "0789123456"
 *                     supportedFeatures:
 *                       type: array
 *                       items:
 *                         type: string
 *                       example: ["sms", "whatsapp", "payment", "payout"]
 *                     paymentMethods:
 *                       type: array
 *                       items:
 *                         type: string
 *                       example: ["orange_money", "mtn_money", "moov_money", "wave"]
 *       404:
 *         description: Pays non trouvé ou non supporté
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/countries/detect:
 *   post:
 *     summary: Détecter le pays depuis un numéro de téléphone
 *     tags: [Countries]
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
 *                 description: "Numéro de téléphone (format international ou local)"
 *                 example: "+2250789123456"
 *     responses:
 *       200:
 *         description: Pays détecté avec succès
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
 *                     detectedCountry:
 *                       type: object
 *                       properties:
 *                         code:
 *                           type: string
 *                           example: "CI"
 *                         name:
 *                           type: string
 *                           example: "Côte d'Ivoire"
 *                         dialCode:
 *                           type: string
 *                           example: "+225"
 *                         confidence:
 *                           type: number
 *                           example: 0.95
 *                     normalizedNumber:
 *                       type: string
 *                       example: "+2250789123456"
 *                     isValid:
 *                       type: boolean
 *                       example: true
 *       400:
 *         description: Numéro de téléphone invalide
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/countries/{countryCode}/support/{feature}:
 *   get:
 *     summary: Vérifier le support d'une fonctionnalité
 *     tags: [Countries]
 *     parameters:
 *       - in: path
 *         name: countryCode
 *         required: true
 *         schema:
 *           type: string
 *           example: "CI"
 *         description: Code pays ISO alpha-2
 *       - in: path
 *         name: feature
 *         required: true
 *         schema:
 *           type: string
 *           enum: [sms, whatsapp, payment, payout, verification]
 *           example: "sms"
 *         description: Fonctionnalité à vérifier
 *     responses:
 *       200:
 *         description: Support de la fonctionnalité vérifié
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
 *                     isSupported:
 *                       type: boolean
 *                       example: true
 *                     feature:
 *                       type: string
 *                       example: "sms"
 *                     countryCode:
 *                       type: string
 *                       example: "CI"
 *                     alternativeFeatures:
 *                       type: array
 *                       items:
 *                         type: string
 *                       example: ["whatsapp"]
 *       404:
 *         description: Pays ou fonctionnalité non trouvé
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/countries/phases/{phase}:
 *   get:
 *     summary: Obtenir les pays par phase de déploiement
 *     tags: [Countries]
 *     parameters:
 *       - in: path
 *         name: phase
 *         required: true
 *         schema:
 *           type: string
 *           enum: [beta, production, expansion]
 *           example: "production"
 *         description: Phase de déploiement
 *     responses:
 *       200:
 *         description: Pays de la phase spécifiée
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
 *                     phase:
 *                       type: string
 *                       example: "production"
 *                     countries:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           code:
 *                             type: string
 *                             example: "CI"
 *                           name:
 *                             type: string
 *                             example: "Côte d'Ivoire"
 *                           launchDate:
 *                             type: string
 *                             format: date
 *                           isActive:
 *                             type: boolean
 *                             example: true
 *                     totalCount:
 *                       type: integer
 *                       example: 3
 *       404:
 *         description: Phase non trouvée
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/countries/{countryCode}/operators:
 *   get:
 *     summary: Obtenir les opérateurs téléphoniques d'un pays
 *     tags: [Countries]
 *     parameters:
 *       - in: path
 *         name: countryCode
 *         required: true
 *         schema:
 *           type: string
 *           example: "CI"
 *         description: Code pays ISO alpha-2
 *     responses:
 *       200:
 *         description: Opérateurs du pays
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
 *                     countryCode:
 *                       type: string
 *                       example: "CI"
 *                     operators:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           name:
 *                             type: string
 *                             example: "Orange"
 *                           code:
 *                             type: string
 *                             example: "orange_money"
 *                           prefixes:
 *                             type: array
 *                             items:
 *                               type: string
 *                             example: ["07", "47", "48", "49"]
 *                           isActive:
 *                             type: boolean
 *                             example: true
 *                           supportedServices:
 *                             type: array
 *                             items:
 *                               type: string
 *                             example: ["sms", "payment", "payout"]
 *       404:
 *         description: Pays non trouvé
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/countries/{countryCode}/regulations:
 *   get:
 *     summary: Obtenir les réglementations d'un pays (authentifié)
 *     tags: [Countries]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: countryCode
 *         required: true
 *         schema:
 *           type: string
 *           example: "CI"
 *         description: Code pays ISO alpha-2
 *     responses:
 *       200:
 *         description: Réglementations du pays
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
 *                     countryCode:
 *                       type: string
 *                       example: "CI"
 *                     regulations:
 *                       type: object
 *                       properties:
 *                         kyc:
 *                           type: object
 *                           properties:
 *                             required:
 *                               type: boolean
 *                               example: true
 *                             documents:
 *                               type: array
 *                               items:
 *                                 type: string
 *                               example: ["identity", "address"]
 *                         paymentLimits:
 *                           type: object
 *                           properties:
 *                             dailyLimit:
 *                               type: number
 *                               example: 500000
 *                             monthlyLimit:
 *                               type: number
 *                               example: 2000000
 *                         taxRequirements:
 *                           type: object
 *                           properties:
 *                             vatRate:
 *                               type: number
 *                               example: 18
 *                             taxId:
 *                               type: boolean
 *                               example: true
 *       401:
 *         description: Non autorisé
 *       404:
 *         description: Pays non trouvé
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/countries/propose-expansion:
 *   post:
 *     summary: Proposer une expansion vers un nouveau pays (admin uniquement)
 *     tags: [Countries]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - countryCode
 *               - justification
 *             properties:
 *               countryCode:
 *                 type: string
 *                 example: "SN"
 *               countryName:
 *                 type: string
 *                 example: "Sénégal"
 *               justification:
 *                 type: string
 *                 example: "Forte demande utilisateur et partenaires locaux disponibles"
 *               estimatedLaunch:
 *                 type: string
 *                 format: date
 *                 example: "2024-06-01"
 *               priority:
 *                 type: string
 *                 enum: [low, medium, high, urgent]
 *                 default: medium
 *     responses:
 *       201:
 *         description: Proposition d'expansion créée
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès réservé aux administrateurs
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/countries/stats:
 *   get:
 *     summary: Statistiques globales des pays (admin uniquement)
 *     tags: [Countries]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Statistiques globales
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
 *                     totalCountries:
 *                       type: integer
 *                       example: 8
 *                     byPhase:
 *                       type: object
 *                       properties:
 *                         beta:
 *                           type: integer
 *                           example: 2
 *                         production:
 *                           type: integer
 *                           example: 4
 *                         expansion:
 *                           type: integer
 *                           example: 2
 *                     mostUsedOperators:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           name:
 *                             type: string
 *                             example: "Orange"
 *                           usage:
 *                             type: number
 *                             example: 45.2
 *                     expansionProposals:
 *                       type: integer
 *                       example: 3
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès réservé aux administrateurs
 *       500:
 *         description: Erreur serveur
 */

// Ce fichier sert uniquement à documenter les endpoints pour Swagger
// Il n'exporte rien car il est uniquement lu par swagger-jsdoc
