import 'package:dio/dio.dart';
import '../../models/reservation/reservation.dart';
import '../../config/app_config.dart';

class ReservationService {
  final Dio _dio;
  // Utilitaire pour construire des endpoints API corrects (gère le préfixe /api)
  String _ep(String path) => AppConfig.getApiEndpoint(path);

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
        _ep('reservations/my-reservations'),
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
        _ep('reservations/$id'),
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
      // Utiliser l'endpoint standard qui gère automatiquement le rôle
      final response = await _dio.get(
        _ep('reservations/my-reservations'),
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
        _ep('reservations/residence/$residenceId'),
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
      
      // ✅ Validation préventive côté client - simplifiée
      // Note: Le modèle Reservation côté Partner n'inclut pas paymentStatus
      // La validation complète se fait côté serveur avec des erreurs explicites
      
      await _dio.patch(
        _ep('reservations/$id/status'),
        data: {'status': status.toBackendFormat()},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'x-mobile-app': 'true',  // Contourne la protection CSRF
          },
        ),
      );
    } catch (e) {
      // Gestion améliorée des erreurs spécifiques
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        
        if (statusCode == 400) {
          final message = responseData?['message'] ?? 'Impossible de mettre à jour le statut de cette réservation';
          throw Exception(message);
        } else if (statusCode == 403) {
          throw Exception('Vous n\'\u00eates pas autorisé à modifier cette réservation');
        } else if (statusCode == 404) {
          throw Exception('Réservation introuvable');
        } else if (statusCode == 409) {
          // ✅ Nouveau: Gestion des conflits d'état
          final message = responseData?['message'] ?? 'Transition d\'état invalide. L\'état de la réservation a peut-être changé.';
          throw Exception(message);
        } else if (statusCode == 500) {
          throw Exception('Erreur serveur. Veuillez réessayer plus tard ou contacter le support.');
        }
      }
      throw Exception('Erreur lors de la mise à jour du statut: ${e.toString()}');
    }
  }

  Future<void> cancelReservation(String id, String reason) async {
    try {
      // Utiliser la méthode PATCH qui correspond à l'API backend
      await _dio.patch(
        _ep('reservations/$id/cancel'),
        data: {'reason': reason},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'x-mobile-app': 'true',  // Contourne la protection CSRF
          },
        ),
      );
    } catch (e) {
      // Gestion améliorée des erreurs spécifiques
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        
        if (statusCode == 400) {
          // Erreur métier (réservation ne peut pas être annulée)
          final message = responseData?['message'] ?? 'Cette réservation ne peut plus être annulée';
          throw Exception(message);
        } else if (statusCode == 403) {
          throw Exception('Vous n\'êtes pas autorisé à annuler cette réservation');
        } else if (statusCode == 404) {
          throw Exception('Réservation introuvable ou déjà traitée');
        } else if (statusCode == 500) {
          throw Exception('Erreur serveur. Veuillez réessayer plus tard ou contacter le support.');
        }
      }
      throw Exception('Erreur lors de l\'annulation de la réservation: ${e.toString()}');
    }
  }

  // Désactivé car l'endpoint backend n'existe pas actuellement
  Future<void> addNote(String id, String note) async {
    throw Exception('Endpoint d\'ajout de note non disponible côté backend');
  }

  Future<List<Reservation>> getPartnerReservations() async {
    try {
      print("Récupération des réservations partenaire...");
      
      // D'abord, récupérer les résidences du partenaire
      final residenceResponse = await _dio.get(
        _ep('residences/my-residences'),
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
            _ep('reservations/residence/$residenceId'),
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
      
      // Utiliser l'endpoint unifié qui gère le rôle partenaire
      final response = await _dio.get(
        _ep('reservations/my-reservations'),
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

  /// Crée une nouvelle réservation
  Future<Reservation?> createReservation(Map<String, dynamic> reservationData) async {
    try {
      final response = await _dio.post(
        _ep('reservations'),
        data: reservationData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201 && response.data != null) {
        return Reservation.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la création de la réservation: ${e.toString()}');
    }
  }

  /// Met à jour une réservation existante
  Future<Reservation?> updateReservation(String id, Map<String, dynamic> reservationData) async {
    try {
      final response = await _dio.put(
        _ep('reservations/$id'),
        data: reservationData,
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
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la réservation: ${e.toString()}');
    }
  }

  // ✅ NOUVEAUX ENDPOINTS - INTEGRATION RESERVATIONMODE
  /// Approuver une réservation (Partner uniquement)
  Future<Reservation?> approveReservation(String reservationId) async {
    try {
      final response = await _dio.patch(
        _ep('reservations/$reservationId/approve'),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200 && response.data != null && response.data['data'] != null) {
        return Reservation.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de l\'approbation de la réservation: ${e.toString()}');
    }
  }

  /// Rejeter une réservation (Partner uniquement)
  Future<Reservation?> rejectReservation(String reservationId, {String? reason}) async {
    try {
      final response = await _dio.patch(
        _ep('reservations/$reservationId/reject'),
        data: reason != null ? {'reason': reason} : {},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200 && response.data != null && response.data['data'] != null) {
        return Reservation.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors du rejet de la réservation: ${e.toString()}');
    }
  }

  /// Effectuer le check-in d'une réservation (Partner uniquement)
  Future<Reservation?> performCheckin(String reservationId) async {
    try {
      final response = await _dio.patch(
        _ep('reservations/$reservationId/checkin'),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200 && response.data != null && response.data['data'] != null) {
        return Reservation.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors du check-in: ${e.toString()}');
    }
  }

  /// Effectuer le check-out d'une réservation (Partner uniquement)
  Future<Reservation?> performCheckout(String reservationId) async {
    try {
      final response = await _dio.patch(
        _ep('reservations/$reservationId/checkout'),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200 && response.data != null && response.data['data'] != null) {
        return Reservation.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors du check-out: ${e.toString()}');
    }
  }
}
