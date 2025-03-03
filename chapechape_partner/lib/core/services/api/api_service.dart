import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../../config/app_config.dart';

class ApiService {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  final String _baseUrl = AppConfig.apiUrl;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) {
          return status != null && status < 500;
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        followRedirects: true,
        maxRedirects: 5,
      ),
    );

    // Ajouter l'intercepteur pour le token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Ajouter le token s'il existe
          final token = await _storage.read(key: 'token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            // Retry the request
            try {
              final response = await _dio.request(
                error.requestOptions.path,
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
                options: Options(
                  method: error.requestOptions.method,
                  headers: error.requestOptions.headers,
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

    // Ajouter le logger en mode debug
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
        compact: true,
      ),
    );
  }

  Future<String?> getToken() async {
    return _storage.read(key: 'token');
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  Future<void> removeToken() async {
    await _storage.delete(key: 'token');
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'token');
  }

  Dio get dio => _dio;

  // Méthodes d'aide pour les requêtes HTTP avec retry
  Future<Response> _retryRequest(Future<Response> Function() request, {int maxRetries = 3}) async {
    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        return await request();
      } on DioException catch (e) {
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          retryCount++;
          if (retryCount == maxRetries) rethrow;
          await Future.delayed(Duration(seconds: retryCount * 2));
          continue;
        }
        rethrow;
      }
    }
    throw Exception('Failed after $maxRetries retries');
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _retryRequest(() => _dio.get(path, queryParameters: queryParameters));
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) {
    return _retryRequest(() => _dio.post(path, data: data, queryParameters: queryParameters));
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) {
    return _retryRequest(() => _dio.put(path, data: data, queryParameters: queryParameters));
  }

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters}) {
    return _retryRequest(() => _dio.patch(path, data: data, queryParameters: queryParameters));
  }

  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters}) {
    return _retryRequest(() => _dio.delete(path, data: data, queryParameters: queryParameters));
  }

  void _validateResponse(Response response) {
    if (response.statusCode == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Pas de réponse du serveur',
      );
    }

    if (response.statusCode! >= 400) {
      String message = 'Une erreur est survenue';
      
      if (response.data != null && response.data['message'] != null) {
        message = response.data['message'];
      } else if (response.statusCode == 401) {
        message = 'Non autorisé';
      } else if (response.statusCode == 403) {
        message = 'Accès refusé';
      } else if (response.statusCode == 404) {
        message = 'Ressource non trouvée';
      } else if (response.statusCode == 500) {
        message = 'Erreur serveur';
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: message,
      );
    }
  }
}
