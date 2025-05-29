// lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/blocs/auth/auth_bloc.dart';
import '../../core/blocs/auth/auth_state.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/residence_type_enum.dart';
import '../../core/constants/app_assets.dart' as assets;
import '../../core/services/promotion_service.dart';
import '../../core/services/logger_service.dart';
import '../widgets/featured_listings.dart';
import '../widgets/categories_menu_widget.dart';
import '../widgets/advanced_search_widget.dart';
import '../widgets/testimonials_widget.dart';
import '../widgets/blog_and_tips_widget.dart';
import '../widgets/footer_widget.dart';
import '../widgets/special_residences_widget.dart';
import '../widgets/residence_type_widget.dart';
import '../widgets/exclusive_promotions_widget.dart';
import '../screens/promotion_detail_screen.dart';
import '../widgets/home_banner_carousel.dart';
import '../widgets/popular_categories_widget.dart';
import '../widgets/around_me_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Service de journalisation pour les logs structurés
  final LoggerService _logger = LoggerService();
  
  @override
  void initState() {
    super.initState();
    // Initialiser le chargement des données dès la création du widget
    _initializeData();
  }
  
  // Méthode pour initialiser les données de manière ordonnée
  Future<void> _initializeData() async {
    _logger.info('🚀 HomeScreen - Initialisation du chargement des données');
    
    // Déclencher le chargement des résidences de manière non-bloquante
    // sans attendre le rendu initial, évitant ainsi le double rendu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Utiliser un bloc au lieu d'un événement direct pour éviter les problèmes de timing
      final bloc = context.read<ResidenceBloc>();
      if (bloc.state is! ResidencesLoaded) {
        _logger.info('🏠 Chargement initial des résidences');
        bloc.add(const RefreshResidencesEvent());
      }
    });
    
    // Pré-initialiser les autres services en parallèle
    try {
      await PromotionService.initialize();
      _logger.info('✅ Service de promotions initialisé');
    } catch (e) {
      _logger.error('⚠️ Erreur lors de l\'initialisation du service de promotions', e, StackTrace.current);
      // Continuer même en cas d'erreur pour ne pas bloquer l'UI
    }
  }
  
  @override
  Widget build(BuildContext context) {
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: SafeArea(
            child: ListView(
              key: const Key('home_screen_list_view'),
              physics: const ClampingScrollPhysics(),
              children: [
                // Bannière d'accueil avec carousel dynamique
                HomeBannerCarousel(constraints: constraints),
                
                // Section de recherche (commune à tous)
                const AdvancedSearchWidget(),
                
                // Section des catégories (commune à tous)
                _buildSectionHeader(
                  constraints, 
                  'Catégories', 
                  'Explorez nos différents types d\'hébergements'
                ),
                
                // Nouveau widget de catégories populaires avec animations
                const PopularCategoriesWidget(
                  title: 'Catégories populaires',
                  subtitle: 'Découvrez nos types d\'hébergements les plus demandés',
                  itemsPerRow: 2,
                  viewStyle: 'grid',
                ),
                
                const SizedBox(height: 24),
                
                // Widget de catégories existant (modes d'affichage alternatifs)
                SizedBox(
                  height: 280,
                  width: constraints.maxWidth,
                  child: CategoriesMenuWidget(
                    title: "Explorez par catégories",
                    filterType: ResidenceType.other,
                  ),
                ),
                
                // Section des offres spéciales (commune à tous)
                _buildSectionHeader(
                  constraints, 
                  'Offres spéciales', 
                  'Résidences avec piscines et aménités exclusives'
                ),
                
                // Widget des promotions exclusives
                FutureBuilder<PromotionService>(
                  future: PromotionService.initialize(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: ExclusivePromotionsWidget(
                          title: 'Offres & Promotions',
                          subtitle: 'Nos meilleures offres du moment',
                          maxItems: 5,
                          exclusiveOnly: false,
                          onPromotionSelected: (promotion) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PromotionDetailScreen(
                                  promotionId: promotion.id,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }
                    return const SizedBox(height: 20);
                  },
                ),
                
                SizedBox(
                  // Augmenter la hauteur pour éviter le débordement
                  height: 450,
                  width: constraints.maxWidth,
                  child: BlocBuilder<ResidenceBloc, ResidenceState>(
                    builder: (context, state) {
                      // Utiliser les résidences chargées ou préservées en cas d'erreur
                      final residences = state is ResidencesLoaded 
                          ? state.residences 
                          : (state is ResidenceError && state.preservedResidences != null)
                              ? state.preservedResidences!
                              : [];
                              
                      return SpecialResidencesWidget(
                        title: "Résidences Spéciales",
                        filterType: ResidenceType.luxury,
                        isLoading: state is ResidenceLoading || state is ResidenceRefreshing,
                        items: residences,
                      );
                    },
                  ),
                ),
                
                // Section Autour de moi (géolocalisation)
                _buildSectionHeader(
                  constraints, 
                  'Autour de moi', 
                  'Découvrez les résidences à proximité de votre position'
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: AroundMeWidget(
                    title: 'À proximité',
                    subtitle: 'Explorez les quartiers autour de vous',
                    itemCount: 5,
                    radiusKm: 5.0,
                    showMap: true,
                  ),
                ),
                
                // Section des résidences recommandées (commune à tous)
                _buildSectionHeader(
                  constraints, 
                  'Résidences recommandées', 
                  'Nos meilleures sélections pour vous'
                ),
                
                SizedBox(
                  // Augmenter la hauteur pour éviter le débordement
                  height: 420,
                  width: constraints.maxWidth,
                  child: BlocBuilder<ResidenceBloc, ResidenceState>(
                    builder: (context, state) {
                      // Utiliser les résidences chargées ou préservées en cas d'erreur
                      final residences = state is ResidencesLoaded 
                          ? state.residences 
                          : (state is ResidenceError && state.preservedResidences != null)
                              ? state.preservedResidences!
                              : [];
                              
                      return FeaturedListings(
                        isLoading: state is ResidenceLoading || state is ResidenceRefreshing,
                        listings: residences,
                        onSeeAllPressed: () {
                          context.push('/search');
                        },
                      );
                    },
                  ),
                ),
                
                // Section pour encourager l'inscription (uniquement pour les non-connectés)
                _buildSignUpPrompt(context, constraints),
                
                // Témoignages clients (commun à tous)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: TestimonialsWidget(),
                ),
                
                // Section blog et conseils (commune à tous)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: BlogAndTipsWidget(),
                ),
                
                // Footer (commun à tous)
                FooterWidget(),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget d'en-tête de section réutilisable
  Widget _buildSectionHeader(BoxConstraints constraints, String title, String subtitle) {
    return Container(
      width: constraints.maxWidth,
      margin: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  // Section d'incitation à l'inscription (visible uniquement pour les non-connectés)
  Widget _buildSignUpPrompt(BuildContext context, BoxConstraints constraints) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Ne montrer que pour les utilisateurs non connectés
        if (state is Authenticated) {
          return const SizedBox.shrink();
        }
        
        return Container(
          width: constraints.maxWidth,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              const Text(
                'Rejoignez ChapeChape Résidences',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Créez un compte pour accéder à des fonctionnalités exclusives, enregistrer vos favoris et recevoir des offres personnalisées.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: 140,
                    child: ElevatedButton(
                      onPressed: () => context.push('/register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('S\'inscrire'),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: TextButton(
                      onPressed: () => context.push('/login'),
                      child: const Text('Se connecter'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}