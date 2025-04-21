import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/models/residence_model.dart';
import '../../core/utils/residence_adapters.dart';
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
              .where((r) => r.rating >= 4.0) // Résidences bien notées
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

  Widget _buildResidencesList(BuildContext context, List<Residence> residences) {
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

  Widget _buildMockResidences(BuildContext context) {
    // Créer des résidences de test pour démonstration en utilisant notre adaptateur
    final mockResidences = List.generate(
      5,
      (index) => ResidenceAdapters.createResidence(
        id: 'mock_$index',
        title: 'Résidence Test ${index + 1}',
        price: 250000 + (index * 50000),
        imageUrl: index % 2 == 0 
            ? 'assets/images/placeholders/residence_placeholder.jpg'
            : 'assets/images/placeholders/apartment_placeholder.jpg',
        address: 'Adresse de test ${index + 1}',
        city: 'Abidjan',
        country: 'Côte d\'Ivoire',
        bedrooms: 2 + (index % 3),
        bathrooms: 1 + (index % 2),
        squareMeters: 80 + (index * 10).toDouble(),
        hasPool: index % 2 == 0,
        hasWifi: true,
        isAvailable: true,
        type: index % 2 == 0 ? 'apartment' : 'villa',
        rating: 4.0 + (index * 0.2),
        reviewCount: 10 + index,
        isFavorite: false,
        isVacationResidence: index % 3 == 0,
        isSpecialResidence: index % 4 == 0,
        isFeatured: true,
        isPopular: index < 3,
      ),
    );

    return _buildResidencesList(context, mockResidences);
  }
}
