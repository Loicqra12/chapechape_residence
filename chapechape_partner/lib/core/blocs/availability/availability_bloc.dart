import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/availability/availability_model.dart';
import '../../services/api/availability_service.dart';

// Events
abstract class AvailabilityEvent extends Equatable {
  const AvailabilityEvent();

  @override
  List<Object?> get props => [];
}

class AvailabilitiesFetched extends AvailabilityEvent {
  final String residenceId;

  const AvailabilitiesFetched({required this.residenceId});

  @override
  List<Object?> get props => [residenceId];
}

class AvailabilityCreated extends AvailabilityEvent {
  final String residenceId;
  final Map<String, dynamic> data;

  const AvailabilityCreated({
    required this.residenceId,
    required this.data,
  });

  @override
  List<Object?> get props => [residenceId, data];
}

class AvailabilityUpdated extends AvailabilityEvent {
  final String residenceId;
  final String availabilityId;
  final Map<String, dynamic> data;

  const AvailabilityUpdated({
    required this.residenceId,
    required this.availabilityId,
    required this.data,
  });

  @override
  List<Object?> get props => [residenceId, availabilityId, data];
}

class AvailabilityDeleted extends AvailabilityEvent {
  final String residenceId;
  final String availabilityId;

  const AvailabilityDeleted({
    required this.residenceId,
    required this.availabilityId,
  });

  @override
  List<Object?> get props => [residenceId, availabilityId];
}

class AvailabilityStatusUpdated extends AvailabilityEvent {
  final String residenceId;
  final String availabilityId;
  final AvailabilityStatus status;

  const AvailabilityStatusUpdated({
    required this.residenceId,
    required this.availabilityId,
    required this.status,
  });

  @override
  List<Object?> get props => [residenceId, availabilityId, status];
}

class AvailabilityPriceUpdated extends AvailabilityEvent {
  final String residenceId;
  final String availabilityId;
  final double price;

  const AvailabilityPriceUpdated({
    required this.residenceId,
    required this.availabilityId,
    required this.price,
  });

  @override
  List<Object?> get props => [residenceId, availabilityId, price];
}

class BulkAvailabilitiesCreated extends AvailabilityEvent {
  final String residenceId;
  final List<Map<String, dynamic>> availabilities;

  const BulkAvailabilitiesCreated({
    required this.residenceId,
    required this.availabilities,
  });

  @override
  List<Object?> get props => [residenceId, availabilities];
}

// States
abstract class AvailabilityState extends Equatable {
  const AvailabilityState();

  @override
  List<Object?> get props => [];
}

class AvailabilityInitial extends AvailabilityState {}

class AvailabilityLoading extends AvailabilityState {}

class AvailabilityLoaded extends AvailabilityState {
  final List<Availability> availabilities;

  const AvailabilityLoaded({required this.availabilities});

  @override
  List<Object?> get props => [availabilities];
}

class AvailabilityError extends AvailabilityState {
  final String message;

  const AvailabilityError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Bloc
class AvailabilityBloc extends Bloc<AvailabilityEvent, AvailabilityState> {
  final AvailabilityService _availabilityService;

  AvailabilityBloc({required AvailabilityService availabilityService})
      : _availabilityService = availabilityService,
        super(AvailabilityInitial()) {
    on<AvailabilitiesFetched>(_onAvailabilitiesFetched);
    on<AvailabilityCreated>(_onAvailabilityCreated);
    on<AvailabilityUpdated>(_onAvailabilityUpdated);
    on<AvailabilityDeleted>(_onAvailabilityDeleted);
    on<AvailabilityStatusUpdated>(_onAvailabilityStatusUpdated);
    on<AvailabilityPriceUpdated>(_onAvailabilityPriceUpdated);
    on<BulkAvailabilitiesCreated>(_onBulkAvailabilitiesCreated);
  }

  Future<void> _onAvailabilitiesFetched(
    AvailabilitiesFetched event,
    Emitter<AvailabilityState> emit,
  ) async {
    try {
      emit(AvailabilityLoading());
      final availabilities = await _availabilityService.getAvailabilities(
        event.residenceId,
      );
      emit(AvailabilityLoaded(availabilities: availabilities));
    } catch (e) {
      emit(AvailabilityError(message: e.toString()));
    }
  }

