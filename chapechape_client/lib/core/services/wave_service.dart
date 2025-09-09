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
  static const String _successUrl = '/payment/success';
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

      final data = response.data;
      
      // Vérifier que la réponse contient les données Wave nécessaires
      if (data['success'] == true && data['data']['paymentUrl'] != null) {
        final paymentData = data['data'];
        return WavePaymentResult(
          success: true,
          transactionId: paymentData['transactionId'],
          paymentUrl: paymentData['paymentUrl'] ?? paymentData['providerResponse']['paymentUrl'],
          paymentToken: paymentData['paymentToken'] ?? paymentData['providerResponse']['paymentToken'],
          expiresAt: DateTime.now().add(Duration(minutes: 30)), // 30min par défaut
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
    try {
      final uri = Uri.parse(paymentUrl);
      
      if (await canLaunchUrl(uri)) {
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw WaveException('Impossible d\'ouvrir l\'URL de paiement Wave');
      }
    } catch (e) {
      throw WaveException('Erreur lors du lancement du paiement Wave: $e');
    }
  }

  /// Vérifier le statut d'un paiement Wave
  Future<WavePaymentStatus> checkPaymentStatus(String transactionId) async {
    try {
      print('🔍 === WAVE STATUS CHECK ===');
      print('🆔 TransactionId recherché: $transactionId');
      
      // Utiliser l'endpoint my-payments pour récupérer le statut
      final response = await _apiService.get('payments/my-payments');
      
      final List<dynamic> payments = response.data['payments'] ?? [];
      print('📋 Nombre de paiements trouvés: ${payments.length}');
      
      // Logs des IDs disponibles pour debug
      final ids = payments.map((p) => {
        'root': p['transactionId']?.toString(),
        'nested': p['paymentDetails']?['providerResponse']?['transactionId']?.toString(),
        'status': p['status']?.toString(),
        'providerStatus': p['providerStatus']?.toString(),
      }).toList();
      print('🔍 IDs disponibles: $ids');
      
      // Recherche robuste par transactionId (SANS filtres de statut)
      final payment = _findPaymentByTransactionId(transactionId, payments);
      
      if (payment == null) {
        print('❌ Paiement Wave non trouvé avec ID: $transactionId');
        return WavePaymentStatus(
          transactionId: transactionId,
          status: PaymentStatus.pending,
          message: 'Paiement non trouvé',
        );
      }
      
      print('✅ Paiement Wave trouvé: ${payment['_id']}');
      print('📊 Status: ${payment['status']}, ProviderStatus: ${payment['providerStatus']}');
      
      return WavePaymentStatus(
        transactionId: transactionId,
        status: _mapPaymentStatus(payment['status']),
        amount: payment['amount']?.toDouble(),
        currency: payment['currency'] ?? 'XOF',
        message: payment['statusMessage'] ?? '',
        processedAt: payment['processedAt'] != null 
            ? DateTime.parse(payment['processedAt']) 
            : null,
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
  PaymentStatus _mapPaymentStatus(String? backendStatus) {
    switch (backendStatus?.toLowerCase()) {
      case 'paid':
      case 'completed':
      case 'success':
        return PaymentStatus.succeeded;
      case 'failed':
      case 'error':
      case 'rejected':
        return PaymentStatus.failed;
      case 'cancelled':
      case 'canceled':
        return PaymentStatus.cancelled;
      case 'pending':
      case 'processing':
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
}

/// Exception spécifique Wave
class WaveException implements Exception {
  final String message;
  final String? code;

  WaveException(this.message, [this.code]);

  @override
  String toString() => 'WaveException: $message${code != null ? ' (Code: $code)' : ''}';
}
