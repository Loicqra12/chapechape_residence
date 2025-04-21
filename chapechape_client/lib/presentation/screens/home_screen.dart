// lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/blocs/auth/auth_bloc.dart';
import '../../core/blocs/auth/auth_state.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/residence_type_enum.dart';
import '../../core/constants/app_assets.dart' as assets;
import '../widgets/featured_listings.dart';
import '../widgets/categories_menu_widget.dart';
import '../widgets/advanced_search_widget.dart';
import '../widgets/testimonials_widget.dart';
import '../widgets/blog_and_tips_widget.dart';
import '../widgets/footer_widget.dart';
import '../widgets/special_residences_widget.dart';
import '../widgets/residence_type_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialiser le chargement des résidences
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ResidenceBloc>().add(const LoadResidences());
    });
    
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          return _buildAuthenticatedContent(context, state);
        } else {
          return _buildUnauthenticatedContent(context);
        }
      },
    );
  }

  Widget _buildAuthenticatedContent(BuildContext context, Authenticated state) {
    // Utiliser LayoutBuilder pour s'assurer que les contraintes sont appliquées
    return LayoutBuilder(
      builder: (context, constraints) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  // Message de bienvenue personnalisé avec largeur contrainte
              Container(
                    width: constraints.maxWidth,
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour ${state.user.firstName}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bienvenue sur ChapeChape Résidences',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Section de recherche et filtres
              const AdvancedSearchWidget(),
              
                  // Section des catégories - avec largeur contrainte
              Container(
                    width: constraints.maxWidth,
                margin: const EdgeInsets.symmetric(vertical: 16.0),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catégories',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Explorez nos différents types d\'hébergements',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
                  
                  // Widgets avec hauteur fixe pour éviter les contraintes indéfinies
                  SizedBox(
                    height: 250,
                    width: constraints.maxWidth,
                    child: const CategoriesMenuWidget(
                      title: "Explorez par catégories",
                      filterType: ResidenceType.other,
                    ),
                  ),
                  
                  // Sections de résidences avec largeur contrainte
              Container(
                    width: constraints.maxWidth,
                margin: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Offres spéciales',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Résidences avec piscines et aménités exclusives',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
                  
                  // Widgets avec hauteur fixe et largeur contrainte
                  SizedBox(
                    height: 370,
                    width: constraints.maxWidth,
                    child: const SpecialResidencesWidget(
                      title: "Résidences Spéciales",
                      filterType: ResidenceType.luxury,
                    ),
                  ),
                  
                  // Le reste du contenu avec le même pattern...
              Container(
                    width: constraints.maxWidth,
                margin: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Résidences recommandées',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Nos meilleures sélections pour vous',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
                  
                  SizedBox(
                    height: 370,
                    width: constraints.maxWidth,
                    child: const FeaturedListings(),
                  ),
                  
                  // Utiliser des widgets adaptés pour le reste des sections
                  // ...
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildUnauthenticatedContent(BuildContext context) {
    // Utiliser LayoutBuilder pour s'assurer que les contraintes sont appliquées
    return LayoutBuilder(
      builder: (context, constraints) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  // Bannière d'accueil principale
              Container(
                    width: constraints.maxWidth,
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Trouvez votre résidence idéale',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                          textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Studios, appartements, villas et plus encore',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                          textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Section de recherche et filtres
              const AdvancedSearchWidget(),
              
              // Section des catégories
              Container(
                    width: constraints.maxWidth,
                margin: const EdgeInsets.symmetric(vertical: 16.0),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        Text(
                      'Catégories',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                        SizedBox(height: 4),
                        Text(
                      'Explorez nos différents types d\'hébergements',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
                  
                  // Widgets des catégories
                  SizedBox(
                    height: 250,
                    width: constraints.maxWidth,
                    child: const CategoriesMenuWidget(
                      title: "Explorez par catégories",
                      filterType: ResidenceType.other,
                    ),
                  ),
              
              // Section des offres spéciales
              Container(
                    width: constraints.maxWidth,
                margin: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                          'Offres spéciales',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                          'Résidences avec piscines et aménités exclusives',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
                  // Widget des résidences spéciales
                  SizedBox(
                    height: 370,
                    width: constraints.maxWidth,
                    child: const SpecialResidencesWidget(
                      title: "Résidences Spéciales",
                      filterType: ResidenceType.luxury,
                    ),
                  ),
                  
                  // Section des résidences recommandées
              Container(
                    width: constraints.maxWidth,
                margin: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                          'Résidences recommandées',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                          'Nos meilleures sélections pour vous',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
                  
                  // Widget des résidences en vedette
                  SizedBox(
                    height: 370,
                    width: constraints.maxWidth,
                    child: const FeaturedListings(),
                  ),
                  
                  // Sections des types de résidences
                  _buildResidenceTypeSection(context, assets.ResidenceType.apartment, 'Appartements', 'Confort et praticité au cœur de la ville'),
                  _buildResidenceTypeSection(context, assets.ResidenceType.villa, 'Villas', 'Élégance et espace pour toute la famille'),
                  _buildResidenceTypeSection(context, assets.ResidenceType.studio, 'Studios', 'Parfaits pour les séjours individuels'),
                  _buildResidenceTypeSection(context, assets.ResidenceType.luxury, 'Résidences de luxe', 'Pour une expérience premium'),
                  
                  // Sections témoignages, blog et autres...
                  const SizedBox(height: 32),
                  const TestimonialsWidget(),
                  const SizedBox(height: 32),
                  const BlogAndTipsWidget(),
                  const SizedBox(height: 32),
                  const FooterWidget(),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  // Helper widget pour les sections de type de résidence
  Widget _buildResidenceTypeSection(BuildContext context, assets.ResidenceType type, String title, String subtitle) {
    return Container(
      width: MediaQuery.of(context).size.width,
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
                    const SizedBox(height: 16),
          SizedBox(
            height: 230,
            child: ResidenceTypeWidget(
              type: type,
              title: getTitleForType(type),
              description: getDescriptionForType(type),
                      ),
                    ),
                  ],
      ),
    );
  }

  String getTitleForType(assets.ResidenceType type) {
    switch (type) {
      case assets.ResidenceType.apartment:
        return 'Appartement';
      case assets.ResidenceType.luxury:
        return 'Résidence de luxe';
      case assets.ResidenceType.villa:
        return 'Villa';
      case assets.ResidenceType.studio:
        return 'Studio';
      default:
        return 'Logement';
    }
  }

  String getDescriptionForType(assets.ResidenceType type) {
    switch (type) {
      case assets.ResidenceType.apartment:
        return 'Appartements confortables pour tous vos besoins';
      case assets.ResidenceType.luxury:
        return 'Résidences haut de gamme avec services premium';
      case assets.ResidenceType.villa:
        return 'Villas spacieuses avec jardin privé';
      case assets.ResidenceType.studio:
        return 'Studios compacts et fonctionnels';
      default:
        return 'Logements adaptés à tous les besoins';
    }
  }
}