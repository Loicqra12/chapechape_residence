import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/residence_type_enum.dart';

/// Widget premium pour afficher les catégories de résidences
/// Design modernisé avec glassmorphism, icônes différenciées et texte complet
class CategoriesMenuWidget extends StatefulWidget {
  final bool showTitle;
  final String title;
  final ResidenceType filterType;
  
  const CategoriesMenuWidget({
    super.key,
    this.showTitle = false,
    this.title = "Catégories",
    this.filterType = ResidenceType.other,
  });

  @override
  State<CategoriesMenuWidget> createState() => _CategoriesMenuWidgetState();
}

class _CategoriesMenuWidgetState extends State<CategoriesMenuWidget> {
  final ScrollController _scrollController = ScrollController();

  // Données statiques pour les catégories avec icônes et couleurs différenciées
  final List<Map<String, dynamic>> _staticCategories = [
    {
      'title': 'Colocation & partage',
      'icon': Icons.people,
      'type': ResidenceType.chambreEnColocation,
      'color': Color(0xFFFF6B6B), // Rouge corail
    },
    {
      'title': 'Résidences longue durée',
      'icon': Icons.home_work,
      'type': ResidenceType.appartementNonMeuble,
      'color': Color(0xFF4ECDC4), // Turquoise
    },
    {
      'title': 'Hébergements économiques',
      'icon': Icons.attach_money,
      'type': ResidenceType.maisonDHotesEconomique,
      'color': Color(0xFFFFD93D), // Jaune doré
    },
    {
      'title': 'Studios meublés',
      'icon': Icons.weekend,
      'type': ResidenceType.studioMeuble,
      'color': Color(0xFF6BCF7F), // Vert menthe
    },
    {
      'title': 'Hôtels & Résidences',
      'icon': Icons.hotel,
      'type': ResidenceType.hotelDePassage,
      'color': Color(0xFFB47AEA), // Violet
    },
    {
      'title': 'Hébergements insolites',
      'icon': Icons.landscape,
      'type': ResidenceType.bungalow,
      'color': Color(0xFFFF8C42), // Orange
    },
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollLeft() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        (_scrollController.offset - 200).clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollRight() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        (_scrollController.offset + 200).clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
        
        // Grid View - 3 colonnes, 2 rangées
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75, // Ratio optimisé pour le contenu
            ),
            itemCount: _staticCategories.length,
            itemBuilder: (context, index) {
              final category = _staticCategories[index];
              return _buildCategoryCard(
                context: context,
                title: category['title'],
                icon: category['icon'],
                type: category['type'],
                accentColor: category['color'],
                isDarkMode: isDarkMode,
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required ResidenceType type,
    required Color accentColor,
    required bool isDarkMode,
    required int index,
  }) {
    final isSelected = type == widget.filterType;
    
    return Container(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onCategoryTap(type),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        Color(0xFF2D2D2D),
                        Color(0xFF1F1F1F),
                      ]
                    : [
                        Colors.white,
                        Colors.grey.shade50,
                      ],
              ),
              border: Border.all(
                color: isSelected 
                    ? accentColor 
                    : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(isSelected ? 0.3 : 0.1),
                  blurRadius: isSelected ? 12 : 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icône dans un cercle coloré
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accentColor.withOpacity(0.2),
                          accentColor.withOpacity(0.05),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: 28,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Titre sur 2 lignes maximum
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: (index * 80).ms)
              .slideX(begin: 0.2, end: 0, duration: 400.ms, delay: (index * 80).ms),
        ),
      ),
    );
  }

  void _onCategoryTap(ResidenceType type) {
    // Navigation vers la page de recherche avec le type sélectionné
    context.push('/search?type=${type.toString().split('.').last}');
  }
}