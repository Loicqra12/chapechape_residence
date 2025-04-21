/**
 * Documentation Swagger pour les rapports système (Super Admin)
 * 
 * @swagger
 * tags:
 *   name: Super Admin - Reports
 *   description: Rapports système pour le Super Admin
 */

/**
 * @swagger
 * /api/superadmin/reports/system:
 *   get:
 *     summary: Obtenir un rapport système complet
 *     tags: [Super Admin - Reports]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Rapport système généré avec succès
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
 *                     system:
 *                       type: object
 *                       properties:
 *                         uptime:
 *                           type: number
 *                           description: Temps d'activité du serveur en secondes
 *                         nodeVersion:
 *                           type: string
 *                           description: Version de Node.js
 *                         memory:
 *                           type: object
 *                           properties:
 *                             total:
 *                               type: number
 *                               description: Mémoire totale en MB
 *                             free:
 *                               type: number
 *                               description: Mémoire libre en MB
 *                             used:
 *                               type: number
 *                               description: Mémoire utilisée en MB
 *                     database:
 *                       type: object
 *                       properties:
 *                         status:
 *                           type: string
 *                           description: Statut de la base de données
 *                         collections:
 *                           type: array
 *                           items:
 *                             type: object
 *                             properties:
 *                               name:
 *                                 type: string
 *                                 description: Nom de la collection
 *                               count:
 *                                 type: number
 *                                 description: Nombre de documents
 *                               size:
 *                                 type: number
 *                                 description: Taille en KB
 *                     usage:
 *                       type: object
 *                       properties:
 *                         totalUsers:
 *                           type: number
 *                           description: Nombre total d'utilisateurs
 *                         totalResidences:
 *                           type: number
 *                           description: Nombre total de résidences
 *                         totalBookings:
 *                           type: number
 *                           description: Nombre total de réservations
 *                         totalPayments:
 *                           type: number
 *                           description: Nombre total de paiements
 *                         activeUsers:
 *                           type: number
 *                           description: Utilisateurs actifs (30 derniers jours)
 *                     lastBackup:
 *                       type: string
 *                       format: date-time
 *                       description: Date du dernier backup
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
 *       500:
 *         description: Erreur serveur
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 */

/**
 * @swagger
 * /api/superadmin/reports/security:
 *   get:
 *     summary: Obtenir un rapport de sécurité
 *     tags: [Super Admin - Reports]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Rapport de sécurité généré avec succès
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
 *                     failedLogins:
 *                       type: object
 *                       properties:
 *                         today:
 *                           type: number
 *                           description: Tentatives échouées aujourd'hui
 *                         week:
 *                           type: number
 *                           description: Tentatives échouées cette semaine
 *                         month:
 *                           type: number
 *                           description: Tentatives échouées ce mois
 *                     suspiciousActivities:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           type:
 *                             type: string
 *                             description: Type d'activité suspecte
 *                           count:
 *                             type: number
 *                             description: Nombre d'occurrences
 *                           lastOccurrence:
 *                             type: string
 *                             format: date-time
 *                             description: Dernière occurrence
 *                     blockedIPs:
 *                       type: object
 *                       properties:
 *                         total:
 *                           type: number
 *                           description: Nombre total d'IPs bloquées
 *                         recent:
 *                           type: array
 *                           description: IPs bloquées récemment
 *                           items:
 *                             type: object
 *                             properties:
 *                               ip:
 *                                 type: string
 *                                 description: Adresse IP
 *                               reason:
 *                                 type: string
 *                                 description: Raison du blocage
 *                               blockedAt:
 *                                 type: string
 *                                 format: date-time
 *                                 description: Date du blocage
 *                     vulnerabilities:
 *                       type: array
 *                       description: Vulnérabilités potentielles détectées
 *                       items:
 *                         type: object
 *                         properties:
 *                           type:
 *                             type: string
 *                             description: Type de vulnérabilité
 *                           severity:
 *                             type: string
 *                             enum: [low, medium, high, critical]
 *                             description: Sévérité
 *                           description:
 *                             type: string
 *                             description: Description de la vulnérabilité
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
 *       500:
 *         description: Erreur serveur
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 */

/**
 * @swagger
 * /api/superadmin/reports/performance:
 *   get:
 *     summary: Obtenir un rapport de performance
 *     tags: [Super Admin - Reports]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Rapport de performance généré avec succès
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
 *                     apiPerformance:
 *                       type: object
 *                       properties:
 *                         averageResponseTime:
 *                           type: number
 *                           description: Temps de réponse moyen en ms
 *                         slowestEndpoints:
 *                           type: array
 *                           items:
 *                             type: object
 *                             properties:
 *                               endpoint:
 *                                 type: string
 *                                 description: Point d'accès API
 *                               method:
 *                                 type: string
 *                                 description: Méthode HTTP
 *                               averageTime:
 *                                 type: number
 *                                 description: Temps moyen en ms
 *                               hits:
 *                                 type: number
 *                                 description: Nombre d'appels
 *                     databasePerformance:
 *                       type: object
 *                       properties:
 *                         averageQueryTime:
 *                           type: number
 *                           description: Temps moyen des requêtes en ms
 *                         slowestQueries:
 *                           type: array
 *                           items:
 *                             type: object
 *                             properties:
 *                               collection:
 *                                 type: string
 *                                 description: Collection concernée
 *                               operation:
 *                                 type: string
 *                                 description: Type d'opération
 *                               averageTime:
 *                                 type: number
 *                                 description: Temps moyen en ms
 *                     serverLoad:
 *                       type: object
 *                       properties:
 *                         cpu:
 *                           type: number
 *                           description: Utilisation CPU en pourcentage
 *                         memory:
 *                           type: number
 *                           description: Utilisation mémoire en pourcentage
 *                         diskSpace:
 *                           type: number
 *                           description: Espace disque utilisé en pourcentage
 *                     recommendedOptimizations:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           type:
 *                             type: string
 *                             description: Type d'optimisation
 *                           description:
 *                             type: string
 *                             description: Description de l'optimisation
 *                           impact:
 *                             type: string
 *                             enum: [low, medium, high]
 *                             description: Impact potentiel
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
 *       500:
 *         description: Erreur serveur
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 */ 