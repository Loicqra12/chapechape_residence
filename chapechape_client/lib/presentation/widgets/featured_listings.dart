import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/blocs/residence/residence_state.dart';
import '../../core/blocs/residence/residence_event.dart';
import '../../core/models/residence_model.dart' as model;
import '../../core/constants/app_assets.dart' as assets;
import 'residence_card_alias.dart';
import 'shimmer_residence_card.dart';

class FeaturedListings extends StatefulWidget {
  const FeaturedListings({Key? key}) : super(key: key);

  @override
  State<FeaturedListings> createState() => _FeaturedListingsState();
}

class _FeaturedListingsState extends State<FeaturedListings> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollLeft() {
    if (_scrollController.hasClients) {
      final double currentPosition = _scrollController.offset;
      final double newPosition = currentPosition - 300;
      _scrollController.animateTo(
        newPosition < 0 ? 0 : newPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollRight() {
    if (_scrollController.hasClients) {
      final double currentPosition = _scrollController.offset;
      final double maxPosition = _scrollController.position.maxScrollExtent;
      final double newPosition = currentPosition + 300;
      _scrollController.animateTo(
        newPosition > maxPosition ? maxPosition : newPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResidenceBloc, ResidenceState>(
      builder: (context, state) {
        if (state is ResidenceLoading) {
          return _buildLoadingState();
        }

        if (state is ResidencesLoaded) {
          // Sélectionner les résidences recommandées (par exemple, celles avec les meilleures notes)
          final featuredResidences = state.residences
              .where((r) => r.rating != null && r.rating! >= 4.0) // Résidences bien notées
              .take(5)
              .toList();

          // Si aucune résidence bien notée, prendre les 5 premières
          if (featuredResidences.isEmpty && state.residences.isNotEmpty) {
            featuredResidences.addAll(state.residences.take(5));
          }

          // Si toujours vide, utiliser des données de test
          if (featuredResidences.isEmpty) {
            return _buildMockResidences(context);
          }

          return _buildResidencesList(context, featuredResidences);
        }

        if (state is ResidenceError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Impossible de charger les résidences',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    context.read<ResidenceBloc>().add(const LoadResidences());
                  },
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        return _buildMockResidences(context);
      },
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 370,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemExtent: 280, // Largeur fixe pour chaque élément
        itemBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: ShimmerResidenceCard(),
          );
        },
      ),
    );
  }

  Widget _buildResidencesList(BuildContext context, List<model.Residence> residences) {
    return Stack(
      children: [
        SizedBox(
          height: 370,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            itemCount: residences.length,
            itemBuilder: (context, index) {
              final residence = residences[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: ResidenceCard(
                  residence: residence,
                  onTap: () => context.go('/residence/${residence.id}'),
                  onFavoritePressed: () {
                    context.read<ResidenceBloc>().add(
                      ToggleFavorite(
                        residenceId: residence.id,
                        isFavorite: !residence.isFavorite,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        // Bouton Précédent
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Center(
            child: InkWell(
              onTap: _scrollLeft,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios, size: 24),
              ),
            ),
          ),
        ),
        
        // Bouton Suivant
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: Center(
            child: InkWell(
              onTap: _scrollRight,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_forward_ios, size: 24),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMockResidences(BuildContext context) {
    // Créer des résidences de test pour démonstration
    final mockResidences = List.generate(
      5,
      (index) => model.Residence(
        id: 'mock_$index',
        name: 'Résidence Test ${index + 1}',
        description: 'Description de test pour la résidence ${index + 1}',
        price: 250000 + (index * 50000),
        address: 'Adresse de test ${index + 1}',
        city: 'Abidjan',
        country: 'Côte d\'Ivoire',
        // Utiliser des URLs d'images plus susceptibles de fonctionner
        images: index % 2 == 0 
            ? ['assets/images/placeholders/residence_placeholder.jpg'] 
            : ['assets/images/placeholders/apartment_placeholder.jpg'],
        bedrooms: 2 + (index % 3),
        bathrooms: 1 + (index % 2),
        surface: 80 + (index * 10),
        isAvailable: true,
        location: {
          'displayAddress': 'Cocody, Abidjan',
          'city': 'Abidjan',
          'coordinates': [5.359952, -4.008256],
        },
        amenities: ['wifi', 'parking', if (index % 2 == 0) 'pool'],
        rules: [],
        isFavorite: false,
        type: _convertToModelType(index % 2 == 0 ? assets.ResidenceType.apartment : assets.ResidenceType.villa),
        pricePeriod: 'month',
        hourlyRate: 5000,
        halfDayRate: 15000,
        fullDayRate: 25000,
        weekendRate: 35000,
        rating: 4.0 + (index * 0.2),
        reviewCount: 10 + index,
      ),
    );

    return _buildResidencesList(context, mockResidences);
  }

  // Méthode de conversion des types
  model.ResidenceType _convertToModelType(assets.ResidenceType type) {
    switch (type) {
      case assets.ResidenceType.apartment:
        return model.ResidenceType.apartment;
      case assets.ResidenceType.villa:
        return model.ResidenceType.villa;
      case assets.ResidenceType.studio:
        return model.ResidenceType.studio;
      case assets.ResidenceType.luxury:
        return model.ResidenceType.luxury;
      case assets.ResidenceType.bungalow:
        return model.ResidenceType.bungalow;
      case assets.ResidenceType.hotel:
        return model.ResidenceType.hotel;
      case assets.ResidenceType.room:
        return model.ResidenceType.house;
      case assets.ResidenceType.penthouse:
      case assets.ResidenceType.coworking:
      case assets.ResidenceType.student:
      default:
        return model.ResidenceType.other;
    }
  }
}
