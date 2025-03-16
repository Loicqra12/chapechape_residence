const express = require('express');
const mongoose = require('mongoose');
const logger = require('./utils/logger');
const { securityMiddleware, fileSecurityMiddleware } = require('./middlewares/security.middleware');
const cache = require('./middlewares/cache.middleware');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');
const compression = require('compression');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
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

const app = express();

// Sécurité
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" },
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "blob:", "http:", "https:"],
      connectSrc: ["'self'", "http:", "https:"],
    },
  },
}));

// CORS
app.use(cors());

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100 // limite chaque IP à 100 requêtes par fenêtre
});
app.use(limiter);

// Middleware de sécurité
app.use(securityMiddleware);

// Middleware de logging
app.use(logger.http);

// Middleware de base
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Compression
app.use(compression());

// Middlewares
app.use(morgan('dev'));

// Documentation API
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpecs));

// Servir les fichiers statiques
app.use('/uploads', express.static(path.join(__dirname, '../uploads'), {
  maxAge: '1d',
  etag: true,
}));

// Routes avec cache pour les requêtes GET
app.use('/api/residences', cache(3600), residenceRoutes);
app.use('/api/reviews', cache(1800), reviewRoutes);
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

// Middleware de sécurité pour les fichiers
app.use('/api/uploads', fileSecurityMiddleware);

// Route de test
app.get('/', (req, res) => {
    res.json({ message: 'Bienvenue sur l\'API ChapeChape' });
});

// Gestion des erreurs
app.use((err, req, res, next) => {
    logger.error('Error:', err);
    
    // Récupérer le code d'état numérique approprié
    let statusCode = 500;
    if (err.statusCode && typeof err.statusCode === 'number') {
        statusCode = err.statusCode;
    }
    
    res.status(statusCode).json({
        success: false,
        message: err.message || 'Une erreur est survenue',
        status: err.status || 'error',
        ...(process.env.NODE_ENV === 'development' && { 
            stack: err.stack,
            details: err 
        })
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
