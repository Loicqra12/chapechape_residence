/**
 * Version de l'application spécifique aux tests
 * Cette version utilise des mocks pour certains middlewares comme CSRF
 */

const express = require('express');
const mongoose = require('mongoose');
const logger = require('./utils/logger');
const { securityMiddleware, fileSecurityMiddleware } = require('./middlewares/security.middleware');
// Utilisation du mock CSRF pour les tests
const { csrfMiddleware, generateCsrfToken } = require('./middlewares/csrf.mock');
const cache = require('./middlewares/cache.middleware');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');
const compression = require('compression');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const cookieParser = require('cookie-parser');
const swaggerUi = require('swagger-ui-express');
const swaggerSpecs = require('./config/swagger');

// Import des routes
const residenceRoutes = require('./routes/residence.routes');
const partnerRoutes = require('./routes/partner.routes');
const reservationRoutes = require('./routes/reservation.routes');
const favoriteRoutes = require('./routes/favorite.routes');
const userRoutes = require('./routes/user.routes');
const paymentRoutes = require('./routes/payment.routes');
const reviewRoutes = require('./routes/review.routes');
const notificationRoutes = require('./routes/notification.routes');
const messageRoutes = require('./routes/message.routes');
const authRoutes = require('./routes/auth.routes');
const adminRoutes = require('./routes/admin.routes');
const superAdminRoutes = require('./routes/superadmin.routes');
const availabilityRoutes = require('./routes/availability.routes');

const app = express();

// Sécurité (version réduite pour les tests)
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" },
  contentSecurityPolicy: false
}));

// CORS - simplifié pour les tests
app.use(cors({
    origin: '*',
    credentials: true,
    exposedHeaders: ['X-CSRF-Token']
}));

// Rate limiting désactivé pour les tests
const testLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 1000, // Limite beaucoup plus élevée pour les tests
    standardHeaders: true,
    legacyHeaders: false,
});
app.use(testLimiter);

// Middleware de sécurité
app.use(securityMiddleware);

// Middleware de logging - silencieux en test
app.use((req, res, next) => next());

// Middleware de base
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser(process.env.COOKIE_SECRET || 'chapechape-test-secret-key'));

// Compression
app.use(compression());

// Documentation API
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpecs));

// Génération de tokens CSRF pour les tests
app.use('/api/auth/login', generateCsrfToken);
app.use('/api/auth/register', generateCsrfToken);

// Mock des protections CSRF pour les routes sensibles
app.use('/api/bookings', csrfMiddleware);
app.use('/api/payments', csrfMiddleware);
app.use('/api/users', csrfMiddleware);
app.use('/api/residences', (req, res, next) => {
    if (['POST', 'PUT', 'DELETE', 'PATCH'].includes(req.method)) {
        csrfMiddleware(req, res, next);
    } else {
        next();
    }
});

// Endpoint pour obtenir un token CSRF pour les tests
app.get('/api/csrf-token', generateCsrfToken, (req, res) => {
    res.json({ csrfToken: res.locals.csrfToken });
});

// Servir les fichiers statiques
app.use('/uploads', express.static(path.join(__dirname, '../uploads'), {
  maxAge: '1d',
  etag: true,
}));

// Routes - Cache désactivé pour les tests
app.use('/api/residences', residenceRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/reservations', reservationRoutes);
app.use('/api/favorites', favoriteRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/partners', partnerRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/superadmin', superAdminRoutes);
app.use('/api/messages', messageRoutes); // Routes de messagerie
app.use('/api', availabilityRoutes); // Ajout des routes pour la gestion des disponibilités

// Middleware de sécurité pour les fichiers
app.use('/api/uploads', fileSecurityMiddleware);

// Route de test
app.get('/', (req, res) => {
    res.json({ message: 'Bienvenue sur l\'API ChapeChape Test' });
});

// Gestion des erreurs - Simplifiée pour les tests
app.use((err, req, res, next) => {
    console.error('Test Error:', err.message);
    
    let statusCode = err.statusCode || 500;
    
    res.status(statusCode).json({
        success: false,
        message: err.message || 'Une erreur est survenue',
        status: err.status || 'error',
        ...(err.errors && { errors: err.errors }),
        ...(err.errorCode && { errorCode: err.errorCode })
    });
});

// Gestion des routes non trouvées
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Route non trouvée'
    });
});

module.exports = app;
