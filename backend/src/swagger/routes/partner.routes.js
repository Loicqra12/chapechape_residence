/**
 * @swagger
 * tags:
 *   name: Partner
 *   description: Gestion des partenaires et de leurs profils
 */

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Inscription d'un nouveau partenaire
 *     tags: [Partner]
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
 *               - phoneNumber
 *               - role
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 description: Email du partenaire
 *               password:
 *                 type: string
 *                 format: password
 *                 description: Mot de passe (min. 8 caractères)
 *               firstName:
 *                 type: string
 *                 description: Prénom
 *               lastName:
 *                 type: string
 *                 description: Nom de famille
 *               phoneNumber:
 *                 type: string
 *                 description: Numéro de téléphone
 *               role:
 *                 type: string
 *                 enum: [partner]
 *                 default: partner
 *                 description: Rôle "partner" pour inscrire un partenaire
 *     responses:
 *       201:
 *         description: Partenaire créé avec succès
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
 *                   description: JWT d'authentification
 *                 refreshToken:
 *                   type: string
 *                   description: Token de rafraîchissement
 *                 user:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: string
 *                       description: ID du partenaire
 *                     email:
 *                       type: string
 *                       description: Email du partenaire
 *                     firstName:
 *                       type: string
 *                       description: Prénom du partenaire
 *                     lastName:
 *                       type: string
 *                       description: Nom du partenaire
 *                     role:
 *                       type: string
 *                       example: "partner"
 *       400:
 *         description: Données invalides
 *       409:
 *         description: Email déjà utilisé
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/partners/profile:
 *   get:
 *     summary: Obtenir le profil du partenaire connecté
 *     tags: [Partner]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Profil du partenaire
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
 *                       description: ID du partenaire
 *                     email:
 *                       type: string
 *                       description: Email du partenaire
 *                     firstName:
 *                       type: string
 *                       description: Prénom du partenaire
 *                     lastName:
 *                       type: string
 *                       description: Nom du partenaire
 *                     phoneNumber:
 *                       type: string
 *                       description: Numéro de téléphone
 *                     role:
 *                       type: string
 *                       example: "partner"
 *                     profileImage:
 *                       type: string
 *                       description: URL de l'image de profil
 *                     documents:
 *                       type: array
 *                       description: Documents téléchargés par le partenaire
 *                       items:
 *                         type: object
 *                         properties:
 *                           type:
 *                             type: string
 *                             description: Type de document
 *                           url:
 *                             type: string
 *                             description: URL du document
 *                           verified:
 *                             type: boolean
 *                             description: Statut de vérification
 *                           uploadedAt:
 *                             type: string
 *                             format: date-time
 *                             description: Date de téléchargement
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé (réservé aux partenaires)
 *       500:
 *         description: Erreur serveur
 *   put:
 *     summary: Mettre à jour le profil du partenaire
 *     tags: [Partner]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               firstName:
 *                 type: string
 *                 description: Prénom du partenaire
 *               lastName:
 *                 type: string
 *                 description: Nom du partenaire
 *               email:
 *                 type: string
 *                 format: email
 *                 description: Email du partenaire
 *               phoneNumber:
 *                 type: string
 *                 description: Numéro de téléphone
 *               profileImage:
 *                 type: string
 *                 format: binary
 *                 description: Image de profil (fichier)
 *               profileimage:
 *                 type: string
 *                 format: binary
 *                 description: Image de profil (alternative)
 *               profile_image:
 *                 type: string
 *                 format: binary
 *                 description: Image de profil (alternative)
 *               image:
 *                 type: string
 *                 format: binary
 *                 description: Image de profil (alternative)
 *     responses:
 *       200:
 *         description: Profil mis à jour avec succès
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
 *                       description: ID du partenaire
 *                     email:
 *                       type: string
 *                       description: Email du partenaire
 *                     firstName:
 *                       type: string
 *                       description: Prénom du partenaire
 *                     lastName:
 *                       type: string
 *                       description: Nom du partenaire
 *                     phoneNumber:
 *                       type: string
 *                       description: Numéro de téléphone
 *                     profileImage:
 *                       type: string
 *                       description: URL de l'image de profil mise à jour
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé (réservé aux partenaires)
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/partners/documents:
 *   post:
 *     summary: Télécharger un document partenaire
 *     tags: [Partner]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required:
 *               - document
 *             properties:
 *               document:
 *                 type: string
 *                 format: binary
 *                 description: Document à télécharger
 *               documentType:
 *                 type: string
 *                 enum: [identity, address, bank, business, other]
 *                 default: identity
 *                 description: Type de document
 *     responses:
 *       200:
 *         description: Document téléchargé avec succès
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
 *                     document:
 *                       type: object
 *                       properties:
 *                         type:
 *                           type: string
 *                           description: Type de document
 *                         url:
 *                           type: string
 *                           description: URL du document
 *                         verified:
 *                           type: boolean
 *                           description: Statut de vérification
 *                         uploadedAt:
 *                           type: string
 *                           format: date-time
 *                           description: Date de téléchargement
 *                     url:
 *                       type: string
 *                       description: URL du document
 *       400:
 *         description: Données invalides ou aucun document fourni
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé (réservé aux partenaires)
 *       500:
 *         description: Erreur serveur
 */ 
