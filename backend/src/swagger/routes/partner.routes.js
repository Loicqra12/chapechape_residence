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