// Residence extensions will go here

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/residence/residence.dart';

extension ResidenceProperties on Residence {
  String get title => name;

  String get status => isAvailable ? 'Disponible' : 'Non disponible';

  Color get statusColor => isAvailable ? Colors.green : Colors.red;

  String? get firstImageUrl {
    if (images.isEmpty) return null;
    
    // Si l'image est une Map avec une URL (nouveau format)
    if (images.first is Map) {
      final imageMap = images.first as Map;
      if (imageMap['url'] != null) {
        return 'http://localhost:4000${imageMap['url']}';
      }
    }
    
    // Si l'image est une String (ancien format)
    if (images.first is String) {
      return images.first as String;
    }
    
    return null;
  }

  String get formattedPrice {
    final numberFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    return numberFormat.format(price);
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