/**
 * @swagger
 * /api/partners/dashboard/overview:
 *   get:
 *     summary: Vue d'ensemble du dashboard partenaire
 *     tags: [Partner]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Données du dashboard récupérées
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
 *                       type: number
 *                       example: 125000
 *                     activeReservations:
 *                       type: integer
 *                       example: 12
 *                     occupancyRate:
 *                       type: number
 *                       example: 85.5
 *                     totalResidences:
 *                       type: integer
 *                       example: 8
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé (réservé aux partenaires)
 */

/**
 * @swagger
 * /api/partners/dashboard/finances:
 *   get:
 *     summary: Données financières du dashboard
 *     tags: [Partner]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Données financières récupérées
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
 *                       type: number
 *                       example: 25000
 *                     pendingPayouts:
 *                       type: number
 *                       example: 15000
 *                     completedPayouts:
 *                       type: number
 *                       example: 85000
 *                     commissionRate:
 *                       type: number
 *                       example: 10
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé (réservé aux partenaires)
 */

/**
 * @swagger
 * /api/partners/dashboard/realtime:
 *   get:
 *     summary: Données temps réel du dashboard
 *     tags: [Partner]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Données temps réel récupérées
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
 *                     onlineVisitors:
 *                       type: integer
 *                       example: 24
 *                     newReservations:
 *                       type: integer
 *                       example: 3
 *                     recentMessages:
 *                       type: integer
 *                       example: 7
 *                     alerts:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           type:
 *                             type: string
 *                             example: "new_reservation"
 *                           message:
 *                             type: string
 *                             example: "Nouvelle réservation pour Villa Marina"
 *                           timestamp:
 *                             type: string
 *                             format: date-time
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé (réservé aux partenaires)
 */

/**
 * @swagger
 * /api/partners/residences:
 *   get:
 *     summary: Récupérer les résidences du partenaire
 *     tags: [Partner]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [active, inactive, pending]
 *     responses:
 *       200:
 *         description: Liste des résidences du partenaire
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
 *                         type: string
 *                       name:
 *                         type: string
 *                         example: "Villa Marina"
 *                       status:
 *                         type: string
 *                         example: "active"
 *                       reservations:
 *                         type: integer
 *                         example: 15
 *                       revenue:
 *                         type: number
 *                         example: 45000
 *                 pagination:
 *                   type: object
 *                   properties:
 *                     page:
 *                       type: integer
 *                     limit:
 *                       type: integer
 *                     total:
 *                       type: integer
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé (réservé aux partenaires)
 */

/**
 * @swagger
 * /api/partners/bookings:
 *   get:
 *     summary: Récupérer les réservations du partenaire
 *     tags: [Partner]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, confirmed, cancelled, completed]
 *     responses:
 *       200:
 *         description: Liste des réservations du partenaire
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
 *                         type: string
 *                       residence:
 *                         type: object
 *                         properties:
 *                           _id:
 *                             type: string
 *                           name:
 *                             type: string
 *                             example: "Villa Marina"
 *                       user:
 *                         type: object
 *                         properties:
 *                           _id:
 *                             type: string
 *                           firstName:
 *                             type: string
 *                           lastName:
 *                             type: string
 *                       checkIn:
 *                         type: string
 *                         format: date
 *                       checkOut:
 *                         type: string
 *                         format: date
 *                       totalPrice:
 *                         type: number
 *                       status:
 *                         type: string
 *                         example: "confirmed"
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé (réservé aux partenaires)
 */

