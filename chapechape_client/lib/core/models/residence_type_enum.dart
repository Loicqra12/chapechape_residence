
import '../constants/app_assets.dart' as assets;

/// Enum qui définit les différents types de résidences
enum ResidenceType {
  apartment,
  house,
  villa,
  studio,
  room,
  hotelRoom,
  other,
  // Types manquants identifiés dans le code
  bungalow,
  hotel,
  luxury,
  student,
  // Types supplémentaires nécessaires
  guesthouse,
  cottage,
  cabin,
  chalet,
  hostel,
  resort,
  // Types meublés
  studioMeuble,
  appartementMeuble,
  villaMeublee,
  // Types spéciaux
  penthouse,
  loft,
  coworking,
  // Types hôteliers
  hotelDePassage,
  motel,
  boutiqueHotel,
  hotelDeLuxe,
  aubergeEtMaisonDHotes,
  residenceHoteliere,
  // Types exotiques
  lodgeEtEcolodge,
  caseTraditionnelle,
  maisonFlottante,
  campementTouristique,
  // Types pour étudiants et colocations
  chambreEnColocation,
  cohabitation,
  residenceUniversitaire,
  citeDortoir,
  // Types non meublés
  appartementNonMeuble,
  villaNonMeublee,
  immeuble,
  courCommune,
  // Types économiques
  maisonDHotesEconomique,
  residenceFamilialeEnLocation,
  chambresDePassage,
  grenier,
}

/// Extension pour ajouter des méthodes utilitaires à ResidenceType
extension ResidenceTypeExtension on ResidenceType {
  /// Nom d'affichage du type de résidence
  String get displayName {
    switch (this) {
      case ResidenceType.apartment:
        return 'Appartement';
      case ResidenceType.house:
        return 'Maison';
      case ResidenceType.villa:
        return 'Villa';
      case ResidenceType.studio:
        return 'Studio';
      case ResidenceType.room:
        return 'Chambre';
      case ResidenceType.hotelRoom:
        return 'Chambre d\'hôtel';
      case ResidenceType.bungalow:
        return 'Bungalow';
      case ResidenceType.hotel:
        return 'Hôtel';
      case ResidenceType.luxury:
        return 'Résidence de Luxe';
      case ResidenceType.student:
        return 'Résidence Étudiante';
      case ResidenceType.studioMeuble:
        return 'Studio Meublé';
      case ResidenceType.appartementMeuble:
        return 'Appartement Meublé';
      case ResidenceType.villaMeublee:
        return 'Villa Meublée';
      case ResidenceType.penthouse:
        return 'Penthouse';
      case ResidenceType.loft:
        return 'Loft';
      case ResidenceType.coworking:
        return 'Espace Coworking';
      case ResidenceType.hotelDePassage:
        return 'Hôtel de Passage';
      case ResidenceType.motel:
        return 'Motel';
      case ResidenceType.boutiqueHotel:
        return 'Boutique Hôtel';
      case ResidenceType.hotelDeLuxe:
        return 'Hôtel de Luxe';
      case ResidenceType.aubergeEtMaisonDHotes:
        return 'Auberge et Maison d\'Hôtes';
      case ResidenceType.residenceHoteliere:
        return 'Résidence Hôtelière';
      case ResidenceType.lodgeEtEcolodge:
        return 'Lodge & Écolodge';
      case ResidenceType.caseTraditionnelle:
        return 'Case Traditionnelle';
      case ResidenceType.maisonFlottante:
        return 'Maison Flottante';
      case ResidenceType.campementTouristique:
        return 'Campement Touristique';
      case ResidenceType.chambreEnColocation:
        return 'Chambre en Colocation';
      case ResidenceType.cohabitation:
        return 'Cohabitation';
      case ResidenceType.residenceUniversitaire:
        return 'Résidence Universitaire';
      case ResidenceType.citeDortoir:
        return 'Cité-Dortoir';
      case ResidenceType.appartementNonMeuble:
        return 'Appartement Non Meublé';
      case ResidenceType.villaNonMeublee:
        return 'Villa Non Meublée';
      case ResidenceType.immeuble:
        return 'Immeuble';
      case ResidenceType.courCommune:
        return 'Cour Commune';
      case ResidenceType.maisonDHotesEconomique:
        return 'Maison d\'Hôtes Économique';
      case ResidenceType.residenceFamilialeEnLocation:
        return 'Résidence Familiale en Location';
      case ResidenceType.chambresDePassage:
        return 'Chambres de Passage';
      case ResidenceType.grenier:
        return 'Grenier Aménagé';
      // Nouveaux types ajoutés
      case ResidenceType.guesthouse:
        return 'Maison d\'hôtes';
      case ResidenceType.cottage:
        return 'Cottage';
      case ResidenceType.cabin:
        return 'Cabine';
      case ResidenceType.chalet:
        return 'Chalet';
      case ResidenceType.hostel:
        return 'Auberge de jeunesse';
      case ResidenceType.resort:
        return 'Resort';
      case ResidenceType.other:
        return 'Autre';
    }
  }
  
