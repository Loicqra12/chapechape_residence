import 'package:intl/intl.dart';

class Booking {
  final String id;
  final String userId;
  final String residenceId;
  final String residenceName;
  final DateTime checkIn;
  final DateTime checkOut;
  final int numberOfGuests;
  final double totalPrice;
  final String status;
  final String? paymentId;
  final String? paymentStatus;
  final String? cancellationReason;
  final String? specialRequests;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Map<String, dynamic>>? modifications;
  final String cancellationPolicyId;

  Booking({
    required this.id,
    required this.userId,
    required this.residenceId,
    required this.residenceName,
    required this.checkIn,
    required this.checkOut,
    required this.numberOfGuests,
    required this.totalPrice,
    this.status = 'pending',
    this.paymentId,
    this.paymentStatus,
    this.cancellationReason,
    this.specialRequests,
    this.createdAt,
    this.updatedAt,
    this.modifications,
    required this.cancellationPolicyId,
  });

  int get nights {
    return checkOut.difference(checkIn).inDays;
  }

  bool get isPaid {
    return paymentStatus == 'paid' || paymentStatus == 'completed' || paymentStatus == 'succeeded';
  }

  Booking copyWith({
    String? id,
    String? userId,
    String? residenceId,
    String? residenceName,
    DateTime? checkIn,
    DateTime? checkOut,
    int? numberOfGuests,
    double? totalPrice,
    String? status,
    String? paymentId,
    String? paymentStatus,
    String? cancellationReason,
    String? specialRequests,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Map<String, dynamic>>? modifications,
    String? cancellationPolicyId,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      residenceId: residenceId ?? this.residenceId,
      residenceName: residenceName ?? this.residenceName,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      numberOfGuests: numberOfGuests ?? this.numberOfGuests,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      paymentId: paymentId ?? this.paymentId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      specialRequests: specialRequests ?? this.specialRequests,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      modifications: modifications ?? this.modifications,
      cancellationPolicyId: cancellationPolicyId ?? this.cancellationPolicyId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'residence': residenceId,
      'residenceName': residenceName,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'numberOfGuests': numberOfGuests,
      'status': status,
      'totalPrice': totalPrice,
      'paymentId': paymentId,
      'paymentStatus': paymentStatus,
      'cancellationReason': cancellationReason,
      'specialRequests': specialRequests,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'modifications': modifications,
      'cancellationPolicyId': cancellationPolicyId,
    };
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] as String,
      userId: json['user'] ?? json['userId'] ?? '',
      residenceId: json['residence'] as String,
      residenceName: json['residenceName'] as String? ?? 'Résidence',
      checkIn: DateTime.parse(json['checkIn'] as String),
      checkOut: DateTime.parse(json['checkOut'] as String),
      numberOfGuests: json['numberOfGuests'] as int,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      status: json['status'] as String,
      paymentId: json['paymentId'],
      paymentStatus: json['paymentStatus'] ?? 'pending',
      cancellationReason: json['cancellationReason'] ?? json['reason'],
      specialRequests: json['specialRequests'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      modifications: json['modifications'] != null
          ? List<Map<String, dynamic>>.from(json['modifications'] as List)
          : null,
      cancellationPolicyId: json['cancellationPolicyId'] as String,
    );
  }
}