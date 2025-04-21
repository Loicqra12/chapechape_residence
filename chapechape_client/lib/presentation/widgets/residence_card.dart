import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// Import des modèles
import '../../core/models/residence_model.dart';

// Import des blocs
import '../../core/blocs/auth/auth_bloc.dart';
import '../../core/blocs/auth/auth_state.dart';
import '../../core/blocs/residence/residence_bloc.dart'; // Contient déjà l'export de residence_event.dart

class ResidenceCard extends StatelessWidget {
  final Residence residence;
  final double? width;
  final bool showSpecialBadge;
  final VoidCallback? onTap;
  final VoidCallback? onFavoritePressed;
  final bool showBeachBadge;
  final bool showMountainBadge;

  const ResidenceCard({
    Key? key,
    required this.residence,
    this.width,
    this.showSpecialBadge = false,
    this.onTap,
    this.onFavoritePressed,
    this.showBeachBadge = false,
    this.showMountainBadge = false,
  }) : super(key: key);

  static const Color goldColor = Color(0xFFFFD700);
  static const Color darkGold = Color(0xFFCCAC00);
  static const Color blackColor = Color(0xFF1A1A1A);
  
  // Utilitaire de formatage de devise
  String _formatCurrency(double value) {
    return NumberFormat.currency(
      symbol: 'FCFA',
      decimalDigits: 0,
      locale: 'fr_FR',
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'FCFA',
      decimalDigits: 0,
      locale: 'fr_FR',
    );

    // Logique pour déterminer un nom de résidence approprié
    String displayName = residence.title.trim();
    if (displayName.isEmpty || displayName.length < 5) {
      displayName = "Résidence Premium ${residence.id.substring(0, 4)}";
    }

    // Logique pour l'adresse par défaut
    String displayAddress = "Adresse non disponible";
    if (residence.location.containsKey('address') && 
        residence.location['address'] != null &&
        residence.location['address'].toString().isNotEmpty) {
      displayAddress = residence.location['address'].toString();
    } else if (residence.location.containsKey('city') && 
               residence.location['city'] != null &&
               residence.location['city'].toString().isNotEmpty) {
      displayAddress = residence.location['city'].toString();
    } else if (residence.location.containsKey('formattedAddress')) {
      displayAddress = residence.location['formattedAddress'].toString();
    }

    return GestureDetector(
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
      child: Container(
        width: width,
        constraints: const BoxConstraints(
          minWidth: 280,
          maxWidth: 280,
          minHeight: 300,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // Image de la résidence
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  child: Image.network(
                    residence.images.isNotEmpty
                        ? residence.images.first
                        : 'https://via.placeholder.com/300x200/CCCCCC/808080?text=Pas+d%27image',
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/placeholders/no_image.jpg',
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
                
                // Badge prix
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '${_formatCurrency(residence.price)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                
                // Badge hébergement spécial
                if (showSpecialBadge && residence.isSpecialResidence)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Spécial',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Bouton favori
                Positioned(
                  top: 10,
                  left: 10,
                  child: GestureDetector(
                    onTap: onFavoritePressed,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        residence.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: residence.isFavorite ? Colors.red : Colors.grey,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          displayAddress,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildFeature(Icons.king_bed, '${residence.bedrooms}'),
                          const SizedBox(width: 15),
                          _buildFeature(Icons.bathtub, '${residence.bathrooms}'),
                          const SizedBox(width: 15),
                          _buildFeature(Icons.square_foot, '${residence.squareMeters.toInt()} m²'),
                        ],
                      ),
                      if (residence.rating > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              residence.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
