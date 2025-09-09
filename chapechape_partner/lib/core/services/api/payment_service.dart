import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../../models/payment/payment_model.dart';
import '../../models/payment/payout_model.dart';
import '../../models/payment/wave_model.dart';
import './api_service.dart';
import './auth_service.dart';
import '../wave_transfer_service.dart';

class PaymentService {
  final ApiService _apiService;
  final Dio _dio;
  late final AuthService _authService;
  late final WaveTransferService _waveService;
  
  PaymentService(Dio dio) 
      : _dio = dio,
        _apiService = ApiService(authBloc: null) {
    _authService = AuthService(_dio);
    _initializeWaveService();
  }
  
  // Alternative constructor
  PaymentService.withApiService({required ApiService apiService}) 
      : _apiService = apiService,
        _dio = apiService.dio {
    _authService = AuthService(_dio);
    _initializeWaveService();
  }

  /// Initialiser le service Wave
  Future<void> _initializeWaveService() async {
    _waveService = await WaveTransferService.initialize();
  }

  /// Récupère l'ID du partner connecté
  Future<String> _getCurrentPartnerId() async {
    try {
      final partner = await _authService.getProfile();
      return partner.id;
    } catch (e) {
      throw Exception('Impossible de récupérer l\'ID du partner connecté: $e');
    }
  }
  
