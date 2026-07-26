const mongoose = require('mongoose');
const Availability = require('../models/availability.model');
const Residence = require('../models/residence.model');
const ApiError = require('../utils/apiError');
const Reservation = require('../models/reservation.model');
const moment = require('moment');
const logger = require('../utils/logger');

class AvailabilityService {
    // Vérifier la disponibilité d'une résidence pour des dates données
    async checkAvailability(residenceId, startDate, endDate, bookingType = 'day') {
        const start = new Date(startDate);
        const end = new Date(endDate);

        if (start >= end) {
            throw new ApiError('La date de départ doit être ultérieure à la date d\'arrivée', 400);
        }

        try {
            const residence = await Residence.findById(residenceId);
            if (!residence) {
                throw new ApiError('Résidence non trouvée', 404);
            }

            // ✅ CORRECTION RÉSERVATIONS HORAIRES : Vérification temporelle précise pour les heures
            if (bookingType === 'hour') {
                console.log(`[Availability] Vérification horaire pour ${residenceId}: ${start.toISOString()} → ${end.toISOString()}`);

                // Chercher les réservations qui chevauchent cette période temporelle
                const conflictingReservations = await Reservation.find({
                    residence: residenceId,
                    status: { $in: ['confirmed', 'pending', 'payment_pending', 'awaiting_approval'] },
                    $or: [
                        {
                            // Cas 1: Réservation existante chevauche le début de la période demandée
                            checkIn: { $lt: end },
                            checkOut: { $gt: start }
                        }
                    ]
                });

                // Vérifier aussi si la journée entière est bloquée manuellement par le partenaire
                const dayStart = new Date(start);
                dayStart.setHours(0, 0, 0, 0);
                const dayEnd = new Date(start);
                dayEnd.setHours(23, 59, 59, 999);

                const dayBlocked = await Availability.findOne({
                    residenceId,
                    date: { $gte: dayStart, $lte: dayEnd },
                    status: 'blocked'
                });

                const isAvailable = conflictingReservations.length === 0 && !dayBlocked;

                console.log(`[Availability] Résultat horaire: ${isAvailable ? 'Disponible' : 'Indisponible'} (${conflictingReservations.length} conflits, bloc manuel: ${!!dayBlocked})`);

                return {
                    available: isAvailable,
                    existingReservations: conflictingReservations,
                    blockedDates: dayBlocked ? [dayBlocked.date] : [],
                    availabilities: [],
                    bookingType: 'hour'
                };
            }

            // Logique existante pour les réservations journalières/hebdomadaires/mensuelles
            const availabilities = await Availability.findForPeriod(residenceId, start, end);

            // Si aucune disponibilité n'est configurée, vérifier avec l'ancienne méthode
            if (availabilities.length === 0) {
                // Vérifier les réservations existantes
                const existingReservations = await Reservation.find({
                    residence: residenceId,
                    status: { $in: ['confirmed', 'pending', 'payment_pending'] },
                    $or: [
                        {
                            checkIn: { $lte: end },
                            checkOut: { $gte: start }
                        }
                    ]
                });

                // Vérifier si la date est bloquée par l'hôte
                const isDateBlocked = residence.blockedDates?.some(blockedDate => {
                    const blocked = new Date(blockedDate);
                    return blocked >= start && blocked <= end;
                });

                return {
                    available: existingReservations.length === 0 && !isDateBlocked,
                    existingReservations,
                    blockedDates: isDateBlocked ? residence.blockedDates : [],
                    availabilities: []
                };
            }

            // Avec le nouveau système, vérifier chaque jour de la période
            const unavailableDates = availabilities.filter(a => a.status !== 'available').map(a => a.date);

            // Compter le nombre de jours à vérifier
            const daysCount = moment(end).diff(moment(start), 'days');
            const requiredAvailabilities = daysCount + 1;

            // Vérifier si toutes les dates ont un statut disponible
            const availableCount = availabilities.filter(a => a.status === 'available').length;

            // Vérifier les règles de séjour minimum
            const minStayRule = availabilities.reduce((max, a) =>
                a.rules && a.rules.minStay ? Math.max(max, a.rules.minStay) : max, 1);

            // Vérifier les règles de check-in/check-out
            const startDateAvailability = availabilities.find(a =>
                moment(a.date).isSame(moment(start), 'day'));
            const endDateAvailability = availabilities.find(a =>
                moment(a.date).isSame(moment(end).subtract(1, 'day'), 'day'));

            const checkInAllowed = !startDateAvailability ||
                !startDateAvailability.rules ||
                startDateAvailability.rules.checkInAllowed !== false;

            const checkOutAllowed = !endDateAvailability ||
                !endDateAvailability.rules ||
                endDateAvailability.rules.checkOutAllowed !== false;

            // Calculer le prix total pour cette période
            const priceDetails = this._calculatePriceDetails(availabilities, start, end);

            return {
                available: unavailableDates.length === 0 && checkInAllowed && checkOutAllowed && daysCount >= minStayRule,
                unavailableDates,
                priceDetails,
                rules: {
                    minStay: minStayRule,
                    checkInAllowed,
                    checkOutAllowed
                }
            };
        } catch (error) {
            if (error instanceof ApiError) throw error;
            throw new ApiError('Erreur lors de la vérification de disponibilité', 500);
        }
    }

