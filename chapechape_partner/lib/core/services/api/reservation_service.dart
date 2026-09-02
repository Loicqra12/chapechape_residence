import 'package:dio/dio.dart';
import '../../models/reservation/reservation.dart';
import '../../models/stay_credential_preview.dart';
import '../../config/app_config.dart';
import 'package:chapechape_partner/core/utils/app_logger.dart';

class ReservationService {
  final Dio _dio;
  // Utilitaire pour construire des endpoints API corrects (gère le préfixe /api)
  String _ep(String path) => AppConfig.getApiEndpoint(path);

  ReservationService(this._dio);

  // Constructeur nommé pour l'instanciation simple
  ReservationService.withDefaultDio() : _dio = Dio();

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
      AppLogger.d("Récupération de la réservation avec ID: $id");
      
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

      AppLogger.d("Statut de la réponse getReservation: ${response.statusCode}");
      AppLogger.d("Données de la réponse: ${response.data}");

      if (response.statusCode == 200 && response.data != null && response.data['data'] != null) {
        return Reservation.fromJson(response.data['data']);
      }

      AppLogger.d("Réservation non trouvée ou réponse invalide");
      return null;
    } catch (e) {
      AppLogger.d("Exception dans getReservation: ${e.toString()}");
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

      AppLogger.d("Réponse API getMyReservations: ${response.data}");
      AppLogger.d("Statut de la réponse: ${response.statusCode}");

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> reservationsJson = response.data['data'] ?? [];
        AppLogger.d("Nombre de réservations trouvées: ${reservationsJson.length}");
        return reservationsJson
            .map((json) => Reservation.fromJson(json))
            .toList();
      }

      // Si aucune réservation trouvée, retourner une liste vide
      return [];
    } catch (e) {
      AppLogger.d("Exception dans getMyReservations: ${e.toString()}");
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

      // F3 — rejeter via l'endpoint dédié (backend = cancelled + rejectedByHost)
      if (status == ReservationStatus.rejected) {
        final rejected = await rejectReservation(id);
        if (rejected == null) {
          throw Exception('Échec du rejet de la réservation');
        }
        return;
      }

      // Approbation via endpoint dédié (→ payment_pending + timer)
      // L'UI legacy envoie parfois "confirmed" pour approuver une demande
      if (status == ReservationStatus.confirmed) {
        try {
          final approved = await approveReservation(id);
          if (approved != null) return;
        } catch (_) {
          // Pas en awaiting_approval : continuer vers PATCH status
        }
      }
      
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

  Future<void> addNote(String id, String note) async {
    try {
      final response = await _dio.post(
        _ep('reservations/$id/notes'),
        data: {'note': note},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'x-mobile-app': 'true',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
          response.data?['message'] ?? 'Impossible d\'ajouter la note',
        );
      }
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data?['message'] ?? e.message;
        throw Exception('Erreur lors de l\'ajout de la note: $message');
      }
      rethrow;
    }
  }

  Future<List<Reservation>> getPartnerReservations() async {
    try {
      AppLogger.d("Récupération des réservations partenaire...");
      
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
      
      AppLogger.d("Résidences trouvées: ${residenceIds.length}");
      
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
            AppLogger.d("Ajout de ${reservations.length} réservations pour résidence $residenceId");
          }
        } catch (e) {
          // Continuer même si une résidence échoue
          AppLogger.d('Erreur lors de la récupération des réservations pour $residenceId: $e');
        }
      }
      
      AppLogger.d("Total des réservations trouvées: ${allReservations.length}");
      return allReservations;
    } catch (e) {
      AppLogger.d("Exception dans getPartnerReservations: ${e.toString()}");
      return [];
    }
  }

  // Utilise le nouvel endpoint dédié aux partenaires
  Future<List<Reservation>> getPartnerReservationsDirect() async {
    try {
      AppLogger.d("Récupération directe des réservations partenaire...");
      
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
        AppLogger.d("Nombre de réservations trouvées: ${reservationsJson.length}");
        return reservationsJson
            .map((json) => Reservation.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      AppLogger.d("Exception dans getPartnerReservationsDirect: ${e.toString()}");
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
      final response = await _dio.patch(
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
  Future<Reservation?> performCheckin(
    String reservationId, {
    String? credential,
  }) async {
    try {
      final response = await _dio.patch(
        _ep('reservations/$reservationId/checkin'),
        data: credential != null ? {'credential': credential} : null,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'x-mobile-app': 'true',
          },
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200 && response.data != null && response.data['data'] != null) {
        return Reservation.fromJson(response.data['data']);
      }
      _throwStayActionError(response, 'check-in');
      return null;
    } on DioException catch (e) {
      _throwStayActionDioError(e, 'check-in');
    } catch (e) {
      rethrow;
    }
  }

  /// Effectuer le check-out d'une réservation (Partner uniquement)
  Future<Reservation?> performCheckout(
    String reservationId, {
    String? credential,
  }) async {
    try {
      final response = await _dio.patch(
        _ep('reservations/$reservationId/checkout'),
        data: credential != null ? {'credential': credential} : null,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'x-mobile-app': 'true',
          },
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200 && response.data != null && response.data['data'] != null) {
        return Reservation.fromJson(response.data['data']);
      }
      _throwStayActionError(response, 'check-out');
      return null;
    } on DioException catch (e) {
      _throwStayActionDioError(e, 'check-out');
    } catch (e) {
      rethrow;
    }
  }

  /// Preview non-mutating d'un credential scanné (P2-05D).
  Future<StayCredentialPreview> resolveStayCredential({
    required String credential,
    required String purpose,
  }) async {
    try {
      final response = await _dio.post(
        _ep('reservations/stay-credentials/resolve'),
        data: {
          'credential': credential,
          'purpose': purpose,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'x-mobile-app': 'true',
          },
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['data'] != null) {
        return StayCredentialPreview.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }

      final parsed = StayCredentialApiException.fromResponse(response.data);
      if (parsed != null) throw parsed;
      throw const StayCredentialApiException('UNKNOWN_ERROR');
    } on DioException catch (e) {
      final parsed = StayCredentialApiException.fromResponse(e.response?.data);
      if (parsed != null) throw parsed;
      throw const StayCredentialApiException('NETWORK_ERROR');
    }
  }

  /// Commit check-in/check-out avec credential QR. Retourne [alreadyApplied] si idempotent.
  Future<({Reservation reservation, bool alreadyApplied})> commitStayCredential({
    required String reservationId,
    required String purpose,
    required String credential,
  }) async {
    final updated = purpose == 'checkout'
        ? await performCheckout(reservationId, credential: credential)
        : await performCheckin(reservationId, credential: credential);

    if (updated == null) {
      throw Exception('Action refusée par le serveur');
    }

    return (reservation: updated, alreadyApplied: false);
  }

  Never _throwStayActionError(Response<dynamic> response, String action) {
    final responseData = response.data;
    final code = responseData?['code'] ?? responseData?['errorCode'];
    final message = responseData?['message'] ?? 'Erreur lors du $action';
    throw Exception(code != null ? '$code: $message' : message);
  }

  Never _throwStayActionDioError(DioException e, String action) {
    final responseData = e.response?.data;
    final code = responseData?['code'] ?? responseData?['errorCode'];
    final message = responseData?['message'] ?? 'Erreur lors du $action';
    throw Exception(code != null ? '$code: $message' : message);
  }
}
