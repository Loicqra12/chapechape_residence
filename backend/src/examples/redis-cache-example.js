/**
 * Exemple d'utilisation du cache Redis dans les routes
 * Ce fichier sert uniquement de référence et ne sera pas utilisé directement
 */

const express = require('express');
const router = express.Router();
const { configureCache } = require('../utils/cache-config');
const { invalidateById } = require('../middlewares/redis-cache');

// Exemple de contrôleur fictif
const residenceController = {
  getAllResidences: (req, res) => {
    // Logique du contrôleur
  },
  getResidenceById: (req, res) => {
    // Logique du contrôleur
  },
  updateResidence: (req, res) => {
    // Logique du contrôleur
  }
};

/**
 * EXEMPLE 1: Route simple avec cache
 * 
 * Cette route utilisera Redis si USE_REDIS_CACHE=true dans l'environnement,
 * sinon elle utilisera node-cache.
 */
router.get('/residences', configureCache({
  prefix: 'residences',
  duration: 600 // 10 minutes
}), residenceController.getAllResidences);

/**
 * EXEMPLE 2: Route avec paramètre d'ID pour invalidation granulaire
 * 
 * Cette configuration permet d'invalider automatiquement le cache
 * pour une résidence spécifique lorsqu'elle est modifiée.
 */
router.get('/residences/:residenceId', configureCache({
  prefix: 'residences',
  duration: 1800, // 30 minutes
  idParam: 'residenceId'
}), residenceController.getResidenceById);

/**
 * EXEMPLE 3: Invalidation manuelle du cache lors d'une mise à jour
 */
router.put('/residences/:residenceId', async (req, res, next) => {
  try {
    // Si Redis est activé, invalider le cache pour cette résidence
    if (process.env.USE_REDIS_CACHE === 'true') {
      await invalidateById('residences', req.params.residenceId);
    }
    next();
  } catch (error) {
    next(error);
  }
}, residenceController.updateResidence);

/**
 * EXEMPLE 4: Migration progressive d'une route à la fois
 * 
 * Vous pouvez utiliser cette approche pour migrer progressivement
 * vos routes vers Redis une par une, en testant chaque migration.
 */

// Pour activer Redis sur une route spécifique, même si USE_REDIS_CACHE est false
router.get('/residences/featured', (() => {
  // Forcer l'utilisation de Redis pour cette route spécifique
  const useRedisForThisRoute = true;
  
  if (useRedisForThisRoute) {
    const { redisCacheMiddleware } = require('../middlewares/redis-cache');
    return redisCacheMiddleware({ 
      prefix: 'featured', 
      duration: 300 
    });
  } else {
    const cacheMiddleware = require('../middlewares/cache.middleware');
    return cacheMiddleware(300);
  }
})(), residenceController.getFeaturedResidences);

module.exports = router;
