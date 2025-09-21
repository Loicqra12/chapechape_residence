/**
 * Documentation Swagger pour les endpoints de reversements (Payouts)
 *
 * @swagger
 * tags:
 *   name: Payouts
 *   description: Gestion des reversements vers les partenaires (Wave, CinetPay, etc.)
 */

/**
 * @swagger
 * /api/payouts/create/{reservationId}:
 *   post:
 *     summary: Créer un payout pour une réservation
 *     tags: [Payouts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: reservationId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la réservation (MongoDB ObjectId)
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               scheduleDelayHours:
 *                 type: integer
 *                 minimum: 0
 *                 maximum: 168
 *                 description: Délai en heures avant exécution (0-168, max 1 semaine)
 *     responses:
 *       201:
 *         description: Payout créé et programmé avec succès
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès interdit (partenaire non propriétaire)
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/payouts/create/batch:
 *   post:
 *     summary: Créer des payouts en batch (admin uniquement)
 *     tags: [Payouts]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - reservationIds
 *             properties:
 *               reservationIds:
 *                 type: array
 *                 items:
 *                   type: string
 *                 minItems: 1
 *                 maxItems: 100
 *                 description: Liste d'IDs de réservations (1-100)
 *               scheduleDelayHours:
 *                 type: integer
 *                 minimum: 0
 *                 maximum: 168
 *                 description: Délai en heures avant exécution
 *     responses:
 *       200:
 *         description: Payouts créés avec succès
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux administrateurs
 */

/**
 * @swagger
 * /api/payouts/partner/{partnerId}:
 *   get:
 *     summary: Récupérer les payouts d'un partenaire
 *     tags: [Payouts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: partnerId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID du partenaire (MongoDB ObjectId)
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [PAYOUT_SCHEDULED, PAYOUT_PENDING, PAYOUT_SUCCESS, PAYOUT_FAILED, PAYOUT_CANCELLED]
 *         description: Filtrer par statut de payout
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 100
 *           default: 20
 *         description: Nombre maximum de résultats
 *       - in: query
 *         name: offset
 *         schema:
 *           type: integer
 *           minimum: 0
 *           default: 0
 *         description: Décalage pour la pagination
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date-time
 *         description: Date de début (ISO 8601)
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date-time
 *         description: Date de fin (ISO 8601)
 *       - in: query
 *         name: sortBy
 *         schema:
 *           type: string
 *           enum: [createdAt, scheduled_for, executed_at, net_amount, status]
 *         description: Champ de tri
 *       - in: query
 *         name: sortOrder
 *         schema:
 *           type: string
 *           enum: [asc, desc]
 *           default: desc
 *         description: Ordre de tri
 *     responses:
 *       200:
 *         description: Liste des payouts récupérée
 *       400:
 *         description: Paramètres invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès interdit
 */

/**
 * @swagger
 * /api/payouts/{payoutId}:
 *   get:
 *     summary: Récupérer un payout par son ID
 *     tags: [Payouts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: payoutId
 *         required: true
 *         schema:
 *           type: string
 *           pattern: '^PAYOUT_'
 *         description: ID payout au format PAYOUT_*
 *     responses:
 *       200:
 *         description: Détails du payout
 *       400:
 *         description: Format ID invalide
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès interdit
 *       404:
 *         description: Payout non trouvé
 */

/**
 * @swagger
 * /api/payouts/execute/{payoutId}:
 *   post:
 *     summary: Exécuter un payout manuellement (admin uniquement)
 *     tags: [Payouts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: payoutId
 *         required: true
 *         schema:
 *           type: string
 *           pattern: '^PAYOUT_'
 *         description: ID payout au format PAYOUT_*
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               force:
 *                 type: boolean
 *                 description: Forcer l'exécution même si des vérifications échouent
 *     responses:
 *       200:
 *         description: Exécution déclenchée
 *       400:
 *         description: Format ID invalide
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux administrateurs
 *       404:
 *         description: Payout non trouvé
 */

/**
 * @swagger
 * /api/payouts/process/scheduled:
 *   post:
 *     summary: Traiter tous les payouts programmés (admin uniquement)
 *     tags: [Payouts]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Traitement des payouts programmés lancé
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux administrateurs
 */

/**
 * @swagger
 * /api/payouts/sync/pending:
 *   post:
 *     summary: Synchroniser les payouts en attente avec CinetPay (admin uniquement)
 *     tags: [Payouts]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Synchronisation effectuée
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux administrateurs
 */

