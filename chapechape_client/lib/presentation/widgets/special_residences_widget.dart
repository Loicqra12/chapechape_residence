import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/blocs/residence/residence_state.dart';
import '../../core/blocs/residence/residence_event.dart';
import '../../core/models/residence_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import 'residence_card.dart';
import 'amenities_widget.dart';

class SpecialResidencesWidget extends StatelessWidget {
  const SpecialResidencesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResidenceBloc, ResidenceState>(
      builder: (context, state) {
        if (state is ResidenceLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ResidencesLoaded) {
          final specialResidences = state.residences
              .where((r) => r.hasPool || r.isVacationResidence)
              .take(5)
              .toList();

          if (specialResidences.isEmpty) {
            return const Center(
              child: Text('Aucune résidence spéciale disponible pour le moment'),
            );
          }

          return _buildSpecialResidencesGrid(context, specialResidences);
        } else if (state is ResidenceError) {
          return Center(
            child: Text('Erreur: ${state.message}'),
          );
        } else {
          return const Center(
            child: Text('Aucune résidence disponible'),
          );
        }
      },
    );
  }

  Widget _buildSpecialResidencesGrid(BuildContext context, List<Residence> residences) {
    // Déterminer le nombre de colonnes en fonction de la largeur de l'écran
    int crossAxisCount;
    if (context.screenWidth < 600) {
      crossAxisCount = 1; // Mobile
    } else if (context.screenWidth < 900) {
      crossAxisCount = 2; // Tablette
    } else {
      crossAxisCount = 3; // Desktop
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résidences spéciales',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Découvrez nos résidences avec piscine et idéales pour les vacances',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: residences.length,
            itemBuilder: (context, index) {
              return _buildResidenceCard(context, residences[index]);
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: () {
                context.go('/residences', extra: {'filter': 'special'});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Voir toutes les résidences spéciales',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidenceCard(BuildContext context, Residence residence) {
    // Vérifier si la résidence est null
    if (residence == null) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          context.go('/residence/${residence.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: _buildResidenceImage(residence),
                  ),
                  
                  // Badge spécial
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.isMobileSmall ? 8 : 12,
                        vertical: context.isMobileSmall ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        residence.hasPool ? 'Piscine' : 'Vacances',
                        style: TextStyle(
                          fontSize: context.responsiveFontSize(12),
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Informations
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(context.isMobileSmall ? 8 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      residence.title,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(16),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      residence.location['displayAddress'] ?? 'Adresse non disponible',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(12),
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Équipements
                    if (residence.amenities != null && residence.amenities!.isNotEmpty)
                      Expanded(
                        child: AmenitiesWidget(
                          amenities: residence.amenities!.take(3).toList(),
                          isDetailed: false,
                        ),
                      ),
                    
                    // Prix
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${residence.pricePerNight} FCFA',
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(16),
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: residence.status == 'available' 
                                ? Colors.green[100] 
                                : Colors.red[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            residence.status == 'available' ? 'Disponible' : 'Indisponible',
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(10),
                              fontWeight: FontWeight.bold,
                              color: residence.status == 'available' 
                                  ? Colors.green[800] 
                                  : Colors.red[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResidenceImage(Residence residence) {
    return Image.network(
      residence.imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Utiliser une image locale en cas d'erreur
        return Image.asset(
          residence.getDefaultImageByType(),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.home, color: Colors.white, size: 50),
              ),
            );
          },
        );
      },
    );
  }
}
