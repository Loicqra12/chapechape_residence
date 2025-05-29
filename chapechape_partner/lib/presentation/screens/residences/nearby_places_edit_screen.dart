import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/residence/nearby_place.dart';
import '../../../core/services/api/residence_service.dart';
import '../../widgets/common/buttons/primary_button.dart';
import '../../widgets/common/inputs/text_input.dart';

class NearbyPlacesEditScreen extends StatefulWidget {
  final String residenceId;
  final List<NearbyPlace> initialPlaces;

  const NearbyPlacesEditScreen({
    Key? key,
    required this.residenceId,
    required this.initialPlaces,
  }) : super(key: key);

  @override
  _NearbyPlacesEditScreenState createState() => _NearbyPlacesEditScreenState();
}

class _NearbyPlacesEditScreenState extends State<NearbyPlacesEditScreen> {
  late List<NearbyPlace> _places;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Copier la liste initiale pour pouvoir la modifier
    _places = List.from(widget.initialPlaces);
  }

  void _addNewPlace() {
    setState(() {
      _places.add(NearbyPlace(
        name: '',
        type: 'other',
        distance: 0,
        description: '',
      ));
      _hasChanges = true;
    });
  }

  void _removePlace(int index) {
    setState(() {
      _places.removeAt(index);
      _hasChanges = true;
    });
  }

  void _updatePlace(int index, NearbyPlace updatedPlace) {
    setState(() {
      _places[index] = updatedPlace;
      _hasChanges = true;
    });
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final residenceService = Provider.of<ResidenceService>(context, listen: false);
      final success = await residenceService.updateNearbyPlaces(
        residenceId: widget.residenceId,
        places: _places,
      );

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Points d\'intérêt mis à jour avec succès')),
        );
        Navigator.pop(context, _places);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la mise à jour des points d\'intérêt')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier les points d\'intérêt'),
        actions: [
          TextButton(
            onPressed: _hasChanges ? _saveChanges : null,
            child: Text(
              'Enregistrer',
              style: TextStyle(
                color: _hasChanges 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Points d\'intérêt à proximité',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ajoutez des lieux à proximité de votre résidence pour aider les visiteurs à mieux comprendre l\'emplacement.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ..._buildPlacesList(),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    onPressed: _addNewPlace,
                    text: 'Ajouter un lieu',
                    icon: Icons.add,
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildPlacesList() {
    return _places.asMap().entries.map((entry) {
      final index = entry.key;
      final place = entry.value;
      
      return _buildPlaceCard(index, place);
    }).toList();
  }

  Widget _buildPlaceCard(int index, NearbyPlace place) {
    final nameController = TextEditingController(text: place.name);
    final distanceController = TextEditingController(text: place.distance.toString());
    final descriptionController = TextEditingController(text: place.description);

    // Liste des types de lieux d'intérêt
    final placeTypes = [
      {'value': 'restaurant', 'label': 'Restaurant'},
      {'value': 'shop', 'label': 'Commerce'},
      {'value': 'hospital', 'label': 'Hôpital'},
      {'value': 'school', 'label': 'École'},
      {'value': 'park', 'label': 'Parc'},
      {'value': 'transport', 'label': 'Transport'},
      {'value': 'beach', 'label': 'Plage'},
      {'value': 'other', 'label': 'Autre'},
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Point d\'intérêt ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removePlace(index),
                  tooltip: 'Supprimer ce lieu',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextInput(
              controller: nameController,
              label: 'Nom du lieu',
              onChanged: (value) {
                _updatePlace(
                  index,
                  place.copyWith(name: value),
                );
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: place.type,
              decoration: const InputDecoration(
                labelText: 'Type de lieu',
                border: OutlineInputBorder(),
              ),
              items: placeTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type['value'],
                  child: Text(type['label']!),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _updatePlace(
                    index,
                    place.copyWith(type: value),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            TextInput(
              controller: distanceController,
              label: 'Distance (en mètres)',
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final distance = int.tryParse(value) ?? 0;
                _updatePlace(
                  index,
                  place.copyWith(distance: distance),
                );
              },
            ),
            const SizedBox(height: 12),
            TextInput(
              controller: descriptionController,
              label: 'Description',
              maxLines: 3,
              onChanged: (value) {
                _updatePlace(
                  index,
                  place.copyWith(description: value),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
