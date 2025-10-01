import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// Import du nouveau widget d'autocomplétion d'adresses
import '../../widgets/maps/address_autocomplete_field.dart';
// Import du widget de configuration du mode de réservation
import '../../widgets/residence/reservation_mode_config.dart';
import '../../../core/blocs/residence/residence_bloc.dart';
import '../../../core/models/residence/residence.dart';
import '../../../core/models/residence/residence_image.dart';
import '../../../core/services/api/residence_service.dart';
import '../../../core/services/api/maps_service.dart';
import '../../../core/config/app_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/exceptions/api_exception.dart';
import 'package:chapechape_maps/chapechape_maps.dart';

class EditResidenceScreen extends StatelessWidget {
  final Residence? residence;
  final _residenceService = ResidenceService(baseUrl: AppConfig.apiUrl);

  EditResidenceScreen({
    super.key,
    this.residence,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ResidenceBloc(
        _residenceService,
      ),
      child: _EditResidenceView(residence: residence),
    );
  }
}

// Classe pour les éléments de localisation (pays, régions, villes)
class LocationItem {
  final String code;
  final String name;

  LocationItem(this.code, this.name);
}

class _EditResidenceView extends StatefulWidget {
  final Residence? residence;

  _EditResidenceView({
    this.residence,
  });

  @override
  State<_EditResidenceView> createState() => _EditResidenceViewState();
}

