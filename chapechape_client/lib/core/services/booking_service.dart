import 'package:dio/dio.dart';
import 'package:chapechape_client/core/models/booking_model.dart';
import 'package:chapechape_client/core/models/cancellation_policy_model.dart';
import 'package:chapechape_client/core/models/modification_fees_model.dart';
import 'package:chapechape_client/core/services/api_service.dart';
import 'package:chapechape_client/core/services/booking_cache_service.dart';
import 'package:flutter/foundation.dart';

class BookingService {
  final ApiService _apiService;
  final BookingCacheService _cacheService;
  bool _isOfflineMode = false;

  BookingService._({ 
    required ApiService apiService,
    required BookingCacheService cacheService,
  }) : 
    _apiService = apiService,
    _cacheService = cacheService;

  static Future<BookingService> initialize() async {
    final apiService = await ApiService.initialize();
    final cacheService = BookingCacheService();
    await cacheService.initialize();
    return BookingService._(
      apiService: apiService,
      cacheService: cacheService
    );
  }
  
  /// Active ou désactive le mode hors ligne
  void setOfflineMode(bool isOffline) {
    _isOfflineMode = isOffline;
    debugPrint('${isOffline ? "🔌" : "🌐"} Mode ${isOffline ? "hors ligne" : "en ligne"} activé');
  }

