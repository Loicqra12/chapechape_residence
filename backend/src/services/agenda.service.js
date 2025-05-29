const Agenda = require('agenda');
const mongoose = require('mongoose');
const logger = require('../utils/logger');
const twilioService = require('./twilio.service');
const Booking = require('../models/booking.model');
const SMSMetrics = require('../models/sms_metrics.model');

// Initialiser Agenda avec la même connexion MongoDB que l'application
const agenda = new Agenda({
  mongo: mongoose.connection,
  processEvery: '1 minute',
  defaultConcurrency: 5,
  maxConcurrency: 20
});

// Définir les types de jobs
agenda.define('sendBookingReminder', async (job) => {
  try {
    const { bookingId } = job.attrs.data;
    
    const booking = await Booking.findById(bookingId)
      .populate('client', 'phoneNumber firstName lastName')
      .populate('residence', 'title address');
    
    if (!booking) {
      logger.warn(`Réservation ${bookingId} non trouvée pour l'envoi du rappel SMS`);
      return;
    }
    
    // Vérifier que la réservation est toujours confirmée
    if (booking.status !== 'confirmed') {
      logger.info(`Rappel SMS non envoyé pour la réservation ${bookingId} car son statut est ${booking.status}`);
      return;
    }
    
    // Envoyer le SMS de rappel
    const message = await twilioService.sendBookingNotification(booking, 'reminder');
    
    // Enregistrer les métriques
    await SMSMetrics.create({
      type: 'booking_reminder',
      recipient: booking.client._id,
      booking: bookingId,
      messageId: message?.sid || null,
      status: message?.status || 'failed',
      content: `Rappel pour la réservation à ${booking.residence.title}`
    });
    
    logger.info(`Rappel SMS envoyé pour la réservation ${bookingId}`);
  } catch (error) {
    logger.error(`Erreur lors de l'envoi du rappel SMS: ${error.message}`, error);
  }
});

agenda.define('sendStatusChangeNotification', async (job) => {
  try {
    const { bookingId, oldStatus, newStatus } = job.attrs.data;
    
    const booking = await Booking.findById(bookingId)
      .populate('client', 'phoneNumber firstName lastName')
      .populate('residence', 'title address');
    
    if (!booking) {
      logger.warn(`Réservation ${bookingId} non trouvée pour l'envoi de la notification de changement de statut`);
      return;
    }
    
    // Déterminer le type de notification en fonction du changement de statut
    let notificationType;
    
    switch (newStatus) {
      case 'confirmed':
        notificationType = 'confirmation';
        break;
      case 'cancelled':
        notificationType = 'cancellation';
        break;
      case 'completed':
        notificationType = 'completed';
        break;
      default:
        notificationType = 'status_change';
    }
    
    // Envoyer le SMS de notification
    const message = await twilioService.sendBookingNotification(booking, notificationType);
    
    // Enregistrer les métriques
    await SMSMetrics.create({
      type: `booking_${notificationType}`,
      recipient: booking.client._id,
      booking: bookingId,
      messageId: message?.sid || null,
      status: message?.status || 'failed',
      content: `Notification de changement de statut (${oldStatus} → ${newStatus}) pour la réservation à ${booking.residence.title}`
    });
    
    logger.info(`Notification SMS de changement de statut envoyée pour la réservation ${bookingId} (${oldStatus} → ${newStatus})`);
  } catch (error) {
    logger.error(`Erreur lors de l'envoi de la notification de changement de statut: ${error.message}`, error);
  }
});

