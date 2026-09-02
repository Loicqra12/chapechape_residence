// Rôles utilisateur
exports.USER_ROLES = {
    USER: 'user',
    PARTNER: 'partner',
    ADMIN: 'admin',
    SUPER_ADMIN: 'super_admin'
};

const {
    RESERVATION_STATUS,
    ACTIVE_BLOCKING_STATUSES,
    TERMINAL_STATUSES,
    normalizeReservationStatusInput,
} = require('../constants/reservation-status');

// Source unique — BOOKING_STATUS n'est plus un enum diverging.
exports.RESERVATION_STATUS = RESERVATION_STATUS;
exports.BOOKING_STATUS = RESERVATION_STATUS;
exports.ACTIVE_BLOCKING_STATUSES = ACTIVE_BLOCKING_STATUSES;
exports.TERMINAL_STATUSES = TERMINAL_STATUSES;
exports.normalizeReservationStatusInput = normalizeReservationStatusInput;

// Statuts de paiement (harmonisés) — distincts de Reservation.status
exports.PAYMENT_STATUS = {
    PENDING: 'pending',
    PAID: 'paid',        // ✅ HARMONISÉ - était 'completed'
    FAILED: 'failed',
    CANCELLED: 'cancelled',
    REFUNDED: 'refunded'
};

// Méthodes de paiement
exports.PAYMENT_METHODS = {
    CARD: 'card',
    PAYPAL: 'paypal',
    MOBILE_MONEY: 'mobile_money'
};

// Types de notifications
// Types de médias
exports.MEDIA_TYPES = {
    IMAGE: 'image',
    VIDEO: 'video',
    DOCUMENT: 'document'
};

// Limites et configurations
exports.LIMITS = {
    MAX_IMAGES_PER_RESIDENCE: 10,
    MAX_FILE_SIZE: 5 * 1024 * 1024, // 5MB
    ITEMS_PER_PAGE: 10,
    MAX_DESCRIPTION_LENGTH: 1000,
    MIN_PASSWORD_LENGTH: 6
};

// Messages d'erreur
exports.ERROR_MESSAGES = {
    NOT_FOUND: 'Resource not found',
    UNAUTHORIZED: 'Unauthorized access',
    VALIDATION_ERROR: 'Validation error',
    SERVER_ERROR: 'Internal server error',
    DUPLICATE_EMAIL: 'Email already exists',
    INVALID_CREDENTIALS: 'Invalid credentials',
    INVALID_TOKEN: 'Invalid or expired token'
};

// Messages de succès
exports.SUCCESS_MESSAGES = {
    CREATED: 'Resource created successfully',
    UPDATED: 'Resource updated successfully',
    DELETED: 'Resource deleted successfully',
    PASSWORD_RESET: 'Password reset successfully'
};

// Configurations des emails
exports.EMAIL_TEMPLATES = {
    WELCOME: 'welcome',
    BOOKING_CONFIRMATION: 'booking_confirmation',
    PASSWORD_RESET: 'password_reset',
    BOOKING_CANCELLATION: 'booking_cancellation'
};

// Configurations de sécurité
exports.SECURITY = {
    JWT_EXPIRES_IN: '7d',
    JWT_COOKIE_EXPIRES_IN: 7,
    PASSWORD_RESET_EXPIRES_IN: 10 * 60 * 1000, // 10 minutes
    MAX_LOGIN_ATTEMPTS: 5,
    BLOCK_DURATION: 15 * 60 * 1000 // 15 minutes
};

// Statuts HTTP
exports.HTTP_STATUS = {
    OK: 200,
    CREATED: 201,
    BAD_REQUEST: 400,
    UNAUTHORIZED: 401,
    FORBIDDEN: 403,
    NOT_FOUND: 404,
    CONFLICT: 409,
    SERVER_ERROR: 500
};

// Regex patterns
exports.PATTERNS = {
    EMAIL: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
    PHONE: /^[0-9+\s-]{8,}$/,
    PASSWORD: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{6,}$/
};

// Configurations des uploads
exports.UPLOAD_CONFIG = {
    ALLOWED_FORMATS: ['image/jpeg', 'image/png', 'image/webp'],
    IMAGE_SIZES: {
        thumbnail: { width: 150, height: 150 },
        medium: { width: 500, height: 500 },
        large: { width: 1024, height: 1024 }
    }
};
