import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/blocs/residence/residence_state.dart';
import '../../core/blocs/residence/residence_event.dart';
import '../../core/models/residence_model.dart' as model;
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/constants/app_assets.dart' as assets;
import 'residence_card_alias.dart'; // Utilisation de l'alias
import 'shimmer_residence_card.dart'; // Ajout de l'import manquant

class ResidenceTypeWidget extends StatefulWidget {
  final String title;
  final String description;
  final assets.ResidenceType type;
  
  const ResidenceTypeWidget({
    Key? key,
    required this.type,
    required this.title,
    required this.description
  }) : super(key: key);

  @override
  State<ResidenceTypeWidget> createState() => _ResidenceTypeWidgetState();
}

class _ResidenceTypeWidgetState extends State<ResidenceTypeWidget> {
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
        } else if (state is ResidencesLoaded) {
          final model.ResidenceType? convertedType = convertToResidenceType(widget.type);
          final filteredResidences = state.residences
              .where((r) => r.type == convertedType)
              .take(5)
              .toList();
              
          if (filteredResidences.isEmpty) {
            return _buildMockResidencesByType(context, widget.type);
          }
          
          return _buildResidencesList(context, filteredResidences);
        } else if (state is ResidenceError) {
          return Center(
            child: Text(
              'Erreur: ${state.message}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        
        return _buildMockResidencesByType(context, widget.type);
      },
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 370,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.only(right: 16),
            child: ShimmerResidenceCard(),
          );
        },
      ),
    );
  }

  Widget _buildResidencesList(BuildContext context, List<model.Residence> residences) {
    return Stack(
      children: [
        SizedBox(
          height: 370,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: residences.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final residence = residences[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ResidenceCard(
                  residence: residence,
                  onTap: () => context.go('/residence/${residence.id}'),
                  onFavoritePressed: () {
                    context.read<ResidenceBloc>().add(
                      ToggleFavorite(
                        residenceId: residence.id,
                        isFavorite: !residence.isFavorite,
                      ),
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

  String getTypeDescription() {
    switch (widget.type) {
      case assets.ResidenceType.apartment:
        return 'appartement';
      case assets.ResidenceType.luxury:
        return 'résidence de luxe';
      case assets.ResidenceType.villa:
        return 'villa';
      case assets.ResidenceType.studio:
        return 'studio';
      default:
        return 'logement';
    }
  }

  String getDefaultImageByType() {
    switch (widget.type) {
      case assets.ResidenceType.apartment:
        return 'assets/images/residences/apartments/seen-hotel-abidjan-plateau.jpg';
      case assets.ResidenceType.luxury:
        return 'assets/images/residences/luxury/Waterfront_view-5B-e1670065708270.webp';
      case assets.ResidenceType.villa:
        return 'assets/images/residences/villas/Villa-Santorini-Abidjan-1.jpg';
      case assets.ResidenceType.studio:
        return 'assets/images/residences/studios/304661255.jpg';
      default:
        return 'assets/images/residences/apartments/seen-hotel-abidjan-plateau.jpg';
    }
  }

  Widget _buildMockResidencesByType(BuildContext context, assets.ResidenceType residenceType) {
    // Créer des résidences de test selon le type
    final String typeDescription = getTypeDescription();
    final String defaultImage = getDefaultImageByType();
    
    // Convertir le type assets.ResidenceType en model.ResidenceType
    final model.ResidenceType? modelType = convertToResidenceType(residenceType);
    
    final mockResidences = List.generate(
      4,
      (index) => model.Residence(
        id: 'mock_type_${residenceType.toString().split('.').last}_$index',
        name: '${widget.title} ${index + 1}',
        description: 'Un bel exemple de $typeDescription proche du centre',
        price: 200000 + (index * 50000),
        address: 'Adresse de test ${index + 1}',
        city: 'Abidjan',
        country: 'Côte d\'Ivoire',
        images: [defaultImage],
        bedrooms: 1 + (index % 3),
        bathrooms: 1 + (index % 2),
        surface: 50 + (index * 20),
        isAvailable: true,
        location: {
          'displayAddress': 'Cocody, Abidjan',
          'city': 'Abidjan',
          'coordinates': [5.359952, -4.008256],
        },
        amenities: ['wifi', 'parking', if (index % 2 == 0) 'pool'],
        // Utiliser le type converti au lieu du type assets directement
        type: modelType ?? model.ResidenceType.other,
        rating: 3.5 + (index * 0.3),
      ),
    );

    return _buildResidencesList(context, mockResidences);
  }

  model.ResidenceType? convertToResidenceType(assets.ResidenceType type) {
    switch (type) {
      case assets.ResidenceType.apartment:
        return model.ResidenceType.apartment;
      case assets.ResidenceType.luxury:
        return model.ResidenceType.luxury;
      case assets.ResidenceType.villa:
        return model.ResidenceType.villa;
      case assets.ResidenceType.studio:
        return model.ResidenceType.studio;
      default:
        return model.ResidenceType.other; // Remplacer null par une valeur par défaut
    }
  }
}
