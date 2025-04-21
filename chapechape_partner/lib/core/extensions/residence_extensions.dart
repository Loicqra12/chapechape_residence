// Residence extensions will go here

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/residence/residence.dart';
import '../constants/app_images.dart';
import '../config/app_config_manager.dart';

extension ResidenceProperties on Residence {
  String get title => name;

  String get status => isAvailable ? 'Disponible' : 'Non disponible';

  Color get statusColor => isAvailable ? Colors.green : Colors.red;

  String? get firstImageUrl {
    if (images.isEmpty) {
      // Retourner l'image placeholder locale comme fallback
      return AppImages.residencePlaceholder;
    }
    
    // Si mainImage est défini, l'utiliser en priorité
    if (mainImage != null && mainImage!.isNotEmpty) {
      return _formatImageUrl(mainImage!);
    }
    
    // Sinon, utiliser la première image disponible
    var firstImage = images.first;
    
    // Si l'image est une Map avec une URL (nouveau format)
    if (firstImage is Map) {
      if (firstImage['url'] != null) {
        return _formatImageUrl(firstImage['url']);
      }
    }
    
    // Si l'image est une String (ancien format)
    if (firstImage is String) {
      return _formatImageUrl(firstImage);
    }
    
    // Si aucune image valide n'est trouvée
    return AppImages.residencePlaceholder;
  }
  
  String _formatImageUrl(String url) {
    // Si l'URL est déjà absolue (commence par http:// ou https://)
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    
    // Si l'URL est relative (commence par /)
    if (url.startsWith('/')) {
      return AppConfigManager.getMediaUrl(url);
    }
    
    // Si l'URL ne commence ni par '/' ni par 'http'
    return AppConfigManager.getMediaUrl('/$url');
  }

  String get formattedPrice {
    final numberFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    return numberFormat.format(price);
  }

  String get priceDisplay {
    final formattedAmount = formattedPrice;
  
    switch (pricePeriod.toLowerCase()) {
      case 'monthly':
        return '$formattedAmount / mois';
      case 'weekly':
        return '$formattedAmount / semaine';
      case 'daily':
        return '$formattedAmount / jour';
      case 'hourly':
        return '$formattedAmount / heure';
      default:
        return formattedAmount;
    }
  }

  String get formattedSurface {
    final numberFormat = NumberFormat.decimalPattern('fr_FR');
    return '${numberFormat.format(surface)} m²';
  }

  Map<String, bool> get propertyFeatures => {
    'hasPool': hasPool,
    'hasWifi': hasWifi,
    'hasRestaurant': hasRestaurant,
    'isVacationResidence': isVacationResidence,
    'isSpecialResidence': isSpecialResidence,
  };
}

extension LocationExtension on Map<String, dynamic> {
  String get displayAddress {
    final List<String> addressParts = [];
    
    if (this['street'] != null) addressParts.add(this['street']);
    if (this['city'] != null) addressParts.add(this['city']);
    if (this['country'] != null) addressParts.add(this['country']);
    
    return addressParts.join(', ');
  }
}
