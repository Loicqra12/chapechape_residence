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

  /// Récupérer les méthodes de paiement réellement supportées par le backend
  /// Seules Wave, Orange Money (CinetPay), MTN Money (CinetPay) et Moov Money (CinetPay) sont actives.
  /// BUG #4 CORRIGÉ : plus de simulation — liste réelle des méthodes du backend
  Future<List<PaymentMethod>> getAcceptedPaymentMethods({
    required String residenceId,
    String? partnerId,
  }) async {
    // Méthodes réellement supportées par le backend (pas de bankTransfer ni cash)
    // Wave est le seul checkout direct. Orange/MTN/Moov passent par CinetPay.
    return [
      PaymentMethod.wave,
      PaymentMethod.orangeMoney,
      PaymentMethod.mtnMoney,
      PaymentMethod.moovMoney,
    ];
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
          .post('/payments/$paymentIntentId/confirm', data: {
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
    double amount = 50000,
    double? commissionRate,
  }) async {
    try {
      // INCO #14 CORRIGÉ: slash de début ajouté (évite la concaténation incorrecte avec baseUrl)
      final response = await _apiService
          .post('/payments/$paymentIntentId/confirm', data: {
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
          .post('/payments/$paymentIntentId/confirm', data: {
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

  // Vérifier le statut d'un paiement via l'endpoint dédié (lookup direct)
  // PROB #7 CORRIGÉ : plus de chargement de tous les paiements — 1 requête directe
  Future<Payment> checkPaymentStatus(String paymentId) async {
    try {
      // Endpoint dédié : GET /payments/status/:transactionId (index direct MongoDB)
      final response = await _apiService.get('/payments/status/$paymentId');

      if (response.data['success'] == true && response.data['payment'] != null) {
        return Payment.fromBackendJson(
            Map<String, dynamic>.from(response.data['payment'] as Map));
      }

      throw Exception('Paiement non trouvé avec ID: $paymentId');
    } on DioException catch (e) {
      throw Exception('Erreur lors de la vérification du statut: ${e.message}');
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
          .map((paymentJson) =>
              Payment.fromBackendJson(Map<String, dynamic>.from(paymentJson as Map)))
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
          await _apiService.post('/payments/$paymentId/refund', data: {
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

  // Annuler un paiement (uniquement possible si statut pending)
  // BUG #6 CORRIGÉ : on ne peut pas "rembourser" un paiement non complété
  Future<void> cancelPayment({
    required String paymentId,
    String? reason,
  }) async {
    try {
      // Un paiement pending ne peut pas être remboursé (pas encore capturé)
      // On log simplement côté client — l'expiration automatique à 30min suffira
      // Si le backend expose un day un endpoint /payments/:id/cancel, l'utiliser ici
      throw Exception(
          'Annulation non disponible. Le paiement expirera automatiquement dans 30 minutes.');
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

  /// Vérifier le statut d'un paiement Wave via l'endpoint dédié (rapide)
  /// PROB #7 CORRIGÉ : lookup direct par transactionId
  Future<WavePaymentStatus> checkWavePaymentStatus(String transactionId) async {
    try {
      final response = await _apiService.get('/payments/status/$transactionId');
      if (response.data['success'] == true && response.data['payment'] != null) {
        final p = response.data['payment'] as Map<String, dynamic>;
        return WavePaymentStatus(
          transactionId: transactionId,
          status: _mapBackendStatusToPaymentStatus(p['status']?.toString()),
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
      throw Exception('Erreur vérification statut Wave: ${e.message}');
    }
  }

  /// Mapper le statut backend vers PaymentStatus (centralisé)
  PaymentStatus _mapBackendStatusToPaymentStatus(String? backendStatus) {
    switch (backendStatus?.toLowerCase()) {
      case 'paid':
      case 'completed':
      case 'succeeded':
      case 'success':
        return PaymentStatus.succeeded;
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

  // BUG #5 CORRIGÉ : plus de reçu simulé pointant vers example.com
  // Le reçu sera disponible dans le futur via un endpoint backend dédié.
  // En attendant, on retourne null — l'UI doit gérer l'absence de reçu.
  Future<String?> generateReceipt(String paymentId) async {
    return null; // Reçu non disponible pour l'instant
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
