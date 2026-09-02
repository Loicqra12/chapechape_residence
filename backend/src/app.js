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
  csrfProtection,
} = require("./middlewares/csrf-custom.middleware");
const cache = require("./middlewares/cache.middleware");
const cors = require("cors");
const path = require("path");
const compression = require("compression");
const helmet = require("helmet");
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
const mediaRoutes = require("./routes/media.routes");
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

const { resolveTrustProxySetting } = require("./runtime/trust-proxy");

const app = express();

app.set("trust proxy", resolveTrustProxySetting());

const { requestIdMiddleware } = require("./middlewares/request-id.middleware");
app.use(requestIdMiddleware);

// Sentry middlewares sont maintenant gérés automatiquement par instrument.js

// Webhooks PSP (corps brut / signature) — AVANT express.json()
const paymentController = require("./controllers/payment/payment.controller");
const payoutController = require("./controllers/payout.controller");
app.post(
  "/api/payments/webhook",
  express.raw({ type: "application/json" }),
  paymentController.handleStripeWebhook
);
app.post(
  "/api/payments/wave/webhook",
  express.raw({ type: "application/json" }),
  paymentController.handleWaveWebhook
);
app.post(
  "/api/payouts/wave/webhook",
  express.raw({ type: "application/json" }),
  payoutController.handleWavePayoutWebhook
);
// CinetPay paiement (urlencoded) — hors paymentLimiter (monté ici, pas via payment.routes)
app.post(
  "/api/payments/cinetpay/webhook",
  express.urlencoded({ extended: true }),
  paymentController.handleCinetPayWebhook
);

// IMPORTANT: Configurer les middlewares de base AVANT toute définition de route
app.use(express.json()); // Pour parser les requêtes avec JSON payloads
app.use(express.urlencoded({ extended: true })); // Pour parser les requêtes avec URL-encoded payloads
app.use(cookieParser(process.env.COOKIE_SECRET || (() => {
  if (process.env.NODE_ENV === 'production') {
    throw new Error('COOKIE_SECRET non défini — obligatoire en production');
  }
  logger.warn('[DEV] COOKIE_SECRET non défini — utilisation d\'une clé temporaire de développement uniquement');
  return 'dev-cookie-secret-not-for-production';
})()));

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

      logger.info(`Envoi d'un email de test à : ${email}`);

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
      logger.error("Erreur lors de l'envoi de l'email de test:", error);
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

      logger.info(`Envoi d'une notification de test: ${title}`);

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
      logger.error("Erreur lors de l'envoi de la notification:", error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de l\'envoi de la notification',
        error: error.message
      });
    }
  });
}

// Route de vérification de santé (health check) basique pour compatibilité
app.get("/health", (req, res, next) => {
  require("./controllers/health.controller").getLiveness(req, res, next);
});
app.get("/ready", (req, res, next) => {
  require("./controllers/health.controller").getReadiness(req, res, next);
});

