import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:chapechape_client/core/services/api_service.dart';
import 'package:chapechape_client/core/models/payment_model.dart';

/// Service CinetPay pour les paiements clients
/// Gère l'initiation des paiements et les redirections vers le portail CinetPay
class CinetPayService {
  final ApiService _apiService;

  // Configuration URLs
  static const String _successUrl = '/payment/success';
  static const String _cancelUrl = '/payment/cancel';

  CinetPayService._({required ApiService apiService})
      : _apiService = apiService;

  static Future<CinetPayService> initialize() async {
    final apiService = await ApiService.initialize();
    return CinetPayService._(apiService: apiService);
  }

  /// Initier un paiement CinetPay
  /// Retourne l'URL de redirection vers le portail CinetPay
  Future<CinetPayPaymentResult> initiatePayment({
    required String reservationId,
    required double amount,
    required String paymentMethod,
    required String phoneNumber,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Appel au backend pour créer l'intention de paiement CinetPay
      // Plus de conversion - le backend gère la normalisation
      final response =
          await _apiService.post('/payments/create-payment-intent', data: {
        'reservationId': reservationId,
        'paymentMethod': paymentMethod,
        'phoneNumber': phoneNumber,
      });

      final data = response.data;

      // Vérifier que la réponse contient les données CinetPay nécessaires
      if (data['success'] == true && data['data'] != null) {
        final paymentData = data['data'];
        return CinetPayPaymentResult(
          success: true,
          transactionId: paymentData['transactionId'],
          paymentUrl: paymentData['paymentUrl'],
          paymentToken: paymentData['paymentToken'],
          expiresAt:
              DateTime.now().add(Duration(minutes: 30)), // 30min par défaut
        );
      } else {
        throw Exception(
            data['message'] ?? 'Erreur lors de l\'initiation du paiement');
      }
    } on DioException catch (e) {
      throw CinetPayException('Erreur réseau: ${e.message}');
    } catch (e) {
      throw CinetPayException('Erreur lors de l\'initiation du paiement: $e');
    }
  }

  /// Lancer le paiement CinetPay dans une WebView intégrée
  Future<bool> launchPaymentInWebView(
    BuildContext context,
    String paymentUrl,
    String transactionId,
    String paymentMethod,
  ) async {
    try {
      // Naviguer vers l'écran WebView personnalisé
      final result =
          await GoRouter.of(context).push('/payment-webview', extra: {
        'paymentUrl': paymentUrl,
        'transactionId': transactionId,
        'paymentMethod': paymentMethod,
      });

      return result == true;
    } catch (e) {
      throw CinetPayException('Erreur lors du lancement de la WebView: $e');
    }
  }

  /// Vérifier le statut d'un paiement CinetPay
  Future<CinetPayPaymentStatus> checkPaymentStatus(String transactionId) async {
    try {
      print('🔍 === CINETPAY STATUS CHECK ===');
      print('🆔 TransactionId reçu: $transactionId');
      print('📏 Longueur: ${transactionId.length}');
      print(
          '🏷️ Format: ${transactionId.startsWith('CHAPE') ? 'Format CinetPay valide' : 'Format non-standard'}');

      // SOLUTION: Utiliser l'endpoint de vérification CinetPay directe
      print('🚀 Utilisation de l\'endpoint de vérification CinetPay temps réel');
      
      try {
        // Essayer d'abord la vérification directe CinetPay
        final response = await _apiService.get('payments/cinetpay/verify/$transactionId');
        
        if (response.data['success'] == true && response.data['payment'] != null) {
          final payment = response.data['payment'];
          print('✅ Paiement trouvé via vérification CinetPay directe');
          print('📊 Statut: ${payment['status']}');
          print('🔄 Données CinetPay: ${response.data['cinetpayData']}');
          
          return CinetPayPaymentStatus(
            transactionId: transactionId,
            status: _mapPaymentStatus(payment['status']),
            amount: payment['amount']?.toDouble(),
            currency: payment['currency'] ?? 'XOF',
            message: payment['statusMessage']?.toString() ?? '',
            processedAt: payment['updatedAt'] != null 
                ? DateTime.tryParse(payment['updatedAt'].toString()) 
                : null,
          );
        }
      } catch (directError) {
        print('⚠️ Erreur vérification directe CinetPay: $directError');
        print('🔄 Fallback vers my-payments...');
      }
      
      // Fallback: utiliser my-payments si la vérification directe échoue
      final response = await _apiService.get('payments/my-payments');

      final List<dynamic> payments = response.data['data'] ?? [];
      print('📋 Total paiements en base: ${payments.length}');

      // Afficher tous les IDs disponibles pour debug
      print('🔍 IDs disponibles dans la base:');
      for (var payment in payments.take(5)) {
        print('  - _id: ${payment['_id']}');
        print('  - transactionId: ${payment['transactionId']}');
        print('  - paymentMethod: ${payment['paymentMethod']}');
        print('  - status: ${payment['status']}');
        print('  - createdAt: ${payment['createdAt']}');
        if (payment['paymentDetails']?['providerResponse'] != null) {
          print(
              '  - providerResponse keys: ${payment['paymentDetails']['providerResponse'].keys}');
        }
        print('  ---');
      }

      // Recherche robuste par transactionId (SANS filtres de statut)
      final payment = _findPaymentByTransactionId(transactionId, payments);

      if (payment == null) {
        print('❌ Paiement CinetPay non trouvé avec ID: $transactionId');
        print('📊 Total paiements en base: ${payments.length}');

        return CinetPayPaymentStatus(
          transactionId: transactionId,
          status: PaymentStatus.pending,
          message: 'Paiement non trouvé',
        );
      }
      
      print('✅ Paiement CinetPay trouvé: ${payment['_id']}');
      print('📊 Status: ${payment['status']}, ProviderStatus: ${payment['providerStatus']}');

      print('✅ Paiement trouvé: ${payment['transactionId']}');
      print('📊 Status: ${payment['status']}');

      return CinetPayPaymentStatus(
        transactionId: transactionId,
        status: _mapPaymentStatus(payment['status']),
        amount: payment['amount']?.toDouble(),
        currency: payment['currency'] ?? 'XOF',
        message: payment['statusMessage']?.toString() ?? '',
        processedAt: payment['processedAt'] != null
            ? DateTime.tryParse(payment['processedAt'].toString())
            : null,
      );
    } on DioException catch (e) {
      print('❌ Erreur DioException: ${e.message}');
      throw CinetPayException(
          'Erreur lors de la vérification du statut: ${e.message}');
    } catch (e) {
      print('❌ Erreur générale: $e');
      rethrow;
    } finally {
      print('🔍 === FIN CINETPAY STATUS CHECK ===');
    }
  }

