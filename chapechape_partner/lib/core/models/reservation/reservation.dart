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
    // Vérification préliminaire des valeurs nulles
    final Map<String, dynamic> data = json;
    
    // Extraire l'ID de la résidence (peut être sous différentes formes)
    final residenceId = data['residence_id'] ?? 
                       (data['residence'] is Map ? data['residence']['_id'] : data['residence'])?.toString() ?? '';
    
    // Extraire le nom de la résidence
    final residenceName = data['residence_name'] ?? 
                         (data['residence'] is Map ? data['residence']['title'] : null) ??
                         data['residenceName'] ?? 'Résidence';
    
    // Extraire l'image de la résidence
    final residenceImage = data['residence_image'] ?? 
                          (data['residence'] is Map && data['residence']['images'] is List && data['residence']['images'].isNotEmpty
                              ? data['residence']['images'][0]
                              : 'https://via.placeholder.com/600x400?text=ChapeChape+Residence');
    
    // Extraire les informations du client
    final clientName = data['client_name'] ?? 
                      (data['user'] is Map 
                           ? "${data['user']['firstName'] ?? ''} ${data['user']['lastName'] ?? ''}"
                           : data['clientName'] ?? 'Client');
    
    final clientPhone = data['client_phone'] ?? 
                       (data['user'] is Map ? data['user']['phoneNumber'] : null) ??
                       data['clientPhone'] ?? 'Non renseigné';
    
    // Extraire le nombre de personnes (guests)
    final guestsCount = data['guests_count'] != null 
        ? (data['guests_count'] as num).toInt() 
        : (data['numberOfGuests'] != null 
            ? (data['numberOfGuests'] as num).toInt() 
            : (data['guestsCount'] as num?)?.toInt() ?? 1);
    
    // Extraire les dates
    DateTime? checkIn;
    if (data['check_in'] != null) {
      checkIn = DateTime.parse(data['check_in'].toString());
    } else if (data['checkIn'] != null) {
      checkIn = data['checkIn'] is String 
          ? DateTime.parse(data['checkIn']) 
          : DateTime.parse(data['checkIn'].toString());
    } else {
      checkIn = DateTime.now();
    }
    
    DateTime? checkOut;
    if (data['check_out'] != null) {
      checkOut = DateTime.parse(data['check_out'].toString());
    } else if (data['checkOut'] != null) {
      checkOut = data['checkOut'] is String 
          ? DateTime.parse(data['checkOut']) 
          : DateTime.parse(data['checkOut'].toString());
    } else {
      checkOut = DateTime.now().add(const Duration(days: 1));
    }
    
    // Extraire le montant total
    final totalAmount = data['total_amount'] != null 
        ? (data['total_amount'] as num).toDouble() 
        : (data['totalPrice'] != null 
            ? (data['totalPrice'] as num).toDouble() 
            : (data['totalAmount'] as num?)?.toDouble() ?? 0.0);
    
    // Extraire le statut
    final status = data['status'] != null 
        ? ReservationStatus.values.firstWhere(
            (e) => e.name.toLowerCase() == data['status'].toString().toLowerCase(),
            orElse: () => ReservationStatus.pending,
          ) 
        : ReservationStatus.pending;
    
    // Extraire la date de création
    DateTime? createdAt;
    if (data['created_at'] != null) {
      createdAt = DateTime.parse(data['created_at'].toString());
    } else if (data['createdAt'] != null) {
      createdAt = data['createdAt'] is String 
          ? DateTime.parse(data['createdAt']) 
          : DateTime.parse(data['createdAt'].toString());
    } else {
      createdAt = DateTime.now();
    }
    
    // Extraire les notes
    final notes = data['notes'] ?? data['specialRequests'];
    
    // Construire l'objet Reservation
    return Reservation(
      id: data['id'] as String? ?? data['_id']?.toString() ?? '',
      residenceId: residenceId,
      residenceName: residenceName,
      residenceImage: residenceImage,
      clientName: clientName,
      clientPhone: clientPhone,
      checkIn: checkIn,
      checkOut: checkOut,
      totalAmount: totalAmount,
      status: status,
      createdAt: createdAt,
      guestsCount: guestsCount,
      notes: notes,
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
