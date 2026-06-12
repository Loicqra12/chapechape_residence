/**
 * @swagger
 * tags:
 *   name: Support
 *   description: Gestion des tickets de support utilisateur
 */

/**
 * @swagger
 * /api/support/tickets:
 *   get:
 *     summary: Liste des tickets de support de l'utilisateur connecté
 *     tags: [Support]
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
 *     responses:
 *       200:
 *         description: Liste des tickets
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
 *                 pagination:
 *                   type: object
 *                   properties:
 *                     page:
 *                       type: integer
 *                     limit:
 *                       type: integer
 *                     total:
 *                       type: integer
 *                     pages:
 *                       type: integer
 *       401:
 *         description: Non autorisé
 *   post:
 *     summary: Créer un nouveau ticket de support
 *     tags: [Support]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - subject
 *               - category
 *             properties:
 *               subject:
 *                 type: string
 *                 description: Sujet du ticket
 *               category:
 *                 type: string
 *                 description: Catégorie du problème
 *               priority:
 *                 type: string
 *                 enum: [low, medium, high, urgent]
 *                 default: medium
 *               message:
 *                 type: string
 *                 description: Description détaillée du problème
 *     responses:
 *       201:
 *         description: Ticket créé avec succès
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
 *                     _id:
 *                       type: string
 *                     subject:
 *                       type: string
 *                     category:
 *                       type: string
 *                     priority:
 *                       type: string
 *                     status:
 *                       type: string
 *                       example: open
 *                     createdAt:
 *                       type: string
 *                       format: date-time
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *
 * /api/support/tickets/{id}/reply:
 *   post:
 *     summary: Répondre à un ticket de support
 *     tags: [Support]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID du ticket
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - message
 *             properties:
 *               message:
 *                 type: string
 *                 description: Contenu de la réponse
 *     responses:
 *       200:
 *         description: Réponse ajoutée avec succès
 *       401:
 *         description: Non autorisé
 *       404:
 *         description: Ticket non trouvé
 *
 * /api/support/tickets/{id}/close:
 *   put:
 *     summary: Fermer un ticket de support
 *     tags: [Support]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID du ticket
 *     responses:
 *       200:
 *         description: Ticket fermé avec succès
 *       401:
 *         description: Non autorisé
 *       404:
 *         description: Ticket non trouvé
 */

// Ce fichier sert uniquement à documenter les endpoints pour Swagger
// Il n'exporte rien car il est uniquement lu par swagger-jsdoc
