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
} = require("./middlewares/csrf.middleware");
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
const reservationRoutes = require("./routes/reservation.routes");
const favoriteRoutes = require("./routes/favorite.routes");
const userRoutes = require("./routes/user.routes");
const paymentRoutes = require("./routes/payment.routes");
const reviewRoutes = require("./routes/review.routes");
const notificationRoutes = require("./routes/notification.routes");
const messageRoutes = require("./routes/message.routes");
const authRoutes = require("./routes/auth.routes");
const adminRoutes = require("./routes/admin.routes");
const superAdminRoutes = require("./routes/superadmin.routes");
const availabilityRoutes = require("./routes/availability.routes");
const promotionRoutes = require("./routes/promotion.routes");

const app = express();

// Routes publiques de test et promotions (AVANT les middlewares de sécurité)
// Route de test simple
app.get("/api/test", (req, res) => {
  res.status(200).json({
    success: true,
    message: "Cette route de test fonctionne correctement"
  });
});

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
      process.env.CLIENT_URL,
      process.env.PARTNER_URL,
    ],
    credentials: true, // Pour permettre les cookies avec CORS
    exposedHeaders: ["X-CSRF-Token"], // Exposer l'en-tête CSRF
  })
);

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limite chaque IP à 100 requêtes par fenêtre
});
app.use(limiter);

// Middleware de base
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser(process.env.COOKIE_SECRET || "chapechape-secret-key"));

// Compression
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
app.use("/api/auth/login", generateCsrfToken);
app.use("/api/auth/register", generateCsrfToken);

// Protection CSRF pour les routes mutatives sensibles
app.use("/api/bookings", csrfMiddleware);
app.use("/api/payments", csrfMiddleware);
app.use("/api/users", csrfMiddleware);

// Temporairement désactivé pour les résidences pour permettre la création
// app.use("/api/residences", (req, res, next) => {
//   if (["POST", "PUT", "DELETE", "PATCH"].includes(req.method)) {
//     csrfMiddleware(req, res, next);
//   } else {
//     next();
//   }
// });

// Routes avec cache pour les requêtes GET
app.use("/api/residences", cache(3600), residenceRoutes);
app.use("/api/reviews", cache(1800), reviewRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/payments", paymentRoutes);
app.use("/api/reservations", reservationRoutes);
app.use("/api/favorites", favoriteRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/partners", partnerRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/superadmin", superAdminRoutes);
app.use("/api/messages", messageRoutes); // Routes de messagerie
app.use("/api", availabilityRoutes); // Ajout des routes pour la gestion des disponibilités

// Route de test
app.get("/", (req, res) => {
  res.json({ message: "Bienvenue sur l'API ChapeChape" });
});

// Ajouter un endpoint pour vérifier le CSRF
app.get("/api/csrf-token", (req, res) => {
  // Utiliser csrfProtection directement pour générer un token sans vérification d'authentification
  const csrf = require("csurf");
  const csrfProtection = csrf({
    cookie: {
      key: "_csrf",
      path: "/",
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
      maxAge: 3600 * 1000, // 1 heure
    },
  });

  // Appliquer csrfProtection directement
  csrfProtection(req, res, (err) => {
    if (err) {
      return res
        .status(500)
        .json({
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

// Middleware de sécurité pour les fichiers
app.use("/api/uploads", fileSecurityMiddleware);

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
