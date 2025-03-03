import 'package:equatable/equatable.dart';

enum AvailabilityStatus {
  available,
  booked,
  blocked,
}

class Availability extends Equatable {
  final String id;
  final String residenceId;
  final DateTime startDate;
  final DateTime endDate;
  final AvailabilityStatus status;
  final double price;
  final String? bookingId;
  final String? note;

  const Availability({
    required this.id,
    required this.residenceId,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.price,
    this.bookingId,
    this.note,
  });

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      id: json['_id'] ?? '',
      residenceId: json['residenceId'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      status: AvailabilityStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => AvailabilityStatus.available,
      ),
      price: (json['price'] ?? 0.0).toDouble(),
      bookingId: json['bookingId'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'residenceId': residenceId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'price': price,
      'bookingId': bookingId,
      'note': note,
    };
  }

  @override
  List<Object?> get props => [
        id,
        residenceId,
        startDate,
        endDate,
        status,
        price,
        bookingId,
        note,
      ];
}
