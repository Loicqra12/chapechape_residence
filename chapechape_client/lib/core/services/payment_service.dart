import 'package:dio/dio.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:chapechape_client/core/models/payment_model.dart';
import 'package:chapechape_client/core/services/api_service.dart';

class PaymentService {
  final ApiService _apiService;
  final Uuid _uuid = const Uuid();
  
  // Taux de commission fixe par défaut (10%)
  static const double defaultCommissionRate = 0.10;

  PaymentService._({
    required ApiService apiService,
  }) : _apiService = apiService;

  static Future<PaymentService> initialize() async {
    final apiService = await ApiService.initialize();
    return PaymentService._(apiService: apiService);
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
      return [PaymentMethod.wave, PaymentMethod.orangeMoney, PaymentMethod.cash];
    }
  }

  // Créer une intention de paiement avec commission
  Future<PaymentIntent> createPaymentIntent({
    required String bookingId,
    required double amount,
    required PaymentMethod method,
    String? partnerId,
    double? commissionRate,
  }) async {
    try {
      // Calculer la commission
      final commission = await calculateCommission(
        amount: amount, 
        rate: commissionRate
      );
      
      final response = await _apiService.post('/payments/intent', data: {
        'reservationId': bookingId,
        'amount': amount,
        'method': method.toString().split('.').last,
        'partnerId': partnerId,
        'commission': {
          'rate': commission.rate,
          'amount': commission.commissionAmount,
          'partnerAmount': commission.partnerAmount
        }
      });

      return PaymentIntent.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Erreur lors de la création de l\'intention de paiement: ${e.message}');
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
    final commission = await calculateCommission(
      amount: amount, 
      rate: commissionRate
    );
    
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

  // Simuler un paiement Mobile Money avec commission
  Future<Payment> confirmMobileMoneyPayment({
    required String paymentIntentId,
    required String phoneNumber,
    required String provider,
    double amount = 50000, // Montant par défaut pour la simulation
    double? commissionRate,
  }) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(seconds: 2));
    
    // Calculer la commission
    final commission = await calculateCommission(
      amount: amount, 
      rate: commissionRate
    );
    
    return Payment(
      id: 'pay_${_uuid.v4()}',
      bookingId: 'reservation_extracted_from_intent',
      userId: 'user_simulation',
      amount: amount,
      method: _getMobileMoneyMethodByProvider(provider),
      status: PaymentStatus.succeeded,
      transactionId: 'tx_${_uuid.v4().substring(0, 8)}',
      metadata: {
        'phoneNumber': phoneNumber,
        'provider': provider,
      },
      isRefundable: true,
      paidAt: DateTime.now(),
      createdAt: DateTime.now(),
      commission: commission,
    );
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

  // Simuler un paiement par carte avec commission
  Future<Payment> confirmCardPayment({
    required String paymentIntentId,
    required Map<String, dynamic> cardDetails,
    double amount = 50000, // Montant par défaut pour la simulation
    double? commissionRate,
  }) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(seconds: 2));
    
    // Calculer la commission
    final commission = await calculateCommission(
      amount: amount, 
      rate: commissionRate
    );
    
    // Déterminer le type de carte
    final cardType = cardDetails['brand']?.toString().toLowerCase() ?? '';
    final PaymentMethod method = cardType.contains('visa') 
        ? PaymentMethod.visa
        : cardType.contains('mastercard')
            ? PaymentMethod.mastercard
            : PaymentMethod.creditCard;
    
    return Payment(
      id: 'pay_${_uuid.v4()}',
      bookingId: 'reservation_extracted_from_intent',
      userId: 'user_simulation',
      amount: amount,
      method: method,
      status: PaymentStatus.succeeded,
      transactionId: 'tx_${_uuid.v4().substring(0, 8)}',
      metadata: {
        'cardType': cardDetails['brand'] ?? 'unknown',
        'last4': cardDetails['last4'] ?? '0000',
      },
      isRefundable: true,
      paidAt: DateTime.now(),
      createdAt: DateTime.now(),
      commission: commission,
    );
  }
  
  // Simuler un paiement par virement bancaire avec commission
  Future<Payment> confirmBankTransferPayment({
    required String paymentIntentId,
    required Map<String, dynamic> bankDetails,
    double amount = 50000, // Montant par défaut pour la simulation
    double? commissionRate,
  }) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(seconds: 2));
    
    // Calculer la commission
    final commission = await calculateCommission(
      amount: amount, 
      rate: commissionRate
    );
    
    return Payment(
      id: 'pay_${_uuid.v4()}',
      bookingId: 'reservation_extracted_from_intent',
      userId: 'user_simulation',
      amount: amount,
      method: PaymentMethod.bankTransfer,
      status: PaymentStatus.pending, // Les virements sont d'abord en attente
      transactionId: 'tx_${_uuid.v4().substring(0, 8)}',
      metadata: {
        'bankName': bankDetails['bankName'] ?? 'Unknown Bank',
        'accountName': bankDetails['accountName'] ?? 'Unknown Account',
        'reference': 'CHAPECHAPE-${_uuid.v4().substring(0, 8)}',
      },
      isRefundable: true,
      createdAt: DateTime.now(),
      commission: commission,
    );
  }

  // Vérifier le statut d'un paiement (simulation)
  Future<Payment> checkPaymentStatus(String paymentId) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(seconds: 1));
    
    // Calculer une commission fictive pour la simulation
    final commission = await calculateCommission(amount: 50000);
    
    return Payment(
      id: paymentId,
      bookingId: 'reservation_simulation',
      userId: 'user_simulation',
      amount: 50000, // Montant fictif
      method: PaymentMethod.mobileMoney,
      status: PaymentStatus.succeeded,
      transactionId: 'tx_${_uuid.v4().substring(0, 8)}',
      isRefundable: true,
      paidAt: DateTime.now(),
      createdAt: DateTime.now(),
      commission: commission,
    );
  }

  // Récupérer l'historique des paiements (simulation)
  Future<List<Payment>> getPaymentHistory({String? bookingId}) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(seconds: 1));
    
    // Créer un historique fictif
    final paymentsList = <Payment>[];
    
    for (var index = 0; index < 3; index++) {
      // Calcul de la commission en dehors de la construction
      final commission = await calculateCommission(amount: 50000.0 * (index + 1));
      
      paymentsList.add(Payment(
        id: 'pay_${_uuid.v4()}',
        bookingId: bookingId ?? 'reservation_${index + 1}',
        userId: 'user_simulation',
        amount: 50000.0 * (index + 1),
        method: index % 2 == 0 ? PaymentMethod.mobileMoney : PaymentMethod.visa,
        status: PaymentStatus.succeeded,
        transactionId: 'tx_${_uuid.v4().substring(0, 8)}',
        isRefundable: true,
        paidAt: DateTime.now().subtract(Duration(days: index * 7)),
        createdAt: DateTime.now().subtract(Duration(days: index * 7 + 1)),
        bookingResidenceName: 'Résidence simulée ${index + 1}',
        commission: commission,
      ));
    }
    
    return paymentsList;
  }

  // Simuler un remboursement
  Future<Payment> requestRefund({
    required String paymentId,
    double? amount,
    String? reason,
  }) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(seconds: 2));
    
    return Payment(
      id: paymentId,
      bookingId: 'reservation_simulation',
      userId: 'user_simulation',
      amount: amount ?? 50000, // Montant fictif ou celui spécifié
      method: PaymentMethod.mobileMoney,
      status: PaymentStatus.refunded,
      transactionId: 'tx_${_uuid.v4().substring(0, 8)}',
      metadata: {
        'refundReason': reason ?? 'Remboursement demandé par l\'utilisateur',
      },
      isRefundable: false,
      paidAt: DateTime.now().subtract(const Duration(days: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now(),
      commission: await calculateCommission(amount: amount ?? 50000),
    );
  }

  // Simuler annulation d'un paiement
  Future<void> cancelPayment({
    required String paymentId,
    String? reason,
  }) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(seconds: 1));
    // Dans une simulation, nous retournons simplement sans erreur
    return;
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
        'commissionRate': '${(effectiveCommissionRate * 100).toStringAsFixed(0)}%',
        'commissionAmount': commissionAmount,
        'processingFee': processingFee,
        'fixedFee': fixedFee,
      }
    };
  }
}
