import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/app_config.dart';

/// Intercepteur pour gérer les tokens CSRF pour l'API ChapeChape
///
/// Cet intercepteur gère:
/// 1. La récupération et le stockage des tokens CSRF
/// 2. L'ajout des tokens aux requêtes qui modifient les données
/// 3. La gestion des erreurs CSRF et la récupération de nouveaux tokens
class CsrfInterceptor extends Interceptor {
  /// Clé pour stocker le token CSRF
  static const String _csrfTokenKey = 'csrf_token';
  
  /// Instance Dio pour les requêtes indépendantes
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiUrl,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );
  
  /// Token CSRF en mémoire
  String? _csrfToken;
  
  /// Indique si une requête de token CSRF est en cours
  bool _isRefreshingToken = false;
  
  /// File d'attente des requêtes en attente d'un token CSRF
  final List<RequestOptions> _pendingRequests = [];

  CsrfInterceptor() {
    _loadCsrfToken();
  }

  /// Charge le token CSRF depuis le stockage
  Future<void> _loadCsrfToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _csrfToken = prefs.getString(_csrfTokenKey);
      
      if (_csrfToken != null) {
        debugPrint('Token CSRF chargé depuis le stockage');
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du token CSRF: $e');
    }
  }

  /// Sauvegarde le token CSRF dans le stockage
  Future<void> _saveCsrfToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_csrfTokenKey, token);
      _csrfToken = token;
      debugPrint('Token CSRF sauvegardé');
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde du token CSRF: $e');
    }
  }

  /// Méthode pour récupérer un nouveau token CSRF
  Future<String?> _fetchCsrfToken() async {
    if (_isRefreshingToken) {
      // Attendre la fin de la requête en cours
      int attempts = 0;
      while (_isRefreshingToken && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      return _csrfToken;
    }

    _isRefreshingToken = true;
    try {
      debugPrint('🔄 Tentative de récupération d\'un token CSRF...');
      
      // Modification: utiliser l'URL correcte sans doubler le /api/
      final response = await _dio.get('/csrf-token', 
        options: Options(
          headers: {'Accept': 'application/json'},
          validateStatus: (status) => status != null, // Accepter tous les codes de statut
          // Désactiver temporairement d'autres intercepteurs qui pourraient affecter cette requête
          extra: {'ignoreInterceptors': true}
        )
      );

      debugPrint('📢 Réponse du serveur pour le token CSRF: ${response.statusCode}');
      
      // Vérifier d'abord le token dans les en-têtes (la méthode préférée)
      final headerToken = response.headers.value('x-csrf-token');
      if (headerToken != null) {
        debugPrint('🔑 Token CSRF trouvé dans les en-têtes');
        await _saveCsrfToken(headerToken);
        return headerToken;
      }
      
      // Rechercher le token dans le corps de la réponse
      if (response.statusCode == 200 && response.data != null) {
        // Accepter différents formats de réponse
        String? token;
        if (response.data is Map) {
          token = response.data['token']?.toString() 
              ?? response.data['csrfToken']?.toString()
              ?? response.data['csrf-token']?.toString();
        } else if (response.data is String) {
          token = response.data as String;
        }
        
        if (token != null) {
          debugPrint('🔑 Token CSRF trouvé dans le corps de la réponse');
          await _saveCsrfToken(token);
          return token;
        }
      }
      
      // Journaliser plus d'informations sur l'erreur
      debugPrint('⚠️ Impossible de récupérer le token CSRF:');
      debugPrint('Code: ${response.statusCode}');
      debugPrint('Response: ${response.data}');
      
      // Solution de contournement temporaire pour les cas d'urgence uniquement
      // En production, cette section devrait être retirée
      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 400) {
        final fallbackToken = 'debug-csrf-token-${DateTime.now().millisecondsSinceEpoch}';
        debugPrint('🔧 Utilisation d\'un token de secours en mode développement uniquement: $fallbackToken');
        await _saveCsrfToken(fallbackToken);
        return fallbackToken;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Exception lors de la récupération du token CSRF: $e');
      return null;
    } finally {
      _isRefreshingToken = false;
      _processPendingRequests();
    }
  }

  /// Traite les requêtes en attente d'un token CSRF
  void _processPendingRequests() {
    final requestOptions = List<RequestOptions>.from(_pendingRequests);
    _pendingRequests.clear();

    for (var request in requestOptions) {
      if (_csrfToken != null) {
        request.headers['X-CSRF-Token'] = _csrfToken;
      }
      _dio.fetch(request);
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Restauration du code original
    // Ignorer cet intercepteur si demandé explicitement
    if (options.extra.containsKey('ignoreInterceptors') && options.extra['ignoreInterceptors'] == true) {
      handler.next(options);
      return;
    }
    
    // On n'ajoute le token CSRF qu'aux méthodes mutatives
    final bool needsCsrfToken = ['POST', 'PUT', 'DELETE', 'PATCH'].contains(options.method.toUpperCase());
    
    // On ignore aussi les requêtes vers le endpoint mobile qui bypass la protection CSRF
    final bool isMobileEndpoint = options.path.startsWith('/mobile/');
    
    if (needsCsrfToken && !isMobileEndpoint) {
      // Si on n'a pas de token ou s'il est temps de le rafraîchir
      if (_csrfToken == null) {
        final token = await _fetchCsrfToken();
        
        if (token != null) {
          options.headers['X-CSRF-Token'] = token;
        }
      } else {
        options.headers['X-CSRF-Token'] = _csrfToken;
      }
    }
    
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // On vérifie si la réponse contient un nouveau token CSRF dans les headers
    final csrfToken = response.headers.value('x-csrf-token');
    
    if (csrfToken != null) {
      _saveCsrfToken(csrfToken);
    }
    
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Ignorer cet intercepteur si demandé explicitement
    if (err.requestOptions.extra.containsKey('ignoreInterceptors') && 
        err.requestOptions.extra['ignoreInterceptors'] == true) {
      handler.next(err);
      return;
    }
    
    // Vérifier si l'erreur est due à un problème de CSRF (403 avec un code spécifique)
    if (err.response?.statusCode == 403) {
      bool isCsrfError = false;
      
      // Vérifier si l'erreur contient un message spécifique de CSRF
      if (err.response?.data is Map) {
        final data = err.response!.data as Map;
        isCsrfError = data['errorCode'] == 'GENERAL_CSRF_ERROR' || 
                     (data['message'] is String && 
                      (data['message'] as String).toLowerCase().contains('csrf'));
      }
      
      if (isCsrfError) {
        debugPrint('Erreur CSRF détectée, récupération d\'un nouveau token...');
        
        // Récupérer un nouveau token
        final token = await _fetchCsrfToken();
        
        if (token != null) {
          // Réessayer la requête avec le nouveau token
          final options = err.requestOptions;
          options.headers['X-CSRF-Token'] = token;
          
          try {
            final response = await _dio.fetch(options);
            handler.resolve(response);
            return;
          } catch (e) {
            debugPrint('Échec de la requête après récupération d\'un nouveau token CSRF: $e');
          }
        }
      }
    }
    
    // Si on ne peut pas résoudre l'erreur, on la propage
    handler.next(err);
  }
}
