import 'package:dio/dio.dart';
import '../../models/country_info.dart';
import '../../config/app_config_manager.dart';

/// Service pour gérer les pays et leur configuration
class CountryService {
  late final Dio _dio;
  
  CountryService() {
    _dio = Dio(BaseOptions(
      baseUrl: '${AppConfigManager.apiBaseUrl}/api/countries',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Ajouter l'interceptor de logs
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  /// Obtenir tous les pays
  Future<List<CountryInfo>> getAllCountries({
    String? status,
    bool activeOnly = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (activeOnly) queryParams['status'] = 'active';
      
      final response = await _dio.get('/', queryParameters: queryParams);
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> countriesData = response.data['data'];
        return countriesData
            .map((countryJson) => CountryInfo.fromJson(countryJson))
            .toList();
      } else {
        throw Exception('Erreur récupération pays');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Erreur inattendue: ${e.toString()}');
    }
  }

  /// Obtenir la configuration d'un pays spécifique
  Future<CountryInfo> getCountryConfig(String countryCode) async {
    try {
      final response = await _dio.get('/$countryCode');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return CountryInfo.fromJson(response.data['data']);
      } else {
        throw Exception('Pays non trouvé');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Erreur inattendue: ${e.toString()}');
    }
  }

  /// Détecter le pays depuis un numéro de téléphone
  Future<CountryDetectionResult> detectCountryFromPhone(String phoneNumber) async {
    try {
      final response = await _dio.post('/detect', data: {
        'phoneNumber': phoneNumber,
      });
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return CountryDetectionResult.fromJson(response.data['data']);
      } else {
        throw Exception('Erreur détection pays');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Erreur inattendue: ${e.toString()}');
    }
  }

  /// Vérifier si un pays supporte une fonctionnalité
  Future<CountrySupportResult> checkCountrySupport(
    String countryCode, 
    String feature
  ) async {
    try {
      final response = await _dio.get('/$countryCode/support/$feature');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return CountrySupportResult.fromJson(response.data['data']);
      } else {
        throw Exception('Erreur vérification support');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Erreur inattendue: ${e.toString()}');
    }
  }

  /// Obtenir les pays par phase de déploiement
  Future<List<CountryInfo>> getCountriesByPhase(String phase) async {
    try {
      final response = await _dio.get('/phases/$phase');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> countriesData = response.data['data'];
        return countriesData
            .map((countryJson) => CountryInfo.fromJson(countryJson))
            .toList();
      } else {
        throw Exception('Phase non trouvée');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Erreur inattendue: ${e.toString()}');
    }
  }

  /// Obtenir les opérateurs d'un pays
  Future<CountryOperatorsResult> getCountryOperators(
    String countryCode, {
    bool includeInactive = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (includeInactive) queryParams['includeInactive'] = 'true';
      
      final response = await _dio.get(
        '/$countryCode/operators',
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return CountryOperatorsResult.fromJson(response.data);
      } else {
        throw Exception('Erreur récupération opérateurs');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Erreur inattendue: ${e.toString()}');
    }
  }

  /// Obtenir les opérateurs supportés par un pays (endpoint simplifié)
  Future<Map<String, dynamic>> getSupportedOperators(String countryCode) async {
    try {
      final response = await _dio.get('/operators/$countryCode');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception('Pays non supporté');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Erreur inattendue: ${e.toString()}');
    }
  }

  /// Obtenir les données locales par défaut (fallback hors ligne)
  List<CountryInfo> getDefaultCountries() {
    return [
      CountryInfo(
        code: 'CI',
        name: 'Côte d\'Ivoire',
        callingCode: '+225',
        currency: 'CFA',
        status: 'active',
        priority: 1,
        operatorCount: 3,
        paymentOptions: 4,
        flagEmoji: '🇨🇮',
        languages: ['fr', 'en'],
        timeZone: 'GMT+0',
      ),
      CountryInfo(
        code: 'SN',
        name: 'Sénégal',
        callingCode: '+221',
        currency: 'CFA',
        status: 'active',
        priority: 2,
        operatorCount: 3,
        paymentOptions: 3,
        flagEmoji: '🇸🇳',
        languages: ['fr', 'wo'],
        timeZone: 'GMT+0',
      ),
      CountryInfo(
        code: 'ML',
        name: 'Mali',
        callingCode: '+223',
        currency: 'CFA',
        status: 'beta',
        priority: 3,
        operatorCount: 2,
        paymentOptions: 2,
        flagEmoji: '🇲🇱',
        languages: ['fr', 'bm'],
        timeZone: 'GMT+0',
      ),
      CountryInfo(
        code: 'BF',
        name: 'Burkina Faso',
        callingCode: '+226',
        currency: 'CFA',
        status: 'beta',
        priority: 4,
        operatorCount: 2,
        paymentOptions: 2,
        flagEmoji: '🇧🇫',
        languages: ['fr', 'mos'],
        timeZone: 'GMT+0',
      ),
      CountryInfo(
        code: 'GN',
        name: 'Guinée',
        callingCode: '+224',
        currency: 'GNF',
        status: 'beta',
        priority: 5,
        operatorCount: 2,
        paymentOptions: 2,
        flagEmoji: '🇬🇳',
        languages: ['fr'],
        timeZone: 'GMT+0',
      ),
    ];
  }

  /// Obtenir un pays depuis le cache local
  CountryInfo? getCountryFromCache(String countryCode) {
    try {
      return getDefaultCountries().firstWhere(
        (country) => country.code.toLowerCase() == countryCode.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Détection locale simple (fallback)
  CountryDetectionResult detectCountryLocally(String phoneNumber) {
    // Nettoyer le numéro
    final cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Détection basée sur les préfixes connus
    if (cleaned.startsWith('+225') || cleaned.startsWith('225')) {
      return CountryDetectionResult(
        countryCode: 'CI',
        countryName: 'Côte d\'Ivoire',
        callingCode: '+225',
        isSupported: true,
        supportLevel: 'active',
        confidence: 0.95,
      );
    } else if (cleaned.startsWith('+221') || cleaned.startsWith('221')) {
      return CountryDetectionResult(
        countryCode: 'SN',
        countryName: 'Sénégal',
        callingCode: '+221',
        isSupported: true,
        supportLevel: 'active',
        confidence: 0.95,
      );
    } else if (cleaned.startsWith('+223') || cleaned.startsWith('223')) {
      return CountryDetectionResult(
        countryCode: 'ML',
        countryName: 'Mali',
        callingCode: '+223',
        isSupported: true,
        supportLevel: 'beta',
        confidence: 0.90,
      );
    } else if (cleaned.startsWith('+226') || cleaned.startsWith('226')) {
      return CountryDetectionResult(
        countryCode: 'BF',
        countryName: 'Burkina Faso',
        callingCode: '+226',
        isSupported: true,
        supportLevel: 'beta',
        confidence: 0.90,
      );
    } else if (cleaned.startsWith('+224') || cleaned.startsWith('224')) {
      return CountryDetectionResult(
        countryCode: 'GN',
        countryName: 'Guinée',
        callingCode: '+224',
        isSupported: true,
        supportLevel: 'beta',
        confidence: 0.90,
      );
    }
    
    // Si aucun pays détecté, essayer de deviner
    if (cleaned.length >= 8) {
      // Probablement un numéro local ivoirien
      return CountryDetectionResult(
        countryCode: 'CI',
        countryName: 'Côte d\'Ivoire',
        callingCode: '+225',
        isSupported: true,
        supportLevel: 'active',
        confidence: 0.60,
      );
    }
    
    return CountryDetectionResult(
      countryCode: null,
      countryName: 'Inconnu',
      callingCode: null,
      isSupported: false,
      supportLevel: 'unsupported',
      confidence: 0.0,
    );
  }

  /// Gérer les erreurs Dio
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Délai de connexion dépassé';
      case DioExceptionType.receiveTimeout:
        return 'Délai de réception dépassé';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'];
        
        switch (statusCode) {
          case 404:
            return message ?? 'Ressource non trouvée';
          case 500:
            return 'Erreur serveur, réessayez plus tard';
          default:
            return message ?? 'Erreur réseau (Code: $statusCode)';
        }
      case DioExceptionType.cancel:
        return 'Requête annulée';
      case DioExceptionType.unknown:
        return 'Erreur de connexion réseau';
      default:
        return 'Erreur inattendue: ${e.message}';
    }
  }
}

/// Résultat de la détection de pays
class CountryDetectionResult {
  final String? countryCode;
  final String countryName;
  final String? callingCode;
  final bool isSupported;
  final String supportLevel;
  final double confidence;

  CountryDetectionResult({
    this.countryCode,
    required this.countryName,
    this.callingCode,
    required this.isSupported,
    required this.supportLevel,
    required this.confidence,
  });

  factory CountryDetectionResult.fromJson(Map<String, dynamic> json) {
    return CountryDetectionResult(
      countryCode: json['countryCode'],
      countryName: json['countryName'] ?? 'Unknown',
      callingCode: json['callingCode'],
      isSupported: json['isSupported'] ?? false,
      supportLevel: json['supportLevel'] ?? 'unsupported',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }
}

/// Résultat des opérateurs d'un pays
class CountryOperatorsResult {
  final CountryInfo country;
  final List<OperatorInfo> operators;
  final OperatorsSummary summary;

  CountryOperatorsResult({
    required this.country,
    required this.operators,
    required this.summary,
  });

  factory CountryOperatorsResult.fromJson(Map<String, dynamic> json) {
    return CountryOperatorsResult(
      country: CountryInfo.fromJson(json['country']),
      operators: (json['operators'] as List)
          .map((op) => OperatorInfo.fromJson(op))
          .toList(),
      summary: OperatorsSummary.fromJson(json['summary']),
    );
  }
}

/// Résumé des opérateurs
class OperatorsSummary {
  final int total;
  final int active;
  final int withApi;
  final double avgReliability;

  OperatorsSummary({
    required this.total,
    required this.active,
    required this.withApi,
    required this.avgReliability,
  });

  factory OperatorsSummary.fromJson(Map<String, dynamic> json) {
    return OperatorsSummary(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
      withApi: json['withApi'] ?? 0,
      avgReliability: (json['avgReliability'] ?? 0.0).toDouble(),
    );
  }
}
