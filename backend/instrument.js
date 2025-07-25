/**
 * Instrument.js - Initialisation précoce de Sentry
 * IMPORTANT: Ce fichier doit être importé en premier dans server.js
 */

const Sentry = require("@sentry/node");

Sentry.init({
  // DSN officiel du projet Sentry
  dsn: process.env.SENTRY_DSN || "https://37b95abe27c210360b7824d0da0bf97b@o4509717994602496.ingest.us.sentry.io/4509717999517696",
  
  // Nom de l'environnement
  environment: process.env.NODE_ENV || 'development',
  
  // Version de l'application
  release: process.env.npm_package_version || '1.0.0',
  
  // Taux d'échantillonnage des traces (0.0 à 1.0)
  tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,
  
  // Envoyer les données PII par défaut (IP, user agent, etc.)
  sendDefaultPii: true,
  
  // Intégrations automatiques
  integrations: [
    // Les intégrations par défaut de Sentry sont automatiquement incluses
    Sentry.httpIntegration(),
    Sentry.expressIntegration(),
    Sentry.mongoIntegration(),
    Sentry.nodeContextIntegration(),
  ],
  
  // Configuration des données utilisateur
  beforeSend(event, hint) {
    // Filtrer les données sensibles
    if (event.request) {
      // Supprimer les headers sensibles
      if (event.request.headers) {
        delete event.request.headers.authorization;
        delete event.request.headers.cookie;
        delete event.request.headers['x-csrf-token'];
      }
      
      // Supprimer les données sensibles du body
      if (event.request.data) {
        if (typeof event.request.data === 'object') {
          delete event.request.data.password;
          delete event.request.data.token;
          delete event.request.data.refreshToken;
        }
      }
    }
    
    // Filtrer les erreurs de développement
    if (process.env.NODE_ENV === 'development') {
      // Ne pas envoyer certaines erreurs en développement
      if (hint.originalException?.code === 'ECONNREFUSED') {
        return null;
      }
    }
    
    return event;
  },
  
  // Tags par défaut
  initialScope: {
    tags: {
      component: 'backend',
      service: 'chapechape-residences'
    },
    level: 'info'
  },
  
  // Ignorer certaines erreurs
  ignoreErrors: [
    // Erreurs réseau communes
    'Network Error',
    'NetworkError',
    'fetch',
    
    // Erreurs de validation communes
    'ValidationError',
    
    // Erreurs 404 (trop communes)
    /404/,
    
    // Erreurs de connexion Redis en développement
    /ECONNREFUSED.*redis/i,
    
    // Erreurs de bot/crawler
    /bot|crawler|spider/i
  ],
  
  // Configuration des breadcrumbs
  beforeBreadcrumb(breadcrumb, hint) {
    // Filtrer les breadcrumbs sensibles
    if (breadcrumb.category === 'http') {
      if (breadcrumb.data?.url?.includes('/auth/')) {
        breadcrumb.data.url = breadcrumb.data.url.replace(/\/auth\/.*/, '/auth/[FILTERED]');
      }
    }
    
    return breadcrumb;
  },
  
  // Limites de performance
  maxBreadcrumbs: 50,
  maxValueLength: 250,
  
  // Désactiver la capture automatique des rejets de promesse non gérés
  // (nous les gérons manuellement)
  captureUnhandledRejections: false,
  
  // Configuration des sessions
  autoSessionTracking: true,
  
  // Désactiver en mode test
  enabled: process.env.NODE_ENV !== 'test'
});

console.log(`✅ Sentry initialized for environment: ${process.env.NODE_ENV}`);
