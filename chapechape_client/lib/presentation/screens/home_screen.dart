// lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/blocs/auth/auth_bloc.dart';
import '../../core/blocs/auth/auth_state.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/blocs/residence/residence_event.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/residence_model.dart';
import '../../core/constants/app_assets.dart';
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
    context.read<ResidenceBloc>().add(const LoadResidences());
    
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
    return SingleChildScrollView(
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Text(
              'Catégories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const CategoriesMenuWidget(),
          
          // Section des résidences recommandées
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Text(
              'Résidences recommandées',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const FeaturedListings(),
          
          // Section des résidences par type
          const SizedBox(height: 24),
          ResidenceTypeWidget(
            type: ResidenceType.apartment,
            title: 'Appartements',
            description: 'Découvrez nos appartements confortables et modernes',
          ),
          
          const SizedBox(height: 24),
          ResidenceTypeWidget(
            type: ResidenceType.luxury,
            title: 'Résidences de luxe',
            description: 'Profitez d\'un séjour dans nos résidences haut de gamme',
          ),
          
          const SizedBox(height: 24),
          ResidenceTypeWidget(
            type: ResidenceType.villa,
            title: 'Villas',
            description: 'Des villas spacieuses pour des vacances inoubliables',
          ),
          
          const SizedBox(height: 24),
          ResidenceTypeWidget(
            type: ResidenceType.studio,
            title: 'Studios',
            description: 'Studios compacts et fonctionnels pour vos séjours',
          ),
          
          // Section des offres spéciales
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Text(
              'Offres spéciales',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SpecialResidencesWidget(),
          
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
          const NewListingsWidget(),
          
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
          const TestimonialsWidget(),
          
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
          const BlogAndTipsWidget(),
          
          // Pied de page
          const FooterWidget(),
        ],
      ),
    );
  }

  Widget _buildUnauthenticatedContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section de recherche et filtres
          const AdvancedSearchWidget(),
          
          // Section des catégories
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Text(
              'Catégories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const CategoriesMenuWidget(),
          
          // Section des résidences recommandées
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Text(
              'Résidences recommandées',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const FeaturedListings(),
          
          // Section des résidences par type
          const SizedBox(height: 24),
          ResidenceTypeWidget(
            type: ResidenceType.apartment,
            title: 'Appartements',
            description: 'Découvrez nos appartements confortables et modernes',
          ),
          
          const SizedBox(height: 24),
          ResidenceTypeWidget(
            type: ResidenceType.luxury,
            title: 'Résidences de luxe',
            description: 'Profitez d\'un séjour dans nos résidences haut de gamme',
          ),
          
          const SizedBox(height: 24),
          ResidenceTypeWidget(
            type: ResidenceType.villa,
            title: 'Villas',
            description: 'Des villas spacieuses pour des vacances inoubliables',
          ),
          
          const SizedBox(height: 24),
          ResidenceTypeWidget(
            type: ResidenceType.studio,
            title: 'Studios',
            description: 'Studios compacts et fonctionnels pour vos séjours',
          ),
          
          // Section des offres spéciales
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Text(
              'Offres spéciales',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SpecialResidencesWidget(),
          
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
          const NewListingsWidget(),
          
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
          const TestimonialsWidget(),
          
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
          const BlogAndTipsWidget(),
          
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
          
          // Pied de page
          const FooterWidget(),
        ],
      ),
    );
  }
}