  Future<void> _onAvailabilityCreated(
    AvailabilityCreated event,
    Emitter<AvailabilityState> emit,
  ) async {
    try {
      if (state is AvailabilityLoaded) {
        final currentState = state as AvailabilityLoaded;
        final newAvailability = await _availabilityService.createAvailability(
          event.residenceId,
          event.data,
        );
        emit(AvailabilityLoaded(
          availabilities: [...currentState.availabilities, newAvailability],
        ));
      }
    } catch (e) {
      emit(AvailabilityError(message: e.toString()));
    }
  }

  Future<void> _onAvailabilityUpdated(
    AvailabilityUpdated event,
    Emitter<AvailabilityState> emit,
  ) async {
    try {
      if (state is AvailabilityLoaded) {
        final currentState = state as AvailabilityLoaded;
        final updatedAvailability = await _availabilityService.updateAvailability(
          event.residenceId,
          event.availabilityId,
          event.data,
        );
        final updatedAvailabilities = currentState.availabilities.map(
          (availability) => availability.id == event.availabilityId
              ? updatedAvailability
              : availability,
        ).toList();
        emit(AvailabilityLoaded(availabilities: updatedAvailabilities));
      }
    } catch (e) {
      emit(AvailabilityError(message: e.toString()));
    }
  }

  Future<void> _onAvailabilityDeleted(
    AvailabilityDeleted event,
    Emitter<AvailabilityState> emit,
  ) async {
    try {
      if (state is AvailabilityLoaded) {
        final currentState = state as AvailabilityLoaded;
        await _availabilityService.deleteAvailability(
          event.residenceId,
          event.availabilityId,
        );
        final updatedAvailabilities = currentState.availabilities
            .where((availability) => availability.id != event.availabilityId)
            .toList();
        emit(AvailabilityLoaded(availabilities: updatedAvailabilities));
      }
    } catch (e) {
      emit(AvailabilityError(message: e.toString()));
    }
  }

  Future<void> _onAvailabilityStatusUpdated(
    AvailabilityStatusUpdated event,
    Emitter<AvailabilityState> emit,
  ) async {
    try {
      if (state is AvailabilityLoaded) {
        final currentState = state as AvailabilityLoaded;
        final updatedAvailability = await _availabilityService.updateAvailabilityStatus(
          event.residenceId,
          event.availabilityId,
          event.status,
        );
        final updatedAvailabilities = currentState.availabilities.map(
          (availability) => availability.id == event.availabilityId
              ? updatedAvailability
              : availability,
        ).toList();
        emit(AvailabilityLoaded(availabilities: updatedAvailabilities));
      }
    } catch (e) {
      emit(AvailabilityError(message: e.toString()));
    }
  }

  Future<void> _onAvailabilityPriceUpdated(
    AvailabilityPriceUpdated event,
    Emitter<AvailabilityState> emit,
  ) async {
    try {
      if (state is AvailabilityLoaded) {
        final currentState = state as AvailabilityLoaded;
        final updatedAvailability = await _availabilityService.updateAvailabilityPrice(
          event.residenceId,
          event.availabilityId,
          event.price,
        );
        final updatedAvailabilities = currentState.availabilities.map(
          (availability) => availability.id == event.availabilityId
              ? updatedAvailability
              : availability,
        ).toList();
        emit(AvailabilityLoaded(availabilities: updatedAvailabilities));
      }
    } catch (e) {
      emit(AvailabilityError(message: e.toString()));
    }
  }

  Future<void> _onBulkAvailabilitiesCreated(
    BulkAvailabilitiesCreated event,
    Emitter<AvailabilityState> emit,
  ) async {
    try {
      if (state is AvailabilityLoaded) {
        final currentState = state as AvailabilityLoaded;
        final newAvailabilities = await _availabilityService.createBulkAvailabilities(
          event.residenceId,
          event.availabilities,
        );
        emit(AvailabilityLoaded(
          availabilities: [...currentState.availabilities, ...newAvailabilities],
        ));
      }
    } catch (e) {
      emit(AvailabilityError(message: e.toString()));
    }
  }
}
