import 'package:flutter/material.dart'; // Ajout de Material pour Color et Colors
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/residence_model.dart';
import '../models/residence_type_enum.dart';
import '../utils/custom_marker_generator.dart';

/// Extension pour la gestion des marqueurs de résidences sur la carte
extension ResidenceMarkerExtension on Residence {
  /// Catégories de marqueurs pour la carte
  static const String categoryMeubles = 'residences-meublees';
  static const String categoryHotels = 'hotels-hebergements';
  static const String categoryInsolites = 'hebergements-insolites';
  static const String categoryColocations = 'colocation-partages';
  static const String categoryLongueDuree = 'longue-duree';
  static const String categoryEconomiques = 'economiques';
  static const String categoryAutres = 'autres';

  /// Détermine la catégorie de marqueur pour cette résidence
  String get markerCategory {
    // 1. Résidences meublées
    if ([
      ResidenceType.apartment,
      ResidenceType.house,
      ResidenceType.villa,
      ResidenceType.appartementMeuble,
      ResidenceType.studioMeuble,
      ResidenceType.villaMeublee,
      ResidenceType.appartementNonMeuble,
      ResidenceType.villaNonMeublee,
      ResidenceType.studio,
    ].contains(type)) {
      return categoryMeubles;
    }

    // 2. Hôtels et hébergements
    if ([
      ResidenceType.hotelRoom,
      ResidenceType.hotel,
      ResidenceType.boutiqueHotel,
      ResidenceType.hotelDeLuxe,
      ResidenceType.aubergeEtMaisonDHotes,
      ResidenceType.motel,
      ResidenceType.hotelDePassage,
      ResidenceType.residenceHoteliere,
      ResidenceType.guesthouse,
      ResidenceType.hostel,
      ResidenceType.resort,
      ResidenceType.maisonDHotesEconomique,
    ].contains(type)) {
      return categoryHotels;
    }

    // 3. Hébergements insolites
    if ([
      ResidenceType.lodgeEtEcolodge,
      ResidenceType.caseTraditionnelle,
      ResidenceType.maisonFlottante,
      ResidenceType.campementTouristique,
      ResidenceType.bungalow,
      ResidenceType.chalet,
      ResidenceType.cabin,
      ResidenceType.cottage,
      ResidenceType.luxury,
      ResidenceType.penthouse,
      ResidenceType.loft,
    ].contains(type)) {
      return categoryInsolites;
    }

    // 4. Colocation et partages
    if ([
      ResidenceType.room,
      ResidenceType.student,
      ResidenceType.residenceUniversitaire,
      ResidenceType.citeDortoir,
      ResidenceType.chambreEnColocation,
      ResidenceType.cohabitation,
      ResidenceType.courCommune,
      ResidenceType.grenier,
    ].contains(type)) {
      return categoryColocations;
    }

    // 5. Autres (par défaut)
    return categoryAutres;
  }

  /// Obtient la couleur du marqueur selon la catégorie pour les overlays
  Color getOverlayColor() {
    switch (markerCategory) {
      case categoryMeubles:
        return Colors.blue; // 🟦 Bleu
      case categoryHotels:
        return Colors.green; // 🟩 Vert
      case categoryInsolites:
        return Colors.amber; // 🟨 Jaune
      case categoryColocations:
        return Colors.orange; // 🟧 Orange
      case categoryLongueDuree:
        return Colors.brown; // 🟫 Brun
      case categoryEconomiques:
        return Colors.white; // ⚪ Blanc
      default:
        return Colors.blue.shade300; // Bleu clair (Autres)
    }
  }

  /// Map statique pour stocker les icônes de prix par ID de résidence
  static final Map<String, BitmapDescriptor> _residenceMarkers = {};
  
  /// Vide le cache des marqueurs pour forcer leur regénération
  static void clearMarkerCache() {
    _residenceMarkers.clear();
    debugPrint('Cache des marqueurs vidé.');
  }
  
  /// Génère une icône de marqueur pour une résidence spécifique
  /// avec son prix exact au format Booking.com - BLEU FONCÉ UNIFORME
  static Future<BitmapDescriptor> generateMarkerForResidence(Residence residence) async {
    // Toujours forcer la regénération pour prendre en compte les modifications de design
    // Ne plus utiliser le cache pour l'instant pour voir les changements immédiatement
    // if (_residenceMarkers.containsKey(residence.id)) {
    //  return _residenceMarkers[residence.id]!;
    // }
    
    // Utiliser ROSE comme dans la capture d'écran
    const Color uniformPinkColor = Color(0xFFE91E63);
    
    // Obtenir l'icône emoji selon le type de résidence
    final String iconEmoji = residence.getResidenceTypeEmoji();
    
    // Créer un nouveau marqueur avec le prix exact et l'icône
    final BitmapDescriptor marker = await CustomMarkerGenerator.createPriceMarker(
      price: residence.price,
      backgroundColor: uniformPinkColor,
      iconEmoji: iconEmoji,
    );
    
    // Stocker dans le cache
    _residenceMarkers[residence.id] = marker;
    
    return marker;
  }
  
  /// Vérifie si un marqueur a déjà été généré pour cette résidence
  static bool hasGeneratedMarker(String residenceId) {
    return _residenceMarkers.containsKey(residenceId);
  }
  
  /// Obtient l'icône du marqueur selon la catégorie
  /// Utilise une couleur correspondant à la catégorie - cette méthode est synchrone
  /// et sera remplacée par le marqueur asynchrone avec prix dès qu'il sera généré
  BitmapDescriptor getMarkerIcon() {
    // Vérifier si un marqueur personnalisé existe déjà pour cette résidence
    if (_residenceMarkers.containsKey(id)) {
      return _residenceMarkers[id]!;
    }
    
    // Sinon, utiliser un marqueur de couleur selon la catégorie temporairement
    switch (markerCategory) {
      case categoryMeubles:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case categoryHotels:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case categoryInsolites:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      case categoryColocations:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case categoryLongueDuree:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      case categoryEconomiques:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
    }
  }
  
  /// Obtient l'icône emoji pour le type de résidence
  String getResidenceTypeEmoji() {
    switch (markerCategory) {
      case categoryMeubles:
        return '🏠'; // Maison
      case categoryHotels:
        return '🏨'; // Hôtel
      case categoryInsolites:
        return '🌴'; // Palmier/Lodge
      case categoryColocations:
        return '👥'; // Personnes
      case categoryLongueDuree:
        return '📅'; // Calendrier
      case categoryEconomiques:
        return '💸'; // Argent
      default:
        return '🏡'; // Autres
    }
  }
  
  /// Obtient l'icône de disponibilité basée sur le taux d'occupation
  String getAvailabilityIcon() {
    // Implémenter la logique de disponibilité ici, pour le moment utilise des valeurs fixes
    if (price < 30000) {
      return '🟢'; // Disponible (vert)
    } else if (price < 100000) {
      return '🟡'; // Bientôt complet (jaune)
    } else {
      return '🔴'; // Indisponible (rouge)
    }
  }
}