  // Créer une nouvelle réservation
  Future<Booking> createBooking({
    required String residenceId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int numberOfGuests,
    String? specialRequests,
  }) async {
    try {
      // Valider les paramètres d'entrée
      if (residenceId.isEmpty) {
        throw Exception('L\'ID de résidence ne peut pas être vide');
      }
      if (checkIn.isAfter(checkOut)) {
        throw Exception('La date d\'arrivée doit être antérieure à la date de départ');
      }
      if (checkIn.isBefore(DateTime.now())) {
        throw Exception('La date d\'arrivée ne peut pas être dans le passé');
      }
      if (numberOfGuests <= 0) {
        throw Exception('Le nombre d\'invités doit être supérieur à zéro');
      }
      
      // Formater les dates au format ISO 8601 comme attendu par l'API
      // ✅ CORRECTION RÉSERVATIONS HORAIRES : Envoyer datetime complet avec heures
      final formattedCheckIn = checkIn.toIso8601String(); // Format ISO complet
      final formattedCheckOut = checkOut.toIso8601String(); // Format ISO complet
      
      debugPrint('📅 Création de réservation: $formattedCheckIn → $formattedCheckOut pour $numberOfGuests invités');
      
      // Créer un Map avec les valeurs fournies par l'utilisateur
      final Map<String, dynamic> requestData = {
        'residence': residenceId,
        'checkIn': formattedCheckIn,
        'checkOut': formattedCheckOut,
        'numberOfGuests': numberOfGuests,
        'specialRequests': specialRequests ?? 'Aucune demande spéciale',
      };
      
      debugPrint('Création réservation avec données réelles: $requestData');
      
      // Assurer que le Content-Type est correctement défini
      final options = Options(
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      // Faire la requête en spécifiant explicitement le type de contenu
      final response = await _apiService.post(
        'reservations',
        data: requestData,
        options: options,
      );

      // Gestion défensive de la réponse pour éviter les erreurs de type
      if (response.data == null) {
        throw Exception('Réponse vide du serveur');
      }
      
      if (response.data is! Map) {
        throw Exception('Format de réponse inattendu: ${response.data}');
      }
      
      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'];
      
      if (data == null) {
        throw Exception('Données de réservation manquantes dans la réponse');
      }
      
      if (data is! Map) {
        throw Exception('Format des données de réservation inattendu: $data');
      }

      final booking = Booking.fromJson(data as Map<String, dynamic>);
      
      // Mettre en cache pour les futures requêtes
      await _cacheService.cacheBooking(booking);
      
      return booking;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      // Capture les autres erreurs (comme les erreurs de parsing)
      debugPrint('Erreur lors de la création de la réservation: $e');
      throw Exception('Impossible de créer la réservation: $e');
    }
  }

  // Récupérer une réservation par son ID
  Future<Booking> getBookingById(String id) async {
    try {
      // Essayer de récupérer du cache d'abord
      final cachedBooking = await _cacheService.getBooking(id);
      if (cachedBooking != null) {
        debugPrint('📦 Réservation $id récupérée du cache');
        return cachedBooking;
      }
      
      // Mode hors ligne activé et pas de données en cache
      if (_isOfflineMode) {
        throw Exception('Impossible de récupérer les données en mode hors ligne');
      }
      
      debugPrint('🔍 Récupération de la réservation $id depuis l\'API');
      
      // AMÉLIORATION: Implémenter une stratégie de récupération avec tentatives multiples
      // 1. D'abord essayer l'endpoint standard pour les réservations
      try {
        final response = await _apiService.get('reservations/$id',
          options: Options(validateStatus: (status) => true),  // Accepter tous les statuts
        );
        
        // Vérifier spécifiquement si nous avons une erreur 403 (Forbidden)
        if (response.statusCode == 403) {
          debugPrint('⚠️ Accès refusé (403) à l\'endpoint reservations/$id, tentative alternative...');
          // Laisser l'exécution continuer pour essayer l'endpoint alternatif
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
          );
        }
        
        // Si pas d'erreur 403, continuer normalement
        if (response.statusCode == 200 && response.data != null) {
          // Gestion défensive de la réponse
          if (response.data is! Map) {
            throw Exception('Format de réponse inattendu: ${response.data}');
          }
          
          final responseData = response.data as Map<String, dynamic>;
          if (!responseData.containsKey('data')) {
            throw Exception('Données manquantes dans la réponse');
          }

          final data = responseData['data'];
          final booking = Booking.fromJson(data as Map<String, dynamic>);
          
          // Mettre en cache pour les futures requêtes
          await _cacheService.cacheBooking(booking);
          
          return booking;
        }
        
        // Si on arrive ici, c'est qu'on a un code HTTP différent de 200 ou 403
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      } catch (firstError) {
        // 2. Si la première tentative échoue (surtout en cas de 403),
        // essayer l'endpoint alternatif user-bookings
        debugPrint('🔄 Première tentative échouée, essai avec l\'endpoint alternatif...');
        
        final alternativeResponse = await _apiService.get('reservations/my-reservations');
        
        if (alternativeResponse.statusCode == 200 && alternativeResponse.data != null) {
          final List<dynamic> bookingsJson = alternativeResponse.data['data'] ?? [];
          
          // Chercher la réservation correspondant à l'ID dans la liste récupérée
          final targetBookingJson = bookingsJson.firstWhere(
            (json) => (json['_id']?.toString() ?? '') == id || (json['id']?.toString() ?? '') == id,
            orElse: () => null
          );
          
          if (targetBookingJson != null) {
            final booking = Booking.fromJson(targetBookingJson as Map<String, dynamic>);
            
            // Mettre en cache pour les futures requêtes
            await _cacheService.cacheBooking(booking);
            
            return booking;
          }
        }
        
        // Si on arrive ici, c'est qu'on n'a pas trouvé la réservation
        // Relancer l'erreur initiale pour une gestion cohérente
        if (firstError is DioException) {
          throw _handleDioError(firstError);
        } else {
          throw firstError;
        }
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Récupérer toutes les réservations de l'utilisateur
  Future<List<Booking>> getUserBookings({String? status}) async {
    try {
      // Essayer de récupérer du cache d'abord
      final cachedBookings = await _cacheService.getUserBookings();
      if (cachedBookings != null) {
        debugPrint('📦 Liste de réservations récupérée du cache');
        
        // Si un filtre de statut est demandé, filtrer les résultats du cache
        if (status != null) {
          return cachedBookings.where((booking) => booking.status == status).toList();
        }
        return cachedBookings;
      }
      
      // Mode hors ligne activé et pas de données en cache
      if (_isOfflineMode) {
        throw Exception('Impossible de récupérer les données en mode hors ligne');
      }
      
      debugPrint('🔍 Récupération des réservations depuis l\'API');
      final queryParams = status != null ? {'status': status} : null;
      final response = await _apiService.get('reservations/my-reservations', queryParameters: queryParams);
      final List<dynamic> data = response.data['data'];
      
      final bookings = data.map((item) => Booking.fromJson(item)).toList();
      
      // Mettre en cache pour les futures requêtes
      await _cacheService.cacheUserBookings(bookings);
      
      return bookings;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Récupérer les réservations d'une résidence
  Future<List<Booking>> getResidenceReservations(String residenceId) async {
    try {
      // Essayer de récupérer du cache d'abord
      final cachedBookings = await _cacheService.getResidenceReservations(residenceId);
      if (cachedBookings != null) {
        debugPrint('📦 Liste de réservations récupérée du cache');
        return cachedBookings;
      }
      
      // Mode hors ligne activé et pas de données en cache
      if (_isOfflineMode) {
        throw Exception('Impossible de récupérer les données en mode hors ligne');
      }
      
      debugPrint('🔍 Récupération des réservations depuis l\'API');
      final response = await _apiService.get('reservations/residence/$residenceId');
      final List<dynamic> data = response.data['data'];
      
      final bookings = data.map((item) => Booking.fromJson(item)).toList();
      
      // Mettre en cache pour les futures requêtes
      await _cacheService.cacheResidenceReservations(residenceId, bookings);
      
      return bookings;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Annuler une réservation
  Future<void> cancelBooking({
    required String id,
    String? reason,
  }) async {
    try {
      if (_isOfflineMode) {
        throw Exception('Impossible d\'annuler une réservation en mode hors ligne');
      }
      
      // Utiliser la méthode PATCH pour l'annulation conforme aux standards REST
      final options = Options(headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'x-mobile-app': 'true'  // Contourne la protection CSRF
      });
      
      // Utiliser patchSimple pour respecter la norme REST
      await _apiService.patchSimple('reservations/$id/cancel', 
        data: {
          'reason': reason ?? 'Aucune raison spécifiée'
        },
        options: options
      );
      
      // Invalider le cache pour cette réservation
      await _cacheService.invalidateBooking(id);
      // Invalider aussi la liste des réservations car elle a changé
      await _cacheService.invalidateAllBookings();
      
      debugPrint('🗑️ Réservation $id annulée et cache invalidé');
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      
      if (statusCode == 400) {
        // Cas spécifique: réservation qui ne peut plus être annulée
        final message = responseData?['message'] ?? 'Cette réservation ne peut plus être annulée';
        throw Exception(message);
      } else if (statusCode == 403) {
        throw Exception('Vous n\'avez pas les droits nécessaires pour annuler cette réservation');
      } else if (statusCode == 404) {
        throw Exception('Réservation introuvable');
      }
      
      throw _handleDioError(e);
    }
  }

  // Modifier une réservation
  Future<Booking> updateBooking({
    required String id,
    DateTime? checkIn,
    DateTime? checkOut,
    int? numberOfGuests,
  }) async {
    try {
      final options = Options(headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'x-mobile-app': 'true'  // Contourne la protection CSRF
      });
      
      final response = await _apiService.patch(
        'reservations/$id',
        data: {
          if (checkIn != null) 'checkIn': checkIn.toIso8601String(),
          if (checkOut != null) 'checkOut': checkOut.toIso8601String(),
          if (numberOfGuests != null) 'numberOfGuests': numberOfGuests,
        },
        options: options
      );

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] ?? responseData;
      return Booking.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      
      if (statusCode == 400) {
        // Validation d'erreurs spécifiques
        final message = responseData?['message'] ?? 'Impossible de modifier cette réservation';
        throw Exception(message);
      } else if (statusCode == 403) {
        throw Exception('Vous n\'avez pas les droits nécessaires pour modifier cette réservation');
      } else if (statusCode == 404) {
        throw Exception('Réservation introuvable');
      } else if (statusCode == 422) {
        throw Exception('Les dates demandées ne sont pas disponibles');
      }
      
      throw _handleDioError(e);
    }
  }

  // Mettre à jour le statut d'une réservation
  Future<void> updateBookingStatus({
    required String id,
    required String status,
    String? paymentId,
  }) async {
    try {
      final options = Options(headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'x-mobile-app': 'true'  // Contourne la protection CSRF
      });
      
      await _apiService.patch(
        'reservations/$id/status',
        data: {
          'status': status,
          if (paymentId != null) 'paymentId': paymentId,
        },
        options: options
      );
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
      // Formater les dates au format YYYY-MM-DD
      final formattedCheckIn = "${checkIn.year}-${checkIn.month.toString().padLeft(2, '0')}-${checkIn.day.toString().padLeft(2, '0')}";
      final formattedCheckOut = "${checkOut.year}-${checkOut.month.toString().padLeft(2, '0')}-${checkOut.day.toString().padLeft(2, '0')}";

      debugPrint('💰 Calcul du prix via API: $residenceId | $formattedCheckIn → $formattedCheckOut | $numberOfGuests invités');

      final response = await _apiService.post(
        'reservations/calculate-price',
        data: {
          'residenceId': residenceId,
          'checkIn': formattedCheckIn,
          'checkOut': formattedCheckOut,
          'numberOfGuests': numberOfGuests,
        },
      );

      final data = response.data['data'] ?? response.data;
      final price = data['totalPrice'] ?? data['price'] ?? data['total'];
      if (price == null) {
        throw Exception('Prix non trouvé dans la réponse du serveur');
      }
      return (price as num).toDouble();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Vérifier la disponibilité d'une résidence pour une période donnée
  Future<Map<String, dynamic>> checkAvailability({
    required String residenceId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      // Vérifier que l'ID de résidence n'est pas un ID temporaire
      if (residenceId.isEmpty || residenceId.startsWith('temp_')) {
        throw Exception('ID de résidence invalide pour la vérification de disponibilité');
      }
      
      // ✅ CORRECTION RÉSERVATIONS HORAIRES : Envoyer datetime complet avec heures
      final formattedCheckIn = checkIn.toIso8601String(); // Format ISO complet
      final formattedCheckOut = checkOut.toIso8601String(); // Format ISO complet
      
      debugPrint('🔍 Vérification disponibilité pour residence: $residenceId');
      debugPrint('Dates: $formattedCheckIn → $formattedCheckOut');
      
      // Invalider le cache potentiellement obsolète avant la vérification
      _cacheService.invalidateAvailability(residenceId);
      
      // Appel à l'API réelle pour vérifier la disponibilité
      // Note: L'URL complète est /api/availability/flutter-check, mais le préfixe /api est géré par l'ApiService
      final response = await _apiService.get(
        'availability/flutter-check',
        queryParameters: {
          'residenceId': residenceId,
          'checkIn': formattedCheckIn,
          'checkOut': formattedCheckOut,
        },
      );
      
      if (response.data == null) {
        throw Exception('Réponse vide du serveur lors de la vérification de disponibilité');
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Format de réponse inattendu: ${response.data}');
      }
      
      final responseData = response.data as Map<String, dynamic>;
      
      // Extraire les données de la réponse
      if (!responseData.containsKey('data')) {
        debugPrint('⚠️ Réponse API sans clé data: $responseData');
        
        // Fallback: retourner une structure avec disponibilité par défaut
        return {
          'isAvailable': false,
          'price': await calculatePrice(
            residenceId: residenceId,
            checkIn: checkIn,
            checkOut: checkOut,
            numberOfGuests: 2, // Valeur par défaut
          ),
          'availableDates': [],
          'conflictDates': [],
          'message': 'Impossible de vérifier la disponibilité'
        };
      }
      
      final data = responseData['data'] as Map<String, dynamic>;
      
      // Log des détails de disponibilité pour débogage
      debugPrint('📅 Résultat disponibilité: ${data['isAvailable'] ? "✅ Disponible" : "❌ Non disponible"}');
      if (data.containsKey('conflictDates') && (data['conflictDates'] as List).isNotEmpty) {
        debugPrint('⚠️ Dates en conflit: ${data['conflictDates']}');
      }
      
      // S'assurer que le champ price est toujours un double
      if (data.containsKey('price')) {
        // Convertir explicitement la valeur du prix en double
        data['price'] = (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0;
        debugPrint('💰 Prix converti en double: ${data['price']}');
      }
      
      return data;
    } on DioException catch (e) {
      debugPrint('🔴 Erreur API lors de la vérification de disponibilité: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('❌ Exception lors de la vérification de disponibilité: $e');
      throw Exception('Impossible de vérifier la disponibilité: $e');
    }
  }

  /// Version simplifiée de checkAvailability qui retourne directement un booléen
  /// Cette méthode doit être utilisée quand seul le statut de disponibilité est nécessaire
  Future<bool> isAvailable({
    required String residenceId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      final result = await checkAvailability(
        residenceId: residenceId,
        checkIn: checkIn,
        checkOut: checkOut,
      );
      
      // Extraire le booléen de la map retournée
      return result['isAvailable'] == true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification de disponibilité: $e');
      return false;
    }
  }

  // Vérification des conflits de dates (implémentation côté client)
  bool _checkDateConflicts(List<Map<String, dynamic>> reservations, DateTime checkIn, DateTime checkOut) {
    for (final reservation in reservations) {
      final reservationCheckIn = DateTime.parse(reservation['checkIn']);
      final reservationCheckOut = DateTime.parse(reservation['checkOut']);
      
      // Vérifie s'il y a un chevauchement entre les dates
      if ((checkIn.isBefore(reservationCheckOut) || checkIn.isAtSameMomentAs(reservationCheckOut)) &&
          (checkOut.isAfter(reservationCheckIn) || checkOut.isAtSameMomentAs(reservationCheckIn))) {
        return true; // Il y a un conflit
      }
    }
    
    return false; // Pas de conflit
  }

  // Vérifier la disponibilité pour les nouvelles dates
  Future<bool> checkAvailabilityForModification({
    required String bookingId,
    DateTime? newCheckIn,
    DateTime? newCheckOut,
  }) async {
    try {
      final response = await _apiService.get(
        'reservations/$bookingId/check-availability',
        queryParameters: {
          if (newCheckIn != null) 'checkIn': newCheckIn.toIso8601String(),
          if (newCheckOut != null) 'checkOut': newCheckOut.toIso8601String(),
        },
      );

      if (response.data == null) {
        throw Exception('Réponse vide du serveur');
      }

      final responseData = response.data as Map<String, dynamic>;
      return responseData['data']['isAvailable'] as bool;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Calculer les frais de modification
  Future<ModificationFees> calculateModificationFees({
    required String bookingId,
    DateTime? newCheckIn,
    DateTime? newCheckOut,
    int? newNumberOfGuests,
  }) async {
    try {
      final response = await _apiService.post(
        'reservations/$bookingId/modification-fees',
        data: {
          if (newCheckIn != null) 'newCheckIn': newCheckIn.toIso8601String(),
          if (newCheckOut != null) 'newCheckOut': newCheckOut.toIso8601String(),
          if (newNumberOfGuests != null) 'newNumberOfGuests': newNumberOfGuests,
        },
      );

      if (response.data == null) {
        throw Exception('Réponse vide du serveur');
      }

      if (response.data is! Map) {
        throw Exception('Format de réponse inattendu: ${response.data}');
      }

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'];

      if (data == null) {
        throw Exception('Données des frais manquantes dans la réponse');
      }

      return ModificationFees.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Modifier une réservation avec frais
  Future<Booking> updateBookingWithFees({
    required String id,
    required DateTime checkIn,
    required DateTime checkOut,
    required int numberOfGuests,
    required double modificationFee,
  }) async {
    try {
      final response = await _apiService.patch(
        'reservations/$id',
        data: {
          'checkIn': checkIn.toIso8601String(),
          'checkOut': checkOut.toIso8601String(),
          'numberOfGuests': numberOfGuests,
          'modificationFee': modificationFee,
        },
      );

      if (response.data == null) {
        throw Exception('Réponse vide du serveur');
      }

      if (response.data is! Map) {
        throw Exception('Format de réponse inattendu: ${response.data}');
      }

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'];

      if (data == null) {
        throw Exception('Données de réservation manquantes dans la réponse');
      }

      return Booking.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Récupérer les détails d'une réservation
  Future<Booking> getBookingDetails(String bookingId) async {
    try {
      final response = await _apiService.get('reservations/$bookingId');
      return Booking.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Récupérer une politique d'annulation
  Future<CancellationPolicy> getCancellationPolicy(String policyId) async {
    try {
      final response = await _apiService.get('cancellation-policies/$policyId');
      return CancellationPolicy.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Gestionnaire d'erreurs Dio
  Exception _handleDioError(DioException e) {
    debugPrint('🔴 Erreur API: ${e.message}');
    
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final responseData = e.response!.data;
      
      // Afficher le message d'erreur exact du serveur si disponible
      if (responseData is Map && responseData.containsKey('message')) {
        final errorMessage = responseData['message'];
        return Exception(errorMessage);
      }
      
      // Sinon, utiliser un message par défaut basé sur le statut HTTP
      switch (statusCode) {
        case 400:
          return Exception('Données invalides. Veuillez vérifier les informations saisies.');
        case 401:
          return Exception('Session expirée. Veuillez vous reconnecter.');
        case 403:
          return Exception('Vous n\'avez pas les droits nécessaires pour effectuer cette action.');
        case 404:
          return Exception('Cette réservation n\'existe pas ou a été supprimée.');
        case 409:
          // ✅ Gestion spécifique des conflits d'état de réservation
          if (responseData is Map && responseData['message'] != null) {
            final message = responseData['message'].toString();
            if (message.contains('Transition') || message.contains('état')) {
              return Exception('Action impossible : l\'état de la réservation a changé. Veuillez actualiser.');
            }
          }
          return Exception('Cette période est déjà réservée. Veuillez choisir d\'autres dates.');
        case 422:
          return Exception('Données incorrectes. Veuillez vérifier les champs obligatoires.');
        case 429:
          return Exception('Trop de requêtes. Veuillez réessayer dans quelques instants.');
        case 500:
        case 502:
        case 503:
          return Exception('Le service est temporairement indisponible. Veuillez réessayer plus tard.');
        default:
          return Exception('Erreur $statusCode: ${e.message}');
      }
    }
    
    // Erreur de connexion ou autre erreur Dio
    if (e.type == DioExceptionType.connectionTimeout) {
      return Exception('La connexion au serveur a expiré. Veuillez vérifier votre connexion internet.');
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return Exception('Le serveur met trop de temps à répondre. Veuillez réessayer plus tard.');
    } else if (e.type == DioExceptionType.connectionError) {
      return Exception('Impossible de se connecter au serveur. Veuillez vérifier votre connexion internet.');
    }
    
    return Exception('Erreur de connexion: ${e.message}');
  }
}