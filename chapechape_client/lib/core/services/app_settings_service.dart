import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cache_service.dart';
import 'logger_service.dart';

/// Service de gestion des paramètres de l'application
class AppSettingsService {
  final CacheService cacheService;
  final LoggerService logger;
  static const String _themeKey = 'app_theme';
  static const String _localeKey = 'app_locale';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _searchHistoryKey = 'search_history';
  static const String _filterPreferencesKey = 'filter_preferences';

  AppSettingsService({
    required this.cacheService,
    required this.logger,
  });

  /// Obtient le thème actuel de l'application
  Future<ThemeMode> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = prefs.getString(_themeKey) ?? 'system';
      
      switch (themeString) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        default:
          return ThemeMode.system;
      }
    } catch (e) {
      logger.error('Erreur lors de la récupération du thème: $e');
      return ThemeMode.system;
    }
  }

  /// Définit le thème de l'application
  Future<void> setThemeMode(ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeString;
      
      switch (themeMode) {
        case ThemeMode.light:
          themeString = 'light';
          break;
        case ThemeMode.dark:
          themeString = 'dark';
          break;
        default:
          themeString = 'system';
      }
      
      await prefs.setString(_themeKey, themeString);
      logger.debug('Thème défini sur: $themeString');
    } catch (e) {
      logger.error('Erreur lors de la définition du thème: $e');
    }
  }

  /// Obtient la locale actuelle de l'application
  Future<Locale> getLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeString = prefs.getString(_localeKey);
      
      if (localeString == null) {
        return const Locale('fr');
      }
      
      final parts = localeString.split('_');
      if (parts.length > 1) {
        return Locale(parts[0], parts[1]);
      } else {
        return Locale(parts[0]);
      }
    } catch (e) {
      logger.error('Erreur lors de la récupération de la locale: $e');
      return const Locale('fr');
    }
  }

  /// Définit la locale de l'application
  Future<void> setLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeString = locale.countryCode != null 
          ? '${locale.languageCode}_${locale.countryCode}' 
          : locale.languageCode;
      
      await prefs.setString(_localeKey, localeString);
      logger.debug('Locale définie sur: $localeString');
    } catch (e) {
      logger.error('Erreur lors de la définition de la locale: $e');
    }
  }

  /// Vérifie si les notifications sont activées
  Future<bool> areNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_notificationsKey) ?? true;
    } catch (e) {
      logger.error('Erreur lors de la vérification des notifications: $e');
      return true;
    }
  }

  /// Active ou désactive les notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsKey, enabled);
      logger.debug('Notifications ${enabled ? 'activées' : 'désactivées'}');
    } catch (e) {
      logger.error('Erreur lors de la modification des notifications: $e');
    }
  }

  /// Obtient l'historique de recherche
  Future<List<String>> getSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_searchHistoryKey);
      return historyJson ?? [];
    } catch (e) {
      logger.error('Erreur lors de la récupération de l\'historique: $e');
      return [];
    }
  }

  /// Ajoute une recherche à l'historique
  Future<void> addToSearchHistory(String query) async {
    if (query.isEmpty) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getSearchHistory();
      
      // Supprimer si déjà présent
      history.remove(query);
      
      // Ajouter au début
      history.insert(0, query);
      
      // Limiter à 10 entrées
      if (history.length > 10) {
        history.removeLast();
      }
      
      await prefs.setStringList(_searchHistoryKey, history);
    } catch (e) {
      logger.error('Erreur lors de l\'ajout à l\'historique: $e');
    }
  }

  /// Efface l'historique de recherche
  Future<void> clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_searchHistoryKey);
      logger.debug('Historique de recherche effacé');
    } catch (e) {
      logger.error('Erreur lors de l\'effacement de l\'historique: $e');
    }
  }

  /// Obtient les préférences de filtre
  Future<Map<String, dynamic>> getFilterPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsJson = prefs.getString(_filterPreferencesKey);
      
      if (prefsJson == null) {
        return {};
      }
      
      return Map<String, dynamic>.from(json.decode(prefsJson));
    } catch (e) {
      logger.error('Erreur lors de la récupération des préférences de filtre: $e');
      return {};
    }
  }

  /// Enregistre les préférences de filtre
  Future<void> saveFilterPreferences(Map<String, dynamic> preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_filterPreferencesKey, json.encode(preferences));
      logger.debug('Préférences de filtre enregistrées');
    } catch (e) {
      logger.error('Erreur lors de l\'enregistrement des préférences de filtre: $e');
    }
  }
} 