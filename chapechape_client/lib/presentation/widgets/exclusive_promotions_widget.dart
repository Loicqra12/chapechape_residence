import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/promotion_model.dart';
import '../../core/services/promotion_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/spacing.dart';
import '../../core/utils/responsive_utils.dart';
import 'promotion_countdown_widget.dart';
import 'common/premium_card.dart';

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
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec titre et sous-titre
          _buildHeader(          ),
          
          SizedBox(height: AppSpacing.md),
          
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
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            Icons.local_offer,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        
        SizedBox(width: AppSpacing.smd),
        
        // Titre et sous-titre
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: AppTextStyles.title.copyWith(
                  fontSize: context.responsiveFontSize(20),
                ),
              ),
              if (widget.subtitle != null) ...[
                SizedBox(height: AppSpacing.xs),
                Text(
                  widget.subtitle!,
                  style: AppTextStyles.body.copyWith(
                    fontSize: context.responsiveFontSize(14),
                    color: AppTheme.textSecondary,
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
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Garantit que la Row prend la taille minimale
              children: [
                Text(
                  'Voir tout',
                  style: AppTextStyles.link.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: AppSpacing.xs),
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
          SizedBox(height: AppSpacing.md),
          Text(
            'Chargement des promotions...',
            style: AppTextStyles.body.copyWith(
              color: AppTheme.textSecondary,
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
            color: AppTheme.errorColor,
            size: 48,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Impossible de charger les promotions',
            style: AppTextStyles.title.copyWith(
              fontSize: context.responsiveFontSize(16),
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Veuillez réessayer plus tard',
            style: AppTextStyles.body.copyWith(
              fontSize: context.responsiveFontSize(14),
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _loadPromotions();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.textLight,
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
            color: AppTheme.textSecondary,
            size: 48,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Aucune promotion disponible',
            style: AppTextStyles.title.copyWith(
              fontSize: context.responsiveFontSize(16),
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Revenez bientôt pour découvrir nos offres',
            style: AppTextStyles.body.copyWith(
              fontSize: context.responsiveFontSize(14),
              color: AppTheme.textSecondary,
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
        child: PremiumCard(
        width: 300,
        margin: EdgeInsets.only(right: AppSpacing.md),
        borderRadius: 20,
        elevation: isHovered ? 8 : 5,
        backgroundColor: AppTheme.textLight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
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
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre
                      Text(
                        promotion.title,
                        style: AppTextStyles.title.copyWith(
                          fontSize: context.responsiveFontSize(16),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: AppSpacing.sm),
                      
                      // Description
                      Expanded(
                        child: Text(
                          promotion.description,
                          style: AppTextStyles.body.copyWith(
                            fontSize: context.responsiveFontSize(14),
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Code promo si disponible
                      if (promotion.discountCode != null) ...[
                        SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Icon(
                              Icons.discount,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                            SizedBox(width: AppSpacing.smd / 2),
                            Text(
                              'Code: ',
                              style: AppTextStyles.body.copyWith(
                                fontSize: context.responsiveFontSize(14),
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              promotion.discountCode!,
                              style: AppTextStyles.body.copyWith(
                                fontSize: context.responsiveFontSize(14),
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      // Validité
                      SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          SizedBox(width: AppSpacing.smd / 2),
                          Text(
                            'Valable jusqu\'au ${DateFormat('dd/MM/yyyy').format(promotion.endDate)}',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: context.responsiveFontSize(12),
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      
                      // Bouton
                      SizedBox(height: AppSpacing.smd),
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
                                foregroundColor: AppTheme.textLight,
                                padding: AppSpacing.buttonPadding,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
        child: PremiumCard(
        width: 220,
        margin: EdgeInsets.only(right: AppSpacing.smd),
        borderRadius: 16,
        elevation: isHovered ? 6 : 3,
        backgroundColor: AppTheme.textLight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
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
                padding: EdgeInsets.all(AppSpacing.smd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    Text(
                      promotion.title,
                      style: AppTextStyles.title.copyWith(
                        fontSize: context.responsiveFontSize(14),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: AppSpacing.smd / 2),
                    
                    // Description
                    Text(
                      promotion.description,
                      style: AppTextStyles.body.copyWith(
                        fontSize: context.responsiveFontSize(12),
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: AppSpacing.sm),
                    
                    // Code promo
                    if (promotion.discountCode != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppTheme.dividerColor,
                          borderRadius: BorderRadius.circular(AppSpacing.xs),
                          border: Border.all(color: AppTheme.dividerColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.discount,
                              size: 14,
                              color: AppTheme.primaryColor,
                            ),
                            SizedBox(width: AppSpacing.xs),
                            Text(
                              promotion.discountCode!,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: context.responsiveFontSize(12),
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    SizedBox(height: AppSpacing.sm),
                    
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
                          foregroundColor: AppTheme.textLight,
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.smd / 2),
                          ),
                          elevation: isHovered ? 3 : 1,
                          textStyle: AppTextStyles.button.copyWith(
                            fontSize: context.responsiveFontSize(12),
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
        color: AppTheme.dividerColor,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        height: height,
        color: AppTheme.dividerColor,
        child: Center(
          child: Icon(
            Icons.broken_image,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
  
  Widget _buildPromotionBadge(Promotion promotion, {bool isCompact = false}) {
    final badgeText = promotion.badge ?? promotion.type.displayName;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? AppSpacing.smd / 2 : AppSpacing.sm,
        vertical: isCompact ? AppSpacing.xs / 2 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _getBadgeColor(promotion.type),
        borderRadius: BorderRadius.circular(isCompact ? AppSpacing.xs : AppSpacing.smd / 2),
      ),
      child: Text(
        badgeText.toUpperCase(),
        style: AppTextStyles.tag.copyWith(
          color: AppTheme.textLight,
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
        horizontal: isCompact ? AppSpacing.smd / 2 : AppSpacing.sm,
        vertical: isCompact ? AppSpacing.xs / 2 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppTheme.errorColor,
        borderRadius: BorderRadius.circular(isCompact ? AppSpacing.xs : AppSpacing.smd / 2),
      ),
      child: Text(
        '-${promotion.discountPercentage.toStringAsFixed(0)}%',
        style: AppTextStyles.tag.copyWith(
          color: AppTheme.textLight,
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
