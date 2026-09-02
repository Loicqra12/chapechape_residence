/**
 * Documentation Swagger pour les endpoints de réservation
 *
 * @swagger
 * tags:
 *   name: Réservations
 *   description: Gestion des réservations de résidences
 */

/**
 * @swagger
 * /api/reservations:
 *   post:
 *     summary: Créer une nouvelle réservation
 *     tags: [Réservations]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - residence
 *               - checkIn
 *               - checkOut
 *               - numberOfGuests
 *             properties:
 *               residence:
 *                 type: string
 *                 description: ID de la résidence à réserver
 *               checkIn:
 *                 type: string
 *                 format: date
 *               checkOut:
 *                 type: string
 *                 format: date
 *               numberOfGuests:
 *                 type: integer
 *                 minimum: 1
 *               bookingType:
 *                 type: string
 *                 enum: [hour, day, week, month]
 *                 default: day
 *               paymentMethod:
 *                 type: string
 *                 enum: [mtn_money, orange_money, wave, moov_money, card]
 *                 default: mtn_money
 *               specialRequests:
 *                 type: string
 *     responses:
 *       201:
 *         description: Réservation créée avec succès
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/Reservation'
 *       400:
 *         description: Données invalides ou résidence non disponible
 *       401:
 *         description: Non autorisé
 *       404:
 *         description: Résidence non trouvée
 */

/**
 * @swagger
 * /api/reservations/my-reservations:
 *   get:
 *     summary: Réservations de l'utilisateur connecté
 *     tags: [Réservations]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, awaiting_approval, payment_pending, confirmed, in_stay, cancelled, completed, expired, refunded]
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *     responses:
 *       200:
 *         description: Liste des réservations
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
 *                     $ref: '#/components/schemas/ReservationWithVirtuals'
 *       401:
 *         description: Non autorisé
 *
 * /api/reservations/partner-reservations:
 *   get:
 *     summary: Réservations du partenaire connecté
 *     tags: [Réservations]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, awaiting_approval, payment_pending, confirmed, in_stay, cancelled, completed, expired, refunded]
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *     responses:
 *       200:
 *         description: Liste des réservations du partenaire
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux partenaires
 *
 * /api/reservations/residence/{residenceId}:
 *   get:
 *     summary: Réservations d'une résidence
 *     tags: [Réservations]
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
 *         description: Liste des réservations de la résidence
 *       401:
 *         description: Non autorisé
 *       404:
 *         description: Résidence non trouvée
 */

/**
 * @swagger
 * /api/reservations/{id}:
 *   get:
 *     summary: Détails d'une réservation
 *     tags: [Réservations]
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
 *         description: Détails de la réservation
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   $ref: '#/components/schemas/ReservationWithVirtuals'
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès interdit
 *       404:
 *         description: Réservation non trouvée
 *   patch:
 *     summary: Modifier une réservation (dates, nombre de personnes)
 *     tags: [Réservations]
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
 *               checkIn:
 *                 type: string
 *                 format: date
 *               checkOut:
 *                 type: string
 *                 format: date
 *               numberOfGuests:
 *                 type: integer
 *                 minimum: 1
 *     responses:
 *       200:
 *         description: Réservation modifiée
 *       400:
 *         description: Modification non autorisée ou dates indisponibles
 *       401:
 *         description: Non autorisé
 *       404:
 *         description: Réservation non trouvée
 */

/**
 * @swagger
 * /api/reservations/{id}/status:
 *   patch:
 *     summary: Mettre à jour le statut d'une réservation
 *     tags: [Réservations]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
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
 *               - status
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [confirmed, cancelled, completed]
 *               reason:
 *                 type: string
 *     responses:
 *       200:
 *         description: Statut mis à jour
 *       400:
 *         description: Transition de statut invalide — règle métier (confirmed requiert paymentStatus=paid)
 *       401:
 *         description: Non autorisé
 *       404:
 *         description: Réservation non trouvée
 *
 * /api/reservations/{id}/cancel:
 *   patch:
 *     summary: Annuler une réservation
 *     tags: [Réservations]
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
 *         description: Réservation annulée
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   $ref: '#/components/schemas/Reservation'
 *                 refundAmount:
 *                   type: number
 *       400:
 *         description: Annulation non autorisée
 *       401:
 *         description: Non autorisé
 *       404:
 *         description: Réservation non trouvée
 */

/**
 * @swagger
 * /api/reservations/{id}/approve:
 *   patch:
 *     summary: Approuver une réservation (partenaire — mode approval_required)
 *     tags: [Réservations]
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
 *         description: Réservation approuvée — statut passe à payment_pending
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux partenaires
 *       404:
 *         description: Réservation non trouvée
 *
 * /api/reservations/{id}/reject:
 *   patch:
 *     summary: Rejeter une réservation (partenaire — mode approval_required)
 *     tags: [Réservations]
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
 *         description: Réservation rejetée — statut passe à cancelled
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux partenaires
 *       404:
 *         description: Réservation non trouvée
 *
 * /api/reservations/{id}/checkin:
 *   patch:
 *     summary: Check-in séjour (partenaire uniquement)
 *     description: |
 *       Transition canonique confirmed → in_stay via ReservationStateService.
 *       QR verification planned for P2-05C — not enforced in P2-05B.
 *     tags: [Réservations]
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
 *         description: Check-in effectué — statut passe à in_stay
 *       400:
 *         description: Trop tôt, paiement manquant ou transition invalide
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux partenaires / ownership
 *       404:
 *         description: Réservation non trouvée
 *       409:
 *         description: Modification concurrente
 *
 * /api/reservations/{id}/checkout:
 *   patch:
 *     summary: Check-out séjour (partenaire uniquement)
 *     description: |
 *       Transition canonique in_stay → completed via ReservationStateService.
 *       QR verification planned for P2-05C — not enforced in P2-05B.
 *     tags: [Réservations]
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
 *         description: Check-out effectué — statut passe à completed
 *       400:
 *         description: Check-in requis ou transition invalide
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux partenaires / ownership
 *       404:
 *         description: Réservation non trouvée
 *       409:
 *         description: Modification concurrente
 */

/**
 * @swagger
 * /api/reservations/{id}/check-availability:
 *   get:
 *     summary: Vérifier la disponibilité pour une modification
 *     tags: [Réservations]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: checkIn
 *         required: true
 *         schema:
 *           type: string
 *           format: date
 *       - in: query
 *         name: checkOut
 *         required: true
 *         schema:
 *           type: string
 *           format: date
 *     responses:
 *       200:
 *         description: Résultat de la vérification
 *       401:
 *         description: Non autorisé
 *       404:
 *         description: Réservation non trouvée
 *
 * /api/reservations/{id}/modification-fees:
 *   post:
 *     summary: Calculer les frais de modification
 *     tags: [Réservations]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               checkIn:
 *                 type: string
 *                 format: date
 *               checkOut:
 *                 type: string
 *                 format: date
 *     responses:
 *       200:
 *         description: Frais de modification calculés
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
 *                     modificationFee:
 *                       type: number
 *                     newTotalPrice:
 *                       type: number
 *       401:
 *         description: Non autorisé
 *       404:
 *         description: Réservation non trouvée
 */

// Ce fichier sert uniquement à documenter les endpoints pour Swagger
// Il n'exporte rien car il est uniquement lu par swagger-jsdoc
