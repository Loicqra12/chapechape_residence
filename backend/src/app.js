// Sentry est maintenant initialisé via instrument.js (importé dans server.js)

const express = require("express");
const mongoose = require("mongoose");
const logger = require("./utils/logger");
const {
  securityMiddleware,
  fileSecurityMiddleware,
} = require("./middlewares/security.middleware");
const {
  csrfMiddleware,
  generateCsrfToken,
} = require("./middlewares/csrf-custom.middleware");
const cache = require("./middlewares/cache.middleware");
const cors = require("cors");
const morgan = require("morgan");
const path = require("path");
const compression = require("compression");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const cookieParser = require("cookie-parser");
const swaggerUi = require("swagger-ui-express");
const swaggerSpecs = require("./config/swagger");

// Import des routes
const residenceRoutes = require("./routes/residence.routes");
const partnerRoutes = require("./routes/partner.routes");
const partnerVerificationRoutes = require("./routes/partner-verification.routes");
const reservationRoutes = require("./routes/reservation.routes");
const favoriteRoutes = require("./routes/favorite.routes");
const userRoutes = require("./routes/user.routes");
const payoutRoutes = require("./routes/payout.routes"); // ✅ RÉACTIVÉ
const pricingRoutes = require("./routes/pricing.routes");
const notificationRoutes = require("./routes/notification.routes");
const messageRoutes = require("./routes/message.routes");
const authRoutes = require("./routes/auth.routes");
// const blogRoutes = require("./routes/blog.routes"); // Temporairement désactivé pour diagnostic
const reviewRoutes = require("./routes/review.routes");
const paymentRoutes = require("./routes/payment.routes");
const adminRoutes = require("./routes/admin.routes");
const dashboardRoutes = require("./routes/dashboard.routes");
const superAdminRoutes = require("./routes/superadmin.routes");
const availabilityRoutes = require("./routes/availability.routes");
const promotionRoutes = require("./routes/promotion.routes");
const mapsRoutes = require("./routes/maps.routes"); // Import des routes Maps
// Import des routes de politique d'annulation
const cancellationPolicyRoutes = require("./routes/cancellationPolicy.routes");
// Import des routes de test
const testRoutes = require("./routes/test.routes");
// Import des routes de gestion des appareils
const deviceRoutes = require("./routes/device.routes");
// Import des routes SMS
const smsRoutes = require("./routes/sms.routes");
// Import des routes website
const websiteRoutes = require("./routes/website.routes");
// Import des routes d'audit et sécurité
const auditRoutes = require("./routes/audit.routes");
// Import des routes support (tickets de support)
const supportRoutes = require("./routes/support.routes");
// Import des routes maintenance (maintenance système)
const maintenanceRoutes = require("./routes/maintenance.routes");
// Import des routes pricing (tarification dynamique) - DÉJÀ DÉCLARÉ PLUS HAUT
// const pricingRoutes = require("./routes/pricing.routes"); // DUPLIQUÉ - SUPPRIMÉ
// Import des routes payout (reversements partners)
// const payoutRoutes = require("./routes/payout.routes"); // TEMPORAIREMENT DESACTIVE

const app = express();

// Sentry middlewares sont maintenant gérés automatiquement par instrument.js

// IMPORTANT: Configurer les middlewares de base AVANT toute définition de route
app.use(express.json()); // Pour parser les requêtes avec JSON payloads
app.use(express.urlencoded({ extended: true })); // Pour parser les requêtes avec URL-encoded payloads
app.use(cookieParser(process.env.COOKIE_SECRET || "chapechape-secret-key"));

// Routes publiques de test et promotions (APRÈS les middlewares de parsing mais AVANT la sécurité)
// Protection des routes de test en production
if (process.env.NODE_ENV === 'production') {
  app.use(['/api/test', '/api/public-test/*'], (req, res) => {
    return res.status(404).json({
      success: false,
      message: "Route non disponible en environnement de production"
    });
  });
} else {
  // Route de test simple - uniquement en développement
  app.get("/api/test", (req, res) => {
    res.status(200).json({
      success: true,
      message: "Cette route de test fonctionne correctement"
    });
  });
}

