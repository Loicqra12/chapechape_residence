const Reservation = require('../models/reservation.model');
const Payment = require('../models/payment.model');
const ApiError = require('../utils/apiError');
const logger = require('../utils/logger');
const errorCodes = require('../utils/errorCodes');

/**
 * Service de gestion des transitions d'état des réservations
 * Implémente une machine à états avec updates atomiques pour éviter les race conditions
 */
class ReservationStateService {
    
    /**
     * Statuts nécessitant un paiement complet
     */
    static PAYMENT_REQUIRED_STATUSES = ['confirmed', 'in_stay', 'completed'];

    /**
     * Effectue une transition d'état atomique avec validation
     * @param {string} reservationId - ID de la réservation
     * @param {string} newStatus - Nouveau statut
     * @param {string} userId - ID de l'utilisateur effectuant la transition
     * @param {Object} options - Options supplémentaires
     * @returns {Promise<Object>} - Réservation mise à jour
     */
    static async updateStatus(reservationId, newStatus, userId, options = {}) {
        const { reason = null } = options;

        logger.info(`Transition atomique: ${reservationId} -> ${newStatus}`, {
            userId,
            reason
        });

        // 1. Construire le filtre atomique avec conditions
        const atomicFilter = {
            _id: reservationId
        };

        // 2. Ajouter condition de paiement si nécessaire
        if (this.PAYMENT_REQUIRED_STATUSES.includes(newStatus)) {
            atomicFilter.paymentStatus = 'paid';
        }

        // 3. Préparer la mise à jour
        const updateData = {
            status: newStatus,
            $push: {
                statusHistory: {
                    newStatus: newStatus,
                    changedAt: new Date(),
                    changedBy: userId,
                    reason: reason
                }
            }
        };

        // Ajouter des champs spécifiques selon le statut
        if (newStatus === 'in_stay') {
            updateData.actualCheckIn = new Date();
        } else if (newStatus === 'completed') {
            updateData.actualCheckOut = new Date();
        } else if (newStatus === 'cancelled') {
            updateData.cancelledAt = new Date();
            updateData.cancellationReason = reason;
        }

        // 4. Effectuer l'update atomique
        const updatedReservation = await Reservation.findOneAndUpdate(
            atomicFilter,
            updateData,
            {
                new: true,
                runValidators: true,
                context: 'query'
            }
        ).populate(['residence', 'user', 'partner']);

        // 5. Vérifier le succès de l'opération atomique
        if (!updatedReservation) {
            // Diagnostiquer la cause de l'échec
            const currentReservation = await Reservation.findById(reservationId, 'status paymentStatus');
            
            if (!currentReservation) {
                throw new ApiError('Réservation non trouvée', 404, errorCodes.RESERVATION.NOT_FOUND);
            }

            // Échec dû aux conditions non remplies
            if (this.PAYMENT_REQUIRED_STATUSES.includes(newStatus) && currentReservation.paymentStatus !== 'paid') {
                throw new ApiError(
                    `Impossible de passer au statut ${newStatus} : paiement requis (statut actuel: ${currentReservation.paymentStatus})`,
                    400,
                    errorCodes.RESERVATION.PAYMENT_REQUIRED
                );
            }

            // Échec dû à une modification concurrente
            throw new ApiError(
                `Échec de la transition atomique vers ${newStatus}. État actuel: ${currentReservation.status}`,
                409,
                errorCodes.RESERVATION.CONCURRENT_MODIFICATION
            );
        }

        logger.info(`Transition réussie: ${updatedReservation.status}`, {
            reservationId,
            userId
        });

        return updatedReservation;
    }

    /**
     * Valide le statut de paiement depuis la source de vérité
     * @param {string} reservationId - ID de la réservation
     * @returns {Promise<string>} - Statut de paiement validé
     */
    static async validatePaymentStatus(reservationId) {
        // Récupérer le dernier paiement pour cette réservation
        const latestPayment = await Payment.findOne({ 
            reservation: reservationId 
        }).sort({ createdAt: -1 });

        if (!latestPayment) {
            return 'pending';
        }

        return latestPayment.status === 'completed' ? 'paid' : latestPayment.status;
    }
}

module.exports = ReservationStateService;