    // Calculer les détails de prix pour une période
    _calculatePriceDetails(availabilities, startDate, endDate) {
        const start = moment(startDate);
        const end = moment(endDate);
        const nights = end.diff(start, 'days');

        let baseTotal = 0;
        let discountTotal = 0;
        const dailyPrices = [];

        // Pour chaque jour de la période
        for (let day = 0; day < nights; day++) {
            const currentDate = moment(startDate).add(day, 'days');
            const availability = availabilities.find(a =>
                moment(a.date).isSame(currentDate, 'day'));

            if (availability && availability.price) {
                const basePrice = availability.price;
                baseTotal += basePrice;

                const finalPrice = availability.getFinalPrice() || basePrice;
                const discount = basePrice - finalPrice;
                discountTotal += discount;

                dailyPrices.push({
                    date: currentDate.toISOString(),
                    basePrice,
                    finalPrice,
                    discount: discount > 0 ? {
                        amount: discount,
                        percentage: availability.promotion?.discountPercentage,
                        description: availability.promotion?.description
                    } : null
                });
            }
        }

        return {
            totalNights: nights,
            baseTotal,
            discountTotal,
            finalTotal: baseTotal - discountTotal,
            dailyPrices
        };
    }

    // Obtenir les disponibilités d'une résidence pour une période
    async getAvailabilities(residenceId, startDate, endDate) {
        try {
            const start = new Date(startDate);
            const end = new Date(endDate);

            // Vérifier si la résidence existe
            const residence = await Residence.findById(residenceId);
            if (!residence) {
                throw new ApiError('Résidence non trouvée', 404);
            }

            // Récupérer les disponibilités
            const availabilities = await Availability.findForPeriod(residenceId, start, end);

            // Si aucune disponibilité n'est configurée, générer des disponibilités par défaut
            if (availabilities.length === 0) {
                const defaultAvailabilities = [];
                const currentDate = moment(start);
                const endDateMoment = moment(end);

                while (currentDate.isSameOrBefore(endDateMoment, 'day')) {
                    // Vérifier si la date est bloquée dans l'ancien système
                    const isBlocked = (residence.blockedDates || []).some(date =>
                        moment(date).isSame(currentDate, 'day'));

                    // Vérifier s'il existe une réservation pour cette date
                    const existingReservation = await Reservation.findOne({
                        residence: residenceId,
                        status: { $in: ['pending', 'confirmed'] },
                        checkIn: { $lte: currentDate.toDate() },
                        checkOut: { $gt: currentDate.toDate() }
                    });

                    defaultAvailabilities.push({
                        date: currentDate.toDate(),
                        residenceId,
                        status: existingReservation ? 'reserved' : (isBlocked ? 'blocked' : 'available'),
                        price: residence.price,
                        reservationId: existingReservation?._id
                    });

                    currentDate.add(1, 'day');
                }

                return defaultAvailabilities;
            }

            return availabilities;
        } catch (error) {
            if (error instanceof ApiError) throw error;
            throw new ApiError('Erreur lors de la récupération des disponibilités', 500);
        }
    }

    // Mettre à jour les disponibilités d'une résidence sur une plage de dates
    async updateAvailabilities(residenceId, startDate, endDate, data) {
        try {
            const start = moment(startDate);
            const end = moment(endDate);

            // Vérifier si la résidence existe
            const residence = await Residence.findById(residenceId);
            if (!residence) {
                throw new ApiError('Résidence non trouvée', 404);
            }

            // Vérifier s'il existe des réservations pendant cette période
            const existingReservations = await Reservation.find({
                residence: residenceId,
                status: { $in: ['pending', 'confirmed'] },
                $or: [
                    {
                        checkIn: { $lte: end.toDate() },
                        checkOut: { $gte: start.toDate() }
                    }
                ]
            });

            // Créer les enregistrements à mettre à jour
            const records = [];
            const currentDate = moment(start);

            while (currentDate.isSameOrBefore(end, 'day')) {
                const dayDate = currentDate.toDate();

                // Vérifier si ce jour est déjà réservé
                const isReserved = existingReservations.some(reservation => {
                    const resStart = moment(reservation.checkIn);
                    const resEnd = moment(reservation.checkOut);
                    return currentDate.isSameOrAfter(resStart, 'day') &&
                        currentDate.isBefore(resEnd, 'day');
                });

                // Ne pas permettre de changer le statut si déjà réservé
                if (!isReserved || data.status !== 'available') {
                    records.push({
                        residenceId,
                        date: dayDate,
                        ...data,
                        status: isReserved ? 'reserved' : data.status,
                        // Préserver le reservationId si la date est réservée
                        reservationId: isReserved ?
                            existingReservations.find(reservation => {
                                const resStart = moment(reservation.checkIn);
                                const resEnd = moment(reservation.checkOut);
                                return currentDate.isSameOrAfter(resStart, 'day') &&
                                    currentDate.isBefore(resEnd, 'day');
                            })?._id : undefined
                    });
                }

                currentDate.add(1, 'day');
            }

            // Mettre à jour les disponibilités
            if (records.length > 0) {
                await Availability.upsertBulk(records);
            }

            // Récupérer et retourner les disponibilités mises à jour
            return this.getAvailabilities(residenceId, startDate, endDate);
        } catch (error) {
            if (error instanceof ApiError) throw error;
            throw new ApiError('Erreur lors de la mise à jour des disponibilités', 500);
        }
    }