agenda.define('sendPaymentReminderAfricaSpecific', async (job) => {
  try {
    const { bookingId, paymentMethod } = job.attrs.data;
    
    const booking = await Booking.findById(bookingId)
      .populate('client', 'phoneNumber firstName lastName')
      .populate('residence', 'title address');
    
    if (!booking) {
      logger.warn(`Réservation ${bookingId} non trouvée pour l'envoi du rappel de paiement`);
      return;
    }
    
    // Personnaliser le message selon la méthode de paiement africaine
    let paymentInstructions = '';
    
    switch (paymentMethod) {
      case 'wave':
        paymentInstructions = `Pour payer avec Wave, envoyez ${booking.amount} FCFA au numéro +225 XX XX XX XX en utilisant le code de référence: CHAPE${booking._id.toString().substring(0, 6)}`;
        break;
      case 'orange_money':
        paymentInstructions = `Pour payer avec Orange Money, envoyez ${booking.amount} FCFA au numéro #144*72# et utilisez le code marchand: CHAP${booking._id.toString().substring(0, 4)}`;
        break;
      case 'mtn_money':
        paymentInstructions = `Pour payer avec MTN Money, composez *133# et choisissez "Payer facture". Utilisez le code marchand CHAPECHAPE et la référence: ${booking._id.toString().substring(0, 8)}`;
        break;
      case 'moov_money':
        paymentInstructions = `Pour payer avec Moov Money, composez *155# et choisissez "Payer facture". Code: CHAPE${booking._id.toString().substring(0, 6)}`;
        break;
      default:
        paymentInstructions = `Pour finaliser votre réservation, merci de procéder au paiement de ${booking.amount} FCFA. Pour toute assistance, contactez-nous au +225 XX XX XX XX.`;
    }
    
    // Message complet
    const messageBody = `ChapeChape: Rappel de paiement pour votre réservation à "${booking.residence.title}" le ${new Date(booking.visitDate).toLocaleDateString('fr-FR')}. ${paymentInstructions}`;
    
    // Envoyer le SMS personnalisé
    const message = await twilioService.sendSMS(booking.client.phoneNumber, messageBody);
    
    // Enregistrer les métriques
    await SMSMetrics.create({
      type: 'payment_reminder',
      recipient: booking.client._id,
      booking: bookingId,
      messageId: message?.sid || null,
      status: message?.status || 'failed',
      content: messageBody,
      metadata: {
        paymentMethod
      }
    });
    
    logger.info(`Rappel de paiement ${paymentMethod} envoyé pour la réservation ${bookingId}`);
  } catch (error) {
    logger.error(`Erreur lors de l'envoi du rappel de paiement: ${error.message}`, error);
  }
});

// Fonction pour planifier un rappel de réservation
const scheduleBookingReminder = async (bookingId, visitDate) => {
  try {
    // Calculer la date du rappel (la veille de la visite à 18h)
    const reminderDate = new Date(visitDate);
    reminderDate.setDate(reminderDate.getDate() - 1);
    reminderDate.setHours(18, 0, 0, 0);
    
    // Vérifier que la date de rappel est dans le futur
    if (reminderDate <= new Date()) {
      logger.warn(`La date de rappel pour la réservation ${bookingId} est déjà passée`);
      return;
    }
    
    // Planifier le job
    await agenda.schedule(reminderDate, 'sendBookingReminder', { bookingId });
    
    logger.info(`Rappel SMS planifié pour la réservation ${bookingId} le ${reminderDate.toISOString()}`);
    return true;
  } catch (error) {
    logger.error(`Erreur lors de la planification du rappel SMS: ${error.message}`);
    return false;
  }
};

// Fonction pour notifier un changement de statut de réservation
const notifyBookingStatusChange = async (bookingId, oldStatus, newStatus) => {
  try {
    // Envoyer immédiatement la notification
    await agenda.now('sendStatusChangeNotification', { bookingId, oldStatus, newStatus });
    
    logger.info(`Notification de changement de statut programmée pour la réservation ${bookingId} (${oldStatus} → ${newStatus})`);
    return true;
  } catch (error) {
    logger.error(`Erreur lors de la programmation de la notification de changement de statut: ${error.message}`);
    return false;
  }
};

// Fonction pour envoyer un rappel de paiement avec instructions spécifiques aux méthodes africaines
const sendPaymentReminderAfricaSpecific = async (bookingId, paymentMethod) => {
  try {
    // Envoyer immédiatement le rappel de paiement
    await agenda.now('sendPaymentReminderAfricaSpecific', { bookingId, paymentMethod });
    
    logger.info(`Rappel de paiement ${paymentMethod} programmé pour la réservation ${bookingId}`);
    return true;
  } catch (error) {
    logger.error(`Erreur lors de la programmation du rappel de paiement: ${error.message}`);
    return false;
  }
};

// Démarrer le service Agenda
const startAgenda = async () => {
  try {
    await agenda.start();
    logger.info('Service Agenda démarré avec succès pour les notifications automatiques');
    return agenda;
  } catch (error) {
    logger.error(`Erreur lors du démarrage du service Agenda: ${error.message}`);
    throw error;
  }
};

module.exports = {
  agenda,
  startAgenda,
  scheduleBookingReminder,
  notifyBookingStatusChange,
  sendPaymentReminderAfricaSpecific
};
