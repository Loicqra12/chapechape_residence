import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../widgets/loading_overlay.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/blocs/residence/residence_state.dart';
import '../../core/models/residence_model.dart';
import '../../config/theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche de résidences'),
        elevation: 0,
      ),
      body: BlocConsumer<ResidenceBloc, ResidenceState>(
        listener: (context, state) {
          setState(() {
            _isLoading = state is ResidenceLoading;
          });
        },
        builder: (context, state) {
          if (state is ResidenceLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is ResidencesLoaded) {
            final residences = state.residences;
            
            if (residences.isEmpty) {
              return _buildEmptyState();
            }

            return LoadingOverlay(
              isLoading: _isLoading,
              child: _buildResidencesList(residences),
            );
          }

          return const Center(
            child: Text('Utilisez les filtres pour rechercher une résidence'),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 72,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune résidence trouvée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Essayez avec d\'autres critères de recherche',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.go('/home');
            },
            icon: const Icon(Icons.home),
            label: const Text('Retour à l\'accueil'),
          ),
        ],
      ),
    );
  }

  Widget _buildResidencesList(List<Residence> residences) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: residences.length,
      itemBuilder: (context, index) {
        final residence = residences[index];
        return _buildResidenceCard(residence);
      },
    );
  }

  Widget _buildResidenceCard(Residence residence) {
    final imageUrl = residence.imageUrl ?? 'assets/images/placeholder.jpg';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          context.go('/residence/${residence.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/placeholder.jpg',
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            
            // Contenu
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type & Prix
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getCategoryIcon(residence.type.toString()),
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatResidenceType(residence.type.toString()),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${residence.price.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Titre
                  Text(
                    residence.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Localisation
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          residence.address,
                          style: const TextStyle(color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Détails (chambres, salles de bain, surface)
                  Row(
                    children: [
                      _buildFeatureChip(Icons.king_bed, '${residence.bedrooms} Ch'),
                      const SizedBox(width: 8),
                      _buildFeatureChip(Icons.bathtub, '${residence.bathrooms} SdB'),
                      const SizedBox(width: 8),
                      _buildFeatureChip(Icons.square_foot, '${residence.surface.toInt()} m²'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String type) {
    // Convertir la chaîne en minuscules pour comparer plus facilement
    final typeLower = type.toLowerCase();
    
    if (typeLower.contains('apartment')) return Icons.apartment;
    if (typeLower.contains('studio')) return Icons.single_bed;
    if (typeLower.contains('villa')) return Icons.house;
    if (typeLower.contains('penthouse')) return Icons.location_city;
    if (typeLower.contains('bungalow')) return Icons.holiday_village;
    if (typeLower.contains('hotel')) return Icons.hotel;
    if (typeLower.contains('room')) return Icons.bedroom_child;
    if (typeLower.contains('luxury')) return Icons.star;
    
    // Par défaut
    return Icons.home;
  }

  String _formatResidenceType(String type) {
    // Nettoyer le type (qui pourrait être au format 'ResidenceType.apartment')
    final cleanType = type.contains('.') ? type.split('.').last : type;
    
    // Mettre en majuscule la première lettre
    if (cleanType.isEmpty) return 'Résidence';
    return cleanType.substring(0, 1).toUpperCase() + cleanType.substring(1);
  }
}