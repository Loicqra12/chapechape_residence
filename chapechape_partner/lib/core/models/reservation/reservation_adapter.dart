import 'package:hive/hive.dart';
import 'reservation.dart';

/// Adaptateur Hive pour la classe Reservation
/// Permet de serializer/deserializer les objets Reservation pour le stockage local
class ReservationAdapter extends TypeAdapter<Reservation> {
  @override
  final int typeId = 1; // ID unique pour ce type d'objet

  @override
  Reservation read(BinaryReader reader) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(reader.readMap());
    
    return Reservation(
      id: data['id'] ?? '',
      residenceId: data['residence_id'] ?? '',
      residenceName: data['residence_name'] ?? 'Résidence',
      residenceImage: data['residence_image'] ?? '',
      clientName: data['client_name'] ?? 'Client',
      clientPhone: data['client_phone'] ?? '',
      checkIn: DateTime.parse(data['check_in']),
      checkOut: DateTime.parse(data['check_out']),
      totalAmount: (data['total_amount'] as num).toDouble(),
      status: ReservationStatus.fromBackendFormat(data['status']?.toString() ?? ''),
      createdAt: DateTime.parse(data['created_at']),
      guestsCount: data['guests_count'],
      notes: data['notes'],
    );
  }

  @override
  void write(BinaryWriter writer, Reservation obj) {
    final data = {
      'id': obj.id,
      'residence_id': obj.residenceId,
      'residence_name': obj.residenceName,
      'residence_image': obj.residenceImage,
      'client_name': obj.clientName,
      'client_phone': obj.clientPhone,
      'check_in': obj.checkIn.toIso8601String(),
      'check_out': obj.checkOut.toIso8601String(),
      'total_amount': obj.totalAmount,
      'status': obj.status.toBackendFormat(),
      'created_at': obj.createdAt.toIso8601String(),
      'guests_count': obj.guestsCount,
      'notes': obj.notes,
    };

    writer.writeMap(data);
  }
}
