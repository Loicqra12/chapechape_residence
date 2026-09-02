import 'package:equatable/equatable.dart';
import '../../models/calendar/partner_calendar.dart';

abstract class PartnerCalendarState extends Equatable {
  const PartnerCalendarState();
  @override
  List<Object?> get props => [];
}

class PartnerCalendarInitial extends PartnerCalendarState {
  const PartnerCalendarInitial();
}

class PartnerCalendarLoading extends PartnerCalendarState {
  const PartnerCalendarLoading();
}

class PartnerCalendarLoaded extends PartnerCalendarState {
  final PartnerCalendar calendar;
  final DateTime focusedMonth;
  final DateTime? selectedDay;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final PartnerOccupation? selectedOccupation;
  final String? bannerMessage;
  final bool mutating;

  const PartnerCalendarLoaded({
    required this.calendar,
    required this.focusedMonth,
    this.selectedDay,
    this.rangeStart,
    this.rangeEnd,
    this.selectedOccupation,
    this.bannerMessage,
    this.mutating = false,
  });

  PartnerCalendarLoaded copyWith({
    PartnerCalendar? calendar,
    DateTime? focusedMonth,
    DateTime? selectedDay,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    PartnerOccupation? selectedOccupation,
    String? bannerMessage,
    bool clearBanner = false,
    bool clearOccupation = false,
    bool clearRange = false,
    bool? mutating,
  }) {
    return PartnerCalendarLoaded(
      calendar: calendar ?? this.calendar,
      focusedMonth: focusedMonth ?? this.focusedMonth,
      selectedDay: selectedDay ?? this.selectedDay,
      rangeStart: clearRange ? null : (rangeStart ?? this.rangeStart),
      rangeEnd: clearRange ? null : (rangeEnd ?? this.rangeEnd),
      selectedOccupation:
          clearOccupation ? null : (selectedOccupation ?? this.selectedOccupation),
      bannerMessage: clearBanner ? null : (bannerMessage ?? this.bannerMessage),
      mutating: mutating ?? this.mutating,
    );
  }

  @override
  List<Object?> get props => [
        calendar,
        focusedMonth,
        selectedDay,
        rangeStart,
        rangeEnd,
        selectedOccupation,
        bannerMessage,
        mutating,
      ];
}

class PartnerCalendarError extends PartnerCalendarState {
  final String message;
  const PartnerCalendarError(this.message);
  @override
  List<Object?> get props => [message];
}