class _EditResidenceViewState extends State<_EditResidenceView> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  List<XFile> _selectedImages = [];
  List<Uint8List> _webImages = [];
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _priceController;
  late final TextEditingController _bedroomsController;
  late final TextEditingController _bathroomsController;
  late final TextEditingController _surfaceController;
  late final TextEditingController _hourlyRateController;
  late final TextEditingController _halfDayRateController;
  late final TextEditingController _fullDayRateController;
  late final TextEditingController _weekendRateController;
  late final TextEditingController _maxGuestsController;
  String _selectedType = 'studio_meuble';
  String _selectedCategory = 'residence_meublee';
  String _selectedPricePeriod =
      'month'; // Valeurs possibles: hour, day, week, month
  bool _hasPool = false;
  bool _isVacationResidence = false;
  bool _isSpecialResidence = false;
  bool _isAvailable = true;
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _hasAlternativePricing = false;
  String? _submitError;

  // Service de résidence pour les appels API directs
  final ResidenceService _residenceService =
      ResidenceService(baseUrl: AppConfig.apiUrl);
      
  // Nous n'avons pas besoin d'instancier MapsService ici car le widget AddressAutocompleteField crée sa propre instance

  // Options spécifiques pour différents types de résidences
  bool _hasAirConditioning = false;
  bool _hasWifi = false;
  bool _hasParking = false;
  bool _hasSecurity = false;
  bool _hasCleaning = false;
  bool _hasHotWater = false;
  bool _hasBalcony = false;
  bool _hasGarden = false;
  bool _hasTerrace = false;
  bool _hasKitchen = false;
  bool _hasSharedKitchen = false;
  bool _hasTv = false;
  bool _hasGenerator = false;
  bool _hasSolarEnergy = false;
  bool _hasGym = false;
  bool _hasSpa = false;
  bool _hasRestaurant = false;
  bool _hasBar = false;
  bool _hasRoomService = false;
  bool _hasLaundry = false;
  bool _hasMeetingRoom = false;
  bool _hasRunningWater = false;
  bool _hasWaterTank = false;
  bool _hasElectricity = false;
  bool _hasInverter = false;
  bool _hasFiberOptic = false;
  bool _hasEthernet = false;
  bool _hasFullKitchen = false;
  bool _hasKitchenette = false;
  bool _hasRefrigerator = false;
  bool _hasMicrowave = false;
  bool _hasOven = false;
  bool _hasFan = false;
  bool _hasCelingFan = false;
  bool _hasAlarmSystem = false;
  bool _hasCCTV = false;
  bool _hasSecurityGuard = false;

  // Méthodes de paiement acceptées
  bool _acceptsCash = true;
  bool _acceptsWave = false;
  bool _acceptsOrangeMoney = false;
  bool _acceptsMoovMoney = false;
  bool _acceptsMtnMoney = false;
  bool _acceptsCreditCard = false;
  bool _acceptsBankTransfer = false;

  // Variables pour la localisation
  String _selectedCountry = 'CI'; // Côte d'Ivoire par défaut
  String _selectedRegion = 'AB'; // Abidjan par défaut
  String _selectedCity = 'CO'; // Cocody par défaut
  
  // Variables pour la géolocalisation
  double? _latitude;
  double? _longitude;
  String? _formattedAddress;
  
  // Variables pour le mode de réservation
  String _selectedReservationMode = 'instant'; // Par défaut: instantané
  
  /// Construction d'une carte Google Maps avec le marqueur de la résidence
  Widget _buildGoogleMap() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(_latitude!, _longitude!),
            zoom: 15,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('selected_location'),
              position: LatLng(_latitude!, _longitude!),
              infoWindow: InfoWindow(title: _formattedAddress ?? "Position sélectionnée"),
            ),
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
        ),
      ),
    );
  }
  
  /// Callback appelé quand une position est sélectionnée sur la carte
  void _onMapPositionSelected(LatLng position, String? address) {
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
      _formattedAddress = address;
      
      // Si l'adresse est disponible et que le champ d'adresse est vide ou a une valeur par défaut
      // on pré-remplit le champ d'adresse
      if (address != null && (_addressController.text.isEmpty || 
          _addressController.text == 'Adresse non spécifiée')) {
        _addressController.text = address;
      }
    });
  }

  /// Obtient la position actuelle de l'utilisateur automatiquement
  Future<void> _getCurrentLocation() async {
    try {
      // Utiliser le service de géolocalisation existant
      final locationService = LocationService();
      
      // Vérifier si la géolocalisation est disponible
      final isAvailable = await locationService.isLocationAvailable();
      if (!isAvailable) {
        print('⚠️ Géolocalisation non disponible');
        return;
      }
      
      // Obtenir la position actuelle
      final position = await locationService.getCurrentPosition();
      
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      
      // Faire un reverse geocoding pour obtenir l'adresse
      final mapsService = MapsService(baseUrl: AppConfig.apiUrl);
      try {
        final result = await mapsService.reverseGeocode(position.latitude, position.longitude);
        if (result['formattedAddress'] != null) {
          setState(() {
            _formattedAddress = result['formattedAddress'];
            // Pré-remplir l'adresse si le champ est vide
            if (_addressController.text.isEmpty) {
              _addressController.text = result['formattedAddress'];
            }
          });
        }
      } catch (e) {
        print('⚠️ Erreur lors du géocodage inverse: $e');
      }
      
      print('✅ Géolocalisation automatique réussie: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('❌ Erreur lors de la géolocalisation automatique: $e');
    }
  }

  // Variables pour les images
  List<String>? _existingImages;
  List<ResidenceImage> _newImages = [];

  // Variables pour les options et règles
  bool _allowsSmoking = false;
  bool _allowsPets = false;
  bool _allowsParties = false;

  // Ensemble des aménités sélectionnées
  Set<String> _selectedAmenities = {};

  // Données des pays, régions et villes
  final List<LocationItem> _availableCountries = [
    LocationItem('SN', 'Sénégal'),
    LocationItem('CI', 'Côte d\'Ivoire'),
    LocationItem('BF', 'Burkina Faso'),
    LocationItem('ML', 'Mali'),
    LocationItem('GN', 'Guinée'),
    LocationItem('BJ', 'Bénin'),
    LocationItem('TG', 'Togo'),
    LocationItem('NE', 'Niger'),
    LocationItem('CM', 'Cameroun'),
    LocationItem('GA', 'Gabon'),
    LocationItem('CG', 'Congo'),
    LocationItem('ST', 'Saint-Louis'),
  ];

  // Map des régions par pays (simplifiée pour l'exemple, à compléter)
  Map<String, List<LocationItem>> _regionsByCountry = {
    'CI': [
      // Côte d'Ivoire
      LocationItem('AB', 'Abidjan'),
      LocationItem('YA', 'Yamoussoukro'),
      LocationItem('BO', 'Bouaké'),
      LocationItem('DA', 'Daloa'),
      LocationItem('KO', 'Korhogo'),
      LocationItem('SM', 'San Pedro'),
      LocationItem('GO', 'Gagnoa'),
      LocationItem('MN', 'Man'),
      LocationItem('AE', 'Abengourou'),
      LocationItem('DI', 'Divo'),
      LocationItem('ZC', 'Zones côtières et plages'),
    ],
    'SN': [
      // Sénégal
      LocationItem('DK', 'Dakar'),
      LocationItem('TH', 'Thiès'),
      LocationItem('ZI', 'Ziguinchor'),
      LocationItem('ST', 'Saint-Louis'),
    ],
    // Autres pays...
  };

  // Map des villes par région (simplifiée pour l'exemple, à compléter)
  Map<String, List<LocationItem>> _citiesByRegion = {
    'CI_AB': [
      // Abidjan
      LocationItem('CO', 'Cocody'),
      LocationItem('PL', 'Plateau'),
      LocationItem('MA', 'Marcory'),
      LocationItem('TR', 'Treichville'),
      LocationItem('AD', 'Adjamé'),
      LocationItem('AT', 'Attécoubé'),
      LocationItem('KO', 'Koumassi'),
      LocationItem('PB', 'Port-Bouët'),
      LocationItem('YO', 'Yopougon'),
      LocationItem('AN', 'Abobo'),
      LocationItem('BG', 'Bingerville'),
      LocationItem('SG', 'Songon'),
      LocationItem('AM', 'Anyama'),
    ],
    'CI_YA': [
      // Yamoussoukro
      LocationItem('CE', 'Centre'),
      LocationItem('NO', 'Nord'),
      LocationItem('ES', 'Est'),
      LocationItem('OU', 'Ouest'),
    ],
    // Nouvelles zones côtières et plages
    'CI_ZC': [
      // Zones côtières et plages
      LocationItem('GB', 'Grand-Bassam'),
      LocationItem('AS', 'Assinie'),
      LocationItem('JV', 'Jacqueville'),
      LocationItem('GL', 'Grand-Lahou'),
      LocationItem('SP', 'San Pedro'),
      LocationItem('SS', 'Sassandra'),
    ],
    // Autres régions...
    'SN_DK': [
      LocationItem('DK', 'Dakar'),
      LocationItem('GD', 'Grand Dakar'),
      LocationItem('AL', 'Almadies'),
      LocationItem('PL', 'Plateau'),
      LocationItem('ME', 'Médina'),
      LocationItem('OG', 'Ouakam'),
      LocationItem('YF', 'Yoff'),
    ],
    'SL_FR': [
      LocationItem('CU', 'CU'),
      LocationItem('BL', 'Boulbinet'),
      LocationItem('KA', 'Kaloum'),
      LocationItem('MA', 'Matam'),
      LocationItem('RA', 'Ratoma'),
    ],
    'GH_AC': [
      LocationItem('AC', 'Accra'),
      LocationItem('KO', 'Korle Bu'),
      LocationItem('LA', 'La'),
      LocationItem('AB', 'Abeka'),
      LocationItem('OK', 'Okai Koi'),
    ],
    'NG_LG': [
      LocationItem('IK', 'Ikeja'),
      LocationItem('AP', 'Apapa'),
      LocationItem('ET', 'Eti-Osa'),
      LocationItem('SU', 'Surulere'),
      LocationItem('YB', 'Yaba'),
    ],
  };

  // Map des catégories de résidences
  final Map<String, Map<String, dynamic>> _residenceCategories = {
    'residence_meublee': {
      'label': 'Résidences meublées',
      'types': [
        ResidenceType('studio_meuble', 'Studio meublé'),
        ResidenceType('appartement_meuble', 'Appartement meublé'),
        ResidenceType('villa_meublee', 'Villa meublée'),
        ResidenceType('penthouse', 'Penthouse'),
        ResidenceType('loft', 'Loft'),
        ResidenceType('grenier', 'Grenier aménagé'),
      ],
    },
    'hotel': {
      'label': 'Hôtels & Hébergements classiques',
      'types': [
        ResidenceType('hotel_passage', 'Hôtel de passage'),
        ResidenceType('motel', 'Motel'),
        ResidenceType('boutique_hotel', 'Boutique-Hôtel'),
        ResidenceType('hotel_luxe', 'Hôtel de luxe'),
        ResidenceType('guest_house', 'Auberge & Guest House'),
        ResidenceType('residence_hoteliere', 'Résidence hôtelière'),
      ],
    },
    'hebergement_insolite': {
      'label': 'Hébergements insolites & nature',
      'types': [
        ResidenceType('bungalow', 'Bungalow'),
        ResidenceType('lodge', 'Lodge & écolodge'),
        ResidenceType('case_traditionnelle', 'Case traditionnelle'),
        ResidenceType('maison_flottante', 'Maison flottante'),
        ResidenceType('campement_touristique', 'Campement touristique'),
      ],
    },
    'colocation': {
      'label': 'Colocation & résidences partagées',
      'types': [
        ResidenceType('chambre_colocation', 'Chambre en colocation'),
        ResidenceType('coliving', 'Coliving'),
        ResidenceType('maison_hotes', 'Maison d\'hôtes'),
        ResidenceType('residence_universitaire', 'Résidence universitaire'),
        ResidenceType('cite_dortoir', 'Cité & dortoir'),
      ],
    },
    'residence_longue_duree': {
      'label': 'Résidences longue durée',
      'types': [
        ResidenceType('appartement_vide', 'Appartement non meublé'),
        ResidenceType('villa_vide', 'Villa non meublée'),
        ResidenceType('immeuble', 'Immeuble'),
        ResidenceType('cour_commune', 'Cour commune'),
      ],
    },
    'hebergement_economique': {
      'label': 'Hébergements économiques et populaires',
      'types': [
        ResidenceType('maison_hotes_economique', 'Maison d\'hôtes économique'),
        ResidenceType('residence_familiale', 'Résidence familiale en location'),
        ResidenceType('chambres_passage', 'Chambres de passage'),
      ],
    },
  };

  List<ResidenceType> get _availableTypesForCategory {
    return _residenceCategories[_selectedCategory]!['types']
        as List<ResidenceType>;
  }

  @override
  void initState() {
    super.initState();

    // Initialiser les contrôleurs
    _nameController = TextEditingController(
      text: widget.residence?.name ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.residence?.description ?? '',
    );
    _addressController = TextEditingController(
      text: widget.residence?.address ?? '',
    );
    _cityController = TextEditingController(
      text: widget.residence?.city ?? '',
    );
    _bedroomsController = TextEditingController(
      text: widget.residence?.bedrooms.toString() ?? '1',
    );
    _bathroomsController = TextEditingController(
      text: widget.residence?.bathrooms.toString() ?? '1',
    );
    _surfaceController = TextEditingController(
      text: widget.residence?.surface.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: widget.residence?.price.toString() ?? '',
    );
    _hourlyRateController = TextEditingController(
      text: widget.residence?.hourlyRate?.toString() ?? '0',
    );
    _halfDayRateController = TextEditingController(
      text: widget.residence?.halfDayRate?.toString() ?? '0',
    );
    _fullDayRateController = TextEditingController(
      text: widget.residence?.fullDayRate?.toString() ?? '0',
    );
    _weekendRateController = TextEditingController(
      text: widget.residence?.weekendRate?.toString() ?? '0',
    );
    _maxGuestsController = TextEditingController(
      text: widget.residence?.maxGuests.toString() ?? '2',
    );

    // Initialiser le type et la catégorie s'il s'agit d'une édition
    if (widget.residence != null) {
      // Afficher le type reçu du backend pour diagnostic
      print('🔍 Type reçu du backend: ${widget.residence!.type}');

      // Convertir le type du backend en type frontend si nécessaire
      _selectedType = _mapBackendTypeToFrontendType(widget.residence!.type);
      print('🔍 Type converti pour l\'interface: $_selectedType');

      _selectedCategory = _getCategoryFromType(_selectedType);
      print('🔍 Catégorie déterminée: $_selectedCategory');

      // S'assurer que le type est valide dans sa catégorie
      _ensureSelectedTypeIsValid();
      print(
          '🔍 Type final utilisé: $_selectedType (catégorie: $_selectedCategory)');

      // Initialiser les états des amenities
      _hasPool = widget.residence!.hasPool;
      _hasWifi = widget.residence!.hasWifi;
      _hasParking = widget.residence!.amenities.contains('parking');
      _hasKitchen = widget.residence!.amenities.contains('kitchen') || true;
      _hasAirConditioning =
          widget.residence!.amenities.contains('air_conditioning') || true;
      _hasTerrace = widget.residence!.amenities.contains('terrace');
      _hasBalcony = widget.residence!.amenities.contains('balcony');
      _hasGym = widget.residence!.amenities.contains('gym');
      _hasSpa = widget.residence!.amenities.contains('spa');
      _hasMeetingRoom = widget.residence!.amenities.contains('meeting_room');

// Initialiser les nouveaux équipements
      _hasRunningWater = widget.residence!.amenities.contains('running_water');
      _hasHotWater = widget.residence!.amenities.contains('hot_water');
      _hasWaterTank = widget.residence!.amenities.contains('water_tank');
      _hasElectricity =
          widget.residence!.amenities.contains('electricity') || true;
      _hasInverter = widget.residence!.amenities.contains('inverter');
      _hasFiberOptic = widget.residence!.amenities.contains('fiber_optic');
      _hasEthernet = widget.residence!.amenities.contains('ethernet');
      _hasFullKitchen = widget.residence!.amenities.contains('full_kitchen');
      _hasKitchenette = widget.residence!.amenities.contains('kitchenette');
      _hasRefrigerator = widget.residence!.amenities.contains('refrigerator');
      _hasMicrowave = widget.residence!.amenities.contains('microwave');
      _hasOven = widget.residence!.amenities.contains('oven');
      _hasFan = widget.residence!.amenities.contains('fan');
      _hasCelingFan = widget.residence!.amenities.contains('ceiling_fan');
      _hasAlarmSystem = widget.residence!.amenities.contains('alarm_system');
      _hasCCTV = widget.residence!.amenities.contains('cctv');
      _hasSecurityGuard =
          widget.residence!.amenities.contains('security_guard');
      // Initialiser les règles
      _allowsSmoking = widget.residence!.allowsSmoking;
      _allowsPets = widget.residence!.allowsPets;
      _allowsParties = widget.residence!.allowsParties;

      // Initialiser les autres statuts
      _isAvailable = widget.residence!.isAvailable;
      _isVacationResidence = widget.residence!.isVacationResidence;
      _isSpecialResidence = widget.residence!.isSpecialResidence;
      
      // Initialiser le mode de réservation
      _selectedReservationMode = widget.residence!.reservationMode;

      // Initialiser la localisation
      if (widget.residence!.country != null) {
        _selectedCountry = widget.residence!.country!;
      }
      if (widget.residence!.region != null) {
        _selectedRegion = widget.residence!.region!;
      }
      if (widget.residence!.cityCode != null) {
        _selectedCity = widget.residence!.cityCode!;
      }

      // Initialiser les images existantes
      _existingImages =
          widget.residence!.images.map((img) => img.toString()).toList();

      // Initialiser les méthodes de paiement
      if (widget.residence != null &&
          widget.residence!.paymentMethods != null) {
        _acceptsCash = widget.residence!.paymentMethods!.contains('cash');
        _acceptsWave = widget.residence!.paymentMethods!.contains('wave');
        _acceptsOrangeMoney =
            widget.residence!.paymentMethods!.contains('orange_money');
        _acceptsMoovMoney =
            widget.residence!.paymentMethods!.contains('moov_money');
        _acceptsMtnMoney =
            widget.residence!.paymentMethods!.contains('mtn_money');
        _acceptsCreditCard =
            widget.residence!.paymentMethods!.contains('credit_card');
        _acceptsBankTransfer =
            widget.residence!.paymentMethods!.contains('bank_transfer');
      }
    }
    
    // Géolocalisation automatique pour les nouvelles résidences
    if (widget.residence == null) {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _priceController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _surfaceController.dispose();
    _hourlyRateController.dispose();
    _halfDayRateController.dispose();
    _fullDayRateController.dispose();
    _weekendRateController.dispose();
    _maxGuestsController.dispose();
    super.dispose();
  }

  // Méthode pour mettre à jour la liste des aménités sélectionnées
  void _updateSelectedAmenities() {
    _selectedAmenities = {};

    // Ajouter les commodités en fonction des booléens
    if (_hasAirConditioning) _selectedAmenities.add('air_conditioning');
    if (_hasWifi) _selectedAmenities.add('wifi');
    if (_hasParking) _selectedAmenities.add('parking');
    if (_hasPool) _selectedAmenities.add('pool');
    if (_hasSecurity) _selectedAmenities.add('security');
    if (_hasCleaning) _selectedAmenities.add('cleaning');
    if (_hasHotWater) _selectedAmenities.add('hot_water');
    if (_hasBalcony) _selectedAmenities.add('balcony');
    if (_hasGarden) _selectedAmenities.add('garden');
    if (_hasTerrace) _selectedAmenities.add('terrace');
    if (_hasKitchen) _selectedAmenities.add('kitchen');
    if (_hasSharedKitchen) _selectedAmenities.add('shared_kitchen');
    if (_hasTv) _selectedAmenities.add('tv');
    if (_hasGenerator) _selectedAmenities.add('generator');
    if (_hasSolarEnergy) _selectedAmenities.add('solar_energy');
    if (_hasGym) _selectedAmenities.add('gym');
    if (_hasSpa) _selectedAmenities.add('spa');
    if (_hasRestaurant) _selectedAmenities.add('restaurant');
    if (_hasBar) _selectedAmenities.add('bar');
    if (_hasRoomService) _selectedAmenities.add('room_service');
    if (_hasLaundry) _selectedAmenities.add('laundry');
    if (_hasMeetingRoom) _selectedAmenities.add('meeting_room');
  }

  // Méthode pour mettre à jour une aménité spécifique
  void _updateAmenity(String amenityName, bool value) {
    setState(() {
      switch (amenityName) {
        case 'pool':
          _hasPool = value;
          break;
        case 'air_conditioning':
          _hasAirConditioning = value;
          break;
        case 'wifi':
          _hasWifi = value;
          break;
        case 'parking':
          _hasParking = value;
          break;
        case 'security':
          _hasSecurity = value;
          break;
        case 'cleaning':
          _hasCleaning = value;
          break;
        case 'hot_water':
          _hasHotWater = value;
          break;
        case 'balcony':
          _hasBalcony = value;
          break;
        case 'garden':
          _hasGarden = value;
          break;
        case 'terrace':
          _hasTerrace = value;
          break;
        case 'kitchen':
          _hasKitchen = value;
          break;
        case 'shared_kitchen':
          _hasSharedKitchen = value;
          break;
        case 'tv':
          _hasTv = value;
          break;
        case 'generator':
          _hasGenerator = value;
          break;
        case 'solar_energy':
          _hasSolarEnergy = value;
          break;
        case 'gym':
          _hasGym = value;
          break;
        case 'spa':
          _hasSpa = value;
          break;
        case 'restaurant':
          _hasRestaurant = value;
          break;
        case 'bar':
          _hasBar = value;
          break;
        case 'room_service':
          _hasRoomService = value;
          break;
        case 'laundry':
          _hasLaundry = value;
          break;
        case 'meeting_room':
          _hasMeetingRoom = value;
          break;
        case 'isVacationResidence':
          _isVacationResidence = value;
          break;
        case 'isSpecialResidence':
          _isSpecialResidence = value;
          break;
      }

      // Mettre à jour l'ensemble des aménités
      _updateSelectedAmenities();
    });
  }

  Future<void> _selectImage() async {
    // Afficher une boîte de dialogue pour choisir la source
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galerie'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImagesFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Appareil photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _takePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImagesFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage();

      print('Images sélectionnées depuis la galerie: ${pickedFiles.length}');

      if (pickedFiles.isNotEmpty) {
        for (final pickedFile in pickedFiles) {
          if (kIsWeb) {
            // En environnement web, nous devons lire le contenu du fichier
            final bytes = await pickedFile.readAsBytes();
            print(
                'Image web lue: ${bytes.length} octets, nom: ${pickedFile.name}');
            setState(() {
              _newImages.add(
                ResidenceImage.fromWebBytes(bytes, path: pickedFile.name),
              );
            });
          } else {
            // En environnement mobile, nous pouvons utiliser le chemin du fichier
            print('Image mobile sélectionnée: ${pickedFile.path}');
            setState(() {
              _newImages.add(
                ResidenceImage.fromFile(File(pickedFile.path)),
              );
            });
          }
        }

        print(
            'Total des images dans _newImages après sélection: ${_newImages.length}');
      }
    } catch (e) {
      print('Erreur lors de la sélection des images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection des images: $e')),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);

      if (pickedFile != null) {
        print('Photo prise avec l\'appareil: ${pickedFile.path}');

        setState(() {
          if (kIsWeb) {
            // En environnement web, nous devons lire le contenu du fichier
            pickedFile.readAsBytes().then((bytes) {
              print('Photo web lue: ${bytes.length} octets');
              _newImages.add(
                ResidenceImage.fromWebBytes(bytes, path: pickedFile.name),
              );
            });
          } else {
            // En environnement mobile, nous pouvons utiliser le chemin du fichier
            _newImages.add(
              ResidenceImage.fromFile(File(pickedFile.path)),
            );
          }
        });
      }
    } catch (e) {
      print('Erreur lors de la prise de photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la prise de photo: $e')),
      );
    }
  }

  Widget _buildImagePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Photos',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Ajoutez au moins une photo de la résidence',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),

        // Compteur d'images
        Text(
          'Images: ${(_existingImages?.length ?? 0) + _newImages.length}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: ((_existingImages?.length ?? 0) + _newImages.length) > 0
                ? Colors.green
                : Colors.red,
          ),
        ),
        const SizedBox(height: 8),

        // Grille d'images
        SizedBox(
          height: 200,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Bouton d'ajout d'image
                Container(
                  width: 120,
                  height: 190,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InkWell(
                    onTap: _selectImage,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_photo_alternate, size: 40),
                        SizedBox(height: 8),
                        Text('Ajouter\nune photo', textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),

                // Images existantes
                if (_existingImages != null)
                  ..._existingImages!.map((imageUrl) {
                    return Container(
                      width: 120,
                      height: 190,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Image avec gestion d'erreur
                            Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print(
                                    'Erreur de chargement d\'image: $error pour URL $imageUrl');
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.broken_image,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Image non\ndisponible',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red.shade700),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            ),

                            // Bouton de suppression
                            Positioned(
                              top: 5,
                              right: 5,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _existingImages!.remove(imageUrl);
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),

                // Nouvelles images
                ..._newImages.map((image) {
                  return Container(
                    width: 120,
                    height: 190,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        // Affichage différent selon le type d'image et la plateforme
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: kIsWeb
                                ? image.webImage != null
                                    ? Image.memory(
                                        image.webImage!,
                                        fit: BoxFit.cover,
                                      )
                                    : image.url != null
                                        ? Image.network(
                                            image.url!,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            color: Colors.grey.shade300,
                                            child: const Icon(Icons.image,
                                                size: 50),
                                          )
                                : image.isLocal
                                    ? Image.file(
                                        File(image.path!),
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        image.url!,
                                        fit: BoxFit.cover,
                                      ),
                          ),
                        ),
                        // Bouton de suppression
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _newImages.remove(image);
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // Méthode appelée lors de la soumission du formulaire
  Future<void> _submitForm() async {
    // Vérifier si le formulaire est valide
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      print('\n=== DÉBUT SOUMISSION DU FORMULAIRE ===');
      print('Nombre d\'images existantes: ${_existingImages?.length ?? 0}');
      print('Nombre de nouvelles images: ${_newImages.length}');

      // Vérifier qu'au moins une image est sélectionnée
      if ((_existingImages == null || _existingImages!.isEmpty) &&
          (_newImages.isEmpty)) {
        print('❌ Aucune image sélectionnée');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez ajouter au moins une image')),
        );
        return;
      }

      // Afficher un indicateur de chargement
      setState(() {
        _isLoading = true;
      });

      try {
        // Préparer les données de la résidence à partir du formulaire
        Map<String, dynamic> formData = {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'bedrooms': int.tryParse(_bedroomsController.text) ?? 0,
          'bathrooms': int.tryParse(_bathroomsController.text) ?? 0,
          'surface': double.tryParse(_surfaceController.text) ?? 0,
          'maxGuests': int.tryParse(_maxGuestsController.text) ?? 1,
          'price': double.tryParse(_priceController.text) ?? 0,
          'pricePeriod': _selectedPricePeriod,
          'type': _selectedType,
          'category': _selectedCategory,
          'status': _isAvailable ? 'available' : 'unavailable',

          // Information sur la localisation (pays, région, ville, adresse)
          'country': _selectedCountry,
          'region': _selectedRegion,
          'city': _selectedCity,
          'address': _addressController.text,
          // Coordonnées GPS (si disponibles)
          'latitude': _latitude,
          'longitude': _longitude,
          'formattedAddress': _formattedAddress,

          // Règles de la résidence
          'rules': {
            'allowsSmoking': _allowsSmoking,
            'allowsPets': _allowsPets,
            'allowsParties': _allowsParties,
          },

          // Liste des aménités
          'amenities': _buildAmenitiesList(),

          // Méthodes de paiement acceptées
          'paymentMethods': _buildPaymentMethodsList(),
          
          // Mode de réservation
          'reservationMode': _selectedReservationMode,
        };

        // Vérifier pour les tarifs alternatifs
        if (_hasAlternativePricing) {
          formData['hourlyRate'] =
              double.tryParse(_hourlyRateController.text) ?? 0;
          formData['halfDayRate'] =
              double.tryParse(_halfDayRateController.text) ?? 0;
          formData['fullDayRate'] =
              double.tryParse(_fullDayRateController.text) ?? 0;
          formData['weekendRate'] =
              double.tryParse(_weekendRateController.text) ?? 0;
        } else {
          formData['hourlyRate'] = 0;
          formData['halfDayRate'] = 0;
          formData['fullDayRate'] = 0;
          formData['weekendRate'] = 0;
        }

        // Préparer les images à envoyer
        List<ResidenceImage> images = [];

        // Ajouter les images existantes qui n'ont pas été supprimées
        if (_existingImages != null) {
          for (var imageUrl in _existingImages!) {
            print('✅ Ajout d\'une image existante: $imageUrl');
            images.add(ResidenceImage(url: imageUrl));
          }
        }

        // Ajouter les nouvelles images sélectionnées
        for (var image in _newImages) {
          print('⭐ Traitement d\'une nouvelle image:');
          print('  - Debug info: ${image.getDebugInfo()}');
          if (image.file != null) {
            print('  - Image native (fichier): ${image.file!.path}');
            images.add(image);
          } else if (image.webImage != null) {
            print('  - Image web (${image.webImage!.length} octets)');
            images.add(image);
          } else if (image.url != null) {
            print('  - Image URL: ${image.url}');
            images.add(image);
          } else {
            print('  - ⚠️ Type d\'image inconnu');
          }
        }

        print('\n=== RÉCAPITULATIF IMAGES ===');
        print('Nombre total d\'images à envoyer: ${images.length}');

        if (images.isEmpty) {
          print(
              '⚠️ AVERTISSEMENT: Aucune image à envoyer malgré les contrôles!');
        }

        for (int i = 0; i < images.length; i++) {
          final img = images[i];
          if (img.url != null) {
            print('Image ${i + 1}: URL = ${img.url}');
          } else if (img.file != null) {
            print('Image ${i + 1}: Fichier local (${img.file!.path})');
          } else if (img.webImage != null) {
            print('Image ${i + 1}: Image web (${img.webImage!.length} octets)');
          } else {
            print('Image ${i + 1}: Type inconnu!');
          }
        }

        if (widget.residence == null) {
          // Créer une nouvelle résidence
          print('\n=== CRÉATION DE RÉSIDENCE ===');
          final residence =
              await _residenceService.createResidence(formData, images);
          print('✅ Résidence créée avec succès! ID: ${residence.id}');

          // Effacer le formulaire après création réussie
          _clearForm();

          // Afficher un message de succès
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Résidence créée avec succès')),
            );
            // Naviguer vers la liste des résidences
            Navigator.of(context).pop(residence);
          }
        } else {
          // Mettre à jour une résidence existante
          print('\n=== MISE À JOUR DE RÉSIDENCE ===');
          print('ID de la résidence: ${widget.residence!.id}');
          final updatedResidence = await _residenceService.updateResidence(
            widget.residence!.id,
            formData,
            images,
          );
          print('✅ Résidence mise à jour avec succès!');

          // Afficher un message de succès
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Résidence mise à jour avec succès')),
            );
            // Naviguer vers la liste des résidences avec la résidence mise à jour
            Navigator.of(context).pop(updatedResidence);
          }
        }
      } catch (e) {
        print('❌ Erreur lors de la soumission du formulaire: $e');
        if (mounted) {
          String errorMessage = 'Une erreur est survenue';
          if (e is ApiException) {
            errorMessage = e.message;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        print('=== FIN SOUMISSION DU FORMULAIRE ===\n');
      }
    } else {
      // Formulaire invalide, afficher un message d'erreur
      print('❌ Formulaire invalide');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez corriger les erreurs dans le formulaire')),
      );
    }
  }

  // Construit la liste des aménités en fonction des sélections de l'utilisateur
  List<String> _buildAmenitiesList() {
    List<String> amenities = [];
    // Équipements existants
    if (_hasWifi) amenities.add('wifi');
    if (_hasPool) amenities.add('pool');
    if (_hasParking) amenities.add('parking');
    if (_hasKitchen) amenities.add('kitchen');
    if (_hasAirConditioning) amenities.add('air_conditioning');
    if (_hasGym) amenities.add('gym');
    if (_hasSpa) amenities.add('spa');
    if (_hasMeetingRoom) amenities.add('meeting_room');
    if (_hasTerrace) amenities.add('terrace');
    if (_hasBalcony) amenities.add('balcony');
    // Nouveaux équipements
    if (_hasRunningWater) amenities.add('running_water');
    if (_hasHotWater) amenities.add('hot_water');
    if (_hasWaterTank) amenities.add('water_tank');
    if (_hasElectricity) amenities.add('electricity');
    if (_hasGenerator) amenities.add('generator');
    if (_hasSolarEnergy) amenities.add('solar_energy');
    if (_hasInverter) amenities.add('inverter');
    if (_hasFiberOptic) amenities.add('fiber_optic');
    if (_hasEthernet) amenities.add('ethernet');
    if (_hasFullKitchen) amenities.add('full_kitchen');
    if (_hasKitchenette) amenities.add('kitchenette');
    if (_hasRefrigerator) amenities.add('refrigerator');
    if (_hasMicrowave) amenities.add('microwave');
    if (_hasOven) amenities.add('oven');
    if (_hasFan) amenities.add('fan');
    if (_hasCelingFan) amenities.add('ceiling_fan');
    if (_hasSecurity) amenities.add('security');
    if (_hasAlarmSystem) amenities.add('alarm_system');
    if (_hasCCTV) amenities.add('cctv');
    if (_hasSecurityGuard) amenities.add('security_guard');
    return amenities;
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _bedroomsController.clear();
    _bathroomsController.clear();
    _surfaceController.clear();
    _maxGuestsController.clear();
    _priceController.clear();
    _addressController.clear();

    _hourlyRateController.clear();
    _halfDayRateController.clear();
    _fullDayRateController.clear();
    _weekendRateController.clear();

    setState(() {
      _selectedImages = [];
      _selectedPricePeriod = 'month';
      _selectedType = 'studio_meuble';
      _selectedCategory = 'residence_meublee';
      _selectedCountry = 'CI';
      _selectedRegion = '';
      _selectedCity = '';
      _hasWifi = false;
      _hasPool = false;
      _hasParking = false;
      _hasKitchen = false;
      _hasAirConditioning = false;
      _hasGym = false;
      _hasSpa = false;
      _hasMeetingRoom = false;
      _hasTerrace = false;
      _hasBalcony = false;
      _isVacationResidence = false;
      _allowsSmoking = false;
      _allowsPets = false;
      _allowsParties = false;
      _isAvailable = true;
      _hasAlternativePricing = false;

      // Réinitialiser les nouveaux équipements
      _hasRunningWater = false;
      _hasWaterTank = false;
      _hasElectricity = true;
      _hasInverter = false;
      _hasFiberOptic = false;
      _hasEthernet = false;
      _hasFullKitchen = false;
      _hasKitchenette = false;
      _hasRefrigerator = false;
      _hasMicrowave = false;
      _hasOven = false;
      _hasFan = false;
      _hasCelingFan = false;
      _hasAlarmSystem = false;
      _hasCCTV = false;
      _hasSecurityGuard = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.residence != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier la résidence' : 'Nouvelle résidence'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submitForm,
          ),
        ],
      ),
      body: BlocListener<ResidenceBloc, ResidenceState>(
        listener: (context, state) {
          if (state is ResidenceSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.of(context).pop();
          } else if (state is ResidenceError) {
            String errorMessage = state.message;
            Widget? action;

            if (state.isAuthError) {
              errorMessage =
                  'Vous devez être connecté pour effectuer cette action.';
              action = TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false);
                },
                child: const Text('SE CONNECTER'),
              );
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: theme.colorScheme.error,
                duration: const Duration(seconds: 5),
                action: action != null
                    ? SnackBarAction(
                        label: 'FERMER',
                        textColor: Colors.white,
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        },
                      )
                    : null,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Informations de base
              Text(
                'Informations de base',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la résidence',
                  hintText: 'ex: Villa Moderne',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nom est requis';
                  }
                  if (value.length < 5) {
                    return 'Le nom doit contenir au moins 5 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Décrivez la résidence...',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La description est requise';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Localisation (section à supprimer)

              // Photos
              _buildImagePreview(),

              // Caractéristiques
              Text(
                'Caractéristiques',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              // Catégorie de résidence
              DropdownButtonFormField<String>(
                isExpanded: true, // Ajoutez cette ligne
                value: _ensureCategoryExists(_selectedCategory),
                decoration: const InputDecoration(
                  labelText: 'Catégorie d\'hébergement',
                ),
                items: _residenceCategories.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value['label'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                      final types = _residenceCategories[value]!['types']
                          as List<ResidenceType>;
                      _selectedType = types[0].value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La catégorie est requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Type de résidence
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Type de résidence',
                ),
                value: _ensureTypeValueExists(_selectedType),
                items: _availableTypesForCategory.map((type) {
                  return DropdownMenuItem<String>(
                    value: type.value,
                    child: Text(type.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                      // Mettre à jour automatiquement la période de facturation
                      _updatePricePeriodBasedOnType();
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner un type de résidence';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bedroomsController,
                      decoration: const InputDecoration(
                        labelText: 'Chambres',
                        hintText: 'ex: 3',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requis';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _bathroomsController,
                      decoration: const InputDecoration(
                        labelText: 'Salles de bain',
                        hintText: 'ex: 2',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requis';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _surfaceController,
                decoration: const InputDecoration(
                  labelText: 'Surface (m²)',
                  hintText: 'ex: 120',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La surface est requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: _getPriceLabel(),
                  hintText: _getPriceHint(),
                  helperText: _getPriceHelperText(),
                  filled: true,
                  fillColor: _selectedPricePeriod == 'month'
                      ? Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.3)
                      : null,
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le prix est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _ensurePeriodExists(_selectedPricePeriod),
                decoration: InputDecoration(
                  labelText: 'Période de tarification',
                  helperText: _getFacturationHelperText(),
                  suffixIcon: Icon(
                    Icons.auto_awesome,
                    color: _isPricePeriodConsistentWithType()
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    size: 20,
                  ),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem<String>(
                    value: 'hour',
                    child: Text('Heure'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'day',
                    child: Text('Jour'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'week',
                    child: Text('Semaine'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'month',
                    child: Text('Mois'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPricePeriod = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La période de tarification est requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Section des tarifs alternatifs
              Card(
                elevation: 0,
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.3),
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tarifs alternatifs',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _hourlyRateController,
                        decoration: InputDecoration(
                          labelText: 'Tarif horaire (FCFA)',
                          hintText: 'ex: 5000',
                          filled: true,
                          fillColor: _selectedPricePeriod == 'hour'
                              ? Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withOpacity(0.3)
                              : null,
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*')),
                        ],
                        validator: (value) {
                          if (_selectedPricePeriod == 'hour' &&
                              (value == null || value.isEmpty)) {
                            return 'Le tarif horaire est requis pour ce type de résidence';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _halfDayRateController,
                        decoration: InputDecoration(
                          labelText: 'Tarif demi-journée (FCFA)',
                          hintText: 'ex: 25000',
                          filled: _selectedPricePeriod == 'day',
                          fillColor: _selectedPricePeriod == 'day'
                              ? Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withOpacity(0.3)
                              : null,
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*')),
                        ],
                        validator: (value) {
                          if (_selectedPricePeriod == 'day' &&
                              (value == null || value.isEmpty)) {
                            return 'Le tarif demi-journée est requis pour ce type de résidence';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _fullDayRateController,
                        decoration: InputDecoration(
                          labelText: 'Tarif journée (FCFA)',
                          hintText: 'ex: 50000',
                          filled: _selectedPricePeriod == 'day',
                          fillColor: _selectedPricePeriod == 'day'
                              ? Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withOpacity(0.3)
                              : null,
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*')),
                        ],
                        validator: (value) {
                          if (_selectedPricePeriod == 'day' &&
                              (value == null || value.isEmpty)) {
                            return 'Le tarif journée est requis pour ce type de résidence';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _weekendRateController,
                        decoration: InputDecoration(
                          labelText: 'Tarif week-end (FCFA)',
                          hintText: 'ex: 75000',
                          filled: _selectedPricePeriod == 'week',
                          fillColor: _selectedPricePeriod == 'week'
                              ? Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withOpacity(0.3)
                              : null,
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*')),
                        ],
                        validator: (value) {
                          if (_selectedPricePeriod == 'week' &&
                              (value == null || value.isEmpty)) {
                            return 'Le tarif week-end est requis pour ce type de résidence';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Options
              Text(
                'Options et équipements',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              // Nouvelle section d'options dynamiques
              Card(
                elevation: 0,
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.3),
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Options communes à toutes les résidences
                      Text(
                        'Options générales',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.pool,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Piscine'),
                          ],
                        ),
                        value: _hasPool,
                        onChanged: (value) => _updateAmenity('pool', value),
                      ),
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.check_circle,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Disponible'),
                          ],
                        ),
                        value: _isAvailable,
                        onChanged: (value) =>
                            setState(() => _isAvailable = value),
                      ),

// Eau
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.water_drop,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Eau courante'),
                          ],
                        ),
                        value: _hasRunningWater,
                        onChanged: (value) =>
                            setState(() => _hasRunningWater = value),
                      ),
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.hot_tub,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Eau chaude'),
                          ],
                        ),
                        value: _hasHotWater,
                        onChanged: (value) =>
                            setState(() => _hasHotWater = value),
                      ),
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.water_damage,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Réservoir d\'eau'),
                          ],
                        ),
                        value: _hasWaterTank,
                        onChanged: (value) =>
                            setState(() => _hasWaterTank = value),
                      ),

// Électricité
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.electric_bolt,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Électricité'),
                          ],
                        ),
                        value: _hasElectricity,
                        onChanged: (value) =>
                            setState(() => _hasElectricity = value),
                      ),
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.power,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Générateur'),
                          ],
                        ),
                        value: _hasGenerator,
                        onChanged: (value) =>
                            setState(() => _hasGenerator = value),
                      ),
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.solar_power,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Énergie solaire'),
                          ],
                        ),
                        value: _hasSolarEnergy,
                        onChanged: (value) =>
                            setState(() => _hasSolarEnergy = value),
                      ),
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.battery_charging_full,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Onduleur'),
                          ],
                        ),
                        value: _hasInverter,
                        onChanged: (value) =>
                            setState(() => _hasInverter = value),
                      ),

