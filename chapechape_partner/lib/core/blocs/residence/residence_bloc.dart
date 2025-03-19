import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb, VoidCallback;
import '../../models/residence/residence.dart';
import '../../models/residence/residence_image.dart';
import '../../services/api/residence_service.dart';
import '../../exceptions/api_exception.dart';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Events
abstract class ResidenceEvent {}

class LoadResidences extends ResidenceEvent {}

class LoadMyResidences extends ResidenceEvent {}

class SearchResidences extends ResidenceEvent {
  final String query;
  SearchResidences(this.query);
}

class FilterResidences extends ResidenceEvent {
  final Map<String, dynamic> filters;
  FilterResidences(this.filters);
}

class SortResidences extends ResidenceEvent {
  final String sortBy;
  final bool ascending;
  SortResidences(this.sortBy, {this.ascending = true});
}

class CreateResidence extends ResidenceEvent {
  final Map<String, dynamic> data;
  final dynamic images;

  CreateResidence(this.data, this.images);
}

class UpdateResidence extends ResidenceEvent {
  final String id;
  final Map<String, dynamic> data;

  UpdateResidence(this.id, this.data);
}

class UploadResidenceImages extends ResidenceEvent {
  final String residenceId;
  final dynamic images;

  UploadResidenceImages(this.residenceId, this.images);
}

class DeleteResidence extends ResidenceEvent {
  final String id;
  DeleteResidence(this.id);
}

class CheckResidenceExists extends ResidenceEvent {
  final String id;
  final VoidCallback onSuccess;
  final VoidCallback? onError;
  
  CheckResidenceExists(this.id, {required this.onSuccess, this.onError});
}

class LoadResidenceDetails extends ResidenceEvent {
  final String residenceId;
  LoadResidenceDetails(this.residenceId);
}

// States
abstract class ResidenceState {}

class ResidenceInitial extends ResidenceState {}

class ResidenceLoading extends ResidenceState {}

class ResidenceSuccess extends ResidenceState {
  final String message;
  ResidenceSuccess(this.message);
}

class ResidenceError extends ResidenceState {
  final String message;
  final bool isNetworkError;
  final bool isAuthError;
  
  ResidenceError(this.message, {
    this.isNetworkError = false,
    this.isAuthError = false,
  });
  
  factory ResidenceError.fromApiException(ApiException e) {
    return ResidenceError(
      e.message,
      isNetworkError: e.isNetworkError,
      isAuthError: e.isAuthError,
    );
  }
}

class ResidenceLoaded extends ResidenceState {
  final List<Residence> residences;
  final int totalCount;
  final Map<String, dynamic>? pagination;
  
  ResidenceLoaded(this.residences, {
    this.totalCount = 0,
    this.pagination,
  });
}

class ResidenceOperationSuccessful extends ResidenceState {}

class ResidenceDetailsLoaded extends ResidenceState {
  final Residence residence;
  ResidenceDetailsLoaded(this.residence);
}

// Bloc
class ResidenceBloc extends Bloc<ResidenceEvent, ResidenceState> {
  final ResidenceService _residenceService;

  ResidenceBloc(this._residenceService) : super(ResidenceInitial()) {
    on<LoadResidences>(_onLoadResidences);
    on<LoadMyResidences>(_onLoadMyResidences);
    on<SearchResidences>(_onSearchResidences);
    on<FilterResidences>(_onFilterResidences);
    on<SortResidences>(_onSortResidences);
    on<CreateResidence>(_onCreateResidence);
    on<UpdateResidence>(_onUpdateResidence);
    on<UploadResidenceImages>(_onUploadResidenceImages);
    on<DeleteResidence>(_onDeleteResidence);
    on<CheckResidenceExists>(_onCheckResidenceExists);
    on<LoadResidenceDetails>(_onLoadResidenceDetails);
  }

  Future<void> _onLoadResidences(
    LoadResidences event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(ResidenceLoading());
      final residences = await _residenceService.getResidences();
      emit(ResidenceLoaded(residences));
    } on ApiException catch (e) {
      emit(ResidenceError.fromApiException(e));
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }

