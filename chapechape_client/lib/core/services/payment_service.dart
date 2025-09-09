import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:chapechape_client/core/models/payment_model.dart';
import 'package:chapechape_client/core/services/api_service.dart';
import 'package:chapechape_client/core/services/cinetpay_service.dart';
import 'package:chapechape_client/core/services/wave_service.dart';

class PaymentService {
  final ApiService _apiService;
  final Uuid _uuid = const Uuid();
  late final CinetPayService _cinetPayService;

  // Taux de commission fixe par défaut (10%)
  static const double defaultCommissionRate = 0.10;

  PaymentService._({
    required ApiService apiService,
    required CinetPayService cinetPayService,
  })  : _apiService = apiService,
        _cinetPayService = cinetPayService;

  static Future<PaymentService> initialize() async {
    final apiService = await ApiService.initialize();
    final cinetPayService = await CinetPayService.initialize();
    return PaymentService._(
      apiService: apiService,
      cinetPayService: cinetPayService,
    );
  }

  /// Calculer une commission basée sur un montant avec le taux par défaut (10%)
  Future<PaymentCommission> calculateCommission({
    required double amount,
    double? rate,
  }) async {
    // Taux par défaut si non spécifié
    final effectiveRate = rate ?? defaultCommissionRate;

    // Calculer les montants
    return PaymentCommission(
      rate: effectiveRate,
      totalAmount: amount,
    );
  }

  /// Récupérer les méthodes de paiement acceptées pour une résidence/partenaire
  Future<List<PaymentMethod>> getAcceptedPaymentMethods({
    required String residenceId,
    String? partnerId,
  }) async {
    try {
      // Pour une API réelle, on ferait ça :
      // final response = await _apiService.get('/residences/$residenceId/payment-methods');
      // return (response.data as List).map((method) => _parsePaymentMethod(method)).toList();

      // Simulation
      await Future.delayed(const Duration(milliseconds: 800));

      // Liste simulée de méthodes de paiement acceptées
      return [
        PaymentMethod.orangeMoney,
        PaymentMethod.moovMoney,
        PaymentMethod.mtnMoney,
        PaymentMethod.wave,
        PaymentMethod.mobileMoney,
        PaymentMethod.creditCard,
        PaymentMethod.bankTransfer,
        PaymentMethod.cash,
      ];
    } catch (e) {
      // En cas d'erreur, retourner des méthodes par défaut
      return [
        PaymentMethod.wave,
        PaymentMethod.orangeMoney,
        PaymentMethod.cash
      ];
    }
  }

