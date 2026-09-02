const twilio = require('twilio');
const logger = require('../utils/logger');
const { normalizePhoneToE164, isValidE164 } = require('../utils/phone.util');

const DEFAULT_PHONE_COUNTRY = process.env.DEFAULT_PHONE_COUNTRY || 'CI';

function maskPhoneNumber(phoneNumber) {
  if (!phoneNumber || typeof phoneNumber !== 'string') {
    return '***';
  }

  if (phoneNumber.length <= 4) {
    return '***';
  }

  return `${phoneNumber.slice(0, 4)}***${phoneNumber.slice(-2)}`;
}

/** Guest sur un Booking : le schéma utilise `user` ; l’ancien code peuplait `client`. */
function guestFromBooking(booking) {
  return booking?.user || booking?.client;
}

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
    this.twilioWhatsAppNumber = process.env.TWILIO_WHATSAPP_NUMBER;
    this.isConfigured = true;
    
    // Vérifier si WhatsApp est configuré
    this.isWhatsAppConfigured = !!this.twilioWhatsAppNumber;
    
    logger.info('Service Twilio initialisé', {
      accountSidConfigured: !!process.env.TWILIO_ACCOUNT_SID,
      phoneNumberConfigured: !!process.env.TWILIO_PHONE_NUMBER,
      whatsAppConfigured: this.isWhatsAppConfigured,
      defaultCountry: DEFAULT_PHONE_COUNTRY
    });

    if (this.isWhatsAppConfigured) {
      logger.info('WhatsApp Business activé');
    } else {
      logger.warn('WhatsApp Business non configuré - variable TWILIO_WHATSAPP_NUMBER manquante');
    }
  }

  async sendSMS(to, body) {
    if (!this.isConfigured) {
      logger.error('Tentative d\'envoi de SMS sans configuration Twilio complète');
      throw new Error('Service Twilio non configuré');
    }

    try {
      const formattedNumber = normalizePhoneToE164(to, DEFAULT_PHONE_COUNTRY);
      if (!isValidE164(formattedNumber)) {
        logger.warn('Numéro SMS invalide après normalisation', {
          original: maskPhoneNumber(to),
          normalized: maskPhoneNumber(formattedNumber),
          defaultCountry: DEFAULT_PHONE_COUNTRY
        });
        throw new Error('Numéro destinataire invalide (format E.164 requis)');
      }

      const message = await this.client.messages.create({
        body,
        from: this.twilioNumber,
        to: formattedNumber
      });
      
      logger.info(`SMS envoyé avec succès à ${maskPhoneNumber(formattedNumber)}. SID: ${message.sid}`);
      return message;
    } catch (error) {
      logger.error(`Erreur lors de l'envoi du SMS: ${error.message}`);
      throw error;
    }
  }

  // ===== WHATSAPP BUSINESS METHODS =====
  
  async sendWhatsAppMessage(to, body) {
    if (!this.isConfigured) {
      logger.error('Tentative d\'envoi de WhatsApp sans configuration Twilio complète');
      throw new Error('Service Twilio non configuré');
    }
    
    if (!this.isWhatsAppConfigured) {
      logger.error('Tentative d\'envoi de WhatsApp sans configuration WhatsApp Business');
      throw new Error('WhatsApp Business non configuré - variable TWILIO_WHATSAPP_NUMBER manquante');
    }

    try {
      const formattedNumber = normalizePhoneToE164(to, DEFAULT_PHONE_COUNTRY);
      if (!isValidE164(formattedNumber)) {
        logger.warn('Numéro WhatsApp invalide après normalisation', {
          original: maskPhoneNumber(to),
          normalized: maskPhoneNumber(formattedNumber),
          defaultCountry: DEFAULT_PHONE_COUNTRY
        });
        throw new Error('Numéro destinataire WhatsApp invalide (format E.164 requis)');
      }

      const message = await this.client.messages.create({
        body,
        from: this.twilioWhatsAppNumber,
        to: `whatsapp:${formattedNumber}`
      });
      
      logger.info(`WhatsApp envoyé avec succès à ${maskPhoneNumber(formattedNumber)}. SID: ${message.sid}`);
      return message;
    } catch (error) {
      logger.error(`Erreur lors de l'envoi du WhatsApp: ${error.message}`);
      throw error;
    }
  }

  // Méthode spécifique pour envoyer des instructions de paiement WhatsApp (version riche)
  async sendWhatsAppPaymentInstructions(booking, paymentMethod) {
    const guest = guestFromBooking(booking);
    if (!booking || !guest?.phoneNumber) {
      logger.warn(`Impossible d'envoyer des instructions de paiement WhatsApp: Données manquantes`);
      return null;
    }
    
    const amount = booking.amount || '(montant dû)';
    const reference = `CHAPE${booking._id.toString().substring(0, 6)}`;
    const residenceName = booking.residence?.title || 'votre résidence';
    const formattedDate = new Date(booking.visitDate).toLocaleDateString('fr-FR');
    
    let messageBody;
    
    switch(paymentMethod) {
      case 'wave':
        messageBody = `🏠 *ChapeChape Résidence*\n\n💳 *Instructions Paiement Wave*\n\n🏡 Résidence: *${residenceName}*\n📅 Date: *${formattedDate}*\n💰 Montant: *${amount} FCFA*\n\n🔵 *Étapes Wave:*\n1️⃣ Ouvrez votre app Wave\n2️⃣ Envoyez vers: *+225 07 07 07 07 07*\n3️⃣ Montant: *${amount} FCFA*\n4️⃣ Référence: *${reference}*\n\n✅ Confirmation automatique après paiement !`;
        break;
      case 'orange_money':
        messageBody = `🏠 *ChapeChape Résidence*\n\n💳 *Instructions Orange Money*\n\n🏡 Résidence: *${residenceName}*\n📅 Date: *${formattedDate}*\n💰 Montant: *${amount} FCFA*\n\n🟠 *Étapes Orange Money:*\n1️⃣ Composez: *#144*72#*\n2️⃣ Code marchand: *${reference}*\n3️⃣ Montant: *${amount}*\n4️⃣ Confirmez avec votre PIN\n\n✅ Confirmation automatique après paiement !`;
        break;
      case 'mtn_money':
        messageBody = `🏠 *ChapeChape Résidence*\n\n💳 *Instructions MTN Money*\n\n🏡 Résidence: *${residenceName}*\n📅 Date: *${formattedDate}*\n💰 Montant: *${amount} FCFA*\n\n🟡 *Étapes MTN Money:*\n1️⃣ Composez: *133#*\n2️⃣ Choisir "Transfert d'argent"\n3️⃣ Référence: *${reference}*\n4️⃣ Montant: *${amount}*\n\n✅ Confirmation automatique après paiement !`;
        break;
      case 'moov_money':
        messageBody = `🏠 *ChapeChape Résidence*\n\n💳 *Instructions Moov Money*\n\n🏡 Résidence: *${residenceName}*\n📅 Date: *${formattedDate}*\n💰 Montant: *${amount} FCFA*\n\n🔴 *Étapes Moov Money:*\n1️⃣ Composez: *155#*\n2️⃣ Choisir "Paiement marchand"\n3️⃣ Référence: *${reference}*\n4️⃣ Montant: *${amount}*\n\n✅ Confirmation automatique après paiement !`;
        break;
      default:
        messageBody = `🏠 *ChapeChape Résidence*\n\n💳 *Finalisation du paiement*\n\n🏡 Résidence: *${residenceName}*\n📅 Date: *${formattedDate}*\n💰 Montant: *${amount} FCFA*\n\n💬 Répondez à ce message pour choisir votre méthode de paiement:\n• Wave\n• Orange Money\n• MTN Money\n• Moov Money\n\n📞 Assistance: +225 07 07 07 07 07`;
    }
    
    logger.info(`Envoi d'instructions de paiement WhatsApp ${paymentMethod} pour la réservation ${booking._id}`);
    return this.sendWhatsAppMessage(guest.phoneNumber, messageBody);
  }

  // ===== FIN WHATSAPP METHODS =====

  // ✅ NOUVELLE MÉTHODE - Notifications pour le modèle Reservation (migré)
  async sendReservationNotification(reservation, type, options = {}) {
    if (!reservation) {
      throw new Error('Reservation object is required');
    }

    // Si le client n'a pas de numéro de téléphone, impossible d'envoyer un SMS
    if (!reservation.user || !reservation.user.phoneNumber) {
      logger.warn(`Impossible d'envoyer un SMS pour la réservation ${reservation._id}: Numéro de téléphone manquant`);
      return null;
    }

    let message;
    const residenceName = reservation.residence?.title || 'votre résidence';
    const checkInDate = new Date(reservation.checkIn).toLocaleDateString('fr-FR');
    const checkOutDate = new Date(reservation.checkOut).toLocaleDateString('fr-FR');

    switch (type) {
      case 'confirmation':
        message = `ChapeChape: Votre réservation pour "${residenceName}" est confirmée du ${checkInDate} au ${checkOutDate}. Merci de votre confiance!`;
        break;
      case 'reminder':
      case 'arrival_reminder':
        message = `ChapeChape: Rappel de votre arrivée à "${residenceName}" prévue demain ${checkInDate}. Bon séjour!`;
        break;
      case 'departure_reminder':
        message = `ChapeChape: Rappel de votre départ de "${residenceName}" prévu demain ${checkOutDate}. Merci pour votre séjour!`;
        break;
      case 'cancellation':
        message = `ChapeChape: Nous sommes désolés, votre réservation pour "${residenceName}" a été annulée. Contactez-nous pour plus d'informations.`;
        break;
      case 'payment':
      case 'payment_deadline':
        const deadline = options.deadline ? new Date(options.deadline).toLocaleDateString('fr-FR') : 'bientôt';
        message = `ChapeChape: Paiement requis avant ${deadline} pour votre réservation à "${residenceName}". Orange Money, Wave, MTN Money ou espèces acceptés.`;
        break;
      case 'expired':
        message = `ChapeChape: Votre réservation pour "${residenceName}" a expiré car le paiement n'a pas été effectué dans les délais.`;
        break;
      case 'approved':
        message = `ChapeChape: Bonne nouvelle! Votre réservation pour "${residenceName}" a été approuvée. Procédez au paiement pour confirmer.`;
        break;
      case 'rejected':
        message = `ChapeChape: Votre demande de réservation pour "${residenceName}" n'a pas pu être acceptée. Contactez-nous pour plus d'informations.`;
        break;
      default:
        message = `ChapeChape: Mise à jour de votre réservation pour "${residenceName}" du ${checkInDate} au ${checkOutDate}. Consultez l'application pour plus de détails.`;
    }

    return this.sendSMS(reservation.user.phoneNumber, message);
  }

  // Méthode spécifique pour envoyer des instructions de paiement Reservation
  async sendReservationPaymentInstructions(reservation, paymentMethod = 'mobile') {
    if (!reservation || !reservation.user || !reservation.user.phoneNumber) {
      logger.warn(`Impossible d'envoyer des instructions de paiement: Données manquantes`);
      return null;
    }

    const residenceName = reservation.residence?.title || 'votre résidence';
    const amount = reservation.totalPrice || 'le montant requis';
    
    let message;
    switch (paymentMethod) {
      case 'orange_money':
        message = `ChapeChape: Pour finaliser votre réservation "${residenceName}", composez *144# et suivez les instructions pour payer ${amount} FCFA.`;
        break;
      case 'wave':
        message = `ChapeChape: Pour finaliser votre réservation "${residenceName}", utilisez l'app Wave pour payer ${amount} FCFA vers notre numéro marchand.`;
        break;
      case 'mtn_money':
        message = `ChapeChape: Pour finaliser votre réservation "${residenceName}", composez *126# et suivez les instructions pour payer ${amount} FCFA.`;
        break;
      default:
        message = `ChapeChape: Instructions de paiement pour "${residenceName}": ${amount} FCFA via Orange Money (*144#), Wave, MTN Money (*126#) ou espèces. Réf: ${reservation._id.toString().substr(-6)}`;
    }

    return this.sendSMS(reservation.user.phoneNumber, message);
  }

  // Méthode spécifique pour envoyer des instructions de paiement adaptées aux méthodes africaines
  async sendPaymentInstructions(booking, paymentMethod) {
    const guest = guestFromBooking(booking);
    if (!booking || !guest?.phoneNumber) {
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
    return this.sendSMS(guest.phoneNumber, messageBody);
  }
}

module.exports = new TwilioService();
