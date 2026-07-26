const jwt = require('../utils/jwt');
const User = require('../models/user.model');

/**
 * Auth optionnelle : peuplereq.user si Bearer valide, sinon continue sans erreur.
 * Utile pour GET publics (détail résidence) afin de tracker les vues authentifiées.
 */
exports.optionalProtect = async (req, res, next) => {
  try {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      return next();
    }

    const token = header.split(' ')[1];
    if (!token) return next();

    const decoded = jwt.verifyToken(token, 'JWT_SECRET');
    const user = await User.findById(decoded.id);
    if (user && user.isActive !== false) {
      req.user = user;
    }
  } catch (_) {
    // Token invalide / expiré → route reste publique
  }
  return next();
};
