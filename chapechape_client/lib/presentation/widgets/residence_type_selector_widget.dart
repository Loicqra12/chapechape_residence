import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/spacing.dart';
import '../../core/models/residence_type_enum.dart' as model_types;

/// Classe pour représenter un type de résidence dans le sélecteur
class ResidenceType {
  final String id;
  final String name;
  final IconData icon;
  final model_types.ResidenceType? modelType;

  const ResidenceType({
    required this.id,
    required this.name,
    required this.icon,
    this.modelType,
  });
}

/// Classe pour représenter une catégorie de résidences
class ResidenceCategory {
  final String id;
  final String name;
  final IconData icon;
  final List<ResidenceType> types;

  const ResidenceCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.types,
  });
}

class ResidenceTypeSelectorWidget extends StatefulWidget {
  final List<ResidenceCategory> categories;
  final Function(ResidenceType?)? onTypeSelected;
  final ResidenceType? initialType;
  final bool showCategories;
  final String? initialCategoryId;

  const ResidenceTypeSelectorWidget({
    Key? key,
    required this.categories,
    this.onTypeSelected,
    this.initialType,
    this.showCategories = true,
    this.initialCategoryId,
  }) : super(key: key);

  @override
  State<ResidenceTypeSelectorWidget> createState() =>
      _ResidenceTypeSelectorWidgetState();
}