/**
 * @swagger
 * /api/payouts/stats/{partnerId}:
 *   get:
 *     summary: Statistiques de payouts d'un partenaire
 *     tags: [Payouts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: partnerId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID du partenaire (MongoDB ObjectId)
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date-time
 *         description: Date de début (ISO 8601)
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date-time
 *         description: Date de fin (ISO 8601)
 *     responses:
 *       200:
 *         description: Statistiques renvoyées
 *       400:
 *         description: Paramètres invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès interdit
 */

/**
 * @swagger
 * /api/payouts/wave/transfer:
 *   post:
 *     summary: Initier un transfert Wave
 *     tags: [Payouts]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - amount
 *               - mobile
 *               - name
 *             properties:
 *               amount:
 *                 type: number
 *                 minimum: 100
 *                 description: Montant minimum 100 FCFA
 *               mobile:
 *                 type: string
 *                 pattern: '^\\+[1-9]\\d{1,14}$'
 *                 description: Numéro de téléphone au format E.164 (+XXXXXXXXXXX)
 *               name:
 *                 type: string
 *                 minLength: 2
 *                 maxLength: 255
 *                 description: Nom du bénéficiaire
 *               payment_reason:
 *                 type: string
 *                 maxLength: 40
 *                 description: Motif du paiement (optionnel)
 *               national_id:
 *                 type: string
 *                 maxLength: 255
 *                 description: ID national (optionnel)
 *     responses:
 *       200:
 *         description: Transfert initié avec succès
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 */

/**
 * @swagger
 * /api/payouts/wave/transfer/{waveId}/status:
 *   get:
 *     summary: Vérifier le statut d'un transfert Wave
 *     tags: [Payouts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: waveId
 *         required: true
 *         schema:
 *           type: string
 *           pattern: '^pt-'
 *         description: ID Wave au format pt-xxx
 *     responses:
 *       200:
 *         description: Statut du transfert renvoyé
 *       400:
 *         description: ID Wave invalide
 *       401:
 *         description: Non autorisé
 */

/**
 * @swagger
 * /api/payouts/wave/search:
 *   get:
 *     summary: Rechercher des transferts Wave
 *     tags: [Payouts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: client_reference
 *         schema:
 *           type: string
 *           minLength: 1
 *         description: Référence client pour la recherche
 *     responses:
 *       200:
 *         description: Résultats de recherche renvoyés
 *       400:
 *         description: Paramètres invalides
 *       401:
 *         description: Non autorisé
 */

/**
 * @swagger
 * /api/payouts/wave/batch:
 *   post:
 *     summary: Créer un batch de transferts Wave (admin uniquement)
 *     tags: [Payouts]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - transfers
 *             properties:
 *               transfers:
 *                 type: array
 *                 minItems: 1
 *                 maxItems: 100
 *                 items:
 *                   type: object
 *                   required:
 *                     - amount
 *                     - mobile
 *                     - name
 *                   properties:
 *                     amount:
 *                       type: number
 *                       minimum: 100
 *                     mobile:
 *                       type: string
 *                       pattern: '^\\+[1-9]\\d{1,14}$'
 *                     name:
 *                       type: string
 *                       minLength: 2
 *                       maxLength: 255
 *     responses:
 *       200:
 *         description: Batch créé avec succès
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux administrateurs
 */

/**
 * @swagger
 * /api/payouts/wave/batch/{batchId}/status:
 *   get:
 *     summary: Statut d'un batch Wave (admin uniquement)
 *     tags: [Payouts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: batchId
 *         required: true
 *         schema:
 *           type: string
 *           pattern: '^pb-'
 *         description: ID batch au format pb-xxx
 *     responses:
 *       200:
 *         description: Statut du batch renvoyé
 *       400:
 *         description: ID batch invalide
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux administrateurs
 */

/**
 * @swagger
 * /api/payouts/wave/transfer/{waveId}/reverse:
 *   post:
 *     summary: Annuler un transfert Wave (admin uniquement)
 *     tags: [Payouts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: waveId
 *         required: true
 *         schema:
 *           type: string
 *           pattern: '^pt-'
 *         description: ID Wave au format pt-xxx
 *     responses:
 *       200:
 *         description: Transfert annulé avec succès
 *       400:
 *         description: ID Wave invalide
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux administrateurs
 */

/**
 * @swagger
 * /api/payouts/wave/webhook:
 *   post:
 *     summary: Webhook Wave Payout (appelé par Wave)
 *     tags: [Payouts]
 *     description: Endpoint appelé par Wave lors des notifications de transfert. Ne pas appeler directement depuis un client.
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *     responses:
 *       200:
 *         description: Webhook traité
 *       400:
 *         description: Signature invalide ou corps invalide
 */

