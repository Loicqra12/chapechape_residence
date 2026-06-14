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
  static const String _successUrl = '/payment-success';
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

  /// Vérifier le statut d'un paiement CinetPay via l'endpoint dédié (rapide)
  /// PROB #7 CORRIGÉ : lookup direct, ne charge plus tous les paiements
  Future<CinetPayPaymentStatus> checkPaymentStatus(String transactionId) async {
    try {
      // Endpoint dédié : GET /payments/status/:transactionId (index direct MongoDB)
      final response = await _apiService.get('/payments/status/$transactionId');

      if (response.data['success'] == true && response.data['payment'] != null) {
        final p = response.data['payment'] as Map<String, dynamic>;
        return CinetPayPaymentStatus(
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

      return CinetPayPaymentStatus(
        transactionId: transactionId,
        status: PaymentStatus.pending,
        message: 'Paiement non trouvé',
      );
    } on DioException catch (e) {
      throw CinetPayException(
          'Erreur lors de la vérification du statut: ${e.message}');
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
  /// PROB #8 CORRIGÉ : retourne PaymentStatus.succeeded (comme wave_service)
  /// L'enum PaymentStatus n'a PAS de valeur 'completed' — évite un crash silencieux
  PaymentStatus _mapPaymentStatus(String? backendStatus) {
    switch (backendStatus?.toLowerCase()) {
      case 'paid':
      case 'completed':
      case 'succeeded':
      case 'success':
        return PaymentStatus.succeeded; // Unifié avec wave_service.dart
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

  bool get isPaid => status == PaymentStatus.succeeded;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isPending => status == PaymentStatus.pending;
}