// Route de test pour l'email - uniquement en environnement non-production
if (process.env.NODE_ENV !== 'production' && process.env.ENABLE_TEST_ROUTES !== 'false') {
  app.post("/api/public-test/email", async (req, res) => {
    try {
      const emailService = require('./services/email.service');
      const { email, subject, content } = req.body;

      if (!email) {
        return res.status(400).json({
          success: false,
          message: "L'adresse email est requise"
        });
      }

      console.log(`Envoi d'un email de test à : ${email}`);

      // Utiliser le service d'email avec API Brevo
      const result = await emailService.sendEmail({
        email,
        subject: subject || 'Test de l\'intégration Brevo',
        html: content || `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h1 style="color: #4A6BD8;">Test d'email ChapeChape</h1>
          <p style="font-size: 16px; line-height: 1.5;">
            Ceci est un email de test envoyé via l'API Brevo.
          </p>
          <p style="font-size: 16px; line-height: 1.5;">
            Si vous recevez cet email, l'intégration entre ChapeChape et Brevo fonctionne correctement!
          </p>
          <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin-top: 20px;">
            <p style="margin: 0; color: #666;">
              Date et heure d'envoi: ${new Date().toLocaleString()}
            </p>
          </div>
        </div>
      `
      });

      res.status(200).json({
        success: true,
        message: 'Email de test envoyé avec succès',
        result
      });
    } catch (error) {
      console.error('Erreur lors de l\'envoi de l\'email de test:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de l\'envoi de l\'email',
        error: error.message
      });
    }
  });
}

// 🔒 Route de test pour OneSignal - STRICTEMENT développement uniquement
if (process.env.NODE_ENV === 'development' && process.env.ENABLE_TEST_ROUTES !== 'false') {
  app.post("/api/public-test/notification", async (req, res) => {
    try {
      const oneSignalService = require('./services/onesignal.service');
      const { title, message, segment } = req.body;

      if (!title || !message) {
        return res.status(400).json({
          success: false,
          message: "Titre et message sont requis"
        });
      }

      console.log(`Envoi d'une notification de test: ${title}`);

      let result;
      if (segment) {
        // Envoyer à un segment spécifique
        result = await oneSignalService.sendToSegment(segment, title, message);
      } else {
        // Envoyer à tous les appareils
        result = await oneSignalService.sendToAll(title, message);
      }

      res.status(200).json({
        success: true,
        message: 'Notification envoyée avec succès',
        result
      });
    } catch (error) {
      console.error('Erreur lors de l\'envoi de la notification:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de l\'envoi de la notification',
        error: error.message
      });
    }
  });
}

// Route de vérification de santé (health check) basique pour compatibilité
app.get("/health", (req, res) => {
  res.status(200).json({
    success: true,
    message: "Server is running",
    timestamp: new Date().toISOString()
  });
});

// Import des routes de health checks avancés
const healthRoutes = require("./routes/health.routes");
const pingRoutes = require("./routes/ping.routes");

// Importer les contrôleurs de promotion directement pour les routes publiques
const {
  getPromotions,
  getActivePromotions,
  getExclusivePromotions,
  getPromotion,
  getResidencePromotions
} = require("./controllers/promotion/promotion.controller");

// Routes publiques de promotions (sans authentification)
app.get("/api/promotions", cache(900), getPromotions);
app.get("/api/promotions/active", cache(900), getActivePromotions);
app.get("/api/promotions/exclusive", cache(900), getExclusivePromotions);
app.get("/api/promotions/residence/:id", cache(900), getResidencePromotions);
app.get("/api/promotions/:id", getPromotion);

// Sécurité
app.use(
  helmet({
    crossOriginResourcePolicy: { policy: "cross-origin" },
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        imgSrc: ["'self'", "data:", "blob:", "http:", "https:"],
        connectSrc: ["'self'", "http:", "https:"],
      },
    },
  })
);

// CORS
app.use(
  cors({
    origin: [
      "http://localhost:3000", // Frontend client
      "http://localhost:3001", // Frontend partenaire
      "http://localhost:3002", // Dashboard local
      "http://localhost:3003", // Dashboard local alternatif
      "https://admin.chapechaperesidence.com", // Dashboard admin
      process.env.CLIENT_URL,
      process.env.PARTNER_URL,
      process.env.DASHBOARD_URL, // Dashboard URL depuis env
    ],
    credentials: true, // Pour permettre les cookies avec CORS
    exposedHeaders: ["X-CSRF-Token", "Authorization"], // Exposer les en-têtes nécessaires
  })
);