// ====================================================================
// ANDROID APP LINKS — .well-known/assetlinks.json (optionnel sur l’hôte API)
// La vérification Android utilise le MÊME domaine que l’URL du lien email
// (souvent presentation.* = site statique chapechape_sitepresentation, pas ce serveur).
// Le fichier canonique est : chapechape_sitepresentation/public/.well-known/assetlinks.json
// Gardez APP_CLIENT_SHA256_FINGERPRINT / APP_PARTNER_SHA256_FINGERPRINT dans .env si vous
// proxy ce chemin vers l’API ou pour cohérence locale.
// ====================================================================
app.get("/.well-known/assetlinks.json", (req, res) => {
  res.setHeader("Content-Type", "application/json");
  res.setHeader("Cache-Control", "public, max-age=3600");
  res.json([
    {
      relation: ["delegate_permission/common.handle_all_urls"],
      target: {
        namespace: "android_app",
        package_name: "com.chapechape.client",
        sha256_cert_fingerprints: [
          process.env.APP_CLIENT_SHA256_FINGERPRINT || "REMPLACER_PAR_VOTRE_SHA256_CLIENT"
        ]
      }
    },
    {
      relation: ["delegate_permission/common.handle_all_urls"],
      target: {
        namespace: "android_app",
        package_name: "com.chapechape.chapechape_partner",
        sha256_cert_fingerprints: [
          process.env.APP_PARTNER_SHA256_FINGERPRINT || "REMPLACER_PAR_VOTRE_SHA256_PARTNER"
        ]
      }
    }
  ]);
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

// Origines autorisées (site vitrine LWS, apps, .env — doublons retirés)
const corsAllowedOrigins = [
  "http://localhost:3000",
  "http://localhost:3001",
  "http://localhost:3002",
  "http://localhost:3003",
  "http://localhost:5173", // Vite (site présentation local)
  "https://admin.chapechaperesidence.com",
  "https://presentation.chapechaperesidence.com", // Site vitrine prod (LWS, etc.)
  process.env.CLIENT_URL,
  process.env.PARTNER_URL,
  process.env.DASHBOARD_URL,
  process.env.PRODUCTION_FRONTEND_URL,
  process.env.PRODUCTION_CORS_ORIGIN,
  process.env.PRESENTATION_URL,
]
  .map((o) => (typeof o === "string" ? o.trim() : o))
  .filter(Boolean);
const corsOriginsUnique = [...new Set(corsAllowedOrigins)];

// CORS
app.use(
  cors({
    origin: corsOriginsUnique,
    credentials: true, // Pour permettre les cookies avec CORS
    exposedHeaders: ["X-CSRF-Token", "Authorization"], // Exposer les en-têtes nécessaires
  })
);

// Routes publiques de promotions (sans authentification)
// Déclarées après Helmet/CORS pour garantir les headers de sécurité sur les réponses.
app.get("/api/promotions", cache(900), getPromotions);
app.get("/api/promotions/active", cache(900), getActivePromotions);
app.get("/api/promotions/exclusive", cache(900), getExclusivePromotions);
app.get("/api/promotions/residence/:id", cache(900), getResidencePromotions);
app.get("/api/promotions/:id", getPromotion);

// ====================================================================
// RATE LIMITING MULTI-NIVEAUX (Sécurité renforcée)
// ====================================================================
const {
  globalLimiter,
  authLoginLimiter,
  authLoginAccountLimiter,
  authRegisterLimiter,
  authForgotPasswordLimiter,
  authForgotAccountLimiter,
  authVerifyCodeLimiter,
  paymentLimiter,
  uploadLimiter,
  adminLimiter,
  userLimiter,
  financialLimiter,
} = require('./middlewares/rate-limit.middleware');

// Rate limiter global (policy PUBLIC, skip health + webhooks)
app.use('/api/', globalLimiter);

// Middleware de base
app.use(compression());

// Access log HTTP unique : logger.http (Morgan → Winston canonique). Pas de second morgan().

const {
  denyPublicPrivateUploads,
} = require("./security/private-uploads");

// Servir uniquement les médias publics (résidences, profils). Documents / messages : auth + ownership.
app.use(
  "/uploads",
  denyPublicPrivateUploads,
  express.static(path.join(__dirname, "../uploads"), {
    maxAge: "1d",
    etag: true,
  })
);

app.use(
  "/api/uploads",
  denyPublicPrivateUploads,
  express.static(path.join(__dirname, "../uploads"), {
    maxAge: "1d",
    etag: true,
  })
);

// Middleware de sécurité (APRÈS exposer les ressources publiques)
app.use(securityMiddleware);

// Middleware de logging
app.use(logger.http);

// Documentation API (désactivée en production pour réduire la surface d'attaque)
if (process.env.NODE_ENV !== "production") {
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
}

// Génération de tokens CSRF pour les routes qui en ont besoin
// Désactivé temporairement pour résoudre les problèmes d'authentification du dashboard
// app.use("/api/auth/login", generateCsrfToken);
app.use("/api/auth/register", generateCsrfToken);

// Protection CSRF pour les routes mutatives sensibles
// Note: /api/bookings legacy retiré — flux vivant = /api/reservations
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
app.use("/api/reviews", cache({
  duration: 1800,
  condition: (req) => req.method === "GET" && !req.headers.authorization,
}), reviewRoutes);

// ====================================================================
// ROUTES PROTÉGÉES PAR RATE LIMITING SPÉCIFIQUE
// ====================================================================

// Routes d'authentification — login strict ; inscription plus tolérante (erreurs 400 comptées)
app.use("/api/auth/login", authLoginLimiter, authLoginAccountLimiter);
app.use("/api/auth/register", authRegisterLimiter);
app.use("/api/auth/register-partner", authRegisterLimiter);
app.use("/api/auth/forgot-password", authForgotPasswordLimiter, authForgotAccountLimiter);
app.use("/api/auth/verify-code", authVerifyCodeLimiter);
app.use("/api/auth/reset-password", authForgotPasswordLimiter);
app.use("/api/auth", authRoutes);

app.use("/api/users", userRoutes);

// Paiements / payouts : policy FINANCIAL (hors webhooks PSP montés plus haut)
app.use("/api/payments", paymentLimiter, paymentRoutes);
app.use("/api/payouts", financialLimiter, payoutRoutes);
app.use("/api/admin", adminLimiter, adminRoutes);
app.use("/api/dashboard", adminLimiter, dashboardRoutes);
app.use("/api/superadmin", adminLimiter, superAdminRoutes);
app.use("/api/reservations", reservationRoutes);
app.use("/api/favorites", userLimiter, favoriteRoutes);
app.use("/api/notifications", userLimiter, notificationRoutes);
app.use("/api/partners", partnerRoutes);
app.use("/api/partners/verify-phone", partnerVerificationRoutes);
app.use("/api/messages", messageRoutes);
app.use("/api/media", uploadLimiter, mediaRoutes);
app.use("/api/availability", availabilityRoutes); // Ajout des routes pour la gestion des disponibilités
app.use("/api/devices", deviceRoutes); // Ajout des routes pour la gestion des appareils
app.use("/api/sms", smsRoutes); // Ajout des routes pour l'envoi de SMS via Twilio
app.use("/api/promotions", promotionRoutes); // Ajout des routes pour la gestion des promotions
app.use("/api/maps", mapsRoutes); // Ajout des routes pour la géolocalisation et les cartes
app.use("/api/cancellation-policies", cancellationPolicyRoutes); // Routes pour les politiques d'annulation
app.use("/api/audit", auditRoutes); // Routes pour l'audit et la sécurité
app.use("/api/website", websiteRoutes); // Routes pour le site vitrine (contact, newsletter)
app.use("/api/pricing", pricingRoutes);
app.use("/api/health", healthRoutes);
app.use("/api/ping", pingRoutes); // Routes pour les pings de connectivité
app.use("/api/support", supportRoutes); // Routes pour les tickets de support
app.use("/api/maintenance", maintenanceRoutes); // Routes pour la maintenance système (SuperAdmin)
// app.use("/api/blog", cache(1800), blogRoutes); // Routes pour le blog dynamique (temporairement désactivé pour diagnostic)

// 🔒 SÉCURITÉ CRITIQUE : Routes de test (TEMPORAIREMENT DÉSACTIVÉES POUR DIAGNOSTIC)
// Double vérification pour s'assurer qu'aucune route de test n'est exposée en production
// TEMPORAIREMENT DÉSACTIVÉ POUR DIAGNOSTIC DU CRASH
/*
if (process.env.NODE_ENV === 'development' && process.env.ENABLE_TEST_ROUTES !== 'false') {
  logger.info('DEV_ONLY: routes de test activées (désactivées en production)');
  app.use("/api/test", testRoutes);
} else if (process.env.NODE_ENV === 'production') {
  // Log explicite en production pour confirmer la désactivation
  logger.info('Routes de test désactivées en production');
}
*/
if (process.env.NODE_ENV !== "production") {
  logger.info("DIAGNOSTIC : Routes de test temporairement désactivées");
}

// Route de test
app.get("/", (req, res) => {
  res.json({ message: "Bienvenue sur l'API ChapeChape" });
});

// Ajouter un endpoint pour vérifier le CSRF
app.get("/api/csrf-token", (req, res) => {
  // Appliquer csrfProtection pour générer un token
  csrfProtection(req, res, (err) => {
    if (err) {
      logger.error(`Erreur lors de la génération du token CSRF: ${err.message}`);
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
    logger.warn("Route de debug Sentry appelée - Développement uniquement");
    throw new Error("Test Sentry - Erreur intentionnelle pour vérifier la capture!");
  });
}

// Middleware de sécurité pour les fichiers
app.use("/api/uploads", fileSecurityMiddleware);

// Gestionnaire d'erreurs Sentry officiel - doit être ajouté AVANT les autres gestionnaires d'erreur
const Sentry = require('@sentry/node');
const { shouldCaptureSentry, logLevelForError } = require('./observability/http-error-policy');
const { extractSafeErrorInfo } = require('./utils/sanitize-error');
Sentry.setupExpressErrorHandler(app, {
  shouldHandleError(error) {
    return shouldCaptureSentry(error);
  },
});

// Gestion des erreurs
app.use((err, req, res, next) => {
  const level = logLevelForError(err);
  logger[level]('Error:', extractSafeErrorInfo(err, req));

  // Récupérer le code d'état numérique approprié
  let statusCode = 500;
  if (err.statusCode && typeof err.statusCode === "number") {
    statusCode = err.statusCode;
  }

  res.status(statusCode).json({
    success: false,
    message: err.message || "Une erreur est survenue",
    errorCode: err.errorCode || undefined,
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