/**
 * @swagger
 * tags:
 *   name: User
 *   description: Authentification et gestion des utilisateurs
 */

/**
 * @swagger
 * /api/users/register:
 *   post:
 *     summary: Inscription d'un nouvel utilisateur
 *     tags: [User]
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
 *                 description: Email de l'utilisateur
 *                 example: "utilisateur@exemple.com"
 *               password:
 *                 type: string
 *                 format: password
 *                 minLength: 8
 *                 description: Mot de passe (minimum 8 caractères)
 *               firstName:
 *                 type: string
 *                 description: Prénom de l'utilisateur
 *                 example: "Jean"
 *               lastName:
 *                 type: string
 *                 description: Nom de famille de l'utilisateur
 *                 example: "Dupont"
 *               phoneNumber:
 *                 type: string
 *                 description: Numéro de téléphone (optionnel)
 *                 example: "+33612345678"
 *               role:
 *                 type: string
 *                 enum: [client]
 *                 default: client
 *                 description: Rôle de l'utilisateur (par défaut client)
 *     responses:
 *       201:
 *         description: Utilisateur créé avec succès
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
 *                   example: "Utilisateur créé avec succès"
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
 *                       description: ID de l'utilisateur
 *                     email:
 *                       type: string
 *                       description: Email de l'utilisateur
 *                     firstName:
 *                       type: string
 *                       description: Prénom de l'utilisateur
 *                     lastName:
 *                       type: string
 *                       description: Nom de l'utilisateur
 *                     role:
 *                       type: string
 *                       example: "client"
 *                     isVerified:
 *                       type: boolean
 *                       description: Statut de vérification de l'email
 *       400:
 *         description: Données invalides
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       409:
 *         description: Email déjà utilisé
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
 * /api/users/login:
 *   post:
 *     summary: Connexion d'un utilisateur
 *     tags: [User]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 description: Email de l'utilisateur
 *                 example: "utilisateur@exemple.com"
 *               password:
 *                 type: string
 *                 format: password
 *                 description: Mot de passe de l'utilisateur
 *               rememberMe:
 *                 type: boolean
 *                 default: false
 *                 description: Maintenir la session active plus longtemps
 *     responses:
 *       200:
 *         description: Connexion réussie
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
 *                   example: "Connexion réussie"
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
 *                       description: ID de l'utilisateur
 *                     email:
 *                       type: string
 *                       description: Email de l'utilisateur
 *                     firstName:
 *                       type: string
 *                       description: Prénom de l'utilisateur
 *                     lastName:
 *                       type: string
 *                       description: Nom de l'utilisateur
 *                     role:
 *                       type: string
 *                       description: Rôle de l'utilisateur
 *                     profileImage:
 *                       type: string
 *                       description: URL de l'image de profil
 *                     isVerified:
 *                       type: boolean
 *                       description: Statut de vérification de l'email
 *                     lastLoginAt:
 *                       type: string
 *                       format: date-time
 *                       description: Date de dernière connexion
 *       400:
 *         description: Données manquantes ou invalides
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       401:
 *         description: Email ou mot de passe incorrect
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       403:
 *         description: Compte désactivé ou non vérifié
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       429:
 *         description: Trop de tentatives de connexion
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

// Ce fichier sert uniquement à documenter les endpoints pour Swagger
// Il n'exporte rien car il est uniquement lu par swagger-jsdoc
