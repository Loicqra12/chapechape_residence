/**
 * @swagger
 * tags:
 *   name: SuperAdmin
 *   description: Interface SuperAdmin — accès exclusif aux superadmins
 */

/**
 * @swagger
 * /api/superadmin/clients:
 *   get:
 *     summary: Liste de tous les clients
 *     tags: [SuperAdmin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des clients
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux superadmins
 *
 * /api/superadmin/partners:
 *   get:
 *     summary: Liste de tous les partenaires
 *     tags: [SuperAdmin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des partenaires
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux superadmins
 *
 * /api/superadmin/admins:
 *   get:
 *     summary: Liste de tous les administrateurs
 *     tags: [SuperAdmin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des admins
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux superadmins
 *   post:
 *     summary: Créer un administrateur
 *     tags: [SuperAdmin]
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
 *               password:
 *                 type: string
 *                 format: password
 *               firstName:
 *                 type: string
 *               lastName:
 *                 type: string
 *     responses:
 *       201:
 *         description: Admin créé
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux superadmins
 *
 * /api/superadmin/admins/{id}:
 *   get:
 *     summary: Détails d'un administrateur
 *     tags: [SuperAdmin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Détails de l'admin
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux superadmins
 *       404:
 *         description: Admin non trouvé
 *   put:
 *     summary: Mettre à jour un administrateur
 *     tags: [SuperAdmin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *     responses:
 *       200:
 *         description: Admin mis à jour
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux superadmins
 *       404:
 *         description: Admin non trouvé
 *   delete:
 *     summary: Supprimer un administrateur
 *     tags: [SuperAdmin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Admin supprimé
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux superadmins
 *       404:
 *         description: Admin non trouvé
 */

/**
 * @swagger
 * /api/superadmin/settings:
 *   get:
 *     summary: Paramètres système (admin et superadmin)
 *     tags: [SuperAdmin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Paramètres système
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins et superadmins
 *   put:
 *     summary: Mettre à jour les paramètres système (admin et superadmin)
 *     tags: [SuperAdmin]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *     responses:
 *       200:
 *         description: Paramètres mis à jour
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins et superadmins
 *
 * /api/superadmin/activity-logs:
 *   get:
 *     summary: Journal d'activité global
 *     tags: [SuperAdmin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Journal d'activité
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux superadmins
 *   delete:
 *     summary: Effacer le journal d'activité
 *     tags: [SuperAdmin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Journal effacé
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux superadmins
 *
 * /api/superadmin/login-attempts:
 *   get:
 *     summary: Tentatives de connexion échouées
 *     tags: [SuperAdmin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des tentatives
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux superadmins
 *   delete:
 *     summary: Effacer les tentatives de connexion
 *     tags: [SuperAdmin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Tentatives effacées
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux superadmins
 *
 * /api/superadmin/blocked-ips:
 *   get:
 *     summary: Liste des IPs bloquées
 *     tags: [SuperAdmin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des IPs bloquées
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux superadmins
 *   post:
 *     summary: Bloquer une IP
 *     tags: [SuperAdmin]
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
 *             properties:
 *               ip:
 *                 type: string
 *                 description: Adresse IP à bloquer
 *                 example: "192.168.1.100"
 *               reason:
 *                 type: string
 *     responses:
 *       200:
 *         description: IP bloquée
 *       400:
 *         description: IP invalide
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux superadmins
 *
 * /api/superadmin/blocked-ips/{ip}:
 *   delete:
 *     summary: Débloquer une IP
 *     tags: [SuperAdmin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: ip
 *         required: true
 *         schema:
 *           type: string
 *         description: Adresse IP à débloquer
 *     responses:
 *       200:
 *         description: IP débloquée
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux superadmins
 *       404:
 *         description: IP non trouvée dans la liste
 */

// Ce fichier sert uniquement à documenter les endpoints pour Swagger
// Il n'exporte rien car il est uniquement lu par swagger-jsdoc
