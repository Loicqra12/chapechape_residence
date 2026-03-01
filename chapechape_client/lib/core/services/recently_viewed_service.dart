import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Stocke les IDs des résidences récemment consultées (max 8, ordre anti-chronologique).
const String _keyIds = 'recently_viewed_residence_ids';
const int _maxIds = 8;

class RecentlyViewedService {
  static RecentlyViewedService? _instance;
  static SharedPreferences? _prefs;

  RecentlyViewedService._();

  static Future<RecentlyViewedService> getInstance() async {
    _instance ??= RecentlyViewedService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  /// Enregistre une consultation (à appeler à l'ouverture d'une fiche résidence).
  Future<void> add(String residenceId) async {
    if (residenceId.isEmpty) return;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyIds);
    List<String> ids = raw != null && raw.isNotEmpty
        ? (jsonDecode(raw) as List<dynamic>).map((e) => e.toString()).toList()
        : [];
    ids.remove(residenceId);
    ids.insert(0, residenceId);
    if (ids.length > _maxIds) ids = ids.take(_maxIds).toList();
    await prefs.setString(_keyIds, jsonEncode(ids));
  }

  /// Retourne la liste des IDs (du plus récent au plus ancien).
  Future<List<String>> getIds() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyIds);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).take(_maxIds).toList();
    } catch (_) {
      return [];
    }
  }

  /// Vide l'historique (optionnel, pour paramètres).
  Future<void> clear() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.remove(_keyIds);
  }
}
