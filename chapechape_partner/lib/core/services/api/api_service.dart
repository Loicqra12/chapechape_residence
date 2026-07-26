import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chapechape_partner/core/utils/secure_storage.dart';
import 'package:chapechape_partner/core/utils/app_logger.dart';
import '../../config/app_config.dart';
import './interceptors/auth_interceptor.dart';
import './interceptors/image_url_interceptor.dart';
import './interceptors/retry_interceptor.dart';
import '../../utils/error_handler.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';

class ApiService {
  late final Dio _dio;
  final _storage = AppSecureStorage.instance;
  final String _baseUrl = AppConfig.apiUrl;
  
  // Clés de stockage des tokens
  static const String _accessTokenKey = AppSecureStorage.tokenKey;
  static const String _refreshTokenKey = AppSecureStorage.refreshTokenKey;
  static const String _tokenExpiryKey = AppSecureStorage.tokenExpiryKey;
  
  // Variables pour le refresh token
  static bool _isRefreshing = false;
  static Completer<String?>? _refreshCompleter;
  
  final AuthBloc? authBloc;

  ApiService({this.authBloc}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'x-mobile-app': 'true',  // Permet de contourner la protection CSRF pour les apps mobiles
        },
        validateStatus: (status) {
          return status != null && status < 500;
        },
        connectTimeout: const Duration(seconds: 120),
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 120),
        followRedirects: true,
        maxRedirects: 5,
      ),
    );

    // Ajouter l'intercepteur d'URL d'images pour corriger les chemins d'images problématiques
    _dio.interceptors.add(ImageUrlInterceptor());

    // Ajouter l'intercepteur de retry avec délai exponentiel pour gérer les erreurs 429 et réseau
    _dio.interceptors.add(RetryInterceptor(
      dio: _dio,
      maxRetries: 3,
      initialDelay: const Duration(milliseconds: 500),
      backoffFactor: 2.0,
      maxDelay: const Duration(seconds: 15),
    ));

    // Ajouter l'intercepteur d'authentification
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Vérifier et ajouter le token d'accès s'il existe
          if (await _shouldRefreshToken()) {
            // Token expiré, besoin de le rafraîchir avant de continuer
            final refreshResult = await _refreshToken();
            if (refreshResult) {
              final newToken = await _storage.read(key: _accessTokenKey);
              if (newToken != null) {
                options.headers['Authorization'] = 'Bearer $newToken';
                AppLogger.d('🔄 Token rafraîchi et ajouté à la requête');
              }
            } else {
              // Échec du rafraîchissement, déconnexion
              if (authBloc != null) {
                authBloc?.add(AuthLogoutRequested());
              }
            }
          } else {
            // Utiliser le token actuel s'il existe
            final token = await _storage.read(key: _accessTokenKey);
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
              
              // Log sécurisé du token
              final maskedToken = _maskToken(token);
              AppLogger.d('🔐 Token ajouté à la requête: $maskedToken');
            }
          }
          
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Si l'erreur est 401 (token expiré), essayer de rafraîchir
          if (error.response?.statusCode == 401) {
            AppLogger.d('🔑 Erreur 401 détectée, tentative de rafraîchissement du token');
            
            // Vérifier si nous sommes déjà en train de rafraîchir
            if (!_isRefreshing) {
              final success = await _refreshToken();
              
              if (success) {
                // Réessayer la requête avec le nouveau token
                final token = await _storage.read(key: _accessTokenKey);
                error.requestOptions.headers['Authorization'] = 'Bearer $token';
                
                try {
                  AppLogger.d('🔄 Réessai de la requête avec le nouveau token');
                  final response = await _dio.fetch(error.requestOptions);
                  return handler.resolve(response);
                } catch (e) {
                  return handler.next(DioException(
                    requestOptions: error.requestOptions,
                    error: 'Échec de la requête après rafraîchissement du token: $e',
                  ));
                }
              } else {
                // Si le rafraîchissement a échoué, déconnexion
                if (authBloc != null) {
                  authBloc?.add(AuthLogoutRequested());
                }
              }
            } else {
              // Attendre que le rafraîchissement en cours soit terminé
              try {
                await _refreshCompleter?.future;
                // Réessayer la requête
                final token = await _storage.read(key: _accessTokenKey);
                error.requestOptions.headers['Authorization'] = 'Bearer $token';
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }
          } 
          // Gestion des erreurs 429 (Too Many Requests)
          else if (error.response?.statusCode == 429) {
            if (_rateLimitRetries < _maxRateLimitRetries) {
              _rateLimitRetries++;
              
              // Calculer le délai avec un backoff exponentiel
              final backoffDelay = Duration(
                seconds: _initialBackoffDelay.inSeconds * (1 << (_rateLimitRetries - 1))
              );
              final delayToUse = backoffDelay > _maxBackoffDelay ? _maxBackoffDelay : backoffDelay;
              
              debugPrint('⚠️ Rate limiting (429) détecté - Attente de ${delayToUse.inSeconds}s avant nouvelle tentative (${_rateLimitRetries}/${_maxRateLimitRetries})');
              
              // Attendre avant de réessayer
              await Future.delayed(delayToUse);
              
              try {
                // Réessayer la requête
                final response = await _dio.fetch(error.requestOptions);
                // Réinitialiser le compteur en cas de succès
                _rateLimitRetries = 0;
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            } else {
              debugPrint('❌ Rate limiting - Nombre maximum de tentatives atteint (${_maxRateLimitRetries})');
              _rateLimitRetries = 0;
              return handler.next(error);
            }
          }
          
          return handler.next(error);
        },
      ),
    );

    // Logger debug sans headers (évite de dump le JWT Bearer en clair)
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          compact: true,
        ),
      );
    }
  }
  
  // Configuration pour la gestion des limites de taux (rate limiting)
  int _rateLimitRetries = 0;
  static const int _maxRateLimitRetries = 3;
  static const Duration _initialBackoffDelay = Duration(seconds: 2);
  static const Duration _maxBackoffDelay = Duration(seconds: 30);
  static const Duration _requestDelayDuration = Duration(milliseconds: 500);
  DateTime _lastRequestTime = DateTime.now().subtract(const Duration(seconds: 1));

  // Méthode pour respecter un délai entre les requêtes
  Future<void> _respectRequestDelay() async {
    final now = DateTime.now();
    final timeSinceLastRequest = now.difference(_lastRequestTime);
    
    if (timeSinceLastRequest < _requestDelayDuration) {
      final waitTime = _requestDelayDuration - timeSinceLastRequest;
      debugPrint('⏱️ Attente de ${waitTime.inMilliseconds}ms entre les requêtes pour éviter le rate limiting');
      await Future.delayed(waitTime);
    }
    
    _lastRequestTime = DateTime.now();
  }
  
  // Vérifier si le token a besoin d'être rafraîchi
  Future<bool> _shouldRefreshToken() async {
    final expiryStr = await _storage.read(key: _tokenExpiryKey);
    if (expiryStr == null) return false;
    
    try {
      final expiry = DateTime.parse(expiryStr);
      final now = DateTime.now();
      
      // Rafraîchir si le token expire dans moins de 5 minutes
      return now.isAfter(expiry.subtract(const Duration(minutes: 5)));
    } catch (e) {
      AppLogger.d('❌ Erreur lors de la vérification de l\'expiration du token: $e');
      return false;
    }
  }
  
  // Rafraîchir le token d'accès
  Future<bool> _refreshToken() async {
    // Si un rafraîchissement est déjà en cours, attendre sa fin
    if (_isRefreshing) {
      final newToken = await _refreshCompleter?.future;
      // Retourner false si le refresh a échoué (token null)
      return newToken != null;
    }
    
    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();
    
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null) {
        _isRefreshing = false;
        _refreshCompleter?.complete(null);
        return false;
      }
      
      AppLogger.d('🔄 Début du rafraîchissement du token...');
      
      final response = await _dio.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: {'Authorization': null}, // Ne pas inclure de token ici
        ),
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final newAccessToken = response.data['accessToken'];
        final newRefreshToken = response.data['refreshToken'];
        
        // Calculer la date d'expiration (par défaut: maintenant + 24h)
        final expiry = DateTime.now().add(const Duration(hours: 24));
        
        // Stocker les nouveaux tokens
        await _storage.write(key: _accessTokenKey, value: newAccessToken);
        await _storage.write(key: _refreshTokenKey, value: newRefreshToken);
        await _storage.write(key: _tokenExpiryKey, value: expiry.toIso8601String());
        
        AppLogger.d('✅ Token rafraîchi avec succès');
        
        _isRefreshing = false;
        _refreshCompleter?.complete(newAccessToken);
        return true;
      } else {
        AppLogger.d('❌ Échec du rafraîchissement du token: ${response.statusCode}');
        _isRefreshing = false;
        _refreshCompleter?.complete(null);
        return false;
      }
    } catch (e) {
      AppLogger.d('❌ Exception lors du rafraîchissement du token: $e');
      _isRefreshing = false;
      _refreshCompleter?.completeError(e);
      return false;
    }
  }
  
  // Masquer le token pour les logs (sécurité)
  String _maskToken(String token) {
    if (token.length <= 8) return '****';
    return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
  }
  
  // Stocker les tokens après la connexion ou l'inscription
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final expiry = DateTime.now().add(const Duration(hours: 24));
    
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _tokenExpiryKey, value: expiry.toIso8601String());
    
    AppLogger.d('📝 Tokens enregistrés (expire le ${expiry.toLocal()})');
  }

  Future<String?> getToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<void> removeToken() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _tokenExpiryKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _tokenExpiryKey);
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

  // Méthodes HTTP avec gestion d'erreur améliorée

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    await _respectRequestDelay();
    try {
      final response = await _retryRequest(() => _dio.get(path, queryParameters: queryParameters));
      _validateResponse(response);
      return response;
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    await _respectRequestDelay();
    try {
      final response = await _retryRequest(() => _dio.post(path, data: data, queryParameters: queryParameters));
      _validateResponse(response);
      return response;
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    await _respectRequestDelay();
    try {
      final response = await _retryRequest(() => _dio.put(path, data: data, queryParameters: queryParameters));
      _validateResponse(response);
      return response;
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    await _respectRequestDelay();
    try {
      final response = await _retryRequest(() => _dio.patch(path, data: data, queryParameters: queryParameters));
      _validateResponse(response);
      return response;
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    await _respectRequestDelay();
    try {
      final response = await _retryRequest(() => _dio.delete(path, data: data, queryParameters: queryParameters));
      _validateResponse(response);
      return response;
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
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
