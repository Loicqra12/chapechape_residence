import 'package:dio/dio.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:chapechape_client/core/models/payment_model.dart';
import 'package:chapechape_client/core/services/api_service.dart';

class PaymentService {
  final ApiService _apiService;
  final Uuid _uuid = const Uuid();

  PaymentService._({
    required ApiService apiService,
  }) : _apiService = apiService;

  static Future<PaymentService> initialize() async {
    final apiService = await ApiService.initialize();
    return PaymentService._(apiService: apiService);
  }

  // Créer une intention de paiement
  Future<PaymentIntent> createPaymentIntent({
    required String bookingId,
    required double amount,
    required PaymentMethod method,
  }) async {
    try {
      final response = await _apiService.post('/payments/intent', data: {
        'reservationId': bookingId,
        'amount': amount,
        'method': method.toString().split('.').last,
      });

      return PaymentIntent.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Erreur lors de la création de l\'intention de paiement: ${e.message}');
    }
  }

  // Simuler une intention de paiement
  Future<PaymentIntent> createPaymentIntentSimulated({
    required String bookingId,
    required double amount,
    required PaymentMethod method,
  }) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(seconds: 1));
    
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
    );
  }

  // Simuler un paiement Mobile Money
  Future<Payment> confirmMobileMoneyPayment({
    required String paymentIntentId,
    required String phoneNumber,
    required String provider,
  }) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(seconds: 2));
    
    return Payment(
      id: 'pay_${_uuid.v4()}',
      bookingId: 'reservation_extracted_from_intent',
      userId: 'user_simulation',
      amount: 50000, // Montant fictif
      method: PaymentMethod.mobileMoney,
      status: PaymentStatus.succeeded,
      transactionId: 'tx_${_uuid.v4().substring(0, 8)}',
      metadata: {
        'phoneNumber': phoneNumber,
        'provider': provider,
      },
      isRefundable: true,
      paidAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  // Simuler un paiement par carte
  Future<Payment> confirmCardPayment({
    required String paymentIntentId,
    required Map<String, dynamic> cardDetails,
  }) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(seconds: 2));
    
    return Payment(
      id: 'pay_${_uuid.v4()}',
      bookingId: 'reservation_extracted_from_intent',
      userId: 'user_simulation',
      amount: 50000, // Montant fictif
      method: PaymentMethod.visa,
      status: PaymentStatus.succeeded,
      transactionId: 'tx_${_uuid.v4().substring(0, 8)}',
      metadata: {
        'cardType': 'visa',
        'last4': '4242',
      },
      isRefundable: true,
      paidAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  // Vérifier le statut d'un paiement (simulation)
  Future<Payment> checkPaymentStatus(String paymentId) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(seconds: 1));
    
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
    );
  }

  // Récupérer l'historique des paiements (simulation)
  Future<List<Payment>> getPaymentHistory({String? bookingId}) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(seconds: 1));
    
    // Créer un historique fictif
    return List.generate(
      3,
      (index) => Payment(
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
      ),
    );
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
  }) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Calculer des frais fictifs
    final baseFee = amount * 0.025; // 2.5% de frais
    final fixedFee = 300.0; // Frais fixe
    
    return {
      'amount': amount,
      'fee': baseFee + fixedFee,
      'total': amount + baseFee + fixedFee,
      'breakdown': {
        'baseFee': baseFee,
        'fixedFee': fixedFee,
      }
    };
  }
}

