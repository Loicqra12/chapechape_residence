import 'package:flutter/foundation.dart'; // kDebugMode, debugPrint
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:chapechape_client/core/services/residence_service.dart';
import 'package:chapechape_client/core/services/favorite_service.dart';
import 'package:chapechape_client/core/services/type_sync_service.dart';
import 'package:chapechape_client/core/models/residence_model.dart';
import 'package:chapechape_client/core/models/residence_type_enum.dart';
import 'package:chapechape_client/core/services/location_service.dart';
import 'package:chapechape_client/core/models/country.dart';
import 'package:chapechape_client/core/models/region.dart';
import 'package:chapechape_client/core/models/city.dart';
import 'package:chapechape_client/core/models/neighborhood.dart';

// Exposer le modèle Residence pour les fichiers part
export 'package:chapechape_client/core/models/residence_model.dart';
export 'package:chapechape_client/core/models/residence_type_enum.dart';

part 'residence_event.dart';
part 'residence_state.dart';

class ResidenceBloc extends Bloc<ResidenceEvent, ResidenceState> {
  final ResidenceService _residenceService;
  final FavoriteService _favoriteService;
  final TypeSyncService _typeSyncService;

  // Accès aux services de localisation et de cache
  final LocationService _locationService = LocationService();

  // Variable pour stocker l'état précédent
  ResidenceState? _previousState;

  ResidenceBloc({
    required ResidenceService residenceService,
    required FavoriteService favoriteService,
    required TypeSyncService typeSyncService,
  })  : _residenceService = residenceService,
        _favoriteService = favoriteService,
        _typeSyncService = typeSyncService,
        super(const ResidenceInitial()) {
    // Gestionnaires de base
    on<LoadResidencesEvent>(_onLoadResidences);
    on<LoadMoreResidencesEvent>(_onLoadMoreResidences);
    on<SearchResidencesEvent>(_onSearchResidences);
    on<LoadResidenceDetails>(_onLoadResidenceDetails);
    on<ToggleFavorite>(_onToggleFavorite);
    on<LoadFavoriteResidences>(_onLoadFavoriteResidences);
    on<CheckResidenceAvailability>(_onCheckResidenceAvailability);
    
    // Gestionnaires supplémentaires
    on<LoadResidencesByType>(_onLoadResidencesByType);
    on<LoadFeaturedResidences>(_onLoadFeaturedResidences);
    on<LoadSpecialResidences>(_onLoadSpecialResidences);
    on<LoadPopularResidences>(_onLoadPopularResidences);
    on<SearchResidences>(_onSearchSpecificResidences);
    on<FilterResidences>(_onFilterResidences);
    on<FilterResidencesByTypeEvent>(_onFilterResidencesByType);
    on<FilterResidencesByLocation>(_onFilterResidencesByLocation);
    on<ClearFiltersEvent>(_onClearFilters);
    on<RefreshResidencesEvent>(_onRefreshResidences);
    on<LoadResidences>(_onLoadResidencesByParams);
    on<RestorePreviousStateEvent>(_onRestorePreviousState);
  }

  Future<List<Residence>> _hydrateFavorites(List<Residence> list) async {
    try {
      final ids = await _favoriteService.getFavorites();
      if (ids.isEmpty) return list;
      return list.map((r) => r.copyWith(isFavorite: ids.contains(r.id))).toList();
    } catch (_) {
      return list;
    }
  }

