import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // Pour debugPrint
import 'package:chapechape_client/core/services/residence_service.dart';
import 'package:chapechape_client/core/services/favorite_service.dart';
import 'package:chapechape_client/core/services/type_sync_service.dart';
import 'package:chapechape_client/core/models/residence_model.dart';
import 'package:chapechape_client/core/models/residence_type_enum.dart';

// Exposer le modèle Residence pour les fichiers part
export 'package:chapechape_client/core/models/residence_model.dart';
export 'package:chapechape_client/core/models/residence_type_enum.dart';

part 'residence_event.dart';
part 'residence_state.dart';

class ResidenceBloc extends Bloc<ResidenceEvent, ResidenceState> {
  final ResidenceService _residenceService;
  final FavoriteService _favoriteService;
  final TypeSyncService _typeSyncService;

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
  }

  Future<void> _onLoadResidences(
    LoadResidencesEvent event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(const ResidenceLoading());
      final residences = await _residenceService.getAllResidences(
        forceRefresh: event.forceRefresh,
      );
      emit(ResidencesLoaded(residences));
    } catch (e) {
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
    try {
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
        emit(ResidenceError('Résidence introuvable'));
      }
    } catch (e) {
      emit(ResidenceError(e.toString()));
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
      emit(const ResidenceLoading());
      final residences = await _residenceService.getAllResidences(forceRefresh: true);
      emit(ResidencesLoaded(residences));
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
}