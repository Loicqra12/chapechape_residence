import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/residence/residence.dart';
import '../../models/residence/residence_image.dart';
import '../../services/api/residence_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

// Events
abstract class ResidenceEvent {}

class LoadResidences extends ResidenceEvent {}

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
  ResidenceError(this.message);
}

class ResidenceLoaded extends ResidenceState {
  final List<Residence> residences;
  ResidenceLoaded(this.residences);
}

// Bloc
class ResidenceBloc extends Bloc<ResidenceEvent, ResidenceState> {
  final ResidenceService _residenceService;

  ResidenceBloc(this._residenceService) : super(ResidenceInitial()) {
    on<LoadResidences>(_onLoadResidences);
    on<CreateResidence>(_onCreateResidence);
    on<UpdateResidence>(_onUpdateResidence);
    on<UploadResidenceImages>(_onUploadResidenceImages);
    on<DeleteResidence>(_onDeleteResidence);
  }

  Future<void> _onLoadResidences(
    LoadResidences event,
    Emitter<ResidenceState> emit,
  ) async {
    try {
      emit(ResidenceLoading());
      final residences = await _residenceService.getResidences();
      emit(ResidenceLoaded(residences));
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
      await _residenceService.uploadResidenceImages(event.residenceId, images);
      emit(ResidenceSuccess('Images téléchargées avec succès'));
      add(LoadResidences());
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
    } catch (e) {
      emit(ResidenceError(e.toString()));
    }
  }
}
