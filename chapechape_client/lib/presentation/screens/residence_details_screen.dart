import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/blocs/auth/auth_bloc.dart';
import '../../core/blocs/auth/auth_state.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../screens/booking_screen.dart';
import '../../core/blocs/booking/booking_bloc.dart';
import '../../core/services/booking_service.dart';

class ResidenceDetailsScreen extends StatefulWidget {
  final String residenceId;
  
  const ResidenceDetailsScreen({super.key, required this.residenceId});

  @override
  State<ResidenceDetailsScreen> createState() => _ResidenceDetailsScreenState();
}

class _ResidenceDetailsScreenState extends State<ResidenceDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Contrôleur pour le carrousel d'images
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  
  // Pour gestion des onglets
  int _currentTabIndex = 0;
  
  // Image par défaut quand aucune image n'est disponible
  final String defaultImage = 'assets/images/residences/apartments/304661255.jpg';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    
    // Charger les détails de la résidence
    context.read<ResidenceBloc>().add(LoadResidenceDetails(residenceId: widget.residenceId));
  }
  
  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Restaurer l'état précédent avant de revenir en arrière
        context.read<ResidenceBloc>().add(const RefreshResidencesEvent());
        return true;
      },
      child: Scaffold(
        body: BlocBuilder<ResidenceBloc, ResidenceState>(
          builder: (context, state) {
            if (state is ResidenceLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ResidenceDetailsLoaded) {
              final residence = state.residence;
              
              return CustomScrollView(
                slivers: [
                  // AppBar avec carrousel d'images en arrière-plan
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    flexibleSpace: Stack(
                      children: [
                        // Carrousel d'images avec style Booking.com
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () {
                              // Ouvrir la galerie en plein écran
                              _openGallery(context, residence.images, _currentImageIndex);
                            },
                            child: Stack(
                              children: [
                                // Image principale (occupe tout l'espace disponible)
                                residence.images.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: residence.images[_currentImageIndex],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        placeholder: (context, url) => Container(
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => Image.asset(
                                          defaultImage,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Image.asset(
                                        defaultImage,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                
                                // Grille des miniatures (en bas à droite)
                                if (residence.images.length > 1)
                                  Positioned(
                                    bottom: 20,
                                    right: 20,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: Text(
                                        "+${residence.images.length - 1}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                // Navigation gauche/droite pour les images
                                if (residence.images.length > 1)
                                  Positioned.fill(
                                    child: Row(
                                      children: [
                                        // Bouton précédent
                                        GestureDetector(
                                          onTap: () {
                                            if (_currentImageIndex > 0) {
                                              _pageController.previousPage(
                                                duration: const Duration(milliseconds: 300),
                                                curve: Curves.easeInOut,
                                              );
                                            }
                                          },
                                          child: Container(
                                            width: 60,
                                            color: Colors.transparent,
                                            alignment: Alignment.center,
                                            child: _currentImageIndex > 0
                                                ? Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.black26,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    padding: const EdgeInsets.all(8),
                                                    child: const Icon(
                                                      Icons.arrow_back_ios,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                  )
                                                : const SizedBox.shrink(),
                                          ),
                                        ),
                                        
                                        // Espace au milieu
                                        Expanded(child: Container()),
                                        
                                        // Bouton suivant
                                        GestureDetector(
                                          onTap: () {
                                            if (_currentImageIndex < residence.images.length - 1) {
                                              _pageController.nextPage(
                                                duration: const Duration(milliseconds: 300),
                                                curve: Curves.easeInOut,
                                              );
                                            }
                                          },
                                          child: Container(
                                            width: 60,
                                            color: Colors.transparent,
                                            alignment: Alignment.center,
                                            child: _currentImageIndex < residence.images.length - 1
                                                ? Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.black26,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    padding: const EdgeInsets.all(8),
                                                    child: const Icon(
                                                      Icons.arrow_forward_ios,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                  )
                                                : const SizedBox.shrink(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Indicateur de nombre d'images
                        if (residence.images.length > 1)
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: SmoothPageIndicator(
                                    controller: _pageController,
                                    count: residence.images.length,
                                    effect: const ExpandingDotsEffect(
                                      spacing: 8.0,
                                      radius: 4.0,
                                      dotWidth: 8.0,
                                      dotHeight: 8.0,
                                      dotColor: Colors.white54,
                                      activeDotColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                        // Superposition semi-transparente pour améliorer la visibilité des boutons
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 100,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        color: Colors.black,
                        onPressed: () {
                          context.read<ResidenceBloc>().add(const RefreshResidencesEvent());
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    actions: [
                      // Bouton de favoris (nécessite authentification)
                      BlocBuilder<AuthBloc, dynamic>(
                        builder: (context, authState) {
                          // Vérification simple d'authentification basée sur la méthode existante
                          final bool isUserAuthenticated = _isUserAuthenticated(context);
                          return Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                residence.isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: residence.isFavorite ? Colors.red : Colors.black,
                              ),
                              onPressed: () {
                                if (isUserAuthenticated) {
                                  context.read<ResidenceBloc>().add(
                                    ToggleFavorite(
                                      residenceId: residence.id,
                                    ),
                                  );
                                } else {
                                  _showAuthDialog(context);
                                }
                              },
                            ),
                          );
                        },
                      ),
                      // Bouton de partage
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.share),
                          color: Colors.black,
                          onPressed: () {
                            // Logique de partage
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  // Contenu principal
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // En-tête amélioré avec nom, note et prix
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Titre et notation
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      residence.name,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    // Notation avec étoiles
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          RatingBarIndicator(
                                            rating: residence.rating,
                                            itemBuilder: (context, index) => const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                            ),
                                            itemCount: 5,
                                            itemSize: 16.0,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "(${residence.reviewCount} avis)",
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Prix avec format et période
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _formatCurrency(residence.price, currency: residence.currency),
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      // Période de prix
                                      Text(
                                        _formatPeriod(residence.pricePeriod),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  // Si un prix avec remise existe
                                  if (residence.hasDiscount)
                                    Row(
                                      children: [
                                        Text(
                                          residence.formattedDiscountPrice,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          residence.formattedPrice,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            decoration: TextDecoration.lineThrough,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                  // Badge de remise
                                  if (residence.hasDiscount)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        residence.discountBadge,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          
                          // Adresse avec icône
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    residence.location['displayAddress'] ?? residence.address,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Caractéristiques principales dans une carte
                          const SizedBox(height: 16),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildEnhancedFeatureItem(
                                    context,
                                    icon: Icons.king_bed_outlined,
                                    value: residence.bedrooms.toString(),
                                    label: 'Chambre${residence.bedrooms > 1 ? "s" : ""}',
                                  ),
                                  _buildVerticalDivider(),
                                  _buildEnhancedFeatureItem(
                                    context,
                                    icon: Icons.bathroom_outlined,
                                    value: residence.bathrooms.toString(),
                                    label: 'Sdb',
                                  ),
                                  _buildVerticalDivider(),
                                  _buildEnhancedFeatureItem(
                                    context,
                                    icon: Icons.person_outline,
                                    value: residence.maxOccupancy.toString(),
                                    label: 'Pers.',
                                  ),
                                  _buildVerticalDivider(),
                                  _buildEnhancedFeatureItem(
                                    context,
                                    icon: Icons.straighten_outlined,
                                    value: residence.surface.toString(),
                                    label: 'm²',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Statut de disponibilité
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: residence.isAvailable ? Colors.green[100] : Colors.red[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      residence.isAvailable ? Icons.check_circle : Icons.cancel,
                                      size: 16,
                                      color: residence.isAvailable ? Colors.green[800] : Colors.red[800],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      residence.isAvailable ? 'Disponible' : 'Non disponible',
                                      style: TextStyle(
                                        color: residence.isAvailable ? Colors.green[800] : Colors.red[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          // Description avec option "Voir plus"
                          const SizedBox(height: 24),
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ExpandableText(
                            residence.description,
                            expandText: 'Voir plus',
                            collapseText: 'Voir moins',
                            maxLines: 4,
                            linkColor: Theme.of(context).primaryColor,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          
                          // Grille d'équipements avec icônes
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Équipements',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(
                                width: 100, // Largeur fixe pour éviter les contraintes infinies
                                child: TextButton(
                                  onPressed: () {
                                    // Ouvrir une page ou modal avec tous les équipements
                                  },
                                  child: const Text('Voir tous'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildSimpleAmenitiesGrid(residence.amenities),
                           
                           // Utilisation de if-else dans une liste de widgets pour un affichage conditionnel
                           
                           // Équipements améliorés
                           if (residence.priceDetails != null && 
                               residence.priceDetails!.containsKey('enhancedAmenities') &&
                               residence.priceDetails!['enhancedAmenities'] is Map<String, dynamic>)
                             _buildEnhancedAmenitiesSection(residence.priceDetails!['enhancedAmenities']),
                           
                           // Classification par étoiles
                           if (residence.priceDetails != null && 
                               residence.priceDetails!.containsKey('stars') &&
                               residence.priceDetails!['stars'] is int)
                             Padding(
                               padding: const EdgeInsets.only(top: 8.0),
                               child: _buildStarsRating(residence.priceDetails!['stars']),
                             ),
                           
                           // FAQ
                           if (residence.priceDetails != null && 
                               residence.priceDetails!.containsKey('faqs') &&
                               residence.priceDetails!['faqs'] is List)
                             _buildFaqsSection(
                               (residence.priceDetails!['faqs'] as List)
                                   .map((e) => e as Map<String, dynamic>)
                                   .toList(),
                             ),
                           
                           // Méthodes de paiement
                           if (residence.priceDetails != null && 
                               residence.priceDetails!.containsKey('paymentMethods') &&
                               residence.priceDetails!['paymentMethods'] is List)
                             _buildPaymentMethodsSection(
                               (residence.priceDetails!['paymentMethods'] as List)
                                   .map((e) => e as String)
                                   .toList(),
                             ),
                          
                          // Points d'intérêt à proximité
                          if (residence.nearbyAttractions != null && residence.nearbyAttractions!.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  child: Text(
                                    'Points d\'intérêt à proximité',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 120,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: residence.nearbyAttractions!.length,
                                    itemBuilder: (context, index) {
                                      final attraction = residence.nearbyAttractions![index];
                                      
                                      // Mappings d'icônes pour les types d'attractions courants
                                      final Map<String, IconData> attractionIcons = {
                                        'restaurant': Icons.restaurant,
                                        'café': Icons.coffee,
                                        'bar': Icons.local_bar,
                                        'marché': Icons.shopping_cart,
                                        'boutique': Icons.shopping_bag,
                                        'pharmacie': Icons.local_pharmacy,
                                        'hôpital': Icons.local_hospital,
                                        'école': Icons.school,
                                        'université': Icons.school,
                                        'banque': Icons.account_balance,
                                        'bureau de poste': Icons.local_post_office,
                                        'mosquée': Icons.mosque,
                                        'église': Icons.church,
                                        'parc': Icons.park,
                                        'plage': Icons.beach_access,
                                        'gare': Icons.train,
                                        'arrêt de bus': Icons.directions_bus,
                                        'station-service': Icons.local_gas_station,
                                      };
                                      
                                      // Détecter le type d'attraction
                                      IconData attractionIcon = Icons.place;
                                      for (final entry in attractionIcons.entries) {
                                        if (attraction.toLowerCase().contains(entry.key.toLowerCase())) {
                                          attractionIcon = entry.value;
                                          break;
                                        }
                                      }
                                      
                                      return Card(
                                        elevation: 2,
                                        margin: const EdgeInsets.only(right: 12, bottom: 4),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Container(
                                          width: 200,
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                attractionIcon,
                                                color: Colors.blue[700],
                                                size: 32,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                attraction,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          
                          // Règles
                          if (residence.rules != null && residence.rules!.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 32),
                                const Text(
                                  'Règles de la résidence',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: residence.rules!.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.check_circle_outline,
                                            color: Colors.green,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              residence.rules![index],
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          
                          // Section des commentaires
                          const SizedBox(height: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Commentaires et avis',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Zone d'ajout de commentaire
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.blue[100],
                                          child: Icon(
                                            Icons.person,
                                            color: Colors.blue[700],
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextButton(
                                            onPressed: () => _showAuthDialog(context),
                                            child: const Text(
                                              'Connectez-vous pour laisser un commentaire',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Commentaires existants (exemples)
                              const SizedBox(height: 16),
                              _buildExampleComment(
                                name: 'Marie S.',
                                date: 'Il y a 2 semaines',
                                rating: 4.5,
                                comment: 'Très belle résidence, propre et bien située. Le personnel est accueillant et serviable.',
                              ),
                              _buildExampleComment(
                                name: 'Jean D.',
                                date: 'Il y a 1 mois',
                                rating: 5.0,
                                comment: 'Excellent rapport qualité-prix. J\'ai particulièrement apprécié la qualité de la connexion internet et la propreté des lieux.',
                              ),
                            ],
                          ),
                          
                          // Séparateur avant bouton de réservation
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            } else if (state is ResidenceError) {
              return Center(child: Text('Erreur: ${state.message}'));
            } else {
              return const Center(child: Text('Aucune donnée disponible'));
            }
          },
        ),
        // Bouton de réservation flottant
        floatingActionButton: BlocBuilder<ResidenceBloc, ResidenceState>(
          builder: (context, state) {
            if (state is ResidenceDetailsLoaded) {
              return BlocBuilder<AuthBloc, dynamic>(
                builder: (context, authState) {
                  final bool isAuthenticated = _isUserAuthenticated(context);
                  return FloatingActionButton.extended(
                    onPressed: state.residence.id.isEmpty 
                      ? null // Désactiver le bouton si l'ID est vide
                      : () async {
                          if (isAuthenticated) {
                            // Déboguer l'ID de résidence
                            debugPrint('ID de résidence pour réservation: ${state.residence.id}');
                            if (state.residence.id.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Erreur: ID de résidence manquant. Cette résidence ne peut pas être réservée.'),
                                  duration: Duration(seconds: 5),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            // Initialiser le BookingService avant de créer le BookingBloc
                            final bookingService = await BookingService.initialize();
                            
                            // Utiliser BlocProvider pour fournir le BookingBloc à l'écran de réservation
                            if (!mounted) return; // Vérifier si le widget est toujours monté
                            
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => MultiBlocProvider(
                                  providers: [
                                    BlocProvider<BookingBloc>(
                                      create: (context) => BookingBloc(
                                        bookingService: bookingService,
                                      ),
                                    ),
                                    // Réutiliser le ResidenceBloc existant
                                    BlocProvider.value(
                                      value: context.read<ResidenceBloc>(),
                                    ),
                                  ],
                                  child: BookingScreen(
                                    residenceId: state.residence.id,
                                  ),
                                ),
                              ),
                            );
                          } else {
                            // Afficher la boîte de dialogue d'authentification
                            _showAuthDialog(context);
                          }
                        },
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    label: Text(
                      isAuthenticated ? 'Réserver maintenant' : 'Se connecter pour réserver',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.calendar_today),
                  );
                },
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  bool _isUserAuthenticated(BuildContext context) {
    try {
      final authBloc = context.read<AuthBloc>();
      return authBloc.state is Authenticated;
    } catch (e) {
      return false;
    }
  }

  Widget _buildEnhancedFeatureItem(BuildContext context, {required IconData icon, required String value, required String label}) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return const VerticalDivider(
      thickness: 1,
      color: Colors.grey,
    );
  }

  String _formatCurrency(double price, {String? currency}) {
    final NumberFormat formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: currency ?? 'FCFA',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  String _formatPeriod(String period) {
    switch (period) {
      case 'hour':
        return '/heure';
      case 'day':
        return '/jour';
      case 'night':
        return '/nuit';
      case 'week':
        return '/semaine';
      case 'month':
        return '/mois';
      default:
        return '';
    }
  }

  void _showAuthDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connexion requise'),
        content: const Text(
          'Vous devez être connecté pour réserver cette résidence ou l\'ajouter à vos favoris.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.black,
            ),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleAmenitiesGrid(List<String> amenities) {
    // Mappings des icônes pour les équipements courants
    final Map<String, IconData> amenityIcons = {
      'wifi': Icons.wifi,
      'tv': Icons.tv,
      'air_conditioning': Icons.ac_unit,
      'climatisation': Icons.ac_unit,
      'heating': Icons.hot_tub,
      'chauffage': Icons.hot_tub,
      'kitchen': Icons.restaurant,
      'cuisine': Icons.restaurant,
      'pool': Icons.pool,
      'piscine': Icons.pool,
      'hot_tub': Icons.hot_tub,
      'jacuzzi': Icons.hot_tub,
      'parking': Icons.local_parking,
      'balcony': Icons.deck,
      'balcon': Icons.deck,
      'terrace': Icons.deck,
      'terrasse': Icons.deck,
      'garden': Icons.yard,
      'jardin': Icons.yard,
      'gym': Icons.fitness_center,
      'security': Icons.security,
      'sécurité': Icons.security,
      'running_water': Icons.water_drop,
      'water_tank': Icons.water,
      'electricity': Icons.bolt,
      'generator': Icons.power,
      'solar_energy': Icons.solar_power,
      'inverter': Icons.electrical_services,
      'fiber_optic': Icons.wifi_tethering,
      'ethernet': Icons.lan,
      'security_guard': Icons.security,
      'cctv': Icons.videocam,
      'alarm_system': Icons.alarm,
    };

    // Mappings des traductions pour les équipements techniques
    final Map<String, String> amenityLabels = {
      'wifi': 'WiFi',
      'tv': 'Télévision',
      'air_conditioning': 'Climatisation',
      'heating': 'Chauffage',
      'kitchen': 'Cuisine',
      'pool': 'Piscine',
      'hot_tub': 'Jacuzzi',
      'parking': 'Parking',
      'balcony': 'Balcon',
      'terrace': 'Terrasse',
      'garden': 'Jardin',
      'gym': 'Salle de sport',
      'security': 'Sécurité',
      'running_water': 'Eau courante',
      'water_tank': 'Réservoir d\'eau',
      'electricity': 'Électricité',
      'generator': 'Générateur',
      'solar_energy': 'Énergie solaire',
      'inverter': 'Onduleur',
      'fiber_optic': 'Fibre optique',
      'ethernet': 'Ethernet',
      'security_guard': 'Gardien',
      'cctv': 'Caméras',
      'alarm_system': 'Système d\'alarme',
    };

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: amenities.length,
      itemBuilder: (context, index) {
        final amenity = amenities[index].toLowerCase();
        
        // Utiliser l'étiquette traduite si disponible, sinon utiliser le texte original
        final displayText = amenityLabels[amenity] ?? amenities[index];
        
        return Column(
          children: [
            Icon(
              amenityIcons[amenity] ?? Icons.check_circle_outline,
              color: Colors.blueAccent,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              displayText,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }

  // Nouveau widget pour afficher les FAQ
  Widget _buildFaqsSection(List<Map<String, dynamic>> faqs) {
    if (faqs.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Questions fréquentes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: faqs.length,
          itemBuilder: (context, index) {
            final faq = faqs[index];
            return ExpansionTile(
              title: Text(
                faq['question'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    faq['answer'],
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // Nouveau widget pour afficher les méthodes de paiement
  Widget _buildPaymentMethodsSection(List<String> paymentMethods) {
    if (paymentMethods.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final Map<String, IconData> paymentIcons = {
      'cash': Icons.money,
      'wave': Icons.wallet,
      'orange_money': Icons.account_balance_wallet,
      'moov_money': Icons.account_balance_wallet,
      'mtn_money': Icons.account_balance_wallet,
      'credit_card': Icons.credit_card,
      'bank_transfer': Icons.account_balance,
    };
    
    final Map<String, String> paymentLabels = {
      'cash': 'Espèces',
      'wave': 'Wave',
      'orange_money': 'Orange Money',
      'moov_money': 'Moov Money',
      'mtn_money': 'MTN Money',
      'credit_card': 'Carte bancaire',
      'bank_transfer': 'Virement bancaire',
    };
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Méthodes de paiement acceptées',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: paymentMethods.map((method) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    paymentIcons[method] ?? Icons.payments,
                    size: 18,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    paymentLabels[method] ?? method,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Widget pour afficher la classification par étoiles
  Widget _buildStarsRating(int stars) {
    if (stars <= 0) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          ...List.generate(
            5,
            (index) => Icon(
              index < stars ? Icons.star : Icons.star_border,
              color: index < stars ? Colors.amber : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$stars étoiles',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Nouveau widget pour afficher les équipements améliorés adaptés au contexte africain
  Widget _buildEnhancedAmenitiesSection(Map<String, dynamic> enhancedAmenities) {
    if (enhancedAmenities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Équipements spécifiques',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),  
        
        // Eau
        if (enhancedAmenities.containsKey('water'))
          _buildEnhancedAmenityCategory(
            'Approvisionnement en eau',
            {
              'runningWater': {'icon': Icons.water_drop, 'label': 'Eau courante'},
              'hotWater': {'icon': Icons.hot_tub, 'label': 'Eau chaude'},
              'waterTank': {'icon': Icons.water, 'label': 'Réservoir d\'eau'},
            },
            enhancedAmenities['water'],
          ),
        
        // Électricité
        if (enhancedAmenities.containsKey('electricity'))
          _buildEnhancedAmenityCategory(
            'Électricité',
            {
              'mainGrid': {'icon': Icons.bolt, 'label': 'Réseau principal'},
              'generator': {'icon': Icons.power, 'label': 'Générateur'},
              'solarEnergy': {'icon': Icons.solar_power, 'label': 'Énergie solaire'},
              'inverter': {'icon': Icons.electrical_services, 'label': 'Onduleur'},
            },
            enhancedAmenities['electricity'],
          ),
        
        // Internet
        if (enhancedAmenities.containsKey('internet'))
          _buildEnhancedAmenityCategory(
            'Internet',
            {
              'wifi': {'icon': Icons.wifi, 'label': 'WiFi'},
              'fiberOptic': {'icon': Icons.wifi_tethering, 'label': 'Fibre optique'},
              'ethernet': {'icon': Icons.lan, 'label': 'Ethernet'},
            },
            enhancedAmenities['internet'],
          ),
        
        // Sécurité
        if (enhancedAmenities.containsKey('security'))
          _buildEnhancedAmenityCategory(
            'Sécurité',
            {
              'securitySystem': {'icon': Icons.security, 'label': 'Système de sécurité'},
              'alarmSystem': {'icon': Icons.alarm, 'label': 'Système d\'alarme'},
              'cctv': {'icon': Icons.videocam, 'label': 'Caméras de surveillance'},
              'securityGuard': {'icon': Icons.person, 'label': 'Gardien 24h/24'},
            },
            enhancedAmenities['security'],
          ),
      ],
    );
  }

  // Helper widget pour afficher une catégorie d'équipements améliorés
  Widget _buildEnhancedAmenityCategory(
    String title, 
    Map<String, Map<String, dynamic>> itemsConfig,
    Map<String, dynamic> availableItems,
  ) {
    // Filtrer les éléments disponibles (value == true)
    final availableFeatures = <Widget>[];
    
    itemsConfig.forEach((key, config) {
      if (availableItems[key] == true) {
        availableFeatures.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Icon(config['icon'] as IconData, size: 20, color: Colors.green),
                const SizedBox(width: 8),
                Text(config['label'] as String),
              ],
            ),
          ),
        );
      }
    });
    
    if (availableFeatures.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ...availableFeatures,
        ],
      ),
    );
  }

  // Widget pour afficher et ajouter des commentaires
  Widget _buildCommentsSection(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    final isLoggedIn = _isUserAuthenticated(context);
  
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Commentaires et avis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Champ pour ajouter un commentaire (uniquement pour les utilisateurs connectés)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Icon(
                      Icons.person,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isLoggedIn ? 'Ajoutez votre commentaire' : 'Connectez-vous pour commenter',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isLoggedIn ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (isLoggedIn)
                Column(
                  children: [
                    // Champ de texte pour le commentaire
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Partagez votre expérience...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    
                    // Barre d'évaluation
                    Row(
                      children: [
                        const Text('Votre note : '),
                        RatingBar.builder(
                          initialRating: 0,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: false,
                          itemCount: 5,
                          itemSize: 20,
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (rating) {
                            // Gérer la mise à jour de la note
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Bouton d'envoi
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          // Logique pour soumettre le commentaire
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: const Text('Publier'),
                      ),
                    ),
                  ],
                )
              else
                // Bouton de connexion pour les utilisateurs non connectés
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      _showAuthDialog(context);
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Se connecter pour commenter'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Liste des commentaires existants
        const SizedBox(height: 16),
        // Simulation de commentaires (à remplacer par des données réelles)
        _buildCommentItem(
          author: 'Marie S.',
          date: 'Il y a 2 semaines',
          rating: 4.5,
          comment: 'Très belle résidence, propre et bien située. Le personnel est accueillant et serviable.',
          photoUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
        ),
        _buildCommentItem(
          author: 'Jean D.',
          date: 'Il y a 1 mois',
          rating: 5,
          comment: 'Excellent rapport qualité-prix. J\'ai particulièrement apprécié la qualité de la connexion internet et la propreté des lieux.',
          photoUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
        ),
      ],
    );
  }

  // Widget pour afficher un commentaire individuel
  Widget _buildCommentItem({
    required String author,
    required String date,
    required double rating,
    required String comment,
    String? photoUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Photo de profil
              CircleAvatar(
                radius: 20,
                backgroundImage: photoUrl != null 
                    ? NetworkImage(photoUrl) as ImageProvider
                    : const AssetImage('assets/images/avatar_placeholder.png'),
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(width: 12),
              // Informations sur l'auteur
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Note
              Row(
                children: [
                  Text(
                    rating.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Commentaire
          Text(
            comment,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Widget pour afficher un exemple de commentaire
  Widget _buildExampleComment({
    required String name,
    required String date,
    required double rating,
    required String comment,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Informations sur l'auteur
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.amber[100],
                      child: Text(
                        name.substring(0, 1),
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Note
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Text(
                      rating.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Contenu du commentaire
          Text(comment),
        ],
      ),
    );
  }
}

// Méthode pour ouvrir la galerie en plein écran
void _openGallery(BuildContext context, List<String> images, int initialIndex) {
  if (images.isEmpty) return;
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => GalleryViewerScreen(
        images: images,
        initialIndex: initialIndex,
      ),
    ),
  );
}

// Widget d'écran de galerie plein écran
class GalleryViewerScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  
  const GalleryViewerScreen({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);
  
  @override
  State<GalleryViewerScreen> createState() => _GalleryViewerScreenState();
}

class _GalleryViewerScreenState extends State<GalleryViewerScreen> with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late PageController _pageController;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    
    // Créer des onglets basés sur le type d'images (par exemple : "Toutes", "Chambre", "Salle de bain", etc.)
    // Pour l'instant, nous utilisons juste un onglet "Toutes les photos"
    _tabController = TabController(length: 1, vsync: this);
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.textLight,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Détails de la résidence'),
            Text(
              'Photo ${_currentIndex + 1} sur ${widget.images.length}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.secondaryColor,
          labelColor: AppTheme.textLight,
          tabs: const [
            Tab(text: 'Toutes les photos'),
            // Ajoutez d'autres onglets si nécessaire, comme :
            // Tab(text: 'Chambre'),
            // Tab(text: 'Salle de bain'),
            // Tab(text: 'Cuisine'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Vue principale des images
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: widget.images[index],
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(color: Colors.white54),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 50,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Miniatures en bas pour navigation rapide
          Container(
            height: 80,
            color: Colors.black,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _currentIndex == index ? AppTheme.primaryColor : Colors.transparent,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: widget.images[index],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white54),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Bouton d'action pour réserver (en bas)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryColor,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Choisir cette chambre',
                style: TextStyle(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}