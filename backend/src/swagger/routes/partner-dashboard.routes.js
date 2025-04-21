/**
 * Documentation Swagger pour les endpoints du dashboard partenaire
 * 
 * @swagger
 * tags:
 *   name: Partner Dashboard
 *   description: Gestion du tableau de bord des partenaires
 */

/**
 * @swagger
 * /api/partners/stats:
 *   get:
 *     summary: Obtenir les statistiques générales du partenaire
 *     tags: [Partner Dashboard]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Statistiques générales du partenaire
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
 *                     totalResidences:
 *                       type: integer
 *                       description: Nombre total de résidences
 *                       example: 5
 *                     activeResidences:
 *                       type: integer
 *                       description: Nombre de résidences actives
 *                       example: 4
 *                     totalBookings:
 *                       type: integer
 *                       description: Nombre total de réservations
 *                       example: 25
 *                     pendingBookings:
 *                       type: integer
 *                       description: Nombre de réservations en attente
 *                       example: 3
 *                     totalRevenue:
 *                       type: number
 *                       description: Revenus totaux
 *                       example: 1250000
 *                     occupancyRate:
 *                       type: number
 *                       description: Taux d'occupation moyen
 *                       example: 78.5
 *       401:
 *         description: Non autorisé
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       403:
 *         description: Accès refusé (réservé aux partenaires)
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
 * /api/partners/stats/trends:
 *   get:
 *     summary: Obtenir les tendances des réservations et revenus
 *     tags: [Partner Dashboard]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: period
 *         schema:
 *           type: string
 *           enum: [daily, weekly, monthly]
 *           default: monthly
 *         description: Période d'analyse
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Date de début (format YYYY-MM-DD)
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Date de fin (format YYYY-MM-DD)
 *     responses:
 *       200:
 *         description: Données de tendances
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
 *                     bookings:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           period:
 *                             type: string
 *                             example: "2023-01"
 *                           count:
 *                             type: integer
 *                             example: 12
 *                     revenue:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           period:
 *                             type: string
 *                             example: "2023-01"
 *                           amount:
 *                             type: number
 *                             example: 350000
 *       401:
 *         description: Non autorisé
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       403:
 *         description: Accès refusé (réservé aux partenaires)
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
 * /api/partners/stats/residences:
 *   get:
 *     summary: Obtenir les statistiques par résidence
 *     tags: [Partner Dashboard]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Date de début (format YYYY-MM-DD)
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Date de fin (format YYYY-MM-DD)
 *     responses:
 *       200:
 *         description: Statistiques par résidence
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
 *                       residence:
 *                         type: object
 *                         properties:
 *                           _id:
 *                             type: string
 *                             description: ID de la résidence
 *                           title:
 *                             type: string
 *                             description: Titre de la résidence
 *                           location:
 *                             type: object
 *                             description: Localisation
 *                           images:
 *                             type: array
 *                             items:
 *                               type: string
 *                       bookings:
 *                         type: integer
 *                         description: Nombre de réservations
 *                         example: 8
 *                       revenue:
 *                         type: number
 *                         description: Revenus générés
 *                         example: 450000
 *                       occupancyRate:
 *                         type: number
 *                         description: Taux d'occupation
 *                         example: 85.2
 *       401:
 *         description: Non autorisé
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       403:
 *         description: Accès refusé (réservé aux partenaires)
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
 * /api/partners/earnings:
 *   get:
 *     summary: Obtenir le détail des revenus
 *     tags: [Partner Dashboard]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Date de début (format YYYY-MM-DD)
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Date de fin (format YYYY-MM-DD)
 *     responses:
 *       200:
 *         description: Détail des revenus par mois
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
 *                       _id:
 *                         type: object
 *                         properties:
 *                           year:
 *                             type: integer
 *                             example: 2023
 *                           month:
 *                             type: integer
 *                             example: 1
 *                       totalEarnings:
 *                         type: number
 *                         description: Revenus totaux pour la période
 *                         example: 350000
 *                       count:
 *                         type: integer
 *                         description: Nombre de paiements
 *                         example: 15
 *       401:
 *         description: Non autorisé
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       403:
 *         description: Accès refusé (réservé aux partenaires)
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
 * /api/partners/dashboard/overview:
 *   get:
 *     summary: Obtenir une vue d'ensemble améliorée du tableau de bord
 *     tags: [Partner Dashboard]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Vue d'ensemble du tableau de bord
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
 *                     quickStats:
 *                       type: object
 *                       properties:
 *                         totalResidences:
 *                           type: integer
 *                           example: 5
 *                         activeResidences:
 *                           type: integer
 *                           example: 4
 *                         totalBookings:
 *                           type: integer
 *                           example: 25
 *                         totalRevenue:
 *                           type: number
 *                           example: 1250000
 *                     recentBookings:
 *                       type: array
 *                       items:
 *                         type: object
 *                         description: Réservations récentes
 *                     residencePerformance:
 *                       type: array
 *                       items:
 *                         type: object
 *                         description: Performance des résidences
 *                     revenueChart:
 *                       type: object
 *                       description: Données pour le graphique des revenus
 *       401:
 *         description: Non autorisé
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       403:
 *         description: Accès refusé (réservé aux partenaires)
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
 * /api/partners/dashboard/finances:
 *   get:
 *     summary: Obtenir les statistiques financières détaillées
 *     tags: [Partner Dashboard]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Statistiques financières détaillées
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
 *                     monthlyRevenue:
 *                       type: array
 *                       items:
 *                         type: object
 *                         description: Revenus mensuels
 *                     paymentMethods:
 *                       type: array
 *                       items:
 *                         type: object
 *                         description: Répartition par méthode de paiement
 *                     revenueSources:
 *                       type: array
 *                       items:
 *                         type: object
 *                         description: Sources de revenus
 *                     unpaidInvoices:
 *                       type: array
 *                       items:
 *                         type: object
 *                         description: Factures impayées
 *       401:
 *         description: Non autorisé
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       403:
 *         description: Accès refusé (réservé aux partenaires)
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
 * /api/partners/dashboard/realtime:
 *   get:
 *     summary: Obtenir les statistiques en temps réel du tableau de bord
 *     tags: [Partner Dashboard]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Statistiques en temps réel
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
 *                     onlineUsers:
 *                       type: integer
 *                       description: Nombre d'utilisateurs actuellement en ligne
 *                       example: 12
 *                     activeViewers:
 *                       type: array
 *                       description: Utilisateurs visualisant activement les résidences
 *                       items:
 *                         type: object
 *                     todayBookings:
 *                       type: integer
 *                       description: Réservations du jour
 *                       example: 3
 *                     liveMetrics:
 *                       type: object
 *                       description: Métriques en temps réel
 *       401:
 *         description: Non autorisé
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       403:
 *         description: Accès refusé (réservé aux partenaires)
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