  /// Chemin d'icône pour le type de résidence
  String get iconPath {
    switch (this) {
      case ResidenceType.apartment:
        return assets.AppAssets.iconApartment;
      case ResidenceType.house:
        return assets.AppAssets.iconHouse;
      case ResidenceType.villa:
        return assets.AppAssets.iconVilla;
      case ResidenceType.studio:
        return assets.AppAssets.iconBed;
      case ResidenceType.room:
        return assets.AppAssets.iconBed;
      case ResidenceType.hotelRoom:
      case ResidenceType.hotel:
        return assets.AppAssets.iconHotel;
      case ResidenceType.bungalow:
        return assets.AppAssets.iconBungalow;
      case ResidenceType.luxury:
        return assets.AppAssets.iconFiveStars;
      // Pour tous les autres types, utiliser une icône par défaut ou similaire
      default:
        return assets.AppAssets.iconHouse;
    }
  }
  
  /// Récupère le code de type pour le backend
  String get typeCode {
    switch (this) {
      case ResidenceType.apartment:
        return 'apartment';
      case ResidenceType.house:
        return 'house';
      case ResidenceType.villa:
        return 'villa';
      case ResidenceType.studio:
        return 'studio';
      case ResidenceType.room:
        return 'room';
      case ResidenceType.hotelRoom:
        return 'hotel';
      case ResidenceType.bungalow:
        return 'bungalow';
      case ResidenceType.hotel:
        return 'hotel';
      case ResidenceType.luxury:
        return 'luxury';
      case ResidenceType.student:
        return 'student';
      case ResidenceType.studioMeuble:
        return 'studio_meuble';
      case ResidenceType.appartementMeuble:
        return 'appartement_meuble';
      case ResidenceType.villaMeublee:
        return 'villa_meublee';
      // Pour tous les autres types, convertir le nom de l'enum en snake_case
      default:
        final name = this.toString().split('.').last;
        return name.replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => '_${match.group(1)!.toLowerCase()}'
        ).replaceFirst('_', '');
    }
  }
  
  /// Convertit une chaîne en ResidenceType
  static ResidenceType fromString(String? value) {
    if (value == null) return ResidenceType.other;
    
    switch (value.toLowerCase()) {
      case 'apartment':
      case 'appartement':
        return ResidenceType.apartment;
      case 'house':
      case 'maison':
        return ResidenceType.house;
      case 'villa':
        return ResidenceType.villa;
      case 'studio':
        return ResidenceType.studio;
      case 'room':
      case 'chambre':
        return ResidenceType.room;
      case 'hotel':
      case 'hotelroom':
        return ResidenceType.hotelRoom;
      default:
        return ResidenceType.other;
    }
  }

  /// Convertit une chaîne snake_case en ResidenceType
  /// Couvre tous les types envoyés par l'app partner.
  static ResidenceType fromSnakeCase(String? value) {
    if (value == null) return ResidenceType.other;

    switch (value.toLowerCase().trim()) {
      // ── Appartements ─────────────────────────────────────────────────
      case 'appartement_meuble':
      case 'furnished_apartment':
        return ResidenceType.appartementMeuble;
      case 'apartment':
      case 'appartement':
        return ResidenceType.apartment;
      case 'appartement_vide':
        return ResidenceType.appartementNonMeuble;
      // ── Studios ──────────────────────────────────────────────────────
      case 'studio_meuble':
      case 'furnished_studio':
        return ResidenceType.studioMeuble;
      case 'studio':
        return ResidenceType.studio;
      // ── Villas ───────────────────────────────────────────────────────
      case 'villa_meublee':
      case 'villa_meuble':
        return ResidenceType.villaMeublee;
      case 'villa_vide':
        return ResidenceType.villaNonMeublee;
      case 'villa':
        return ResidenceType.villa;
      // ── Maison ───────────────────────────────────────────────────────
      case 'house':
      case 'maison':
        return ResidenceType.house;
      // ── Types spéciaux ────────────────────────────────────────────────
      case 'penthouse':
        return ResidenceType.penthouse;
      case 'loft':
        return ResidenceType.loft;
      case 'grenier':
        return ResidenceType.grenier;
      case 'immeuble':
        return ResidenceType.immeuble;
      case 'cour_commune':
        return ResidenceType.courCommune;
      // ── Hôtels ───────────────────────────────────────────────────────
      case 'hotel_passage':
        return ResidenceType.hotelDePassage;
      case 'motel':
        return ResidenceType.motel;
      case 'boutique_hotel':
        return ResidenceType.boutiqueHotel;
      case 'hotel_luxe':
      case 'hotel_de_luxe':
        return ResidenceType.hotelDeLuxe;
      case 'guest_house':
      case 'auberge_et_maison_d_hotes':
        return ResidenceType.aubergeEtMaisonDHotes;
      case 'residence_hoteliere':
        return ResidenceType.residenceHoteliere;
      case 'hotel':
      case 'hotel_room':
        return ResidenceType.hotel;
      // ── Insolites ────────────────────────────────────────────────────
      case 'bungalow':
        return ResidenceType.bungalow;
      case 'lodge':
      case 'lodge_et_ecolodge':
        return ResidenceType.lodgeEtEcolodge;
      case 'case_traditionnelle':
        return ResidenceType.caseTraditionnelle;
      case 'maison_flottante':
        return ResidenceType.maisonFlottante;
      case 'campement_touristique':
        return ResidenceType.campementTouristique;
      // ── Colocations ──────────────────────────────────────────────────
      case 'chambre_colocation':
      case 'chambre_en_colocation':
        return ResidenceType.chambreEnColocation;
      case 'coliving':
        return ResidenceType.cohabitation;
      case 'maison_hotes':
        return ResidenceType.guesthouse;
      case 'residence_universitaire':
        return ResidenceType.residenceUniversitaire;
      case 'cite_dortoir':
        return ResidenceType.citeDortoir;
      // ── Économiques ──────────────────────────────────────────────────
      case 'maison_hotes_economique':
        return ResidenceType.maisonDHotesEconomique;
      case 'residence_familiale':
      case 'residence_familiale_en_location':
        return ResidenceType.residenceFamilialeEnLocation;
      case 'chambres_passage':
      case 'chambres_de_passage':
        return ResidenceType.chambresDePassage;
      // ── Chambre / Room ───────────────────────────────────────────────
      case 'room':
      case 'chambre':
        return ResidenceType.room;
      default:
        return ResidenceType.other;
    }
  }

  /// Obtient la catégorie du type de résidence
  String get category {
    // Types meublés
    if ([
      ResidenceType.apartment,
      ResidenceType.house,
      ResidenceType.villa,
      ResidenceType.appartementMeuble,
      ResidenceType.studioMeuble,
      ResidenceType.villaMeublee,
    ].contains(this)) {
      return 'residences-meublees';
    }
    
    // Types hôteliers
    if ([
      ResidenceType.hotelRoom,
      ResidenceType.hotel,
      ResidenceType.boutiqueHotel,
      ResidenceType.hotelDeLuxe,
      ResidenceType.aubergeEtMaisonDHotes,
      ResidenceType.motel,
      ResidenceType.hotelDePassage,
      ResidenceType.residenceHoteliere,
    ].contains(this)) {
      return 'hotels';
    }
    
    // Types pour étudiants
    if ([
      ResidenceType.student,
      ResidenceType.residenceUniversitaire,
      ResidenceType.citeDortoir,
    ].contains(this)) {
      return 'residences-etudiantes';
    }
    
    // Types exotiques ou spéciaux
    if ([
      ResidenceType.luxury,
      ResidenceType.penthouse,
      ResidenceType.lodgeEtEcolodge,
      ResidenceType.caseTraditionnelle,
      ResidenceType.maisonFlottante,
      ResidenceType.campementTouristique,
    ].contains(this)) {
      return 'residences-speciales';
    }
    
    return 'autre';
  }

  /// Vérifie si le type a une icône personnalisée
  bool get hasCustomIcon {
    // Les types qui ont une icône spécifique définie
    return [
      ResidenceType.apartment,
      ResidenceType.house,
      ResidenceType.villa,
      ResidenceType.studio,
      ResidenceType.room,
      ResidenceType.hotelRoom,
      ResidenceType.hotel,
      ResidenceType.bungalow,
      ResidenceType.luxury,
    ].contains(this);
  }
}

// Méthodes supplémentaires pour ResidenceType
extension ResidenceTypeFeatures on ResidenceType {
  bool get isStudentResidence {
    return this == ResidenceType.student;
  }
}
