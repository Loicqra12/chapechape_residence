import 'dart:convert';
import 'package:dio/dio.dart';
import 'api/api_service.dart';
import 'api/auth_service.dart';

/// Service CinetPay Transfer pour les transferts d'argent aux partenaires
/// Gère les payouts, vérifications de solde et transferts via CinetPay Transfer API
class CinetPayTransferService {
  final ApiService _apiService;
  final AuthService _authService;
  
  CinetPayTransferService._({
    required ApiService apiService,
    required AuthService authService,
  }) : _apiService = apiService,
       _authService = authService;
  
  static Future<CinetPayTransferService> initialize() async {
    final apiService = ApiService();
    final authService = AuthService(apiService.dio);
    return CinetPayTransferService._(
      apiService: apiService,
      authService: authService,
    );
  }

  /// Récupérer le solde CinetPay du partenaire
  Future<CinetPayBalance> getBalance() async {
    try {
      final partnerId = await _getCurrentPartnerId();
      
      final response = await _apiService.get('/api/payouts/cinetpay/balance/$partnerId');
      
      final data = response.data;
      return CinetPayBalance(
        amount: data['balance']?.toDouble() ?? 0.0,
        currency: data['currency'] ?? 'XOF',
        lastUpdated: data['lastUpdated'] != null 
            ? DateTime.parse(data['lastUpdated'])
            : DateTime.now(),
      );
      
    } on DioException catch (e) {
      throw CinetPayTransferException('Erreur lors de la récupération du solde: ${e.message}');
    }
  }

  /// Initier un transfert d'argent vers un numéro de téléphone
  Future<CinetPayTransferResult> initiateTransfer({
    required double amount,
    required String phoneNumber,
    required String paymentMethod,
    String? reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _validateTransferParams(
        amount: amount,
        phoneNumber: phoneNumber,
      );

      final partnerId = await _getCurrentPartnerId();
      
      final response = await _apiService.post('/api/payouts', data: {
        'partnerId': partnerId,
        'amount': amount,
        'method': 'cinetpay_transfer',
        'destination': {
          'phoneNumber': formatPhoneNumber(phoneNumber),
          'paymentMethod': paymentMethod,
        },
        'reason': reason ?? 'Paiement partenaire ChapeChape',
        'metadata': metadata ?? {},
      });

      final data = response.data;
      
      return CinetPayTransferResult(
        success: data['success'] ?? false,
        transferId: data['transferId'],
        transactionId: data['transactionId'],
        status: _mapTransferStatus(data['status']),
        amount: amount,
        phoneNumber: phoneNumber,
        estimatedDelivery: data['estimatedDelivery'] != null
            ? DateTime.parse(data['estimatedDelivery'])
            : null,
        fees: data['fees']?.toDouble(),
      );
      
    } on DioException catch (e) {
      throw CinetPayTransferException('Erreur lors du transfert: ${e.message}');
    }
  }

  /// Vérifier le statut d'un transfert
  Future<CinetPayTransferStatus> checkTransferStatus(String transferId) async {
    try {
      final partnerId = await _getCurrentPartnerId();
      
      final response = await _apiService.get('/api/payouts/$transferId?partnerId=$partnerId');
      
      final data = response.data;
      
      return CinetPayTransferStatus(
        transferId: transferId,
        status: _mapTransferStatus(data['status']),
        amount: data['amount']?.toDouble(),
        phoneNumber: data['destination']?['phoneNumber'],
        processedAt: data['processedAt'] != null
            ? DateTime.parse(data['processedAt'])
            : null,
        errorMessage: data['errorMessage'],
        fees: data['fees']?.toDouble(),
      );
      
    } on DioException catch (e) {
      throw CinetPayTransferException('Erreur lors de la vérification du statut: ${e.message}');
    }
  }

  /// Récupérer l'historique des transferts
  Future<List<CinetPayTransferStatus>> getTransferHistory({
    int page = 1,
    int limit = 20,
    TransferStatus? statusFilter,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final partnerId = await _getCurrentPartnerId();
      
      Map<String, dynamic> queryParams = {
        'partnerId': partnerId,
        'page': page,
        'limit': limit,
        'method': 'cinetpay_transfer',
      };
      
      if (statusFilter != null) {
        queryParams['status'] = statusFilter.name;
      }
      
      if (fromDate != null) {
        queryParams['fromDate'] = fromDate.toIso8601String();
      }
      
      if (toDate != null) {
        queryParams['toDate'] = toDate.toIso8601String();
      }
      
      final queryString = _buildQueryString(queryParams);
      final response = await _apiService.get('/api/payouts${queryString.isNotEmpty ? '?$queryString' : ''}');
      
      final List<dynamic> transfers = response.data['payouts'] ?? [];
      
      return transfers.map((transfer) => CinetPayTransferStatus(
        transferId: transfer['_id'],
        status: _mapTransferStatus(transfer['status']),
        amount: transfer['amount']?.toDouble(),
        phoneNumber: transfer['destination']?['phoneNumber'],
        processedAt: transfer['processedAt'] != null
            ? DateTime.parse(transfer['processedAt'])
            : null,
        createdAt: transfer['createdAt'] != null
            ? DateTime.parse(transfer['createdAt'])
            : null,
        fees: transfer['fees']?.toDouble(),
        reason: transfer['reason'],
      )).toList();
      
    } on DioException catch (e) {
      throw CinetPayTransferException('Erreur lors de la récupération de l\'historique: ${e.message}');
    }
  }

