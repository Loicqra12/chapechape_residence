/**
 * Wrapper pour gérer les erreurs asynchrones dans les contrôleurs
 * Évite d'avoir à utiliser try-catch dans chaque contrôleur
 */
const asyncHandler = fn => (req, res, next) =>
    Promise.resolve(fn(req, res, next)).catch(next);

module.exports = asyncHandler;
