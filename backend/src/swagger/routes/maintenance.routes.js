/**
 * @swagger
 * tags:
 *   name: Maintenance
 *   description: Maintenance système — accès réservé aux superadmins (sauf GET /mode)
 */

/**
 * @swagger
 * /api/maintenance/mode:
 *   get:
 *     summary: Statut du mode maintenance (public)
 *     tags: [Maintenance]
 *     responses:
 *       200:
 *         description: Statut du mode maintenance
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     maintenanceMode:
 *                       type: boolean
 *                       example: false
 *                     message:
 *                       type: string
 *                       example: "Système opérationnel"
 *       500:
 *         description: Erreur serveur
 *   put:
 *     summary: Activer/désactiver le mode maintenance (superadmin uniquement)
 *     tags: [Maintenance]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - enabled
 *             properties:
 *               enabled:
 *                 type: boolean
 *                 description: Activer (true) ou désactiver (false) le mode maintenance
 *               message:
 *                 type: string
 *                 description: Message affiché pendant la maintenance
 *               estimatedDuration:
 *                 type: integer
 *                 description: Durée estimée en minutes
 *     responses:
 *       200:
 *         description: Mode maintenance mis à jour
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux superadmins
 *
 * /api/maintenance/status:
 *   get:
 *     summary: Statut système détaillé (superadmin uniquement)
 *     tags: [Maintenance]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Statut système
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     database:
 *                       type: string
 *                       enum: [connected, disconnected]
 *                     redis:
 *                       type: string
 *                       enum: [connected, disconnected, mock]
 *                     uptime:
 *                       type: number
 *                       description: Uptime en secondes
 *                     memory:
 *                       type: object
 *                     cpu:
 *                       type: object
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux superadmins
 */

/**
 * @swagger
 * /api/maintenance/backups:
 *   get:
 *     summary: Liste des sauvegardes disponibles (superadmin uniquement)
 *     tags: [Maintenance]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des sauvegardes
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: string
 *                       filename:
 *                         type: string
 *                       size:
 *                         type: number
 *                       createdAt:
 *                         type: string
 *                         format: date-time
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux superadmins
 *
 * /api/maintenance/backup:
 *   post:
 *     summary: Créer une nouvelle sauvegarde (superadmin uniquement)
 *     tags: [Maintenance]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               description:
 *                 type: string
 *                 description: Description de la sauvegarde
 *     responses:
 *       201:
 *         description: Sauvegarde créée
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux superadmins
 *
 * /api/maintenance/backup/{id}:
 *   delete:
 *     summary: Supprimer une sauvegarde (superadmin uniquement)
 *     tags: [Maintenance]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la sauvegarde
 *     responses:
 *       200:
 *         description: Sauvegarde supprimée
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux superadmins
 *       404:
 *         description: Sauvegarde non trouvée
 *
 * /api/maintenance/backup/{id}/restore:
 *   post:
 *     summary: Restaurer depuis une sauvegarde (superadmin uniquement)
 *     tags: [Maintenance]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la sauvegarde à restaurer
 *     responses:
 *       200:
 *         description: Restauration lancée
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux superadmins
 *       404:
 *         description: Sauvegarde non trouvée
 *
 * /api/maintenance/cleanup/{type}:
 *   post:
 *     summary: Nettoyer cache, logs, sessions ou fichiers temporaires (superadmin uniquement)
 *     tags: [Maintenance]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: type
 *         required: true
 *         schema:
 *           type: string
 *           enum: [cache, logs, sessions, temp]
 *         description: Type de nettoyage à effectuer
 *     responses:
 *       200:
 *         description: Nettoyage effectué
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     type:
 *                       type: string
 *                     itemsRemoved:
 *                       type: integer
 *                     freedSpace:
 *                       type: string
 *       400:
 *         description: Type de nettoyage invalide
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux superadmins
 */

// Ce fichier sert uniquement à documenter les endpoints pour Swagger
// Il n'exporte rien car il est uniquement lu par swagger-jsdoc
