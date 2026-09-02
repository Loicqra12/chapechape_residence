import 'package:equatable/equatable.dart';

enum CalendarSourceType {
  reservation,
  manualBlock,
  externalReservation,
  unknown,
}

enum CalendarOccupationStatus { reserved, blocked, unavailable }

/// Actions UI dérivées de [sourceType] — jamais d'inventaire local.
enum PartnerCalendarAction {
  createBlock,
  createExternal,
  viewReservation,
  unblock,
  viewBlock,
  viewExternal,
  editExternal,
  cancelExternal,
  completeExternal,
}

class PartnerOccupation extends Equatable {
  final String id;
  final CalendarSourceType sourceType;
  final CalendarOccupationStatus status;
  final DateTime start;
  final DateTime end;
  final String bookingType;
  final String? blockType;
  final String? reservationStatus;
  final DateTime? hostApprovalDeadline;
  final String? channel;
  final String? guestName;
  final String? guestPhone;
  final String? externalReference;
  final String? notes;

  const PartnerOccupation({
    required this.id,
    required this.sourceType,
    required this.status,
    required this.start,
    required this.end,
    required this.bookingType,
    this.blockType,
    this.reservationStatus,
    this.hostApprovalDeadline,
    this.channel,
    this.guestName,
    this.guestPhone,
    this.externalReference,
    this.notes,
  });

  bool get isHour => bookingType == 'hour';
  bool get isAwaitingApproval => reservationStatus == 'awaiting_approval';

  factory PartnerOccupation.fromJson(Map<String, dynamic> json) {
    return PartnerOccupation(
      id: json['id']?.toString() ?? '',
      sourceType: _parseSource(json['sourceType']?.toString()),
      status: _parseStatus(json['status']?.toString()),
      start: DateTime.parse(json['start'].toString()).toUtc(),
      end: DateTime.parse(json['end'].toString()).toUtc(),
      bookingType: json['bookingType']?.toString() ?? 'day',
      blockType: json['blockType']?.toString(),
      reservationStatus: json['reservationStatus']?.toString(),
      hostApprovalDeadline: json['hostApprovalDeadline'] != null
          ? DateTime.parse(json['hostApprovalDeadline'].toString()).toUtc()
          : null,
      channel: json['channel']?.toString(),
      guestName: json['guestName']?.toString(),
      guestPhone: json['guestPhone']?.toString(),
      externalReference: json['externalReference']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  static CalendarSourceType _parseSource(String? value) {
    switch (value) {
      case 'reservation':
        return CalendarSourceType.reservation;
      case 'manual_block':
        return CalendarSourceType.manualBlock;
      case 'external_reservation':
        return CalendarSourceType.externalReservation;
      default:
        return CalendarSourceType.unknown;
    }
  }

  static CalendarOccupationStatus _parseStatus(String? value) {
    switch (value) {
      case 'blocked':
        return CalendarOccupationStatus.blocked;
      case 'unavailable':
        return CalendarOccupationStatus.unavailable;
      default:
        return CalendarOccupationStatus.reserved;
    }
  }

  @override
  List<Object?> get props => [id, sourceType, start, end, bookingType];
}

class PartnerCalendarDay extends Equatable {
  final String date;
  /// Disponibilité pour une occupation **journée entière**, pas « aucune minute occupée ».
  /// Un block hour 13:00→15:00 rend `available == false`. L'heure se lit dans [slots].
  final bool available;
  final String availableMeaning;
  final List<PartnerOccupation> slots;

  const PartnerCalendarDay({
    required this.date,
    required this.available,
    this.availableMeaning = 'full_day',
    this.slots = const [],
  });

  DateTime get utcDate => DateTime.parse('${date}T00:00:00.000Z');

  factory PartnerCalendarDay.fromJson(Map<String, dynamic> json) {
    final rawSlots = json['slots'] as List<dynamic>? ?? const [];
    return PartnerCalendarDay(
      date: json['date']?.toString() ?? '',
      available: json['available'] == true,
      availableMeaning: json['availableMeaning']?.toString() ?? 'full_day',
      slots: rawSlots
          .whereType<Map>()
          .map((slot) => PartnerOccupation.fromJson(
                Map<String, dynamic>.from(slot),
              ))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [date, available, availableMeaning, slots];
}

class PartnerCalendar extends Equatable {
  final String residenceId;
  final String timezone;
  final DateTime start;
  final DateTime end;
  final List<PartnerOccupation> occupations;
  final List<PartnerCalendarDay> days;

  const PartnerCalendar({
    required this.residenceId,
    required this.timezone,
    required this.start,
    required this.end,
    required this.occupations,
    required this.days,
  });

  factory PartnerCalendar.fromJson(Map<String, dynamic> json) {
    final occupations = (json['occupations'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => PartnerOccupation.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final days = (json['days'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => PartnerCalendarDay.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return PartnerCalendar(
      residenceId: json['residenceId']?.toString() ?? '',
      timezone: json['timezone']?.toString() ?? 'Africa/Abidjan',
      start: DateTime.parse(json['start'].toString()).toUtc(),
      end: DateTime.parse(json['end'].toString()).toUtc(),
      occupations: occupations,
      days: days,
    );
  }

  PartnerCalendarDay? dayFor(DateTime day) {
    final key =
        '${day.toUtc().year.toString().padLeft(4, '0')}-${day.toUtc().month.toString().padLeft(2, '0')}-${day.toUtc().day.toString().padLeft(2, '0')}';
    try {
      return days.firstWhere((d) => d.date == key);
    } catch (_) {
      return null;
    }
  }

  List<PartnerOccupation> occupationsOn(DateTime day) {
    final start = DateTime.utc(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return occupations
        .where((occ) => occ.start.isBefore(end) && occ.end.isAfter(start))
        .toList();
  }

  @override
  List<Object?> get props => [residenceId, start, end, occupations, days];
}

/// Politique d'actions : projection de sourceType, pas de logique d'inventaire.
class PartnerCalendarActionPolicy {
  static List<PartnerCalendarAction> forEmptySelection() => const [
        PartnerCalendarAction.createBlock,
        PartnerCalendarAction.createExternal,
      ];

  static List<PartnerCalendarAction> forOccupation(PartnerOccupation occupation) {
    switch (occupation.sourceType) {
      case CalendarSourceType.reservation:
        return const [PartnerCalendarAction.viewReservation];
      case CalendarSourceType.manualBlock:
        return const [
          PartnerCalendarAction.viewBlock,
          PartnerCalendarAction.unblock,
        ];
      case CalendarSourceType.externalReservation:
        return const [
          PartnerCalendarAction.viewExternal,
          PartnerCalendarAction.editExternal,
          PartnerCalendarAction.cancelExternal,
          PartnerCalendarAction.completeExternal,
        ];
      case CalendarSourceType.unknown:
        return const [];
    }
  }

  static bool canUnblock(PartnerOccupation occupation) {
    return occupation.sourceType == CalendarSourceType.manualBlock;
  }
}
