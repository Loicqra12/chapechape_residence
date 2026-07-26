import 'residence.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/config/app_config.dart';
import '../../utils/formatters.dart';
import '../../utils/string_utils.dart';
import 'package:chapechape_partner/core/utils/app_logger.dart';

extension ResidenceProperties on Residence {
  /// Nom affiché avec majuscule à chaque mot (ex. "désir amina" → "Désir Amina").
  String get displayName => StringUtils.toTitleCase(name);

  /// Libellé français du type de bien (ex. "apartment" → "Appartement").
  String get typeDisplay {
    if (type.isEmpty) return type;
    const Map<String, String> _labels = {
      'apartment': 'Appartement',
      'appartement': 'Appartement',
      'studio_meuble': 'Studio meublé',
      'villa': 'Villa',
      'house': 'Maison',
      'studio': 'Studio',
    };
    return _labels[type.toLowerCase()] ?? type;
  }
  // Utiliser l'URL de base depuis la configuration
  static String get baseUrl => AppConfig.apiUrl;
  
  // Flag pour détecter si c'est une image locale qui devrait être chargée comme asset
  bool get hasPlaceholderImage {
    final imagePath = mainImage ?? (images.isNotEmpty ? images.first : '');
    return imagePath.isEmpty || 
           imagePath.startsWith('assets/') || 
           imagePath == AppImages.residencePlaceholder;
  }
  
  // Méthode utilitaire améliorée pour construire les URLs d'images complètes
  String _getCompleteImageUrl(String imagePath) {
    // Si l'image est vide, retourner le placeholder
    if (imagePath.isEmpty) return AppImages.residencePlaceholder;
    
    // Si c'est une image locale (assets), la retourner telle quelle
    if (imagePath.toString().startsWith('assets/')) return imagePath.toString();
    
    // Si déjà une URL complète avec le domaine mais pas /residences/
    if (imagePath.startsWith('http') && imagePath.contains('/uploads/') && !imagePath.contains('/uploads/residences/')) {
      AppLogger.d('Correction d\'URL: ajout de /residences/ dans: $imagePath');
      return imagePath.replaceAll('/uploads/', '/uploads/residences/');
    }
    
    // Si déjà une URL complète, la retourner telle quelle
    if (imagePath.toString().startsWith('http')) return imagePath.toString();
    
    // Récupérer l'URL de base en enlevant /api si présent
    String baseUrl = AppConfig.apiUrl;
    if (baseUrl.endsWith("/api")) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 4);
    }
    
    // Si le chemin commence par /uploads mais pas par /uploads/residences/
    if (imagePath.startsWith('/uploads/') && !imagePath.startsWith('/uploads/residences/')) {
      String modifiedUrl = imagePath.replaceAll('/uploads/', '/uploads/residences/');
      return '$baseUrl$modifiedUrl';
    }
    
    // Si le chemin commence déjà par un slash, ne pas en ajouter un autre
    if (imagePath.startsWith('/')) {
      return '$baseUrl$imagePath';
    }
    
    // Ajouter le slash et le chemin complet avec residences/
    return '$baseUrl/uploads/residences/$imagePath';
  }
  
  String get imageUrl {
    final imagePath = mainImage ?? (images.isNotEmpty ? images.first : AppImages.residencePlaceholder);
    AppLogger.d('ResidenceProperties - Image originale: $imagePath');
    
    // Si c'est un objet et pas une chaîne, essayer d'extraire l'URL
    if (imagePath is Map) {
      AppLogger.d('ResidenceProperties - L\'image est une Map: $imagePath');
      final String? url = imagePath['url'];
      if (url != null) {
        final fullUrl = _getCompleteImageUrl(url);
        AppLogger.d('ResidenceProperties - URL extraite de la Map: $fullUrl');
        return fullUrl;
      }
    }
    
    // Vérifier si l'image est un élément du tableau images mais pas une chaîne
    if (images.isNotEmpty && imagePath == images.first && imagePath is! String) {
      AppLogger.d('ResidenceProperties - L\'image n\'est pas une chaîne: $imagePath (type: ${imagePath.runtimeType})');
      
      // Si c'est une liste d'images avec structure différente
      if (images.first is Map) {
        final firstImage = images.first as Map;
        if (firstImage.containsKey('url')) {
          final String imageUrl = firstImage['url'];
          final fullUrl = _getCompleteImageUrl(imageUrl);
          AppLogger.d('ResidenceProperties - URL extraite d\'une Map dans images: $fullUrl');
          return fullUrl;
        }
      }
      
      // Si on ne peut pas extraire une URL, retourner l'image par défaut
      AppLogger.d('ResidenceProperties - Impossible d\'extraire l\'URL, retour à l\'image par défaut');
      return AppImages.residencePlaceholder;
    }
    
    AppLogger.d('ResidenceProperties - Conversion en chaîne et création de l\'URL complète');
    final fullUrl = _getCompleteImageUrl(imagePath.toString());
    AppLogger.d('ResidenceProperties - URL complète: $fullUrl');
    return fullUrl;
  }
  
  List<String> get imageUrls {
    return images.map((image) {
      final fullUrl = _getCompleteImageUrl(image);
      AppLogger.d('Image in list: $fullUrl');  // Debug: afficher chaque URL
      return fullUrl;
    }).toList();
  }
  
  String get title => name;
  
  String get status => isAvailable ? 'available' : 'unavailable';
  
  String get statusText => isAvailable ? 'Disponible' : 'Non disponible';
  
  // Formatage de prix avec devise actuelle
  String get formattedPrice => PriceFormatter.formatPrice(
    price,
    withCurrency: true,
    currency: currency,
  );
  
  // Formatage de prix sans symbole de devise
  String get formattedPriceWithoutCurrency => PriceFormatter.formatPrice(
    price,
    withCurrency: false,
    currency: currency,
  );
  
  // Conversion du prix vers une autre devise
  double convertPrice(String targetCurrency) {
    return CurrencyConverter.convert(price, currency, targetCurrency);
  }
  
  // Formatage du prix dans une autre devise
  String getFormattedPriceIn(String targetCurrency, {bool withCurrency = true}) {
    final convertedPrice = convertPrice(targetCurrency);
    return PriceFormatter.formatPrice(
      convertedPrice,
      withCurrency: withCurrency,
      currency: targetCurrency,
    );
  }
  
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