  /// Récupère les transactions avec pagination
  Future<TransactionResult> getTransactions({
    int page = 1, 
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get(
        '/payments/my-payments', // ✅ Correction: suppression du /api dupliqué
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
  
  /// Demande un retrait (via création d'un payout)
  Future<PaymentModel> requestWithdrawal({
    required double amount,
    required String method,
  }) async {
    try {
      // Note: Le backend n'a pas d'endpoint direct pour withdrawals
      // Les retraits se font via le système de payouts pour les partners
      final response = await _apiService.post(
        '/api/payments/create-payment-intent', // Utiliser l'endpoint existant
        data: {
          'amount': amount,
          'paymentMethod': method,
        },
      );
      
      return PaymentModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Impossible de traiter la demande de retrait: $e');
    }
  }
  
  /// Annule une demande de retrait en attente (via refund)
  Future<void> cancelWithdrawal({required String transactionId}) async {
    try {
      await _apiService.post(
        '/api/payments/$transactionId/refund', // ✅ ALIGNÉ - endpoint existant backend
        data: {
          'reason': 'Annulation demandée par le partenaire'
        },
      );
    } catch (e) {
      throw Exception('Impossible d\'annuler le retrait: $e');
    }
  }
  
  /// Récupère le détail d'une transaction
  Future<PaymentModel> getTransactionDetails({required String transactionId}) async {
    try {
      final response = await _apiService.get(
        '/api/payments/$transactionId',
      );
      
      return PaymentModel.fromJson(response.data['transaction']);
    } catch (e) {
      throw Exception('Impossible de récupérer les détails de la transaction: $e');
    }
  }
  
  /// Ajoute une méthode de paiement (via AfricanPaymentService)
  Future<void> addPaymentMethod({
    required String type,
    required Map<String, dynamic> details,
  }) async {
    try {
      // Note: Le backend n'a pas d'endpoint /api/payments/methods
      // Les méthodes de paiement sont gérées via AfricanPaymentService en local
      // ou via des endpoints partner spécifiques si implémentés
      throw UnimplementedError('Utiliser AfricanPaymentService pour gérer les méthodes de paiement');
    } catch (e) {
      throw Exception('Impossible d\'ajouter la méthode de paiement: $e');
    }
  }
  
  /// Récupère les méthodes de paiement disponibles (via AfricanPaymentService)
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      // Note: Le backend n'a pas d'endpoint /api/payments/methods
      // Les méthodes de paiement sont gérées via AfricanPaymentService
      throw UnimplementedError('Utiliser AfricanPaymentService.getAvailableAfricanPaymentMethods()');
    } catch (e) {
      throw Exception('Impossible de récupérer les méthodes de paiement: $e');
    }
  }
  
  /// Récupère les statistiques de paiement (via payout stats)
  Future<Map<String, dynamic>> getPaymentStats() async {
    try {
      // Note: Le backend n'a pas d'endpoint /api/payments/stats
      // Les statistiques se trouvent dans /api/payouts/stats/:partnerId
      // Il faut obtenir l'ID du partner connecté depuis le service d'authentification
      throw UnimplementedError('Utiliser getPayoutStats() avec partnerId du user connecté');
    } catch (e) {
      throw Exception('Impossible de récupérer les statistiques de paiement: $e');
    }
  }

  // ========== MÉTHODES PAYOUT ==========
  
  /// Récupère la liste des payouts pour le partenaire connecté
  Future<List<PayoutModel>> getPayouts({
    int page = 1, 
    int limit = 20,
    PayoutStatus? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (status != null) {
        queryParams['status'] = status.name;
      }
      
      // Récupérer l'ID du partner connecté depuis AuthService
      final partnerId = await _getCurrentPartnerId();
      final response = await _apiService.get(
        '/api/payouts/partner/$partnerId', // ✅ ALIGNÉ avec backend
        queryParameters: queryParams,
      );
      
      final payoutsData = response.data['payouts'] as List;
      return payoutsData.map((p) => PayoutModel.fromJson(p)).toList();
    } catch (e) {
      throw Exception('Impossible de récupérer les reversements: $e');
    }
  }
  
  /// Récupère le détail d'un payout spécifique
  Future<PayoutModel> getPayoutDetails(String payoutId) async {
    try {
      final response = await _apiService.get(
        '/api/payouts/$payoutId', // ✅ ALIGNÉ avec backend - endpoint existant
      );
      
      return PayoutModel.fromJson(response.data['payout']);
    } catch (e) {
      throw Exception('Impossible de récupérer les détails du reversement: $e');
    }
  }
  
  /// Récupère les statistiques des payouts pour le partenaire connecté
  Future<PayoutStats> getPayoutStats() async {
    try {
      // Récupérer l'ID du partner connecté depuis AuthService
      final partnerId = await _getCurrentPartnerId();
      final response = await _apiService.get(
        '/api/payouts/stats/$partnerId', // ✅ ALIGNÉ avec backend
      );
      
      return PayoutStats.fromJson(response.data['stats']);
    } catch (e) {
      throw Exception('Impossible de récupérer les statistiques des reversements: $e');
    }
  }
  
  /// Récupère l'historique des payouts avec filtres (utilise getPayouts avec filtres)
  Future<PayoutHistoryResult> getPayoutHistory({
    int page = 1,
    int limit = 20,
    DateTime? fromDate,
    DateTime? toDate,
    PayoutStatus? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (fromDate != null) {
        queryParams['startDate'] = fromDate.toIso8601String();
      }
      
      if (toDate != null) {
        queryParams['endDate'] = toDate.toIso8601String();
      }
      
      if (status != null) {
        queryParams['status'] = status.name;
      }
      
      // Utiliser l'endpoint getPayouts existant avec filtres
      final partnerId = await _getCurrentPartnerId();
      final response = await _apiService.get(
        '/api/payouts/partner/$partnerId', // ✅ ALIGNÉ avec backend
        queryParameters: queryParams,
      );
      
      return PayoutHistoryResult.fromJson(response.data);
    } catch (e) {
      throw Exception('Impossible de récupérer l\'historique des reversements: $e');
    }
  }
  
  // ========== MÉTHODES WAVE ==========
  
  /// Initier un transfert Wave
  Future<WaveTransferModel> initiateWaveTransfer({
    required double amount,
    required String mobile,
    required String name,
    String? paymentReason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      return await _waveService.initiateTransfer(
        amount: amount,
        mobile: mobile,
        name: name,
        paymentReason: paymentReason,
        metadata: metadata,
      );
    } catch (e) {
      throw Exception('Impossible d\'initier le transfert Wave: $e');
    }
  }
  
  /// Vérifier le statut d'un transfert Wave
  Future<WaveTransferModel> getWaveTransferStatus(String waveId) async {
    try {
      return await _waveService.getTransferStatus(waveId);
    } catch (e) {
      throw Exception('Impossible de récupérer le statut Wave: $e');
    }
  }
  
  /// Rechercher des transferts Wave
  Future<WaveSearchResult> searchWaveTransfers({
    String? clientReference,
    String? mobile,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 20,
  }) async {
    try {
      return await _waveService.searchTransfers(
        clientReference: clientReference,
        mobile: mobile,
        fromDate: fromDate,
        toDate: toDate,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Impossible de rechercher les transferts Wave: $e');
    }
  }
  
  /// Créer un batch de transferts Wave
  Future<WaveBatchModel> createWaveBatch({
    required List<WaveBatchTransfer> transfers,
  }) async {
    try {
      return await _waveService.createBatch(transfers: transfers);
    } catch (e) {
      throw Exception('Impossible de créer le batch Wave: $e');
    }
  }
  
  /// Vérifier le statut d'un batch Wave
  Future<WaveBatchModel> getWaveBatchStatus(String batchId) async {
    try {
      return await _waveService.getBatchStatus(batchId);
    } catch (e) {
      throw Exception('Impossible de récupérer le statut du batch Wave: $e');
    }
  }
  
  /// Annuler un transfert Wave
  Future<bool> reverseWaveTransfer(String waveId) async {
    try {
      return await _waveService.reverseTransfer(waveId);
    } catch (e) {
      throw Exception('Impossible d\'annuler le transfert Wave: $e');
    }
  }
  
  /// Récupérer l'historique des transferts Wave
  Future<List<WaveTransferModel>> getWaveTransferHistory({
    int page = 1,
    int limit = 20,
    WaveTransferStatus? statusFilter,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      return await _waveService.getTransferHistory(
        page: page,
        limit: limit,
        statusFilter: statusFilter,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      throw Exception('Impossible de récupérer l\'historique Wave: $e');
    }
  }
  
  /// Récupérer les statistiques des transferts Wave
  Future<WaveTransferStats> getWaveTransferStats({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      return await _waveService.getTransferStats(
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      throw Exception('Impossible de récupérer les statistiques Wave: $e');
    }
  }
  
  /// Vérifier si Wave est disponible
  Future<bool> isWaveAvailable() async {
    try {
      return await _waveService.isWaveAvailable();
    } catch (e) {
      return false;
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