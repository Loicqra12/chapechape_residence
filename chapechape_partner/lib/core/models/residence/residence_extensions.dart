import 'residence.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/config/app_config.dart';

extension ResidenceProperties on Residence {
  // Utiliser l'URL de base depuis la configuration
  static String get baseUrl => AppConfig.apiUrl;
  
  // Méthode utilitaire améliorée pour construire les URLs d'images complètes
  String _getCompleteImageUrl(String imagePath) {
    // Si déjà une URL complète, la retourner telle quelle
    if (imagePath.toString().startsWith('http')) return imagePath.toString();
    
    // Si c'est une image locale (assets), la retourner telle quelle
    if (imagePath.toString().startsWith('assets')) return imagePath.toString();
    
    // Si le chemin commence déjà par un slash, ne pas en ajouter un autre
    if (imagePath.startsWith('/')) {
      return '$baseUrl$imagePath';
    }
    
    // Ajouter le slash si nécessaire
    return '$baseUrl/$imagePath';
  }
  
  String get imageUrl {
    final imagePath = mainImage ?? (images.isNotEmpty ? images.first : AppImages.residencePlaceholder);
    print('Original image path: $imagePath');  // Debug: afficher le chemin original
    final fullUrl = _getCompleteImageUrl(imagePath);
    print('Full image URL: $fullUrl');  // Debug: afficher l'URL complète
    return fullUrl;
  }
  
  List<String> get imageUrls {
    return images.map((image) {
      final fullUrl = _getCompleteImageUrl(image);
      print('Image in list: $fullUrl');  // Debug: afficher chaque URL
      return fullUrl;
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
