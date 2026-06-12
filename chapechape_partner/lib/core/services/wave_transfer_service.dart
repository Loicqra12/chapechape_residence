
import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/payment/wave_model.dart';
import 'api/api_service.dart';
import 'api/auth_service.dart';

/// Service Wave Transfer pour les transferts d'argent aux partenaires
/// Gère les payouts, batch transfers et recherches via Wave API
class WaveTransferService {
  final ApiService _apiService;
  final AuthService _authService;
  
  WaveTransferService._({
    required ApiService apiService,
    required AuthService authService,
  }) : _apiService = apiService,
       _authService = authService;
  
  static Future<WaveTransferService> initialize() async {
    final apiService = ApiService();
    final authService = AuthService(apiService.dio);
    return WaveTransferService._(
      apiService: apiService,
      authService: authService,
    );
  }

  /// Initier un transfert Wave vers un numéro de téléphone
  Future<WaveTransferModel> initiateTransfer({
    required double amount,
    required String mobile,
    required String name,
    String? paymentReason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _validateTransferParams(
        amount: amount,
        mobile: mobile,
        name: name,
      );

      // PROB #9 CORRIGÉ : ApiService du partner ajoute déjà le préfixe /api dans sa baseUrl
      // Ne pas ajouter /api ici sinon on obtient /api/api/payouts/...
      final response = await _apiService.post('/payouts/wave/transfer', data: {
        'amount': amount,
        'mobile': _formatPhoneNumber(mobile),
        'name': name,
        'payment_reason': paymentReason ?? 'Paiement partenaire ChapeChape',
        'metadata': metadata ?? {},
      });

      final data = response.data;
      
      return WaveTransferModel.fromJson(data['transfer']);
      
    } on DioException catch (e) {
      throw WaveTransferException('Erreur lors du transfert Wave: ${e.message}');
    }
  }

  /// Vérifier le statut d'un transfert Wave
  Future<WaveTransferModel> getTransferStatus(String waveId) async {
    try {
      final response = await _apiService.get('/payouts/wave/transfer/$waveId/status');
      
      final data = response.data;
      
      return WaveTransferModel.fromJson(data['transfer']);
      
    } on DioException catch (e) {
      throw WaveTransferException('Erreur lors de la vérification du statut: ${e.message}');
    }
  }

  /// Rechercher des transferts Wave par référence client
  Future<WaveSearchResult> searchTransfers({
    String? clientReference,
    String? mobile,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (clientReference != null) {
        queryParams['client_reference'] = clientReference;
      }
      
      if (mobile != null) {
        queryParams['mobile'] = mobile;
      }
      
      if (fromDate != null) {
        queryParams['from_date'] = fromDate.toIso8601String();
      }
      
      if (toDate != null) {
        queryParams['to_date'] = toDate.toIso8601String();
      }
      
      if (limit > 0) {
        queryParams['limit'] = limit;
      }
      
      final response = await _apiService.get(
        '/payouts/wave/search',
        queryParameters: queryParams,
      );
      
      return WaveSearchResult.fromJson(response.data);
      
    } on DioException catch (e) {
      throw WaveTransferException('Erreur lors de la recherche: ${e.message}');
    }
  }

  /// Créer un batch de transferts Wave
  Future<WaveBatchModel> createBatch({
    required List<WaveBatchTransfer> transfers,
  }) async {
    try {
      if (transfers.isEmpty) {
        throw WaveTransferException('Au moins un transfert requis pour créer un batch');
      }
      
      if (transfers.length > 100) {
        throw WaveTransferException('Maximum 100 transferts par batch');
      }

      // Valider chaque transfert
      for (final transfer in transfers) {
        _validateTransferParams(
          amount: transfer.amount,
          mobile: transfer.mobile,
          name: transfer.name,
        );
      }

      final response = await _apiService.post('/payouts/wave/batch', data: {
        'transfers': transfers.map((t) => {
          'amount': t.amount,
          'mobile': _formatPhoneNumber(t.mobile),
          'name': t.name,
          'payment_reason': t.paymentReason ?? 'Batch paiement partenaire',
        }).toList(),
      });

      final data = response.data;
      
      return WaveBatchModel.fromJson(data);
      
    } on DioException catch (e) {
      throw WaveTransferException('Erreur lors de la création du batch: ${e.message}');
    }
  }