// ====================================================================
// RATE LIMITING MULTI-NIVEAUX (Sécurité renforcée)
// ====================================================================
const {
  globalLimiter,
  authLimiter,
  paymentLimiter,
  userLimiter,
  uploadLimiter
} = require('./middlewares/rate-limit.middleware');

// Rate limiter global (100 req/15min) - Appliqué à toutes les routes
app.use('/api/', globalLimiter);

// Middleware de base
app.use(compression());

// Middlewares
app.use(morgan("dev"));

// Servir les fichiers statiques publiquement pour les images (AVANT sécurité)
app.use(
  "/uploads",
  express.static(path.join(__dirname, "../uploads"), {
    maxAge: "1d",
    etag: true,
  })
);

// Ajouter également la route /api/uploads pour maintenir la rétrocompatibilité
app.use(
  "/api/uploads",
  express.static(path.join(__dirname, "../uploads"), {
    maxAge: "1d",
    etag: true,
  })
);

// Middleware de sécurité (APRÈS exposer les ressources publiques)
app.use(securityMiddleware);

// Middleware de logging
app.use(logger.http);

// Documentation API
app.use(
  "/api-docs",
  swaggerUi.serve,
  swaggerUi.setup(swaggerSpecs, {
    explorer: true,
    customCss: ".swagger-ui .topbar { display: none }",
    customSiteTitle: "ChapeChape API Documentation",
    customfavIcon: "/favicon.ico",
    swaggerOptions: {
      persistAuthorization: true,
      docExpansion: "none",
      filter: true,
      tagsSorter: "alpha",
      operationsSorter: "alpha",
    },
  })
);

// Génération de tokens CSRF pour les routes qui en ont besoin
// Désactivé temporairement pour résoudre les problèmes d'authentification du dashboard
// app.use("/api/auth/login", generateCsrfToken);
app.use("/api/auth/register", generateCsrfToken);

// Protection CSRF pour les routes mutatives sensibles
app.use("/api/bookings", csrfMiddleware);
// app.use("/api/payments", csrfMiddleware); // ✅ DÉSACTIVÉ pour apps mobiles Flutter
app.use("/api/users", csrfMiddleware);

// Temporairement désactivé pour les résidences pour permettre la création
// app.use("/api/residences", (req, res, next) => {
//   if (["POST", "PUT", "DELETE", "PATCH"].includes(req.method)) {
//     csrfMiddleware(req, res, next);
//   } else {
//     next();
//   }
// });

// Routes avec cache pour les requêtes GET (sans cache pour les routes authentifiées type /my-residences)
app.use("/api/residences", cache({
  duration: 3600,
  condition: (req) => req.method === 'GET' && !req.headers.authorization
}), residenceRoutes);
app.use("/api/reviews", cache(1800), reviewRoutes);

// ====================================================================
// ROUTES PROTÉGÉES PAR RATE LIMITING SPÉCIFIQUE
// ====================================================================

// Routes d'authentification - Rate limit strict (5/15min)
app.use("/api/auth/login", authLimiter);
app.use("/api/auth/register", authLimiter);
app.use("/api/auth/register-partner", authLimiter);
app.use("/api/auth", authRoutes);

app.use("/api/users", userRoutes);

