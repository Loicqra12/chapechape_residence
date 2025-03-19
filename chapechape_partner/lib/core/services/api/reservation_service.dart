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
        '$baseUrl/api/reservations/my-reservations',
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

  Future<Reservation?> getReservation(String id) async {
    try {
      print("Récupération de la réservation avec ID: $id");
      
      final response = await _dio.get(
        '$baseUrl/api/reservations/$id',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          // Accepter tous les codes de statut pour éviter les exceptions
          validateStatus: (status) => true,
        ),
      );

      print("Statut de la réponse getReservation: ${response.statusCode}");
      print("Données de la réponse: ${response.data}");

      if (response.statusCode == 200 && response.data != null && response.data['data'] != null) {
        return Reservation.fromJson(response.data['data']);
      }

      print("Réservation non trouvée ou réponse invalide");
      return null;
    } catch (e) {
      print("Exception dans getReservation: ${e.toString()}");
      return null;
    }
  }

  Future<List<Reservation>> getMyReservations() async {
    try {
      // Essayer avec my-reservations (pour les clients)
      final response = await _dio.get(
        '$baseUrl/api/reservations/my-reservations',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          // Accepter tous les codes de statut pour éviter les exceptions
          validateStatus: (status) => true,
        ),
      );

      print("Réponse API getMyReservations: ${response.data}");
      print("Statut de la réponse: ${response.statusCode}");

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> reservationsJson = response.data['data'] ?? [];
        print("Nombre de réservations trouvées: ${reservationsJson.length}");
        return reservationsJson
            .map((json) => Reservation.fromJson(json))
            .toList();
      }

      // Si aucune réservation trouvée, retourner une liste vide
      return [];
    } catch (e) {
      print("Exception dans getMyReservations: ${e.toString()}");
      // Au lieu de lancer une exception, retourner une liste vide
      // pour éviter d'afficher un message d'erreur à l'utilisateur
      return [];
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
      if (id.isEmpty) {
        throw Exception('ID de réservation invalide ou manquant');
      }
      
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

  Future<List<Reservation>> getPartnerReservations() async {
    try {
      print("Récupération des réservations partenaire...");
      
      // D'abord, récupérer les résidences du partenaire
      final residenceResponse = await _dio.get(
        '$baseUrl/api/residences/my-residences',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      
      if (residenceResponse.statusCode != 200) {
        throw Exception('Erreur lors de la récupération des résidences');
      }
      
      final List<dynamic> residences = residenceResponse.data['data'] ?? [];
      final List<String> residenceIds = residences
          .map<String>((residence) => residence['_id'].toString())
          .toList();
      
      print("Résidences trouvées: ${residenceIds.length}");
      
      // Si aucune résidence, retourner une liste vide
      if (residenceIds.isEmpty) {
        return [];
      }
      
      // Récupérer les réservations pour chaque résidence
      List<Reservation> allReservations = [];
      for (final residenceId in residenceIds) {
        try {
          final response = await _dio.get(
            '$baseUrl/api/reservations/residence/$residenceId',
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              validateStatus: (status) => true,
            ),
          );
          
          if (response.statusCode == 200 && response.data != null) {
            final List<dynamic> reservationsJson = response.data['data'] ?? [];
            final reservations = reservationsJson
                .map((json) => Reservation.fromJson(json))
                .toList();
            allReservations.addAll(reservations);
            print("Ajout de ${reservations.length} réservations pour résidence $residenceId");
          }
        } catch (e) {
          // Continuer même si une résidence échoue
          print('Erreur lors de la récupération des réservations pour $residenceId: $e');
        }
      }
      
      print("Total des réservations trouvées: ${allReservations.length}");
      return allReservations;
    } catch (e) {
      print("Exception dans getPartnerReservations: ${e.toString()}");
      return [];
    }
  }

  // Utilise le nouvel endpoint dédié aux partenaires
  Future<List<Reservation>> getPartnerReservationsDirect() async {
    try {
      print("Récupération directe des réservations partenaire...");
      
      final response = await _dio.get(
        '$baseUrl/api/reservations/partner-reservations',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> reservationsJson = response.data['data'] ?? [];
        print("Nombre de réservations trouvées: ${reservationsJson.length}");
        return reservationsJson
            .map((json) => Reservation.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      print("Exception dans getPartnerReservationsDirect: ${e.toString()}");
      return [];
    }
  }
}