  Future<void> _onLoadMyResidences(
    LoadMyResidences event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      print("🔍 Début du chargement des résidences du partenaire");
      emit(ResidenceLoading());
      
      // Vérifier si l'ID utilisateur est bien stocké
      final storage = const FlutterSecureStorage();
      final userId = await storage.read(key: 'userId');
      print("🔑 ID utilisateur trouvé dans le storage: $userId");
      
      final residences = await _residenceService.getMyResidences();
      print("📋 Résidences du partenaire chargées: ${residences.length}");
      
      // Afficher les ID des résidences chargées
      if (residences.isNotEmpty) {
        print("🏠 Résidences filtrées:");
        for (var residence in residences) {
          print("   - ${residence.name} (${residence.id})");
        }
      } else {
        print("⚠️ Aucune résidence trouvée pour ce partenaire");
      }
      
      emit(ResidenceLoaded(residences));
    } catch (e) {
      print("❌ Erreur lors du chargement des résidences du partenaire: $e");
      emit(ResidenceError(e.toString()));
    }
  }

  Future<void> _onSearchResidences(
    SearchResidences event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(ResidenceLoading());
      final residences = await _residenceService.searchResidences(event.query);
      emit(ResidenceLoaded(residences));
    } on ApiException catch (e) {
      emit(ResidenceError.fromApiException(e));
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }

  Future<void> _onFilterResidences(
    FilterResidences event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(ResidenceLoading());
      final residences = await _residenceService.filterResidences(event.filters);
      emit(ResidenceLoaded(residences));
    } on ApiException catch (e) {
      emit(ResidenceError.fromApiException(e));
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }

  Future<void> _onSortResidences(
    SortResidences event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(ResidenceLoading());
      final residences = await _residenceService.sortResidences(event.sortBy, event.ascending);
      emit(ResidenceLoaded(residences));
    } on ApiException catch (e) {
      emit(ResidenceError.fromApiException(e));
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }

  Future<void> _onCreateResidence(
    CreateResidence event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(ResidenceLoading());
      final images = ResidenceImage.fromMixed(event.images);
      await _residenceService.createResidence(event.data, images);
      emit(ResidenceSuccess('Résidence créée avec succès'));
      add(LoadResidences());
    } on ApiException catch (e) {
      emit(ResidenceError.fromApiException(e));
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }

  Future<void> _onUpdateResidence(
    UpdateResidence event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(ResidenceLoading());
      await _residenceService.updateResidence(event.id, event.data);
      emit(ResidenceSuccess('Résidence mise à jour avec succès'));
      add(LoadResidences());
    } on ApiException catch (e) {
      emit(ResidenceError.fromApiException(e));
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }

  Future<void> _onUploadResidenceImages(
    UploadResidenceImages event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(ResidenceLoading());
      final images = ResidenceImage.fromMixed(event.images);
      
      if (images.isNotEmpty) {
        print("Téléchargement et rafraîchissement des données de la résidence");
        // Utiliser la nouvelle méthode qui télécharge les images et récupère la résidence mise à jour
        final updatedResidence = await _residenceService.uploadImagesAndRefreshResidence(event.residenceId, images);
        
        emit(ResidenceSuccess('Images téléchargées avec succès'));
        // Recharger toutes les résidences pour mettre à jour la liste
        add(LoadResidences());
      } else {
        // Si aucune image n'est à télécharger, simplement émettre un succès
        emit(ResidenceSuccess('Aucune image à télécharger'));
        add(LoadResidences());
      }
    } on ApiException catch (e) {
      emit(ResidenceError.fromApiException(e));
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }

  Future<void> _onDeleteResidence(
    DeleteResidence event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(ResidenceLoading());
      await _residenceService.deleteResidence(event.id);
      emit(ResidenceSuccess('Résidence supprimée avec succès'));
      add(LoadResidences());
    } on ApiException catch (e) {
      emit(ResidenceError.fromApiException(e));
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }

  Future<void> _onCheckResidenceExists(
    CheckResidenceExists event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      // On ne change pas l'état pour ne pas perturber l'UI
      await _residenceService.getResidenceById(event.id);
      // Si on arrive ici, la résidence existe
      event.onSuccess();
    } on ApiException catch (e) {
      if (event.onError != null) {
        event.onError!();
      } else {
        // Si aucun callback d'erreur n'est fourni, on affiche un message d'erreur
        emit(ResidenceError.fromApiException(e));
      }
    } catch (e) {
      if (event.onError != null) {
        event.onError!();
      } else {
        emit(ResidenceError(e.toString()));
      }
    }
  }

  Future<void> _onLoadResidenceDetails(
    LoadResidenceDetails event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(ResidenceLoading());
      final residence = await _residenceService.getResidenceById(event.residenceId);
      emit(ResidenceLoaded([residence], totalCount: 1));
    } on ApiException catch (e) {
      emit(ResidenceError.fromApiException(e));
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }
}
