/**
 * Wrapper pour gérer les erreurs dans les fonctions async/await
 * Évite d'avoir à écrire des blocs try/catch dans chaque controller
 * @param {Function} fn - Fonction asynchrone à exécuter
 * @returns {Function} - Middleware Express
 */
const catchAsync = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch((err) => next(err));
};

module.exports = catchAsync;
