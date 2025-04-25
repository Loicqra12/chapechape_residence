/**
 * Classe d'erreur personnalisée pour faciliter la gestion des erreurs API
 * @class ErrorResponse
 * @extends Error
 */
class ErrorResponse extends Error {
  /**
   * Crée une instance de ErrorResponse
   * @param {string} message - Message d'erreur
   * @param {number} statusCode - Code de statut HTTP
   */
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

module.exports = ErrorResponse;
