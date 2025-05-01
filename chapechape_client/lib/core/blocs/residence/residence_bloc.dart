import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // Pour debugPrint
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

  Future<void> _onLoadResidences(
    LoadResidencesEvent event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      print('🔍 DÉBUT _onLoadResidences');
      emit(const ResidenceLoading());
      // Toujours forcer le rafraîchissement pour s'assurer d'avoir les dernières données
      print('🔍 Avant appel à getAllResidences avec forceRefresh=true');
      final residences = await _residenceService.getAllResidences(
        forceRefresh: true, // Forcer le rafraîchissement indépendamment de la valeur event.forceRefresh
      );
      
      print('🔍 Résidences récupérées: ${residences.runtimeType}, longueur: ${residences is List ? residences.length : "non-list"}');
      
      // S'assurer que nous avons bien une liste concrète avant d'émettre l'état
      if (residences is List<Residence>) {
        print('🔍 Émission de ResidencesLoaded avec ${residences.length} résidences (List<Residence>)');
        emit(ResidencesLoaded(residences));
      } else if (residences is List) {
        print('🔍 Émission de ResidencesLoaded avec ${residences.length} résidences (List générique)');
        final typedResidences = residences.cast<Residence>();
        emit(ResidencesLoaded(typedResidences));
      } else if (residences is Future) {
        print('🔍 Résidences est un Future, en attente de résolution...');
        final List<Residence> resolvedResidences = await residences;
        print('🔍 Future résolu avec ${resolvedResidences.length} résidences');
        emit(ResidencesLoaded(resolvedResidences));
      } else {
        print('🔍 ERREUR: Type inattendu: ${residences.runtimeType}');
        emit(ResidenceError("Type de résidence inattendu: ${residences.runtimeType}"));
      }
      print('🔍 FIN _onLoadResidences');
    } catch (e) {
      print('🔍 ERREUR dans _onLoadResidences: $e');
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

  Future<void> _onSearchResidences(
    SearchResidencesEvent event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(const ResidenceLoading());
      
      // Extraire les paramètres pertinents pour la recherche
      final query = event.filters['query'] as String? ?? '';
      final city = event.filters['city'] as String?;
      final minPrice = event.filters['minPrice'] is num ? (event.filters['minPrice'] as num).toDouble() : null;
      final maxPrice = event.filters['maxPrice'] is num ? (event.filters['maxPrice'] as num).toDouble() : null;
      final bedrooms = event.filters['bedrooms'] is int ? event.filters['bedrooms'] as int : null;
      final bathrooms = event.filters['bathrooms'] is int ? event.filters['bathrooms'] as int : null;
      
      // Convertir les filtres en paramètres spécifiques acceptés par le service
      final residences = await _residenceService.searchResidences(
        query: query,
        city: city,
        minPrice: minPrice,
        maxPrice: maxPrice,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        forceRefresh: true,
      );
      
      emit(ResidencesLoaded(residences));
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
      
      final residence = await _residenceService.getResidenceById(event.residenceId);
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
          
          // Mettre à jour l'état de favori
          Map<String, dynamic> priceDetails = currentResidence.priceDetails ?? {};
          priceDetails['isFavorite'] = !isFavorite; // Inverser l'état actuel
          
          final updatedResidence = currentResidence.copyWith(
            priceDetails: priceDetails,
          );
          
          emit(ResidenceDetailsLoaded(updatedResidence));
        } else if (state is ResidencesLoaded) {
          final residences = (state as ResidencesLoaded).residences;
          final updatedResidences = residences.map((residence) {
            if (residence.id == event.residenceId) {
              Map<String, dynamic> priceDetails = residence.priceDetails ?? {};
              priceDetails['isFavorite'] = !isFavorite; // Inverser l'état actuel
              
              return residence.copyWith(
                priceDetails: priceDetails,
              );
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
      
      // Obtenir les IDs des favoris
      final favoriteIds = await _favoriteService.getFavorites();
      
      // Si pas de favoris, retourner une liste vide
      if (favoriteIds.isEmpty) {
        emit(const ResidencesLoaded([]));
        return;
      }
      
      // Récupérer les résidences correspondantes
      final List<Residence> favoriteResidences = [];
      
      for (final id in favoriteIds) {
        try {
          final residence = await _residenceService.getResidenceById(id);
          if (residence != null) {
            // Créer une copie des détails de prix avec sécurité null
            final priceDetails = Map<String, dynamic>.from(residence.priceDetails ?? {});
            priceDetails['isFavorite'] = true;
            
            favoriteResidences.add(residence.copyWith(
              priceDetails: priceDetails,
            ));
          }
        } catch (e) {
          // Ignorer les erreurs pour les résidences individuelles
          if (kDebugMode) print('Erreur lors du chargement du favori $id: ${e.toString()}');
        }
      }
      
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