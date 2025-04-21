import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static SharedPreferencesService? _instance;
  static SharedPreferences? _preferences;

  SharedPreferencesService._();

  static Future<SharedPreferencesService> getInstance() async {
    _instance ??= SharedPreferencesService._();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // String methods
  Future<bool> setString(String key, String value) async {
    return await _preferences!.setString(key, value);
  }

  String getString(String key, {String defaultValue = ''}) {
    return _preferences!.getString(key) ?? defaultValue;
  }

  // Int methods
  Future<bool> setInt(String key, int value) async {
    return await _preferences!.setInt(key, value);
  }

  int getInt(String key, {int defaultValue = 0}) {
    return _preferences!.getInt(key) ?? defaultValue;
  }

  // Double methods
  Future<bool> setDouble(String key, double value) async {
    return await _preferences!.setDouble(key, value);
  }

  double getDouble(String key, {double defaultValue = 0.0}) {
    return _preferences!.getDouble(key) ?? defaultValue;
  }

  // Bool methods
  Future<bool> setBool(String key, bool value) async {
    return await _preferences!.setBool(key, value);
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return _preferences!.getBool(key) ?? defaultValue;
  }

  // StringList methods
  Future<bool> setStringList(String key, List<String> value) async {
    return await _preferences!.setStringList(key, value);
  }

  List<String> getStringList(String key, {List<String> defaultValue = const []}) {
    return _preferences!.getStringList(key) ?? defaultValue;
  }

  // Remove and clear methods
  Future<bool> remove(String key) async {
    return await _preferences!.remove(key);
  }

  Future<bool> clear() async {
    return await _preferences!.clear();
  }

  // Check if key exists
  bool containsKey(String key) {
    return _preferences!.containsKey(key);
  }

  // Get all keys
  Set<String> getKeys() {
    return _preferences!.getKeys();
  }

  /// Calcule la taille approximative des données stockées dans les SharedPreferences
  int getSize() {
    int totalSize = 0;
    final keys = getKeys();
    
    for (final key in keys) {
      // Taille de la clé
      totalSize += key.length * 2; // Approximation pour les caractères UTF-16
      
      // Taille de la valeur selon son type
      if (_preferences!.getString(key) != null) {
        totalSize += (_preferences!.getString(key)?.length ?? 0) * 2;
      } else if (_preferences!.getStringList(key) != null) {
        final list = _preferences!.getStringList(key) ?? [];
        for (final item in list) {
          totalSize += item.length * 2;
        }
      } else if (_preferences!.getInt(key) != null || _preferences!.getDouble(key) != null) {
        totalSize += 8; // Taille approximative pour int/double
      } else if (_preferences!.getBool(key) != null) {
        totalSize += 1; // Taille approximative pour bool
      }
    }
    
    return totalSize;
  }
}
