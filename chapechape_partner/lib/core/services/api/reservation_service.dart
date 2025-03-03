import 'package:dio/dio.dart';
import '../../models/reservation/reservation.dart';

class ReservationService {
  final Dio _dio;
  static const String baseUrl = 'http://localhost:4000';

  ReservationService(this._dio);

  Future<List<Reservation>> getReservations({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      
      if (status != null) queryParams['status'] = status;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await _dio.get(
        '$baseUrl/api/reservations',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> reservationsJson = response.data['data'] ?? [];
        return reservationsJson
            .map((json) => Reservation.fromJson(json))
            .toList();
      }

      throw Exception('Erreur lors de la récupération des réservations');
    } catch (e) {
      throw Exception('Erreur lors de la récupération des réservations: ${e.toString()}');
    }
  }

  Future<Reservation> getReservation(String id) async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/reservations/$id',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return Reservation.fromJson(response.data['data']);
      }

      throw Exception('Réservation non trouvée');
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la réservation: ${e.toString()}');
    }
  }

  Future<List<Reservation>> getMyReservations() async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/reservations/my-reservations',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> reservationsJson = response.data['data'] ?? [];
        return reservationsJson
            .map((json) => Reservation.fromJson(json))
            .toList();
      }

      throw Exception('Erreur lors de la récupération de vos réservations');
    } catch (e) {
      throw Exception('Erreur lors de la récupération de vos réservations: ${e.toString()}');
    }
  }

  Future<List<Reservation>> getResidenceReservations(String residenceId) async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/reservations/residence/$residenceId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> reservationsJson = response.data['data'] ?? [];
        return reservationsJson
            .map((json) => Reservation.fromJson(json))
            .toList();
      }

      throw Exception('Erreur lors de la récupération des réservations de la résidence');
    } catch (e) {
      throw Exception('Erreur lors de la récupération des réservations de la résidence: ${e.toString()}');
    }
  }

  Future<void> updateReservationStatus(String id, ReservationStatus status) async {
    try {
      await _dio.patch(
        '$baseUrl/api/reservations/$id/status',
        data: {'status': status.name},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut: ${e.toString()}');
    }
  }

  Future<void> cancelReservation(String id) async {
    try {
      await _dio.post(
        '$baseUrl/api/reservations/$id/cancel',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation de la réservation: ${e.toString()}');
    }
  }

  Future<void> addNote(String id, String note) async {
    try {
      await _dio.post(
        '$baseUrl/api/reservations/$id/notes',
        data: {'note': note},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de la note: ${e.toString()}');
    }
  }
}
