/**
 * Point d'entrée pour toutes les erreurs de domaine
 * Facilite l'importation et améliore la clarté du code
 */

const BookingErrors = require('./bookingErrors');
const ResidenceErrors = require('./residenceErrors');

module.exports = {
    BookingErrors,
    ResidenceErrors
};
