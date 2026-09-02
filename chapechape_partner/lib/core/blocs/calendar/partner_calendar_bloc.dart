import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/calendar/partner_calendar.dart';
import '../../services/api/partner_calendar_service.dart';
import '../../utils/calendar_error_mapper.dart';
import 'partner_calendar_event.dart';
import 'partner_calendar_state.dart';

class PartnerCalendarBloc extends Bloc<PartnerCalendarEvent, PartnerCalendarState> {
  final PartnerCalendarService _service;
  String? _residenceId;
  String? _pendingBanner;

  PartnerCalendarBloc({required PartnerCalendarService service})
      : _service = service,
        super(const PartnerCalendarInitial()) {
    on<PartnerCalendarStarted>(_onStarted);
    on<PartnerCalendarMonthChanged>(_onMonthChanged);
    on<PartnerCalendarRefreshed>(_onRefreshed);
    on<PartnerCalendarSocketPinged>(_onRefreshed);
    on<PartnerCalendarDaySelected>(_onDaySelected);
    on<PartnerCalendarRangeSelected>(_onRangeSelected);
    on<PartnerCalendarOccupationSelected>(_onOccupationSelected);
    on<PartnerCalendarSelectionCleared>(_onSelectionCleared);
    on<PartnerCalendarBlockRequested>(_onBlock);
    on<PartnerCalendarUnblockRequested>(_onUnblock);
    on<PartnerCalendarExternalRequested>(_onExternal);
    on<PartnerCalendarExternalCancelled>(_onCancelExternal);
    on<PartnerCalendarExternalCompleted>(_onCompleteExternal);
    on<PartnerCalendarExternalUpdated>(_onUpdateExternal);
  }

  DateTime _monthStart(DateTime month) => DateTime.utc(month.year, month.month, 1);
  DateTime _monthEnd(DateTime month) => DateTime.utc(month.year, month.month + 1, 1);

  Future<void> _onStarted(
    PartnerCalendarStarted event,
    Emitter<PartnerCalendarState> emit,
  ) async {
    _residenceId = event.residenceId;
    emit(const PartnerCalendarLoading());
    try {
      final calendar = await _service.getPartnerCalendar(
        residenceId: event.residenceId,
        start: _monthStart(event.month),
        end: _monthEnd(event.month),
      );
      emit(PartnerCalendarLoaded(
        calendar: calendar,
        focusedMonth: _monthStart(event.month),
      ));
    } catch (error) {
      emit(PartnerCalendarError(error.toString()));
    }
  }

  Future<void> _onMonthChanged(
    PartnerCalendarMonthChanged event,
    Emitter<PartnerCalendarState> emit,
  ) async {
    final residenceId = _residenceId;
    if (residenceId == null) return;
    final nextMonth = _monthStart(event.month);
    final current = state;
    if (current is PartnerCalendarLoaded &&
        current.focusedMonth.year == nextMonth.year &&
        current.focusedMonth.month == nextMonth.month) {
      return;
    }
    emit(const PartnerCalendarLoading());
    try {
      final calendar = await _service.getPartnerCalendar(
        residenceId: residenceId,
        start: nextMonth,
        end: _monthEnd(event.month),
      );
      emit(PartnerCalendarLoaded(
        calendar: calendar,
        focusedMonth: nextMonth,
      ));
    } catch (error) {
      emit(PartnerCalendarError(error.toString()));
    }
  }

  Future<void> _onRefreshed(
    PartnerCalendarEvent event,
    Emitter<PartnerCalendarState> emit,
  ) async {
    final current = state;
    final residenceId = _residenceId;
    if (residenceId == null) return;
    final month = current is PartnerCalendarLoaded
        ? current.focusedMonth
        : DateTime.now().toUtc();
    try {
      final calendar = await _service.getPartnerCalendar(
        residenceId: residenceId,
        start: _monthStart(month),
        end: _monthEnd(month),
      );
      if (current is PartnerCalendarLoaded) {
        emit(current.copyWith(
          calendar: calendar,
          mutating: false,
          bannerMessage: _pendingBanner,
          clearBanner: _pendingBanner == null,
        ));
        _pendingBanner = null;
      } else {
        emit(PartnerCalendarLoaded(calendar: calendar, focusedMonth: _monthStart(month)));
      }
    } catch (error) {
      emit(PartnerCalendarError(error.toString()));
    }
  }

