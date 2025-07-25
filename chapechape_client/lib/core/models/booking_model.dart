import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // Import pour debugPrint

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
    // Vérifier si les données sont imbriquées dans un objet 'data'
    final Map<String, dynamic> data = json.containsKey('data') ? json['data'] as Map<String, dynamic> : json;
    
    // Déboguer la réponse pour identifier les champs qui pourraient être null
    debugPrint('Désérialisation réservation avec données: $data');
    
    // Extraction sécurisée des champs avec gestion des null pour éviter les erreurs de cast
    final String idValue = data['_id']?.toString() ?? '';
    final String userIdValue = data['user']?.toString() ?? data['userId']?.toString() ?? '';
    final String residenceIdValue = data['residence']?.toString() ?? '';
    final String residenceNameValue = data['residenceName']?.toString() ?? 'Résidence';
    final String statusValue = data['status']?.toString() ?? 'pending';
    final String? paymentIdValue = data['paymentId']?.toString();
    final String? paymentStatusValue = data['paymentStatus']?.toString() ?? 'pending';
    final String? cancellationReasonValue = 
      data['cancellationReason'] == null ? null : data['cancellationReason'].toString();
    final String? specialRequestsValue = 
      data['specialRequests'] == null ? null : data['specialRequests'].toString();
    
    // Gestion prudente du champ cancellationPolicy qui peut être null ou avoir un format différent
    String cancellationPolicyIdValue = '';
    if (data['cancellationPolicy'] != null) {
      cancellationPolicyIdValue = data['cancellationPolicy'] is Map 
        ? data['cancellationPolicy']['_id']?.toString() ?? ''
        : data['cancellationPolicy'].toString();
    } else if (data['cancellationPolicyId'] != null) {
      cancellationPolicyIdValue = data['cancellationPolicyId'].toString();
    }
    
    return Booking(
      id: idValue,
      userId: userIdValue,
      residenceId: residenceIdValue,
      residenceName: residenceNameValue,
      checkIn: data['checkIn'] != null ? DateTime.parse(data['checkIn'] as String) : DateTime.now(),
      checkOut: data['checkOut'] != null ? DateTime.parse(data['checkOut'] as String) : DateTime.now().add(const Duration(days: 1)),
      numberOfGuests: data['numberOfGuests'] != null ? (data['numberOfGuests'] as num).toInt() : 1,
      totalPrice: data['totalPrice'] != null ? (data['totalPrice'] as num).toDouble() : 0.0,
      status: statusValue,
      paymentId: paymentIdValue,
      paymentStatus: paymentStatusValue,
      cancellationReason: cancellationReasonValue,
      specialRequests: specialRequestsValue,
      createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt'] as String) : null,
      updatedAt: data['updatedAt'] != null ? DateTime.parse(data['updatedAt'] as String) : null,
      modifications: data['modifications'] != null
          ? List<Map<String, dynamic>>.from(
              (data['modifications'] as List<dynamic>).map(
                (item) => (item as Map<dynamic, dynamic>).cast<String, dynamic>(),
              ),
            )
          : <Map<String, dynamic>>[],
      cancellationPolicyId: cancellationPolicyIdValue,
    );
  }
}