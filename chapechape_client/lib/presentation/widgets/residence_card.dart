import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/residence_model_alias.dart';
import '../../core/models/residence_model.dart';
import '../../core/blocs/auth/auth_bloc.dart';
import '../../core/blocs/auth/auth_state.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/blocs/residence/residence_event.dart';

class ResidenceCard extends StatelessWidget {
  final ResidenceModel residence;
  final VoidCallback? onFavoritePressed;
  final VoidCallback? onTap;
  final bool showBeachBadge;
  final bool showMountainBadge;

  const ResidenceCard({
    super.key,
    required this.residence,
    this.onFavoritePressed,
    this.onTap,
    this.showBeachBadge = false,
    this.showMountainBadge = false,
  });

  static const Color goldColor = Color(0xFFFFD700);
  static const Color darkGold = Color(0xFFCCAC00);
  static const Color blackColor = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'FCFA',
      decimalDigits: 0,
      locale: 'fr_FR',
    );

    // Logique pour déterminer un nom de résidence approprié
    String displayName = residence.name.trim();
    if (displayName.isEmpty || displayName.length < 5) {
      displayName = "Résidence Premium ${residence.id.substring(0, 4)}";
    }

    // Logique pour l'adresse par défaut
    String displayAddress = "Adresse non disponible";
    if (residence.location.displayAddress.isNotEmpty && 
        residence.location.displayAddress != "Adresse non disponible") {
      displayAddress = residence.location.displayAddress;
    }

    return Container(
      width: 280,
      constraints: const BoxConstraints(
        minWidth: 280,
        maxWidth: 280,
        minHeight: 300,
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: InkWell(
          onTap: () {
            final authState = context.read<AuthBloc>().state;
            if (authState is Authenticated) {
              if (onTap != null) {
                onTap!();
              }
            } else {
              // Afficher une boîte de dialogue pour inciter à s'authentifier
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Authentification requise'),
                    content: const Text(
                      'Connectez-vous ou créez un compte pour voir les détails de cette résidence.',
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Annuler'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('Se connecter'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.go('/login');
                        },
                      ),
                    ],
                  );
                },
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 160,
                  maxHeight: 160,
                ),
                child: Stack(
                  children: [
                    // Image principale
                    Container(
                      height: 160,
                      width: double.infinity,
                      child: _buildResidenceImage(),
                    ),

                    // Badge de disponibilité
                    if (residence.status == 'available')
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Disponible',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    
                    // Badge de type (Vacances, Plage, Montagne)
                    if (residence.isVacationResidence || showBeachBadge || showMountainBadge)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: residence.isVacationResidence 
                                ? const Color(0xFF3F51B5) 
                                : showBeachBadge 
                                    ? const Color(0xFF00BCD4)
                                    : const Color(0xFF795548),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            residence.isVacationResidence 
                                ? 'Vacances'
                                : showBeachBadge 
                                    ? 'Plage'
                                    : 'Montagne',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    // Badge de favoris
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            residence.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: residence.isFavorite ? Colors.red : Colors.grey,
                            size: 20,
                          ),
                          onPressed: onFavoritePressed ?? () {},
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Informations de la résidence
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre de la résidence
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Adresse
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            displayAddress,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Caractéristiques (lits, salles de bain)
                    Row(
                      children: [
                        Icon(Icons.bed_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          residence.bedrooms > 0 
                              ? "${residence.bedrooms} chambre${residence.bedrooms > 1 ? 's' : ''}" 
                              : "Studio",
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.bathtub_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          residence.bathrooms > 0 
                              ? "${residence.bathrooms} SDB" 
                              : "1 SDB",
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Prix
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            currencyFormat.format(residence.price),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (residence.rating != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: goldColor,
                                size: 14,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                residence.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      ],
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

  Widget _buildResidenceImage() {
    // Vérifier si des images sont disponibles dans la liste
    if (residence.images.isEmpty) {
      return _buildPlaceholderImage();
    }

    // Prendre la première image de la liste
    final String imageUrl = residence.images.first;

    // Si l'URL est vide ou null, afficher l'image par défaut
    if (imageUrl.isEmpty) {
      return _buildPlaceholderImage();
    }

    // Si l'URL commence par 'assets/', c'est un asset local
    if (imageUrl.startsWith('assets/')) {
      try {
        return Image.asset(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint("Erreur de chargement d'asset: $error pour $imageUrl");
            return _buildPlaceholderImage();
          },
        );
      } catch (e) {
        debugPrint("Exception lors du chargement d'asset: $e");
        return _buildPlaceholderImage();
      }
    }
    
    // Si l'URL commence par 'http', c'est une image distante
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint("Erreur de chargement réseau: $error pour $imageUrl");
          return _buildPlaceholderImage();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
    }

    // Si l'URL n'est ni un asset ni une URL HTTP, afficher l'image par défaut
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.home,
          size: 60,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}