  Future<void> _onLoadResidences(
    LoadResidencesEvent event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      if (kDebugMode) debugPrint('🔍 _onLoadResidences');
      emit(const ResidenceLoading());
      final residences = await _residenceService.getAllResidences(
        forceRefresh: true,
      );
      if (residences is! List) {
        if (kDebugMode) debugPrint('🔍 Type inattendu: ${residences.runtimeType}');
        emit(ResidenceError("Type de résidence inattendu: ${residences.runtimeType}"));
        return;
      }
      final typed = residences is List<Residence> ? residences : residences.cast<Residence>();
      final hydrated = await _hydrateFavorites(typed);
      emit(ResidencesLoaded(hydrated));
    } catch (e) {
      if (kDebugMode) debugPrint('🔍 ERREUR _onLoadResidences: $e');
      emit(ResidenceError(e.toString()));
    }
  }

  Future<void> _onLoadMoreResidences(
    LoadMoreResidencesEvent event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      if (state is ResidencesLoaded) {
        final currentState = state as ResidencesLoaded;
        final moreResidences = await _residenceService.getAllResidences(
          page: currentState.residences.length ~/ 10 + 1,
          limit: 10,
        );
        
        if (moreResidences.isNotEmpty) {
          emit(ResidencesLoaded([...currentState.residences, ...moreResidences]));
        }
      }
    } catch (e) {
      // Ne pas émettre d'erreur, simplement conserver l'état actuel
    }
  }

  // Mapping des catégories → types backend (snake_case / enum Mongoose)
  static const Map<String, List<String>> _categoryToTypes = {
    'meublee': [
      'room', 'studio_meuble', 'appartement_meuble', 'villa_meublee', 'loft', 'penthouse',
    ],
    'hotel': [
      'hotel', 'motel', 'boutique_hotel', 'hotel_passage',
      'hotel_luxe', 'guest_house', 'residence_hoteliere', 'maison_hotes',
    ],
    'insolite': [
      'bungalow', 'lodge', 'case_traditionnelle', 'maison_flottante', 'campement_touristique',
    ],
    'colocation': [
      'chambre_colocation', 'coliving', 'residence_universitaire', 'cite_dortoir',
    ],
    'longue_duree': [
      'apartment', 'house', 'villa', 'studio', 'appartement_vide',
      'villa_vide', 'immeuble', 'cour_commune',
    ],
    'economique': [
      'maison_hotes_economique', 'residence_familiale',
      'chambres_passage', 'grenier', 'other',
    ],
  };

  Future<void> _onSearchResidences(
    SearchResidencesEvent event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(const ResidenceLoading());
      
      final f = event.filters;

      final query            = f['query'] as String?;
      final city             = f['city'] as String?;
      final minPrice         = f['minPrice'] is num ? (f['minPrice'] as num).toDouble() : null;
      final maxPrice         = f['maxPrice'] is num ? (f['maxPrice'] as num).toDouble() : null;
      final residenceType    = f['residenceType'] as String?;
      final period           = f['period'] as String?;
      final neighborhood     = f['neighborhood'] as String?;
      final region           = f['region'] as String?;

      // Nouveaux filtres du panneau de filtres (SearchFilters)
      final residenceCategory = f['residenceCategory'] as String?;
      final minBedrooms      = f['minBedrooms'] is int ? f['minBedrooms'] as int : null;
      final minBathrooms     = f['minBathrooms'] is int ? f['minBathrooms'] as int : null;
      final minGuests        = f['minGuests'] is int ? f['minGuests'] as int : null;
      final amenitiesFilter  = f['amenities'] is List ? List<String>.from(f['amenities'] as List) : <String>[];
      final allowsPets       = f['allowsPets'] as bool?;
      final allowsSmoking    = f['allowsSmoking'] as bool?;
      final allowsParties    = f['allowsParties'] as bool?;
      final reservationMode  = f['reservationMode'] as String?;
      final minRating        = f['minRating'] is num ? (f['minRating'] as num).toDouble() : null;

      // Catégorie → liste de types backend (filtrée côté serveur via `types`)
      List<String>? categoryTypes;
      if (residenceCategory != null && residenceCategory.isNotEmpty) {
        categoryTypes = _categoryToTypes[residenceCategory];
      }

      var residences = await _residenceService.searchResidences(
        query: query,
        city: city,
        neighborhood: neighborhood,
        region: region,
        minPrice: minPrice,
        maxPrice: maxPrice,
        bedrooms: minBedrooms,
        bathrooms: minBathrooms,
        minGuests: minGuests,
        amenities: amenitiesFilter.isNotEmpty ? amenitiesFilter : null,
        residenceType: (residenceType != null && residenceType.isNotEmpty)
            ? residenceType
            : null,
        types: (categoryTypes != null && categoryTypes.isNotEmpty)
            ? categoryTypes
            : null,
        period: period,
        allowsPets: allowsPets,
        allowsSmoking: allowsSmoking,
        allowsParties: allowsParties,
        reservationMode: reservationMode,
        minRating: minRating,
        page: event.page,
        limit: event.limit,
        forceRefresh: true,
      );

      // Plus de refiltre client sur une page paginée — filtres appliqués côté API
      final hydrated = await _hydrateFavorites(residences);
      emit(ResidencesLoaded(hydrated));
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }

  Future<void> _onLoadResidenceDetails(
    LoadResidenceDetails event,
    Emitter<ResidenceState> emit,
  ) async {
    // Sauvegarder l'état actuel pour pouvoir le restaurer en cas d'erreur
    final currentState = state;
    _previousState = currentState; // Sauvegarder l'état actuel dans la variable _previousState
    
    List<Residence> previousResidences = [];
    
    // Récupérer les résidences précédentes si disponibles
    if (currentState is ResidencesLoaded) {
      previousResidences = currentState.residences;
    }
    
    try {
      // Émettre l'état de chargement
      emit(const ResidenceLoading());
      
      // forceRefresh: éviter un cache sans le champ `videos` (ajouté après coup)
      final residence = await _residenceService.getResidenceById(
        event.residenceId,
        forceRefresh: true,
      );
      final isFavorite = await _favoriteService.checkFavorite(event.residenceId);
      
      if (residence != null) {
        Map<String, dynamic> priceDetails = residence.priceDetails ?? {};
        priceDetails['isFavorite'] = isFavorite;
        
        final updatedResidence = residence.copyWith(
          priceDetails: priceDetails,
        );
        
        emit(ResidenceDetailsLoaded(updatedResidence));
      } else {
        // En cas de résidence introuvable, restaurer l'état précédent
        if (previousResidences.isNotEmpty) {
          emit(ResidenceError('Résidence introuvable', preservedResidences: previousResidences));
        } else {
          emit(const ResidenceError('Résidence introuvable'));
        }
      }
    } catch (e) {
      // En cas d'erreur, restaurer l'état précédent
      if (previousResidences.isNotEmpty) {
        emit(ResidenceError(e.toString(), preservedResidences: previousResidences));
      } else {
        emit(ResidenceError(e.toString()));
      }
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      // Vérifier si la résidence est déjà en favoris
      final isFavorite = await _favoriteService.checkFavorite(event.residenceId);
      bool success;
      
      // Utiliser les méthodes spécifiques plutôt que toggleFavorite
      if (isFavorite) {
        success = await _favoriteService.removeFromFavorites(event.residenceId);
      } else {
        success = await _favoriteService.addToFavorites(event.residenceId);
      }
      
      if (success) {
        if (state is ResidenceDetailsLoaded) {
          final currentResidence = (state as ResidenceDetailsLoaded).residence;
          if (currentResidence.id == event.residenceId) {
            emit(ResidenceDetailsLoaded(
                currentResidence.copyWith(isFavorite: !isFavorite)));
          }
        } else if (state is ResidencesLoaded) {
          final residences = (state as ResidencesLoaded).residences;
          final updatedResidences = residences.map((residence) {
            if (residence.id == event.residenceId) {
              return residence.copyWith(isFavorite: !isFavorite);
            }
            return residence;
          }).toList();
          emit(ResidencesLoaded(updatedResidences));
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour des favoris: $e');
      // Ne pas émettre d'erreur, simplement conserver l'état actuel
    }
  }

  Future<void> _onLoadFavoriteResidences(
    LoadFavoriteResidences event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(const ResidenceLoading());

      // Endpoint bulk : objets complets (évite N× getById)
      try {
        final fromApi = await _residenceService.getFavoriteResidences();
        final favoriteResidences = fromApi
            .map((residence) => residence.copyWith(isFavorite: true))
            .toList();
        emit(ResidencesLoaded(favoriteResidences));
        return;
      } catch (apiErr) {
        if (kDebugMode) {
          debugPrint(
              'Favoris API indisponible, fallback IDs locaux: $apiErr');
        }
      }

      final favoriteIds = await _favoriteService.getFavorites();
      if (favoriteIds.isEmpty) {
        emit(const ResidencesLoaded([]));
        return;
      }

      final results = await Future.wait(
        favoriteIds.map((id) async {
          try {
            return await _residenceService.getResidenceById(id);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Erreur chargement favori $id: ${e.toString()}');
            }
            return null;
          }
        }),
      );

      final favoriteResidences = results
          .whereType<Residence>()
          .map((residence) => residence.copyWith(isFavorite: true))
          .toList();

      emit(ResidencesLoaded(favoriteResidences));
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }

  Future<void> _onCheckResidenceAvailability(
    CheckResidenceAvailability event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(const ResidenceLoading());
      final isAvailable = await _residenceService.checkAvailability(
        residenceId: event.residenceId,
        checkIn: event.checkIn,
        checkOut: event.checkOut,
      );
      emit(ResidenceAvailabilityChecked(isAvailable));
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }
  
  // Gestionnaire pour charger les résidences par type
  Future<void> _onLoadResidencesByType(
    LoadResidencesByType event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(const ResidenceLoading());
      final residences = await _residenceService.getResidencesByType(event.type);
      emit(ResidencesByTypeLoaded(residences: residences, type: event.type));
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }
  
  // Gestionnaire pour charger les résidences en vedette
  Future<void> _onLoadFeaturedResidences(
    LoadFeaturedResidences event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(const ResidenceLoading());
      // Si la méthode n'accepte pas forceRefresh, nous devrons la modifier dans ResidenceService
      final residences = await _residenceService.getFeaturedResidences();
      emit(FeaturedResidencesLoaded(residences: residences));
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }
  
  // Gestionnaire pour charger les résidences spéciales
  Future<void> _onLoadSpecialResidences(
    LoadSpecialResidences event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(const ResidenceLoading());
      // Si la méthode n'accepte pas forceRefresh, nous devrons la modifier dans ResidenceService
      final residences = await _residenceService.getSpecialResidences();
      emit(SpecialResidencesLoaded(residences: residences));
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }
  
  // Gestionnaire pour charger les résidences populaires
  Future<void> _onLoadPopularResidences(
    LoadPopularResidences event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(const ResidenceLoading());
      final residences = await _residenceService.getPopularResidences();
      emit(PopularResidencesLoaded(residences: residences));
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }
  
  // Gestionnaire pour recherche spécifique
  Future<void> _onSearchSpecificResidences(
    SearchResidences event, 
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(const ResidenceLoading());
      
      // Extraire les filtres et les convertir en paramètres spécifiques
      final filters = event.filters;
      
      // Vérification de minPrice et maxPrice plus sécurisée
      double? minPrice;
      double? maxPrice;
      
      if (filters != null) {
        if (filters['minPrice'] is num) {
          minPrice = (filters['minPrice'] as num).toDouble();
        }
        if (filters['maxPrice'] is num) {
          maxPrice = (filters['maxPrice'] as num).toDouble();
        }
      }
      
      final residences = await _residenceService.searchResidences(
        query: event.query,
        city: filters?['city'] as String?,
        minPrice: minPrice,
        maxPrice: maxPrice,
        forceRefresh: true,
      );
      
      emit(ResidencesSearchResult(
        residences: residences,
        query: event.query,
        filters: event.filters,
      ));
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }
  
  // Gestionnaire pour filtrer les résidences
  Future<void> _onFilterResidences(
    FilterResidences event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(const ResidenceLoading());
      final residences = await _residenceService.getAllResidences(
        filters: event.filters,
      );
      emit(ResidencesFilterResult(
        residences: residences,
        filters: event.filters,
      ));
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }
  
  // Gestionnaire pour filtrer les résidences par type
  Future<void> _onFilterResidencesByType(
    FilterResidencesByTypeEvent event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(const ResidenceLoading());
      final typeString = event.type.toString().split('.').last;
      
      // Filtrer par type via une méthode dédiée
      final residences = await _residenceService.getResidencesByType(typeString);
      
      emit(ResidencesByTypeLoaded(
        residences: residences,
        type: typeString,
      ));
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }
  
  // Gestionnaire pour filtrer les résidences par localisation
  Future<void> _onFilterResidencesByLocation(
    FilterResidencesByLocation event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(ResidencesFiltering());
      
      // Récupérer les résidences filtrées en utilisant searchResidences
      final residences = await _residenceService.searchResidences(
        city: event.cityId,
        // Inclure d'autres paramètres de filtre si nécessaire
      );
      
      // Construire l'objet de filtres pour l'état
      final filters = <String, dynamic>{
        'location': {
          if (event.cityId != null) 'cityId': event.cityId,
          if (event.region != null) 'region': event.region,
          if (event.countryCode != null) 'countryCode': event.countryCode,
          if (event.neighborhood != null) 'neighborhood': event.neighborhood,
        },
      };
      
      emit(ResidencesFilterResult(
        residences: residences,
        filters: filters,
      ));
    } catch (e) {
      emit(ResidenceError('Erreur lors du filtrage par localisation: $e'));
    }
  }
  
  // Gestionnaire pour effacer les filtres
  Future<void> _onClearFilters(
    ClearFiltersEvent event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(const ResidenceLoading());
      final residences = await _residenceService.getAllResidences();
      emit(ResidencesLoaded(residences));
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }
  
  // Gestionnaire pour rafraîchir les résidences
  Future<void> _onRefreshResidences(
    RefreshResidencesEvent event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      // Si nous avons un état précédent et que nous revenons de la page de détails,
      // restaurer cet état au lieu de recharger les données
      if (_previousState != null && 
          (_previousState is ResidencesLoaded || 
           (_previousState is ResidenceError && (_previousState as ResidenceError).preservedResidences != null))) {
        emit(_previousState!);
        return;
      }
      
      // Sinon, procéder au rafraîchissement normal
      emit(const ResidenceRefreshing());
      
      // Récupérer les dernières données avec force refresh
      final residences = await _residenceService.getAllResidences(forceRefresh: true);
      
      // Émettre le nouvel état avec les données fraîches
      // s'assurer que nous avons bien une liste non future
      if (residences is Future) {
        final List<Residence> resolvedResidences = await residences;
        emit(ResidencesLoaded(resolvedResidences));
      } else {
        emit(ResidencesLoaded(residences));
      }
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }

  Future<void> _onLoadResidencesByParams(
    LoadResidences event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(const ResidenceLoading());
      final residences = await _residenceService.getAllResidences(
        filters: event.filters,
        page: event.page,
        limit: event.limit,
      );
      emit(ResidencesLoaded(residences));
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }

  Future<void> _onRestorePreviousState(
    RestorePreviousStateEvent event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      if (_previousState != null) {
        emit(_previousState!);
      }
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }

  // Méthodes d'accès aux données de localisation

  /// Obtenir un pays par son code
  Country? getCountryByCode(String countryCode) {
    return _locationService.getCountryByCode(countryCode);
  }

  /// Obtenir une région par son ID
  Region? getRegionById(String regionId, String countryCode) {
    return _locationService.getRegionById(regionId, countryCode);
  }

  /// Obtenir une ville par son ID
  City? getCityById(String cityId) {
    return _locationService.getCityById(cityId);
  }

  /// Obtenir un quartier par son ID
  Neighborhood? getNeighborhoodById(String neighborhoodId) {
    return _locationService.getNeighborhoodById(neighborhoodId);
  }

  /// Construire un filtre de localisation pour l'API
  Map<String, dynamic> buildLocationFilter({
    String? countryCode,
    String? regionId,
    String? cityId,
    String? neighborhoodId,
  }) {
    final filters = <String, dynamic>{};
    
    if (countryCode != null) {
      filters['countryCode'] = countryCode;
    }
    
    if (regionId != null) {
      final region = getRegionById(regionId, countryCode ?? '');
      if (region != null) {
        filters['region'] = region.name;
      }
    }
    
    if (cityId != null) {
      filters['cityId'] = cityId;
    }
    
    if (neighborhoodId != null) {
      final neighborhood = getNeighborhoodById(neighborhoodId);
      if (neighborhood != null) {
        filters['neighborhood'] = neighborhood.name;
      }
    }
    
    return filters;
  }
}