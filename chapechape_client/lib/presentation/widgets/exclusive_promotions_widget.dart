import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/promotion_model.dart';
import '../../core/services/promotion_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import 'promotion_countdown_widget.dart';

/// Widget affichant la liste des offres et promotions exclusives
class ExclusivePromotionsWidget extends StatefulWidget {
  /// Callback appelé lorsqu'une promotion est sélectionnée
  final Function(Promotion)? onPromotionSelected;
  
  /// Titre du widget
  final String title;
  
  /// Sous-titre descriptif
  final String? subtitle;
  
  /// Nombre maximum de promotions à afficher
  final int maxItems;
  
  /// Si true, affiche uniquement les promotions exclusives
  final bool exclusiveOnly;
  
  const ExclusivePromotionsWidget({
    Key? key,
    this.onPromotionSelected,
    this.title = 'Offres & Promotions Exclusives',
    this.subtitle,
    this.maxItems = 5,
    this.exclusiveOnly = true,
  }) : super(key: key);

  @override
  State<ExclusivePromotionsWidget> createState() => _ExclusivePromotionsWidgetState();
}

class _ExclusivePromotionsWidgetState extends State<ExclusivePromotionsWidget> {
  // Initialiser avec une Future déjà complétée vide pour éviter l'erreur LateInitializationError
  Future<List<Promotion>> _promotionsFuture = Future.value([]);
  final _scrollController = ScrollController();
  int _hoveredIndex = -1;
  
  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _loadPromotions() async {
    final service = await PromotionService.initialize();
    setState(() {
      _promotionsFuture = widget.exclusiveOnly 
          ? service.getExclusivePromotions() 
          : service.getActivePromotions();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec titre et sous-titre
          _buildHeader(),
          
          const SizedBox(height: 16),
          
          // Liste des promotions
          SizedBox(
            height: 320,
            child: FutureBuilder<List<Promotion>>(
              future: _promotionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingIndicator();
                } else if (snapshot.hasError) {
                  return _buildErrorWidget(snapshot.error.toString());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }
                
                final promotions = snapshot.data!;
                final displayItems = promotions.length > widget.maxItems 
                    ? promotions.sublist(0, widget.maxItems) 
                    : promotions;
                
                return _buildPromotionsList(displayItems);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      children: [
        // Icône décorative
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.local_offer,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Titre et sous-titre
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: context.responsiveFontSize(20),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.subtitle!,
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(14),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Bouton Voir tout
        Container(
          constraints: const BoxConstraints(maxWidth: 120), // Contrainte de largeur explicite
          child: TextButton(
            onPressed: () {
              // Navigation vers la liste complète des promotions
              context.push('/promotions');
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Garantit que la Row prend la taille minimale
              children: [
                Text(
                  'Voir tout',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement des promotions...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: context.responsiveFontSize(14),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[400],
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Impossible de charger les promotions',
            style: TextStyle(
              fontSize: context.responsiveFontSize(16),
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Veuillez réessayer plus tard',
            style: TextStyle(
              fontSize: context.responsiveFontSize(14),
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _loadPromotions();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            color: Colors.grey[400],
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune promotion disponible',
            style: TextStyle(
              fontSize: context.responsiveFontSize(16),
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Revenez bientôt pour découvrir nos offres',
            style: TextStyle(
              fontSize: context.responsiveFontSize(14),
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPromotionsList(List<Promotion> promotions) {
    // Version plus simple pour petit écran
    if (MediaQuery.of(context).size.width < 600) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: promotions.length,
        controller: _scrollController,
        itemBuilder: (context, index) => _buildCompactPromotionCard(promotions[index], index),
      );
    }
    
    // Version plus riche pour grand écran
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: promotions.length,
      controller: _scrollController,
      itemBuilder: (context, index) => _buildPromotionCard(promotions[index], index),
    );
  }
  
  Widget _buildPromotionCard(Promotion promotion, int index) {
    final isHovered = _hoveredIndex == index;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: GestureDetector(
        onTap: () {
          if (widget.onPromotionSelected != null) {
            widget.onPromotionSelected!(promotion);
          } else {
            // Navigation par défaut vers les détails de la promotion
            context.push('/promotion/${promotion.id}');
          }
        },
        child: Container(
          width: 300,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isHovered ? 0.15 : 0.08),
                blurRadius: isHovered ? 12 : 8,
                offset: Offset(0, isHovered ? 6 : 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image avec badge
              Stack(
                children: [
                  // Image
                  _buildPromotionImage(promotion, height: 150),
                  
                  // Badges
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _buildPromotionBadge(promotion),
                  ),
                  
                  // Countdown timer pour les offres à durée limitée
                  if (promotion.isLastMinute)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: _buildCountdownBadge(promotion),
                    ),
                  
                  // Discount overlay
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _buildDiscountBadge(promotion),
                  ),
                ],
              ),
              
              // Contenu
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre
                      Text(
                        promotion.title,
                        style: TextStyle(
                          fontSize: context.responsiveFontSize(16),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Description
                      Expanded(
                        child: Text(
                          promotion.description,
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(14),
                            color: Colors.grey[600],
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Code promo si disponible
                      if (promotion.discountCode != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.discount,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Code: ',
                              style: TextStyle(
                                fontSize: context.responsiveFontSize(14),
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              promotion.discountCode!,
                              style: TextStyle(
                                fontSize: context.responsiveFontSize(14),
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      // Validité
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Valable jusqu\'au ${DateFormat('dd/MM/yyyy').format(promotion.endDate)}',
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(12),
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      
                      // Bouton
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (widget.onPromotionSelected != null) {
                                  widget.onPromotionSelected!(promotion);
                                } else {
                                  // Navigation par défaut vers les détails de la promotion
                                  context.push('/promotion/${promotion.id}');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: isHovered ? 4 : 2,
                              ),
                              child: const Text('En profiter'),
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
        )
        .animate(target: isHovered ? 1 : 0)
        .scale(begin: const Offset(1, 1), end: const Offset(1.03, 1.03), duration: 300.ms, curve: Curves.easeOutQuad)
        .elevation(begin: 2, end: 8, duration: 300.ms),
      ),
    );
  }
  
  Widget _buildCompactPromotionCard(Promotion promotion, int index) {
    final isHovered = _hoveredIndex == index;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: GestureDetector(
        onTap: () {
          if (widget.onPromotionSelected != null) {
            widget.onPromotionSelected!(promotion);
          } else {
            // Navigation par défaut vers les détails de la promotion
            context.push('/promotion/${promotion.id}');
          }
        },
        child: Container(
          width: 220,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isHovered ? 0.12 : 0.06),
                blurRadius: isHovered ? 10 : 6,
                offset: Offset(0, isHovered ? 4 : 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image avec badge
              Stack(
                children: [
                  // Image
                  _buildPromotionImage(promotion, height: 120),
                  
                  // Badges
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _buildPromotionBadge(promotion, isCompact: true),
                  ),
                  
                  // Discount overlay
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildDiscountBadge(promotion, isCompact: true),
                  ),
                ],
              ),
              
              // Contenu
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    Text(
                      promotion.title,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(14),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Description
                    Text(
                      promotion.description,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(12),
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Code promo
                    if (promotion.discountCode != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.discount,
                              size: 14,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              promotion.discountCode!,
                              style: TextStyle(
                                fontSize: context.responsiveFontSize(12),
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Bouton
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (widget.onPromotionSelected != null) {
                            widget.onPromotionSelected!(promotion);
                          } else {
                            // Navigation par défaut vers les détails de la promotion
                            context.push('/promotion/${promotion.id}');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: isHovered ? 3 : 1,
                          textStyle: TextStyle(
                            fontSize: context.responsiveFontSize(12),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('En profiter'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate(target: isHovered ? 1 : 0)
        .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 250.ms, curve: Curves.easeOutQuad)
        .elevation(begin: 1, end: 5, duration: 250.ms),
      ),
    );
  }
  
  Widget _buildPromotionImage(Promotion promotion, {required double height}) {
    return CachedNetworkImage(
      imageUrl: promotion.imageUrl,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        height: height,
        color: Colors.grey[200],
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        height: height,
        color: Colors.grey[200],
        child: Center(
          child: Icon(
            Icons.broken_image,
            color: Colors.grey[400],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPromotionBadge(Promotion promotion, {bool isCompact = false}) {
    final badgeText = promotion.badge ?? promotion.type.displayName;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: _getBadgeColor(promotion.type),
        borderRadius: BorderRadius.circular(isCompact ? 4 : 6),
      ),
      child: Text(
        badgeText.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: isCompact 
              ? context.responsiveFontSize(8) 
              : context.responsiveFontSize(10),
        ),
      ),
    );
  }
  
  Widget _buildDiscountBadge(Promotion promotion, {bool isCompact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(isCompact ? 4 : 6),
      ),
      child: Text(
        '-${promotion.discountPercentage.toStringAsFixed(0)}%',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: isCompact 
              ? context.responsiveFontSize(10) 
              : context.responsiveFontSize(12),
        ),
      ),
    );
  }
  
  Widget _buildCountdownBadge(Promotion promotion) {
    return PromotionCountdownWidget(
      promotion: promotion,
      isCompact: true,
    );
  }
  
  Color _getBadgeColor(PromotionType type) {
    final colorHex = type.badgeColor;
    
    // Convertir le code hexadécimal en Color
    final value = int.parse(colorHex.substring(1), radix: 16);
    return Color(value).withOpacity(1);
  }
}
