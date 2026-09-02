import 'package:equatable/equatable.dart';

abstract class PartnerCalendarEvent extends Equatable {
  const PartnerCalendarEvent();

  @override
  List<Object?> get props => [];
}

class PartnerCalendarStarted extends PartnerCalendarEvent {
  final String residenceId;
  final DateTime month;
  const PartnerCalendarStarted({required this.residenceId, required this.month});

  @override
  List<Object?> get props => [residenceId, month];
}

class PartnerCalendarMonthChanged extends PartnerCalendarEvent {
  final DateTime month;
  const PartnerCalendarMonthChanged(this.month);
  @override
  List<Object?> get props => [month];
}

class PartnerCalendarRefreshed extends PartnerCalendarEvent {
  const PartnerCalendarRefreshed();
}

class PartnerCalendarSocketPinged extends PartnerCalendarEvent {
  const PartnerCalendarSocketPinged();
}

class PartnerCalendarDaySelected extends PartnerCalendarEvent {
  final DateTime day;
  const PartnerCalendarDaySelected(this.day);
  @override
  List<Object?> get props => [day];
}

class PartnerCalendarRangeSelected extends PartnerCalendarEvent {
  final DateTime start;
  final DateTime end;
  const PartnerCalendarRangeSelected({required this.start, required this.end});
  @override
  List<Object?> get props => [start, end];
}

class PartnerCalendarOccupationSelected extends PartnerCalendarEvent {
  final String occupationId;
  const PartnerCalendarOccupationSelected(this.occupationId);
  @override
  List<Object?> get props => [occupationId];
}

class PartnerCalendarSelectionCleared extends PartnerCalendarEvent {
  const PartnerCalendarSelectionCleared();
}

class PartnerCalendarBlockRequested extends PartnerCalendarEvent {
  final DateTime start;
  final DateTime end;
  final String bookingType;
  final String type;
  final String reason;
  const PartnerCalendarBlockRequested({
    required this.start,
    required this.end,
    this.bookingType = 'day',
    this.type = 'other',
    this.reason = '',
  });
}

class PartnerCalendarUnblockRequested extends PartnerCalendarEvent {
  final String blockId;
  const PartnerCalendarUnblockRequested(this.blockId);
  @override
  List<Object?> get props => [blockId];
}

class PartnerCalendarExternalRequested extends PartnerCalendarEvent {
  final DateTime checkIn;
  final DateTime checkOut;
  final String bookingType;
  final String channel;
  final String guestName;
  final String guestPhone;
  final String notes;
  const PartnerCalendarExternalRequested({
    required this.checkIn,
    required this.checkOut,
    this.bookingType = 'day',
    this.channel = 'other',
    this.guestName = '',
    this.guestPhone = '',
    this.notes = '',
  });
}

class PartnerCalendarExternalCancelled extends PartnerCalendarEvent {
  final String id;
  const PartnerCalendarExternalCancelled(this.id);
  @override
  List<Object?> get props => [id];
}

class PartnerCalendarExternalCompleted extends PartnerCalendarEvent {
  final String id;
  const PartnerCalendarExternalCompleted(this.id);
  @override
  List<Object?> get props => [id];
}

class PartnerCalendarExternalUpdated extends PartnerCalendarEvent {
  final String id;
  final DateTime checkIn;
  final DateTime checkOut;
  final String channel;
  final String guestName;
  final String guestPhone;
  final String notes;
  const PartnerCalendarExternalUpdated({
    required this.id,
    required this.checkIn,
    required this.checkOut,
    this.channel = 'other',
    this.guestName = '',
    this.guestPhone = '',
    this.notes = '',
  });
  @override
  List<Object?> get props => [id, checkIn, checkOut];
}
