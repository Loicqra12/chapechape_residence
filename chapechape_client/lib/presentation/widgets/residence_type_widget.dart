import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Import du bloc principal qui contient déjà les exports des part files
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/models/residence_model.dart' as model;
import '../../core/models/residence_type_enum.dart' as model_types;
import '../../core/constants/app_assets.dart' as assets;

// Import des widgets utilisés
import 'residence_card_alias.dart';
import 'shimmer_residence_card.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/spacing.dart';

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
          final model_types.ResidenceType? convertedType = convertToResidenceType(widget.type);
          final filteredResidences = state.residences
              .where((r) => r.type == convertedType)
              .take(5)
              .toList();
              
          if (filteredResidences.isEmpty) {
            return _buildMockResidencesByType(context, widget.type);
          }
          
          return _buildResidencesList(context, filteredResidences);
        } else if (state is ResidenceError) {
          // Si des résidences sont préservées, les utiliser au lieu d'afficher une erreur
          if (state.preservedResidences != null && state.preservedResidences!.isNotEmpty) {
            final model_types.ResidenceType? convertedType = convertToResidenceType(widget.type);
            final filteredResidences = state.preservedResidences!
                .where((r) => r.type == convertedType)
                .take(5)
                .toList();
                
            if (filteredResidences.isNotEmpty) {
              return _buildResidencesList(context, filteredResidences);
            }
          }
          
          // Sinon, afficher l'erreur
          return Center(
            child: Text(
              'Erreur: ${state.message}',
              style: AppTextStyles.error,
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
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
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
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemBuilder: (context, index) {
              final residence = residences[index];
              return Padding(
                padding: EdgeInsets.only(right: AppSpacing.md),
                child: ResidenceCard(
                  residence: residence,
                  onTap: () => context.go('/residence/${residence.id}'),
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
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppTheme.textLight.withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.textPrimary.withOpacity(0.1),
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
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppTheme.textLight.withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.textPrimary.withOpacity(0.1),
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
    final model_types.ResidenceType? modelType = convertToResidenceType(residenceType);
    
    final mockResidences = List.generate(
      4,
      (index) => model.Residence(
        id: 'mock_type_${residenceType.toString().split('.').last}_$index',
        title: '${widget.title} ${index + 1}', // Utiliser title au lieu de name
        description: 'Un bel exemple de $typeDescription proche du centre',
        shortDescription: 'Belle résidence ${index + 1}',
        price: 200000 + (index * 50000),
        location: {
          'address': 'Adresse de test ${index + 1}',
          'city': 'Abidjan',
          'country': 'Côte d\'Ivoire',
          'displayAddress': 'Cocody, Abidjan',
          'coordinates': [5.359952, -4.008256],
        },
        images: [defaultImage],
        bedrooms: 1 + (index % 3),
        bathrooms: 1 + (index % 2),
        squareMeters: 80 + (index * 20),
        hasPool: index % 2 == 0,
        hasWifi: true,
        isVacationResidence: index % 3 == 0,
        isSpecialResidence: index % 4 == 0,
        isAvailable: true,
        isFeatured: index == 0,
        isPopular: index == 1,
        isVerified: true,
        isNew: index == 3,
        amenities: ['wifi', 'parking', if (index % 2 == 0) 'pool'],
        // Utiliser le type converti au lieu du type assets directement
        type: modelType ?? model_types.ResidenceType.other,
        rating: 3.5 + (index * 0.3),
        reviewCount: 10 + index,
        currency: 'FCFA',
        maxOccupancy: 2 + index,
        owner: 'Propriétaire Test',
        pricePeriod: 'nuit',
        hourlyRate: 5000.0,
        halfDayRate: 20000.0,
        fullDayRate: 35000.0,
        weekendRate: 40000.0,
      ),
    );

    return _buildResidencesList(context, mockResidences);
  }

  model_types.ResidenceType? convertToResidenceType(assets.ResidenceType type) {
    // Utiliser une table de correspondance basée sur les noms
    // Après avoir convertir le type en String, nous mappons cette String vers un type connu
    final String typeName = type.toString().split('.').last.toLowerCase();
    
    // Correspondances directes par catégorie
    
    // Types d'appartement
    if (['apartment', 'appartement', 'appartementmeuble', 'appartementnonmeuble', 
         'cohabitation', 'student', 'residenceuniversitaire', 'citedortoir']
        .contains(typeName)) {
      return model_types.ResidenceType.apartment;
    }
    
    // Types de maison
    if (['house', 'maison', 'casetraditionnelle', 'immeuble', 'courcommune',
         'residencefamilialeenlocation']
        .contains(typeName)) {
      return model_types.ResidenceType.house;
    }
    
    // Types de villa
    if (['villa', 'villameublee', 'villanonmeublee', 'maisonflottante']
        .contains(typeName)) {
      return model_types.ResidenceType.villa;
    }
    
    // Types de studio
    if (['studio', 'studiomeuble']
        .contains(typeName)) {
      return model_types.ResidenceType.studio;
    }
    
    // Types de bungalow
    if (['bungalow', 'lodge', 'lodgetecolodge', 'campementtouristique']
        .contains(typeName)) {
      return model_types.ResidenceType.bungalow;
    }
    
    // Types d'hôtel
    if (['hotel', 'motel', 'boutiquehotel', 'residencehoteliere']
        .contains(typeName)) {
      return model_types.ResidenceType.hotel;
    }
    
    // Types de chambres d'hôtel
    if (['hotelroom', 'room', 'chambre', 'chambresencolocation', 'hoteldepassage']
        .contains(typeName)) {
      return model_types.ResidenceType.hotelRoom;
    }
    
    // Types de luxe
    if (['luxury', 'luxe', 'penthouse', 'hoteldeluxe']
        .contains(typeName)) {
      return model_types.ResidenceType.luxury;
    }
    
    // Types de maisons d'hôtes
    if (['guesthouse', 'auberge', 'aubergeetmaisondhotes', 'maisondhoteseconomique']
        .contains(typeName)) {
      return model_types.ResidenceType.guesthouse;
    }
    
    // Types d'hostels
    if (['hostel', 'aubergedejeunesse', 'chambresdepassage']
        .contains(typeName)) {
      return model_types.ResidenceType.hostel;
    }
    
    // Cas spéciaux et types génériques
    if (['other', 'autre', 'coworking', 'grenier']
        .contains(typeName)) {
      return model_types.ResidenceType.other;
    }
    
    // Par défaut
    return model_types.ResidenceType.other;
  }
}
