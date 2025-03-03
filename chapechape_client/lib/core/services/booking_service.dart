import 'package:dio/dio.dart';
import 'package:chapechape_client/core/models/booking_model.dart';
import 'package:chapechape_client/core/services/api_service.dart';

class BookingService {
  final ApiService _apiService;

  BookingService._({
    required ApiService apiService,
  }) : _apiService = apiService;

  static Future<BookingService> initialize() async {
    final apiService = await ApiService.initialize();
    return BookingService._(apiService: apiService);
  }

  // Créer une nouvelle réservation
  Future<Booking> createBooking({
    required String residenceId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int numberOfGuests,
  }) async {
    try {
      final response = await _apiService.post('/bookings', data: {
        'residenceId': residenceId,
        'checkIn': checkIn.toIso8601String(),
        'checkOut': checkOut.toIso8601String(),
        'numberOfGuests': numberOfGuests,
      });

      return Booking.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Récupérer une réservation par son ID
  Future<Booking> getBookingById(String id) async {
    try {
      final response = await _apiService.get('/bookings/$id');
      return Booking.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Récupérer toutes les réservations de l'utilisateur
  Future<List<Booking>> getUserBookings({String? status}) async {
    try {
      final response = await _apiService.get(
        '/bookings',
        queryParameters: status != null ? {'status': status} : null,
      );

      return (response.data['data'] as List)
          .map((json) => Booking.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Annuler une réservation
  Future<void> cancelBooking({
    required String bookingId,
    String? reason,
  }) async {
    try {
      await _apiService.put('/bookings/$bookingId/cancel', data: {
        if (reason != null) 'reason': reason,
      });
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Modifier une réservation
  Future<Booking> updateBooking({
    required String bookingId,
    DateTime? checkIn,
    DateTime? checkOut,
    int? numberOfGuests,
  }) async {
    try {
      final response = await _apiService.put(
        '/bookings/$bookingId',
        data: {
          if (checkIn != null) 'checkIn': checkIn.toIso8601String(),
          if (checkOut != null) 'checkOut': checkOut.toIso8601String(),
          if (numberOfGuests != null) 'numberOfGuests': numberOfGuests,
        },
      );

      return Booking.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Calculer le prix total d'une réservation
  Future<double> calculatePrice({
    required String residenceId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int numberOfGuests,
  }) async {
    try {
      final response = await _apiService.post(
        '/bookings/calculate-price',
        data: {
          'residenceId': residenceId,
          'checkIn': checkIn.toIso8601String(),
          'checkOut': checkOut.toIso8601String(),
          'numberOfGuests': numberOfGuests,
        },
      );

      return response.data['totalPrice'];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Gérer les erreurs Dio
  Exception _handleDioError(DioException e) {
    switch (e.response?.statusCode) {
      case 400:
        return Exception(e.response?.data['message'] ?? 'Requête invalide');
      case 401:
        return Exception('Non autorisé');
      case 404:
        return Exception('Réservation non trouvée');
      case 409:
        return Exception('Conflit - Dates non disponibles');
      case 422:
        return Exception('Données invalides');
      case 500:
        return Exception('Erreur serveur');
      default:
        return Exception('Une erreur est survenue');
    }
  }
}