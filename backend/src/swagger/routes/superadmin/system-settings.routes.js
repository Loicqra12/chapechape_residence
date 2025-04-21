/**
 * Documentation Swagger pour la gestion des paramètres système (Super Admin)
 * 
 * @swagger
 * tags:
 *   name: Super Admin - System Settings
 *   description: Gestion des paramètres système par le Super Admin
 */

/**
 * @swagger
 * /api/superadmin/settings:
 *   get:
 *     summary: Récupérer tous les paramètres système
 *     tags: [Super Admin - System Settings]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des paramètres système
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
 *                         description: ID du paramètre
 *                       key:
 *                         type: string
 *                         description: Clé du paramètre
 *                       value:
 *                         type: string
 *                         description: Valeur du paramètre
 *                       description:
 *                         type: string
 *                         description: Description du paramètre
 *                       type:
 *                         type: string
 *                         enum: [string, number, boolean, json]
 *                         description: Type de donnée du paramètre
 *                       category:
 *                         type: string
 *                         enum: [general, security, email, payment, notification, booking]
 *                         description: Catégorie du paramètre
 *                       isPublic:
 *                         type: boolean
 *                         description: Indique si le paramètre est accessible publiquement
 *                       updatedAt:
 *                         type: string
 *                         format: date-time
 *                         description: Date de dernière mise à jour
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
 *   put:
 *     summary: Mettre à jour un ou plusieurs paramètres système
 *     tags: [Super Admin - System Settings]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             additionalProperties:
 *               type: string
 *             example:
 *               maintenance_mode: "true"
 *               booking_fee_percentage: "5"
 *               default_currency: "XOF"
 *     responses:
 *       200:
 *         description: Paramètres mis à jour avec succès
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
 *                         description: ID du paramètre
 *                       key:
 *                         type: string
 *                         description: Clé du paramètre
 *                       value:
 *                         type: string
 *                         description: Valeur du paramètre (mise à jour)
 *                       updatedAt:
 *                         type: string
 *                         format: date-time
 *                         description: Date de mise à jour
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