// Routes de paiement - Rate limit très strict (3/1min)
app.use("/api/payments", paymentLimiter, paymentRoutes);
app.use("/api/reservations", reservationRoutes);
app.use("/api/favorites", favoriteRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/partners", partnerRoutes);
app.use("/api/partners/verify-phone", partnerVerificationRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/dashboard", dashboardRoutes);
app.use("/api/superadmin", superAdminRoutes);
app.use("/api/messages", messageRoutes); // Routes de messagerie
app.use("/api/availability", availabilityRoutes); // Ajout des routes pour la gestion des disponibilités
app.use("/api/devices", deviceRoutes); // Ajout des routes pour la gestion des appareils
app.use("/api/sms", smsRoutes); // Ajout des routes pour l'envoi de SMS via Twilio
app.use("/api/promotions", promotionRoutes); // Ajout des routes pour la gestion des promotions
app.use("/api/maps", mapsRoutes); // Ajout des routes pour la géolocalisation et les cartes
app.use("/api/cancellation-policies", cancellationPolicyRoutes); // Routes pour les politiques d'annulation
app.use("/api/audit", auditRoutes); // Routes pour l'audit et la sécurité
app.use("/api/website", websiteRoutes); // Routes pour le site vitrine (contact, newsletter)
app.use("/api/pricing", pricingRoutes); // Routes pour la tarification dynamique CinetPay - ✅ Réactivé après correction bug d'import auth
app.use("/api/payouts", payoutRoutes); // ✅ RÉACTIVÉ - Routes pour les reversements aux partners via CinetPay
app.use("/api/health", healthRoutes); // Routes pour les health checks avancés
app.use("/api/ping", pingRoutes); // Routes pour les pings de connectivité
app.use("/api/support", supportRoutes); // Routes pour les tickets de support
app.use("/api/maintenance", maintenanceRoutes); // Routes pour la maintenance système (SuperAdmin)
// app.use("/api/blog", cache(1800), blogRoutes); // Routes pour le blog dynamique (temporairement désactivé pour diagnostic)

// 🔒 SÉCURITÉ CRITIQUE : Routes de test (TEMPORAIREMENT DÉSACTIVÉES POUR DIAGNOSTIC)
// Double vérification pour s'assurer qu'aucune route de test n'est exposée en production
// TEMPORAIREMENT DÉSACTIVÉ POUR DIAGNOSTIC DU CRASH
/*
if (process.env.NODE_ENV === 'development' && process.env.ENABLE_TEST_ROUTES !== 'false') {
  console.log('⚠️ Routes de test activées en environnement de développement UNIQUEMENT');
  console.log('🚨 CES ROUTES SONT AUTOMATIQUEMENT DÉSACTIVÉES EN PRODUCTION');
  app.use("/api/test", testRoutes);
} else if (process.env.NODE_ENV === 'production') {
  // Log explicite en production pour confirmer la désactivation
  console.log('✅ SÉCURITÉ : Routes de test DÉSACTIVÉES en production');
}
*/
console.log('🔧 DIAGNOSTIC : Routes de test temporairement désactivées');

// Route de test
app.get("/", (req, res) => {
  res.json({ message: "Bienvenue sur l'API ChapeChape" });
});

// Ajouter un endpoint pour vérifier le CSRF
app.get("/api/csrf-token", (req, res) => {
  // Importer le middleware CSRF qui utilise csurf
  const { csrfProtection } = require("./middlewares/csrf-custom.middleware");

  // Appliquer csrfProtection pour générer un token
  csrfProtection(req, res, (err) => {
    if (err) {
      console.error(`Erreur lors de la génération du token CSRF: ${err.message}`);
      return res.status(500).json({
        success: false,
        message: "Erreur lors de la génération du token CSRF",
      });
    }

    // Générer et renvoyer le token
    const token = req.csrfToken();
    res.setHeader("X-CSRF-Token", token);
    return res.status(200).json({ success: true, csrfToken: token });
  });
});

// 🔒 Route de test Sentry (STRICTEMENT développement uniquement)
if (process.env.NODE_ENV === 'development' && process.env.ENABLE_DEBUG_ROUTES !== 'false') {
  app.get("/debug-sentry", function mainHandler(req, res) {
    console.log('⚠️ Route de debug Sentry appelée - Développement uniquement');
    throw new Error("Test Sentry - Erreur intentionnelle pour vérifier la capture!");
  });
} else if (process.env.NODE_ENV === 'production') {
  console.log('✅ SÉCURITÉ : Route debug Sentry DÉSACTIVÉE en production');
}

// Middleware de sécurité pour les fichiers
app.use("/api/uploads", fileSecurityMiddleware);

// Gestionnaire d'erreurs Sentry officiel - doit être ajouté AVANT les autres gestionnaires d'erreur
const Sentry = require('@sentry/node');
Sentry.setupExpressErrorHandler(app);

// Gestion des erreurs
app.use((err, req, res, next) => {
  logger.error("Error:", err);

  // Récupérer le code d'état numérique approprié
  let statusCode = 500;
  if (err.statusCode && typeof err.statusCode === "number") {
    statusCode = err.statusCode;
  }

  res.status(statusCode).json({
    success: false,
    message: err.message || "Une erreur est survenue",
    status: err.status || "error",
    ...(process.env.NODE_ENV === "development" && {
      stack: err.stack,
      details: err,
    }),
  });
});

// Gestion des routes non trouvées
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: "Route non trouvée",
  });
});

module.exports = app;