  /// Recherche robuste par transactionId (root ou nested) avec filtrage CinetPay
  Map<String, dynamic>? _findPaymentByTransactionId(String wantedId, List<dynamic> payments) {
    // Filtrer d'abord les paiements CinetPay uniquement
    final cinetpayPayments = payments.cast<Map<String, dynamic>>().where((payment) {
      final provider = payment['paymentProvider']?.toString().toLowerCase();
      final method = payment['paymentMethod']?.toString().toLowerCase();
      
      // Vérifier que c'est un paiement CinetPay (Orange Money, MTN Money, Moov Money, Card)
      return provider == 'cinetpay' && 
             (method == 'orange_money' || method == 'mtn_money' || 
              method == 'moov_money' || method == 'credit_card');
    }).toList();
    
    print('🔍 Paiements CinetPay filtrés: ${cinetpayPayments.length}/${payments.length}');
    
    for (final raw in cinetpayPayments) {
      final txnRoot = raw['transactionId']?.toString();
      final txnNested = raw['paymentDetails']?['providerResponse']?['transactionId']?.toString();
      
      print('🔍 Comparaison: $wantedId vs Root:$txnRoot, Nested:$txnNested');
      
      if (wantedId == txnRoot || wantedId == txnNested) {
        print('✅ Match CinetPay trouvé: ${wantedId == txnRoot ? 'root' : 'nested'} transactionId');
        print('📱 Méthode: ${raw['paymentMethod']}, Provider: ${raw['paymentProvider']}');
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
        return PaymentStatus.completed;
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
    required String phoneNumber,
  }) {
    if (reservationId.isEmpty) {
      throw CinetPayException('ID de réservation requis');
    }

    if (amount <= 0) {
      throw CinetPayException('Montant invalide');
    }

    // Validation CinetPay: montant multiple de 5 XOF
    if (amount % 5 != 0) {
      throw CinetPayException('Le montant doit être un multiple de 5 XOF');
    }

    if (phoneNumber.isEmpty) {
      throw CinetPayException('Numéro de téléphone requis');
    }

    // Validation format téléphone ivoirien basique
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.length < 8) {
      throw CinetPayException('Numéro de téléphone invalide');
    }
  }

  /// Formater le numéro de téléphone pour CinetPay
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

  /// Déterminer les canaux CinetPay selon la méthode de paiement
  String getChannelsForPaymentMethod(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'orange_money':
      case 'mtn_money':
      case 'moov_money':
      case 'wave':
        return 'MOBILE_MONEY';
      case 'card':
      case 'credit_card':
        return 'CREDIT_CARD';
      case 'wallet':
        return 'WALLET';
      default:
        return 'ALL'; // Tous les canaux disponibles
    }
  }
}

/// Résultat de l'initiation d'un paiement CinetPay
class CinetPayPaymentResult {
  final bool success;
  final String? transactionId;
  final String? paymentUrl;
  final String? paymentToken;
  final String? errorMessage;
  final DateTime? expiresAt;

  CinetPayPaymentResult({
    required this.success,
    this.transactionId,
    this.paymentUrl,
    this.paymentToken,
    this.errorMessage,
    this.expiresAt,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

/// Statut d'un paiement CinetPay
class CinetPayPaymentStatus {
  final String transactionId;
  final PaymentStatus status;
  final double? amount;
  final String? currency;
  final String? message;
  final DateTime? processedAt;

  CinetPayPaymentStatus({
    required this.transactionId,
    required this.status,
    this.amount,
    this.currency,
    this.message,
    this.processedAt,
  });

  bool get isPaid => status == PaymentStatus.completed;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isPending => status == PaymentStatus.pending;
}

/// Exception spécifique CinetPay
class CinetPayException implements Exception {
  final String message;
  final String? code;

  CinetPayException(this.message, [this.code]);

  @override
  String toString() =>
      'CinetPayException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Enum pour les statuts de paiement
enum PaymentStatus {
  pending,
  completed,
  failed,
  cancelled,
}
