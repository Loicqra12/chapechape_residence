/**
 * Documentation Swagger pour les endpoints de tarification dynamique
 *
 * @swagger
 * tags:
 *   name: Pricing
 *   description: Système de tarification dynamique et optimisation des coûts
 */

/**
 * @swagger
 * /api/pricing/calculate:
 *   post:
 *     summary: Calculer le pricing dynamique optimisé
 *     tags: [Pricing]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - basePrice
 *             properties:
 *               basePrice:
 *                 type: number
 *                 minimum: 1000
 *                 maximum: 1000000
 *                 description: "Prix de base en XOF (1,000 - 1,000,000)"
 *                 example: 25000
 *               paymentMethod:
 *                 type: string
 *                 enum: [mtn_money, orange_money, wave, moov_money, card]
 *                 description: "Méthode de paiement préférée"
 *                 example: "mtn_money"
 *               payoutMethod:
 *                 type: string
 *                 enum: [mtn_money, orange_money, wave, moov_money, card]
 *                 description: "Méthode de payout préférée"
 *                 example: "wave"
 *     responses:
 *       200:
 *         description: Pricing calculé avec succès
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
 *                     basePrice:
 *                       type: number
 *                       example: 25000
 *                     paymentMethod:
 *                       type: string
 *                       example: "mtn_money"
 *                     payoutMethod:
 *                       type: string
 *                       example: "wave"
 *                     fees:
 *                       type: object
 *                       properties:
 *                         paymentFee:
 *                           type: number
 *                           example: 750
 *                         payoutFee:
 *                           type: number
 *                           example: 500
 *                         platformCommission:
 *                           type: number
 *                           example: 2500
 *                         totalFees:
 *                           type: number
 *                           example: 3750
 *                     amounts:
 *                       type: object
 *                       properties:
 *                         totalClientPrice:
 *                           type: number
 *                           example: 25750
 *                           description: "Montant total payé par le client"
 *                         partnerNetAmount:
 *                           type: number
 *                           example: 22000
 *                           description: "Montant net reçu par le partenaire"
 *                         chapeChapeRevenue:
 *                           type: number
 *                           example: 3750
 *                           description: "Revenus de la plateforme"
 *                     optimization:
 *                       type: object
 *                       properties:
 *                         isOptimized:
 *                           type: boolean
 *                           example: true
 *                         savingsVsExpensive:
 *                           type: number
 *                           example: 1250
 *                           description: "Économies par rapport à la méthode la plus chère"
 *                         recommendedMethod:
 *                           type: string
 *                           example: "wave"
 *                 message:
 *                   type: string
 *                   example: "Pricing calculé avec succès"
 *       400:
 *         description: Données invalides
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/pricing/payment-methods:
 *   get:
 *     summary: Obtenir toutes les méthodes de paiement ordonnées par coût
 *     tags: [Pricing]
 *     responses:
 *       200:
 *         description: Méthodes ordonnées par optimisation
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
 *                       method:
 *                         type: string
 *                         example: "wave"
 *                       name:
 *                         type: string
 *                         example: "Wave Money"
 *                       fees:
 *                         type: object
 *                         properties:
 *                           fixedFee:
 *                             type: number
 *                             example: 0
 *                           percentageFee:
 *                             type: number
 *                             example: 1.5
 *                           maxFee:
 *                             type: number
 *                             example: 1000
 *                       costRanking:
 *                         type: integer
 *                         example: 1
 *                         description: "1 = moins cher, 5 = plus cher"
 *                       isRecommended:
 *                         type: boolean
 *                         example: true
 *                       supportedCountries:
 *                         type: array
 *                         items:
 *                           type: string
 *                         example: ["CI", "SN", "BF"]
 *                 message:
 *                   type: string
 *                   example: "Méthodes de paiement ordonnées par optimisation"
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/pricing/savings-analysis:
 *   get:
 *     summary: Analyser les économies potentielles pour un prix donné
 *     tags: [Pricing]
 *     parameters:
 *       - in: query
 *         name: basePrice
 *         required: true
 *         schema:
 *           type: number
 *           minimum: 1000
 *           maximum: 1000000
 *         description: "Prix de base en XOF"
 *         example: 50000
 *     responses:
 *       200:
 *         description: Analyse d'économies calculée
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
 *                     basePrice:
 *                       type: number
 *                       example: 50000
 *                     cheapestMethod:
 *                       type: object
 *                       properties:
 *                         method:
 *                           type: string
 *                           example: "wave"
 *                         totalClientCost:
 *                           type: number
 *                           example: 50750
 *                     mostExpensiveMethod:
 *                       type: object
 *                       properties:
 *                         method:
 *                           type: string
 *                           example: "card"
 *                         totalClientCost:
 *                           type: number
 *                           example: 52500
 *                     maxSavings:
 *                       type: number
 *                       example: 1750
 *                       description: "Économies maximales possibles"
 *                     savingsPercentage:
 *                       type: number
 *                       example: 3.3
 *                       description: "Pourcentage d'économies"
 *                     detailedComparisons:
 *                       type: object
 *                       additionalProperties:
 *                         type: object
 *                         properties:
 *                           totalClientPrice:
 *                             type: number
 *                           partnerNetAmount:
 *                             type: number
 *                           chapeChapeRevenue:
 *                             type: number
 *                 message:
 *                   type: string
 *                   example: "Analyse d'économies calculée"
 *       400:
 *         description: Prix invalide
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/pricing/validate:
 *   post:
 *     summary: Valider une configuration de pricing (admin uniquement)
 *     tags: [Pricing]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - basePrice
 *               - paymentMethod
 *             properties:
 *               basePrice:
 *                 type: number
 *                 minimum: 1000
 *                 maximum: 1000000
 *                 example: 25000
 *               paymentMethod:
 *                 type: string
 *                 enum: [mtn_money, orange_money, wave, moov_money, card]
 *                 example: "mtn_money"
 *     responses:
 *       200:
 *         description: Configuration validée
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
 *                     isValid:
 *                       type: boolean
 *                       example: true
 *                     pricing:
 *                       $ref: '#/components/schemas/PricingResult'
 *                     validation:
 *                       type: object
 *                       properties:
 *                         marginCheck:
 *                           type: boolean
 *                           example: true
 *                         profitabilityCheck:
 *                           type: boolean
 *                           example: true
 *                         competitivenessCheck:
 *                           type: boolean
 *                           example: true
 *                 warnings:
 *                   type: array
 *                   items:
 *                     type: string
 *                   example: []
 *       400:
 *         description: Configuration invalide
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès réservé aux administrateurs
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/pricing/partner/{partnerId}/stats:
 *   get:
 *     summary: Obtenir les stats de pricing pour un partenaire
 *     tags: [Pricing]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: partnerId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID du partenaire (MongoDB ObjectId)
 *     responses:
 *       200:
 *         description: Statistiques de pricing récupérées
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
 *                     totalReservations:
 *                       type: integer
 *                       example: 45
 *                     totalRevenue:
 *                       type: integer
 *                       description: "Revenus totaux en XOF"
 *                       example: 1125000
 *                     totalSavings:
 *                       type: integer
 *                       description: "Économies totales générées"
 *                       example: 25000
 *                     optimizationRate:
 *                       type: integer
 *                       description: "Taux d'optimisation en pourcentage"
 *                       example: 78
 *                     methodStats:
 *                       type: object
 *                       additionalProperties:
 *                         type: object
 *                         properties:
 *                           count:
 *                             type: integer
 *                           revenue:
 *                             type: integer
 *                       example:
 *                         wave:
 *                           count: 25
 *                           revenue: 625000
 *                         mtn_money:
 *                           count: 20
 *                           revenue: 500000
 *                     avgRevenuePerReservation:
 *                       type: integer
 *                       example: 25000
 *                 message:
 *                   type: string
 *                   example: "Statistiques de pricing récupérées"
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/pricing/simulate:
 *   post:
 *     summary: Simuler l'impact d'un changement de tarification (admin uniquement)
 *     tags: [Pricing]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - currentPrices
 *             properties:
 *               currentPrices:
 *                 type: array
 *                 minItems: 1
 *                 maxItems: 10
 *                 items:
 *                   type: number
 *                   minimum: 1000
 *                 description: "Liste des prix actuels à simuler (max 10)"
 *                 example: [15000, 25000, 35000, 50000]
 *               newCommissionRate:
 *                 type: number
 *                 minimum: 0.05
 *                 maximum: 0.30
 *                 description: "Nouveau taux de commission (5% - 30%)"
 *                 example: 0.12
 *     responses:
 *       200:
 *         description: Simulation de tarification calculée
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
 *                     simulations:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           basePrice:
 *                             type: number
 *                             example: 25000
 *                           current:
 *                             type: object
 *                             properties:
 *                               clientPays:
 *                                 type: number
 *                                 example: 26250
 *                               partnerReceives:
 *                                 type: number
 *                                 example: 22500
 *                               chapeChapeRevenue:
 *                                 type: number
 *                                 example: 3750
 *                           optimized:
 *                             type: object
 *                             properties:
 *                               clientPays:
 *                                 type: number
 *                                 example: 25750
 *                               partnerReceives:
 *                                 type: number
 *                                 example: 22000
 *                               chapeChapeRevenue:
 *                                 type: number
 *                                 example: 3750
 *                           improvements:
 *                             type: object
 *                             properties:
 *                               clientSavings:
 *                                 type: number
 *                                 example: 500
 *                               chapeChapeGain:
 *                                 type: number
 *                                 example: 0
 *                               partnerImpact:
 *                                 type: number
 *                                 example: -500
 *                     summary:
 *                       type: object
 *                       properties:
 *                         totalClientSavings:
 *                           type: number
 *                           example: 2000
 *                         totalRevenueGain:
 *                           type: number
 *                           example: 500
 *                         avgOptimization:
 *                           type: number
 *                           example: 2.1
 *                           description: "Optimisation moyenne en pourcentage"
 *                 message:
 *                   type: string
 *                   example: "Simulation de tarification calculée"
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
 * components:
 *   schemas:
 *     PricingResult:
 *       type: object
 *       properties:
 *         basePrice:
 *           type: number
 *           example: 25000
 *         paymentMethod:
 *           type: string
 *           example: "wave"
 *         fees:
 *           type: object
 *           properties:
 *             paymentFee:
 *               type: number
 *               example: 375
 *             payoutFee:
 *               type: number
 *               example: 500
 *             platformCommission:
 *               type: number
 *               example: 2500
 *         amounts:
 *           type: object
 *           properties:
 *             totalClientPrice:
 *               type: number
 *               example: 25375
 *             partnerNetAmount:
 *               type: number
 *               example: 22000
 *             chapeChapeRevenue:
 *               type: number
 *               example: 3375
 *         optimization:
 *           type: object
 *           properties:
 *             isOptimized:
 *               type: boolean
 *               example: true
 *             savingsVsExpensive:
 *               type: number
 *               example: 875
 */

// Ce fichier sert uniquement à documenter les endpoints pour Swagger
// Il n'exporte rien car il est uniquement lu par swagger-jsdoc
