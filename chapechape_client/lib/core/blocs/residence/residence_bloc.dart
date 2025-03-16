import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chapechape_client/core/services/residence_service.dart';
import 'package:chapechape_client/core/services/favorite_service.dart';
import 'package:chapechape_client/core/models/residence_model.dart';
import 'residence_event.dart';
import 'residence_state.dart';

class ResidenceBloc extends Bloc<ResidenceEvent, ResidenceState> {
  final ResidenceService _residenceService;
  final FavoriteService _favoriteService;

  ResidenceBloc({
    required ResidenceService residenceService,
    required FavoriteService favoriteService,
  })  : _residenceService = residenceService,
        _favoriteService = favoriteService,
        super(const ResidenceInitial()) {
    on<LoadResidences>(_onLoadResidences);
    on<LoadResidenceDetails>(_onLoadResidenceDetails);
    on<SearchResidences>(_onSearchResidences);
    on<ToggleFavorite>(_onToggleFavorite);
    on<LoadFavoriteResidences>(_onLoadFavoriteResidences);
    on<CheckResidenceAvailability>(_onCheckResidenceAvailability);
  }

  Future<void> _onLoadResidences(
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

  Future<void> _onLoadResidenceDetails(
    LoadResidenceDetails event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(const ResidenceLoading());
      final residence = await _residenceService.getResidenceById(event.residenceId);
      emit(ResidenceDetailsLoaded(residence));
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }

  Future<void> _onSearchResidences(
    SearchResidences event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(const ResidenceLoading());
      final residences = await _residenceService.searchResidences(
        query: event.query,
        city: event.city,
        minPrice: event.minPrice,
        maxPrice: event.maxPrice,
        bedrooms: event.bedrooms,
        bathrooms: event.bathrooms,
        amenities: event.amenities,
        checkIn: event.checkIn,
        checkOut: event.checkOut,
      );
      emit(ResidencesLoaded(residences));
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      if (event.isFavorite) {
        await _favoriteService.addToFavorites(event.residenceId);
      } else {
        await _favoriteService.removeFromFavorites(event.residenceId);
      }
      
      if (state is ResidenceDetailsLoaded) {
        final currentResidence = (state as ResidenceDetailsLoaded).residence;
        final updatedResidence = Residence(
          id: currentResidence.id,
          name: currentResidence.name,
          description: currentResidence.description,
          price: currentResidence.price,
          address: currentResidence.address,
          city: currentResidence.city,
          country: currentResidence.country,
          images: currentResidence.images,
          bedrooms: currentResidence.bedrooms,
          bathrooms: currentResidence.bathrooms,
          surface: currentResidence.surface,
          isAvailable: currentResidence.isAvailable,
          location: currentResidence.location,
          amenities: currentResidence.amenities,
          rules: currentResidence.rules,
          isFavorite: event.isFavorite,
          type: currentResidence.type,
          pricePeriod: currentResidence.pricePeriod,
          hourlyRate: currentResidence.hourlyRate,
          halfDayRate: currentResidence.halfDayRate,
          fullDayRate: currentResidence.fullDayRate,
          weekendRate: currentResidence.weekendRate,
          rating: currentResidence.rating,
          reviewCount: currentResidence.reviewCount,
          ownerId: currentResidence.ownerId,
          createdAt: currentResidence.createdAt,
          updatedAt: currentResidence.updatedAt,
        );
        emit(ResidenceDetailsLoaded(updatedResidence));
      } else if (state is ResidencesLoaded) {
        final residences = (state as ResidencesLoaded).residences;
        final updatedResidences = residences.map((residence) {
          if (residence.id == event.residenceId) {
            return Residence(
              id: residence.id,
              name: residence.name,
              description: residence.description,
              price: residence.price,
              address: residence.address,
              city: residence.city,
              country: residence.country,
              images: residence.images,
              bedrooms: residence.bedrooms,
              bathrooms: residence.bathrooms,
              surface: residence.surface,
              isAvailable: residence.isAvailable,
              location: residence.location,
              amenities: residence.amenities,
              rules: residence.rules,
              isFavorite: event.isFavorite,
              type: residence.type,
              pricePeriod: residence.pricePeriod,
              hourlyRate: residence.hourlyRate,
              halfDayRate: residence.halfDayRate,
              fullDayRate: residence.fullDayRate,
              weekendRate: residence.weekendRate,
              rating: residence.rating,
              reviewCount: residence.reviewCount,
              ownerId: residence.ownerId,
              createdAt: residence.createdAt,
              updatedAt: residence.updatedAt,
            );
          }
          return residence;
        }).toList();
        emit(ResidencesLoaded(updatedResidences));
      }
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }

  Future<void> _onLoadFavoriteResidences(
    LoadFavoriteResidences event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(const ResidenceLoading());
      final residences = await _favoriteService.getFavorites();
      emit(ResidencesLoaded(residences));
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
}