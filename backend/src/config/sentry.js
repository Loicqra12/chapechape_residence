const Sentry = require('@sentry/node');

// Gestion compatible des handlers pour différentes versions de Sentry
let requestHandler, errorHandler, tracingHandler;

try {
  // Tentative d'import moderne (v8+)
  const handlers = require('@sentry/node/handlers');
  requestHandler = handlers.requestHandler;
  errorHandler = handlers.errorHandler;
  tracingHandler = handlers.tracingHandler;
} catch (e1) {
  try {
    // Fallback vers l'ancienne méthode (v7 et antérieur)
    requestHandler = Sentry.Handlers?.requestHandler;
    errorHandler = Sentry.Handlers?.errorHandler;
    tracingHandler = Sentry.Handlers?.tracingHandler;
  } catch (e2) {
    console.warn('Impossible de charger les handlers Sentry:', e2.message);
  }
}

/**
 * Configuration Sentry pour ChapeChape Residences Backend
 * Monitoring des erreurs et performance
 */

const initSentry = () => {
  Sentry.init({
    // DSN Sentry - à configurer avec votre clé projet
    dsn: process.env.SENTRY_DSN || 'your-sentry-dsn-here',
    
    // Nom de l'environnement
    environment: process.env.NODE_ENV || 'development',
    
    // Version de l'application
    release: process.env.npm_package_version || '1.0.0',
    
    // Taux d'échantillonnage des traces (0.0 à 1.0)
    tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,
    
    // Intégrations automatiques par défaut
    integrations: [
      // Les intégrations par défaut de Sentry sont automatiquement incluses
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
    
    // Configuration du transport
    transport: Sentry.makeNodeTransport,
    
    // Désactiver la capture automatique des rejets de promesse non gérés
    // (nous les gérons manuellement)
    captureUnhandledRejections: false,
    
    // Configuration des sessions
    autoSessionTracking: true,
    
    // Désactiver en mode test
    enabled: process.env.NODE_ENV !== 'test'
  });
  
  console.log(`✅ Sentry initialized for environment: ${process.env.NODE_ENV}`);
};

/**
 * Middleware Sentry pour Express
 */
const sentryRequestHandler = () => {
  try {
    return requestHandler({
      ip: true,
      request: ['method', 'url', 'headers', 'data'],
      user: ['id', 'email', 'role']
    });
  } catch (error) {
    console.warn('Sentry requestHandler not available, using fallback:', error.message);
    return (req, res, next) => next();
  }
};

/**
 * Middleware de gestion des erreurs Sentry
 */
const sentryErrorHandler = () => {
  try {
    return errorHandler({
      shouldHandleError(error) {
        // Gérer toutes les erreurs sauf les 404
        return error.status !== 404;
      }
    });
  } catch (error) {
    console.warn('Sentry errorHandler not available, using fallback:', error.message);
    return (err, req, res, next) => {
      // Fallback error handler
      if (err.status !== 404) {
        console.error('Error captured by fallback handler:', err);
      }
      next(err);
    };
  }
};

/**
 * Middleware de tracing Sentry
 */
const sentryTracingHandler = () => {
  try {
    return tracingHandler();
  } catch (error) {
    console.warn('Sentry tracingHandler not available, using fallback:', error.message);
    return (req, res, next) => next();
  }
};

/**
 * Capturer une erreur personnalisée
 */
const captureError = (error, context = {}) => {
  Sentry.withScope((scope) => {
    // Ajouter le contexte
    Object.keys(context).forEach(key => {
      scope.setTag(key, context[key]);
    });
    
    // Capturer l'erreur
    Sentry.captureException(error);
  });
};

/**
 * Capturer un message personnalisé
 */
const captureMessage = (message, level = 'info', context = {}) => {
  Sentry.withScope((scope) => {
    scope.setLevel(level);
    
    // Ajouter le contexte
    Object.keys(context).forEach(key => {
      scope.setTag(key, context[key]);
    });
    
    Sentry.captureMessage(message);
  });
};

/**
 * Ajouter des informations utilisateur
 */
const setUser = (user) => {
  Sentry.setUser({
    id: user.id || user._id,
    email: user.email,
    role: user.role,
    firstName: user.firstName,
    lastName: user.lastName
  });
};

/**
 * Ajouter des tags personnalisés
 */
const setTag = (key, value) => {
  Sentry.setTag(key, value);
};

/**
 * Créer une transaction personnalisée
 */
const startTransaction = (name, op = 'http') => {
  return Sentry.startTransaction({
    name,
    op
  });
};

module.exports = {
  initSentry,
  sentryRequestHandler,
  sentryErrorHandler,
  sentryTracingHandler,
  captureError,
  captureMessage,
  setUser,
  setTag,
  startTransaction,
  Sentry
};
