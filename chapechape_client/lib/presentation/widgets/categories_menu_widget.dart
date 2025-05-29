import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/residence_type_enum.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/services/category_cache_service.dart';
import '../../core/services/type_sync_service.dart';

class CategoriesMenuWidget extends StatefulWidget {
  final bool showTitle;
  final String title;
  final ResidenceType filterType;
  
  const CategoriesMenuWidget({
    super.key,
    this.showTitle = false, // Le titre est désactivé par défaut
    this.title = "Catégories",
    this.filterType = ResidenceType.other,
  });

  @override
  State<CategoriesMenuWidget> createState() => _CategoriesMenuWidgetState();
}

class _CategoriesMenuWidgetState extends State<CategoriesMenuWidget> {
  final ScrollController _scrollController = ScrollController();
  late final CategoryCacheService _categoryCacheService;
  late final TypeSyncService _typeSyncService;
  
  // Récupération des services via GetIt
  void _initServices() {
    final getIt = GetIt.instance;
    _categoryCacheService = getIt<CategoryCacheService>();
    _typeSyncService = getIt<TypeSyncService>();
  }
  
  List<CategoryData>? _categories;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initServices();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    
    try {
      final categories = await _categoryCacheService.getAllCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollLeft() {
    if (_scrollController.hasClients) {
      final double currentPosition = _scrollController.offset;
      final double newPosition = currentPosition - 240;
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
      final double newPosition = currentPosition + 240;
      _scrollController.animateTo(
        newPosition > maxPosition ? maxPosition : newPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = context.screenWidth <= 600;
    
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ... [
          Padding(
            padding: context.responsivePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(24),
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Explorez les meilleurs types de logements disponibles',
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(14),
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isMobile) ...[
                      Flexible(
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swipe,
                              color: Colors.grey,
                              size: 20,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Faites défiler',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () async {
                        await _categoryCacheService.forceRefresh();
                        _loadCategories();
                      },
                      tooltip: 'Actualiser les catégories',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        Stack(
          children: [
            if (!isMobile) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: _buildCategoryItems(context),
                ),
              ),
            ] else ...[
              Container(
                height: 260,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.white.withOpacity(0.8),
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.8),
                    ],
                    stops: const [0.0, 0.05, 0.95, 1.0],
                  ),
                ),
                child: ListView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  children: _buildCategoryItems(context),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              
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
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  List<Widget> _buildCategoryItems(BuildContext context) {
    if (_categories == null || _categories!.isEmpty) {
      return _buildDefaultCategories(context);
    }
    
    return _categories!.map((category) {
      return _buildCategoryItem(
        context: context,
        title: category.title,
        icon: _getCategoryIcon(category.type),
        type: category.type,
      );
    }).toList();
  }

  IconData _getCategoryIcon(ResidenceType type) {
    // Utiliser une icône par défaut si non disponible
    return Icons.home;
  }

  Widget _buildCategoryItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required ResidenceType type,
  }) {
    final bool isMobile = context.screenWidth <= 600;
    
    return Container(
      width: isMobile ? 100 : 120, // Réduction de la largeur pour un design plus compact
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4), // Marges réduites
      child: InkWell(
        onTap: () {
          _onCategoryTap(type);
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: AppTheme.primaryColor.withOpacity(0.1),
        highlightColor: AppTheme.primaryColor.withOpacity(0.05),
        child: Card(
          elevation: 2, // Ombre plus légère
          shadowColor: AppTheme.primaryColor.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppTheme.primaryColor.withOpacity(0.05),
              width: 0.5, // Bordure plus fine
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8), // Padding réduit
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50, // Taille de l'icône réduite
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 28, // Icône plus petite
                    color: AppTheme.primaryColor,
                  ),
                )
                .animate()
                .scaleXY(
                  duration: 700.ms,
                  curve: Curves.easeInOut,
                  begin: 1.0,
                  end: 1.05,
                )
                .then()
                .scaleXY(
                  duration: 700.ms,
                  curve: Curves.easeInOut,
                  begin: 1.05,
                  end: 1.0,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(14), // Police plus petite
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 400.ms)
    .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutQuad);
  }

  List<Widget> _buildDefaultCategories(BuildContext context) {
    return [
      _buildCategoryItem(
        context: context,
        title: 'Appartements',
        icon: Icons.apartment,
        type: ResidenceType.apartment,
      ),
      _buildCategoryItem(
        context: context,
        title: 'Villas',
        icon: Icons.villa,
        type: ResidenceType.villa,
      ),
      _buildCategoryItem(
        context: context,
        title: 'Studios',
        icon: Icons.single_bed,
        type: ResidenceType.studio,
      ),
      _buildCategoryItem(
        context: context,
        title: 'Hôtels',
        icon: Icons.hotel,
        type: ResidenceType.hotel,
      ),
      _buildCategoryItem(
        context: context,
        title: 'Résidences de vacances',
        icon: Icons.beach_access,
        type: ResidenceType.resort,
      ),
      _buildCategoryItem(
        context: context,
        title: 'Éco-lodges',
        icon: Icons.nature_people,
        type: ResidenceType.cottage,
      ),
      _buildCategoryItem(
        context: context,
        title: 'Maisons de plage',
        icon: Icons.waves,
        type: ResidenceType.bungalow,
      ),
      _buildCategoryItem(
        context: context,
        title: 'Logements étudiants',
        icon: Icons.school,
        type: ResidenceType.student,
      ),
      _buildCategoryItem(
        context: context,
        title: 'Airbnb locaux',
        icon: Icons.home,
        type: ResidenceType.guesthouse,
      ),
    ];
  }

  void _onCategoryTap(ResidenceType type) {
    // Envoyer l'événement au Bloc pour filtrer les résidences
    context.read<ResidenceBloc>().add(
      FilterResidencesByTypeEvent(widget.filterType == ResidenceType.other ? type : widget.filterType), // Utiliser le filterType si spécifié
    );
    
    // Naviguer vers la page de recherche
    final router = GoRouter.of(context);
    final currentLocation = router.routerDelegate.currentConfiguration.uri.path;
    if (!currentLocation.startsWith('/search')) {
      context.push('/search');
    }
  }
}