  /// Annuler un transfert en attente
  Future<bool> cancelTransfer(String transferId) async {
    try {
      final partnerId = await _getCurrentPartnerId();
      
      final response = await _apiService.post('/api/payouts/$transferId/cancel', data: {
        'partnerId': partnerId,
        'reason': 'Annulation demandée par le partenaire',
      });

      return response.data['success'] ?? false;
      
    } on DioException catch (e) {
      throw CinetPayTransferException('Erreur lors de l\'annulation: ${e.message}');
    }
  }

  /// Récupérer les statistiques des transferts
  Future<CinetPayTransferStats> getTransferStats({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final partnerId = await _getCurrentPartnerId();
      
      Map<String, dynamic> queryParams = {
        'partnerId': partnerId,
      };
      
      if (fromDate != null) {
        queryParams['fromDate'] = fromDate.toIso8601String();
      }
      
      if (toDate != null) {
        queryParams['toDate'] = toDate.toIso8601String();
      }
      
      final queryString = _buildQueryString(queryParams);
      final response = await _apiService.get('/api/payouts/cinetpay/transfer/stats${queryString.isNotEmpty ? '?$queryString' : ''}');
      
      final data = response.data;
      
      return CinetPayTransferStats(
        totalTransfers: data['totalTransfers'] ?? 0,
        totalAmount: data['totalAmount']?.toDouble() ?? 0.0,
        successfulTransfers: data['successfulTransfers'] ?? 0,
        failedTransfers: data['failedTransfers'] ?? 0,
        pendingTransfers: data['pendingTransfers'] ?? 0,
        totalFees: data['totalFees']?.toDouble() ?? 0.0,
        averageAmount: data['averageAmount']?.toDouble() ?? 0.0,
        successRate: data['successRate']?.toDouble() ?? 0.0,
      );
      
    } on DioException catch (e) {
      throw CinetPayTransferException('Erreur lors de la récupération des statistiques: ${e.message}');
    }
  }

  /// Récupérer l'ID du partenaire connecté
  Future<String> _getCurrentPartnerId() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw CinetPayTransferException('Utilisateur non authentifié');
    }
    
    // Parse token to get partner ID (assuming JWT structure)
    final payload = _parseJwtPayload(token);
    final partnerId = payload['partnerId'] ?? payload['userId'];
    if (partnerId == null) {
      throw CinetPayTransferException('ID partenaire non trouvé dans le token');
    }
    return partnerId as String;
  }

  /// Mapper le statut backend vers enum TransferStatus
  TransferStatus _mapTransferStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'success':
      case 'delivered':
        return TransferStatus.completed;
      case 'failed':
      case 'error':
      case 'rejected':
        return TransferStatus.failed;
      case 'cancelled':
      case 'canceled':
        return TransferStatus.cancelled;
      case 'processing':
      case 'in_progress':
        return TransferStatus.processing;
      case 'pending':
      default:
        return TransferStatus.pending;
    }
  }

  /// Valider les paramètres de transfert
  void _validateTransferParams({
    required double amount,
    required String phoneNumber,
  }) {
    if (amount <= 0) {
      throw CinetPayTransferException('Montant invalide');
    }
    
    // Montant minimum 100 XOF pour CinetPay Transfer
    if (amount < 100) {
      throw CinetPayTransferException('Montant minimum : 100 XOF');
    }
    
    // Montant maximum 1,000,000 XOF par transfert
    if (amount > 1000000) {
      throw CinetPayTransferException('Montant maximum : 1,000,000 XOF');
    }
    
    if (phoneNumber.isEmpty) {
      throw CinetPayTransferException('Numéro de téléphone requis');
    }
    
    // Validation format téléphone ivoirien
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.length < 8) {
      throw CinetPayTransferException('Numéro de téléphone invalide');
    }
  }

  /// Formater le numéro de téléphone pour CinetPay Transfer
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

  /// Obtenir les méthodes de transfert disponibles
  List<String> getAvailableTransferMethods() {
    return [
      'ORANGE_MONEY',
      'MTN_MONEY', 
      'MOOV_MONEY',
      'WAVE',
      'FLOOZ',
    ];
  }

  /// Construire une chaîne de requête à partir d'un Map
  String _buildQueryString(Map<String, dynamic> params) {
    final entries = <String>[];
    params.forEach((key, value) {
      if (value != null) {
        entries.add('$key=${Uri.encodeComponent(value.toString())}');
      }
    });
    return entries.join('&');
  }

  /// Parser le payload d'un token JWT
  Map<String, dynamic> _parseJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw CinetPayTransferException('Token JWT invalide');
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
      throw CinetPayTransferException('Erreur lors du parsing du token JWT: $e');
    }
  }
}

