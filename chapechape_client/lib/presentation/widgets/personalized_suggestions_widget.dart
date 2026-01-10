import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/blocs/favorite/favorite_bloc.dart';
import '../../core/blocs/favorite/favorite_state.dart';
import 'residence_card.dart';

/// Widget de suggestions personnalisées basées sur:
/// 1. Les types de résidences similaires aux favoris
/// 2. Les résidences les mieux notées
/// 3. Les résidences avec promotions actives
class PersonalizedSuggestionsWidget extends StatelessWidget {
  const PersonalizedSuggestionsWidget({Key? key}) : super(key: key);

  /// Génère des suggestions personnalisées intelligentes
  List<Residence> _getPersonalizedSuggestions(
    List<Residence> allResidences,
    List<Residence> favorites,
  ) {
    if (allResidences.isEmpty) return [];

    // Étape 1: Identifier les types préférés basés sur les favoris
    final Set<ResidenceType> preferredTypes = {};
    final Set<String> favoriteIds = favorites.map((r) => r.id).toSet();
    
    for (final residence in favorites) {
      preferredTypes.add(residence.type);
    }

    // Étape 2: Calculer un score de pertinence pour chaque résidence
    final List<MapEntry<Residence, double>> scoredResidences = [];
    
    for (final residence in allResidences) {
      // Ne pas suggérer les résidences déjà en favoris
      if (favoriteIds.contains(residence.id)) continue;
      
      double score = 0;
      
      // Bonus si même type que les favoris (+3)
      if (preferredTypes.contains(residence.type)) {
        score += 3.0;
      }
      
      // Bonus pour les bien notées (+1 à +2)
      if (residence.rating >= 4.0) {
        score += residence.rating - 3.0;
      }
      
      // Bonus pour les promotions actives (+1.5)
      if (residence.hasDiscount) {
        score += 1.5;
      }
      
      // Bonus pour les nouvelles résidences (+1)
      if (residence.isNew) {
        score += 1.0;
      }
      
      // Bonus pour les résidences populaires (+0.5)
      if (residence.isPopular) {
        score += 0.5;
      }
      
      scoredResidences.add(MapEntry(residence, score));
    }

    // Étape 3: Trier par score décroissant et prendre les 5 meilleures
    scoredResidences.sort((a, b) => b.value.compareTo(a.value));
    
    return scoredResidences.take(5).map((e) => e.key).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResidenceBloc, ResidenceState>(
      builder: (context, state) {
        if (state is ResidenceLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Residence> allResidences = [];
        
        if (state is ResidencesLoaded) {
          allResidences = state.residences;
        } else if (state is ResidenceError && state.preservedResidences != null && state.preservedResidences!.isNotEmpty) {
          allResidences = state.preservedResidences!;
        }
        
        if (allResidences.isEmpty) {
          return const SizedBox.shrink();
        }

        // Récupérer les favoris pour la personnalisation
        return BlocBuilder<FavoriteBloc, FavoriteState>(
          builder: (context, favoriteState) {
            List<Residence> favorites = [];
            if (favoriteState is FavoriteLoaded) {
              favorites = favoriteState.favorites;
            }
            
            // Générer les suggestions personnalisées
            final suggestedResidences = _getPersonalizedSuggestions(
              allResidences,
              favorites,
            );
            
            // Si pas assez de données pour personnaliser, utiliser les mieux notées
            final displayResidences = suggestedResidences.isNotEmpty
                ? suggestedResidences
                : allResidences.take(5).toList();

            if (displayResidences.isEmpty) {
              return const SizedBox.shrink();
            }

            return _buildSuggestionsList(context, displayResidences);
          },
        );
      },
    );
  }

  Widget _buildSuggestionsList(BuildContext context, List<Residence> suggestedResidences) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Suggestions pour vous',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () {
                  // Naviguer vers la recherche
                  context.push('/search');
                },
                child: const Text('Voir tout'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 280,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            itemCount: suggestedResidences.length,
            itemBuilder: (context, index) {
              final residence = suggestedResidences[index];
              return SizedBox(
                width: 280,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: ResidenceCard(
                    residence: residence,
                    onTap: () {
                      context.read<ResidenceBloc>().add(
                            LoadResidenceDetails(residenceId: residence.id),
                          );
                      context.go('/residence-details/${residence.id}');
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