  void _onDaySelected(
    PartnerCalendarDaySelected event,
    Emitter<PartnerCalendarState> emit,
  ) {
    final current = state;
    if (current is! PartnerCalendarLoaded) return;
    final day = DateTime.utc(event.day.year, event.day.month, event.day.day);
    emit(current.copyWith(
      selectedDay: day,
      rangeStart: day,
      rangeEnd: day.add(const Duration(days: 1)),
      clearOccupation: true,
      clearBanner: true,
    ));
  }

  void _onRangeSelected(
    PartnerCalendarRangeSelected event,
    Emitter<PartnerCalendarState> emit,
  ) {
    final current = state;
    if (current is! PartnerCalendarLoaded) return;
    final start = DateTime.utc(event.start.year, event.start.month, event.start.day);
    final end = event.end.toUtc();
    emit(current.copyWith(
      rangeStart: start,
      rangeEnd: end.isAfter(start) ? end : start.add(const Duration(days: 1)),
      selectedDay: start,
      clearOccupation: true,
      clearBanner: true,
    ));
  }

  void _onOccupationSelected(
    PartnerCalendarOccupationSelected event,
    Emitter<PartnerCalendarState> emit,
  ) {
    final current = state;
    if (current is! PartnerCalendarLoaded) return;
    PartnerOccupation? found;
    for (final occ in current.calendar.occupations) {
      if (occ.id == event.occupationId) {
        found = occ;
        break;
      }
    }
    emit(current.copyWith(selectedOccupation: found, clearBanner: true));
  }

  void _onSelectionCleared(
    PartnerCalendarSelectionCleared event,
    Emitter<PartnerCalendarState> emit,
  ) {
    final current = state;
    if (current is! PartnerCalendarLoaded) return;
    emit(current.copyWith(clearOccupation: true, clearRange: true, clearBanner: true));
  }

  Future<void> _mutate({
    required Emitter<PartnerCalendarState> emit,
    required String action,
    required Future<void> Function() run,
  }) async {
    final current = state;
    if (current is! PartnerCalendarLoaded) return;
    emit(current.copyWith(mutating: true, clearBanner: true));
    try {
      await run();
      add(const PartnerCalendarRefreshed());
    } catch (error) {
      _pendingBanner = CalendarErrorMapper.messageFor(error, action: action);
      emit(current.copyWith(mutating: false, bannerMessage: _pendingBanner));
      add(const PartnerCalendarRefreshed());
    }
  }

  Future<void> _onBlock(
    PartnerCalendarBlockRequested event,
    Emitter<PartnerCalendarState> emit,
  ) async {
    final residenceId = _residenceId;
    if (residenceId == null) return;
    await _mutate(
      emit: emit,
      action: 'block',
      run: () => _service.createBlock(
        residenceId: residenceId,
        start: event.start,
        end: event.end,
        bookingType: event.bookingType,
        type: event.type,
        reason: event.reason,
      ),
    );
  }

  Future<void> _onUnblock(
    PartnerCalendarUnblockRequested event,
    Emitter<PartnerCalendarState> emit,
  ) async {
    await _mutate(
      emit: emit,
      action: 'unblock',
      run: () => _service.releaseBlock(event.blockId),
    );
  }

  Future<void> _onExternal(
    PartnerCalendarExternalRequested event,
    Emitter<PartnerCalendarState> emit,
  ) async {
    final residenceId = _residenceId;
    if (residenceId == null) return;
    await _mutate(
      emit: emit,
      action: 'external',
      run: () => _service.createExternal(
        residenceId: residenceId,
        checkIn: event.checkIn,
        checkOut: event.checkOut,
        bookingType: event.bookingType,
        channel: event.channel,
        guestName: event.guestName,
        guestPhone: event.guestPhone,
        notes: event.notes,
      ),
    );
  }

  Future<void> _onCancelExternal(
    PartnerCalendarExternalCancelled event,
    Emitter<PartnerCalendarState> emit,
  ) async {
    await _mutate(
      emit: emit,
      action: 'external',
      run: () => _service.cancelExternal(event.id),
    );
  }

  Future<void> _onCompleteExternal(
    PartnerCalendarExternalCompleted event,
    Emitter<PartnerCalendarState> emit,
  ) async {
    await _mutate(
      emit: emit,
      action: 'external',
      run: () => _service.completeExternal(event.id),
    );
  }

  Future<void> _onUpdateExternal(
    PartnerCalendarExternalUpdated event,
    Emitter<PartnerCalendarState> emit,
  ) async {
    await _mutate(
      emit: emit,
      action: 'external',
      run: () => _service.updateExternal(
        id: event.id,
        checkIn: event.checkIn,
        checkOut: event.checkOut,
        channel: event.channel,
        guestName: event.guestName,
        guestPhone: event.guestPhone,
        notes: event.notes,
      ),
    );
  }
}