/// Résultat d'un transfert CinetPay
class CinetPayTransferResult {
  final bool success;
  final String? transferId;
  final String? transactionId;
  final TransferStatus status;
  final double amount;
  final String phoneNumber;
  final DateTime? estimatedDelivery;
  final double? fees;
  final String? errorMessage;

  CinetPayTransferResult({
    required this.success,
    this.transferId,
    this.transactionId,
    required this.status,
    required this.amount,
    required this.phoneNumber,
    this.estimatedDelivery,
    this.fees,
    this.errorMessage,
  });

  bool get isSuccessful => success && status != TransferStatus.failed;
  bool get isPending => status == TransferStatus.pending || status == TransferStatus.processing;
  bool get isFailed => !success || status == TransferStatus.failed;
}

/// Statut d'un transfert CinetPay
class CinetPayTransferStatus {
  final String transferId;
  final TransferStatus status;
  final double? amount;
  final String? phoneNumber;
  final DateTime? processedAt;
  final DateTime? createdAt;
  final String? errorMessage;
  final double? fees;
  final String? reason;

  CinetPayTransferStatus({
    required this.transferId,
    required this.status,
    this.amount,
    this.phoneNumber,
    this.processedAt,
    this.createdAt,
    this.errorMessage,
    this.fees,
    this.reason,
  });

  bool get isCompleted => status == TransferStatus.completed;
  bool get isFailed => status == TransferStatus.failed;
  bool get isPending => status == TransferStatus.pending || status == TransferStatus.processing;
  bool get isCancelled => status == TransferStatus.cancelled;
}

/// Solde CinetPay du partenaire
class CinetPayBalance {
  final double amount;
  final String currency;
  final DateTime lastUpdated;

  CinetPayBalance({
    required this.amount,
    required this.currency,
    required this.lastUpdated,
  });

  String get formattedAmount => '${amount.toStringAsFixed(0)} $currency';
  bool get hasBalance => amount > 0;
}

/// Statistiques des transferts CinetPay
class CinetPayTransferStats {
  final int totalTransfers;
  final double totalAmount;
  final int successfulTransfers;
  final int failedTransfers;
  final int pendingTransfers;
  final double totalFees;
  final double averageAmount;
  final double successRate;

  CinetPayTransferStats({
    required this.totalTransfers,
    required this.totalAmount,
    required this.successfulTransfers,
    required this.failedTransfers,
    required this.pendingTransfers,
    required this.totalFees,
    required this.averageAmount,
    required this.successRate,
  });

  String get formattedTotalAmount => '${totalAmount.toStringAsFixed(0)} XOF';
  String get formattedAverageAmount => '${averageAmount.toStringAsFixed(0)} XOF';
  String get formattedSuccessRate => '${(successRate * 100).toStringAsFixed(1)}%';
  String get formattedTotalFees => '${totalFees.toStringAsFixed(0)} XOF';
}

/// Enum pour les statuts de transfert
enum TransferStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

/// Extension pour obtenir le nom d'affichage du statut
extension TransferStatusExtension on TransferStatus {
  String get displayName {
    switch (this) {
      case TransferStatus.pending:
        return 'En attente';
      case TransferStatus.processing:
        return 'En cours';
      case TransferStatus.completed:
        return 'Terminé';
      case TransferStatus.failed:
        return 'Échoué';
      case TransferStatus.cancelled:
        return 'Annulé';
    }
  }

  String get description {
    switch (this) {
      case TransferStatus.pending:
        return 'Le transfert est en attente de traitement';
      case TransferStatus.processing:
        return 'Le transfert est en cours de traitement';
      case TransferStatus.completed:
        return 'Le transfert a été effectué avec succès';
      case TransferStatus.failed:
        return 'Le transfert a échoué';
      case TransferStatus.cancelled:
        return 'Le transfert a été annulé';
    }
  }
}

class CinetPayTransferException implements Exception {
  final String message;
  final String? code;

  CinetPayTransferException(this.message, [this.code]);

  @override
  String toString() => 'CinetPayTransferException: $message${code != null ? ' (Code: $code)' : ''}';
}