class _ResidenceTypeSelectorWidgetState
    extends State<ResidenceTypeSelectorWidget> {
  ResidenceType? _selectedType;
  String? _selectedCategoryId;
  List<ResidenceType> _filteredTypes = [];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _selectedCategoryId =
        widget.initialCategoryId ?? widget.categories.first.id;
    _updateFilteredTypes();
  }

  void _updateFilteredTypes() {
    if (_selectedCategoryId != null) {
      // Filtrer les types selon la catégorie sélectionnée
      final category = widget.categories.firstWhere(
        (cat) => cat.id == _selectedCategoryId,
        orElse: () => widget.categories.first,
      );
      setState(() {
        _filteredTypes = category.types;
      });
    } else {
      // Si aucune catégorie n'est sélectionnée, afficher tous les types
      setState(() {
        _filteredTypes = widget.categories.expand((cat) => cat.types).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section des catégories (optionnelle)
        if (widget.showCategories) _buildCategoriesSelector(),

        // Section des types
        _buildTypesSelector(),
      ],
    );
  }

  Widget _buildCategoriesSelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[800] : AppTheme.textLight;
    final textColor = isDarkMode ? Colors.white70 : AppTheme.textPrimary;
    final selectedTextColor = isDarkMode ? AppTheme.textLight : AppTheme.textLight;
    final iconColor = isDarkMode ? Colors.white70 : AppTheme.primaryColor;
    final selectedIconColor = isDarkMode ? AppTheme.textLight : AppTheme.textLight;
    final borderColor = isDarkMode ? Colors.grey[700] : AppTheme.dividerColor;

    return Container(
      height: 130, // Hauteur augmentée pour correspondre au sélecteur de type
      margin: EdgeInsets.only(bottom: AppSpacing.md), // Marge inférieure ajustée
      clipBehavior: Clip.hardEdge, // Ajouté pour la cohérence et pour éviter le débordement visuel
      decoration: BoxDecoration(
        // Pas de couleur de fond ici, chaque carte aura la sienne
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        // Pas d'ombre globale ici, chaque carte aura la sienne si nécessaire
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.categories.length,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm), // Padding vertical ajouté
        itemBuilder: (context, index) {
          final category = widget.categories[index];
          final isSelected = category.id == _selectedCategoryId;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.smd / 2), // Espacement horizontal entre les cartes
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCategoryId = category.id;
                  _selectedType = null; // Réinitialiser le type sélectionné
                  if (widget.onTypeSelected != null) {
                    widget.onTypeSelected!(null); // Notifier qu'aucun type n'est sélectionné
                  }
                });
                _updateFilteredTypes();
              },
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                width: 110, // Largeur ajustée
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.smd), // Padding interne ajusté
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : cardColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : borderColor!,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.textPrimary.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category.icon,
                      size: 32, // Taille de l'icône augmentée
                      color: isSelected ? selectedIconColor : iconColor,
                    ),
                    SizedBox(height: AppSpacing.sm), // Espacement ajusté
                    Text(
                      category.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: isSelected ? selectedTextColor : textColor,
                        fontSize: 13, // Taille de police ajustée
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypesSelector() {
    return Container(
      height: 132, // Augmenté de 2 pixels pour résoudre le débordement
      clipBehavior: Clip.hardEdge, // Ajouté pour éviter tout débordement visuel
      decoration: BoxDecoration(
        color: AppTheme.textLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filteredTypes.length,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        itemBuilder: (context, index) {
          final type = _filteredTypes[index];
          final isSelected = type.id == _selectedType?.id;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedType = type;
                });
                if (widget.onTypeSelected != null) {
                  widget.onTypeSelected!(type);
                }
              },
              child: Container(
                width: 100,
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.dividerColor,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type.icon,
                      size: 32,
                      color: isSelected ? AppTheme.textLight : AppTheme.primaryColor,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      type.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: isSelected ? AppTheme.textLight : AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Liste des types de résidences organisées par catégories
final List<ResidenceCategory> availableResidenceCategories = [
  // Catégorie 1: Résidences meublées
  ResidenceCategory(
    id: 'residences_meublees',
    name: 'Résidences meublées',
    icon: Icons.apartment,
    types: [
      ResidenceType(
        id: 'studio_meuble',
        name: 'Studio meublé',
        icon: Icons.single_bed,
        modelType: model_types.ResidenceType.studioMeuble,
      ),
      ResidenceType(
        id: 'appartement_meuble',
        name: 'Appartement meublé',
        icon: Icons.apartment,
        modelType: model_types.ResidenceType.appartementMeuble,
      ),
      ResidenceType(
        id: 'villa_meublee',
        name: 'Villa meublée',
        icon: Icons.home,
        modelType: model_types.ResidenceType.villaMeublee,
      ),
      ResidenceType(
        id: 'penthouse',
        name: 'Penthouse',
        icon: Icons.location_city,
        modelType: model_types.ResidenceType.penthouse,
      ),
      ResidenceType(
        id: 'loft',
        name: 'Loft',
        icon: Icons.view_quilt,
        modelType: model_types.ResidenceType.loft,
      ),
      ResidenceType(
        id: 'grenier',
        name: 'Grenier aménagé',
        icon: Icons.roofing,
        modelType: model_types.ResidenceType.grenier,
      ),
    ],
  ),

  // Catégorie 2: Hôtels & Hébergements classiques
  ResidenceCategory(
    id: 'hotels_hebergements',
    name: 'Hôtels & Hébergements',
    icon: Icons.hotel,
    types: [
      ResidenceType(
        id: 'hotel_passage',
        name: 'Hôtel de passage',
        icon: Icons.timer,
        modelType: model_types.ResidenceType.hotelDePassage,
      ),
      ResidenceType(
        id: 'motel',
        name: 'Motel',
        icon: Icons.directions_car,
        modelType: model_types.ResidenceType.motel,
      ),
      ResidenceType(
        id: 'boutique_hotel',
        name: 'Boutique-Hôtel',
        icon: Icons.star,
        modelType: model_types.ResidenceType.boutiqueHotel,
      ),
      ResidenceType(
        id: 'hotel_luxe',
        name: 'Hôtel de luxe',
        icon: Icons.star_rate,
        modelType: model_types.ResidenceType.hotelDeLuxe,
      ),
      ResidenceType(
        id: 'guest_house',
        name: 'Auberge & Guest House',
        icon: Icons.house,
        modelType: model_types.ResidenceType.aubergeEtMaisonDHotes,
      ),
      ResidenceType(
        id: 'residence_hoteliere',
        name: 'Résidence hôtelière',
        icon: Icons.hotel_class,
        modelType: model_types.ResidenceType.residenceHoteliere,
      ),
    ],
  ),

  // Catégorie 3: Hébergements insolites & nature
  ResidenceCategory(
    id: 'hebergements_insolites',
    name: 'Hébergements insolites',
    icon: Icons.landscape,
    types: [
      ResidenceType(
        id: 'bungalow',
        name: 'Bungalow',
        icon: Icons.holiday_village,
        modelType: model_types.ResidenceType.bungalow,
      ),
      ResidenceType(
        id: 'lodge',
        name: 'Lodge & écolodge',
        icon: Icons.park,
        modelType: model_types.ResidenceType.lodgeEtEcolodge,
      ),
      ResidenceType(
        id: 'case_traditionnelle',
        name: 'Case traditionnelle',
        icon: Icons.grain,
        modelType: model_types.ResidenceType.caseTraditionnelle,
      ),
      ResidenceType(
        id: 'maison_flottante',
        name: 'Maison flottante',
        icon: Icons.sailing,
        modelType: model_types.ResidenceType.maisonFlottante,
      ),
      ResidenceType(
        id: 'campement_touristique',
        name: 'Campement touristique',
        icon: Icons.cabin,
        modelType: model_types.ResidenceType.campementTouristique,
      ),
    ],
  ),

  // Catégorie 4: Colocation & résidences partagées
  ResidenceCategory(
    id: 'colocation_partage',
    name: 'Colocation & partage',
    icon: Icons.people,
    types: [
      ResidenceType(
        id: 'chambre_colocation',
        name: 'Chambre en colocation',
        icon: Icons.person,
        modelType: model_types.ResidenceType.chambreEnColocation,
      ),
      ResidenceType(
        id: 'coliving',
        name: 'Coliving',
        icon: Icons.people,
        modelType: model_types.ResidenceType.cohabitation,
      ),
      ResidenceType(
        id: 'maison_hotes',
        name: 'Maison d\'hôtes',
        icon: Icons.home_work,
        modelType: model_types.ResidenceType.guesthouse,
      ),
      ResidenceType(
        id: 'residence_universitaire',
        name: 'Résidence universitaire',
        icon: Icons.school,
        modelType: model_types.ResidenceType.residenceUniversitaire,
      ),
      ResidenceType(
        id: 'cite_dortoir',
        name: 'Cité & dortoir',
        icon: Icons.night_shelter,
        modelType: model_types.ResidenceType.citeDortoir,
      ),
    ],
  ),

  // Catégorie 5: Résidences longue durée
  ResidenceCategory(
    id: 'residences_longue_duree',
    name: 'Résidences longue durée',
    icon: Icons.home,
    types: [
      ResidenceType(
        id: 'appartement_vide',
        name: 'Appartement non meublé',
        icon: Icons.domain,
        modelType: model_types.ResidenceType.appartementNonMeuble,
      ),
      ResidenceType(
        id: 'villa_vide',
        name: 'Villa non meublée',
        icon: Icons.villa,
        modelType: model_types.ResidenceType.villaNonMeublee,
      ),
      ResidenceType(
        id: 'immeuble',
        name: 'Immeuble',
        icon: Icons.business,
        modelType: model_types.ResidenceType.immeuble,
      ),
      ResidenceType(
        id: 'cour_commune',
        name: 'Cour commune',
        icon: Icons.apps,
        modelType: model_types.ResidenceType.courCommune,
      ),
    ],
  ),

  // Catégorie 6: Hébergements économiques et populaires
  ResidenceCategory(
    id: 'hebergements_economiques',
    name: 'Hébergements économiques',
    icon: Icons.monetization_on,
    types: [
      ResidenceType(
        id: 'maison_hotes_economique',
        name: 'Maison d\'hôtes économique',
        icon: Icons.home_mini,
        modelType: model_types.ResidenceType.maisonDHotesEconomique,
      ),
      ResidenceType(
        id: 'residence_familiale',
        name: 'Résidence familiale',
        icon: Icons.family_restroom,
        modelType: model_types.ResidenceType.residenceFamilialeEnLocation,
      ),
      ResidenceType(
        id: 'chambres_passage',
        name: 'Chambres de passage',
        icon: Icons.bedroom_child,
        modelType: model_types.ResidenceType.chambresDePassage,
      ),
    ],
  ),
];

// Pour la compatibilité avec le code existant
final List<ResidenceType> availableResidenceTypes =
    availableResidenceCategories.expand((category) => category.types).toList();
