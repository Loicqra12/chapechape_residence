/**
 * @swagger
 * tags:
 *   name: Admin
 *   description: Gestion de l'interface d'administration
 */

/**
 * @swagger
 * /api/admin/login:
 *   post:
 *     summary: Connexion administrateur
 *     tags: [Admin]
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
 *                 example: admin@chapechape.com
 *               password:
 *                 type: string
 *                 format: password
 *                 example: Admin123!
 *     responses:
 *       200:
 *         description: Connexion réussie
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 token:
 *                   type: string
 *                   description: JWT Token
 *                 refreshToken:
 *                   type: string
 *                   description: Refresh Token
 *                 user:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: string
 *                       example: "60d21b4667d0d8992e610c80"
 *                     email:
 *                       type: string
 *                       example: "admin@chapechape.com"
 *                     firstName:
 *                       type: string
 *                       example: "Admin"
 *                     lastName:
 *                       type: string
 *                       example: "User"
 *                     role:
 *                       type: string
 *                       enum: [admin, superadmin]
 *                       example: "admin"
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Identifiants invalides
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/admin/dashboard:
 *   get:
 *     summary: Récupérer les statistiques du tableau de bord
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Statistiques du tableau de bord
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
 *                     totalUsers:
 *                       type: number
 *                       example: 125
 *                     totalResidences:
 *                       type: number
 *                       example: 50
 *                     totalReservations:
 *                       type: number
 *                       example: 150
 *                     totalRevenue:
 *                       type: number
 *                       example: 25000
 *                     totalPayments:
 *                       type: number
 *                       example: 200
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès interdit
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/admin/stats/advanced:
 *   get:
 *     summary: Récupérer les statistiques avancées
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Date de début (YYYY-MM-DD)
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Date de fin (YYYY-MM-DD)
 *     responses:
 *       200:
 *         description: Statistiques avancées
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
 *                     mostViewedResidences:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           _id:
 *                             type: string
 *                             example: "60d21b4667d0d8992e610c70"
 *                           name:
 *                             type: string
 *                             example: "Villa avec piscine"
 *                           views:
 *                             type: number
 *                             example: 250
 *                     mostBookedResidences:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           _id:
 *                             type: string
 *                             example: "60d21b4667d0d8992e610c71"
 *                           name:
 *                             type: string
 *                             example: "Appartement en centre-ville"
 *                           bookings:
 *                             type: number
 *                             example: 45
 *                     revenueStats:
 *                       type: object
 *                       properties:
 *                         totalRevenue:
 *                           type: number
 *                           example: 25000
 *                         byPeriod:
 *                           type: array
 *                           items:
 *                             type: object
 *                             properties:
 *                               period:
 *                                 type: string
 *                                 example: "2023-07"
 *                               amount:
 *                                 type: number
 *                                 example: 5000
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès interdit
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/admin/admins:
 *   post:
 *     summary: Créer un administrateur
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *               - firstName
 *               - lastName
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 example: nouvel.admin@chapechape.com
 *               password:
 *                 type: string
 *                 format: password
 *                 example: Admin123!
 *               firstName:
 *                 type: string
 *                 example: "Nouvel"
 *               lastName:
 *                 type: string
 *                 example: "Admin"
 *               phoneNumber:
 *                 type: string
 *                 example: "+33612345678"
 *     responses:
 *       201:
 *         description: Administrateur créé
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
 *                     _id:
 *                       type: string
 *                       example: "60d21b4667d0d8992e610c81"
 *                     email:
 *                       type: string
 *                       example: "nouvel.admin@chapechape.com"
 *                     firstName:
 *                       type: string
 *                       example: "Nouvel"
 *                     lastName:
 *                       type: string
 *                       example: "Admin"
 *                     role:
 *                       type: string
 *                       example: "admin"
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès interdit
 *       500:
 *         description: Erreur serveur
 */ 