import 'package:flutter/foundation.dart';
import '../api/api_service.dart';

/// Service pour gérer l'envoi de SMS via l'API Twilio du backend
class SmsService {
  final ApiService _apiService;
  
  SmsService({required ApiService apiService}) : _apiService = apiService;

  /// Envoyer un SMS simple
  ///
  /// [phoneNumber] Le numéro de téléphone du destinataire
  /// [message] Le contenu du message à envoyer
  Future<bool> sendSms(String phoneNumber, String message) async {
    try {
      final response = await _apiService.post(
        '/api/sms/send',
        data: {
          'to': phoneNumber,
          'body': message,
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi du SMS: $e');
      return false;
    }
  }

  /// Envoyer une notification SMS pour une réservation
  ///
  /// [bookingId] L'identifiant de la réservation
  /// [notificationType] Le type de notification (confirmation, reminder, cancellation, payment)
  Future<bool> sendBookingNotification(String bookingId, String notificationType) async {
    try {
      final response = await _apiService.post(
        '/api/sms/booking',
        data: {
          'bookingId': bookingId,
          'notificationType': notificationType,
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi de la notification SMS: $e');
      return false;
    }
  }

  /// Envoyer des instructions de paiement pour les méthodes africaines
  ///
  /// [bookingId] L'identifiant de la réservation
  /// [paymentMethod] La méthode de paiement (wave, orange_money, mtn_money, moov_money, cash, other)
  Future<bool> sendPaymentInstructions(String bookingId, String paymentMethod) async {
    try {
      final response = await _apiService.post(
        '/api/sms/payment-instructions',
        data: {
          'bookingId': bookingId,
          'paymentMethod': paymentMethod,
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi des instructions de paiement: $e');
      return false;
    }
  }

  /// Vérifier si un numéro de téléphone est valide pour l'Afrique de l'Ouest
  ///
  /// Cette méthode valide les formats de numéros pour les pays d'Afrique de l'Ouest
  /// comme la Côte d'Ivoire, le Sénégal, etc.
  bool isValidPhoneNumber(String phoneNumber) {
    // Supprime les espaces, tirets et parenthèses
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Vérifie les formats suivants:
    // 1. Numéro international complet commençant par + (ex: +22501234567)
    // 2. Numéro avec code pays sans + (ex: 22501234567)
    // 3. Numéro local (ex: 01234567)
    final regexInternational = RegExp(r'^\+[0-9]{10,15}$');
    final regexWithCountryCode = RegExp(r'^[0-9]{11,15}$');
    final regexLocal = RegExp(r'^[0-9]{8,10}$');
    
    return regexInternational.hasMatch(cleanPhone) || 
           regexWithCountryCode.hasMatch(cleanPhone) ||
           regexLocal.hasMatch(cleanPhone);
  }

  /// Formater un numéro de téléphone pour l'affichage
  String formatPhoneNumber(String phoneNumber) {
    // Supprime les espaces, tirets et parenthèses
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Si le numéro commence par +, c'est déjà un format international
    if (cleanPhone.startsWith('+')) {
      return cleanPhone;
    }
    
    // Si le numéro commence par 225, 221, etc. (codes pays), ajouter le +
    if (RegExp(r'^(225|221|226|227|228|229|233|234)').hasMatch(cleanPhone)) {
      return '+$cleanPhone';
    }
    
    // Sinon, supposer que c'est un numéro ivoirien (remplacer par le pays par défaut)
    return '+225$cleanPhone';
  }
}
