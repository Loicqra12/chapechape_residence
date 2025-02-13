const Residence = require('../models/residence.model');
const Reservation = require('../models/reservation.model');

class AvailabilityService {
    // Vérifier la disponibilité d'une résidence pour des dates données
    async checkAvailability(residenceId, startDate, endDate) {
        const start = new Date(startDate);
        const end = new Date(endDate);

        // Vérifier les réservations existantes
        const existingReservations = await Reservation.find({
            residence: residenceId,
            status: { $in: ['pending', 'confirmed'] },
            $or: [
                {
                    checkIn: { $lte: end },
                    checkOut: { $gte: start }
                }
            ]
        });

        // Vérifier les dates bloquées
        const residence = await Residence.findById(residenceId);
        const blockedDates = residence.blockedDates || [];

        // Vérifier si une date dans la plage est bloquée
        const isDateBlocked = blockedDates.some(date => {
            const blockedDate = new Date(date);
            return blockedDate >= start && blockedDate <= end;
        });

        return {
            available: existingReservations.length === 0 && !isDateBlocked,
            existingReservations,
            blockedDates: blockedDates.filter(date => {
                const blockedDate = new Date(date);
                return blockedDate >= start && blockedDate <= end;
            })
        };
    }

    // Bloquer des dates pour une résidence
    async blockDates(residenceId, { startDate, endDate }) {
        const residence = await Residence.findById(residenceId);
        
        if (!residence) {
            throw new Error('Résidence non trouvée');
        }

        const start = new Date(startDate);
        const end = new Date(endDate);
        const dates = [];

        // Générer toutes les dates entre startDate et endDate
        for (let date = new Date(start); date <= end; date.setDate(date.getDate() + 1)) {
            dates.push(new Date(date));
        }

        // Vérifier les réservations existantes
        for (const date of dates) {
            const existingReservation = await Reservation.findOne({
                residence: residenceId,
                status: { $in: ['pending', 'confirmed'] },
                checkIn: { $lte: date },
                checkOut: { $gte: date }
            });

            if (existingReservation) {
                throw new Error(`Il existe déjà une réservation pour la date ${date.toISOString().split('T')[0]}`);
            }
        }

        // Ajouter les nouvelles dates aux dates bloquées existantes
        residence.blockedDates = [...(residence.blockedDates || []), ...dates];
        
        // Supprimer les doublons et trier
        residence.blockedDates = [...new Set(residence.blockedDates.map(date => 
            date.toISOString().split('T')[0]
        ))].sort().map(date => new Date(date));

        await residence.save();
        return residence;
    }

    // Débloquer des dates pour une résidence
    async unblockDates(residenceId, { startDate, endDate }) {
        const residence = await Residence.findById(residenceId);
        
        if (!residence) {
            throw new Error('Résidence non trouvée');
        }

        const start = new Date(startDate);
        const end = new Date(endDate);

        // Filtrer les dates bloquées
        residence.blockedDates = (residence.blockedDates || []).filter(date => {
            const blockedDate = new Date(date);
            return blockedDate < start || blockedDate > end;
        });

        await residence.save();
        return residence;
    }

    // Obtenir toutes les dates bloquées pour une résidence
    async getBlockedDates(residenceId) {
        const residence = await Residence.findById(residenceId);
        if (!residence) {
            throw new Error('Résidence non trouvée');
        }

        // Obtenir les réservations
        const reservations = await Reservation.find({
            residence: residenceId,
            status: { $in: ['pending', 'confirmed'] }
        });

        // Extraire toutes les dates réservées
        const reservedDates = [];
        for (const reservation of reservations) {
            const start = new Date(reservation.checkIn);
            const end = new Date(reservation.checkOut);
            
            for (let date = new Date(start); date <= end; date.setDate(date.getDate() + 1)) {
                reservedDates.push(new Date(date));
            }
        }

        return {
            blockedDates: residence.blockedDates || [],
            reservedDates: reservedDates
        };
    }
}

module.exports = new AvailabilityService();