/**
 * @swagger
 * /api/payouts/cinetpay/balance:
 *   get:
 *     summary: Récupérer le solde CinetPay
 *     tags: [Payouts]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Solde récupéré avec succès
 *       401:
 *         description: Non autorisé
 *       500:
 *         description: Erreur lors de la récupération du solde
 */

/**
 * @swagger
 * /api/payouts/cinetpay/transfer:
 *   post:
 *     summary: Initier un transfert CinetPay
 *     tags: [Payouts]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - payout_id
 *               - amount
 *               - phone_number
 *             properties:
 *               payout_id:
 *                 type: string
 *                 description: ID payout unique
 *               amount:
 *                 type: number
 *                 minimum: 100
 *                 description: Montant minimum 100 FCFA
 *               phone_number:
 *                 type: string
 *                 pattern: '^\\+[1-9]\\d{1,14}$'
 *                 description: Numéro de téléphone au format E.164
 *               first_name:
 *                 type: string
 *                 description: Prénom (optionnel)
 *               last_name:
 *                 type: string
 *                 description: Nom (optionnel)
 *               email:
 *                 type: string
 *                 format: email
 *                 description: Email (optionnel)
 *               channel:
 *                 type: string
 *                 enum: [orange_money, mtn_money, moov_money]
 *                 description: Canal de paiement (optionnel)
 *     responses:
 *       200:
 *         description: Transfert initié avec succès
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 */

/**
 * @swagger
 * /api/payouts/cinetpay/transfer/{transferId}/status:
 *   get:
 *     summary: Vérifier le statut d'un transfert CinetPay
 *     tags: [Payouts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: transferId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de transfert CinetPay
 *     responses:
 *       200:
 *         description: Statut du transfert renvoyé
 *       400:
 *         description: ID transfert invalide
 *       401:
 *         description: Non autorisé
 */

/**
 * @swagger
 * /api/payouts/cinetpay/transfer/{transferId}/cancel:
 *   post:
 *     summary: Annuler un transfert CinetPay
 *     tags: [Payouts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: transferId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de transfert CinetPay
 *     responses:
 *       200:
 *         description: Transfert annulé avec succès
 *       400:
 *         description: ID transfert invalide
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès interdit (partenaire non propriétaire)
 */

/**
 * @swagger
 * /api/payouts/cinetpay/transfer/history:
 *   get:
 *     summary: Récupérer l'historique des transferts CinetPay
 *     tags: [Payouts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           minimum: 1
 *           default: 1
 *         description: Numéro de page
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 100
 *           default: 20
 *         description: Nombre d'éléments par page
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, completed, failed, cancelled]
 *         description: Filtrer par statut
 *     responses:
 *       200:
 *         description: Historique récupéré avec succès
 *       400:
 *         description: Paramètres invalides
 *       401:
 *         description: Non autorisé
 */

/**
 * @swagger
 * /api/payouts/cinetpay/transfer/stats:
 *   get:
 *     summary: Récupérer les statistiques des transferts CinetPay
 *     tags: [Payouts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date-time
 *         description: Date de début (ISO 8601)
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date-time
 *         description: Date de fin (ISO 8601)
 *     responses:
 *       200:
 *         description: Statistiques récupérées avec succès
 *       400:
 *         description: Paramètres invalides
 *       401:
 *         description: Non autorisé
 */

/**
 * @swagger
 * /api/payouts/cinetpay/webhook:
 *   post:
 *     summary: Webhook CinetPay Transfer (appelé par CinetPay)
 *     tags: [Payouts]
 *     description: Endpoint appelé par CinetPay lors des notifications de transfert. Ne pas appeler directement depuis un client.
 *     requestBody:
 *       content:
 *         application/x-www-form-urlencoded:
 *           schema:
 *             type: object
 *     responses:
 *       200:
 *         description: Webhook traité
 *       400:
 *         description: Erreur traitement webhook
 */

/**
 * @swagger
 * /api/payouts/reset/{payoutId}:
 *   post:
 *     summary: Réinitialiser un payout échoué (admin uniquement)
 *     tags: [Payouts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: payoutId
 *         required: true
 *         schema:
 *           type: string
 *           pattern: '^PAYOUT_'
 *         description: ID payout au format PAYOUT_*
 *     responses:
 *       200:
 *         description: Payout réinitialisé avec succès
 *       400:
 *         description: Format ID invalide
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux administrateurs
 *       404:
 *         description: Payout non trouvé
 */

// Ce fichier sert uniquement à documenter les endpoints pour Swagger
// Il n'exporte rien car il est uniquement lu par swagger-jsdoc