    // Vérifier si une mise à jour de réservation est possible
    async checkBookingModification(bookingId, newStartDate, newEndDate) {
        try {
            const booking = await Reservation.findById(bookingId);
            if (!booking) {
                throw new ApiError('Réservation non trouvée', 404);
            }

            const residenceId = booking.residence;
            const start = new Date(newStartDate);
            const end = new Date(newEndDate);

            // Vérifier la disponibilité pour les nouvelles dates (en excluant cette réservation)
            const existingReservations = await Reservation.find({
                _id: { $ne: bookingId },
                residence: residenceId,
                status: { $in: ['pending', 'confirmed'] },
                $or: [
                    {
                        checkIn: { $lte: end },
                        checkOut: { $gte: start }
                    }
                ]
            });

            // Vérifier les disponibilités avec le nouveau système
            const availabilities = await Availability.findForPeriod(residenceId, start, end);

            // Exclure les dates marquées comme 'reserved' par cette réservation
            const unavailableDates = availabilities.filter(a =>
                a.status !== 'available' &&
                (!a.reservationId || !a.reservationId.equals(booking._id))
            ).map(a => a.date);

            return {
                modificationPossible: existingReservations.length === 0 && unavailableDates.length === 0,
                conflictingReservations: existingReservations,
                unavailableDates
            };
        } catch (error) {
            if (error instanceof ApiError) throw error;
            throw new ApiError('Erreur lors de la vérification de modification', 500);
        }
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

    /**
     * Met à jour les disponibilités pour une réservation.
     * Signature stable (utilisée par reservation.service, payment-timer, controller) :
     * (residenceId, startDate, endDate, reservationId, status = 'reserved', bookingType = 'day')
     *
     * - bookingType === 'hour' : no-op (conflits gérés via collection Reservation)
     * - checkOut exclusif (convention hôtel) : [checkIn, checkOut)
     * - champ modèle : residenceId (pas residence)
     */
    async updateAvailabilityForReservation(residenceId, startDate, endDate, reservationId, status = 'reserved', bookingType = 'day', session = null) {
        if (!residenceId || !startDate || !endDate || !reservationId) {
            throw new Error('Paramètres insuffisants pour mise à jour disponibilité');
        }

        // Réservations horaires : pas de blocage jour par jour
        if (bookingType === 'hour') {
            logger.info(`[Availability] Réservation horaire ${reservationId} — pas de blocage disponibilité`);
            return { acknowledged: true, message: 'Hourly booking - no availability block', modifiedCount: 0 };
        }

        const start = new Date(startDate);
        const end = new Date(endDate);

        if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime()) || start >= end) {
            throw new Error('Date de départ doit être ultérieure à la date d\'arrivée');
        }

        let residenceQuery = require('../models/residence.model').findById(residenceId).select('_id');
        if (session) residenceQuery = residenceQuery.session(session);
        const residence = await residenceQuery;
        if (!residence) {
            throw new Error(`Résidence ${residenceId} non trouvée`);
        }

        const dates = [];
        const currentDate = new Date(start);

        // checkOut exclusif : une nuit du 1 au 2 bloque uniquement le 1er
        while (currentDate < end) {
            dates.push({
                residenceId,
                date: new Date(currentDate),
                status,
                reservationId: status === 'reserved' ? reservationId : null,
                lastModified: new Date()
            });
            currentDate.setDate(currentDate.getDate() + 1);
        }

        if (dates.length === 0) {
            return { acknowledged: true, message: 'Aucune date à mettre à jour', modifiedCount: 0 };
        }

        try {
            const result = await Availability.upsertBulk(dates, {
                session,
                failIfReservedByOther: status === 'reserved',
            });
            logger.info(`Disponibilité mise à jour pour réservation ${reservationId}: ${dates.length} dates → ${status}`);
            return result;
        } catch (err) {
            // Course concurrente : index unique residenceId+date ou filtre anti-écrasement
            if (err?.code === 11000 || err?.code === 11001 || /E11000|duplicate/i.test(err?.message || '')) {
                const conflict = new Error('Ces dates viennent d\'être réservées par un autre client');
                conflict.statusCode = 409;
                throw conflict;
            }
            throw err;
        }
    }
}

module.exports = new AvailabilityService();