// Internet
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.wifi,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('WiFi'),
                          ],
                        ),
                        value: _hasWifi,
                        onChanged: (value) => setState(() => _hasWifi = value),
                      ),
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.fiber_new,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Fibre optique'),
                          ],
                        ),
                        value: _hasFiberOptic,
                        onChanged: (value) =>
                            setState(() => _hasFiberOptic = value),
                      ),
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.lan,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Ethernet'),
                          ],
                        ),
                        value: _hasEthernet,
                        onChanged: (value) =>
                            setState(() => _hasEthernet = value),
                      ),

// Cuisine
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.kitchen,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Cuisine'),
                          ],
                        ),
                        value: _hasKitchen,
                        onChanged: (value) =>
                            setState(() => _hasKitchen = value),
                      ),
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.kitchen,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Cuisine complète'),
                          ],
                        ),
                        value: _hasFullKitchen,
                        onChanged: (value) =>
                            setState(() => _hasFullKitchen = value),
                      ),
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.countertops,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Kitchenette'),
                          ],
                        ),
                        value: _hasKitchenette,
                        onChanged: (value) =>
                            setState(() => _hasKitchenette = value),
                      ),
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.kitchen,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Réfrigérateur'),
                          ],
                        ),
                        value: _hasRefrigerator,
                        onChanged: (value) =>
                            setState(() => _hasRefrigerator = value),
                      ),
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.microwave,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Micro-ondes'),
                          ],
                        ),
                        value: _hasMicrowave,
                        onChanged: (value) =>
                            setState(() => _hasMicrowave = value),
                      ),
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.local_fire_department,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Four'),
                          ],
                        ),
                        value: _hasOven,
                        onChanged: (value) => setState(() => _hasOven = value),
                      ),

