import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/blocs/favorite/favorite_bloc.dart';
import '../../core/blocs/favorite/favorite_event.dart';
import '../../core/blocs/favorite/favorite_state.dart';
import '../../core/models/residence_model.dart';
import '../../core/theme/app_theme.dart';
import 'residence_details_screen.dart';

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
              return const Center(child: CircularProgressIndicator());
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
                    const SizedBox(height: 16),
                    Text(
                      'Erreur',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                    const SizedBox(height: 16),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty_favorites.png',
            height: 150,
            width: 150,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.favorite_border,
                size: 150,
                color: Colors.grey[300],
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun favori',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vous n\'avez pas encore ajouté de résidences à vos favoris',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.search),
            label: const Text('Découvrir des résidences'),
            style: ElevatedButton.styleFrom(
              backgroundColor: goldColor,
              foregroundColor: blackColor,
            ),
            onPressed: () {
              // Naviguer vers l'écran de recherche ou d'accueil
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(BuildContext context, List<Residence> favorites) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<FavoriteBloc>().add(const LoadFavorites());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
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
        padding: const EdgeInsets.only(right: 20),
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
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
          borderRadius: BorderRadius.circular(12),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            residence.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: residence.status == 'available' ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            residence.status == 'available' ? 'Disponible' : 'Indisponible',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (residence.location != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              residence.location!.displayAddress,
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '${residence.pricePerNight} FCFA / nuit',
                      style: TextStyle(
                        fontSize: 16,
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