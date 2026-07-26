import 'package:flutter/foundation.dart';
import 'package:chapechape_partner/core/utils/app_logger.dart';

/// Extension pour convertir de façon sécurisée différents types de données
/// vers double, int, String, etc.
extension SafeConversion on dynamic {
  /// Convertit une valeur en double avec une valeur par défaut si la conversion échoue
  double toDoubleOrDefault([double defaultValue = 0.0]) {
    if (this == null) return defaultValue;
    if (this is double) return this as double;
    if (this is int) return (this as int).toDouble();
    if (this is String) {
      final parsed = double.tryParse(this as String);
      return parsed ?? defaultValue;
    }
    // En mode debug, journaliser les tentatives de conversion étranges
    if (kDebugMode && this is! num && this is! String) {
      AppLogger.d('⚠️ Tentative de conversion en double d\'un type non numérique: ${this.runtimeType}');
    }
    return defaultValue;
  }

  /// Convertit une valeur en int avec une valeur par défaut si la conversion échoue
  int toIntOrDefault([int defaultValue = 0]) {
    if (this == null) return defaultValue;
    if (this is int) return this as int;
    if (this is double) return (this as double).round();
    if (this is String) {
      final parsed = int.tryParse(this as String);
      return parsed ?? defaultValue;
    }
    // En mode debug, journaliser les tentatives de conversion étranges
    if (kDebugMode && this is! num && this is! String) {
      AppLogger.d('⚠️ Tentative de conversion en int d\'un type non numérique: ${this.runtimeType}');
    }
    return defaultValue;
  }

  /// Convertit une valeur en String avec une valeur par défaut si la conversion échoue
  String toStringOrDefault([String defaultValue = '']) {
    if (this == null) return defaultValue;
    return this.toString();
  }

  /// Vérifie si une valeur est null ou vide (pour String, List, Map)
  bool get isNullOrEmpty {
    if (this == null) return true;
    if (this is String) return (this as String).isEmpty;
    if (this is List) return (this as List).isEmpty;
    if (this is Map) return (this as Map).isEmpty;
    return false;
  }

  /// Récupère en toute sécurité un élément imbriqué dans un Map
  dynamic safeGet(List<String> keys, [dynamic defaultValue]) {
    if (this == null || !(this is Map)) return defaultValue;
    
    dynamic current = this;
    for (final key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return defaultValue;
      }
    }
    return current ?? defaultValue;
  }
} 