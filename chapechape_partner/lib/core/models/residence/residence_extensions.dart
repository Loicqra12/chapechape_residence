import 'residence.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_images.dart';

extension ResidenceProperties on Residence {
  String get imageUrl {
    final imagePath = mainImage ?? (images.isNotEmpty ? images.first : AppImages.defaultResidence);
    return imagePath;
  }
  
  List<String> get imageUrls {
    const baseUrl = 'http://localhost:4000';  // TODO: à configurer via les variables d'environnement
    return images.map((image) {
      if (image.toString().startsWith('http')) return image.toString();
      if (image.toString().startsWith('assets')) return image.toString();
      return '$baseUrl/$image';
    }).toList();
  }
  
  String get title => name;
  
  String get status => isAvailable ? 'available' : 'unavailable';
  
  String get statusText => isAvailable ? 'Disponible' : 'Non disponible';
  
  String get formattedPrice => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  ).format(price);
  
  String get priceDisplay => formattedPrice;
  
  String get formattedSurface => '${surface.toStringAsFixed(0)} m²';
  
  String get formattedDate {
    final format = DateFormat('dd MMM yyyy', 'fr_FR');
    return format.format(createdAt);
  }
  
  bool get hasPool => amenities.contains('pool');
  bool get isVacationResidence => type == 'vacation';
  bool get isSpecialResidence => type == 'special';
}

extension LocationExtension on Map<String, dynamic> {
  String get displayAddress => this['formatted_address'] as String? ?? '';
}
