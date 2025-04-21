/**
 * @swagger
 * tags:
 *   name: Roles & Permissions
 *   description: Gestion des rôles et des permissions (Super Admin uniquement)
 */

/**
 * @swagger
 * /api/roles:
 *   get:
 *     summary: Récupérer tous les rôles
 *     tags: [Roles & Permissions]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des rôles
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
 *                         example: "60d21b4667d0d8992e610c70"
 *                       name:
 *                         type: string
 *                         example: "admin"
 *                       description:
 *                         type: string
 *                         example: "Administrateur du système"
 *                       permissions:
 *                         type: array
 *                         items:
 *                           type: string
 *                           example: "60d21b4667d0d8992e610c71"
 *                       createdAt:
 *                         type: string
 *                         format: date-time
 *                       updatedAt:
 *                         type: string
 *                         format: date-time
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé (réservé aux super admins)
 *       500:
 *         description: Erreur serveur
 * 
 *   post:
 *     summary: Créer un nouveau rôle
 *     tags: [Roles & Permissions]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - description
 *             properties:
 *               name:
 *                 type: string
 *                 example: "editor"
 *               description:
 *                 type: string
 *                 example: "Éditeur de contenu"
 *               permissions:
 *                 type: array
 *                 items:
 *                   type: string
 *                 example: ["60d21b4667d0d8992e610c71", "60d21b4667d0d8992e610c72"]
 *     responses:
 *       201:
 *         description: Rôle créé
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
 *                       example: "60d21b4667d0d8992e610c80"
 *                     name:
 *                       type: string
 *                       example: "editor"
 *                     description:
 *                       type: string
 *                       example: "Éditeur de contenu"
 *                     permissions:
 *                       type: array
 *                       items:
 *                         type: string
 *                         example: "60d21b4667d0d8992e610c71"
 *                     createdAt:
 *                       type: string
 *                       format: date-time
 *                     updatedAt:
 *                       type: string
 *                       format: date-time
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé (réservé aux super admins)
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/roles/{id}:
 *   get:
 *     summary: Récupérer un rôle spécifique
 *     tags: [Roles & Permissions]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID du rôle
 *     responses:
 *       200:
 *         description: Détails du rôle
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
 *                       example: "60d21b4667d0d8992e610c70"
 *                     name:
 *                       type: string
 *                       example: "admin"
 *                     description:
 *                       type: string
 *                       example: "Administrateur du système"
 *                     permissions:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           _id:
 *                             type: string
 *                             example: "60d21b4667d0d8992e610c71"
 *                           name:
 *                             type: string
 *                             example: "read:users"
 *                           description:
 *                             type: string
 *                             example: "Lire les données utilisateurs"
 *                     createdAt:
 *                       type: string
 *                       format: date-time
 *                     updatedAt:
 *                       type: string
 *                       format: date-time
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé (réservé aux super admins)
 *       404:
 *         description: Rôle non trouvé
 *       500:
 *         description: Erreur serveur
 * 
 *   put:
 *     summary: Mettre à jour un rôle
 *     tags: [Roles & Permissions]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID du rôle
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *                 example: "editor"
 *               description:
 *                 type: string
 *                 example: "Éditeur de contenu avancé"
 *               permissions:
 *                 type: array
 *                 items:
 *                   type: string
 *                 example: ["60d21b4667d0d8992e610c71", "60d21b4667d0d8992e610c72", "60d21b4667d0d8992e610c73"]
 *     responses:
 *       200:
 *         description: Rôle mis à jour
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
 *                       example: "60d21b4667d0d8992e610c70"
 *                     name:
 *                       type: string
 *                       example: "editor"
 *                     description:
 *                       type: string
 *                       example: "Éditeur de contenu avancé"
 *                     permissions:
 *                       type: array
 *                       items:
 *                         type: string
 *                         example: "60d21b4667d0d8992e610c71"
 *                     updatedAt:
 *                       type: string
 *                       format: date-time
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé (réservé aux super admins)
 *       404:
 *         description: Rôle non trouvé
 *       500:
 *         description: Erreur serveur
 * 
 *   delete:
 *     summary: Supprimer un rôle
 *     tags: [Roles & Permissions]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID du rôle
 *     responses:
 *       200:
 *         description: Rôle supprimé
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
 *                   example: "Rôle supprimé avec succès"
 *       400:
 *         description: Impossible de supprimer un rôle système
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé (réservé aux super admins)
 *       404:
 *         description: Rôle non trouvé
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/permissions:
 *   get:
 *     summary: Récupérer toutes les permissions
 *     tags: [Roles & Permissions]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des permissions
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
 *                         example: "60d21b4667d0d8992e610c71"
 *                       name:
 *                         type: string
 *                         example: "read:users"
 *                       description:
 *                         type: string
 *                         example: "Lire les données utilisateurs"
 *                       resource:
 *                         type: string
 *                         example: "users"
 *                       action:
 *                         type: string
 *                         example: "read"
 *                       createdAt:
 *                         type: string
 *                         format: date-time
 *                       updatedAt:
 *                         type: string
 *                         format: date-time
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé (réservé aux super admins)
 *       500:
 *         description: Erreur serveur
 * 
 *   post:
 *     summary: Créer une nouvelle permission
 *     tags: [Roles & Permissions]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - description
 *               - resource
 *               - action
 *             properties:
 *               name:
 *                 type: string
 *                 example: "read:reports"
 *               description:
 *                 type: string
 *                 example: "Lire les rapports du système"
 *               resource:
 *                 type: string
 *                 example: "reports"
 *               action:
 *                 type: string
 *                 example: "read"
 *     responses:
 *       201:
 *         description: Permission créée
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
 *                       example: "60d21b4667d0d8992e610c75"
 *                     name:
 *                       type: string
 *                       example: "read:reports"
 *                     description:
 *                       type: string
 *                       example: "Lire les rapports du système"
 *                     resource:
 *                       type: string
 *                       example: "reports"
 *                     action:
 *                       type: string
 *                       example: "read"
 *                     createdAt:
 *                       type: string
 *                       format: date-time
 *                     updatedAt:
 *                       type: string
 *                       format: date-time
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé (réservé aux super admins)
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/permissions/{id}:
 *   get:
 *     summary: Récupérer une permission spécifique
 *     tags: [Roles & Permissions]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la permission
 *     responses:
 *       200:
 *         description: Détails de la permission
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
 *                       example: "60d21b4667d0d8992e610c71"
 *                     name:
 *                       type: string
 *                       example: "read:users"
 *                     description:
 *                       type: string
 *                       example: "Lire les données utilisateurs"
 *                     resource:
 *                       type: string
 *                       example: "users"
 *                     action:
 *                       type: string
 *                       example: "read"
 *                     createdAt:
 *                       type: string
 *                       format: date-time
 *                     updatedAt:
 *                       type: string
 *                       format: date-time
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé (réservé aux super admins)
 *       404:
 *         description: Permission non trouvée
 *       500:
 *         description: Erreur serveur
 * 
 *   put:
 *     summary: Mettre à jour une permission
 *     tags: [Roles & Permissions]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la permission
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *                 example: "read:users"
 *               description:
 *                 type: string
 *                 example: "Lire et consulter les données utilisateurs"
 *               resource:
 *                 type: string
 *                 example: "users"
 *               action:
 *                 type: string
 *                 example: "read"
 *     responses:
 *       200:
 *         description: Permission mise à jour
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
 *                       example: "60d21b4667d0d8992e610c71"
 *                     name:
 *                       type: string
 *                       example: "read:users"
 *                     description:
 *                       type: string
 *                       example: "Lire et consulter les données utilisateurs"
 *                     resource:
 *                       type: string
 *                       example: "users"
 *                     action:
 *                       type: string
 *                       example: "read"
 *                     updatedAt:
 *                       type: string
 *                       format: date-time
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé (réservé aux super admins)
 *       404:
 *         description: Permission non trouvée
 *       500:
 *         description: Erreur serveur
 * 
 *   delete:
 *     summary: Supprimer une permission
 *     tags: [Roles & Permissions]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la permission
 *     responses:
 *       200:
 *         description: Permission supprimée
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
 *                   example: "Permission supprimée avec succès"
 *       400:
 *         description: Impossible de supprimer une permission système
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé (réservé aux super admins)
 *       404:
 *         description: Permission non trouvée
 *       500:
 *         description: Erreur serveur
 */ 