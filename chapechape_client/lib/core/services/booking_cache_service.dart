import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:chapechape_client/core/models/booking_model.dart';

/// Service de mise en cache des réservations
class BookingCacheService {
  static const String _bookingBoxName = 'bookings';
  static const String _bookingListKey = 'user_bookings';
  static const Duration _cacheExpiration = Duration(minutes: 15);
  
  late Box _bookingBox;
  
  /// Singleton instance
  static final BookingCacheService _instance = BookingCacheService._internal();
  
  /// Factory pour accéder à l'instance singleton
  factory BookingCacheService() => _instance;
  
  /// Constructeur privé
  BookingCacheService._internal();
  
  /// Initialise le service de cache
  Future<void> initialize() async {
    if (!Hive.isBoxOpen(_bookingBoxName)) {
      _bookingBox = await Hive.openBox(_bookingBoxName);
    } else {
      _bookingBox = Hive.box(_bookingBoxName);
    }
    debugPrint('✅ BookingCacheService initialisé');
  }
  
  /// Récupère une réservation du cache par son ID
  Future<Booking?> getBooking(String bookingId) async {
    try {
      final cachedData = _bookingBox.get(bookingId);
      if (cachedData == null) {
        return null;
      }
      
      final bookingData = jsonDecode(cachedData['data']) as Map<String, dynamic>;
      final timestamp = cachedData['timestamp'] as int;
      
      // Vérifier si le cache est expiré
      if (DateTime.now().millisecondsSinceEpoch - timestamp > _cacheExpiration.inMilliseconds) {
        await _bookingBox.delete(bookingId);
        return null;
      }
      
      return Booking.fromJson(bookingData);
    } catch (e) {
      debugPrint('🔴 Erreur lors de la récupération du cache: $e');
      return null;
    }
  }
  
  /// Sauvegarde une réservation dans le cache
  Future<void> cacheBooking(Booking booking) async {
    try {
      await _bookingBox.put(booking.id, {
        'data': jsonEncode(booking.toJson()),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('🔴 Erreur lors de la mise en cache: $e');
    }
  }
  
  /// Récupère la liste des réservations de l'utilisateur du cache
  Future<List<Booking>?> getUserBookings() async {
    try {
      final cachedData = _bookingBox.get(_bookingListKey);
      if (cachedData == null) {
        return null;
      }
      
      final List<dynamic> bookingsData = jsonDecode(cachedData['data']);
      final timestamp = cachedData['timestamp'] as int;
      
      // Vérifier si le cache est expiré
      if (DateTime.now().millisecondsSinceEpoch - timestamp > _cacheExpiration.inMilliseconds) {
        await _bookingBox.delete(_bookingListKey);
        return null;
      }
      
      return bookingsData
          .map((data) => Booking.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('🔴 Erreur lors de la récupération du cache de la liste: $e');
      return null;
    }
  }
  
  /// Sauvegarde la liste des réservations de l'utilisateur dans le cache
  Future<void> cacheUserBookings(List<Booking> bookings) async {
    try {
      final List<Map<String, dynamic>> bookingsJson = 
          bookings.map((booking) => booking.toJson()).toList();
      
      await _bookingBox.put(_bookingListKey, {
        'data': jsonEncode(bookingsJson),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('🔴 Erreur lors de la mise en cache de la liste: $e');
    }
  }
  
  /// Invalide le cache d'une réservation spécifique
  Future<void> invalidateBooking(String bookingId) async {
    await _bookingBox.delete(bookingId);
  }
  
  /// Invalide tout le cache des réservations
  Future<void> invalidateAllBookings() async {
    await _bookingBox.clear();
  }
  
  /// Récupère la liste des réservations d'une résidence du cache
  Future<List<Booking>?> getResidenceReservations(String residenceId) async {
    try {
      final cacheKey = 'residence_bookings_$residenceId';
      final cachedData = _bookingBox.get(cacheKey);
      if (cachedData == null) {
        return null;
      }
      
      final List<dynamic> bookingsData = jsonDecode(cachedData['data']);
      final timestamp = cachedData['timestamp'] as int;
      
      // Vérifier si le cache est expiré
      if (DateTime.now().millisecondsSinceEpoch - timestamp > _cacheExpiration.inMilliseconds) {
        await _bookingBox.delete(cacheKey);
        return null;
      }
      
      return bookingsData
          .map((data) => Booking.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('🔴 Erreur lors de la récupération du cache des réservations de résidence: $e');
      return null;
    }
  }
  
  /// Sauvegarde la liste des réservations d'une résidence dans le cache
  Future<void> cacheResidenceReservations(String residenceId, List<Booking> bookings) async {
    try {
      final cacheKey = 'residence_bookings_$residenceId';
      final List<Map<String, dynamic>> bookingsJson = 
          bookings.map((booking) => booking.toJson()).toList();
      
      await _bookingBox.put(cacheKey, {
        'data': jsonEncode(bookingsJson),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('🔴 Erreur lors de la mise en cache des réservations de résidence: $e');
    }
  }
}