/**
 * @swagger
 * /api/partners/stats:
 *   get:
 *     summary: Statistiques générales du partenaire
 *     tags: [Partner]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: period
 *         schema:
 *           type: string
 *           enum: [week, month, quarter, year]
 *           default: month
 *     responses:
 *       200:
 *         description: Statistiques générales
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
 *                     reservations:
 *                       type: object
 *                       properties:
 *                         total:
 *                           type: integer
 *                           example: 125
 *                         confirmed:
 *                           type: integer
 *                           example: 98
 *                         cancelled:
 *                           type: integer
 *                           example: 12
 *                     revenue:
 *                       type: object
 *                       properties:
 *                         total:
 *                           type: number
 *                           example: 350000
 *                         commission:
 *                           type: number
 *                           example: 35000
 *                         net:
 *                           type: number
 *                           example: 315000
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé (réservé aux partenaires)
 */

/**
 * @swagger
 * /api/partners/stats/residences:
 *   get:
 *     summary: Statistiques des résidences du partenaire
 *     tags: [Partner]
 *     security:
 *       - bearerAuth: []
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
 *                           name:
 *                             type: string
 *                             example: "Villa Marina"
 *                       totalReservations:
 *                         type: integer
 *                         example: 25
 *                       occupancyRate:
 *                         type: number
 *                         example: 78.5
 *                       averageRating:
 *                         type: number
 *                         example: 4.8
 *                       totalRevenue:
 *                         type: number
 *                         example: 85000
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé (réservé aux partenaires)
 */

/**
 * @swagger
 * /api/partners/stats/trends:
 *   get:
 *     summary: Tendances et analyses du partenaire
 *     tags: [Partner]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: period
 *         schema:
 *           type: string
 *           enum: [6months, year, 2years]
 *           default: year
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
 *                     monthlyRevenue:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           month:
 *                             type: string
 *                             example: "2024-01"
 *                           revenue:
 *                             type: number
 *                             example: 25000
 *                     reservationTrends:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           month:
 *                             type: string
 *                             example: "2024-01"
 *                           count:
 *                             type: integer
 *                             example: 12
 *                     seasonalAnalysis:
 *                       type: object
 *                       properties:
 *                         peakSeason:
 *                           type: string
 *                           example: "Décembre - Février"
 *                         lowSeason:
 *                           type: string
 *                           example: "Juin - Août"
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé (réservé aux partenaires)
 */

/**
 * @swagger
 * /api/partners/earnings:
 *   get:
 *     summary: Revenus détaillés du partenaire
 *     tags: [Partner]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date
 *       - in: query
 *         name: residenceId
 *         schema:
 *           type: string
 *         description: Filtrer par résidence spécifique
 *     responses:
 *       200:
 *         description: Détail des revenus
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
 *                     totalEarnings:
 *                       type: number
 *                       example: 125000
 *                     platformCommission:
 *                       type: number
 *                       example: 12500
 *                     netEarnings:
 *                       type: number
 *                       example: 112500
 *                     breakdown:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           date:
 *                             type: string
 *                             format: date
 *                           reservationId:
 *                             type: string
 *                           residenceName:
 *                             type: string
 *                           grossAmount:
 *                             type: number
 *                           commission:
 *                             type: number
 *                           netAmount:
 *                             type: number
 *                     payoutStatus:
 *                       type: object
 *                       properties:
 *                         pending:
 *                           type: number
 *                           example: 15000
 *                         paid:
 *                           type: number
 *                           example: 97500
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé (réservé aux partenaires)
 */

// Ce fichier sert uniquement à documenter les endpoints pour Swagger
// Il n'exporte rien car il est uniquement lu par swagger-jsdoc