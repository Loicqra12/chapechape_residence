/**
 * @swagger
 * tags:
 *   name: Messages
 *   description: Gestion des messages et conversations entre utilisateurs
 */

/**
 * @swagger
 * /api/messages/conversations:
 *   get:
 *     summary: Récupérer toutes les conversations de l'utilisateur
 *     tags: [Messages]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des conversations
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
 *                         example: "60d21b4667d0d8992e610c85"
 *                       participants:
 *                         type: array
 *                         items:
 *                           type: object
 *                           properties:
 *                             _id:
 *                               type: string
 *                               example: "60d21b4667d0d8992e610c80"
 *                             name:
 *                               type: string
 *                               example: "John Doe"
 *                             avatar:
 *                               type: string
 *                               example: "https://example.com/avatar.jpg"
 *                       lastMessage:
 *                         type: object
 *                         properties:
 *                           _id:
 *                             type: string
 *                             example: "60d21b4667d0d8992e610c90"
 *                           content:
 *                             type: string
 *                             example: "Bonjour, est-ce que la résidence est disponible?"
 *                           createdAt:
 *                             type: string
 *                             format: date-time
 *                       unreadCount:
 *                         type: number
 *                         example: 3
 *                       residenceId:
 *                         type: string
 *                         example: "60d21b4667d0d8992e610c70"
 *                       createdAt:
 *                         type: string
 *                         format: date-time
 *                       updatedAt:
 *                         type: string
 *                         format: date-time
 *       401:
 *         description: Non autorisé
 *       500:
 *         description: Erreur serveur
 * 
 *   post:
 *     summary: Créer une nouvelle conversation
 *     tags: [Messages]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - participants
 *             properties:
 *               participants:
 *                 type: array
 *                 items:
 *                   type: string
 *                 example: ["60d21b4667d0d8992e610c80"]
 *               residenceId:
 *                 type: string
 *                 example: "60d21b4667d0d8992e610c70"
 *               reservationId:
 *                 type: string
 *                 example: "60d21b4667d0d8992e610c60"
 *     responses:
 *       201:
 *         description: Conversation créée
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
 *                       example: "60d21b4667d0d8992e610c85"
 *                     participants:
 *                       type: array
 *                       items:
 *                         type: string
 *                         example: "60d21b4667d0d8992e610c80"
 *                     residenceId:
 *                       type: string
 *                       example: "60d21b4667d0d8992e610c70"
 *                     createdAt:
 *                       type: string
 *                       format: date-time
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/messages/conversations/{id}:
 *   get:
 *     summary: Récupérer les détails d'une conversation spécifique
 *     tags: [Messages]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la conversation
 *     responses:
 *       200:
 *         description: Détails de la conversation
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
 *                       example: "60d21b4667d0d8992e610c85"
 *                     participants:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           _id:
 *                             type: string
 *                             example: "60d21b4667d0d8992e610c80"
 *                           name:
 *                             type: string
 *                             example: "John Doe"
 *                           avatar:
 *                             type: string
 *                             example: "https://example.com/avatar.jpg"
 *                     lastMessage:
 *                       type: object
 *                       properties:
 *                         _id:
 *                           type: string
 *                           example: "60d21b4667d0d8992e610c90"
 *                         content:
 *                           type: string
 *                           example: "Bonjour, est-ce que la résidence est disponible?"
 *                         createdAt:
 *                           type: string
 *                           format: date-time
 *                     residenceId:
 *                       type: object
 *                       properties:
 *                         _id:
 *                           type: string
 *                           example: "60d21b4667d0d8992e610c70"
 *                         name:
 *                           type: string
 *                           example: "Villa avec piscine"
 *                     reservationId:
 *                       type: object
 *                       properties:
 *                         _id:
 *                           type: string
 *                           example: "60d21b4667d0d8992e610c60"
 *                         status:
 *                           type: string
 *                           example: "confirmed"
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès interdit
 *       404:
 *         description: Conversation non trouvée
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/messages/conversations/{id}/messages:
 *   get:
 *     summary: Récupérer les messages d'une conversation
 *     tags: [Messages]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la conversation
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Numéro de page
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *         description: Nombre de messages par page
 *     responses:
 *       200:
 *         description: Liste des messages
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
 *                     messages:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           _id:
 *                             type: string
 *                             example: "60d21b4667d0d8992e610c90"
 *                           conversation:
 *                             type: string
 *                             example: "60d21b4667d0d8992e610c85"
 *                           sender:
 *                             type: object
 *                             properties:
 *                               _id:
 *                                 type: string
 *                                 example: "60d21b4667d0d8992e610c80"
 *                               name:
 *                                 type: string
 *                                 example: "John Doe"
 *                               avatar:
 *                                 type: string
 *                                 example: "https://example.com/avatar.jpg"
 *                           content:
 *                             type: string
 *                             example: "Bonjour, est-ce que la résidence est disponible?"
 *                           read:
 *                             type: boolean
 *                             example: false
 *                           readAt:
 *                             type: string
 *                             format: date-time
 *                             nullable: true
 *                           attachments:
 *                             type: array
 *                             items:
 *                               type: object
 *                               properties:
 *                                 type:
 *                                   type: string
 *                                   enum: [image, document]
 *                                   example: "image"
 *                                 url:
 *                                   type: string
 *                                   example: "https://example.com/image.jpg"
 *                                 name:
 *                                   type: string
 *                                   example: "image.jpg"
 *                                 size:
 *                                   type: number
 *                                   example: 1024
 *                           createdAt:
 *                             type: string
 *                             format: date-time
 *                     pagination:
 *                       type: object
 *                       properties:
 *                         page:
 *                           type: integer
 *                           example: 1
 *                         limit:
 *                           type: integer
 *                           example: 20
 *                         total:
 *                           type: integer
 *                           example: 45
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès interdit
 *       404:
 *         description: Conversation non trouvée
 *       500:
 *         description: Erreur serveur
 * 
 *   post:
 *     summary: Envoyer un message dans une conversation
 *     tags: [Messages]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la conversation
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - content
 *             properties:
 *               content:
 *                 type: string
 *                 example: "Bonjour, est-ce que la résidence est disponible?"
 *               attachments:
 *                 type: array
 *                 items:
 *                   type: object
 *                   properties:
 *                     type:
 *                       type: string
 *                       enum: [image, document]
 *                       example: "image"
 *                     url:
 *                       type: string
 *                       example: "https://example.com/image.jpg"
 *                     name:
 *                       type: string
 *                       example: "image.jpg"
 *                     size:
 *                       type: number
 *                       example: 1024
 *     responses:
 *       201:
 *         description: Message envoyé
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
 *                       example: "60d21b4667d0d8992e610c90"
 *                     conversation:
 *                       type: string
 *                       example: "60d21b4667d0d8992e610c85"
 *                     sender:
 *                       type: object
 *                       properties:
 *                         _id:
 *                           type: string
 *                           example: "60d21b4667d0d8992e610c80"
 *                         name:
 *                           type: string
 *                           example: "John Doe"
 *                         avatar:
 *                           type: string
 *                           example: "https://example.com/avatar.jpg"
 *                     content:
 *                       type: string
 *                       example: "Bonjour, est-ce que la résidence est disponible?"
 *                     read:
 *                       type: boolean
 *                       example: false
 *                     attachments:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           type:
 *                             type: string
 *                             enum: [image, document]
 *                             example: "image"
 *                           url:
 *                             type: string
 *                             example: "https://example.com/image.jpg"
 *                           name:
 *                             type: string
 *                             example: "image.jpg"
 *                           size:
 *                             type: number
 *                             example: 1024
 *                     createdAt:
 *                       type: string
 *                       format: date-time
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès interdit
 *       404:
 *         description: Conversation non trouvée
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/messages/conversations/{id}/attachments:
 *   post:
 *     summary: Envoyer une pièce jointe dans une conversation
 *     tags: [Messages]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la conversation
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required:
 *               - file
 *             properties:
 *               file:
 *                 type: string
 *                 format: binary
 *                 description: Fichier à envoyer
 *     responses:
 *       201:
 *         description: Pièce jointe envoyée
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
 *                     type:
 *                       type: string
 *                       enum: [image, document]
 *                       example: "image"
 *                     url:
 *                       type: string
 *                       example: "https://example.com/uploads/messages/image.jpg"
 *                     name:
 *                       type: string
 *                       example: "image.jpg"
 *                     size:
 *                       type: number
 *                       example: 1024
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès interdit
 *       404:
 *         description: Conversation non trouvée
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/messages/conversations/{id}/read:
 *   patch:
 *     summary: Marquer une conversation comme lue
 *     tags: [Messages]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la conversation
 *     responses:
 *       200:
 *         description: Conversation marquée comme lue
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
 *                     unreadCount:
 *                       type: number
 *                       example: 0
 *                     updatedAt:
 *                       type: string
 *                       format: date-time
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès interdit
 *       404:
 *         description: Conversation non trouvée
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/messages/whatsapp/test:
 *   post:
 *     summary: Tester l'envoi WhatsApp Business (développement)
 *     tags: [Messages]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - to
 *               - message
 *             properties:
 *               to:
 *                 type: string
 *                 description: "Numéro de téléphone destinataire (format E.164)"
 *                 example: "+2250789123456"
 *               message:
 *                 type: string
 *                 description: "Contenu du message à envoyer"
 *                 example: "Test message WhatsApp Business"
 *     responses:
 *       200:
 *         description: Message WhatsApp envoyé avec succès
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       500:
 *         description: Erreur envoi WhatsApp
 */

/**
 * @swagger
 * /api/messages/conversations/{id}/whatsapp:
 *   post:
 *     summary: Envoyer un message WhatsApp Business dans une conversation
 *     tags: [Messages]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la conversation
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
 *                 description: "Contenu du message WhatsApp"
 *                 example: "Votre réservation est confirmée"
 *     responses:
 *       201:
 *         description: Message WhatsApp envoyé et ajouté à la conversation
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès interdit
 *       404:
 *         description: Conversation non trouvée
 *       500:
 *         description: Erreur serveur ou WhatsApp
 */

// Ce fichier sert uniquement à documenter les endpoints pour Swagger
// Il n'exporte rien car il est uniquement lu par swagger-jsdoc