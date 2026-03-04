import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb, VoidCallback;
import '../../models/residence/residence.dart';
import '../../models/residence/residence_image.dart';
import '../../services/api/residence_service.dart';
import '../../exceptions/api_exception.dart';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/connectivity_service.dart';
import '../../services/cache_service.dart';
import '../../services/sync_service.dart';
import 'dart:convert';
import '../../../core/services/event_bus/residence_event_bus.dart';
import 'package:equatable/equatable.dart';
import '../../repositories/notification_repository.dart';
import 'package:flutter/foundation.dart';

// Events
abstract class ResidenceEvent extends Equatable {
  const ResidenceEvent();

  @override
  List<Object?> get props => [];
}

class LoadResidences extends ResidenceEvent {}

class LoadMyResidences extends ResidenceEvent {}

class SearchResidences extends ResidenceEvent {
  final String query;
  SearchResidences(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterResidences extends ResidenceEvent {
  final Map<String, dynamic> filters;
  FilterResidences(this.filters);

  @override
  List<Object?> get props => [filters];
}

class SortResidences extends ResidenceEvent {
  final String sortBy;
  final bool ascending;
  SortResidences(this.sortBy, {this.ascending = true});

  @override
  List<Object?> get props => [sortBy, ascending];
}

class CreateResidence extends ResidenceEvent {
  final Map<String, dynamic> data;
  final List<dynamic> images;

  CreateResidence(this.data, this.images);

  @override
  List<Object?> get props => [data, images];
}

class UpdateResidence extends ResidenceEvent {
  final String id;
  final Map<String, dynamic> data;

  UpdateResidence(this.id, this.data);

  @override
  List<Object?> get props => [id, data];
}

class UploadResidenceImages extends ResidenceEvent {
  final String residenceId;
  final List<dynamic> images;

  UploadResidenceImages(this.residenceId, this.images);

  @override
  List<Object?> get props => [residenceId, images];
}

class DeleteResidence extends ResidenceEvent {
  final String residenceId;
  DeleteResidence(this.residenceId);

  @override
  List<Object?> get props => [residenceId];
}

class UpdateResidenceAvailability extends ResidenceEvent {
  final String residenceId;
  final bool isAvailable;
  
  UpdateResidenceAvailability(this.residenceId, this.isAvailable);

  @override
  List<Object?> get props => [residenceId, isAvailable];
}

class AddResidencePhoto extends ResidenceEvent {
  final String residenceId;
  final String source; // 'gallery' ou 'camera'
  
  AddResidencePhoto(this.residenceId, {required this.source});

  @override
  List<Object?> get props => [residenceId, source];
}

class DeleteResidencePhoto extends ResidenceEvent {
  final String residenceId;
  final String imageUrl;
  
  DeleteResidencePhoto(this.residenceId, {required this.imageUrl});

  @override
  List<Object?> get props => [residenceId, imageUrl];
}

class CheckResidenceExists extends ResidenceEvent {
  final String id;
  final Function(bool) onSuccess;
  final Function(String)? onError;
  
  CheckResidenceExists(this.id, {required this.onSuccess, this.onError});

  @override
  List<Object?> get props => [id, onSuccess, onError];
}

class LoadResidenceDetails extends ResidenceEvent {
  final String residenceId;
  LoadResidenceDetails(this.residenceId);

  @override
  List<Object?> get props => [residenceId];
}

class RefreshResidences extends ResidenceEvent {}

class SynchronizeResidence extends ResidenceEvent {
  final String residenceId;
  final bool forceRefresh;
  
  const SynchronizeResidence({
    required this.residenceId,
    this.forceRefresh = true,
  });
  
  @override
  List<Object> get props => [residenceId, forceRefresh];
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
  
  factory ResidenceError.fromApiException(ApiException e, {bool isAuthError = false}) {
    return ResidenceError(
      e.message,
      isNetworkError: e.isNetworkError,
      isAuthError: isAuthError || e.isAuthError,
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

class ResidenceCreated extends ResidenceState {
  final Residence newResidence;
  final List<Residence> residences;

  ResidenceCreated({required this.newResidence, required this.residences});
}

class ResidenceUpdated extends ResidenceState {
  final Residence residence;
  final List<Residence> residences;

  ResidenceUpdated({required this.residence, required this.residences});
}

class ResidenceDeleted extends ResidenceState {
  final String residenceId;
  final List<Residence> residences;
  final bool isOfflineMode;

  ResidenceDeleted({
    required this.residenceId,
    required this.residences,
    this.isOfflineMode = false,
  });
}

class ResidenceResidencesLoaded extends ResidenceState {
  final List<Residence> residences;

  ResidenceResidencesLoaded(this.residences);
}

// Bloc
class ResidenceBloc extends Bloc<ResidenceEvent, ResidenceState> {
  final ResidenceService _residenceService;
  final ConnectivityService _connectivityService = ConnectivityService();
  final CacheService _cacheService = CacheService();
  final SyncService _syncService = SyncService();
  final ResidenceEventBus? eventBus;
  final NotificationRepository? _notificationRepository;

  ResidenceBloc(
    this._residenceService, {
    this.eventBus,
    NotificationRepository? notificationRepository,
  }) : _notificationRepository = notificationRepository,
       super(ResidenceInitial()) {
    _connectivityService.initialize();
    _cacheService.initialize();

    on<LoadResidences>(_onLoadResidences);
    on<LoadMyResidences>(_onLoadMyResidences);
    on<SearchResidences>(_onSearchResidences);
    on<FilterResidences>(_onFilterResidences);
    on<SortResidences>(_onSortResidences);
    on<CreateResidence>(_onCreateResidence);
    on<UpdateResidence>(_onUpdateResidence);
    on<UploadResidenceImages>(_onUploadResidenceImages);
    on<DeleteResidence>(_onDeleteResidence);
    on<UpdateResidenceAvailability>(_onUpdateResidenceAvailability);
    on<AddResidencePhoto>(_onAddResidencePhoto);
    on<DeleteResidencePhoto>(_onDeleteResidencePhoto);
    on<CheckResidenceExists>(_onCheckResidenceExists);
    on<LoadResidenceDetails>(_onLoadResidenceDetails);
    on<RefreshResidences>(_onRefreshResidences);
    on<SynchronizeResidence>(_onSynchronizeResidence);

    // SyncService est déjà initialisé dans main.dart avec les bonnes instances (apiService, residenceService, reservationService).
    // Ne pas réinitialiser ici avec des instances vierges pour éviter 404 en cas de sync offline.
  }

  // Méthode pour convertir la liste de maps en liste de Résidences
  List<Residence> _convertToResidenceList(List<dynamic> dynamicList) {
    return dynamicList
        .map((item) => Residence.fromJson(item))
        .toList();
  }

  // Handler pour LoadMyResidences
  Future<void> _onLoadMyResidences(
    LoadMyResidences event,
    Emitter<ResidenceState> emit,
  ) async {
    emit(ResidenceLoading());
    try {
      final residences = await _residenceService.getMyResidences();
      emit(ResidenceLoaded(residences));
    } catch (e) {
      emit(ResidenceError('Erreur lors du chargement: $e'));
    }
  }

  // Handler pour LoadResidences
  Future<void> _onLoadResidences(
    LoadResidences event,
    Emitter<ResidenceState> emit,
  ) async {
    emit(ResidenceLoading());
    try {
      final residences = await _residenceService.getResidences();
      emit(ResidenceLoaded(residences));
    } catch (e) {
      emit(ResidenceError('Erreur lors du chargement: $e'));
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
    emit(ResidenceLoading());
    try {
      if (_connectivityService.isOnline) {
        // En ligne: création directe
        final residence = await _residenceService.createResidence(event.data, ResidenceImage.fromMixed(event.images));
        emit(ResidenceSuccess('Résidence créée avec succès'));
        
        // Notifier via le bus d'événements
        eventBus?.emit(ResidenceEventType.created);
        
        // Envoyer une notification via Twilio
        if (_notificationRepository != null) {
          _notificationRepository!.handleResidenceEvent(
            'residence_created',
            {
              'residenceId': residence.id,
              'residenceName': residence.name,
            },
          );
        }
        
        // Recharger la liste à jour
        final residences = await _residenceService.getMyResidences();
        await _cacheService.cacheResidences(residences);
        
        emit(ResidenceLoaded(residences));
      } else {
        // Hors ligne: ajouter à la liste des opérations en attente
        await _syncService.addOfflineOperation('create_residence', event.data);
        emit(ResidenceSuccess('Résidence enregistrée et sera créée lorsque vous serez en ligne'));
        
        // Recharger la liste locale
        final dynamicResidences = await _cacheService.getCachedResidences();
        final residences = _convertToResidenceList(dynamicResidences);
        emit(ResidenceLoaded(residences));
      }
    } catch (e) {
      emit(ResidenceError('Erreur lors de la création: $e'));
    }
  }

  Future<void> _onUpdateResidence(
    UpdateResidence event,
    Emitter<ResidenceState> emit,
  ) async {
    emit(ResidenceLoading());
    try {
      if (_connectivityService.isOnline) {
        // Récupérer d'abord la résidence pour obtenir les images existantes
        final existingResidence = await _residenceService.getResidenceById(event.id);
        
        // Convertir les URLs d'images en objets ResidenceImage
        final existingImages = existingResidence.images
            .map((url) => ResidenceImage(url: url))
            .toList();
        
        // En ligne: mise à jour directe avec préservation des images
        final residence = await _residenceService.updateResidence(
            event.id, 
            event.data, 
            existingImages  // Utiliser les images existantes au lieu de []
        );
        emit(ResidenceSuccess('Résidence mise à jour avec succès'));
        
        // Notifier via le bus d'événements
        eventBus?.emit(ResidenceEventType.updated);
        
        // Envoyer une notification via Twilio
        if (_notificationRepository != null) {
          _notificationRepository!.handleResidenceEvent(
            'residence_updated',
            {
              'residenceId': residence.id,
              'residenceName': residence.name,
            },
          );
        }
        
        // Recharger la liste à jour
        final residences = await _residenceService.getMyResidences();
        await _cacheService.cacheResidences(residences);
        
        emit(ResidenceLoaded(residences));
      } else {
        // Hors ligne: ajouter à la liste des opérations en attente
        final data = {
          'id': event.id,
          ...event.data,
        };
        await _syncService.addOfflineOperation('update_residence', data);
        emit(ResidenceSuccess('Modification enregistrée et sera appliquée lorsque vous serez en ligne'));
        
        // Recharger la liste locale
        final dynamicResidences = await _cacheService.getCachedResidences();
        final residences = _convertToResidenceList(dynamicResidences);
        emit(ResidenceLoaded(residences));
      }
    } catch (e) {
      emit(ResidenceError('Erreur lors de la mise à jour: $e'));
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
      
      // Récupérer les informations de la résidence avant de la supprimer
      Residence? residenceToDelete;
      try {
        residenceToDelete = await _residenceService.getResidenceById(event.residenceId);
      } catch (e) {
        // Continuer même si on ne peut pas récupérer les infos
        debugPrint('⚠️ Impossible de récupérer les infos de la résidence à supprimer: $e');
      }
      
      if (_connectivityService.isOnline) {
        // En ligne: suppression directe
        await _residenceService.deleteResidence(event.residenceId);
        
        // Notifier via le bus d'événements
        eventBus?.emit(ResidenceEventType.deleted);
        
        // Envoyer une notification via Twilio
        if (_notificationRepository != null) {
          _notificationRepository!.handleResidenceEvent(
            'residence_deleted',
            {
              'residenceId': event.residenceId,
              'residenceName': residenceToDelete?.name ?? 'Résidence',
            },
          );
        }
        
        emit(ResidenceSuccess('Résidence supprimée avec succès'));
        
        // Attendre 1 seconde pour s'assurer que les modifications sont enregistrées côté serveur
        await Future.delayed(const Duration(seconds: 1));
        
        // Forcer un rafraîchissement complet des résidences
        add(RefreshResidences());
      } else {
        // Hors ligne: ajouter à la liste des opérations en attente
        await _syncService.addOfflineOperation('delete_residence', {'id': event.residenceId});
        emit(ResidenceSuccess('Résidence marquée pour suppression et sera traitée lorsque vous serez en ligne'));
        
        // Mettre à jour la liste locale immédiatement
        final dynamicResidences = await _cacheService.getCachedResidences();
        final allResidences = _convertToResidenceList(dynamicResidences);
        final filteredResidences = allResidences.where((r) => r.id != event.residenceId).toList();
        await _cacheService.cacheResidences(filteredResidences);
        emit(ResidenceLoaded(filteredResidences));
      }
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // La résidence n'existe déjà plus, donc on peut considérer ça comme un succès
        emit(ResidenceSuccess('La résidence a été supprimée'));
        add(LoadMyResidences());
      } else {
        emit(ResidenceError.fromApiException(e));
      }
    } catch (e) {
      emit(ResidenceError('Erreur lors de la suppression: $e'));
    }
  }

  Future<void> _onUpdateResidenceAvailability(
    UpdateResidenceAvailability event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(ResidenceLoading());
      
      // Préparer les données de mise à jour
      final Map<String, dynamic> updateData = {
        'status': event.isAvailable ? 'available' : 'unavailable',
      };
      
      // Récupérer d'abord la résidence pour obtenir les images existantes
      final existingResidence = await _residenceService.getResidenceById(event.residenceId);
      
      // Convertir les URLs d'images en objets ResidenceImage
      final existingImages = existingResidence.images
          .map((url) => ResidenceImage(url: url))
          .toList();
      
      // Appeler le service pour mettre à jour la résidence avec les images existantes
      await _residenceService.updateResidence(
          event.residenceId, 
          updateData, 
          existingImages
      );
      
      emit(ResidenceSuccess('Statut de disponibilité mis à jour avec succès'));
      
      // Recharger les détails de la résidence pour actualiser l'UI
      add(LoadResidenceDetails(event.residenceId));
      
    } catch (e) {
      if (e is ApiException) {
        emit(ResidenceError.fromApiException(e));
      } else {
        emit(ResidenceError('Erreur lors de la mise à jour du statut: ${e.toString()}'));
      }
    }
  }

  Future<void> _onAddResidencePhoto(
    AddResidencePhoto event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(ResidenceLoading());
      
      // Nous allons simuler l'ajout réussi d'une photo puisque l'image_picker
      // nécessite une interaction avec l'interface utilisateur que nous ne pouvons pas
      // gérer directement dans le bloc. L'action réelle doit être implémentée au niveau UI.
      // Cette simulation permet au moins de montrer un message de succès.
      
      // Note: Dans l'implémentation complète, l'UI devrait:
      // 1. Utiliser image_picker pour obtenir l'image
      // 2. Créer un ResidenceImage à partir du fichier
      // 3. Appeler uploadResidenceImages sur le service
      
      // Simuler un traitement court
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Plutôt que juste simuler, notifier l'utilisateur que la fonctionnalité est en développement
      emit(ResidenceSuccess('La fonctionnalité d\'ajout de photos sera bientôt disponible'));
      
      // Recharger les détails de la résidence (cela ne changera rien mais respecte le flux)
      add(LoadResidenceDetails(event.residenceId));
      
    } catch (e) {
      if (e is ApiException) {
        emit(ResidenceError.fromApiException(e));
      } else {
        emit(ResidenceError('Erreur lors de l\'ajout de la photo: ${e.toString()}'));
      }
    }
  }

  Future<void> _onDeleteResidencePhoto(
    DeleteResidencePhoto event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(ResidenceLoading());
      
      // Extraire l'ID de l'image de l'URL
      final Uri uri = Uri.parse(event.imageUrl);
      final String imageName = uri.pathSegments.last;
      
      // Appeler le service pour supprimer l'image
      await _residenceService.deleteResidenceImage(event.residenceId, imageName);
      
      emit(ResidenceSuccess('Photo supprimée avec succès'));
      
      // Recharger les détails de la résidence pour actualiser l'UI
      add(LoadResidenceDetails(event.residenceId));
      
    } catch (e) {
      if (e is ApiException) {
        emit(ResidenceError.fromApiException(e));
      } else {
        emit(ResidenceError('Erreur lors de la suppression de la photo: ${e.toString()}'));
      }
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
      event.onSuccess(true);
    } on ApiException catch (e) {
      if (event.onError != null) {
        event.onError!(e.message);
      } else {
        // Si aucun callback d'erreur n'est fourni, on affiche un message d'erreur
        emit(ResidenceError(e.message, isNetworkError: e.isNetworkError, isAuthError: e.isAuthError));
      }
    } catch (e) {
      if (event.onError != null) {
        event.onError!(e.toString());
      } else {
        emit(ResidenceError(e.toString(), isNetworkError: true, isAuthError: false));
      }
    }
  }

  Future<void> _onLoadResidenceDetails(
    LoadResidenceDetails event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(ResidenceLoading());
      
      if (_connectivityService.isOnline) {
        // En ligne: chargement direct depuis le serveur
        final residence = await _residenceService.getResidenceById(event.residenceId);
        emit(ResidenceDetailsLoaded(residence));
      } else {
        // Hors ligne: recherche dans le cache
        print('📴 Appareil hors-ligne, recherche de la résidence dans le cache');
        final dynamicResidences = await _cacheService.getCachedResidences();
        
        // Chercher la résidence correspondante
        try {
          final dynamicResidence = dynamicResidences.firstWhere(
            (r) => r is Map<String, dynamic> && 
                  (r['id'] == event.residenceId || r['_id'] == event.residenceId),
            orElse: () => null,
          );
          
          if (dynamicResidence != null) {
            final residence = Residence.fromJson(dynamicResidence);
            emit(ResidenceDetailsLoaded(residence));
          } else {
            emit(ResidenceError('Résidence non trouvée en mode hors-ligne'));
          }
        } catch (e) {
          emit(ResidenceError('Erreur lors de la recherche de la résidence: $e'));
        }
      }
    } on ApiException catch (e) {
      emit(ResidenceError.fromApiException(e));
    } catch (e) {
      emit(ResidenceError('Erreur lors du chargement de la résidence: $e'));
    }
  }

  Future<void> _onRefreshResidences(
    RefreshResidences event,
    Emitter<ResidenceState> emit,
  ) async {
    emit(ResidenceLoading());
    try {
      // Forcer le chargement depuis le serveur sans utiliser le cache
      final residences = await _residenceService.getMyResidences();
      // Mettre à jour le cache avec les nouvelles données
      await _cacheService.cacheResidences(residences);
      
      // Notifier via le bus d'événements
      eventBus?.emit(ResidenceEventType.refreshNeeded);
      
      emit(ResidenceLoaded(residences));
    } catch (e) {
      emit(ResidenceError('Erreur lors du rafraîchissement: $e'));
    }
  }

  Future<void> _onSynchronizeResidence(
    SynchronizeResidence event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      // Indiquer que la synchronisation est en cours
      emit(ResidenceLoading());
      
      // Utiliser le service de synchronisation pour forcer la synchronisation
      final success = await _syncService.forceSyncResidence(event.residenceId);
      
      if (success) {
        // Si la synchronisation a réussi, récupérer les données à jour
        final residences = await _residenceService.getMyResidences();
        
        // Chercher la résidence synchronisée dans la liste
        final synchronizedResidence = residences.firstWhere(
          (r) => r.id == event.residenceId,
          orElse: () => throw Exception('Résidence non trouvée après synchronisation'),
        );
        
        // Informer via le bus d'événements
        eventBus?.emit(ResidenceEventType.updated);
        
        // Émettre l'état avec la résidence synchronisée
        emit(ResidenceUpdated(
          residence: synchronizedResidence,
          residences: residences,
        ));
      } else {
        emit(ResidenceError('Échec de la synchronisation de la résidence'));
      }
    } on ApiException catch (e) {
      emit(ResidenceError.fromApiException(e));
    } catch (e) {
      emit(ResidenceError('Erreur lors de la synchronisation: $e'));
    }
  }
}
