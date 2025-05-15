import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Service pour mettre en cache les résultats de vérification de disponibilité
/// Cela permet de réduire les appels API et d'améliorer les performances
class AvailabilityCacheService {
  static const String _boxName = 'availability_cache';
  static final AvailabilityCacheService _instance = AvailabilityCacheService._internal();
  
  late Box<String> _cacheBox;
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');
  bool _isInitialized = false;

  /// Singleton instance
  factory AvailabilityCacheService() => _instance;
  
  AvailabilityCacheService._internal();
  
  /// Initialiser le service de cache
  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        _cacheBox = await Hive.openBox<String>(_boxName);
      } else {
        _cacheBox = Hive.box<String>(_boxName);
      }
      _isInitialized = true;
      debugPrint('✓ AvailabilityCacheService initialisé');
    } catch (e) {
      debugPrint('✗ Erreur lors de l\'initialisation d\'AvailabilityCacheService: $e');
      rethrow;
    }
  }
  
  /// Génère une clé de cache basée sur les paramètres de disponibilité
  String _generateKey(String residenceId, DateTime checkIn, DateTime checkOut) {
    final formattedCheckIn = _dateFormatter.format(checkIn);
    final formattedCheckOut = _dateFormatter.format(checkOut);
    return 'availability_${residenceId}_${formattedCheckIn}_${formattedCheckOut}';
  }
  
  /// Mettre en cache un résultat de disponibilité
  Future<void> cacheAvailabilityResult({
    required String residenceId,
    required DateTime checkIn,
    required DateTime checkOut,
    required bool isAvailable,
    int expiryHours = 24, // Par défaut, expire après 24 heures
  }) async {
    await ensureInitialized();
    
    final key = _generateKey(residenceId, checkIn, checkOut);
    final data = {
      'residenceId': residenceId,
      'checkIn': _dateFormatter.format(checkIn),
      'checkOut': _dateFormatter.format(checkOut),
      'isAvailable': isAvailable,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiryTime': DateTime.now().add(Duration(hours: expiryHours)).millisecondsSinceEpoch,
    };
    
    await _cacheBox.put(key, jsonEncode(data));
    debugPrint('📅 Résultat de disponibilité mis en cache: $key');
  }
  
  /// Récupérer un résultat de disponibilité du cache
  /// Retourne null si non trouvé ou expiré
  Future<bool?> getCachedAvailability({
    required String residenceId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    await ensureInitialized();
    
    final key = _generateKey(residenceId, checkIn, checkOut);
    final cachedData = _cacheBox.get(key);
    
    if (cachedData == null) {
      debugPrint('📅 Aucun résultat en cache pour: $key');
      return null;
    }
    
    try {
      final data = jsonDecode(cachedData) as Map<String, dynamic>;
      final expiryTime = data['expiryTime'] as int;
      
      // Vérifier si le cache est expiré
      if (DateTime.now().millisecondsSinceEpoch > expiryTime) {
        debugPrint('📅 Cache expiré pour: $key');
        // Supprimer l'entrée expirée
        await _cacheBox.delete(key);
        return null;
      }
      
      debugPrint('📅 Résultat trouvé en cache pour: $key');
      return data['isAvailable'] as bool;
    } catch (e) {
      debugPrint('📅 Erreur lors de la lecture du cache: $e');
      // En cas d'erreur, supprimer l'entrée corrompue
      await _cacheBox.delete(key);
      return null;
    }
  }
  
  /// Invalider toutes les entrées de cache pour une résidence spécifique
  Future<void> invalidateResidenceCache(String residenceId) async {
    await ensureInitialized();
    
    final keysToDelete = <String>[];
    
    // Trouver toutes les clés correspondant à cette résidence
    for (final key in _cacheBox.keys) {
      if (key.toString().startsWith('availability_$residenceId')) {
        keysToDelete.add(key.toString());
      }
    }
    
    // Supprimer les entrées
    for (final key in keysToDelete) {
      await _cacheBox.delete(key);
    }
    
    debugPrint('📅 ${keysToDelete.length} entrées de cache invalidées pour la résidence: $residenceId');
  }
  
  /// Mettre à jour le statut de disponibilité dans le cache lors d'une réservation
  Future<void> updateAvailabilityOnBooking({
    required String residenceId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    await ensureInitialized();
    
    // Trouver toutes les entrées de cache qui se chevauchent avec la période réservée
    final keysToUpdate = <String>[];
    
    // Trouver toutes les entrées de cache qui pourraient être affectées
    for (final key in _cacheBox.keys) {
      if (key.toString().startsWith('availability_$residenceId')) {
        final cachedData = _cacheBox.get(key.toString());
        if (cachedData != null) {
          try {
            final data = jsonDecode(cachedData) as Map<String, dynamic>;
            final cachedCheckIn = _dateFormatter.parse(data['checkIn'] as String);
            final cachedCheckOut = _dateFormatter.parse(data['checkOut'] as String);
            
            // Vérifier si cette période chevauche la nouvelle réservation
            if (_periodsOverlap(cachedCheckIn, cachedCheckOut, checkIn, checkOut)) {
              keysToUpdate.add(key.toString());
            }
          } catch (e) {
            debugPrint('📅 Erreur lors de la lecture d\'une entrée de cache: $e');
            await _cacheBox.delete(key.toString());
          }
        }
      }
    }
    
    // Mettre à jour les entrées à "non disponible"
    for (final key in keysToUpdate) {
      try {
        final cachedData = _cacheBox.get(key);
        if (cachedData != null) {
          final data = jsonDecode(cachedData) as Map<String, dynamic>;
          data['isAvailable'] = false;
          await _cacheBox.put(key, jsonEncode(data));
        }
      } catch (e) {
        debugPrint('📅 Erreur lors de la mise à jour du cache: $e');
        await _cacheBox.delete(key);
      }
    }
    
    debugPrint('📅 ${keysToUpdate.length} entrées de cache mises à jour suite à une réservation');
  }
  
  /// Vérifier si deux périodes se chevauchent
  bool _periodsOverlap(
    DateTime period1Start, 
    DateTime period1End, 
    DateTime period2Start, 
    DateTime period2End,
  ) {
    return period1Start.isBefore(period2End) && period2Start.isBefore(period1End);
  }
  
  /// Obtenir toutes les dates entre deux dates
  List<DateTime> _getDatesBetween(DateTime startDate, DateTime endDate) {
    final dates = <DateTime>[];
    var currentDate = startDate;
    
    while (currentDate.isBefore(endDate)) {
      dates.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return dates;
  }
  
  /// Nettoyer le cache (supprimer les entrées expirées)
  Future<void> cleanupCache() async {
    await ensureInitialized();
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final keysToDelete = <String>[];
    
    for (final key in _cacheBox.keys) {
      final cachedData = _cacheBox.get(key.toString());
      if (cachedData != null) {
        try {
          final data = jsonDecode(cachedData) as Map<String, dynamic>;
          final expiryTime = data['expiryTime'] as int;
          
          if (now > expiryTime) {
            keysToDelete.add(key.toString());
          }
        } catch (e) {
          // Entrée corrompue, la supprimer
          keysToDelete.add(key.toString());
        }
      }
    }
    
    // Supprimer les entrées
    for (final key in keysToDelete) {
      await _cacheBox.delete(key);
    }
    
    debugPrint('📅 Nettoyage du cache: ${keysToDelete.length} entrées expirées supprimées');
  }
  
  /// Obtenir la taille du cache
  Future<int> getCacheSize() async {
    await ensureInitialized();
    return _cacheBox.length;
  }
}