// Refroidissement
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.ac_unit,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Climatisation'),
                          ],
                        ),
                        value: _hasAirConditioning,
                        onChanged: (value) =>
                            setState(() => _hasAirConditioning = value),
                      ),
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.air,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Ventilateur'),
                          ],
                        ),
                        value: _hasFan,
                        onChanged: (value) => setState(() => _hasFan = value),
                      ),
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.cyclone,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Ventil. plafond'),
                          ],
                        ),
                        value: _hasCelingFan,
                        onChanged: (value) =>
                            setState(() => _hasCelingFan = value),
                      ),

// Sécurité
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.security,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Sécurité'),
                          ],
                        ),
                        value: _hasSecurity,
                        onChanged: (value) =>
                            setState(() => _hasSecurity = value),
                      ),
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.alarm,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Syst. alarme'),
                          ],
                        ),
                        value: _hasAlarmSystem,
                        onChanged: (value) =>
                            setState(() => _hasAlarmSystem = value),
                      ),
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.videocam,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Caméras surveill.'),
                          ],
                        ),
                        value: _hasCCTV,
                        onChanged: (value) => setState(() => _hasCCTV = value),
                      ),
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.person,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Gardien sécu.'),
                          ],
                        ),
                        value: _hasSecurityGuard,
                        onChanged: (value) =>
                            setState(() => _hasSecurityGuard = value),
                      ),

                      Divider(),

