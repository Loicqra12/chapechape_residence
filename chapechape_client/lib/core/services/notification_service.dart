import 'package:dio/dio.dart';
import '../models/notification_model.dart';
import 'api_service.dart';
import '../utils/logger.dart';


class NotificationService {
  final ApiService _apiService;
  final AppLogger _logger = AppLogger('NotificationService');

  NotificationService._({
    required ApiService apiService,
  }) : _apiService = apiService;

  static Future<NotificationService> initialize() async {
    final apiService = await ApiService.initialize();
    return NotificationService._(apiService: apiService);
  }

  // Récupérer les notifications de l'utilisateur
  Future<List<NotificationModel>> getNotifications({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiService.get(
        '/notifications',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      
      if (response.data['success'] == true && response.data['data'] != null) {
        final List<dynamic> notificationsData = response.data['data'];
        return notificationsData.map((json) => _mapToNotificationModel(json)).toList();
      }
      
      return [];
    } on DioException catch (e) {
      _logger.error('Erreur lors de la récupération des notifications', e);
      rethrow;
    }
  }
  
  // Obtenir le nombre de notifications non lues
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.get('/notifications/unread/count');
      if (response.data['success'] == true) {
        return response.data['data']['count'] ?? 0;
      }
      return 0;
    } on DioException catch (e) {
      _logger.error('Erreur lors du comptage des notifications non lues', e);
      return 0;
    }
  }
  
  // Marquer une notification comme lue
  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await _apiService.put('/notifications/$notificationId/read');
      return response.data['success'] == true;
    } on DioException catch (e) {
      _logger.error('Erreur lors du marquage de la notification', e);
      rethrow;
    }
  }
  
  // Marquer toutes les notifications comme lues
  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiService.put('/notifications/read-all');
      return response.data['success'] == true;
    } on DioException catch (e) {
      _logger.error('Erreur lors du marquage de toutes les notifications', e);
      rethrow;
    }
  }
  
  // Marquer une notification comme supprimée
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await _apiService.delete('/notifications/$notificationId');
      return response.data['success'] == true;
    } on DioException catch (e) {
      _logger.error('Erreur lors de la suppression de la notification', e);
      return false;
    }
  }
  
  // Mapper les données JSON en modèle de notification
  NotificationModel _mapToNotificationModel(Map<String, dynamic> json) {
    return NotificationModel.fromJson(json);
  }

  // ================= FONCTIONNALITÉS SMS (TWILIO) =================
  
  /// Demander l'envoi d'un SMS de confirmation pour une réservation
  ///
  /// [bookingId] L'identifiant de la réservation
  Future<bool> requestBookingSmsConfirmation(String bookingId) async {
    try {
      final response = await _apiService.post(
        '/bookings/$bookingId/request-sms',
        data: {
          'type': 'confirmation'
        },
      );
      return response.data['success'] == true;
    } catch (e) {
      _logger.error('Erreur lors de la demande de SMS de confirmation', e);
      return false;
    }
  }

  /// Demander l'envoi d'un SMS de rappel pour une réservation
  ///
  /// [bookingId] L'identifiant de la réservation
  Future<bool> requestBookingSmsReminder(String bookingId) async {
    try {
      final response = await _apiService.post(
        '/bookings/$bookingId/request-sms',
        data: {
          'type': 'reminder'
        },
      );
      return response.data['success'] == true;
    } catch (e) {
      _logger.error('Erreur lors de la demande de SMS de rappel', e);
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

  /// Formater un numéro de téléphone pour l'API
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
  
  // ================= VÉRIFICATION DU NUMÉRO DE TÉLÉPHONE PAR SMS =================
  
  /// Demander un code de vérification par SMS
  /// 
  /// [phoneNumber] Le numéro de téléphone à vérifier
  /// 
  /// Retourne un map contenant codeId et expiresAt en cas de succès
  Future<Map<String, dynamic>?> requestVerificationCode(String phoneNumber) async {
    try {
      final formattedNumber = formatPhoneNumber(phoneNumber);
      
      final response = await _apiService.post(
        '/api/auth/request-verification-code',
        data: {
          'phoneNumber': formattedNumber
        },
      );
      
      if (response.data['success'] == true && response.data['data'] != null) {
        return {
          'codeId': response.data['data']['codeId'],
          'expiresAt': response.data['data']['expiresAt'],
        };
      }
      
      _logger.error('Erreur lors de la demande de code de vérification: ${response.data['message']}');
      return null;
    } catch (e) {
      _logger.error('Erreur lors de la demande de code de vérification', e);
      rethrow;
    }
  }
  
  /// Vérifier un code reçu par SMS
  /// 
  /// [phoneNumber] Le numéro de téléphone à vérifier
  /// [code] Le code reçu par SMS
  /// [codeId] L'identifiant du code (optionnel)
  Future<bool> verifyCode(String phoneNumber, String code, {String? codeId}) async {
    try {
      final formattedNumber = formatPhoneNumber(phoneNumber);
      
      final Map<String, dynamic> data = {
        'phoneNumber': formattedNumber,
        'code': code,
      };
      
      if (codeId != null) {
        data['codeId'] = codeId;
      }
      
      final response = await _apiService.post(
        '/api/auth/verify-code',
        data: data,
      );
      
      return response.data['success'] == true;
    } catch (e) {
      _logger.error('Erreur lors de la vérification du code', e);
      return false;
    }
  }
  
  /// Renvoyer un code de vérification
  /// 
  /// [phoneNumber] Le numéro de téléphone
  Future<bool> resendVerificationCode(String phoneNumber) async {
    try {
      final formattedNumber = formatPhoneNumber(phoneNumber);
      
      final response = await _apiService.post(
        '/api/auth/resend-verification-code',
        data: {
          'phoneNumber': formattedNumber
        },
      );
      
      return response.data['success'] == true;
    } catch (e) {
      _logger.error('Erreur lors du renvoi du code de vérification', e);
      return false;
    }
  }
  
  /// Envoyer un SMS personnalisé à un numéro de téléphone
  ///
  /// [phoneNumber] Le numéro de téléphone du destinataire
  /// [message] Le contenu du message à envoyer
  Future<bool> sendCustomSms({required String phoneNumber, required String message}) async {
    try {
      final formattedNumber = formatPhoneNumber(phoneNumber);
      
      final response = await _apiService.post(
        '/api/sms/send',
        data: {
          'phoneNumber': formattedNumber,
          'message': message,
          'type': 'custom'
        },
      );
      
      return response.data['success'] == true;
    } catch (e) {
      _logger.error('Erreur lors de l\'envoi du SMS personnalisé', e);
      return false;
    }
  }
  
  // Obtenir un titre basé sur le type de notification
  String _getTitleFromType(String? type) {
    switch (type) {
      case 'booking_confirmed':
        return 'Réservation confirmée';
      case 'booking_cancelled':
        return 'Réservation annulée';
      case 'payment_received':
        return 'Paiement reçu';
      case 'favorite_added':
        return 'Nouvelle propriété favorite';
      case 'system_maintenance':
        return 'Maintenance système';
      case 'account_update':
        return 'Mise à jour du compte';
      default:
        return 'Notification';
    }
  }
}