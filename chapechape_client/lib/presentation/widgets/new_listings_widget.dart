import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/models/residence_model.dart';
import '../../core/utils/residence_adapters.dart';
import 'residence_card_alias.dart';
import 'shimmer_residence_card.dart';

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
          // Filtrer pour obtenir les nouvelles résidences (moins de 15 jours)
          final now = DateTime.now();
          final newResidences = state.residences.where((residence) {
            // Vérifier si la résidence a été créée il y a moins de 15 jours
            if (residence.createdAt != null) {
              return now.difference(residence.createdAt!).inDays <= 15;
            }
            return false;
          }).take(5).toList();
          
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
                    final isFav = residence.priceDetails != null && 
                              residence.priceDetails!.containsKey('isFavorite') ? 
                              residence.priceDetails!['isFavorite'] == true : false;
                    context.read<ResidenceBloc>().add(
                      !isFav
                        ? AddToFavorites(residenceId: residence.id)
                        : RemoveFromFavorites(residenceId: residence.id),
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
    // Utiliser des résidences de test avec ResidenceAdapters
    final mockResidences = List.generate(
      4,
      (index) => ResidenceAdapters.createResidence(
        id: 'mock_new_$index',
        title: 'Nouvelle Résidence ${index + 1}',
        price: 15000 + (index * 5000),
        imageUrl: 'assets/images/residences/apartments/seen-hotel-abidjan-plateau.jpg',
        address: 'Adresse de test ${index + 1}',
        city: 'Abidjan',
        country: 'Côte d\'Ivoire',
        bedrooms: index == 0 ? 0 : 1,  // Studio ou 1 chambre
        bathrooms: 1,
        squareMeters: (25 + (index * 10)).toDouble(),
        hasPool: false,
        hasWifi: true,
        isAvailable: true,
        type: 'studio',
        rating: 0.0,  // Pas encore de notation
        reviewCount: 0,
        isVacationResidence: false,
        isSpecialResidence: false,
        isFeatured: false,
        isPopular: index < 2,
        isNew: true,  // Marquer comme nouvelle résidence
      ),
    );

    return _buildResidencesList(context, mockResidences);
  }
}
