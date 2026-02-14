import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/location_filter_widget.dart';
import '../widgets/skeletons/search_result_skeleton.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/models/residence_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/text_styles.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:chapechape_client/presentation/widgets/common/empty_state_widget.dart';

class SearchScreen extends StatefulWidget {
  final String? category;
  final String? types;
  
  const SearchScreen({
    super.key,
    this.category,
    this.types,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _filters = {};
  bool _showAdvancedFilters = false;

  @override
  void initState() {
    super.initState();
    
    // Vérifier si nous avons des paramètres de recherche depuis les arguments du widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.types != null && widget.types!.isNotEmpty) {
        // Extraire la liste des types
        final typesList = widget.types!.split(',');
        final category = widget.category ?? 'Résultats';
        
        print('🔍 Recherche par catégorie: $category, types: $typesList');
        
        // Mettre à jour le titre de l'app bar et les filtres
        setState(() {
          _filters = {
            'typesList': typesList,
            'category': category,
          };
        });
        
        // Lancer la recherche avec ces types
        context.read<ResidenceBloc>().add(SearchResidencesEvent(filters: _filters));
      } else {
        // Recherche standard sans filtre
        context.read<ResidenceBloc>().add(const SearchResidencesEvent(filters: {}));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche de résidences'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('🔄 Rafraîchissement des résidences demandé...');
              // Débogage: forcer le rafraîchissement et afficher les données
              context.read<ResidenceBloc>().add(const RefreshResidencesEvent());
              
              // Afficher des informations de débogage après un délai
              Future.delayed(const Duration(seconds: 3), () {
                final state = context.read<ResidenceBloc>().state;
                if (state is ResidencesLoaded) {
                  print('✅ ResidencesLoaded: ${state.residences.length} résidences chargées');
                  for (var residence in state.residences) {
                    print('   - ${residence.id}: ${residence.title} (${residence.pricePeriod})');
                  }
                } else {
                  print('❌ État actuel: ${state.runtimeType}');
                }
              });
            },
          ),
          IconButton(
            icon: Icon(_showAdvancedFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showAdvancedFilters = !_showAdvancedFilters;
              });
            },
            tooltip: _showAdvancedFilters ? 'Masquer les filtres' : 'Afficher les filtres',
          ),
        ],
      ),
      body: Column(
        children: [
          // Zone de filtres avancés
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showAdvancedFilters ? null : 0,
            child: _showAdvancedFilters
                ? Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    child: LocationFilterWidget(
                      onApplyFilters: _applyLocationFilters,
                      currentFilters: _filters,
                    ),
                  ).animate().fadeIn(duration: 300.ms)
                : const SizedBox.shrink(),
          ),
          
          // Liste des résidences
          Expanded(
            child: BlocConsumer<ResidenceBloc, ResidenceState>(
              listener: (context, state) {
                setState(() {
                  _isLoading = state is ResidenceLoading;
                });
              },
              builder: (context, state) {
                if (state is ResidenceLoading && _filters.isEmpty) {
                  return const SearchResultSkeleton(itemCount: 5);
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

                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Utilisez les filtres pour rechercher une résidence',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      AppSpacing.verticalMd,
                      if (!_showAdvancedFilters)
                        ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _showAdvancedFilters = true;
                            });
                          },
                          icon: const Icon(Icons.filter_list),
                          label: const Text('Afficher les filtres'),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      imagePath: 'assets/images/empty_states/empty_search_illustration.png',
      title: 'Aucune résidence trouvée',
      subtitle: 'Essayez avec d\'autres critères de recherche pour trouver votre bonheur',
      fallbackIcon: Icons.search_off,
      action: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.mediumImpact();
          // Réinitialiser filtres ou aller à l'accueil
          context.go('/home');
        },
        icon: const Icon(Icons.home),
        label: const Text('Retour à l\'accueil'),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.smd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }

  Widget _buildResidencesList(List<Residence> residences) {
    return ListView.builder(
      padding: AppSpacing.cardPadding,
      itemCount: residences.length,
      itemBuilder: (context, index) {
        final residence = residences[index];
        return _buildResidenceCard(residence);
      },
    );
  }

  Widget _buildResidenceCard(Residence residence) {
    final imageUrl = residence.imageUrl ?? 'assets/images/placeholders/residence_standard.jpg';
    
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
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
                  return Image.network(
                    'assets/images/placeholders/residence_standard.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey[600]),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            
            // Contenu
            Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type & Prix
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getCategoryIcon(residence.type.toString()),
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                            SizedBox(width: AppSpacing.xs),
                            Text(
                              _formatResidenceType(residence.type.toString()),
                              style: AppTextStyles.tag.copyWith(
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${residence.price.toStringAsFixed(0)} FCFA',
                        style: AppTextStyles.price,
                      ),
                    ],
                  ),
                  
                  AppSpacing.verticalSm,
                  
                  // Titre
                  Text(
                    residence.title,
                    style: AppTextStyles.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  AppSpacing.verticalXs,
                  
                  // Localisation
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          residence.address,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  AppSpacing.verticalSm,
                  
                  // Détails (chambres, salles de bain, surface)
                  Row(
                    children: [
                      _buildFeatureChip(Icons.king_bed, '${residence.bedrooms} Ch'),
                      SizedBox(width: AppSpacing.sm),
                      _buildFeatureChip(Icons.bathtub, '${residence.bathrooms} SdB'),
                      SizedBox(width: AppSpacing.sm),
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
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          SizedBox(width: AppSpacing.xs),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
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

  // Appliquer les filtres de localisation
  void _applyLocationFilters(Map<String, dynamic> locationFilters) {
    setState(() {
      _filters = {..._filters, ...locationFilters};
    });
    
    // Construire des filtres API-compatibles et lancer la recherche
    final apiFilters = context
        .read<ResidenceBloc>()
        .buildLocationFilter(
          countryCode: locationFilters['countryCode'],
          regionId: locationFilters['regionId'],
          cityId: locationFilters['cityId'],
          neighborhoodId: locationFilters['neighborhoodId'],
        );
    
    // Lancer la recherche avec les filtres combinés
    context.read<ResidenceBloc>().add(SearchResidencesEvent(filters: apiFilters));
  }
}