// Options spécifiques à la catégorie
                      Text(
                        'Options spécifiques',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      ..._getCategorySpecificOptions(),

                      if (_getTypeSpecificOptions().isNotEmpty) ...[
                        Divider(),
                        Text(
                          'Options pour ${_getTypeLabel()}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        ..._getTypeSpecificOptions(),
                      ],
                    ],
                  ),
                ),
              ),

              // Section localisation améliorée (à modifier)
              Text(
                'Localisation détaillée',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: InputDecoration(
                  labelText: 'Pays',
                  prefixIcon: Icon(Icons.flag),
                  border: OutlineInputBorder(),
                ),
                items: _availableCountries.map((country) {
                  return DropdownMenuItem<String>(
                    value: country.code,
                    child: Text(country.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCountry = value;
                      _selectedRegion = _getDefaultRegion(value);
                      _selectedCity = _getDefaultCity(_selectedRegion);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _getRegionsForCountry(_selectedCountry).any((region) => region.code == _selectedRegion) 
                    ? _selectedRegion 
                    : null,
                decoration: InputDecoration(
                  labelText: 'Ville',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                ),
                items: _getRegionsForCountry(_selectedCountry).map((region) {
                  return DropdownMenuItem<String>(
                    value: region.code,
                    child: Text(region.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRegion = value;
                      _selectedCity = _getDefaultCity(value);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _ensureCityExists(_selectedCity, _selectedRegion),
                decoration: InputDecoration(
                  labelText: 'Commune / Quartier',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                ),
                items: _getCitiesForRegion(_selectedRegion).map((city) {
                  return DropdownMenuItem<String>(
                    value: city.code,
                    child: Text(city.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCity = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              AddressAutocompleteField(
                initialAddress: _formattedAddress ?? _addressController.text,
                onAddressSelected: (result) {
                  setState(() {
                    _addressController.text = result.formattedAddress;
                    _formattedAddress = result.formattedAddress;
                    if (result.coordinates != null) {
                      _latitude = result.coordinates!.latitude;
                      _longitude = result.coordinates!.longitude;
                    }
                    
                    // Extraire les composantes d'adresse si disponibles
                    if (result.components != null) {
                      final components = result.components!;
                      if (components['country'] != null) {
                        // Si nous avons un code pays dans les composantes,
                        // nous pourrions le mapper à nos codes pays internes
                        // Pour l'instant, nous gardons simplement la vérification de base
                      }
                      
                      if (components['city'] != null) {
                        _cityController.text = components['city'];
                      }
                    }
                  });
                },
                label: 'Adresse exacte',
                hintText: 'Rechercher une adresse...',
                showMap: false, // Désactivons la carte dans le widget car nous affichons notre propre carte
              ),

              const SizedBox(height: 16),
              
              // Affichage de la carte Google Maps si des coordonnées sont disponibles
              if (_latitude != null && _longitude != null)
                _buildGoogleMap(),
                
              const SizedBox(height: 16),
              
              // Section de sélection sur la carte
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.map,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Position exacte sur la carte',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sélectionnez l\'emplacement précis de votre résidence en touchant la carte ou en recherchant une adresse.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      // Bouton de géolocalisation automatique
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _getCurrentLocation,
                              icon: const Icon(Icons.my_location),
                              label: const Text('Ma position actuelle'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // À remplacer par une véritable implémentation de sélection
                                setState(() {
                                  _latitude = 5.3364504;
                                  _longitude = -4.0266486;
                                  _formattedAddress = 'Abidjan, Côte d\'Ivoire';
                                });
                              },
                              icon: const Icon(Icons.location_searching),
                              label: const Text('Sélectionner'),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Utilisation d'un conteneur simple avec gestion d'état pour la sélection de localisation
                      Container(
                        margin: EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Bouton de recherche d'adresse
                            ElevatedButton.icon(
                              icon: Icon(Icons.search),
                              label: Text('Rechercher une adresse'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                // Implémentation temporaire: coordonnées fictives pour démonstration
                                // À remplacer par une véritable implémentation de sélection
                                setState(() {
                                  _latitude = 5.3364504;
                                  _longitude = -4.0266486;
                                  _formattedAddress = 'Abidjan, Côte d\'Ivoire';
                                });
                              },
                            ),
                            SizedBox(height: 12),
                            // Affichage de l'adresse sélectionnée
                            if (_latitude != null && _longitude != null)
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Theme.of(context).dividerColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Position sélectionnée:',
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _formattedAddress ?? 'Adresse non disponible',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Coordonnées: ${_latitude?.toStringAsFixed(6)}, ${_longitude?.toStringAsFixed(6)}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    SizedBox(height: 8),
                                    // Bouton pour réinitialiser la sélection
                                    TextButton.icon(
                                      icon: Icon(Icons.refresh),
                                      label: Text('Modifier la position'),
                                      onPressed: () {
                                        setState(() {
                                          _latitude = null;
                                          _longitude = null;
                                          _formattedAddress = null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_formattedAddress != null) ...[  
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Position sélectionnée: $_formattedAddress',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Section des méthodes de paiement
              Text(
                'Méthodes de paiement acceptées',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Sélectionnez les méthodes de paiement que vous acceptez. Les paiements passeront par ChapeChape qui prélèvera une commission de 10%.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  _buildPaymentMethodChip('cash', 'Espèces', Icons.money),
                  _buildPaymentMethodChip('wave', 'Wave', Icons.waves),
                  _buildPaymentMethodChip(
                      'orange_money', 'Orange Money', Icons.phone_android),
                  _buildPaymentMethodChip(
                      'moov_money', 'Moov Money', Icons.phone_android),
                  _buildPaymentMethodChip(
                      'mtn_money', 'MTN Money', Icons.phone_android),
                  _buildPaymentMethodChip(
                      'credit_card', 'Carte bancaire', Icons.credit_card),
                  _buildPaymentMethodChip('bank_transfer', 'Virement bancaire',
                      Icons.account_balance),
                ],
              ),

              const SizedBox(height: 32),

              // Section du mode de réservation
              ReservationModeConfig(
                currentMode: _selectedReservationMode,
                onModeChanged: (String newMode) {
                  setState(() {
                    _selectedReservationMode = newMode;
                  });
                },
                enabled: true,
                title: 'Configuration des réservations',
              ),

              const SizedBox(height: 32),

              FilledButton(
                onPressed: _submitForm,
                child: Text(isEditing ? 'Mettre à jour' : 'Créer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Méthode pour vérifier si la période de facturation est cohérente avec le type de résidence
  bool _isPricePeriodConsistentWithType() {
    final expectedPeriod = _getExpectedPricePeriodForType(_selectedType);
    return _selectedPricePeriod == expectedPeriod;
  }

  // Méthode pour obtenir la période de facturation attendue pour un type de résidence
  String _getExpectedPricePeriodForType(String type) {
    // Facturation à l'heure pour les hébergements de passage
    if (['hotel_passage', 'motel', 'chambres_passage'].contains(type)) {
      return 'hour';
    }

    // Facturation à la journée pour les séjours courts
    if ([
      'studio_meuble',
      'guest_house',
      'lodge',
      'case_traditionnelle',
      'campement_touristique',
      'maison_flottante',
      'boutiqueHotel',
      'aubergeEtMaisonDHotes'
    ].contains(type)) {
      return 'day';
    }

    // Facturation à la semaine pour certains types spécifiques
    if ([
      'maison_hotes_economique',
      'residence_familiale',
    ].contains(type)) {
      return 'week';
    }

    // Par défaut, facturation au mois pour les locations longue durée
    return 'month';
  }

  // Méthode pour mettre à jour automatiquement la période de facturation en fonction du type
  void _updatePricePeriodBasedOnType() {
    // Obtenir la période recommandée
    final recommendedPeriod = _getExpectedPricePeriodForType(_selectedType);

    // Vérifier si la période recommandée est valide
    final validPeriods = ['hour', 'day', 'week', 'month'];

    if (!validPeriods.contains(recommendedPeriod)) {
      print(
          '⚠️ Période de facturation invalide: $recommendedPeriod. Utilisation de "day" par défaut.');
      setState(() {
        _selectedPricePeriod = 'day';
      });
      return;
    }

    setState(() {
      _selectedPricePeriod = recommendedPeriod;
      print('✅ Période de facturation mise à jour: $_selectedPricePeriod');
    });
  }

  // Méthode pour obtenir le texte d'aide pour la période de facturation
  String _getFacturationHelperText() {
    // Obtenir la période recommandée pour le type sélectionné
    final recommendedPeriod = _getExpectedPricePeriodForType(_selectedType);

    // Préparer le texte en fonction du type de résidence
    switch (_selectedType) {
      case 'hotel_passage':
      case 'motel':
      case 'chambres_passage':
        return 'Les hébergements de passage sont généralement facturés à l\'heure';

      case 'studio_meuble':
      case 'guest_house':
      case 'lodge':
      case 'campement_touristique':
      case 'case_traditionnelle':
      case 'maison_flottante':
        return 'Les séjours courts sont généralement facturés à la journée';

      case 'maison_hotes_economique':
      case 'residence_familiale':
        return 'Ce type d\'hébergement est souvent facturé à la semaine';

      default:
        return 'Sélectionnez la période de tarification appropriée';
    }
  }

  String _getPriceLabel() {
    switch (_selectedPricePeriod) {
      case 'hour':
        return 'Prix par heure (FCFA)';
      case 'day':
        return 'Prix par jour (FCFA)';
      case 'week':
        return 'Prix par semaine (FCFA)';
      case 'month':
        return 'Prix par mois (FCFA)';
      default:
        return 'Prix (FCFA)';
    }
  }

  String _getPriceHint() {
    switch (_selectedPricePeriod) {
      case 'hour':
        return 'ex: 5000';
      case 'day':
        return 'ex: 25000';
      case 'week':
        return 'ex: 150000';
      case 'month':
        return 'ex: 500000';
      default:
        return 'ex: 150000';
    }
  }

  String _getPriceHelperText() {
    switch (_selectedPricePeriod) {
      case 'hour':
        return 'Ce tarif s\'applique pour une location à l\'heure (hôtels de passage, etc.)';
      case 'day':
        return 'Ce tarif s\'applique pour une location journalière (maisons d\'hôtes, lodges, etc.)';
      case 'week':
        return 'Ce tarif s\'applique pour une location hebdomadaire (maisons d\'hôtes économiques, etc.)';
      case 'month':
        return 'Ce tarif s\'applique pour une location mensuelle (appartements, villas, etc.)';
      default:
        return 'Sélectionnez une période de tarification adaptée à votre type de résidence';
    }
  }

  // Méthode pour obtenir les options spécifiques à la catégorie
  List<Widget> _getCategorySpecificOptions() {
    List<Widget> options = [];

    switch (_selectedCategory) {
      case 'residence_meublee':
        options.add(SwitchListTile(
          title: Row(
            children: [
              Icon(Icons.ac_unit,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text('Climatisation'),
            ],
          ),
          value: _hasAirConditioning,
          onChanged: (value) => _updateAmenity('air_conditioning', value),
        ));
        options.add(SwitchListTile(
          title: Row(
            children: [
              Icon(Icons.wifi,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text('Wi-Fi gratuit'),
            ],
          ),
          value: _hasWifi,
          onChanged: (value) => _updateAmenity('wifi', value),
        ));
        options.add(SwitchListTile(
          title: Row(
            children: [
              Icon(Icons.local_parking,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text('Parking'),
            ],
          ),
          value: _hasParking,
          onChanged: (value) => _updateAmenity('parking', value),
        ));
        options.add(SwitchListTile(
          title: Row(
            children: [
              Icon(Icons.kitchen,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text('Cuisine équipée'),
            ],
          ),
          value: _hasKitchen,
          onChanged: (value) => _updateAmenity('kitchen', value),
        ));
        break;

      case 'hotel':
        options.add(SwitchListTile(
          title: Row(
            children: [
              Icon(Icons.room_service,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text('Service de chambre'),
            ],
          ),
          value: _hasRoomService,
          onChanged: (value) => _updateAmenity('room_service', value),
        ));
        options.add(SwitchListTile(
          title: Row(
            children: [
              Icon(Icons.restaurant,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text('Restaurant'),
            ],
          ),
          value: _hasRestaurant,
          onChanged: (value) => _updateAmenity('restaurant', value),
        ));
        options.add(SwitchListTile(
          title: Row(
            children: [
              Icon(Icons.local_bar,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text('Bar'),
            ],
          ),
          value: _hasBar,
          onChanged: (value) => _updateAmenity('bar', value),
        ));
        break;

      case 'hebergement_insolite':
        options.add(SwitchListTile(
          title: Row(
            children: [
              Icon(Icons.nature_people,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text('Vue sur la nature'),
            ],
          ),
          value: _hasGarden,
          onChanged: (value) => _updateAmenity('garden', value),
        ));
        options.add(SwitchListTile(
          title: Row(
            children: [
              Icon(Icons.solar_power,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text('Énergie solaire'),
            ],
          ),
          value: _hasSolarEnergy,
          onChanged: (value) => _updateAmenity('solar_energy', value),
        ));
        break;

      case 'colocation':
        options.add(SwitchListTile(
          title: Row(
            children: [
              Icon(Icons.kitchen,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text('Cuisine partagée'),
            ],
          ),
          value: _hasSharedKitchen,
          onChanged: (value) => _updateAmenity('shared_kitchen', value),
        ));
        options.add(SwitchListTile(
          title: Row(
            children: [
              Icon(Icons.local_laundry_service,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text('Buanderie'),
            ],
          ),
          value: _hasLaundry,
          onChanged: (value) => _updateAmenity('laundry', value),
        ));
        break;

      case 'residence_longue_duree':
        options.add(SwitchListTile(
          title: Row(
            children: [
              Icon(Icons.security,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text('Sécurité 24/7'),
            ],
          ),
          value: _hasSecurity,
          onChanged: (value) => _updateAmenity('security', value),
        ));
        options.add(SwitchListTile(
          title: Row(
            children: [
              Icon(Icons.electrical_services,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text('Générateur de secours'),
            ],
          ),
          value: _hasGenerator,
          onChanged: (value) => _updateAmenity('generator', value),
        ));
        break;

      case 'hebergement_economique':
        options.add(SwitchListTile(
          title: Row(
            children: [
              Icon(Icons.clean_hands,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text('Service de ménage'),
            ],
          ),
          value: _hasCleaning,
          onChanged: (value) => _updateAmenity('cleaning', value),
        ));
        options.add(SwitchListTile(
          title: Row(
            children: [
              Icon(Icons.tv,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text('Télévision'),
            ],
          ),
          value: _hasTv,
          onChanged: (value) => _updateAmenity('tv', value),
        ));
        break;
    }

    // Si aucune option spécifique n'est définie pour cette catégorie
    if (options.isEmpty) {
      options.add(Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Pas d\'options spécifiques pour cette catégorie',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      ));
    }

    return options;
  }

  // Méthode pour obtenir les options spécifiques au type
  List<Widget> _getTypeSpecificOptions() {
    List<Widget> options = [];

    switch (_selectedType) {
      case 'hotel_luxe':
        options.add(SwitchListTile(
          title: Row(
            children: [
              Icon(Icons.spa,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text('Spa / Bien-être'),
            ],
          ),
          value: _hasSpa,
          onChanged: (value) => _updateAmenity('spa', value),
        ));
        options.add(SwitchListTile(
          title: Row(
            children: [
              Icon(Icons.fitness_center,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text('Salle de sport'),
            ],
          ),
          value: _hasGym,
          onChanged: (value) => _updateAmenity('gym', value),
        ));
        break;

      case 'boutique_hotel':
        options.add(SwitchListTile(
          title: Row(
            children: [
              Icon(Icons.meeting_room,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text('Salle de réunion'),
            ],
          ),
          value: _hasMeetingRoom,
          onChanged: (value) => _updateAmenity('meeting_room', value),
        ));
        break;

      case 'villa_meublee':
      case 'villa_vide':
        options.add(SwitchListTile(
          title: Row(
            children: [
              Icon(Icons.deck,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text('Terrasse'),
            ],
          ),
          value: _hasTerrace,
          onChanged: (value) => _updateAmenity('terrace', value),
        ));
        break;

      case 'appartement_meuble':
      case 'penthouse':
        options.add(SwitchListTile(
          title: Row(
            children: [
              Icon(Icons.balcony,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text('Balcon'),
            ],
          ),
          value: _hasBalcony,
          onChanged: (value) => _updateAmenity('balcony', value),
        ));
        break;

      case 'residence_universitaire':
        options.add(SwitchListTile(
          title: Row(
            children: [
              Icon(Icons.info,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text('Résidence de vacances'),
            ],
          ),
          value: _isVacationResidence,
          onChanged: (value) => _updateAmenity('isVacationResidence', value),
        ));
        break;
    }

    return options;
  }

  // Méthode pour obtenir le label du type de résidence sélectionné
  String _getTypeLabel() {
    for (var category in _residenceCategories.values) {
      final types = category['types'] as List<ResidenceType>;
      for (var type in types) {
        if (type.value == _selectedType) {
          return type.label;
        }
      }
    }
    return 'ce type de résidence';
  }

  // Méthode pour obtenir la région par défaut pour un pays
  String _getDefaultRegion(String countryCode) {
    final regions = _regionsByCountry[countryCode];
    if (regions != null && regions.isNotEmpty) {
      return regions.first.code;
    }
    return '';
  }

  // Méthode pour obtenir la ville par défaut pour une région
  String _getDefaultCity(String regionCode) {
    final cities = _citiesByRegion[regionCode];
    if (cities != null && cities.isNotEmpty) {
      return cities.first.code;
    }
    return '';
  }

  // Méthode pour obtenir les régions d'un pays
  List<LocationItem> _getRegionsForCountry(String countryCode) {
    return _regionsByCountry[countryCode] ?? [];
  }

  // Méthode pour obtenir les villes d'une région
  List<LocationItem> _getCitiesForRegion(String regionCode) {
    return _citiesByRegion[regionCode] ?? [];
  }

  // Méthode pour obtenir le nom du pays à partir du code
  String _getCountryName(String countryCode) {
    for (var country in _availableCountries) {
      if (country.code == countryCode) {
        return country.name;
      }
    }
    return '';
  }

  // Méthode pour obtenir le nom de la région à partir du code
  String _getRegionName(String regionCode) {
    final regions = _regionsByCountry[_selectedCountry] ?? [];
    for (var region in regions) {
      if (region.code == regionCode) {
        return region.name;
      }
    }
    return '';
  }

  // Méthode pour obtenir le nom de la ville à partir du code
  String _getCityName(String cityCode) {
    final cities = _citiesByRegion[_selectedRegion] ?? [];
    for (var city in cities) {
      if (city.code == cityCode) {
        return city.name;
      }
    }
    return '';
  }

  // Méthode pour obtenir le nom de la ville sélectionnée
  String _getSelectedCityName() {
    return _getCityName(_selectedCity);
  }


  // Méthode pour obtenir la catégorie à partir du type
  String _getCategoryFromType(String type) {
    for (var category in _residenceCategories.keys) {
      final types =
          _residenceCategories[category]!['types'] as List<ResidenceType>;
      for (var residenceType in types) {
        if (residenceType.value == type) {
          return category;
        }
      }
    }
    // Si le type n'est pas trouvé, retourner la catégorie par défaut
    return 'residence_meublee';
  }

  // Méthode pour convertir un type backend en type frontend lors de l'édition
  String _mapBackendTypeToFrontendType(String backendType) {
    print('🔍 Conversion du type: "$backendType"');

    // Normaliser le type (enlever espaces en trop, mettre en minuscules)
    final normalizedType = backendType.toLowerCase().trim();

    // Mapping explicite et complet entre les types backend et frontend
    final Map<String, String> typeMapping = {
      // Types d'appartements
      'apartment': 'appartement_meuble',
      'furnished_apartment': 'appartement_meuble',
      'apartment_building': 'immeuble',
      'penthouse': 'penthouse',
      'loft': 'loft',
      'attic': 'grenier',

      // Types de studios
      'studio': 'studio_meuble',
      'furnished_studio': 'studio_meuble',

      // Types de villas
      'villa': 'villa_meublee',
      'house': 'villa_meublee',
      'furnished_villa': 'villa_meublee',
      'unfurnished_villa': 'villa_vide',

      // Types d'hôtels
      'hotel': 'hotel_passage',
      'boutique_hotel': 'boutique_hotel',
      'luxury_hotel': 'hotel_luxe',
      'motel': 'motel',
      'guest_house': 'guest_house',
      'hotel_residence': 'residence_hoteliere',

      // Hébergements insolites
      'bungalow': 'bungalow',
      'lodge': 'lodge',
      'ecolodge': 'lodge',
      'traditional_hut': 'case_traditionnelle',
      'floating_house': 'maison_flottante',
      'tourist_camp': 'campement_touristique',

      // Colocation
      'room': 'chambre_colocation',
      'coliving': 'coliving',
      'guest_house_room': 'maison_hotes',
      'university_residence': 'residence_universitaire',
      'dormitory': 'cite_dortoir',

      // Résidences longue durée
      'unfurnished_apartment': 'appartement_vide',
      'building': 'immeuble',
      'shared_court': 'cour_commune',

      // Économiques
      'budget_house': 'maison_hotes_economique',
      'family_residence': 'residence_familiale',
      'short_stay_rooms': 'chambres_passage',
    };

    // Vérifier d'abord si le type est déjà un type frontend valide
    for (var category in _residenceCategories.keys) {
      final types =
          _residenceCategories[category]!['types'] as List<ResidenceType>;
      for (var residenceType in types) {
        if (residenceType.value.toLowerCase() == normalizedType) {
          print('✅ Type déjà valide: $backendType → ${residenceType.value}');
          return residenceType
              .value; // Retourner le type exact avec la casse correcte
        }
      }
    }

    // Essayer de trouver une correspondance dans le mapping
    if (typeMapping.containsKey(normalizedType)) {
      final mappedType = typeMapping[normalizedType]!;
      print('✅ Type mappé: $backendType → $mappedType');
      return mappedType;
    }

    // Fallback basé sur des préfixes pour les types inconnus
    for (var entry in typeMapping.entries) {
      if (normalizedType.startsWith(entry.key.split('_')[0])) {
        print('⚠️ Type partiellement mappé: $backendType → ${entry.value}');
        return entry.value;
      }
    }

    // Dernier recours: choisir un type par défaut selon la première lettre
    print('⚠️ Type inconnu: $backendType. Utilisation d\'un type par défaut.');
    if (normalizedType.startsWith('s')) {
      return 'studio_meuble';
    } else if (normalizedType.startsWith('v') ||
        normalizedType.startsWith('h')) {
      return 'villa_meublee';
    } else if (normalizedType.startsWith('h')) {
      return 'hotel_passage';
    } else {
      return 'appartement_meuble'; // Type par défaut
    }
  }

  // Nouvelle méthode pour s'assurer que le type sélectionné est valide
  void _ensureSelectedTypeIsValid() {
    if (_selectedType == null || _selectedType.isEmpty) {
      print('⚠️ Type non défini ou vide, utilisation d\'un type par défaut');
      _selectedType = 'appartement_meuble';
      _selectedCategory = _getCategoryFromType(_selectedType);
      return;
    }

    // Vérifier si le type sélectionné existe dans la catégorie actuelle
    bool typeExistsInCategory =
        _availableTypesForCategory.any((type) => type.value == _selectedType);

    if (!typeExistsInCategory) {
      print('⚠️ Type invalide dans la catégorie: $_selectedType');

      // Chercher le type dans toutes les catégories
      String? foundCategory;
      for (var category in _residenceCategories.keys) {
        final types = _residenceCategories[category]!['types']
            as List<ResidenceType>;
        if (types.any((type) => type.value == _selectedType)) {
          foundCategory = category;
          break;
        }
      }

      // Si le type existe dans une autre catégorie, changer de catégorie
      if (foundCategory != null) {
        print('✅ Type trouvé dans une autre catégorie: $foundCategory');
        _selectedCategory = foundCategory;
      } else {
        // Sinon, utiliser le premier type de la catégorie actuelle
        print(
            '⚠️ Type non trouvé dans aucune catégorie, utilisation du premier type disponible');
        _selectedType = _availableTypesForCategory.first.value;
      }
    }
  }

  // Méthode pour s'assurer que la valeur du dropdown existe dans les options
  String _ensureTypeValueExists(String typeValue) {
    // Vérifier si la valeur existe dans les options disponibles
    bool valueExists =
        _availableTypesForCategory.any((type) => type.value == typeValue);

    // Si la valeur n'existe pas, retourner la première option disponible
    if (!valueExists && _availableTypesForCategory.isNotEmpty) {
      print(
          '⚠️ Valeur non trouvée dans les options du dropdown: $typeValue. Utilisation de la première option.');
      return _availableTypesForCategory.first.value;
    }

    return typeValue;
  }

  // Méthode pour s'assurer que la catégorie existe
  String _ensureCategoryExists(String categoryValue) {
    if (!_residenceCategories.containsKey(categoryValue)) {
      print(
          '⚠️ Catégorie non trouvée: $categoryValue. Utilisation de la première catégorie disponible.');
      return _residenceCategories.keys.first;
    }
    return categoryValue;
  }

  // Méthode pour s'assurer que la période existe
  String _ensurePeriodExists(String periodValue) {
    final validPeriods = ['hour', 'day', 'week', 'month'];
    if (!validPeriods.contains(periodValue)) {
      print(
          '⚠️ Période non valide: $periodValue. Utilisation de "day" par défaut.');
      return 'day';
    }
    return periodValue;
  }

  // Méthode spécifique pour vérifier si la ville existe dans la région sélectionnée
  String _ensureCityExists(String cityCode, String regionCode) {
    // Si la liste des villes est vide, retourner null
    if (_getCitiesForRegion(regionCode).isEmpty) {
      print('⚠️ Aucune ville disponible pour la région: $regionCode');
      return '';
    }

    // Vérifier si la ville existe dans la région
    bool cityExists =
        _getCitiesForRegion(regionCode).any((city) => city.code == cityCode);

    // Si la ville n'existe pas, utiliser la première ville disponible
    if (!cityExists) {
      print(
          '⚠️ Ville non trouvée dans la région: $cityCode (région: $regionCode). Utilisation de la première ville disponible.');
      return _getCitiesForRegion(regionCode).first.code;
    }

    // Sinon, retourner la ville sélectionnée
    return cityCode;
  }

  // Méthode pour construire la liste des méthodes de paiement sélectionnées
  List<String> _buildPaymentMethodsList() {
    List<String> paymentMethods = [];
    if (_acceptsCash) paymentMethods.add('cash');
    if (_acceptsWave) paymentMethods.add('wave');
    if (_acceptsOrangeMoney) paymentMethods.add('orange_money');
    if (_acceptsMoovMoney) paymentMethods.add('moov_money');
    if (_acceptsMtnMoney) paymentMethods.add('mtn_money');
    if (_acceptsCreditCard) paymentMethods.add('credit_card');
    if (_acceptsBankTransfer) paymentMethods.add('bank_transfer');
    return paymentMethods;
  }

  // Méthode pour construire un chip de méthode de paiement
  Widget _buildPaymentMethodChip(
      String paymentMethod, String label, IconData icon) {
    return ChoiceChip(
      label: Text(label),
      avatar: Icon(icon),
      selected: _getPaymentMethodSelected(paymentMethod),
      onSelected: (value) {
        setState(() {
          _updatePaymentMethod(paymentMethod, value);
        });
      },
    );
  }

  // Méthode pour obtenir l'état de sélection d'une méthode de paiement
  bool _getPaymentMethodSelected(String paymentMethod) {
    switch (paymentMethod) {
      case 'cash':
        return _acceptsCash;
      case 'wave':
        return _acceptsWave;
      case 'orange_money':
        return _acceptsOrangeMoney;
      case 'moov_money':
        return _acceptsMoovMoney;
      case 'mtn_money':
        return _acceptsMtnMoney;
      case 'credit_card':
        return _acceptsCreditCard;
      case 'bank_transfer':
        return _acceptsBankTransfer;
      default:
        return false;
    }
  }

  // Méthode pour mettre à jour l'état de sélection d'une méthode de paiement
  void _updatePaymentMethod(String paymentMethod, bool value) {
    switch (paymentMethod) {
      case 'cash':
        _acceptsCash = value;
        break;
      case 'wave':
        _acceptsWave = value;
        break;
      case 'orange_money':
        _acceptsOrangeMoney = value;
        break;
      case 'moov_money':
        _acceptsMoovMoney = value;
        break;
      case 'mtn_money':
        _acceptsMtnMoney = value;
        break;
      case 'credit_card':
        _acceptsCreditCard = value;
        break;
      case 'bank_transfer':
        _acceptsBankTransfer = value;
        break;
    }
  }
}

class ResidenceType {
  final String value;
  final String label;

  ResidenceType(this.value, this.label);
}
