import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/config/app_config_manager.dart';

/// Service pour gérer la vérification SMS des partenaires
class PartnerVerificationService {
  late final Dio _dio;
  
  PartnerVerificationService() {
    _dio = Dio(BaseOptions(
      baseUrl: '${AppConfigManager.apiBaseUrl}/api/partners/verify-phone',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Ajouter l'interceptor d'authentification
    _dio.interceptors.add(AuthInterceptor());
    
    // Ajouter l'interceptor de logs
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  /// Demander un code de vérification SMS ou WhatsApp
  Future<VerificationRequestResult> requestVerification({
    required String phoneNumber,
    required String reason,
    String channel = 'sms',
  }) async {
    try {
      final response = await _dio.post('/request', data: {
        'phoneNumber': phoneNumber,
        'reason': reason,
        'channel': channel,
      });
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return VerificationRequestResult(
          success: true,
          message: response.data['message'],
          expiresIn: response.data['expiresIn'],
          attemptsRemaining: response.data['attemptsRemaining'],
        );
      } else {
        return VerificationRequestResult(
          success: false,
          message: response.data['message'] ?? 'Erreur inconnue',
        );
      }
    } on DioException catch (e) {
      return VerificationRequestResult(
        success: false,
        message: _handleDioError(e),
      );
    } catch (e) {
      return VerificationRequestResult(
        success: false,
        message: 'Erreur inattendue: ${e.toString()}',
      );
    }
  }

  /// Confirmer le code de vérification
  Future<VerificationConfirmResult> confirmVerification({
    required String code,
    bool setupPayouts = false,
  }) async {
    try {
      final response = await _dio.post('/confirm', data: {
        'code': code,
        'setupPayouts': setupPayouts,
      });
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return VerificationConfirmResult(
          success: true,
          message: response.data['message'],
          partner: response.data['partner'] != null 
              ? PartnerInfo.fromJson(response.data['partner'])
              : null,
          payoutChannels: List<String>.from(response.data['payoutChannels'] ?? []),
        );
      } else {
        return VerificationConfirmResult(
          success: false,
          message: response.data['message'] ?? 'Code incorrect',
        );
      }
    } on DioException catch (e) {
      return VerificationConfirmResult(
        success: false,
        message: _handleDioError(e),
      );
    } catch (e) {
      return VerificationConfirmResult(
        success: false,
        message: 'Erreur inattendue: ${e.toString()}',
      );
    }
  }

  /// Obtenir l'historique des vérifications
  Future<VerificationHistoryResult> getVerificationHistory({
    int days = 30,
  }) async {
    try {
      final response = await _dio.get('/history', queryParameters: {
        'days': days,
      });
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        return VerificationHistoryResult(
          success: true,
          history: (data['history'] as List)
              .map((item) => VerificationHistoryItem.fromJson(item))
              .toList(),
          totalFound: data['totalFound'],
        );
      } else {
        return VerificationHistoryResult(
          success: false,
          message: response.data['message'] ?? 'Erreur récupération historique',
        );
      }
    } on DioException catch (e) {
      return VerificationHistoryResult(
        success: false,
        message: _handleDioError(e),
      );
    } catch (e) {
      return VerificationHistoryResult(
        success: false,
        message: 'Erreur inattendue: ${e.toString()}',
      );
    }
  }

  /// Gérer les erreurs Dio
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Délai de connexion dépassé';
      case DioExceptionType.receiveTimeout:
        return 'Délai de réception dépassé';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'];
        
        switch (statusCode) {
          case 400:
            return message ?? 'Requête invalide';
          case 401:
            return 'Session expirée, veuillez vous reconnecter';
          case 403:
            return 'Accès refusé - réservé aux partenaires';
          case 409:
            return message ?? 'Conflit de données';
          case 429:
            return message ?? 'Trop de tentatives, réessayez plus tard';
          case 500:
            return 'Erreur serveur, réessayez plus tard';
          default:
            return message ?? 'Erreur réseau (Code: $statusCode)';
        }
      case DioExceptionType.cancel:
        return 'Requête annulée';
      case DioExceptionType.unknown:
        return 'Erreur de connexion réseau';
      default:
        return 'Erreur inattendue: ${e.message}';
    }
  }
}