  // Créer une intention de paiement avec commission - CONNECTÉ AU BACKEND RÉEL
  Future<PaymentIntent> createPaymentIntent({
    required String bookingId,
    required double amount,
    required PaymentMethod method,
    String? phoneNumber,
    String? partnerId,
    double? commissionRate,
  }) async {
    try {
      // Construire les données de base
      final Map<String, dynamic> requestData = {
        'reservationId': bookingId,
        'paymentMethod': _getPaymentMethodString(method),
      };

      // Ajouter phoneNumber seulement s'il est fourni et non vide
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
        requestData['phoneNumber'] = phoneNumber.trim();
      }

      final response = await _apiService.post('/payments/create-payment-intent',
          data: requestData);

      // Le backend retourne { success: true, data: {...} }
      if (response.data['success'] == true) {
        return PaymentIntent.fromBackendJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ??
            'Erreur lors de la création du paiement');
      }
    } on DioException catch (e) {
      throw Exception(
          'Erreur lors de la création de l\'intention de paiement: ${e.message}');
    }
  }

  // Mapper PaymentMethod vers string backend (format canonique)
  String _getPaymentMethodString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.orangeMoney:
        return 'orange_money';
      case PaymentMethod.moovMoney:
        return 'moov_money';
      case PaymentMethod.mtnMoney:
        return 'mtn_money';
      case PaymentMethod.wave:
        return 'wave';
      case PaymentMethod.creditCard:
        return 'card';
      case PaymentMethod.mobileMoney:
      default:
        return 'mobile_money';
    }
  }

  // Simuler une intention de paiement avec commission
  Future<PaymentIntent> createPaymentIntentSimulated({
    required String bookingId,
    required double amount,
    required PaymentMethod method,
    String? partnerId,
    double? commissionRate,
  }) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(seconds: 1));

    // Calculer la commission
    final commission =
        await calculateCommission(amount: amount, rate: commissionRate);

    // Générer un identifiant unique pour l'intention de paiement
    final id = _uuid.v4();

    return PaymentIntent(
      id: id,
      bookingId: bookingId,
      userId: 'user_${_uuid.v4().substring(0, 8)}',
      amount: amount,
      method: method,
      clientSecret: 'pi_${_uuid.v4()}',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      createdAt: DateTime.now(),
      paymentParams: {
        'commission': commission.toJson(),
        'partnerId': partnerId ?? 'partner_default',
      },
    );
  }

  // Confirmer un paiement Mobile Money via backend réel
  Future<Payment> confirmMobileMoneyPayment({
    required String paymentIntentId,
    required String phoneNumber,
    required String provider,
    String? otp,
    String? transactionId,
  }) async {
    try {
      final response = await _apiService
          .post('/api/payments/$paymentIntentId/confirm', data: {
        if (otp != null) 'otp': otp,
        if (transactionId != null) 'transactionId': transactionId,
      });

      // Le backend retourne { success: true, data: {...} }
      if (response.data['success'] == true) {
        return Payment.fromBackendJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ??
            'Erreur lors de la confirmation du paiement');
      }
    } on DioException catch (e) {
      throw Exception(
          'Erreur lors de la confirmation du paiement: ${e.message}');
    }
  }

  // Mapper provider vers méthode backend
  String _getProviderMethodString(String provider) {
    final providerLower = provider.toLowerCase();
    if (providerLower.contains('orange')) return 'orange_money';
    if (providerLower.contains('moov')) return 'moov_money';
    if (providerLower.contains('mtn')) return 'mtn_money';
    if (providerLower.contains('wave')) return 'wave';
    return 'cinetpay'; // Défaut CinetPay
  }

  // Déterminer la méthode de paiement mobile money en fonction du fournisseur
  PaymentMethod _getMobileMoneyMethodByProvider(String provider) {
    final providerLower = provider.toLowerCase();

    if (providerLower.contains('orange')) return PaymentMethod.orangeMoney;
    if (providerLower.contains('moov')) return PaymentMethod.moovMoney;
    if (providerLower.contains('mtn')) return PaymentMethod.mtnMoney;
    if (providerLower.contains('wave')) return PaymentMethod.wave;

    // Par défaut
    return PaymentMethod.mobileMoney;
  }

  // Confirmer un paiement par carte via backend réel
  Future<Payment> confirmCardPayment({
    required String paymentIntentId,
    required Map<String, dynamic> cardDetails,
    double amount = 50000, // Montant par défaut pour la simulation
    double? commissionRate,
  }) async {
    try {
      // CORRIGÉ: Utiliser le bon endpoint backend
      final response = await _apiService
          .post('payments/$paymentIntentId/confirm', data: {
        'paymentMethod': 'card',
        'cardDetails': {
          'number': cardDetails['number'],
          'expiryMonth': cardDetails['expiryMonth'],
          'expiryYear': cardDetails['expiryYear'],
          'cvc': cardDetails['cvc'],
          'holderName': cardDetails['holderName'],
        },
      });

      // CORRIGÉ: Adapter à la structure de réponse backend
      return Payment.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
          'Erreur lors de la confirmation du paiement par carte: ${e.message}');
    }
  }

  // Confirmer un paiement par virement bancaire via backend réel
  Future<Payment> confirmBankTransferPayment({
    required String paymentIntentId,
    required Map<String, dynamic> bankDetails,
    double amount = 50000, // Montant par défaut pour la simulation
    double? commissionRate,
  }) async {
    try {
      // CORRIGÉ: Utiliser le bon endpoint backend avec préfixe /api
      final response = await _apiService
          .post('/api/payments/$paymentIntentId/confirm', data: {
        'paymentMethod': 'bank_transfer',
        'bankDetails': {
          'bankName': bankDetails['bankName'],
          'accountNumber': bankDetails['accountNumber'],
          'accountName': bankDetails['accountName'],
          'reference': bankDetails['reference'],
        },
      });

      // CORRIGÉ: Adapter à la structure de réponse backend
      return Payment.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
          'Erreur lors de la confirmation du virement bancaire: ${e.message}');
    }
  }

  // Vérifier le statut d'un paiement via backend réel
  Future<Payment> checkPaymentStatus(String paymentId) async {
    try {
      print('🔍 === DÉBUT VÉRIFICATION PAIEMENT ===');
      print('🆔 ID recherché: $paymentId');
      print('📏 Longueur ID: ${paymentId.length}');
      print(
          '🏷️ Format ID: ${paymentId.startsWith('CHAPE') ? 'CinetPay TransactionID' : 'Autre format'}');

      // Pour les paiements CinetPay, utiliser la vérification directe
      if (paymentId.startsWith('CHAPE')) {
        print('🚀 Paiement CinetPay détecté - utilisation vérification directe');
        try {
          final response = await _apiService.get('payments/cinetpay/verify/$paymentId');
          
          if (response.data['success'] == true && response.data['payment'] != null) {
            final payment = response.data['payment'];
            print('✅ Paiement trouvé via vérification CinetPay directe');
            print('📊 Statut: ${payment['status']}');
            return Payment.fromJson(payment);
          }
        } catch (directError) {
          print('⚠️ Erreur vérification directe CinetPay: $directError');
          print('🔄 Fallback vers my-payments...');
        }
      }
      
      // Utiliser l'endpoint my-payments pour récupérer tous les paiements
      final response = await _apiService.get('payments/my-payments');

      // Chercher le paiement par ID dans la liste
      final List<dynamic> paymentsData = response.data['data'] ?? [];

      print('📋 Nombre de paiements trouvés: ${paymentsData.length}');
      print('🔍 IDs de paiements disponibles:');
      for (var payment in paymentsData.take(10)) {
        print('  - _id: ${payment['_id']}');
        print('  - transactionId: ${payment['transactionId']}');
        if (payment['paymentDetails']?['providerResponse']?['transactionId'] !=
            null) {
          print(
              '  - providerResponse.transactionId: ${payment['paymentDetails']['providerResponse']['transactionId']}');
        }
        print('  - paymentMethod: ${payment['paymentMethod']}');
        print('  - status: ${payment['status']}');
        print('  - createdAt: ${payment['createdAt']}');
        print('  ---');
      }

      // Logs des IDs disponibles pour debug
      final ids = paymentsData.map((p) => {
        'root': p['transactionId']?.toString(),
        'nested': p['paymentDetails']?['providerResponse']?['transactionId']?.toString(),
        'status': p['status']?.toString(),
        'providerStatus': p['providerStatus']?.toString(),
      }).toList();
      print('🔍 IDs disponibles: $ids');
      
      // Recherche robuste par transactionId (SANS filtres de statut)
      final paymentData = _findPaymentByTransactionId(paymentId, paymentsData);
      
      if (paymentData != null) {
        print('✅ Paiement trouvé: ${paymentData['_id']}');
        print('📊 Status: ${paymentData['status']}, ProviderStatus: ${paymentData['providerStatus']}');
        return Payment.fromJson(paymentData);
      }

      print('❌ === AUCUN PAIEMENT TROUVÉ ===');
      print('🆔 ID recherché: $paymentId');
      print('📊 Total paiements en base: ${paymentsData.length}');

      throw Exception('Paiement non trouvé avec ID: $paymentId');
    } on DioException catch (e) {
      print('❌ Erreur Dio: ${e.message}');
      throw Exception('Erreur lors de la vérification du statut: ${e.message}');
    } catch (e) {
      print('❌ Erreur générale: $e');
      rethrow;
    } finally {
      print('🔍 === FIN VÉRIFICATION PAIEMENT ===');
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

  // Récupérer l'historique des paiements via backend réel
  Future<List<Payment>> getPaymentHistory({String? bookingId}) async {
    try {
      // CORRIGÉ: Utiliser le bon endpoint backend
      final queryParams = bookingId != null ? '?reservationId=$bookingId' : '';
      final response =
          await _apiService.get('payments/my-payments$queryParams');

      // CORRIGÉ: Le backend retourne les paiements dans 'data', pas 'payments'
      final List<dynamic> paymentsData = response.data['data'] ?? [];
      return paymentsData
          .map((paymentJson) => Payment.fromJson(paymentJson))
          .toList();
    } on DioException catch (e) {
      throw Exception(
          'Erreur lors de la récupération de l\'historique: ${e.message}');
    }
  }

  // Demander un remboursement via backend réel
  Future<Payment> requestRefund({
    required String paymentId,
    double? amount,
    String? reason,
  }) async {
    try {
      // CORRIGÉ: Utiliser le bon endpoint backend avec préfixe /api
      final response =
          await _apiService.post('/api/payments/$paymentId/refund', data: {
        'amount': amount,
        'reason': reason ?? 'Remboursement demandé par l\'utilisateur',
      });

      // CORRIGÉ: Adapter à la structure de réponse backend
      return Payment.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
          'Erreur lors de la demande de remboursement: ${e.message}');
    }
  }

  // Annuler un paiement via backend réel
  Future<void> cancelPayment({
    required String paymentId,
    String? reason,
  }) async {
    try {
      // CORRIGÉ: Le backend n'a pas d'endpoint /payments/{id}/cancel
      // Utiliser l'endpoint refund avec montant complet pour "annuler"
      await _apiService.post('/api/payments/$paymentId/refund', data: {
        'reason': reason ?? 'Annulation demandée par l\'utilisateur',
        // Le montant sera déduit automatiquement par le backend (remboursement complet)
      });
    } on DioException catch (e) {
      throw Exception('Erreur lors de l\'annulation du paiement: ${e.message}');
    }
  }

  /// Initier un paiement CinetPay et retourner l'URL de redirection
  Future<CinetPayPaymentResult> initiateCinetPayPayment({
    required String reservationId,
    required double amount,
    required String paymentMethod,
    required String phoneNumber,
    Map<String, dynamic>? metadata,
  }) async {
    return await _cinetPayService.initiatePayment(
      reservationId: reservationId,
      amount: amount,
      paymentMethod: paymentMethod,
      phoneNumber: phoneNumber,
      metadata: metadata,
    );
  }

  /// Initier un paiement Wave et retourner l'URL de redirection
  Future<WavePaymentResult> initiateWavePayment({
    required String reservationId,
    required double amount,
    String? phoneNumber,
    Map<String, dynamic>? metadata,
  }) async {
    final waveService = await WaveService.initialize();
    return await waveService.initiatePayment(
      reservationId: reservationId,
      amount: amount,
      phoneNumber: phoneNumber,
      metadata: metadata,
    );
  }

  /// Lancer le paiement Wave dans le navigateur externe
  Future<bool> launchWavePaymentInBrowser(String paymentUrl) async {
    final waveService = await WaveService.initialize();
    return await waveService.launchPaymentInBrowser(paymentUrl);
  }

  /// Vérifier le statut d'un paiement Wave
  Future<WavePaymentStatus> checkWavePaymentStatus(String transactionId) async {
    final waveService = await WaveService.initialize();
    return await waveService.checkPaymentStatus(transactionId);
  }

  /// Vérifier le statut d'un paiement CinetPay
  Future<CinetPayPaymentStatus> checkCinetPayStatus(
      String transactionId) async {
    return await _cinetPayService.checkPaymentStatus(transactionId);
  }

  /// Lancer le paiement CinetPay dans une WebView intégrée
  Future<bool> launchCinetPayInWebView(
    BuildContext context,
    String paymentUrl,
    String transactionId,
    String paymentMethod,
  ) async {
    return await _cinetPayService.launchPaymentInWebView(
      context,
      paymentUrl,
      transactionId,
      paymentMethod,
    );
  }

  /// Formater le numéro de téléphone pour CinetPay
  String formatPhoneForCinetPay(String phoneNumber) {
    return _cinetPayService.formatPhoneNumber(phoneNumber);
  }

  // Simuler génération de reçu
  Future<String> generateReceipt(String paymentId) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(seconds: 1));
    return 'https://example.com/receipts/simulated_receipt.pdf';
  }

  // Vérifier si un moyen de paiement est disponible (simulation)
  Future<bool> isPaymentMethodAvailable(PaymentMethod method) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 500));
    // Toutes les méthodes sont disponibles dans la simulation
    return true;
  }

  // Récupérer les frais de transaction (simulation)
  Future<Map<String, dynamic>> getTransactionFees({
    required double amount,
    required PaymentMethod method,
    double? commissionRate,
  }) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 800));

    // Taux de commission (10% par défaut)
    final effectiveCommissionRate = commissionRate ?? defaultCommissionRate;

    // Calculer les frais
    final commissionAmount = amount * effectiveCommissionRate;
    final processingFee = amount * 0.025; // 2.5% de frais de traitement
    final fixedFee = 300.0; // Frais fixe

    // Calculer le montant total des frais
    final totalFee = commissionAmount + processingFee + fixedFee;

    return {
      'amount': amount,
      'fee': totalFee,
      'partnerAmount': amount - commissionAmount,
      'total': amount + processingFee + fixedFee,
      'breakdown': {
        'commissionRate':
            '${(effectiveCommissionRate * 100).toStringAsFixed(0)}%',
        'commissionAmount': commissionAmount,
        'processingFee': processingFee,
        'fixedFee': fixedFee,
      }
    };
  }
}
