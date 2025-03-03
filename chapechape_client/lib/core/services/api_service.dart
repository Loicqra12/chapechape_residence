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

    // Ajouter l'intercepteur pour le token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Récupérer le token depuis le storage
          const storage = FlutterSecureStorage();
          final token = await storage.read(key: 'token');
          
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          return handler.next(options);
        },
      ),
    );

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
      // Ne pas ajouter /api car c'est déjà dans l'URL de base
      final response = await _dio.get(
        path, 
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
      // Ajouter des logs pour déboguer
      debugPrint('POST request to: ${AppConfig.apiUrl}/$path');
      debugPrint('Data: $data');
      
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      
      // Ajouter des logs pour déboguer
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');
      
      return response;
    } catch (e) {
      debugPrint('Error in POST request: $e');
      rethrow;
    }
  }

  Future<Response> put(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      // Ne pas ajouter /api car c'est déjà dans l'URL de base
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
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
  }) async {
    try {
      // Ne pas ajouter /api car c'est déjà dans l'URL de base
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> patch(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      // Ne pas ajouter /api car c'est déjà dans l'URL de base
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}