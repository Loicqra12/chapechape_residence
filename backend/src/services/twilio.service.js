const twilio = require('twilio');
const logger = require('../utils/logger');

class TwilioService {
  constructor() {
    // Vérification des variables d'environnement
    if (!process.env.TWILIO_ACCOUNT_SID || !process.env.TWILIO_AUTH_TOKEN || !process.env.TWILIO_PHONE_NUMBER) {
      logger.warn('Configuration Twilio incomplète. Le service SMS ne fonctionnera pas correctement.');
      this.isConfigured = false;
      return;
    }
    
    this.client = new twilio(
      process.env.TWILIO_ACCOUNT_SID,
      process.env.TWILIO_AUTH_TOKEN
    );
    this.twilioNumber = process.env.TWILIO_PHONE_NUMBER;
    this.isConfigured = true;
    logger.info('Service Twilio initialisé avec succès');
  }

  async sendSMS(to, body) {
    if (!this.isConfigured) {
      logger.error('Tentative d\'envoi de SMS sans configuration Twilio complète');
      throw new Error('Service Twilio non configuré');
    }

    try {
      // Formatage international du numéro si nécessaire
      let formattedNumber = to;
      if (!to.startsWith('+')) {
        // Ajout du préfixe international pour les pays d'Afrique de l'Ouest si absent
        // Par défaut, nous utilisons +225 (Côte d'Ivoire) mais cela devrait être configuré selon le pays principal
        formattedNumber = `+225${to}`; 
      }

      const message = await this.client.messages.create({
        body,
        from: this.twilioNumber,
        to: formattedNumber
      });
      
      logger.info(`SMS envoyé avec succès à ${formattedNumber}. SID: ${message.sid}`);
      return message;
    } catch (error) {
      logger.error(`Erreur lors de l'envoi du SMS: ${error.message}`);
      throw error;
    }
  }

  // Méthode spécifique pour les notifications de réservation
  async sendBookingNotification(booking, type) {
    if (!booking) {
      throw new Error('Booking object is required');
    }

    // Si le client n'a pas de numéro de téléphone, impossible d'envoyer un SMS
    if (!booking.client || !booking.client.phoneNumber) {
      logger.warn(`Impossible d'envoyer un SMS pour la réservation ${booking._id}: Numéro de téléphone manquant`);
      return null;
    }

    let message;
    const residenceName = booking.residence?.title || 'votre résidence';
    const formattedDate = new Date(booking.visitDate).toLocaleDateString('fr-FR');

    switch (type) {
      case 'confirmation':
        message = `ChapeChape: Votre réservation pour "${residenceName}" est confirmée pour le ${formattedDate} à ${booking.visitTime}. Merci de votre confiance!`;
        break;
      case 'reminder':
        message = `ChapeChape: Rappel de votre visite à "${residenceName}" prévue pour demain ${formattedDate} à ${booking.visitTime}. A bientôt!`;
        break;
      case 'cancellation':
        message = `ChapeChape: Nous sommes désolés, votre réservation pour "${residenceName}" a été annulée. Contactez-nous pour plus d'informations.`;
        break;
      case 'payment':
        // Adapté aux méthodes de paiement africaines
        message = `ChapeChape: Paiement requis pour votre réservation à "${residenceName}". Vous pouvez payer via Orange Money, Wave, MTN Money ou en espèces lors de votre visite.`;
        break;
      default:
        message = `ChapeChape: Mise à jour de votre réservation pour "${residenceName}" prévue le ${formattedDate}. Veuillez consulter l'application pour plus de détails.`;
    }

    return this.sendSMS(booking.client.phoneNumber, message);
  }

  // Méthode spécifique pour envoyer des instructions de paiement adaptées aux méthodes africaines
  async sendPaymentInstructions(booking, paymentMethod) {
    if (!booking || !booking.client || !booking.client.phoneNumber) {
      logger.warn(`Impossible d'envoyer des instructions de paiement: Données manquantes`);
      return null;
    }
    
    let messageBody;
    const amount = booking.amount || '(montant dû)';
    const reference = `CHAPE${booking._id.toString().substring(0, 6)}`;
    const residenceName = booking.residence?.title || 'votre résidence';
    const formattedDate = new Date(booking.visitDate).toLocaleDateString('fr-FR');
    
    switch(paymentMethod) {
      case 'wave':
        messageBody = `ChapeChape: Pour finaliser votre réservation pour "${residenceName}" le ${formattedDate}, veuillez payer ${amount} FCFA via Wave au +225 07 07 07 07 07 avec la référence: ${reference}`;
        break;
      case 'orange_money':
        messageBody = `ChapeChape: Pour finaliser votre réservation pour "${residenceName}" le ${formattedDate}, veuillez payer ${amount} FCFA via Orange Money au #144*72# avec le code marchand: ${reference}`;
        break;
      case 'mtn_money':
        messageBody = `ChapeChape: Pour finaliser votre réservation pour "${residenceName}" le ${formattedDate}, veuillez payer ${amount} FCFA via MTN Money en composant *133# et en utilisant la référence: ${reference}`;
        break;
      case 'moov_money':
        messageBody = `ChapeChape: Pour finaliser votre réservation pour "${residenceName}" le ${formattedDate}, veuillez payer ${amount} FCFA via Moov Money en composant *155# et en utilisant la référence: ${reference}`;
        break;
      default:
        messageBody = `ChapeChape: Merci de finaliser le paiement de ${amount} FCFA pour votre réservation à "${residenceName}" le ${formattedDate}. Pour assistance, contactez-nous au +225 07 07 07 07 07.`;
    }
    
    logger.info(`Envoi d'instructions de paiement ${paymentMethod} pour la réservation ${booking._id}`);
    return this.sendSMS(booking.client.phoneNumber, messageBody);
  }
}

module.exports = new TwilioService();
