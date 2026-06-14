import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:chapechape_client/core/services/api_service.dart';
import 'package:chapechape_client/core/models/payment_model.dart';

/// Service Wave pour les paiements clients
/// Gère l'initiation des paiements et les redirections vers le portail Wave
class WaveService {
  final ApiService _apiService;
  
  // Configuration URLs
  static const String _successUrl = '/payment-success';
  static const String _cancelUrl = '/payment/cancel';
  
  WaveService._({required ApiService apiService}) : _apiService = apiService;
  
  static Future<WaveService> initialize() async {
    final apiService = await ApiService.initialize();
    return WaveService._(apiService: apiService);
  }

  /// Initier un paiement Wave
  /// Retourne l'URL de redirection vers le portail Wave
  Future<WavePaymentResult> initiatePayment({
    required String reservationId,
    required double amount,
    String? phoneNumber,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Appel au backend pour créer l'intention de paiement Wave
      final response = await _apiService.post('/payments/create-payment-intent', data: {
        'reservationId': reservationId,
        'paymentMethod': 'wave',
        'phoneNumber': phoneNumber ?? '', // Utiliser le phoneNumber fourni
      });

      final data = _mapFrom(response.data);
      if (data == null) {
        throw Exception('Réponse API invalide');
      }

      final paymentData = _mapFrom(data['data']);
      final success = data['success'] == true;
      final paymentUrl = _stringFrom(paymentData?['paymentUrl']) ??
          _stringFrom(_mapFrom(paymentData?['providerResponse'])?['paymentUrl']);

      if (success && paymentUrl != null && paymentUrl.isNotEmpty) {
        final provider = _mapFrom(paymentData?['providerResponse']);
        final paymentToken = _stringFrom(paymentData?['paymentToken']) ??
            _stringFrom(provider?['paymentToken']) ??
            _stringFrom(paymentData?['transactionId']);

        DateTime? expiresAt;
        final rawExpiry = paymentData?['expiresAt'];
        if (rawExpiry != null) {
          expiresAt = DateTime.tryParse(rawExpiry.toString());
        }
        expiresAt ??= DateTime.now().add(const Duration(minutes: 30));

        return WavePaymentResult(
          success: true,
          transactionId: _stringFrom(paymentData?['transactionId']),
          paymentUrl: paymentUrl,
          paymentToken: paymentToken,
          expiresAt: expiresAt,
        );
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de l\'initiation du paiement Wave');
      }
      
    } on DioException catch (e) {
      throw WaveException('Erreur réseau: ${e.message}');
    } catch (e) {
      throw WaveException('Erreur lors de l\'initiation du paiement Wave: $e');
    }
  }

  /// Lancer le paiement Wave dans le navigateur externe
  Future<bool> launchPaymentInBrowser(String paymentUrl) async {
    final uri = Uri.parse(paymentUrl);
    if (!uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw WaveException('URL de paiement invalide');
    }
    try {
      // Sur Android 11+, sans <queries> https dans le manifeste, [canLaunchUrl] est souvent false
      // alors qu’un navigateur existe — on tente [launchUrl] directement.
      var launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      if (!launched) {
        throw WaveException('Impossible d\'ouvrir l\'URL de paiement Wave');
      }
      return launched;
    } catch (e) {
      if (e is WaveException) rethrow;
      throw WaveException('Erreur lors du lancement du paiement Wave: $e');
    }
  }

  /// Vérifier le statut d'un paiement Wave via l'endpoint dédié (rapide)
  /// PROB #7 CORRIGÉ : lookup direct, ne charge plus tous les paiements
  Future<WavePaymentStatus> checkPaymentStatus(String transactionId) async {
    try {
      // Endpoint dédié : lookup direct par index MongoDB
      final response = await _apiService.get('/payments/status/$transactionId');

      if (response.data['success'] == true && response.data['payment'] != null) {
        final p = response.data['payment'] as Map<String, dynamic>;
        return WavePaymentStatus(
          transactionId: transactionId,
          status: _mapPaymentStatus(p['status']?.toString()),
          amount: (p['amount'] as num?)?.toDouble(),
          currency: p['currency']?.toString() ?? 'XOF',
          message: p['providerStatus']?.toString() ?? '',
          processedAt: p['updatedAt'] != null
              ? DateTime.tryParse(p['updatedAt'].toString())
              : null,
        );
      }

      return WavePaymentStatus(
        transactionId: transactionId,
        status: PaymentStatus.pending,
        message: 'Paiement non trouvé',
      );
    } on DioException catch (e) {
      throw WaveException('Erreur lors de la vérification du statut Wave: ${e.message}');
    }
  }

  /// Recherche robuste par transactionId (root ou nested)
  Map<String, dynamic>? _findPaymentByTransactionId(String wantedId, List<dynamic> payments) {
    for (final raw in payments.cast<Map<String, dynamic>>()) {
      final txnRoot = raw['transactionId']?.toString();
      final txnNested = raw['paymentDetails']?['providerResponse']?['transactionId']?.toString();
      
      if (wantedId == txnRoot || wantedId == txnNested) {
        print('✅ Match trouvé: ${wantedId == txnRoot ? 'root' : 'nested'} transactionId');
        return raw;
      }
    }
    return null;
  }

  /// Mapper le statut backend vers enum PaymentStatus
  /// PROB #8 CORRIGÉ : centralisé, inclut tous les alias backend
  PaymentStatus _mapPaymentStatus(String? backendStatus) {
    switch (backendStatus?.toLowerCase()) {
      case 'paid':
      case 'completed':
      case 'succeeded':
      case 'success':
        return PaymentStatus.succeeded; // Cohérent avec payment_model.dart
      case 'failed':
      case 'error':
      case 'rejected':
        return PaymentStatus.failed;
      case 'cancelled':
      case 'canceled':
        return PaymentStatus.cancelled;
      case 'processing':
        return PaymentStatus.processing;
      case 'pending':
      default:
        return PaymentStatus.pending;
    }
  }

  /// Valider les paramètres de paiement avant l'initiation
  void _validatePaymentParams({
    required String reservationId,
    required double amount,
  }) {
    if (reservationId.isEmpty) {
      throw WaveException('ID de réservation requis');
    }
    
    if (amount <= 0) {
      throw WaveException('Montant invalide');
    }
    
    // Validation Wave: montant minimum 100 FCFA
    if (amount < 100) {
      throw WaveException('Le montant minimum est de 100 FCFA');
    }
  }

  /// Formater le numéro de téléphone pour Wave
  String formatPhoneNumber(String phoneNumber) {
    // Nettoyer le numéro
    String clean = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Ajouter le préfixe ivoirien si nécessaire
    if (clean.length == 10 && clean.startsWith('0')) {
      clean = '225${clean.substring(1)}';
    } else if (clean.length == 8) {
      clean = '225$clean';
    }
    
    return clean;
  }

  static Map<String, dynamic>? _mapFrom(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String? _stringFrom(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    return s.isEmpty ? null : s;
  }
}

/// Exception spécifique Wave
class WaveException implements Exception {
  final String message;
  final String? code;

  WaveException(this.message, [this.code]);

  @override
  String toString() => 'WaveException: $message${code != null ? ' (Code: $code)' : ''}';
}
