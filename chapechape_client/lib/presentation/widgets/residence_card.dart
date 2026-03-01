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
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    ).format(value);
  }
  
  // Obtient le libellé de la période de prix (par jour, par mois, etc.)
  String _getPeriodLabel(String period) {
    switch (period.toLowerCase()) {
      case 'hour':
        return '/heure';
      case 'day':
        return '/jour';
      case 'week':
        return '/semaine';
      case 'month':
        return '/mois';
      case 'year':
        return '/an';
      default:
        return '';
    }
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
        width: width ?? 176,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: Image.network(
                      residence.images.isNotEmpty
                          ? residence.images.first
                          : 'https://via.placeholder.com/300x200/CCCCCC/808080?text=Pas+d%27image',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/placeholders/no_image.jpg',
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 5,
                    left: 8,
                    child: Text(
                      '${_formatCurrency(residence.price)}${_getPeriodLabel(residence.pricePeriod)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (showBeachBadge)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.beach_access, color: Colors.white, size: 12),
                      ),
                    ),
                  if (showMountainBadge && !showBeachBadge)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.terrain, color: Colors.white, size: 12),
                      ),
                    ),
                  if (showSpecialBadge && residence.isSpecialResidence)
                    Positioned(
                      top: 6,
                      right: showBeachBadge || showMountainBadge ? 28 : 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.white, size: 10),
                            SizedBox(width: 3),
                            Text(
                              'Spécial',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (onFavoritePressed != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: GestureDetector(
                        onTap: onFavoritePressed,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            residence.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: residence.isFavorite ? Colors.red : Colors.grey,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    displayAddress,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.grey,
          size: 16,
        ),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
