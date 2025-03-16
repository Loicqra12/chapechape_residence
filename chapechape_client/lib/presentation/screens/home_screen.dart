// lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/blocs/auth/auth_bloc.dart';
import '../../core/blocs/auth/auth_state.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/blocs/residence/residence_event.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/residence_model.dart' as model;
import '../../core/constants/app_assets.dart' as assets;
import '../widgets/featured_listings.dart';
import '../widgets/new_listings_widget.dart';
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message de bienvenue personnalisé
              Container(
                width: double.infinity,
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
              
              // Section des catégories
              Container(
                width: double.infinity,
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
              const SizedBox(
                height: 250, // Augmentation de la hauteur pour afficher toutes les options
                child: CategoriesMenuWidget(),
              ),
              
              // Section des offres spéciales
              Container(
                width: double.infinity,
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
              const SizedBox(
                height: 370, // Mise à jour à 370px pour cohérence
                child: SpecialResidencesWidget(),
              ),
              
              // Section des résidences recommandées
              Container(
                width: double.infinity,
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
              const SizedBox(
                height: 370, // Mise à jour à 370px pour cohérence
                child: FeaturedListings(),
              ),
              
              // Section des résidences par type
              _buildResidenceTypeSection(context, assets.ResidenceType.apartment, 'Appartements', 'Découvrez nos appartements confortables et modernes'),
              _buildResidenceTypeSection(context, assets.ResidenceType.luxury, 'Résidences de luxe', 'Profitez d\'un séjour dans nos résidences haut de gamme'),
              _buildResidenceTypeSection(context, assets.ResidenceType.villa, 'Villas', 'Des villas spacieuses pour des vacances inoubliables'),
              _buildResidenceTypeSection(context, assets.ResidenceType.studio, 'Studios', 'Studios compacts et fonctionnels pour vos séjours'),
              
              // Section des nouvelles résidences
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Text(
                  'Nouvelles résidences',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(
                height: 370, // Mise à jour à 370px pour cohérence
                child: NewListingsWidget(),
              ),
              
              // Section des témoignages
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Text(
                  'Ce que disent nos clients',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(
                height: 250, // Hauteur fixe
                child: TestimonialsWidget(),
              ),
              
              // Section blog et conseils
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Text(
                  'Blog et conseils',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(
                height: 250, // Hauteur fixe
                child: BlogAndTipsWidget(),
              ),
              
              // Footer
              const SizedBox(height: 32),
              const FooterWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResidenceTypeSection(BuildContext context, assets.ResidenceType type, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 370,
            child: ResidenceTypeWidget(
              type: type,
              title: title,
              description: description,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthenticatedContent(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec titre principal
              Container(
                width: double.infinity,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trouvez votre résidence idéale',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Studios, appartements, villas et plus encore',
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
              
              // Section des catégories
              Container(
                width: double.infinity,
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
              const SizedBox(
                height: 250, // Augmentation de la hauteur pour afficher toutes les options
                child: CategoriesMenuWidget(),
              ),
              
              // Section des offres spéciales
              Container(
                width: double.infinity,
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
              const SizedBox(
                height: 370, // Mise à jour à 370px pour cohérence
                child: SpecialResidencesWidget(),
              ),
              
              // Section des résidences recommandées
              Container(
                width: double.infinity,
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
              const SizedBox(
                height: 370, // Mise à jour à 370px pour cohérence
                child: FeaturedListings(),
              ),
              
              // Section par types de résidences
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explorer par type',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Trouvez la résidence qui vous correspond',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Types de résidences
              _buildResidenceTypeSection(context, assets.ResidenceType.apartment, 'Appartements', 'Découvrez nos appartements confortables et modernes'),
              _buildResidenceTypeSection(context, assets.ResidenceType.luxury, 'Résidences de luxe', 'Profitez d\'un séjour dans nos résidences haut de gamme'),
              _buildResidenceTypeSection(context, assets.ResidenceType.villa, 'Villas', 'Des villas spacieuses pour des vacances inoubliables'),
              _buildResidenceTypeSection(context, assets.ResidenceType.studio, 'Studios', 'Studios compacts et fonctionnels pour vos séjours'),
              
              // Section des nouvelles résidences
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nouvelles résidences',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ajoutées récemment à notre catalogue',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 370, // Mise à jour à 370px pour cohérence
                child: NewListingsWidget(),
              ),
              
              // Section des témoignages
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 32.0, bottom: 8.0),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ce que disent nos clients',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Témoignages de clients satisfaits',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 370, // Augmenté de 250 à 370
                child: TestimonialsWidget(
                  showTitle: false, // Ne pas afficher le titre dans le widget
                ),
              ),
              
              // Bannière d'inscription
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(24.0),
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
                  children: [
                    const Text(
                      'Rejoignez ChapeChape Résidences',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Créez un compte pour accéder à toutes nos fonctionnalités et bénéficier d\'offres exclusives.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'S\'inscrire gratuitement',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Footer
              const FooterWidget(),
            ],
          ),
        ),
      ),
    );
  }
}