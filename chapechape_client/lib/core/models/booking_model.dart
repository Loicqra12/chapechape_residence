import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking_model.freezed.dart';
part 'booking_model.g.dart';

@freezed
class Booking with _$Booking {
  const factory Booking({
    required String id,
    required String userId,
    required String residenceId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int numberOfGuests,
    required double totalPrice,
    @Default('pending') String status,
    String? paymentId,
    String? paymentStatus,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Booking;

  factory Booking.fromJson(Map<String, dynamic> json) => _$BookingFromJson(json);
}