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
      
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        // Backend actuel: { success, notifications, total, page, pages }
        final rawNotifications = data['notifications'] ?? data['data'];
        if (rawNotifications is List) {
          return rawNotifications
              .whereType<Map>()
              .map((json) =>
                  _mapToNotificationModel(Map<String, dynamic>.from(json)))
              .toList();
        }
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
    final id = (json['_id'] ?? json['id'] ?? '').toString();
    final message = (json['message'] ?? '').toString();
    final title = (json['title'] ??
            _getTitleFromType(json['type']?.toString()) ??
            'Notification')
        .toString();
    final read = json['read'] == true || json['isRead'] == true;
    final timestampRaw = json['createdAt'] ?? json['timestamp'];
    final timestamp = DateTime.tryParse(timestampRaw?.toString() ?? '') ??
        DateTime.now();
    final data = json['data'];
    String? actionUrl;
    if (data is Map) {
      final dynamic reservationId = data['reservationId'] ?? data['bookingId'];
      if (reservationId != null && reservationId.toString().isNotEmpty) {
        actionUrl = '/bookings';
      }
    }

    return NotificationModel(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: read,
      imageUrl: json['imageUrl']?.toString(),
      actionUrl: actionUrl ?? json['actionUrl']?.toString(),
      type: json['type']?.toString(),
    );
  }

  // ================= FONCTIONNALITÉS SMS (TWILIO) =================
  
  /// Demander l'envoi d'un SMS de confirmation pour une réservation
  ///
  /// [bookingId] L'identifiant de la réservation
  Future<bool> requestBookingSmsConfirmation(String bookingId) async {
    try {
      final response = await _apiService.post(
        '/sms/reservation',
        data: {
          'bookingId': bookingId,
          'notificationType': 'confirmation'
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
        '/sms/reservation',
        data: {
          'bookingId': bookingId,
          'notificationType': 'reminder'
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
        '/auth/request-verification-code',
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
        '/auth/verify-code',
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
        '/auth/resend-verification-code',
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
        '/sms/send',
        data: {
          'to': formattedNumber,
          'body': message,
        },
      );
      
      return response.data['success'] == true;
    } catch (e) {
      _logger.error('Erreur lors de l\'envoi du SMS personnalisé', e);
      return false;
    }
  }

  /// Envoyer des instructions de paiement par SMS selon la méthode choisie
  ///
  /// [bookingId] L'identifiant de la réservation
  /// [paymentMethod] La méthode de paiement (wave, orange_money, mtn_money, moov_money, cash, credit_card)
  /// [phoneNumber] Le numéro de téléphone du destinataire (optionnel, utilise celui de l'utilisateur connecté si non fourni)
  Future<bool> sendPaymentInstructionsSms({
    required String bookingId,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    try {
      final response = await _apiService.post(
        '/sms/reservation/payment-instructions',
        data: {
          'bookingId': bookingId,
          'paymentMethod': paymentMethod,
          if (phoneNumber != null) 'phoneNumber': formatPhoneNumber(phoneNumber),
        },
      );
      
      if (response.data['success'] == true) {
        _logger.info('Instructions de paiement $paymentMethod envoyées pour la réservation $bookingId');
        return true;
      } else {
        _logger.error('Erreur lors de l\'envoi des instructions: ${response.data['message']}');
        return false;
      }
    } catch (e) {
      _logger.error('Erreur lors de l\'envoi des instructions de paiement', e);
      return false;
    }
  }

  /// Générer un message d'instructions de paiement local (fallback)
  ///
  /// [paymentMethod] La méthode de paiement
  /// [amount] Le montant à payer
  /// [reference] La référence de paiement
  /// [residenceName] Le nom de la résidence
  String generatePaymentInstructionsMessage({
    required String paymentMethod,
    required double amount,
    required String reference,
    required String residenceName,
  }) {
    final formattedAmount = amount.toStringAsFixed(0);
    
    switch (paymentMethod.toLowerCase()) {
      case 'wave':
        return 'ChapeChape: Pour finaliser votre réservation "$residenceName", '
            'payez $formattedAmount FCFA via Wave en scannant le QR code '
            'ou en envoyant au +225 07 88 88 88 88 avec la référence: $reference';
            
      case 'orange_money':
        return 'ChapeChape: Pour finaliser votre réservation "$residenceName", '
            'payez $formattedAmount FCFA via Orange Money. '
            'Composez #144*1*1# et utilisez le code marchand: $reference';
            
      case 'mtn_money':
        return 'ChapeChape: Pour finaliser votre réservation "$residenceName", '
            'payez $formattedAmount FCFA via MTN Money. '
            'Composez *133# > Paiements > Marchands et utilisez la référence: $reference';
            
      case 'moov_money':
        return 'ChapeChape: Pour finaliser votre réservation "$residenceName", '
            'payez $formattedAmount FCFA via Moov Money. '
            'Composez *155# > Paiement facture > Marchands avec la référence: $reference';
            
      case 'cash':
        return 'ChapeChape: Votre réservation "$residenceName" est confirmée. '
            'Montant à régler: $formattedAmount FCFA en espèces lors de votre arrivée. '
            'Référence: $reference';
            
      case 'credit_card':
      case 'card':
        return 'ChapeChape: Finalisez le paiement de votre réservation "$residenceName" '
            'par carte bancaire via notre plateforme sécurisée. '
            'Montant: $formattedAmount FCFA - Référence: $reference';
            
      default:
        return 'ChapeChape: Finalisez le paiement de $formattedAmount FCFA '
            'pour votre réservation "$residenceName". '
            'Référence: $reference - Contactez-nous au +225 07 07 07 07 07 pour assistance.';
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