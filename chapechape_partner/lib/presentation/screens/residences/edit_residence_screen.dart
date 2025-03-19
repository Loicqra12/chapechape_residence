import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../../../core/blocs/residence/residence_bloc.dart';
import '../../../core/models/residence/residence.dart';
import '../../../core/services/api/residence_service.dart';
import '../../../core/config/app_config.dart';

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
  String _selectedType = 'studio_meuble';
  String _selectedCategory = 'residence_meublee';
  String _selectedPricePeriod = 'month'; // Valeurs possibles: hour, day, week, month
  bool _hasPool = false;
  bool _isVacationResidence = false;
  bool _isSpecialResidence = false;
  bool _isAvailable = true;
  bool _isLoading = false;
  
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
  
  // Variables pour la localisation
  String _selectedCountry = 'CI'; // Côte d'Ivoire par défaut
  String _selectedRegion = 'AB'; // Abidjan par défaut
  String _selectedCity = 'CO'; // Cocody par défaut

  // Données des pays, régions et villes
  final List<LocationItem> _availableCountries = [
    LocationItem('CI', 'Côte d\'Ivoire'),
    LocationItem('SN', 'Sénégal'),
    LocationItem('ML', 'Mali'),
    LocationItem('BF', 'Burkina Faso'),
    LocationItem('GH', 'Ghana'),
    LocationItem('GN', 'Guinée'),
    LocationItem('BJ', 'Bénin'),
    LocationItem('TG', 'Togo'),
    LocationItem('NE', 'Niger'),
    LocationItem('CM', 'Cameroun'),
  ];
  
  // Map des régions par pays (simplifiée pour l'exemple, à compléter)
  Map<String, List<LocationItem>> _regionsByCountry = {
    'CI': [ // Côte d'Ivoire
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
    'SN': [ // Sénégal
      LocationItem('DK', 'Dakar'),
      LocationItem('TH', 'Thiès'),
      LocationItem('ZI', 'Ziguinchor'),
      LocationItem('ST', 'Saint-Louis'),
    ],
    // Autres pays...
  };
  
  // Map des villes par région (simplifiée pour l'exemple, à compléter)
  Map<String, List<LocationItem>> _citiesByRegion = {
    'AB': [ // Abidjan
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
    'YA': [ // Yamoussoukro
      LocationItem('CE', 'Centre'),
      LocationItem('NO', 'Nord'),
      LocationItem('ES', 'Est'),
      LocationItem('OU', 'Ouest'),
    ],
    // Nouvelles zones côtières et plages
    'ZC': [ // Zones côtières et plages
      LocationItem('GB', 'Grand-Bassam'),
      LocationItem('AS', 'Assinie'),
      LocationItem('JV', 'Jacqueville'),
      LocationItem('GL', 'Grand-Lahou'),
      LocationItem('SP', 'San Pedro'),
      LocationItem('SS', 'Sassandra'),
    ],
    // Autres régions...
  };

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
    return _residenceCategories[_selectedCategory]!['types'] as List<ResidenceType>;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.residence?.name);
    _descriptionController = TextEditingController(text: widget.residence?.description);
    _addressController = TextEditingController(text: widget.residence?.address);
    _cityController = TextEditingController(text: widget.residence?.city);
    _priceController = TextEditingController(
      text: widget.residence?.price.toString() ?? '0',
    );
    _bedroomsController = TextEditingController(
      text: widget.residence?.bedrooms.toString() ?? '0',
    );
    _bathroomsController = TextEditingController(
      text: widget.residence?.bathrooms.toString() ?? '0',
    );
    _surfaceController = TextEditingController(
      text: widget.residence?.surface.toString() ?? '0',
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
    
    // Initialiser le type et la catégorie s'il s'agit d'une édition
    if (widget.residence != null) {
      _selectedType = widget.residence?.type ?? 'studio_meuble';
      
      // Déterminer la catégorie en fonction du type
      bool categoryFound = false;
      for (var category in _residenceCategories.keys) {
        final types = _residenceCategories[category]!['types'] as List<dynamic>;
        for (var type in types) {
          if (type.value == _selectedType) {
            _selectedCategory = category;
            categoryFound = true;
            break;
          }
        }
        if (categoryFound) break;
      }

      // Si la catégorie n'est pas trouvée, utiliser la première catégorie et son premier type
      if (!categoryFound) {
        _selectedCategory = _residenceCategories.keys.first;
        final firstTypes = _residenceCategories[_selectedCategory]!['types'] as List<dynamic>;
        if (firstTypes.isNotEmpty) {
          _selectedType = firstTypes.first.value;
        }
      }
      
      // Pour les résidences existantes, mettre à jour le mode de facturation en fonction du type
      _selectedPricePeriod = widget.residence?.pricePeriod ?? 'month';
      
      // Si le mode de facturation n'est pas cohérent avec le type, le mettre à jour
      if (!_isPricePeriodConsistentWithType()) {
        _updatePricePeriodBasedOnType();
      }
      
      // Initialiser les options si disponibles
      Map<String, dynamic>? options = widget.residence?.options;
      if (options != null) {
        _hasPool = options['hasPool'] ?? false;
        _isVacationResidence = options['isVacationResidence'] ?? false;
        _isSpecialResidence = options['isSpecialResidence'] ?? false;
        _hasAirConditioning = options['hasAirConditioning'] ?? false;
        _hasWifi = options['hasWifi'] ?? false;
        _hasParking = options['hasParking'] ?? false;
        _hasSecurity = options['hasSecurity'] ?? false;
        _hasCleaning = options['hasCleaning'] ?? false;
        _hasHotWater = options['hasHotWater'] ?? false;
        _hasBalcony = options['hasBalcony'] ?? false;
        _hasGarden = options['hasGarden'] ?? false;
        _hasTerrace = options['hasTerrace'] ?? false;
        _hasKitchen = options['hasKitchen'] ?? false;
        _hasSharedKitchen = options['hasSharedKitchen'] ?? false;
        _hasTv = options['hasTv'] ?? false;
        _hasGenerator = options['hasGenerator'] ?? false;
        _hasSolarEnergy = options['hasSolarEnergy'] ?? false;
        _hasGym = options['hasGym'] ?? false;
        _hasSpa = options['hasSpa'] ?? false;
        _hasRestaurant = options['hasRestaurant'] ?? false;
        _hasBar = options['hasBar'] ?? false;
        _hasRoomService = options['hasRoomService'] ?? false;
        _hasLaundry = options['hasLaundry'] ?? false;
        _hasMeetingRoom = options['hasMeetingRoom'] ?? false;
      }
      
      // Initialiser la localisation
      if (widget.residence?.country != null) {
        _selectedCountry = widget.residence?.country ?? 'CI';
      }
      if (widget.residence?.region != null) {
        _selectedRegion = widget.residence?.region ?? 'AB';
      }
      if (widget.residence?.cityCode != null) {
        _selectedCity = widget.residence?.cityCode ?? 'CO';
      }
    } else {
      // Pour les nouvelles résidences, définir le mode de facturation en fonction du type par défaut
      _updatePricePeriodBasedOnType();
    }
    
    _hasPool = widget.residence?.hasPool ?? false;
    _isVacationResidence = widget.residence?.isVacationResidence ?? false;
    _isSpecialResidence = widget.residence?.isSpecialResidence ?? false;
    _isAvailable = widget.residence?.isAvailable ?? true;
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
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection des images: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
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
        const SizedBox(height: 16),
        if (_selectedImages.isEmpty)
          Center(
            child: TextButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Ajouter des photos'),
            ),
          )
        else
          Column(
            children: [
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _selectedImages.length) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: IconButton(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add_photo_alternate),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                          ),
                        ),
                      );
                    }

                    return Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: FutureBuilder<Uint8List>(
                            future: _selectedImages[index].readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                );
                              }
                              return Container(
                                height: 100,
                                width: 100,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.error,
                              foregroundColor: Theme.of(context).colorScheme.onError,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Créer un objet pour les options
      Map<String, dynamic> options = {
        'hasPool': _hasPool,
        'isVacationResidence': _isVacationResidence,
        'isSpecialResidence': _isSpecialResidence,
        'hasAirConditioning': _hasAirConditioning,
        'hasWifi': _hasWifi,
        'hasParking': _hasParking,
        'hasSecurity': _hasSecurity,
        'hasCleaning': _hasCleaning,
        'hasHotWater': _hasHotWater,
        'hasBalcony': _hasBalcony,
        'hasGarden': _hasGarden,
        'hasTerrace': _hasTerrace,
        'hasKitchen': _hasKitchen,
        'hasSharedKitchen': _hasSharedKitchen,
        'hasTv': _hasTv,
        'hasGenerator': _hasGenerator,
        'hasSolarEnergy': _hasSolarEnergy,
        'hasGym': _hasGym,
        'hasSpa': _hasSpa,
        'hasRestaurant': _hasRestaurant,
        'hasBar': _hasBar,
        'hasRoomService': _hasRoomService,
        'hasLaundry': _hasLaundry,
        'hasMeetingRoom': _hasMeetingRoom,
      };
      
      // Récupérer les noms des localités
      String countryName = _getCountryName(_selectedCountry);
      String regionName = _getRegionName(_selectedRegion);
      String cityName = _getCityName(_selectedCity);

      final data = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'address': _addressController.text,
        'city':  _getRegionName(_selectedRegion),
        'price': double.parse(_priceController.text),
        'bedrooms': int.parse(_bedroomsController.text),
        'bathrooms': int.parse(_bathroomsController.text),
        'surface': double.parse(_surfaceController.text),
        'type': _selectedType,
        'category': _selectedCategory,
        'hasPool': _hasPool,
        'isVacationResidence': _isVacationResidence,
        'isSpecialResidence': _isSpecialResidence,
        'isAvailable': _isAvailable,
        'hourlyRate': double.parse(_hourlyRateController.text),
        'halfDayRate': double.parse(_halfDayRateController.text),
        'fullDayRate': double.parse(_fullDayRateController.text),
        'weekendRate': double.parse(_weekendRateController.text),
        'pricePeriod': _selectedPricePeriod,
        'options': options,
        'country': _selectedCountry,
        'countryName': countryName,
        'region': _selectedRegion,
        'regionName': regionName,
        'cityCode': _selectedCity,
        'cityName': cityName,
      };

      if (widget.residence != null) {
        context.read<ResidenceBloc>().add(
          UpdateResidence(widget.residence!.id, data),
        );

        if (kIsWeb) {
          if (_webImages.isNotEmpty) {
            // Upload images after updating residence
            context.read<ResidenceBloc>().add(
              UploadResidenceImages(widget.residence!.id, _webImages),
            );
          }
        } else {
          if (_selectedImages.isNotEmpty) {
            // Upload images after updating residence
            context.read<ResidenceBloc>().add(
              UploadResidenceImages(widget.residence!.id, _selectedImages),
            );
          }
        }
      } else {
        if (kIsWeb) {
          context.read<ResidenceBloc>().add(
            CreateResidence(data, _webImages),
          );
        } else {
          context.read<ResidenceBloc>().add(
            CreateResidence(data, _selectedImages),
          );
        }
      }
    }
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
              errorMessage = 'Vous devez être connecté pour effectuer cette action.';
              action = TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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
                value: _selectedCategory,
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
                      final types = _residenceCategories[value]!['types'] as List<ResidenceType>;
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
                value: _selectedType,
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                    : null,
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                value: _selectedPricePeriod,
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
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
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
                            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                            : null,
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        validator: (value) {
                          if (_selectedPricePeriod == 'hour' && (value == null || value.isEmpty)) {
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
                            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                            : null,
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        validator: (value) {
                          if (_selectedPricePeriod == 'day' && (value == null || value.isEmpty)) {
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
                            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                            : null,
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        validator: (value) {
                          if (_selectedPricePeriod == 'day' && (value == null || value.isEmpty)) {
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
                            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                            : null,
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        validator: (value) {
                          if (_selectedPricePeriod == 'week' && (value == null || value.isEmpty)) {
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
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
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
                            Icon(Icons.pool, size: 20, color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Piscine'),
                          ],
                        ),
                        value: _hasPool,
                        onChanged: (value) => setState(() => _hasPool = value),
                      ),
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.check_circle, size: 20, color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text('Disponible'),
                          ],
                        ),
                        value: _isAvailable,
                        onChanged: (value) => setState(() => _isAvailable = value),
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
                value: _selectedRegion,
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
                value: _selectedCity,
                decoration: InputDecoration(
                  labelText: 'Commune / Quartier',
                  prefixIcon: Icon(Icons.apartment),
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
              
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Adresse exacte',
                  hintText: 'ex: 123 Rue des Fleurs, Résidence Le Palmier',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'L\'adresse exacte est requise';
                  }
                  return null;
                },
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
    if ([
      'hotel_passage', 
      'motel', 
      'chambres_passage'
    ].contains(type)) {
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
    setState(() {
      _selectedPricePeriod = _getExpectedPricePeriodForType(_selectedType);
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
        
      case 'appartement_meuble':
      case 'appartement_vide':
      case 'villa_meublee':
      case 'villa_vide':
      case 'chambre_colocation':
      case 'residence_universitaire':
      case 'coliving':
      case 'immeuble':
      case 'cour_commune':
        return 'Les locations longue durée sont généralement facturées au mois';
        
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
        options.add(
          SwitchListTile(
            title: Row(
              children: [
                Icon(Icons.ac_unit, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Climatisation'),
              ],
            ),
            value: _hasAirConditioning,
            onChanged: (value) => setState(() => _hasAirConditioning = value),
          )
        );
        options.add(
          SwitchListTile(
            title: Row(
              children: [
                Icon(Icons.wifi, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Wi-Fi gratuit'),
              ],
            ),
            value: _hasWifi,
            onChanged: (value) => setState(() => _hasWifi = value),
          )
        );
        options.add(
          SwitchListTile(
            title: Row(
              children: [
                Icon(Icons.local_parking, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Parking'),
              ],
            ),
            value: _hasParking,
            onChanged: (value) => setState(() => _hasParking = value),
          )
        );
        options.add(
          SwitchListTile(
            title: Row(
              children: [
                Icon(Icons.kitchen, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Cuisine équipée'),
              ],
            ),
            value: _hasKitchen,
            onChanged: (value) => setState(() => _hasKitchen = value),
          )
        );
        break;
        
      case 'hotel':
        options.add(
          SwitchListTile(
            title: Row(
              children: [
                Icon(Icons.room_service, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Service de chambre'),
              ],
            ),
            value: _hasRoomService,
            onChanged: (value) => setState(() => _hasRoomService = value),
          )
        );
        options.add(
          SwitchListTile(
            title: Row(
              children: [
                Icon(Icons.restaurant, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Restaurant'),
              ],
            ),
            value: _hasRestaurant,
            onChanged: (value) => setState(() => _hasRestaurant = value),
          )
        );
        options.add(
          SwitchListTile(
            title: Row(
              children: [
                Icon(Icons.local_bar, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Bar'),
              ],
            ),
            value: _hasBar,
            onChanged: (value) => setState(() => _hasBar = value),
          )
        );
        break;
        
      case 'hebergement_insolite':
        options.add(
          SwitchListTile(
            title: Row(
              children: [
                Icon(Icons.nature_people, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Vue sur la nature'),
              ],
            ),
            value: _hasGarden,
            onChanged: (value) => setState(() => _hasGarden = value),
          )
        );
        options.add(
          SwitchListTile(
            title: Row(
              children: [
                Icon(Icons.solar_power, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Énergie solaire'),
              ],
            ),
            value: _hasSolarEnergy,
            onChanged: (value) => setState(() => _hasSolarEnergy = value),
          )
        );
        break;
        
      case 'colocation':
        options.add(
          SwitchListTile(
            title: Row(
              children: [
                Icon(Icons.kitchen, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Cuisine partagée'),
              ],
            ),
            value: _hasSharedKitchen,
            onChanged: (value) => setState(() => _hasSharedKitchen = value),
          )
        );
        options.add(
          SwitchListTile(
            title: Row(
              children: [
                Icon(Icons.local_laundry_service, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Buanderie'),
              ],
            ),
            value: _hasLaundry,
            onChanged: (value) => setState(() => _hasLaundry = value),
          )
        );
        break;
        
      case 'residence_longue_duree':
        options.add(
          SwitchListTile(
            title: Row(
              children: [
                Icon(Icons.security, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Sécurité 24/7'),
              ],
            ),
            value: _hasSecurity,
            onChanged: (value) => setState(() => _hasSecurity = value),
          )
        );
        options.add(
          SwitchListTile(
            title: Row(
              children: [
                Icon(Icons.electrical_services, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Générateur de secours'),
              ],
            ),
            value: _hasGenerator,
            onChanged: (value) => setState(() => _hasGenerator = value),
          )
        );
        break;
        
      case 'hebergement_economique':
        options.add(
          SwitchListTile(
            title: Row(
              children: [
                Icon(Icons.clean_hands, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Service de ménage'),
              ],
            ),
            value: _hasCleaning,
            onChanged: (value) => setState(() => _hasCleaning = value),
          )
        );
        options.add(
          SwitchListTile(
            title: Row(
              children: [
                Icon(Icons.tv, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Télévision'),
              ],
            ),
            value: _hasTv,
            onChanged: (value) => setState(() => _hasTv = value),
          )
        );
        break;
    }
    
    // Si aucune option spécifique n'est définie pour cette catégorie
    if (options.isEmpty) {
      options.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Pas d\'options spécifiques pour cette catégorie',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        )
      );
    }
    
    return options;
  }
  
  // Méthode pour obtenir les options spécifiques au type
  List<Widget> _getTypeSpecificOptions() {
    List<Widget> options = [];
    
    switch (_selectedType) {
      case 'hotel_luxe':
        options.add(
          SwitchListTile(
            title: Row(
              children: [
                Icon(Icons.spa, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Spa / Bien-être'),
              ],
            ),
            value: _hasSpa,
            onChanged: (value) => setState(() => _hasSpa = value),
          )
        );
        options.add(
          SwitchListTile(
            title: Row(
              children: [
                Icon(Icons.fitness_center, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Salle de sport'),
              ],
            ),
            value: _hasGym,
            onChanged: (value) => setState(() => _hasGym = value),
          )
        );
        break;
        
      case 'boutique_hotel':
        options.add(
          SwitchListTile(
            title: Row(
              children: [
                Icon(Icons.meeting_room, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Salle de réunion'),
              ],
            ),
            value: _hasMeetingRoom,
            onChanged: (value) => setState(() => _hasMeetingRoom = value),
          )
        );
        break;
        
      case 'villa_meublee':
      case 'villa_vide':
        options.add(
          SwitchListTile(
            title: Row(
              children: [
                Icon(Icons.deck, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Terrasse'),
              ],
            ),
            value: _hasTerrace,
            onChanged: (value) => setState(() => _hasTerrace = value),
          )
        );
        break;
        
      case 'appartement_meuble':
      case 'penthouse':
        options.add(
          SwitchListTile(
            title: Row(
              children: [
                Icon(Icons.balcony, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Balcon'),
              ],
            ),
            value: _hasBalcony,
            onChanged: (value) => setState(() => _hasBalcony = value),
          )
        );
        break;
        
      case 'residence_universitaire':
        options.add(
          SwitchListTile(
            title: Row(
              children: [
                Icon(Icons.info, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Résidence de vacances'),
              ],
            ),
            value: _isVacationResidence,
            onChanged: (value) => setState(() => _isVacationResidence = value),
          )
        );
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
}

class ResidenceType {
  final String value;
  final String label;

  ResidenceType(this.value, this.label);
}

class LocationItem {
  final String code;
  final String name;

  LocationItem(this.code, this.name);
}
