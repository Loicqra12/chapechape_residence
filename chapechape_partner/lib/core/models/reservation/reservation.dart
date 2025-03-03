import 'package:intl/intl.dart';

enum ReservationStatus {
  pending,
  confirmed,
  cancelled,
  completed;

  String get displayName {
    switch (this) {
      case ReservationStatus.pending:
        return 'En attente';
      case ReservationStatus.confirmed:
        return 'Confirmée';
      case ReservationStatus.cancelled:
        return 'Annulée';
      case ReservationStatus.completed:
        return 'Terminée';
    }
  }

  String get color {
    switch (this) {
      case ReservationStatus.pending:
        return '#FFA726';
      case ReservationStatus.confirmed:
        return '#66BB6A';
      case ReservationStatus.cancelled:
        return '#EF5350';
      case ReservationStatus.completed:
        return '#42A5F5';
    }
  }
}

class Reservation {
  final String id;
  final String residenceId;
  final String residenceName;
  final String residenceImage;
  final String clientName;
  final String clientPhone;
  final DateTime checkIn;
  final DateTime checkOut;
  final double totalAmount;
  final ReservationStatus status;
  final DateTime createdAt;
  final int guestsCount;
  final String? notes;

  const Reservation({
    required this.id,
    required this.residenceId,
    required this.residenceName,
    required this.residenceImage,
    required this.clientName,
    required this.clientPhone,
    required this.checkIn,
    required this.checkOut,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.guestsCount,
    this.notes,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] as String,
      residenceId: json['residence_id'] as String,
      residenceName: json['residence_name'] as String,
      residenceImage: json['residence_image'] as String,
      clientName: json['client_name'] as String,
      clientPhone: json['client_phone'] as String,
      checkIn: DateTime.parse(json['check_in'] as String),
      checkOut: DateTime.parse(json['check_out'] as String),
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: ReservationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReservationStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      guestsCount: json['guests_count'] as int,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'residence_id': residenceId,
      'residence_name': residenceName,
      'residence_image': residenceImage,
      'client_name': clientName,
      'client_phone': clientPhone,
      'check_in': checkIn.toIso8601String(),
      'check_out': checkOut.toIso8601String(),
      'total_amount': totalAmount,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'guests_count': guestsCount,
      'notes': notes,
    };
  }
}

extension ReservationProperties on Reservation {
  String get formattedTotalAmount {
    final format = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    return format.format(totalAmount);
  }

  String get formattedDates {
    final format = DateFormat('dd MMM', 'fr_FR');
    return '${format.format(checkIn)} - ${format.format(checkOut)}';
  }

  String get formattedCreatedAt {
    final format = DateFormat('dd MMM yyyy à HH:mm', 'fr_FR');
    return format.format(createdAt);
  }

  int get durationInDays {
    return checkOut.difference(checkIn).inDays;
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return checkIn.isAfter(now);
  }

  bool get isOngoing {
    final now = DateTime.now();
    return checkIn.isBefore(now) && checkOut.isAfter(now);
  }
}
