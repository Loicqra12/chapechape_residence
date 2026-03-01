import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chapechape_client/core/config/app_config.dart';

class PlacePrediction {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String description;

  const PlacePrediction({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.description,
  });
}

/// Service d'autocomplétion — passe par le backend (GET /api/maps/autocomplete)
/// La clé Google Maps reste côté serveur, jamais exposée dans l'app.
class PlacesService {
  static const String _recentKey = 'recent_destinations';
  static const int _maxRecent = 5;

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  /// Retourne l'URL de base du backend sans le suffixe "/api"
  String get _backendBase {
    final url = AppConfig.apiUrl; // ex: "http://192.168.x.x:4000/api"
    return url.endsWith('/api')
        ? url
        : url.endsWith('/')
            ? '${url}api'
            : '$url/api'.replaceAll('/api/api', '/api');
  }

  Future<List<PlacePrediction>> autocomplete(String input) async {
    if (input.trim().isEmpty) return [];
    try {
      final response = await _dio
          .get(
            '$_backendBase/maps/autocomplete',
            queryParameters: {'query': input},
          )
          .timeout(const Duration(seconds: 8));

      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) return [];

      final list = body['data'] as List? ?? [];
      return list.map((p) {
        return PlacePrediction(
          placeId: p['placeId'] as String? ?? '',
          mainText: p['mainText'] as String? ?? '',
          secondaryText: p['secondaryText'] as String? ?? '',
          description: p['description'] as String? ?? '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentKey) ?? [];
  }

  Future<void> addRecentSearch(String description) async {
    if (description.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_recentKey) ?? [];
    list.remove(description);
    list.insert(0, description);
    if (list.length > _maxRecent) list.removeLast();
    await prefs.setStringList(_recentKey, list);
  }

  Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentKey);
  }
}
