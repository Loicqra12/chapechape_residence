const socketIO = require('socket.io');
const Reservation = require('../models/reservation.model');
const DateService = require('./date.service');

let io;

class SocketService {
    static initialize(server) {
        if (io) return io;

        io = socketIO(server, {
            cors: {
                origin: process.env.FRONTEND_URL || "*",
                methods: ["GET", "POST"]
            }
        });

        io.on('connection', (socket) => {
            console.log('Client connected:', socket.id);

            socket.on('join_residence', (residenceId) => {
                socket.join(`residence_${residenceId}`);
                console.log(`Client ${socket.id} joined residence_${residenceId}`);
            });

            socket.on('leave_residence', (residenceId) => {
                socket.leave(`residence_${residenceId}`);
                console.log(`Client ${socket.id} left residence_${residenceId}`);
            });

            socket.on('disconnect', () => {
                console.log('Client disconnected:', socket.id);
            });
        });

        return io;
    }

    static async notifyBlockedDatesUpdate(residenceId) {
        if (!io) return;

        try {
            const reservations = await Reservation.find({
                residence: residenceId,
                status: 'confirmed',
                checkOut: { $gte: new Date() }
            });

            const blockedDates = reservations.flatMap(reservation => 
                DateService.getDatesInRange(reservation.checkIn, reservation.checkOut)
            );

            io.to(`residence_${residenceId}`).emit('blocked_dates_updated', {
                residenceId,
                blockedDates: blockedDates.map(date => date.toISOString())
            });
        } catch (error) {
            console.error('Error notifying blocked dates update:', error);
        }
    }

    static async notifyNewReservation(reservation) {
        if (!io) return;

        io.to(`residence_${reservation.residence}`).emit('new_reservation', {
            reservation: reservation.toObject()
        });
    }

    static async notifyReservationCancellation(reservation) {
        if (!io) return;

        io.to(`residence_${reservation.residence}`).emit('reservation_cancelled', {
            reservation: reservation.toObject()
        });
    }
}

module.exports = SocketService;
