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
  String _selectedType = 'studio_meuble';
  String _selectedCategory = 'residence_meublee';
  bool _hasPool = false;
  bool _isVacationResidence = false;
  bool _isSpecialResidence = false;
  bool _isAvailable = true;
  bool _isLoading = false;

  final Map<String, Map<String, dynamic>> _residenceCategories = {
    'residence_meublee': {
      'label': 'Résidences meublées',
      'types': [
        ResidenceType('studio_meuble', 'Studio meublé'),
        ResidenceType('appartement_meuble', 'Appartement meublé'),
        ResidenceType('villa_meublee', 'Villa meublée'),
        ResidenceType('penthouse', 'Penthouse'),
        ResidenceType('loft', 'Loft'),
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
      ],
    },
    'hebergement_insolite': {
      'label': 'Hébergements insolites & nature',
      'types': [
        ResidenceType('bungalow', 'Bungalow'),
        ResidenceType('lodge', 'Lodge & écolodge'),
        ResidenceType('case_traditionnelle', 'Case traditionnelle'),
        ResidenceType('maison_flottante', 'Maison flottante'),
      ],
    },
    'colocation': {
      'label': 'Colocation & résidences partagées',
      'types': [
        ResidenceType('chambre_colocation', 'Chambre en colocation'),
        ResidenceType('coliving', 'Coliving'),
        ResidenceType('maison_hotes', 'Maison d\'hôtes'),
      ],
    },
    'residence_longue_duree': {
      'label': 'Résidences longue durée',
      'types': [
        ResidenceType('appartement_vide', 'Appartement non meublé'),
        ResidenceType('villa_vide', 'Villa non meublée'),
        ResidenceType('immeuble', 'Immeuble'),
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.residence?.name);
    _descriptionController = TextEditingController(text: widget.residence?.description);
    _addressController = TextEditingController(text: widget.residence?.address);
    _cityController = TextEditingController(text: widget.residence?.city);
    _priceController = TextEditingController(
      text: widget.residence?.price.toString(),
    );
    _bedroomsController = TextEditingController(
      text: widget.residence?.bedrooms.toString(),
    );
    _bathroomsController = TextEditingController(
      text: widget.residence?.bathrooms.toString(),
    );
    _surfaceController = TextEditingController(
      text: widget.residence?.surface.toString(),
    );
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
      final data = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'address': _addressController.text,
        'city': _cityController.text,
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
      ),
      body: BlocListener<ResidenceBloc, ResidenceState>(
        listener: (context, state) {
          if (state is ResidenceSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.pop(context);
          }

          if (state is ResidenceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
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

              // Localisation
              Text(
                'Localisation',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  hintText: 'ex: 123 Rue des Fleurs',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'L\'adresse est requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Ville',
                  hintText: 'ex: Abidjan',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La ville est requise';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

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
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type d\'hébergement',
                ),
                items: (_residenceCategories[_selectedCategory]!['types'] as List<ResidenceType>)
                    .map((type) => DropdownMenuItem<String>(
                          value: type.value,
                          child: Text(type.label),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le type est requis';
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
                decoration: const InputDecoration(
                  labelText: 'Prix (FCFA)',
                  hintText: 'ex: 500000',
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

              const SizedBox(height: 24),

              // Options
              Text(
                'Options',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Piscine'),
                value: _hasPool,
                onChanged: (value) => setState(() => _hasPool = value),
              ),
              SwitchListTile(
                title: const Text('Résidence de vacances'),
                value: _isVacationResidence,
                onChanged: (value) => setState(() => _isVacationResidence = value),
              ),
              SwitchListTile(
                title: const Text('Résidence spéciale'),
                value: _isSpecialResidence,
                onChanged: (value) => setState(() => _isSpecialResidence = value),
              ),
              SwitchListTile(
                title: const Text('Disponible'),
                value: _isAvailable,
                onChanged: (value) => setState(() => _isAvailable = value),
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
}

class ResidenceType {
  final String value;
  final String label;

  ResidenceType(this.value, this.label);
}
