import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chapechape_client/core/config/app_config.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class ApiService {
  late final Dio _dio;
  static ApiService? _instance;

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
      ),
    );
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

  // Méthodes HTTP génériques
  Future<Response> get(String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      // Assurer qu'il y a un slash entre l'URL de base et le chemin
      final sanitizedPath = path.startsWith('/') ? path : '/$path';
      
      final response = await _dio.get(
        sanitizedPath, 
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
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
      // Assurer qu'il y a un slash entre l'URL de base et le chemin
      final sanitizedPath = path.startsWith('/') ? path : '/$path';
      
      // Créer des options avec des en-têtes supplémentaires qui pourraient être nécessaires
      Options finalOptions = options ?? Options();
      finalOptions.headers = {
        ...?finalOptions.headers,
        'Accept': 'application/json',
        'User-Agent': 'ChapecapeApp/1.0',
        // Attention : Content-Length sera ajouté automatiquement par Dio
      };
      
      // Ajouter des logs détaillés pour déboguer
      debugPrint('---------- DÉTAILS COMPLETS DE LA REQUÊTE POST ----------');
      debugPrint('URL: ${AppConfig.apiUrl}$sanitizedPath');
      debugPrint('Données: $data');
      debugPrint('En-têtes: ${finalOptions.headers}');
      debugPrint('-------------------------------------------------------');
      
      final response = await _dio.post(
        sanitizedPath,
        data: data,
        queryParameters: queryParameters,
        options: finalOptions,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      
      // Ajouter des logs détaillés pour la réponse
      debugPrint('---------- DÉTAILS COMPLETS DE LA RÉPONSE ----------');
      debugPrint('Statut: ${response.statusCode}');
      debugPrint('En-têtes de réponse: ${response.headers.map}');
      debugPrint('Corps de réponse: ${response.data}');
      debugPrint('---------------------------------------------------');
      
      return response;
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
      // Assurer qu'il y a un slash entre l'URL de base et le chemin
      final sanitizedPath = path.startsWith('/') ? path : '/$path';
      
      final response = await _dio.put(
        sanitizedPath,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
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
      // Assurer qu'il y a un slash entre l'URL de base et le chemin
      final sanitizedPath = path.startsWith('/') ? path : '/$path';
      
      final response = await _dio.delete(
        sanitizedPath,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } catch (e) {
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
      // Assurer qu'il y a un slash entre l'URL de base et le chemin
      final sanitizedPath = path.startsWith('/') ? path : '/$path';
      
      final response = await _dio.patch(
        sanitizedPath,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}