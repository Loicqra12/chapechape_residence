import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/stay_credential.dart';
import '../services/booking_service.dart';

class StayCredentialState extends Equatable {
  final int requestGeneration;
  final bool isIssuing;
  final StayCredential? credential;
  final String? errorCode;
  final bool isExpired;

  const StayCredentialState({
    this.requestGeneration = 0,
    this.isIssuing = false,
    this.credential,
    this.errorCode,
    this.isExpired = false,
  });

  StayCredentialState copyWith({
    int? requestGeneration,
    bool? isIssuing,
    StayCredential? credential,
    String? errorCode,
    bool clearCredential = false,
    bool? isExpired,
  }) {
    return StayCredentialState(
      requestGeneration: requestGeneration ?? this.requestGeneration,
      isIssuing: isIssuing ?? this.isIssuing,
      credential: clearCredential ? null : (credential ?? this.credential),
      errorCode: errorCode,
      isExpired: isExpired ?? this.isExpired,
    );
  }

  @override
  List<Object?> get props =>
      [requestGeneration, isIssuing, credential?.version, errorCode, isExpired];

  @override
  String toString() =>
      'StayCredentialState(requestGeneration: $requestGeneration, isIssuing: $isIssuing, '
      'hasCredential: ${credential != null}, purpose: ${credential?.purpose}, '
      'version: ${credential?.version}, errorCode: $errorCode, isExpired: $isExpired)';
}

/// Owner unique de l'état credential Client (mémoire runtime uniquement).
class StayCredentialCubit extends Cubit<StayCredentialState> {
  StayCredentialCubit(this._bookingService) : super(const StayCredentialState());

  final BookingService _bookingService;
  int _activeGeneration = 0;
  bool _httpInFlight = false;

  Future<void> issue({
    required String reservationId,
    required String purpose,
  }) async {
    if (_httpInFlight) return;

    final generation = ++_activeGeneration;
    emit(state.copyWith(
      requestGeneration: generation,
      isIssuing: true,
      errorCode: null,
      isExpired: false,
      clearCredential: true,
    ));

    _httpInFlight = true;
    try {
      final credential = await _bookingService.issueStayCredential(
        reservationId: reservationId,
        purpose: purpose,
      );

      if (isClosed || generation != _activeGeneration) return;

      emit(StayCredentialState(
        requestGeneration: generation,
        isIssuing: false,
        credential: credential,
      ));
    } on StayCredentialException catch (e) {
      if (isClosed || generation != _activeGeneration) return;
      emit(StayCredentialState(
        requestGeneration: generation,
        isIssuing: false,
        errorCode: e.code,
      ));
    } on DioException catch (e) {
      if (isClosed || generation != _activeGeneration) return;
      final parsed = StayCredentialException.fromResponseData(e.response?.data);
      emit(StayCredentialState(
        requestGeneration: generation,
        isIssuing: false,
        errorCode: parsed?.code ?? 'NETWORK_ERROR',
      ));
    } catch (_) {
      if (isClosed || generation != _activeGeneration) return;
      emit(StayCredentialState(
        requestGeneration: generation,
        isIssuing: false,
        errorCode: 'UNKNOWN_ERROR',
      ));
    } finally {
      _httpInFlight = false;
      if (!isClosed &&
          generation != _activeGeneration &&
          state.isIssuing) {
        emit(state.copyWith(isIssuing: false));
      }
    }
  }

  void markExpired() {
    if (state.credential == null) return;
    emit(state.copyWith(isExpired: true));
  }

  void clearError() {
    emit(state.copyWith(errorCode: null));
  }

  @visibleForTesting
  void invalidateInFlightGenerationForTest() {
    _activeGeneration++;
  }

  @override
  Future<void> close() {
    _activeGeneration++;
    return super.close();
  }
}
