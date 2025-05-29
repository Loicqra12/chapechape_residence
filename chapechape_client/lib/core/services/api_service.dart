import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chapechape_client/core/config/app_config.dart';
import 'package:chapechape_client/core/errors/api_error.dart';
import 'package:chapechape_client/core/models/api_response.dart';
import 'package:chapechape_client/core/services/api/interceptors/auth_interceptor.dart';
import 'package:chapechape_client/core/services/api/interceptors/csrf_interceptor.dart';
import 'package:chapechape_client/core/services/api/interceptors/logging_interceptor.dart';
import 'package:chapechape_client/core/services/api/interceptors/retry_interceptor.dart';
import 'package:chapechape_client/core/services/cache_service.dart';
import 'package:chapechape_client/core/services/connectivity_service.dart';
import 'package:chapechape_client/core/services/logger_service.dart';

/// Service d'accès à l'API
class ApiService {
  static ApiService? _instance;
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final CacheService _cacheService = CacheService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final LoggerService _logger = LoggerService();
  
  bool _isConnected = true;
  
  /// URL de base de l'API
  String get baseUrl => _dio.options.baseUrl;
  
  ApiService._();
  
  static Future<ApiService> initialize() async {
    if (_instance != null) {
      return _instance!;
    }
    
    final instance = ApiService._();
    await instance._initialize();
    _instance = instance;
    return instance;
  }
  
