import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/promotion_model.dart';
import '../../core/services/promotion_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/text_styles.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/promotion_countdown_widget.dart';

class PromotionDetailScreen extends StatefulWidget {
  final String promotionId;
  
  const PromotionDetailScreen({
    Key? key,
    required this.promotionId,
  }) : super(key: key);

  @override
  State<PromotionDetailScreen> createState() => _PromotionDetailScreenState();
}

class _PromotionDetailScreenState extends State<PromotionDetailScreen> {
  late Future<Promotion> _promotionFuture;
  bool _isLoading = false;
  bool _isCodeCopied = false;
  
  @override
  void initState() {
    super.initState();
    _loadPromotionDetails();
  }
  
  void _loadPromotionDetails() async {
    final service = await PromotionService.initialize();
    setState(() {
      _promotionFuture = service.getPromotionDetails(widget.promotionId);
    });
  }
  
  void _copyPromoCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() {
      _isCodeCopied = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code "$code" copié dans le presse-papier'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isCodeCopied = false;
        });
      }
    });
  }
  
  void _bookResidence(Promotion promotion) {
    setState(() {
      _isLoading = true;
    });
    
    // Simuler un appel à l'API
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        if (promotion.residence != null) {
          // Naviguer vers la page de réservation avec le code promo pré-rempli
          context.push(
            '/residences/${promotion.residenceId}/booking',
            extra: {'promoCode': promotion.discountCode},
          );
        }
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: FutureBuilder<Promotion>(
          future: _promotionFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            } else if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            } else if (!snapshot.hasData) {
              return _buildEmptyState();
            }
            
            return _buildContent(snapshot.data!);
          },
        ),
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
  
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[400],
            size: 60,
          ),
          AppSpacing.verticalMd,
          Text(
            'Impossible de charger cette promotion',
            style: AppTextStyles.subtitle,
          ),
          AppSpacing.verticalSm,
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          AppSpacing.verticalLg,
          ElevatedButton.icon(
            onPressed: () {
              _loadPromotionDetails();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
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
            Icons.search_off,
            color: Colors.grey[400],
            size: 60,
          ),
          AppSpacing.verticalMd,
          Text(
            'Promotion non trouvée',
            style: AppTextStyles.subtitle,
          ),
          AppSpacing.verticalLg,
          ElevatedButton.icon(
            onPressed: () {
              context.go('/');
            },
            icon: const Icon(Icons.home),
            label: const Text('Retour à l\'accueil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent(Promotion promotion) {
    return CustomScrollView(
      slivers: [
        // AppBar avec image en arrière-plan
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          leading: IconButton(
            icon: Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: _buildPromotionHeader(promotion),
          ),
        ),
        
        // Contenu
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: EdgeInsets.all(AppSpacing.lg20), // 20px
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info validité
                  Container(
                    padding: AppSpacing.cardPadding,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.timer,
                          color: Colors.orange,
                        ),
                        SizedBox(width: AppSpacing.smd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Offre à durée limitée',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              SizedBox(height: AppSpacing.xs),
                              Text(
                                'Valable du ${DateFormat('dd/MM/yyyy').format(promotion.startDate)} au ${DateFormat('dd/MM/yyyy').format(promotion.endDate)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[800],
                                ),
                              ),
                              if (promotion.isLastMinute) ...[
                                SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Plus que ${promotion.timeRemaining} pour en profiter !',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  AppSpacing.verticalLg,
                  
                  // Description
                  Text(
                    'À propos de cette offre',
                    style: AppTextStyles.subtitle,
                  ),
                  AppSpacing.verticalSmd,
                  Text(
                    promotion.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                  
                  AppSpacing.verticalLg,
                  
                  // Code promo
                  if (promotion.discountCode != null) ...[
                    Text(
                      'Code promo',
                      style: AppTextStyles.subtitle,
                    ),
                    AppSpacing.verticalSmd,
                    GestureDetector(
                      onTap: () => _copyPromoCode(promotion.discountCode!),
                      child: Container(
                        padding: AppSpacing.cardPadding,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(
                            color: Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                promotion.discountCode!,
                                style: AppTextStyles.subtitle.copyWith(
                                  color: AppTheme.primaryColor,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _copyPromoCode(promotion.discountCode!),
                              icon: Icon(
                                _isCodeCopied ? Icons.check : Icons.copy,
                                size: 18,
                              ),
                              label: Text(
                                _isCodeCopied ? 'Copié' : 'Copier',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isCodeCopied 
                                    ? Colors.green 
                                    : AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AppSpacing.verticalSm,
                    Text(
                      'Cliquez pour copier le code à utiliser lors de votre réservation',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    AppSpacing.verticalLg,
                  ],
                  
                  // Résidence associée
                  if (promotion.residence != null) ...[
                    Text(
                      'Résidence concernée',
                      style: AppTextStyles.subtitle,
                    ),
                    AppSpacing.verticalSmd,
                    GestureDetector(
                      onTap: () => context.push('/residences/${promotion.residenceId}'),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: promotion.residence!.imageUrl,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 160,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 160,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                            ),
                            
                            // Content
                            Padding(
                              padding: AppSpacing.cardPadding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    promotion.residence!.title,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  AppSpacing.verticalSm,
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      SizedBox(width: AppSpacing.xs),
                                      Expanded(
                                        child: Text(
                                          promotion.residence!.location['displayAddress'] ?? 'Emplacement inconnu',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  AppSpacing.verticalSm,
                                  Row(
                                    children: [
                                      // Prix original
                                      Text(
                                        '${NumberFormat.currency(symbol: '', decimalDigits: 0).format(promotion.residence!.price)} FCFA',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          decoration: TextDecoration.lineThrough,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(width: AppSpacing.sm),
                                      // Prix avec réduction
                                      Text(
                                        '${NumberFormat.currency(symbol: '', decimalDigits: 0).format(promotion.calculateDiscountedPrice(promotion.residence!.price))} FCFA',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: AppSpacing.xs),
                                      Text(
                                        '/nuit',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
                    ),
                    
                    AppSpacing.verticalLg,
                  ],
                  
                  // Conditions
                  if (promotion.termsAndConditions != null) ...[
                    Text(
                      'Conditions d\'utilisation',
                      style: AppTextStyles.subtitle,
                    ),
                    AppSpacing.verticalSmd,
                    Text(
                      promotion.termsAndConditions!,
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    AppSpacing.verticalLg,
                  ],
                  
                  // Bouton réserver
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _bookResidence(promotion),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.smd),
                        ),
                      ),
                      child: Text(
                        'Réserver maintenant',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  AppSpacing.verticalMd,
                  
                  // Bouton partager
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Fonctionnalité de partage à implémenter
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fonctionnalité de partage à venir'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Partager cette offre'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        side: BorderSide(color: AppTheme.primaryColor),
                        foregroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                      ),
                    ),
                  ),
                  
                  AppSpacing.verticalXl,
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }
  
  Widget _buildPromotionHeader(Promotion promotion) {
    return Stack(
      children: [
        // Image de fond
        CachedNetworkImage(
          imageUrl: promotion.imageUrl,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 200,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 200,
            color: Colors.grey[200],
            child: Center(
              child: Icon(
                Icons.broken_image,
                color: Colors.grey[400],
                size: 60,
              ),
            ),
          ),
        ),
        
        // Gradient de superposition pour meilleure lisibilité
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
        ),
        
        // Contenu
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge de type de promotion
              Container(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: _getPromotionColor(promotion.type),
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                ),
                child: Text(
                  promotion.type.displayName.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              AppSpacing.verticalSm,
              
              // Titre
              Text(
                promotion.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              
              AppSpacing.verticalSm,
              
              // Discount & Timer row
              Row(
                children: [
                  // Badge de réduction
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                    ),
                    child: Text(
                      "-${promotion.discountPercentage.toStringAsFixed(0)}%",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  SizedBox(width: AppSpacing.sm),
                  
                  // Compte à rebours
                  if (promotion.isLastMinute)
                    Expanded(
                      child: PromotionCountdownWidget(
                        promotion: promotion,
                        onExpired: () {
                          // Recharger la promotion quand le timer expire
                          _loadPromotionDetails();
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        
        // Bouton retour
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ],
    );
  }

  Color _getPromotionColor(PromotionType type) {
    final colorHex = type.badgeColor;
    
    // Convertir le code hexadécimal en Color
    final value = int.parse(colorHex.substring(1), radix: 16);
    return Color(value).withOpacity(1);
  }
}
