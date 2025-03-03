import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/blocs/residence/residence_state.dart';
import '../../core/blocs/residence/residence_event.dart';
import '../../core/models/residence_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/constants/app_assets.dart';

class ResidenceTypeWidget extends StatelessWidget {
  final ResidenceType type;
  final String title;
  final String description;

  const ResidenceTypeWidget({
    Key? key,
    required this.type,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResidenceBloc, ResidenceState>(
      builder: (context, state) {
        if (state is ResidenceLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ResidencesLoaded) {
          final filteredResidences = state.residences
              .where((r) => r.type == type)
              .take(4)
              .toList();

          if (filteredResidences.isEmpty) {
            return const SizedBox.shrink(); // Ne pas afficher si aucune résidence
          }

          return _buildResidenceTypeSection(context, filteredResidences);
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildResidenceTypeSection(BuildContext context, List<Residence> residences) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          _buildResidencesList(context, residences),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: () {
                context.go('/residences', extra: {'type': type.toString().split('.').last});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Voir toutes les ${_getTypeDisplayName()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidencesList(BuildContext context, List<Residence> residences) {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: residences.length,
        itemBuilder: (context, index) {
          return _buildResidenceCard(context, residences[index]);
        },
      ),
    );
  }

  Widget _buildResidenceCard(BuildContext context, Residence residence) {
    // Vérifier si la résidence est null
    if (residence == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
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
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image
              SizedBox(
                height: 160,
                width: double.infinity,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: _buildResidenceImage(residence),
                    ),
                    
                    // Badge de statut
                    if (residence.status == 'available')
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Disponible',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Informations
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      residence.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      residence.location['displayAddress'] ?? 'Adresse non disponible',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Prix
                    Text(
                      '${residence.pricePerNight} FCFA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
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

  String _getTypeDisplayName() {
    switch (type) {
      case ResidenceType.apartment:
        return 'appartements';
      case ResidenceType.luxury:
        return 'résidences de luxe';
      case ResidenceType.studio:
        return 'studios';
      case ResidenceType.villa:
        return 'villas';
      case ResidenceType.bungalow:
        return 'bungalows';
      case ResidenceType.hotel:
        return 'hôtels';
      case ResidenceType.penthouse:
        return 'penthouses';
      case ResidenceType.room:
        return 'chambres';
      case ResidenceType.coworking:
        return 'espaces de coworking';
      case ResidenceType.student:
        return 'résidences étudiantes';
      default:
        return 'résidences';
    }
  }
}
