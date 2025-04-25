/**
 * Service de cache pour gérer la mise en cache des données
 * Utilise node-cache pour le stockage en mémoire
 */
const NodeCache = require('node-cache');
const cache = new NodeCache({ stdTTL: 900 }); // 15 minutes par défaut

/**
 * Service de mise en cache
 */
const cacheService = {
  /**
   * Récupère une valeur du cache
   * @param {string} key - Clé du cache
   * @returns {any} Valeur mise en cache ou undefined si non trouvée
   */
  get: async (key) => {
    return cache.get(key);
  },

  /**
   * Ajoute une valeur au cache
   * @param {string} key - Clé du cache
   * @param {any} value - Valeur à mettre en cache
   * @param {number} ttl - Durée de vie en secondes (optional)
   * @returns {boolean} Succès ou échec
   */
  set: async (key, value, ttl) => {
    return cache.set(key, value, ttl);
  },

  /**
   * Supprime une valeur du cache
   * @param {string} key - Clé du cache à invalider
   * @returns {number} Nombre d'éléments supprimés
   */
  invalidate: async (key) => {
    return cache.del(key);
  },

  /**
   * Supprime toutes les valeurs du cache correspondant à un pattern
   * @param {string} pattern - Motif pour correspondre aux clés
   * @returns {number} Nombre d'éléments supprimés
   */
  invalidatePattern: async (pattern) => {
    const keys = cache.keys();
    const regex = new RegExp(pattern.replace('*', '.*'));
    const matchingKeys = keys.filter(key => regex.test(key));
    
    if (matchingKeys.length > 0) {
      return cache.del(matchingKeys);
    }
    
    return 0;
  },

  /**
   * Vide entièrement le cache
   * @returns {boolean} Succès ou échec
   */
  flush: async () => {
    return cache.flushAll();
  }
};

module.exports = { cacheService };