  Future<void> _initialize() async {
    _logger.info('Initialisation du service API');
    
    // Initialisation de Dio
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));
    
    // Ajouter les intercepteurs dans le bon ordre
    
    // 1. L'intercepteur de logging pour déboguer les requêtes/réponses
    _dio.interceptors.add(LoggingInterceptor.create(isProduction: AppConfig.isProduction));
    
    // 2. Ajouter l'intercepteur de retry (doit être avant l'auth pour gérer les erreurs d'authentification)
    _dio.interceptors.add(RetryInterceptor(
      dio: _dio,
      maxRetries: 3,
      initialDelay: const Duration(milliseconds: 500),
      maxDelay: const Duration(seconds: 30),
      // Inclure le 401 pour réessayer avec un token rafraîchi
      retryStatusCodes: [401, 408, 429, 500, 502, 503, 504],
    ));
    
    // 3. Ajouter l'intercepteur d'authentification
    _dio.interceptors.add(AuthInterceptor(
      dio: _dio,
      storage: _storage,
    ));
    
    // 4. Ajouter l'intercepteur CSRF pour la protection contre les attaques CSRF
    _dio.interceptors.add(CsrfInterceptor());
    
    // Configurer les certificats pour les environnements de développement
    if (!kIsWeb && !AppConfig.isProduction) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        // Désactiver la vérification des certificats en développement uniquement
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }
    
    // Configuration du proxy si spécifié
    final String? proxyUrl = AppConfig.proxyUrl;
    if (!kIsWeb && proxyUrl != null && proxyUrl.isNotEmpty) {
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.findProxy = (uri) => 'PROXY $proxyUrl';
          return client;
        },
      );
    }
    
    // Vérifier l'état de la connectivité initial et s'abonner aux changements
    _connectivityService.connectivityStream.listen((isConnected) {
      _isConnected = isConnected;
      _logger.info('État de connexion changé: ${_isConnected ? 'Connecté' : 'Déconnecté'}');
      
      // Si la connexion est rétablie, traiter la file d'attente hors ligne
      if (_isConnected) {
        _processOfflineQueue();
      }
    });
    
    // Vérifier l'état de connectivité initial
    _isConnected = await _connectivityService.checkConnectivity();
    _logger.info('🌍 État de connexion initial: ${_isConnected ? 'Connecté' : 'Déconnecté'}');
    
    _logger.info('✅ Service API initialisé avec succès');
  }
  
  // File d'attente pour les requêtes en mode hors ligne
  final List<Map<String, dynamic>> _offlineQueue = [];
  
  // Gérer une requête en mode hors ligne
  Future<void> _handleOfflineRequest(
    String method,
    String path,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  ) async {
    _logger.info('📱 Mode hors ligne: Mise en file d\'attente de la requête $method $path');
    
    // Ajouter la requête à la file d'attente
    _offlineQueue.add({
      'method': method,
      'path': path,
      'data': data,
      'queryParameters': queryParameters,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Sauvegarder la file d'attente pour la persistance
    await _cacheService.put('offline_queue', _offlineQueue);
    
    // Afficher une notification à l'utilisateur
    // Vous pouvez utiliser un service de notification ici
    _logger.info('📝 Requête enregistrée pour synchronisation future');
  }
  
  // Traiter la file d'attente des requêtes hors ligne lorsque la connexion est rétablie
  Future<void> _processOfflineQueue() async {
    _logger.info('🔄 Traitement de la file d\'attente hors ligne (${_offlineQueue.length} requêtes)');
    
    // Récupérer les requêtes sauvegardées si la file d'attente est vide
    if (_offlineQueue.isEmpty) {
      final savedQueue = await _cacheService.get('offline_queue');
      if (savedQueue != null && savedQueue is List) {
        for (final item in savedQueue) {
          _offlineQueue.add(Map<String, dynamic>.from(item));
        }
      }
    }
    
    if (_offlineQueue.isEmpty) {
      _logger.info('✅ Aucune requête en attente à synchroniser');
      return;
    }
    
    // Traiter les requêtes par ordre chronologique
    _offlineQueue.sort((a, b) => 
      (a['timestamp'] as int).compareTo(b['timestamp'] as int));
    
    // Créer une copie de la file d'attente pour itération
    final queueCopy = List<Map<String, dynamic>>.from(_offlineQueue);
    
    for (final request in queueCopy) {
      try {
        final method = request['method'] as String;
        final path = request['path'] as String;
        final data = request['data'] as Map<String, dynamic>?;
        final queryParameters = request['queryParameters'] as Map<String, dynamic>?;
        
        _logger.info('🔄 Synchronisation de la requête $method $path');
        
        // Exécuter la requête
        switch (method.toUpperCase()) {
          case 'GET':
            await _dio.get(path, queryParameters: queryParameters);
            break;
          case 'POST':
            await _dio.post(path, data: data, queryParameters: queryParameters);
            break;
          case 'PUT':
            await _dio.put(path, data: data, queryParameters: queryParameters);
            break;
          case 'DELETE':
            await _dio.delete(path, data: data, queryParameters: queryParameters);
            break;
          default:
            _logger.warning('⚠️ Méthode HTTP non prise en charge: $method');
        }
        
        // Si la requête réussit, la retirer de la file d'attente
        _offlineQueue.remove(request);
        _logger.info('✅ Requête $method $path synchronisée avec succès');
      } catch (e) {
        _logger.error('❌ Échec de la synchronisation: $e');
        // Laisser la requête dans la file d'attente pour une tentative ultérieure
      }
    }
    
    // Mettre à jour la file d'attente persistante
    await _cacheService.put('offline_queue', _offlineQueue);
    
    if (_offlineQueue.isEmpty) {
      _logger.info('✅ Toutes les requêtes ont été synchronisées');
    } else {
      _logger.warning('⚠️ ${_offlineQueue.length} requêtes restent à synchroniser');
    }
  }
  
  /// Synchronise les données mises en cache pendant que l'appareil était hors ligne
  /// Cette méthode publique peut être appelée lorsque la connexion est rétablie
  Future<bool> synchronizeOfflineData() async {
    try {
      // Vérifier si nous sommes connectés
      if (!_isConnected) {
        debugPrint('❌ Impossible de synchroniser: appareil toujours hors ligne');
        return false;
      }
      
      // Traiter la file d'attente des requêtes hors ligne
      await _processOfflineQueue();
      
      // Marquer comme synchronisé
      debugPrint('✅ Synchronisation terminée avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la synchronisation: $e');
      return false;
    }
  }
  
  /// Gestion standardisée des erreurs
  Exception handleError(dynamic error) {
    if (error is DioException) {
      // Vérifier s'il s'agit d'une erreur de connectivité
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        debugPrint('🔌 Erreur de connectivité détectée');
        
        // Si nous avons déjà détecté que nous sommes hors ligne, utiliser le cache
        if (!_isConnected) {
          return ApiError(
            message: 'Vous êtes actuellement hors ligne. L\'application fonctionne en mode limité.',
            statusCode: 0,
            errorCode: 'OFFLINE_MODE',
          );
        }
      }
      return ApiError.fromDioError(error);
    } else if (error is ApiError) {
      return error;
    }
    return ApiError.generic(message: error?.toString() ?? 'Une erreur inconnue est survenue');
  }

  /// Tente de rafraîchir le token d'accès
  /// Cette méthode est désormais une façade qui délègue à l'AuthInterceptor pour maintenir la compatibilité
  Future<bool> _refreshToken() async {
    try {
      // Cette opération est désormais gérée par l'intercepteur
      // Cette méthode est conservée pour maintenir la compatibilité
      debugPrint('_refreshToken est déprécié, utilisez plutôt l\'AuthInterceptor');
      
      // On obtient l'intercepteur depuis les intercepteurs enregistrés
      final authInterceptor = _dio.interceptors.whereType<AuthInterceptor>().firstOrNull;
      if (authInterceptor != null) {
        return await authInterceptor.refreshToken();
      }
      
      // Si l'intercepteur n'est pas trouvé, retourner false
      return false;
    } catch (e) {
      debugPrint('Erreur lors du rafraîchissement du token: $e');
      return false;
    }
  }
  
  /// Méthode privée pour la logique de retry
  Future<Response> _retryRequest(Future<Response> Function() requestFunction) async {
    const maxRetries = 3;
    const initialDelayMs = 1000;
    
    int attempts = 0;
    
    while (true) {
      try {
        // Tentative d'exécution de la requête
        return await requestFunction();
      } catch (e) {
        attempts++;
        
        if (attempts >= maxRetries) {
          // Si le nombre maximum de tentatives est atteint, propager l'erreur
          rethrow;
        }
        
        // Délai exponentiel avec un peu d'aléatoire (jitter)
        final delay = initialDelayMs * math.pow(2, attempts - 1);
        final jitter = math.Random().nextInt((delay * 0.1).toInt());
        final totalDelay = delay + jitter;
        
        debugPrint('Tentative $attempts a échoué, nouvel essai dans ${totalDelay}ms');
        await Future.delayed(Duration(milliseconds: totalDelay.toInt()));
      }
    }
  }

  // Méthodes HTTP avec gestion standardisée
  Future<ApiResponse<T>> getData<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    T Function(dynamic)? fromJson,
    bool useCacheIfOffline = true,
  }) async {
    try {
      final sanitizedPath = path.startsWith('/') ? path : '/$path';
      
      // Vérifier si nous sommes hors ligne et utiliser le cache si demandé
      if (!_isConnected && useCacheIfOffline) {
        final cachedData = await _cacheService.get('GET_$sanitizedPath');
        if (cachedData != null) {
          debugPrint('📦 Utilisation des données en cache pour $sanitizedPath');
          
          if (fromJson != null) {
            final data = fromJson(cachedData);
            return ApiResponse.success(data, isFromCache: true);
          }
          return ApiResponse.success(cachedData as T, isFromCache: true);
        }
      }
      
      final response = await _retryRequest(() => _dio.get(
        sanitizedPath,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      ));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Mise en cache des données pour utilisation hors ligne
        if (useCacheIfOffline) {
          await _cacheService.put('GET_$sanitizedPath', response.data);
        }
        
        if (fromJson != null) {
          final data = fromJson(response.data);
          return ApiResponse.success(data);
        }
        return ApiResponse.success(response.data as T);
      }
      
      return ApiResponse.error(
        'Erreur avec le code: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Erreur dans la requête GET: $e');
      final error = handleError(e);
      if (error is ApiError) {
        return ApiResponse.error(
          error.message,
          statusCode: error.statusCode,
          isNetworkError: error.errorCode == 'NETWORK_ERROR' || error.errorCode == 'OFFLINE_MODE',
          isAuthError: error.statusCode == 401,
        );
      }
      return ApiResponse.error(error.toString());
    }
  }

  Future<ApiResponse<T>> postData<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final sanitizedPath = path.startsWith('/') ? path : '/$path';
      
      // Si hors ligne, mettre en file d'attente la requête
      if (!_isConnected) {
        await _handleOfflineRequest('POST', sanitizedPath, data as Map<String, dynamic>?, queryParameters);
        return ApiResponse.error(
          'Vous êtes hors ligne. La requête sera exécutée lorsque la connexion sera rétablie.',
          statusCode: 0,
          isNetworkError: true,
          isQueuedForSync: true,
        );
      }
      
      final response = await _retryRequest(() => _dio.post(
        sanitizedPath,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (fromJson != null) {
          final responseData = fromJson(response.data);
          return ApiResponse.success(responseData);
        }
        return ApiResponse.success(response.data as T);
      }
      
      return ApiResponse.error(
        'Erreur avec le code: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Erreur dans la requête POST: $e');
      final error = handleError(e);
      if (error is ApiError) {
        return ApiResponse.error(
          error.message,
          statusCode: error.statusCode,
          isNetworkError: error.errorCode == 'NETWORK_ERROR' || error.errorCode == 'OFFLINE_MODE',
          isAuthError: error.statusCode == 401,
        );
      }
      return ApiResponse.error(error.toString());
    }
  }

  Future<ApiResponse<T>> putData<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final sanitizedPath = path.startsWith('/') ? path : '/$path';
      
      final response = await _retryRequest(() => _dio.put(
        sanitizedPath,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (fromJson != null && response.data != null) {
          final parsedData = fromJson(response.data);
          return ApiResponse.success(parsedData);
        }
        return ApiResponse.success(response.data as T);
      }
      
      return ApiResponse.error(
        'Erreur avec le code: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Erreur dans la requête PUT: $e');
      final error = handleError(e);
      if (error is ApiError) {
        return ApiResponse.error(
          error.message,
          statusCode: error.statusCode,
          isNetworkError: error.errorCode == 'NETWORK_ERROR',
          isAuthError: error.statusCode == 401,
        );
      }
      return ApiResponse.error(e.toString());
    }
  }



  Future<ApiResponse<T>> deleteData<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final sanitizedPath = path.startsWith('/') ? path : '/$path';
      
      final response = await _retryRequest(() => _dio.delete(
        sanitizedPath,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ));
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (fromJson != null && response.data != null) {
          final parsedData = fromJson(response.data);
          return ApiResponse.success(parsedData);
        }
        return ApiResponse.success(response.data as T);
      }
      
      return ApiResponse.error(
        'Erreur avec le code: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Erreur dans la requête DELETE: $e');
      final error = handleError(e);
      if (error is ApiError) {
        return ApiResponse.error(
          error.message,
          statusCode: error.statusCode,
          isNetworkError: error.errorCode == 'NETWORK_ERROR',
          isAuthError: error.statusCode == 401,
        );
      }
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<T>> patchData<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final sanitizedPath = path.startsWith('/') ? path : '/$path';
      
      final response = await _retryRequest(() => _dio.patch(
        sanitizedPath,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (fromJson != null && response.data != null) {
          final parsedData = fromJson(response.data);
          return ApiResponse.success(parsedData);
        }
        return ApiResponse.success(response.data as T);
      }
      
      return ApiResponse.error(
        'Erreur avec le code: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Erreur dans la requête PATCH: $e');
      final error = handleError(e);
      if (error is ApiError) {
        return ApiResponse.error(
          error.message,
          statusCode: error.statusCode,
          isNetworkError: error.errorCode == 'NETWORK_ERROR',
          isAuthError: error.statusCode == 401,
        );
      }
      return ApiResponse.error(e.toString());
    }
  }

  // Méthode raccourcie pour les requêtes PATCH
  Future<dynamic> patchSimple(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final response = await patchData<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
    
    if (response.isSuccess) {
      return response.data;
    } else {
      throw Exception(response.message ?? 'Erreur inconnue');
    }
  }

  // Méthodes de compatibilité avec l'ancien code
  // Ces méthodes sont conservées pour la compatibilité avec le code existant
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final sanitizedPath = path.startsWith('/') ? path : '/$path';
      
      return await _retryRequest(() => _dio.get(
        sanitizedPath,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      ));
    } catch (e) {
      debugPrint('Erreur dans la requête GET (méthode de compatibilité): $e');
      throw handleError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final sanitizedPath = path.startsWith('/') ? path : '/$path';
      
      return await _retryRequest(() => _dio.post(
        sanitizedPath,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ));
    } catch (e) {
      debugPrint('Erreur dans la requête POST (méthode de compatibilité): $e');
      throw handleError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final sanitizedPath = path.startsWith('/') ? path : '/$path';
      
      return await _retryRequest(() => _dio.put(
        sanitizedPath,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ));
    } catch (e) {
      debugPrint('Erreur dans la requête PUT (méthode de compatibilité): $e');
      throw handleError(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final sanitizedPath = path.startsWith('/') ? path : '/$path';
      
      return await _retryRequest(() => _dio.delete(
        sanitizedPath,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ));
    } catch (e) {
      debugPrint('Erreur dans la requête DELETE (méthode de compatibilité): $e');
      throw handleError(e);
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final sanitizedPath = path.startsWith('/') ? path : '/$path';
      
      return await _retryRequest(() => _dio.patch(
        sanitizedPath,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ));
    } catch (e) {
      debugPrint('Erreur dans la requête PATCH (méthode de compatibilité): $e');
      throw handleError(e);
    }
  }
  
  // Ajout de la méthode getAuthenticatedImageUrl pour la compatibilité
  String getAuthenticatedImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    
    final sanitizedPath = path.startsWith('/') ? path.substring(1) : path;
    final mediaBaseUrl = AppConfig.apiBaseUrl;
    return '$mediaBaseUrl/media/$sanitizedPath';
  }
}