import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/blocs/favorite/favorite_bloc.dart';
import '../../core/blocs/favorite/favorite_event.dart';
import '../../core/blocs/favorite/favorite_state.dart';
import '../../core/models/residence_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/text_styles.dart';
import '../widgets/skeletons/residence_card_skeleton.dart';
import 'residence_details_screen.dart';
import 'package:chapechape_client/presentation/widgets/common/empty_state_widget.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  static const Color goldColor = Color(0xFFFFD700);
  static const Color darkGold = Color(0xFFCCAC00);
  static const Color orangeColor = Color(0xFFFF8C00);
  static const Color blackColor = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final favoriteRepository = context.read<FavoriteBloc>().favoriteRepository;
    
    return BlocProvider(
      create: (context) => FavoriteBloc(
        favoriteRepository: favoriteRepository,
      )..add(const LoadFavorites()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Favoris'),
          backgroundColor: goldColor,
        ),
        body: BlocBuilder<FavoriteBloc, FavoriteState>(
          builder: (context, state) {
            if (state is FavoriteLoading) {
              return ListView.builder(
                padding: EdgeInsets.all(AppSpacing.sm),
                itemCount: 3,
                itemBuilder: (context, index) => const ResidenceCardSkeleton(),
              );
            } else if (state is FavoriteLoaded) {
              if (state.favorites.isEmpty) {
                return _buildEmptyFavorites(context);
              }
              return _buildFavoritesList(context, state.favorites);
            } else if (state is FavoriteError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[400],
                    ),
                    AppSpacing.verticalMd,
                    Text(
                      'Erreur',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[600],
                      ),
                    ),
                    AppSpacing.verticalSm,
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    AppSpacing.verticalMd,
                    ElevatedButton(
                      onPressed: () {
                        context.read<FavoriteBloc>().add(const LoadFavorites());
                      },
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyFavorites(BuildContext context) {
    return EmptyStateWidget(
      imagePath: 'assets/images/empty_states/empty_favorites_illustration.png',
      title: 'Aucun coup de cœur',
      subtitle: 'Explorez nos résidences et sauvegardez vos préférées pour les retrouver facilement',
      action: ElevatedButton.icon(
        icon: const Icon(Icons.explore),
        label: const Text('Découvrir les résidences'),
        style: ElevatedButton.styleFrom(
          backgroundColor: goldColor,
          foregroundColor: blackColor,
          padding: AppSpacing.buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        onPressed: () => context.go('/home'),
      ),
    );
  }

  Widget _buildFavoritesList(BuildContext context, List<Residence> favorites) {
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        context.read<FavoriteBloc>().add(const LoadFavorites());
      },
      child: ListView.builder(
        padding: AppSpacing.cardPadding,
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final residence = favorites[index];
          return _buildFavoriteItem(context, residence);
        },
      ),
    );
  }

  Widget _buildFavoriteItem(BuildContext context, Residence residence) {
    return Dismissible(
      key: Key(residence.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: AppSpacing.md + AppSpacing.xs),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Supprimer des favoris'),
              content: Text('Voulez-vous vraiment supprimer ${residence.name} de vos favoris?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Supprimer'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        context.read<FavoriteBloc>().add(RemoveFromFavorites(residence.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${residence.name} supprimé des favoris'),
            action: SnackBarAction(
              label: 'ANNULER',
              onPressed: () {
                context.read<FavoriteBloc>().add(AddToFavorites(residence.id));
              },
            ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.only(bottom: AppSpacing.md),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: InkWell(
          onTap: () {
            // Naviguer vers les détails de la résidence
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResidenceDetailsScreen(residenceId: residence.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  residence.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 50),
                    );
                  },
                ),
              ),
              Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            residence.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: residence.status == 'available' ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: Text(
                            residence.status == 'available' ? 'Disponible' : 'Indisponible',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.verticalSm,
                    if (residence.location != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              residence.location!.displayAddress,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    AppSpacing.verticalSm,
                    Text(
                      '${residence.pricePerNight} FCFA / nuit',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: goldColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}