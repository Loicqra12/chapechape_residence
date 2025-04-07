import 'dart:io';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chapechape_client/core/config/app_config.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class ApiService {
  late final Dio _dio;
  static ApiService? _instance;

  // Ajouter un getter pour accéder à l'URL de base
  String get baseUrl => _dio.options.baseUrl;

  ApiService._();

  static Future<ApiService> initialize() async {
    if (_instance != null) return _instance!;

    final instance = ApiService._();
    await instance._initialize();
    _instance = instance;
    return instance;
  }

  Future<void> _initialize() async {
    final apiUrl = AppConfig.apiUrl;
    final apiTimeout = 30000;
    
    debugPrint('Initialisation ApiService avec URL: $apiUrl');
    
    _dio = Dio(
      BaseOptions(
        baseUrl: apiUrl,
        connectTimeout: Duration(milliseconds: apiTimeout),
        receiveTimeout: Duration(milliseconds: apiTimeout ~/ 2),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) {
          return status != null && status < 500;
        },
      ),
    );

    // Configuration des intercepteurs
    _setupInterceptors();

    // Ajouter le logger pour le débogage
    if (!kIsWeb && (kDebugMode || kProfileMode)) {
      _dio.interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: true,
        error: true,
        compact: true,
      ));
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
  }

  // Configuration des intercepteurs
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Ajouter le token d'authentification à chaque requête si disponible
          const storage = FlutterSecureStorage();
          final token = await storage.read(key: 'token');
          
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            debugPrint('Token d\'authentification ajouté à la requête: ${options.path}');
          } else {
            debugPrint('⚠️ ATTENTION: Pas de token d\'authentification pour la requête: ${options.path}');
          }
          
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Si l'erreur est liée à une expiration de token, essayer de rafraîchir
          if (error.response?.statusCode == 401) {
            await _handleTokenExpiration();
          }
          
          // Pour certaines erreurs, mettre en place une tentative de retry
          if (_isRetryable(error)) {
            try {
              // Utiliser des options modifiées pour le retry
              final options = error.requestOptions;
              final response = await _dio.request(
                options.path,
                data: options.data,
                queryParameters: options.queryParameters,
                options: Options(
                  method: options.method,
                  headers: options.headers,
                ),
              );
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
          
          return handler.next(error);
        },
      ),
    );
  }

  // Vérifier si une erreur peut être réessayée
  bool _isRetryable(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
           e.type == DioExceptionType.sendTimeout ||
           e.type == DioExceptionType.receiveTimeout ||
           (e.response?.statusCode != null && 
            (e.response!.statusCode == 429 || 
             (e.response!.statusCode! >= 500 && e.response!.statusCode! < 600)));
  }

  Future<String?> _getToken() async {
    try {
      const storage = FlutterSecureStorage();
      return await storage.read(key: 'token');
    } catch (e) {
      debugPrint('Erreur lors de la récupération du token: $e');
      return null;
    }
  }

  Future<void> _handleTokenExpiration() async {
    // Implémenter la logique de rafraîchissement du token
    try {
      const storage = FlutterSecureStorage();
      await storage.delete(key: 'token');
      debugPrint('Token expiré supprimé');
    } catch (e) {
      debugPrint('Erreur lors de la suppression du token: $e');
    }
  }

  // Méthode générique pour les requêtes avec retry
  Future<Response> _retryRequest(
    Future<Response> Function() request, {
    int maxRetries = 3,
  }) async {
    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        return await request();
      } on DioException catch (e) {
        if (_isRetryable(e)) {
          retryCount++;
          if (retryCount == maxRetries) rethrow;
          
          // Backoff exponentiel: 500ms, 1s, 2s, 4s, etc.
          final delay = Duration(milliseconds: (math.pow(2, retryCount) * 500).toInt());
          debugPrint('Retry ${retryCount}/${maxRetries} pour la requête après ${delay.inMilliseconds}ms');
          await Future.delayed(delay);
          continue;
        }
        rethrow;
      }
    }
    throw Exception('Failed after $maxRetries retries');
  }

  // Méthodes HTTP génériques
  Future<Response> get(String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final sanitizedPath = path.startsWith('/') ? path : '/$path';
      return await _retryRequest(() => _dio.get(
        sanitizedPath, 
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ));
    } catch (e) {
      debugPrint('Erreur dans la requête GET: $e');
      rethrow;
    }
  }

  Future<Response> post(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final sanitizedPath = path.startsWith('/') ? path : '/$path';
      
      Options finalOptions = options ?? Options();
      finalOptions.headers = {
        ...?finalOptions.headers,
        'Accept': 'application/json',
        'User-Agent': 'ChapecapeApp/1.0',
      };
      
      debugPrint('---------- DÉTAILS COMPLETS DE LA REQUÊTE POST ----------');
      debugPrint('URL: ${AppConfig.apiUrl}$sanitizedPath');
      debugPrint('Données: $data');
      debugPrint('En-têtes: ${finalOptions.headers}');
      debugPrint('-------------------------------------------------------');
      
      return await _retryRequest(() => _dio.post(
        sanitizedPath,
        data: data,
        queryParameters: queryParameters,
        options: finalOptions,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ));
    } catch (e) {
      debugPrint('Erreur dans la requête POST: $e');
      rethrow;
    }
  }

  Future<Response> put(String path, {
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
      debugPrint('Erreur dans la requête PUT: $e');
      rethrow;
    }
  }

  Future<Response> delete(String path, {
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
      debugPrint('Erreur dans la requête DELETE: $e');
      rethrow;
    }
  }

  Future<Response> patch(String path, {
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
      debugPrint('Erreur dans la requête PATCH: $e');
      rethrow;
    }
  }
}