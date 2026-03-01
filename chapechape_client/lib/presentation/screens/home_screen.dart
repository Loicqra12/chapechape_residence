// lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/blocs/auth/auth_bloc.dart';
import '../../core/blocs/auth/auth_state.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/text_styles.dart';
import '../../core/models/residence_type_enum.dart';
import '../../core/models/promotion_model.dart';
import '../../core/services/promotion_service.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/shared_preferences_service.dart';
import '../widgets/featured_listings.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/tendances_widget.dart';
import '../widgets/exclusive_promotions_widget.dart';
import '../screens/promotion_detail_screen.dart';
import '../widgets/que_cherchez_vous_widget.dart';
import '../widgets/around_me_widget.dart';
import '../widgets/home_compact_sections.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final LoggerService _logger = LoggerService();

  late final AnimationController _heroAnimController;
  late final Animation<double> _heroFade;

  /// Lieu pour la section Tendances (préférence ou dernier lieu connu)
  String? _tendancesCity;
  String? _tendancesCommune;
  String? _tendancesQuartier;

  @override
  void initState() {
    super.initState();
    _logger.debug('HomeScreen initialisé');
    _heroAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heroFade = CurvedAnimation(
      parent: _heroAnimController,
      curve: Curves.easeOut,
    );
    _heroAnimController.forward();
    _initializeData();
    _loadTendancesLocation();
  }

  Future<void> _loadTendancesLocation() async {
    try {
      final prefs = await SharedPreferencesService.getInstance();
      if (!mounted) return;
      setState(() {
        _tendancesCity = prefs.getString('tendances_city');
        _tendancesCommune = prefs.getString('tendances_commune');
        _tendancesQuartier = prefs.getString('tendances_quartier');
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _heroAnimController.dispose();
    _logger.debug('HomeScreen détruit - nettoyage des ressources');
    super.dispose();
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

  /// Charge les promotions actives pour décider d'afficher ou non la section.
  /// Retourne une liste vide en cas d'erreur (section masquée).
  Future<List<Promotion>> _loadPromotionsForSection() async {
    try {
      final service = await PromotionService.initialize();
      return await service.getActivePromotions();
    } catch (e) {
      _logger.warning('Promotions section: chargement échoué, section masquée ($e)');
      return [];
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: ListView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            key: const Key('home_screen_list_view'),
            children: [
              // Hero texte centré en haut (sans bannière) avec animation
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    letterSpacing: -0.3,
                  );
                  final subtitleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.35,
                  );
                  String title;
                  String subtitle;
                  if (authState is Authenticated) {
                    final name = authState.user.firstName.isNotEmpty
                        ? authState.user.firstName
                        : 'là';
                    title = 'Bonjour $name 👋';
                    subtitle = 'Vous cherchez pour quand ?';
                  } else {
                    title = 'Trouvez votre résidence idéale en Côte d\'Ivoire';
                    subtitle = 'À l\'heure, à la nuit ou au mois en fonction de votre zone';
                  }
                  return FadeTransition(
                    opacity: _heroFade,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: titleStyle,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: subtitleStyle,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              const HomeSearchBar(),
              
              const SizedBox(height: 12),
              
              const QueCherchezVousWidget(),
              
              const SizedBox(height: 12),
              
              // Section À proximité (géolocalisation) — en 4e position après l’intention de recherche
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: AroundMeWidget(
                  title: 'À proximité',
                  subtitle: 'Découvrez les résidences à proximité de votre position',
                  itemCount: 5,
                  radiusKm: 5.0,
                  showMap: true,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Section promotions : affichée uniquement s'il y a des promotions
              FutureBuilder<List<Promotion>>(
                future: _loadPromotionsForSection(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final promotions = snapshot.data!;
                  return Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.lg),
                    child: ExclusivePromotionsWidget(
                      title: 'Offres & Promotions',
                      subtitle: 'Nos meilleures offres du moment',
                      maxItems: 5,
                      exclusiveOnly: false,
                      initialPromotions: promotions,
                      onPromotionSelected: (promotion) {
                        HapticFeedback.selectionClick();
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
                },
              ),
              
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 300, maxWidth: constraints.maxWidth),
                child: TendancesWidget(
                  city: (_tendancesCity != null && _tendancesCity!.isNotEmpty) ? _tendancesCity! : 'Abidjan',
                  commune: (_tendancesCommune != null && _tendancesCommune!.isNotEmpty) ? _tendancesCommune : null,
                  quartier: (_tendancesQuartier != null && _tendancesQuartier!.isNotEmpty) ? _tendancesQuartier : null,
                  limit: 8,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Section Résidences recommandées (style Airbnb : compact, sans espace vide)
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 280, maxWidth: constraints.maxWidth),
                child: BlocSelector<ResidenceBloc, ResidenceState, Map<String, dynamic>>(
                  selector: (state) => {
                    'residences': state is ResidencesLoaded 
                        ? state.residences 
                        : (state is ResidenceError && state.preservedResidences != null)
                            ? state.preservedResidences!
                            : [],
                    'isLoading': state is ResidenceLoading || state is ResidenceRefreshing,
                  },
                  builder: (context, data) {
                    final residences = data['residences'] as List;
                    final isLoading = data['isLoading'] as bool;
                            
                    return FeaturedListings(
                      title: 'Résidences recommandées',
                      subtitle: 'Nos meilleures sélections pour vous',
                      isLoading: isLoading,
                      listings: residences,
                      onSeeAllPressed: () {
                        HapticFeedback.selectionClick();
                        context.push('/search');
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: const TopRatedSectionWidget(limit: 6),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: const RecentlyViewedSectionWidget(maxItems: 6),
              ),
            ],
          ),
        );
      },
    );
  }
}