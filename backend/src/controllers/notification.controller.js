const asyncHandler = require('../middlewares/async.middleware');
const notificationService = require('../services/notification.service');
const twilioService = require('../services/twilio.service');
const { NOTIFICATION_TYPES } = require('../utils/constants');
const Reservation = require('../models/reservation.model'); // ✅ MIGRÉ - était Booking
const apiError = require('../utils/apiError');

// @desc    Get user notifications
// @route   GET /api/notifications
// @access  Private
exports.getNotifications = asyncHandler(async (req, res) => {
    const { page, limit } = req.query;
    const result = await notificationService.getUserNotifications(req.user.id, page, limit);
    
    res.status(200).json({
        success: true,
        ...result
    });
});

// @desc    Mark notification as read
// @route   PUT /api/notifications/:id/read
// @access  Private
exports.markAsRead = asyncHandler(async (req, res) => {
    const notification = await notificationService.markAsRead(req.params.id, req.user.id);
    
    if (!notification) {
        return res.status(404).json({
            success: false,
            message: 'Notification non trouvée'
        });
    }
    
    res.status(200).json({
        success: true,
        data: notification
    });
});

// @desc    Mark all notifications as read
// @route   PUT /api/notifications/read-all
// @access  Private
exports.markAllAsRead = asyncHandler(async (req, res) => {
    await notificationService.markAllAsRead(req.user.id);
    
    res.status(200).json({
        success: true,
        message: 'Toutes les notifications ont été marquées comme lues'
    });
});

// @desc    Delete notification
// @route   DELETE /api/notifications/:id
// @access  Private
exports.deleteNotification = asyncHandler(async (req, res) => {
    const notification = await notificationService.deleteNotification(req.params.id, req.user.id);
    
    if (!notification) {
        return res.status(404).json({
            success: false,
            message: 'Notification non trouvée'
        });
    }
    
    res.status(200).json({
        success: true,
        data: {}
    });
});

// @desc    Delete all read notifications
// @route   DELETE /api/notifications/read
// @access  Private
exports.deleteReadNotifications = asyncHandler(async (req, res) => {
    await notificationService.deleteReadNotifications(req.user.id);
    
    res.status(200).json({
        success: true,
        message: 'Toutes les notifications lues ont été supprimées'
    });
});

// @desc    Get unread notifications count
// @route   GET /api/notifications/unread/count
// @access  Private
exports.getUnreadCount = asyncHandler(async (req, res) => {
    const count = await notificationService.countUnreadNotifications(req.user.id);
    
    res.status(200).json({
        success: true,
        data: {
            count
        }
    });
});
