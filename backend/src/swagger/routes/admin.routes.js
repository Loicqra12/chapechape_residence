/**
 * @swagger
 * tags:
 *   name: Admin
 *   description: Interface d'administration — accès réservé aux admins et superadmins
 */

/**
 * @swagger
 * /api/admin/dashboard:
 *   get:
 *     summary: Statistiques du tableau de bord admin
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Statistiques globales
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 *
 * /api/admin/payments:
 *   get:
 *     summary: Liste de tous les paiements
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des paiements
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 *
 * /api/admin/stats/advanced:
 *   get:
 *     summary: Statistiques avancées avec filtres de dates
 *     tags: [Admin]
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
 *     responses:
 *       200:
 *         description: Statistiques avancées
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 *
 * /api/admin/activity-logs:
 *   get:
 *     summary: Journal d'activité global
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Journal d'activité
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 */

/**
 * @swagger
 * /api/admin/admins:
 *   get:
 *     summary: Liste de tous les administrateurs
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des admins
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 *   post:
 *     summary: Créer un nouvel administrateur
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
 *               password:
 *                 type: string
 *                 format: password
 *               firstName:
 *                 type: string
 *               lastName:
 *                 type: string
 *               phoneNumber:
 *                 type: string
 *     responses:
 *       201:
 *         description: Administrateur créé
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 *
 * /api/admin/admins/{id}:
 *   get:
 *     summary: Détails d'un administrateur
 *     tags: [Admin]
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
 *         description: Réservé aux admins
 *       404:
 *         description: Admin non trouvé
 *   put:
 *     summary: Mettre à jour un administrateur
 *     tags: [Admin]
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
 *         description: Réservé aux admins
 *       404:
 *         description: Admin non trouvé
 *   delete:
 *     summary: Supprimer un administrateur
 *     tags: [Admin]
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
 *         description: Réservé aux admins
 *       404:
 *         description: Admin non trouvé
 */

/**
 * @swagger
 * /api/admin/users:
 *   get:
 *     summary: Liste de tous les utilisateurs
 *     tags: [Admin]
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
 *           default: 20
 *       - in: query
 *         name: role
 *         schema:
 *           type: string
 *           enum: [client, partner, admin, superadmin]
 *     responses:
 *       200:
 *         description: Liste des utilisateurs
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 *
 * /api/admin/users/{id}:
 *   get:
 *     summary: Détails d'un utilisateur
 *     tags: [Admin]
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
 *         description: Détails de l'utilisateur
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 *       404:
 *         description: Utilisateur non trouvé
 *   put:
 *     summary: Mettre à jour un utilisateur
 *     tags: [Admin]
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
 *         description: Utilisateur mis à jour
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 *       404:
 *         description: Utilisateur non trouvé
 *   delete:
 *     summary: Supprimer un utilisateur
 *     tags: [Admin]
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
 *         description: Utilisateur supprimé
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 *       404:
 *         description: Utilisateur non trouvé
 */

/**
 * @swagger
 * /api/admin/partners:
 *   get:
 *     summary: Liste de tous les partenaires
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des partenaires
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 *
 * /api/admin/partners/{id}:
 *   get:
 *     summary: Détails d'un partenaire
 *     tags: [Admin]
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
 *         description: Détails du partenaire
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 *       404:
 *         description: Partenaire non trouvé
 *   put:
 *     summary: Mettre à jour un partenaire
 *     tags: [Admin]
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
 *         description: Partenaire mis à jour
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 *       404:
 *         description: Partenaire non trouvé
 *   delete:
 *     summary: Supprimer un partenaire
 *     tags: [Admin]
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
 *         description: Partenaire supprimé
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 *       404:
 *         description: Partenaire non trouvé
 *
 * /api/admin/partners/{id}/verify:
 *   put:
 *     summary: Vérifier/valider un partenaire
 *     tags: [Admin]
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
 *         description: Partenaire vérifié
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 *       404:
 *         description: Partenaire non trouvé
 */

/**
 * @swagger
 * /api/admin/residences:
 *   get:
 *     summary: Liste de toutes les résidences
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des résidences
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 *
 * /api/admin/residences/pending:
 *   get:
 *     summary: Résidences en attente de validation
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des résidences en attente
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 *
 * /api/admin/residences/{id}:
 *   get:
 *     summary: Détails d'une résidence
 *     tags: [Admin]
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
 *         description: Détails de la résidence
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 *       404:
 *         description: Résidence non trouvée
 *
 * /api/admin/residences/{id}/validate:
 *   put:
 *     summary: Valider une résidence
 *     tags: [Admin]
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
 *         description: Résidence validée
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 *       404:
 *         description: Résidence non trouvée
 *
 * /api/admin/residences/{id}/reject:
 *   put:
 *     summary: Rejeter une résidence
 *     tags: [Admin]
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
 *             properties:
 *               reason:
 *                 type: string
 *     responses:
 *       200:
 *         description: Résidence rejetée
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 *       404:
 *         description: Résidence non trouvée
 *
 * /api/admin/residences/{id}/verify:
 *   put:
 *     summary: Vérifier une résidence
 *     tags: [Admin]
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
 *         description: Résidence vérifiée
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 *       404:
 *         description: Résidence non trouvée
 */

/**
 * @swagger
 * /api/admin/residences/{residenceId}/availability:
 *   get:
 *     summary: Disponibilités d'une résidence (admin)
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: residenceId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Disponibilités de la résidence
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 *
 * /api/admin/residences/{residenceId}/block-dates:
 *   post:
 *     summary: Bloquer des dates pour une résidence (admin)
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: residenceId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - startDate
 *               - endDate
 *             properties:
 *               startDate:
 *                 type: string
 *                 format: date
 *               endDate:
 *                 type: string
 *                 format: date
 *               reason:
 *                 type: string
 *     responses:
 *       200:
 *         description: Dates bloquées
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 *
 * /api/admin/residences/{residenceId}/unblock-dates:
 *   delete:
 *     summary: Débloquer des dates pour une résidence (admin)
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: residenceId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - startDate
 *               - endDate
 *             properties:
 *               startDate:
 *                 type: string
 *                 format: date
 *               endDate:
 *                 type: string
 *                 format: date
 *     responses:
 *       200:
 *         description: Dates débloquées
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 */

/**
 * @swagger
 * /api/admin/roles:
 *   get:
 *     summary: Liste de tous les rôles
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des rôles
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 *   post:
 *     summary: Créer un rôle
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
 *               - name
 *             properties:
 *               name:
 *                 type: string
 *               permissions:
 *                 type: array
 *                 items:
 *                   type: string
 *     responses:
 *       201:
 *         description: Rôle créé
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 *
 * /api/admin/permissions:
 *   get:
 *     summary: Liste de toutes les permissions
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des permissions
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 *   post:
 *     summary: Créer une permission
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
 *               - name
 *               - resource
 *               - action
 *             properties:
 *               name:
 *                 type: string
 *               resource:
 *                 type: string
 *               action:
 *                 type: string
 *     responses:
 *       201:
 *         description: Permission créée
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux admins
 */

// Ce fichier sert uniquement à documenter les endpoints pour Swagger
// Il n'exporte rien car il est uniquement lu par swagger-jsdoc