/// Interceptor pour ajouter le token d'authentification
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Récupérer le token depuis le stockage sécurisé
    // Ici, vous devrez adapter selon votre système d'auth
    final token = await _getAuthToken();
    
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    handler.next(options);
  }
  
  Future<String?> _getAuthToken() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      return token;
    } catch (e) {
      print('❌ Erreur lors de la récupération du token: $e');
      return null;
    }
  }
}

/// Résultat de la demande de vérification
class VerificationRequestResult {
  final bool success;
  final String? message;
  final int? expiresIn;
  final int? attemptsRemaining;

  VerificationRequestResult({
    required this.success,
    this.message,
    this.expiresIn,
    this.attemptsRemaining,
  });
}

/// Résultat de la confirmation de vérification
class VerificationConfirmResult {
  final bool success;
  final String? message;
  final PartnerInfo? partner;
  final List<String> payoutChannels;

  VerificationConfirmResult({
    required this.success,
    this.message,
    this.partner,
    this.payoutChannels = const [],
  });
}

/// Résultat de l'historique des vérifications
class VerificationHistoryResult {
  final bool success;
  final String? message;
  final List<VerificationHistoryItem> history;
  final int? totalFound;

  VerificationHistoryResult({
    required this.success,
    this.message,
    this.history = const [],
    this.totalFound,
  });
}

/// Informations du partenaire après vérification
class PartnerInfo {
  final String id;
  final String phoneNumber;
  final bool isPhoneVerified;
  final DateTime? phoneVerifiedAt;

  PartnerInfo({
    required this.id,
    required this.phoneNumber,
    required this.isPhoneVerified,
    this.phoneVerifiedAt,
  });

  factory PartnerInfo.fromJson(Map<String, dynamic> json) {
    return PartnerInfo(
      id: json['id'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      phoneVerifiedAt: json['phoneVerifiedAt'] != null
          ? DateTime.parse(json['phoneVerifiedAt'])
          : null,
    );
  }
}

/// Élément de l'historique de vérification
class VerificationHistoryItem {
  final DateTime timestamp;
  final String action;
  final String? phoneNumber;
  final String? reason;
  final String? error;

  VerificationHistoryItem({
    required this.timestamp,
    required this.action,
    this.phoneNumber,
    this.reason,
    this.error,
  });

  factory VerificationHistoryItem.fromJson(Map<String, dynamic> json) {
    return VerificationHistoryItem(
      timestamp: DateTime.parse(json['timestamp']),
      action: json['action'] ?? '',
      phoneNumber: json['normalizedOutput'] ?? json['originalInput'],
      reason: json['reason'],
      error: json['error'],
    );
  }

  /// Obtenir une description lisible de l'action
  String get actionDescription {
    switch (action) {
      case 'partner_verification_request':
        return 'Demande de vérification';
      case 'partner_sms_sent':
        return 'SMS envoyé';
      case 'partner_phone_verified':
        return 'Téléphone vérifié';
      case 'partner_sms_failed':
        return 'Échec envoi SMS';
      case 'partner_verification_failed':
        return 'Échec vérification';
      default:
        return action;
    }
  }

  /// Obtenir la couleur de statut
  Color get statusColor {
    switch (action) {
      case 'partner_phone_verified':
        return Colors.green;
      case 'partner_sms_sent':
        return Colors.blue;
      case 'partner_verification_request':
        return Colors.orange;
      case 'partner_sms_failed':
      case 'partner_verification_failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Obtenir l'icône de statut
  IconData get statusIcon {
    switch (action) {
      case 'partner_phone_verified':
        return Icons.verified_user;
      case 'partner_sms_sent':
        return Icons.sms;
      case 'partner_verification_request':
        return Icons.request_quote;
      case 'partner_sms_failed':
      case 'partner_verification_failed':
        return Icons.error;
      default:
        return Icons.info;
    }
  }
}
