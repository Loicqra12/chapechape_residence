/**
 * Documentation Swagger pour la gestion de la sécurité (Super Admin)
 * 
 * @swagger
 * tags:
 *   name: Super Admin - Security
 *   description: Gestion de la sécurité par le Super Admin
 */

/**
 * @swagger
 * /api/superadmin/activity-logs:
 *   get:
 *     summary: Consulter les journaux d'activité
 *     tags: [Super Admin - Security]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page à afficher
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *         description: Nombre d'éléments par page
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
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *         description: Type d'activité à filtrer
 *     responses:
 *       200:
 *         description: Liste des journaux d'activité
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
 *                         description: ID du journal
 *                       user:
 *                         type: string
 *                         description: ID de l'utilisateur concerné
 *                       action:
 *                         type: string
 *                         description: Action réalisée
 *                       resource:
 *                         type: string
 *                         description: Ressource concernée
 *                       resourceId:
 *                         type: string
 *                         description: ID de la ressource concernée
 *                       details:
 *                         type: object
 *                         description: Détails supplémentaires
 *                       ip:
 *                         type: string
 *                         description: Adresse IP
 *                       userAgent:
 *                         type: string
 *                         description: Agent utilisateur
 *                       createdAt:
 *                         type: string
 *                         format: date-time
 *                         description: Date de l'action
 *                 pagination:
 *                   type: object
 *                   properties:
 *                     total:
 *                       type: integer
 *                       description: Nombre total d'éléments
 *                     pages:
 *                       type: integer
 *                       description: Nombre total de pages
 *                     page:
 *                       type: integer
 *                       description: Page actuelle
 *                     limit:
 *                       type: integer
 *                       description: Nombre d'éléments par page
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
 *
 *   delete:
 *     summary: Effacer tous les journaux d'activité
 *     tags: [Super Admin - Security]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Journaux d'activité supprimés
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
 *                   example: Tous les journaux d'activité ont été supprimés
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
 * /api/superadmin/login-attempts:
 *   get:
 *     summary: Consulter les tentatives de connexion
 *     tags: [Super Admin - Security]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page à afficher
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *         description: Nombre d'éléments par page
 *     responses:
 *       200:
 *         description: Liste des tentatives de connexion
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
 *                         description: ID de la tentative
 *                       email:
 *                         type: string
 *                         description: Email utilisé
 *                       ip:
 *                         type: string
 *                         description: Adresse IP
 *                       userAgent:
 *                         type: string
 *                         description: Agent utilisateur
 *                       success:
 *                         type: boolean
 *                         description: Réussite ou échec
 *                       reason:
 *                         type: string
 *                         description: Raison de l'échec
 *                       attemptedAt:
 *                         type: string
 *                         format: date-time
 *                         description: Date de la tentative
 *                 pagination:
 *                   type: object
 *                   properties:
 *                     total:
 *                       type: integer
 *                       description: Nombre total d'éléments
 *                     pages:
 *                       type: integer
 *                       description: Nombre total de pages
 *                     page:
 *                       type: integer
 *                       description: Page actuelle
 *                     limit:
 *                       type: integer
 *                       description: Nombre d'éléments par page
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
 * 
 *   delete:
 *     summary: Effacer toutes les tentatives de connexion
 *     tags: [Super Admin - Security]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Tentatives de connexion supprimées
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
 *                   example: Toutes les tentatives de connexion ont été supprimées
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
 * /api/superadmin/blocked-ips:
 *   get:
 *     summary: Consulter les adresses IP bloquées
 *     tags: [Super Admin - Security]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des adresses IP bloquées
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
 *                         description: ID de l'entrée
 *                       ip:
 *                         type: string
 *                         description: Adresse IP bloquée
 *                       reason:
 *                         type: string
 *                         description: Raison du blocage
 *                       blockedBy:
 *                         type: string
 *                         description: ID de l'utilisateur ayant bloqué l'IP
 *                       attempts:
 *                         type: integer
 *                         description: Nombre de tentatives
 *                       lastAttempt:
 *                         type: string
 *                         format: date-time
 *                         description: Date de la dernière tentative
 *                       expiresAt:
 *                         type: string
 *                         format: date-time
 *                         description: Date d'expiration du blocage
 *                       createdAt:
 *                         type: string
 *                         format: date-time
 *                         description: Date de création du blocage
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
 * 
 *   post:
 *     summary: Bloquer une adresse IP
 *     tags: [Super Admin - Security]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - ip
 *               - reason
 *             properties:
 *               ip:
 *                 type: string
 *                 description: Adresse IP à bloquer
 *                 example: 192.168.1.1
 *               reason:
 *                 type: string
 *                 description: Raison du blocage
 *                 example: Tentatives de connexion répétées
 *               expiresAt:
 *                 type: string
 *                 format: date-time
 *                 description: Date d'expiration du blocage (optionnel)
 *     responses:
 *       201:
 *         description: Adresse IP bloquée avec succès
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
 *                       description: ID de l'entrée
 *                     ip:
 *                       type: string
 *                       description: Adresse IP bloquée
 *                     reason:
 *                       type: string
 *                       description: Raison du blocage
 *                     blockedAt:
 *                       type: string
 *                       format: date-time
 *                       description: Date du blocage
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
 *       500:
 *         description: Erreur serveur
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 */

/**
 * @swagger
 * /api/superadmin/blocked-ips/{ip}:
 *   delete:
 *     summary: Débloquer une adresse IP
 *     tags: [Super Admin - Security]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: ip
 *         schema:
 *           type: string
 *         required: true
 *         description: Adresse IP à débloquer
 *     responses:
 *       200:
 *         description: Adresse IP débloquée avec succès
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
 *                   example: {}
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
 *         description: Adresse IP non trouvée
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