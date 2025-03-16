import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/blocs/residence/residence_state.dart';
import '../../core/blocs/residence/residence_event.dart';
import '../../core/models/residence_model.dart';
import 'residence_card_alias.dart';
import 'shimmer_residence_card.dart';
import '../../core/theme/app_theme.dart';

class NewListingsWidget extends StatefulWidget {
  const NewListingsWidget({super.key});

  @override
  State<NewListingsWidget> createState() => _NewListingsWidgetState();
}

class _NewListingsWidgetState extends State<NewListingsWidget> {
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
          return _buildShimmerLoading();
        } else if (state is ResidencesLoaded) {
          // Filtrer pour obtenir les nouvelles résidences
          final newResidences = state.residences.where((residence) => residence.isNewListing).take(5).toList();
          
          if (newResidences.isEmpty) {
            return _buildMockNewResidences(context);
          }
          
          return _buildResidencesList(context, newResidences);
        } else if (state is ResidenceError) {
          return SizedBox(
            height: 300,
            child: Center(
              child: Text(
                'Erreur: ${state.message}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        } else {
          return _buildMockNewResidences(context);
        }
      },
    );
  }

  Widget _buildShimmerLoading() {
    return SizedBox(
      height: 370,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.only(right: 16),
            child: ShimmerResidenceCard(),
          );
        },
      ),
    );
  }

  Widget _buildResidencesList(BuildContext context, List<Residence> residences) {
    return Stack(
      children: [
        SizedBox(
          height: 370,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: residences.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final residence = residences[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
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

  Widget _buildMockNewResidences(BuildContext context) {
    // Utiliser des résidences de test
    final mockResidences = List.generate(
      4,
      (index) => Residence(
        id: 'mock_new_$index',
        name: 'Nouvelle Résidence ${index + 1}',
        description: 'Une nouvelle résidence disponible à la location',
        price: 15000 + (index * 5000),
        address: 'Adresse de test ${index + 1}',
        city: 'Abidjan',
        country: 'Côte d\'Ivoire',
        images: ['assets/images/residences/apartments/seen-hotel-abidjan-plateau.jpg'],
        bedrooms: index == 0 ? 0 : 1,  // Studio ou 1 chambre
        bathrooms: 1,
        surface: 25 + (index * 10),
        isAvailable: true,
        createdAt: DateTime.now().subtract(Duration(days: index + 1)),  // Résidence créée récemment
        location: {
          'displayAddress': 'Cocody, Abidjan',
          'city': 'Abidjan',
          'coordinates': [5.359952, -4.008256],
        },
        amenities: ['wifi', 'parking'],
        type: ResidenceType.studio,
        rating: 0.0,  // Pas encore de notation
      ),
    );

    return _buildResidencesList(context, mockResidences);
  }
}
