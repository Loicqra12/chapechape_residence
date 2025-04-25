import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/promotion_model.dart';
import '../../core/services/promotion_service.dart';
import '../../core/theme/app_theme.dart';
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
          const SizedBox(height: 16),
          Text(
            'Impossible de charger cette promotion',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
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
          const SizedBox(height: 16),
          Text(
            'Promotion non trouvée',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
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
              padding: const EdgeInsets.all(8),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info validité
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Offre à durée limitée',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Valable du ${DateFormat('dd/MM/yyyy').format(promotion.startDate)} au ${DateFormat('dd/MM/yyyy').format(promotion.endDate)}',
                                style: TextStyle(
                                  color: Colors.grey[800],
                                ),
                              ),
                              if (promotion.isLastMinute) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Plus que ${promotion.timeRemaining} pour en profiter !',
                                  style: const TextStyle(
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
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  const Text(
                    'À propos de cette offre',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    promotion.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Code promo
                  if (promotion.discountCode != null) ...[
                    const Text(
                      'Code promo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _copyPromoCode(promotion.discountCode!),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                promotion.discountCode!,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
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
                    const SizedBox(height: 8),
                    Text(
                      'Cliquez pour copier le code à utiliser lors de votre réservation',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Résidence associée
                  if (promotion.residence != null) ...[
                    const Text(
                      'Résidence concernée',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => context.push('/residences/${promotion.residenceId}'),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
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
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    promotion.residence!.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          promotion.residence!.location['displayAddress'] ?? 'Emplacement inconnu',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      // Prix original
                                      Text(
                                        '${NumberFormat.currency(symbol: '', decimalDigits: 0).format(promotion.residence!.price)} FCFA',
                                        style: TextStyle(
                                          decoration: TextDecoration.lineThrough,
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Prix avec réduction
                                      Text(
                                        '${NumberFormat.currency(symbol: '', decimalDigits: 0).format(promotion.calculateDiscountedPrice(promotion.residence!.price))} FCFA',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '/nuit',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
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
                    
                    const SizedBox(height: 24),
                  ],
                  
                  // Conditions
                  if (promotion.termsAndConditions != null) ...[
                    const Text(
                      'Conditions d\'utilisation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      promotion.termsAndConditions!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Bouton réserver
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _bookResidence(promotion),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Réserver maintenant',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppTheme.primaryColor),
                        foregroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPromotionColor(promotion.type),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  promotion.type.displayName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Titre
              Text(
                promotion.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Discount & Timer row
              Row(
                children: [
                  // Badge de réduction
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "-${promotion.discountPercentage.toStringAsFixed(0)}%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
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
