import 'package:freezed_annotation/freezed_annotation.dart';

part 'residence_model.freezed.dart';
part 'residence_model.g.dart';

@freezed
class Residence with _$Residence {
  const factory Residence({
    required String id,
    required String name,
    required String description,
    required double price,
    required String address,
    required String city,
    required String country,
    required List<String> images,
    required int bedrooms,
    required int bathrooms,
    required double surface,
    required bool isAvailable,
    required Map<String, dynamic> location,
    @Default([]) List<String> amenities,
    @Default([]) List<String> rules,
    double? rating,
    int? reviewCount,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Residence;

  factory Residence.fromJson(Map<String, dynamic> json) => _$ResidenceFromJson(json);
}