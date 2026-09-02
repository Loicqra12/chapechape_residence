const winston = require('winston');
require('winston-daily-rotate-file');
const path = require('path');
const morgan = require('morgan');
const { getRequestContext } = require('../observability/request-context');

const SENSITIVE_FIELDS = [
    'password', 'token', 'auth', 'secret', 'key', 'private', 'credential',
    'api_key', 'apikey', 'authorization', 'bearer', 'jwt', 'session',
    'cookie', 'csrf', 'otp', 'pin', 'ssn', 'credit_card', 'card_number',
    'cvv', 'expiry', 'bank_account', 'stripe_secret', 'paypal_secret',
    'oauth_secret', 'client_secret', 'refresh_token', 'access_token',
    'mongo_uri', 'database_url', 'db_password', 'smtp_password',
    'twilio_auth_token', 'brevo_api_key', 'cloudinary_secret',
    'onesignal_key', 'google_api_key', 'firebase_private_key'
];

const EMAIL_KEY_RE = /(^|_)(email|e-mail)$|^email$|emailaddress|useremail/;
const PHONE_KEY_RE = /(phone|telephone|mobile|whatsapp|msisdn)/;
const EMAIL_IN_TEXT_RE = /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g;

function maskEmail(value) {
    if (typeof value !== 'string' || !value.includes('@')) return value;
    const [local, domain] = value.split('@');
    if (!domain) return value;
    const keep = local.slice(0, Math.min(2, local.length));
    return `${keep}***@${domain}`;
}

function maskPhone(value) {
    if (typeof value !== 'string') return value;
    const prefix = value.trim().startsWith('+') ? '+' : '';
    const digits = value.replace(/\D/g, '');
    if (digits.length < 8) {
        return `${prefix}${digits.slice(0, 2)}****`;
    }
    const head = digits.slice(0, 5);
    const tail = digits.slice(-2);
    return `${prefix}${head}******${tail}`;
}

function maskEmailsInString(str) {
    return str.replace(EMAIL_IN_TEXT_RE, (match) => maskEmail(match));
}

function isEmailKey(lowerKey) {
    return EMAIL_KEY_RE.test(lowerKey);
}

function isPhoneKey(lowerKey) {
    return PHONE_KEY_RE.test(lowerKey);
}

function sanitizeObject(obj, depth = 0) {
    if (depth > 10) return '[CIRCULAR]';

    if (obj === null || obj === undefined) return obj;

    if (typeof obj === 'string') {
        const maskedSecrets = obj.replace(/(password|token|secret|key|auth)\s*[=:]\s*[^\s&,]+/gi, '$1=***MASKED***');
        return maskEmailsInString(maskedSecrets);
    }

    if (typeof obj !== 'object') return obj;

    if (Array.isArray(obj)) {
        return obj.map(item => sanitizeObject(item, depth + 1));
    }

    const sanitized = {};
    for (const [key, value] of Object.entries(obj)) {
        const lowerKey = key.toLowerCase();
        const isSensitive = SENSITIVE_FIELDS.some(field => lowerKey.includes(field));

        if (isSensitive) {
            sanitized[key] = '***MASKED***';
        } else if (isEmailKey(lowerKey) && typeof value === 'string') {
            sanitized[key] = maskEmail(value);
        } else if (isPhoneKey(lowerKey) && typeof value === 'string') {
            sanitized[key] = maskPhone(value);
        } else {
            sanitized[key] = sanitizeObject(value, depth + 1);
        }
    }

    return sanitized;
}

const sanitizeFormat = winston.format((info) => {
    if (typeof info.message === 'object') {
        info.message = sanitizeObject(info.message);
    } else if (typeof info.message === 'string') {
        info.message = sanitizeObject(info.message);
    }

    Object.keys(info).forEach(key => {
        if (key !== 'level' && key !== 'timestamp') {
            info[key] = sanitizeObject(info[key]);
        }
    });

    return info;
});

const logDir = path.join(__dirname, '../../logs');

const formats = [
    winston.format.timestamp(),
    sanitizeFormat(),
    winston.format.json()
];

const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: winston.format.combine(...formats),
    transports: [
        new winston.transports.DailyRotateFile({
            filename: path.join(logDir, '%DATE%-error.log'),
            datePattern: 'YYYY-MM-DD',
            zippedArchive: true,
            maxSize: '20m',
            maxFiles: '14d',
            level: 'error'
        }),
        new winston.transports.DailyRotateFile({
            filename: path.join(logDir, '%DATE%-combined.log'),
            datePattern: 'YYYY-MM-DD',
            zippedArchive: true,
            maxSize: '20m',
            maxFiles: '14d'
        })
    ]
});

if (process.env.NODE_ENV !== 'production') {
    logger.add(new winston.transports.Console({
        format: winston.format.combine(
            winston.format.colorize(),
            winston.format.simple()
        )
    }));
}

function mergeContext(meta) {
    const ctx = getRequestContext();
    if (!ctx) return meta;
    if (meta && typeof meta === 'object' && !Array.isArray(meta)) {
        return { ...ctx, ...meta };
    }
    return { ...ctx };
}

function wrapLevel(level) {
    return (message, meta, ...rest) => {
        const ctx = getRequestContext();
        if (!ctx) {
            return logger[level](message, meta, ...rest);
        }
        if (rest.length > 0) {
            return logger[level](message, meta, ...rest);
        }
        if (meta === undefined) {
            return logger[level](message, mergeContext({}));
        }
        if (typeof meta === 'object' && meta !== null && !Array.isArray(meta)) {
            return logger[level](message, mergeContext(meta));
        }
        return logger[level](message, meta);
    };
}

/** API unique — http stream + helpers passent par les mêmes méthodes (spy / ALS). */
const api = {
    error: wrapLevel('error'),
    warn: wrapLevel('warn'),
    info: wrapLevel('info'),
    debug: wrapLevel('debug'),
};

const stream = {
    write: (message) => {
        api.info(message.trim());
    }
};

const httpLogger = morgan('combined', { stream });
logger.http = httpLogger;
api.http = httpLogger;

api.logPerformance = (operation, duration, details = {}) => {
    api.info('Performance Metric', {
        type: 'performance',
        operation,
        duration,
        ...details
    });
};

api.logUserAction = (userId, action, details = {}) => {
    api.info('User Action', {
        type: 'user_action',
        userId,
        action,
        ...details
    });
};

api.logSecurityEvent = (type, details = {}) => {
    api.warn('Security Event', {
        type: 'security',
        securityType: type,
        ...details
    });
};

api.logSystemEvent = (type, details = {}) => {
    api.info('System Event', {
        type: 'system',
        systemType: type,
        ...details
    });
};

api.sanitizeObject = sanitizeObject;
api.maskEmail = maskEmail;
api.maskPhone = maskPhone;
api.attachRequestContext = (meta) => mergeContext(meta && typeof meta === 'object' ? meta : {});

module.exports = api;
