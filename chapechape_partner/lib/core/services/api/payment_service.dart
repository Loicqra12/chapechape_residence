import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../../models/payment/payment_model.dart';
import 'api_service.dart';

class PaymentService {
  final ApiService _apiService;
  final Dio _dio;
  
  PaymentService(Dio dio) 
      : _dio = dio,
        _apiService = ApiService(authBloc: null);
  
  // Alternative constructor
  PaymentService.withApiService({required ApiService apiService}) 
      : _apiService = apiService,
        _dio = apiService.dio;
  
  /// Récupère la liste des transactions avec pagination
  Future<TransactionResult> getTransactions({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiService.get(
        '/api/partners/payments',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      
      return TransactionResult.fromJson(response.data);
    } catch (e) {
      throw Exception('Impossible de récupérer les transactions: $e');
    }
  }
  
  /// Demande un retrait de fonds
  Future<PaymentModel> requestWithdrawal({
    required double amount,
    String method = 'bank_transfer',
  }) async {
    try {
      final response = await _apiService.post(
        '/api/partners/payments/withdrawals',
        data: {
          'amount': amount,
          'payment_method': method,
        },
      );
      
      return PaymentModel.fromJson(response.data['transaction']);
    } catch (e) {
      throw Exception('Impossible de traiter la demande de retrait: $e');
    }
  }
  
  /// Annule une demande de retrait en attente
  Future<void> cancelWithdrawal({required String transactionId}) async {
    try {
      await _apiService.post(
        '/api/partners/payments/withdrawals/$transactionId/cancel',
      );
    } catch (e) {
      throw Exception('Impossible d\'annuler le retrait: $e');
    }
  }
  
  /// Récupère le détail d'une transaction
  Future<PaymentModel> getTransactionDetails({required String transactionId}) async {
    try {
      final response = await _apiService.get(
        '/api/partners/payments/$transactionId',
      );
      
      return PaymentModel.fromJson(response.data['transaction']);
    } catch (e) {
      throw Exception('Impossible de récupérer les détails de la transaction: $e');
    }
  }
  
  /// Ajoute une méthode de paiement (pour les futurs retraits)
  Future<void> addPaymentMethod({
    required String type,
    required Map<String, dynamic> details,
  }) async {
    try {
      await _apiService.post(
        '/api/partners/payments/methods',
        data: {
          'type': type,
          'details': details,
        },
      );
    } catch (e) {
      throw Exception('Impossible d\'ajouter la méthode de paiement: $e');
    }
  }
  
  /// Récupère les méthodes de paiement disponibles
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      final response = await _apiService.get(
        '/api/partners/payments/methods',
      );
      
      return (response.data['methods'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Impossible de récupérer les méthodes de paiement: $e');
    }
  }
  
  /// Récupère les statistiques de paiement
  Future<Map<String, dynamic>> getPaymentStats() async {
    try {
      final response = await _apiService.get(
        '/api/partners/payments/stats',
      );
      
      return response.data['stats'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Impossible de récupérer les statistiques de paiement: $e');
    }
  }
  
  // Méthode simulée pour la démo
  Future<TransactionResult> _mockGetTransactions({int page = 1, int limit = 10}) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Générer des transactions fictives
    final now = DateTime.now();
    final List<PaymentModel> transactions = [];
    
    // Différentes sources pour les transactions
    final sources = [
      'Réservation #1234',
      'Réservation #1235',
      'Réservation #1236',
      'Retrait sur compte bancaire',
      'Réservation #1237',
    ];
    
    // Générer des transactions en fonction de la page
    final baseIndex = (page - 1) * limit;
    
    for (int i = 0; i < limit; i++) {
      final index = baseIndex + i;
      
      // Limiter à 25 transactions max
      if (index >= 25) break;
      
      // Alterner entre crédit et débit
      final type = index % 4 == 3 ? PaymentType.withdrawal : PaymentType.credit;
      
      // Générer un montant aléatoire
      final amount = (index % 5 + 1) * 250000.0;
      
      // Date dans le passé
      final date = now.subtract(Duration(days: index * 3));
      
      // Générer la transaction
      transactions.add(PaymentModel(
        id: 'TRX${10000 + index}',
        amount: amount,
        type: type,
        source: sources[i % sources.length],
        date: date,
        status: type == PaymentType.withdrawal ? (index % 3 == 0 ? 'pending' : 'completed') : 'completed',
        sourceId: type == PaymentType.credit ? 'RES${1000 + index}' : null,
      ));
    }
    
    return TransactionResult(
      transactions: transactions,
      balance: 2500000,
      monthlyRevenue: 1500000,
      totalWithdrawals: 500000,
    );
  }
} 