  /// Vérifier le statut d'un batch Wave
  Future<WaveBatchModel> getBatchStatus(String batchId) async {
    try {
      final response = await _apiService.get('/payouts/wave/batch/$batchId/status');
      
      return WaveBatchModel.fromJson(response.data['data']);
      
    } on DioException catch (e) {
      throw WaveTransferException('Erreur lors de la vérification du batch: ${e.message}');
    }
  }

  /// Annuler un transfert Wave (reverse)
  Future<bool> reverseTransfer(String waveId) async {
    try {
      final response = await _apiService.post('/payouts/wave/transfer/$waveId/reverse');
      
      return response.data['success'] ?? false;
      
    } on DioException catch (e) {
      throw WaveTransferException('Erreur lors de l\'annulation: ${e.message}');
    }
  }

  /// Récupérer l'historique des transferts Wave pour le partenaire
  Future<List<WaveTransferModel>> getTransferHistory({
    int page = 1,
    int limit = 20,
    WaveTransferStatus? statusFilter,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final partnerId = await _getCurrentPartnerId();
      
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'partner_id': partnerId,
      };
      
      if (statusFilter != null) {
        queryParams['status'] = statusFilter.name;
      }
      
      if (fromDate != null) {
        queryParams['from_date'] = fromDate.toIso8601String();
      }
      
      if (toDate != null) {
        queryParams['to_date'] = toDate.toIso8601String();
      }
      
      // Utiliser l'endpoint de recherche avec filtres
      final result = await searchTransfers(
        fromDate: fromDate,
        toDate: toDate,
        limit: limit,
      );
      
      // Filtrer par statut si spécifié
      if (statusFilter != null) {
        return result.transfers.where((t) => t.status == statusFilter).toList();
      }
      
      return result.transfers;
      
    } on DioException catch (e) {
      throw WaveTransferException('Erreur lors de la récupération de l\'historique: ${e.message}');
    }
  }

  /// Récupérer les statistiques des transferts Wave
  Future<WaveTransferStats> getTransferStats({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final partnerId = await _getCurrentPartnerId();
      
      final queryParams = <String, dynamic>{
        'partner_id': partnerId,
      };
      
      if (fromDate != null) {
        queryParams['from_date'] = fromDate.toIso8601String();
      }
      
      if (toDate != null) {
        queryParams['to_date'] = toDate.toIso8601String();
      }
      
      // PROB #10 CORRIGÉ : ne pas charger 1000 enregistrements pour calculer des stats
      // Limite à 100 — les stats précises doivent être calculées côté serveur
      final transfers = await getTransferHistory(
        limit: 100,
        fromDate: fromDate,
        toDate: toDate,
      );
      
      return _calculateStats(transfers);
      
    } on DioException catch (e) {
      throw WaveTransferException('Erreur lors de la récupération des statistiques: ${e.message}');
    }
  }

  /// Récupérer l'ID du partenaire connecté
  Future<String> _getCurrentPartnerId() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw WaveTransferException('Utilisateur non authentifié');
    }
    
    // Parse token to get partner ID (assuming JWT structure)
    final payload = _parseJwtPayload(token);
    final partnerId = payload['partnerId'] ?? payload['userId'];
    if (partnerId == null) {
      throw WaveTransferException('ID partenaire non trouvé dans le token');
    }
    return partnerId as String;
  }

  /// Valider les paramètres de transfert
  void _validateTransferParams({
    required double amount,
    required String mobile,
    required String name,
  }) {
    if (amount <= 0) {
      throw WaveTransferException('Montant invalide');
    }
    
    // Montant minimum 100 XOF pour Wave
    if (amount < 100) {
      throw WaveTransferException('Montant minimum : 100 XOF');
    }
    
    // Montant maximum 1,000,000 XOF par transfert
    if (amount > 1000000) {
      throw WaveTransferException('Montant maximum : 1,000,000 XOF');
    }
    
    if (mobile.isEmpty) {
      throw WaveTransferException('Numéro de téléphone requis');
    }
    
    if (name.isEmpty || name.length < 2) {
      throw WaveTransferException('Nom du bénéficiaire requis (minimum 2 caractères)');
    }
    
    if (name.length > 255) {
      throw WaveTransferException('Nom du bénéficiaire trop long (maximum 255 caractères)');
    }
    
    // Validation format téléphone international
    final phoneRegex = RegExp(r'^\+[1-9]\d{1,14}$');
    final formattedPhone = _formatPhoneNumber(mobile);
    if (!phoneRegex.hasMatch(formattedPhone)) {
      throw WaveTransferException('Format de numéro de téléphone invalide');
    }
  }

  /// Formater le numéro de téléphone pour Wave
  String _formatPhoneNumber(String phoneNumber) {
    // Nettoyer le numéro
    String clean = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Si déjà au format international, retourner tel quel
    if (clean.startsWith('+')) {
      return clean;
    }
    
    // Ajouter le préfixe ivoirien si nécessaire
    if (clean.length == 10 && clean.startsWith('0')) {
      return '+225${clean.substring(1)}';
    } else if (clean.length == 8) {
      return '+225$clean';
    } else if (clean.length == 11 && clean.startsWith('225')) {
      return '+$clean';
    }
    
    // Si le format n'est pas reconnu, retourner tel quel et laisser la validation échouer
    return clean.startsWith('+') ? clean : '+$clean';
  }

  /// Calculer les statistiques à partir d'une liste de transferts
  WaveTransferStats _calculateStats(List<WaveTransferModel> transfers) {
    if (transfers.isEmpty) {
      return const WaveTransferStats(
        totalTransfers: 0,
        totalAmount: 0.0,
        successfulTransfers: 0,
        failedTransfers: 0,
        pendingTransfers: 0,
        totalFees: 0.0,
        averageAmount: 0.0,
        successRate: 0.0,
      );
    }

    final totalTransfers = transfers.length;
    final totalAmount = transfers.fold<double>(0.0, (sum, t) => sum + t.amount);
    final successfulTransfers = transfers.where((t) => t.isCompleted).length;
    final failedTransfers = transfers.where((t) => t.isFailed).length;
    final pendingTransfers = transfers.where((t) => t.isPending).length;
    final totalFees = transfers.fold<double>(0.0, (sum, t) => sum + (t.fee ?? 0.0));
    final averageAmount = totalAmount / totalTransfers;
    final successRate = totalTransfers > 0 ? successfulTransfers / totalTransfers : 0.0;
    
    // Trouver le dernier transfert
    transfers.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final lastTransferDate = transfers.isNotEmpty ? transfers.first.timestamp : null;

    return WaveTransferStats(
      totalTransfers: totalTransfers,
      totalAmount: totalAmount,
      successfulTransfers: successfulTransfers,
      failedTransfers: failedTransfers,
      pendingTransfers: pendingTransfers,
      totalFees: totalFees,
      averageAmount: averageAmount,
      successRate: successRate,
      lastTransferDate: lastTransferDate,
    );
  }

  /// Parser le payload d'un token JWT
  Map<String, dynamic> _parseJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw WaveTransferException('Token JWT invalide');
      }
      
      // Décoder la partie payload (partie 2)
      final payload = parts[1];
      
      // Ajouter padding si nécessaire
      final normalizedPayload = base64Url.normalize(payload);
      
      // Décoder et parser
      final decodedBytes = base64Url.decode(normalizedPayload);
      final decodedString = utf8.decode(decodedBytes);
      
      return jsonDecode(decodedString) as Map<String, dynamic>;
    } catch (e) {
      throw WaveTransferException('Erreur lors du parsing du token JWT: $e');
    }
  }

  /// Obtenir les méthodes de paiement Wave disponibles
  List<String> getAvailablePaymentMethods() {
    return [
      'WAVE',
      'ORANGE_MONEY',
      'MTN_MONEY',
      'MOOV_MONEY',
    ];
  }

  /// Vérifier si Wave est disponible
  Future<bool> isWaveAvailable() async {
    try {
      // Faire un appel simple pour vérifier la disponibilité
      await _apiService.get('/api/health');
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Modèle pour un transfert dans un batch
class WaveBatchTransfer {
  final double amount;
  final String mobile;
  final String name;
  final String? paymentReason;

  const WaveBatchTransfer({
    required this.amount,
    required this.mobile,
    required this.name,
    this.paymentReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'mobile': mobile,
      'name': name,
      'payment_reason': paymentReason,
    };
  }
}
