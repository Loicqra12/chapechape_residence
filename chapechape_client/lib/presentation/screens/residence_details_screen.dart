import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chapechape_maps/chapechape_maps.dart';
import 'package:chapechape_client/presentation/widgets/animated_favorite_button.dart';
import 'package:chapechape_client/core/services/residence_service.dart';
// import '../screens/full_map_screen.dart'; // Commenté car non utilisé
import '../../core/blocs/auth/auth_bloc.dart';
import '../../core/blocs/auth/auth_state.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/text_styles.dart';
import '../screens/booking_screen.dart';
import '../../core/blocs/booking/booking_bloc.dart';
import '../../core/services/booking_service.dart';
import '../widgets/skeletons/residence_details_skeleton.dart';

class ResidenceDetailsScreen extends StatefulWidget {
  final String residenceId;
  
  const ResidenceDetailsScreen({super.key, required this.residenceId});

  @override
  State<ResidenceDetailsScreen> createState() => _ResidenceDetailsScreenState();
}

class _ResidenceDetailsScreenState extends State<ResidenceDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController commentController = TextEditingController();
  double selectedRating = 0;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  
  final String defaultImage = 'assets/images/residences/apartments/304661255.jpg';

  late final LocationService _locationService;
  
  LatLng? _currentUserLocation;
  
  // Variable pour forcer le rechargement des avis
  int _reviewsRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    
    _locationService = LocationService();
    _getCurrentLocation();
    
    context.read<ResidenceBloc>().add(LoadResidenceDetails(residenceId: widget.residenceId));
  }
  
  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentUserLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la position: $e');
    }
  }
  
  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        // _currentTabIndex = _tabController.index; // Commenté car non utilisé
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
        context.read<ResidenceBloc>().add(const RefreshResidencesEvent());
        return true;
      },
      child: Scaffold(
        body: BlocBuilder<ResidenceBloc, ResidenceState>(
          builder: (context, state) {
            if (state is ResidenceLoading) {
              return const ResidenceDetailsSkeleton();
            } else if (state is ResidenceDetailsLoaded) {
              final residence = state.residence;
              
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    flexibleSpace: Stack(
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _openGallery(context, residence.images, _currentImageIndex);
                            },
                            child: Stack(
                              children: [
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
                                
                                if (residence.images.length > 1)
                                  Positioned(
                                    bottom: 20,
                                    right: 20,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                      ),
                                      padding: EdgeInsets.all(AppSpacing.xs),
                                      child: Text(
                                        "+${residence.images.length - 1}",
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                if (residence.images.length > 1)
                                  Positioned.fill(
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            if (_currentImageIndex > 0) {
                                              HapticFeedback.selectionClick();
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
                                                    padding: EdgeInsets.all(AppSpacing.sm),
                                                    child: const Icon(
                                                      Icons.arrow_back_ios,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                  )
                                                : const SizedBox.shrink(),
                                          ),
                                        ),
                                        
                                        Expanded(child: Container()),
                                        
                                        GestureDetector(
                                          onTap: () {
                                            if (_currentImageIndex < residence.images.length - 1) {
                                              HapticFeedback.selectionClick();
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
                                                    padding: EdgeInsets.all(AppSpacing.sm),
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
                        
                        if (residence.images.length > 1)
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                  ),
                                  child: SmoothPageIndicator(
                                    controller: _pageController,
                                    count: residence.images.length,
                                    effect: ExpandingDotsEffect(
                                      spacing: AppSpacing.sm,
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
                      margin: EdgeInsets.all(AppSpacing.sm),
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
                      BlocBuilder<AuthBloc, dynamic>(
                        builder: (context, authState) {
                          final bool isUserAuthenticated = _isUserAuthenticated(context);
                          return Container(
                            margin: EdgeInsets.all(AppSpacing.sm),
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
                      Container(
                        margin: EdgeInsets.all(AppSpacing.sm),
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
                  
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: AppSpacing.cardPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      residence.name,
                                      style: Theme.of(context).textTheme.headlineMedium,
                                    ),
                                    SizedBox(height: AppSpacing.xs5), // 5px pour espacement spécifique
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
                                          SizedBox(width: AppSpacing.xs),
                                          Text(
                                            "(${residence.reviewCount} avis)",
                                            style: AppTextStyles.caption.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _formatCurrency(residence.price, currency: residence.currency),
                                        style: AppTextStyles.title.copyWith(
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                      SizedBox(width: AppSpacing.xs5), // 5px pour espacement spécifique
                                      Text(
                                        _formatPeriod(residence.pricePeriod),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  if (residence.hasDiscount)
                                    Row(
                                      children: [
                                        Text(
                                          residence.formattedDiscountPrice,
                                          style: AppTextStyles.subtitle.copyWith(
                                            color: Colors.green,
                                          ),
                                        ),
                                        SizedBox(width: AppSpacing.xs),
                                        Text(
                                          residence.formattedPrice,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            decoration: TextDecoration.lineThrough,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                  if (residence.hasDiscount)
                                    Container(
                                      margin: EdgeInsets.only(top: AppSpacing.xs),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: AppSpacing.xs6,
                                        vertical: AppSpacing.xxs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(AppSpacing.xs),
                                      ),
                                      child: Text(
                                        residence.discountBadge,
                                        style: AppTextStyles.tag.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          
                          AppSpacing.verticalMd,
                          Container(
                            padding: EdgeInsets.all(AppSpacing.smd),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.grey, size: 20),
                                SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    residence.location['displayAddress'] ?? residence.address,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          AppSpacing.verticalMd,
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Padding(
                              padding: AppSpacing.cardPadding,
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
                          
                          AppSpacing.verticalMd,
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: AppSpacing.smd, vertical: 6),
                                decoration: BoxDecoration(
                                  color: residence.isAvailable ? Colors.green[100] : Colors.red[100],
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd + AppSpacing.sm),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      residence.isAvailable ? Icons.check_circle : Icons.cancel,
                                      size: 16,
                                      color: residence.isAvailable ? Colors.green[800] : Colors.red[800],
                                    ),
                                    SizedBox(width: AppSpacing.xs),
                                    Text(
                                      residence.isAvailable ? 'Disponible' : 'Non disponible',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: residence.isAvailable ? Colors.green[800] : Colors.red[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          AppSpacing.verticalLg,
                          Text(
                            'Description',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          AppSpacing.verticalSm,
                          ExpandableText(
                            residence.description,
                            expandText: 'Voir plus',
                            collapseText: 'Voir moins',
                            maxLines: 4,
                            linkColor: Theme.of(context).primaryColor,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          
                          AppSpacing.verticalXl,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Équipements',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              SizedBox(
                                width: 100, 
                                child: TextButton(
                                  onPressed: () {
                                    // Ouvrir une page ou modal avec tous les équipements
                                  },
                                  child: const Text('Voir tous'),
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.verticalSm,
                          _buildSimpleAmenitiesGrid(residence.amenities),
                           
                           if (residence.priceDetails != null && 
                               residence.priceDetails!.containsKey('enhancedAmenities') &&
                               residence.priceDetails!['enhancedAmenities'] is Map<String, dynamic>)
                             _buildEnhancedAmenitiesSection(residence.priceDetails!['enhancedAmenities']),
                           
                           if (residence.priceDetails != null && 
                               residence.priceDetails!.containsKey('stars') &&
                               residence.priceDetails!['stars'] is int)
                             Padding(
                               padding: EdgeInsets.only(top: AppSpacing.sm),
                               child: _buildStarsRating(residence.priceDetails!['stars']),
                             ),
                           
                           if (residence.priceDetails != null && 
                               residence.priceDetails!.containsKey('faqs') &&
                               residence.priceDetails!['faqs'] is List)
                             _buildFaqsSection(
                               (residence.priceDetails!['faqs'] as List)
                                   .map((e) => e as Map<String, dynamic>)
                                   .toList(),
                             ),
                           
                           if (residence.priceDetails != null && 
                               residence.priceDetails!.containsKey('paymentMethods') &&
                               residence.priceDetails!['paymentMethods'] is List)
                             _buildPaymentMethodsSection(
                               (residence.priceDetails!['paymentMethods'] as List)
                                   .map((e) => e as String)
                                   .toList(),
                             ),
                          
                          if (residence.nearbyAttractions != null && residence.nearbyAttractions!.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                                  child: Text(
                                    'Points d\'intérêt à proximité',
                                    style: AppTextStyles.subtitle,
                                  ),
                                ),
                                SizedBox(
                                  height: 120,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: residence.nearbyAttractions!.length,
                                    itemBuilder: (context, index) {
                                      final attraction = residence.nearbyAttractions![index];
                                      
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
                                      
                                      IconData attractionIcon = Icons.place;
                                      for (final entry in attractionIcons.entries) {
                                        if (attraction.toLowerCase().contains(entry.key.toLowerCase())) {
                                          attractionIcon = entry.value;
                                          break;
                                        }
                                      }
                                      
                                      return Card(
                                        elevation: 2,
                                        margin: EdgeInsets.only(right: AppSpacing.smd, bottom: AppSpacing.xs),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                        ),
                                        child: Container(
                                          width: 200,
                                          padding: EdgeInsets.all(AppSpacing.smd),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                attractionIcon,
                                                color: Colors.blue[700],
                                                size: 32,
                                              ),
                                              AppSpacing.verticalSm,
                                              Text(
                                                attraction,
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                          
                          if (residence.rules != null && residence.rules!.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppSpacing.verticalXl,
                                Text(
                                  'Règles de la résidence',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                SizedBox(height: AppSpacing.smd),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: residence.rules!.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.check_circle_outline,
                                            color: Colors.green,
                                            size: 20,
                                          ),
                                          SizedBox(width: AppSpacing.smd),
                                          Expanded(
                                            child: Text(
                                              residence.rules![index],
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          
                          AppSpacing.verticalLg,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Commentaires et avis',
                                style: AppTextStyles.subtitle,
                              ),
                              AppSpacing.verticalMd,
                              Container(
                                padding: AppSpacing.cardPadding,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: _isUserAuthenticated(context) 
                                  ? _buildCommentForm(context, residence) 
                                  : Column(
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
                                          SizedBox(width: AppSpacing.smd),
                                          Expanded(
                                            child: TextButton(
                                              onPressed: () => _navigateToLogin(context),
                                              child: Text(
                                                'Connectez-vous pour laisser un commentaire',
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                              ),
                              
                              AppSpacing.verticalMd,
                              FutureBuilder<Map<String, dynamic>>(
                                key: ValueKey(_reviewsRefreshKey),
                                future: _loadRealReviews(residence.id),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  
                                  if (snapshot.hasError || !snapshot.hasData) {
                                    // Fallback vers les commentaires d'exemple en cas d'erreur
                                    return Column(
                                      children: [
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
                                    );
                                  }
                                  
                                  final reviewsData = snapshot.data!;
                                  final dataSection = reviewsData['data'] as Map<String, dynamic>? ?? {};
                                  final reviews = dataSection['reviews'] as List<dynamic>? ?? [];
                                  
                                  print('DEBUG: reviewsData keys: ${reviewsData.keys}');
                                  print('DEBUG: reviews length: ${reviews.length}');
                                  
                                  if (reviews.isEmpty) {
                                    return Column(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(AppSpacing.lg),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey[300]!),
                                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(Icons.rate_review_outlined, 
                                                   size: 48, color: Colors.grey[400]),
                                              AppSpacing.verticalSm,
                                              Text(
                                                'Aucun avis pour cette résidence',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              AppSpacing.verticalXs,
                                              Text(
                                                'Soyez le premier à laisser un avis !',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                  
                                  // Afficher les vrais avis (limiter à 3 pour l'aperçu)
                                  final displayReviews = reviews.take(3).toList();
                                  return Column(
                                    children: [
                                      ...displayReviews.map((review) => _buildRealReviewComment(review)).toList(),
                                      if (reviews.length > 3)
                                        Padding(
                                          padding: EdgeInsets.only(top: AppSpacing.md),
                                          child: TextButton(
                                            onPressed: () {
                                              // Navigation vers l'écran des avis complet
                                              Navigator.pushNamed(
                                                context, 
                                                '/reviews/${residence.id}'
                                              );
                                            },
                                            child: Text(
                                              'Voir tous les ${reviews.length} avis',
                                              style: AppTextStyles.link.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                          
                          AppSpacing.verticalXl,
                          _buildLocationSection(context, residence),
                          
                          SizedBox(height: AppSpacing.huge), // 80px pour espacement spécifique
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
        floatingActionButton: BlocBuilder<ResidenceBloc, ResidenceState>(
          builder: (context, state) {
            if (state is ResidenceDetailsLoaded) {
              return BlocBuilder<AuthBloc, dynamic>(
                builder: (context, authState) {
                  final bool isAuthenticated = _isUserAuthenticated(context);
                  return FloatingActionButton.extended(
                    onPressed: state.residence.id.isEmpty 
                      ? null 
                      : () async {
                          if (isAuthenticated) {
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
                            
                            final bookingService = await BookingService.initialize();
                            
                            if (!mounted) return; 
                            
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => MultiBlocProvider(
                                  providers: [
                                    BlocProvider<BookingBloc>(
                                      create: (context) => BookingBloc(
                                        bookingService: bookingService,
                                      ),
                                    ),
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
                            _showAuthDialog(context);
                          }
                        },
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    label: Text(
                      isAuthenticated ? 'Réserver maintenant' : 'Se connecter pour réserver',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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

  /// Navigue vers l'écran de connexion
  void _navigateToLogin(BuildContext context) {
    // Utilise le routeur pour naviguer vers la page de connexion
    context.push('/auth/login');
  }

  /// Construit le formulaire pour ajouter un commentaire
  Widget _buildCommentForm(BuildContext context, dynamic residence) {
    // Contrôleurs pour le formulaire de commentaire
    final TextEditingController commentController = TextEditingController();
    final double rating = 5.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête du formulaire
        Text(
          'Laissez votre avis',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
                          SizedBox(height: AppSpacing.smd),
        
        // Étoiles pour la note
        Row(
          children: [
            const Text('Note: '),
            RatingBar.builder(
              initialRating: rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 24,
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (newRating) {
                // Mettre à jour la note
                setState(() {
                  selectedRating = newRating;
                });
              },
            ),
          ],
        ),
                          SizedBox(height: AppSpacing.smd),
        
        // Champ de commentaire
        TextField(
          controller: commentController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Partagez votre expérience...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
        ),
                          SizedBox(height: AppSpacing.smd),
        
        // Bouton pour soumettre
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () async {
              final comment = commentController.text;
              if (comment.isNotEmpty) {
                // Afficher un indicateur de chargement
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Envoi de votre commentaire...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                
                try {
                  // Obtenir le ResidenceService
                  final residenceService = await ResidenceService.initialize();
                  
                  // Soumettre le commentaire
                  final success = await residenceService.submitReview(
                    residenceId: widget.residenceId,
                    rating: selectedRating,
                    comment: comment,
                  );
                  
                  if (success) {
                    // Montrer un message de succès
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Merci pour votre avis!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    
                    // Effacer le champ de commentaire
                    commentController.clear();
                    // Réinitialiser la note
                    setState(() {
                      selectedRating = 0;
                      // Forcer le rechargement des avis
                      _reviewsRefreshKey++;
                    });
                  } else {
                    // Montrer un message d'erreur
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erreur lors de l\'envoi de votre commentaire. Veuillez réessayer.'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                } catch (e) {
                  // Montrer un message d'erreur
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('Publier'),
          ),
        ),
      ],
    );
  }

  /// Obtient le libellé d'emplacement personnalisé selon le type de résidence
  String _getLocationLabel(dynamic residence) {
    try {
      if (residence.type != null) {
        // Convertir le type en ResidenceType si c'est une chaîne
        ResidenceType residenceType;
        if (residence.type is String) {
          residenceType = ResidenceTypeExtension.fromString(residence.type);
        } else if (residence.type is ResidenceType) {
          residenceType = residence.type;
        } else {
          residenceType = ResidenceType.other;
        }
        
        // Utiliser le nom d'affichage du type comme base
        String typeDisplay = residenceType.displayName;
        
        // Déterminer le bon libellé selon le type
        if (typeDisplay.toLowerCase().contains('hôtel')) {
          return 'Emplacement de l\'hôtel';
        } else if (typeDisplay.toLowerCase().contains('villa')) {
          return 'Emplacement de la villa';
        } else if (typeDisplay.toLowerCase().contains('appartement')) {
          return 'Emplacement de l\'appartement';
        } else if (typeDisplay.toLowerCase().contains('studio')) {
          return 'Emplacement du studio';
        } else if (typeDisplay.toLowerCase().contains('chambre') || 
                  typeDisplay.toLowerCase().contains('colocation')) {
          return 'Emplacement de la colocation';
        } else if (typeDisplay.toLowerCase().contains('bungalow')) {
          return 'Emplacement du bungalow';
        } else if (typeDisplay.toLowerCase().contains('loft')) {
          return 'Emplacement du loft';
        } else if (typeDisplay.toLowerCase().contains('maison')) {
          return 'Emplacement de la maison';
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération du type de résidence: $e');
    }
    
    // Valeur par défaut
    return 'Emplacement de l\'hébergement';
  }

  /// Construit la section d'emplacement avec carte Google Maps (style Booking.com)
  Widget _buildLocationSection(BuildContext context, dynamic residence) {
    // Récupérer les coordonnées de la résidence depuis le modèle
    double? lat, lng;
    String displayAddress = 'Adresse non disponible';
    String locationLabel = _getLocationLabel(residence);
    
    // Essayer de récupérer les coordonnées et l'adresse depuis différentes structures possibles
    try {
      if (residence.location != null) {
        if (residence.location['coordinates'] != null && residence.location['coordinates'] is List) {
          // Format GeoJSON [longitude, latitude]
          final coords = residence.location['coordinates'] as List;
          if (coords.length >= 2) {
            lng = coords[0];
            lat = coords[1];
          }
        }
        
        // Récupérer l'adresse affichable
        if (residence.location['displayAddress'] != null) {
          displayAddress = residence.location['displayAddress'];
        } else if (residence.address != null) {
          // Construire une adresse à partir des composants disponibles
          List<String> addressParts = [];
          if (residence.address.isNotEmpty) addressParts.add(residence.address);
          if (residence.city.isNotEmpty) addressParts.add(residence.city);
          if (residence.country.isNotEmpty) addressParts.add(residence.country);
          
          if (addressParts.isNotEmpty) {
            displayAddress = addressParts.join(', ');
          }
        }
      } else if (residence.latitude != null && residence.longitude != null) {
        // Structure directe avec latitude/longitude
        lat = residence.latitude;
        lng = residence.longitude;
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des coordonnées: $e');
    }
    
    // Si pas de coordonnées valides, afficher un message
    if (lat == null || lng == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locationLabel,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          AppSpacing.verticalMd,
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Text(
                'Les coordonnées de localisation ne sont pas disponibles pour cette résidence',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            ),
          ),
        ],
      );
    }
    
    // Calculer la distance entre l'utilisateur et la résidence si disponible
    String distanceText = '';
    if (_currentUserLocation != null) {
      try {
        final distance = _locationService.calculateDistance(
          _currentUserLocation!,
          LatLng(lat, lng)
        ) / 1000; // Convertir en km
        
        // Formater la distance
        if (distance < 1) {
          distanceText = '${(distance * 1000).toStringAsFixed(0)} m de votre emplacement actuel';
        } else {
          distanceText = '${distance.toStringAsFixed(1)} km de votre emplacement actuel';
        }
      } catch (e) {
        debugPrint('Erreur lors du calcul de la distance: $e');
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locationLabel,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        AppSpacing.verticalMd,
        // Carte Google Maps avec marqueur et bouton pour carte plein écran
        Stack(
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(lat, lng),
                    zoom: 14.0,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('residence'),
                      position: LatLng(lat, lng),
                      infoWindow: InfoWindow(title: residence.title ?? 'Résidence'),
                    ),
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: false,
                  onTap: (_) {
                    // Ouvrir la carte en plein écran
                    _openFullMap(context, lat, lng, residence);
                  },
                ),
              ),
            ),
            // Bouton pour ouvrir la carte en plein écran
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.fullscreen, color: Colors.blue),
                  tooltip: 'Voir la carte en plein écran',
                  onPressed: () {
                    _openFullMap(context, lat, lng, residence);
                  },
                ),
              ),
            ),
          ],
        ),
        AppSpacing.verticalMd,
        // Adresse et distance
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                                          SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      displayAddress,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.2, // Interligne réduit pour éviter les overflow
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis, // Ajoute des points de suspension si l'adresse est trop longue
                      maxLines: 2, // Limite à deux lignes maximum
                    ),
                  ),
                ],
              ),
              if (distanceText.isNotEmpty) ...[  
                                              AppSpacing.verticalSm,
                Row(
                  children: [
                    Icon(Icons.near_me, color: Theme.of(context).primaryColor),
                                          SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        distanceText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis, // Ajoute des points de suspension si le texte est trop long
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
              AppSpacing.verticalMd,
              // Bouton pour voir l'itinéraire dans Google Maps
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _launchMapsUrl(lat, lng, residence.title ?? 'Résidence'),
                  icon: const Icon(Icons.directions),
                  label: const Text('Obtenir l\'itinéraire'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Ouvre la carte en plein écran avec les résidences à proximité
  void _openFullMap(BuildContext context, double? lat, double? lng, dynamic residence) {
    if (lat == null || lng == null) return;
    
    // Récupérer l'ID de la résidence si disponible
    String? residenceId;
    try {
      residenceId = residence.id?.toString();
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'ID de résidence: $e');
    }
    
    // Naviguer vers la carte en plein écran
    context.push(
      '/map-fullscreen',
      extra: {
        'lat': lat,
        'lng': lng,
        'title': residence.title ?? 'Résidence',
        'residenceId': residenceId,
      },
    );
  }
  
  /// Lance Google Maps avec un itinéraire vers la destination
  Future<void> _launchMapsUrl(double? lat, double? lng, String title) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=${Uri.encodeComponent(title)}'
    );
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Impossible d\'ouvrir Google Maps');
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildEnhancedFeatureItem(BuildContext context, {required IconData icon, required String value, required String label}) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 24),
                                              AppSpacing.verticalSm,
        Text(
          value,
          style: AppTextStyles.subtitle,
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
                                              AppSpacing.verticalSm,
            Text(
              displayText,
              style: Theme.of(context).textTheme.bodySmall,
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
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text(
            'Questions fréquentes',
            style: AppTextStyles.subtitle,
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              children: [
                Padding(
                  padding: AppSpacing.cardPadding,
                  child: Text(
                    faq['answer'],
                    style: Theme.of(context).textTheme.bodySmall,
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
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text(
            'Méthodes de paiement acceptées',
            style: AppTextStyles.subtitle,
          ),
        ),
        Wrap(
          spacing: AppSpacing.smd,
          runSpacing: AppSpacing.smd,
          children: paymentMethods.map((method) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.smd, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd + AppSpacing.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    paymentIcons[method] ?? Icons.payments,
                    size: 18,
                    color: Colors.blue[700],
                  ),
                                          SizedBox(width: AppSpacing.sm),
                  Text(
                    paymentLabels[method] ?? method,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
                                          SizedBox(width: AppSpacing.sm),
          Text(
            '$stars étoiles',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text(
            'Équipements spécifiques',
            style: AppTextStyles.subtitle,
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
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Icon(config['icon'] as IconData, size: 20, color: Colors.green),
                                          SizedBox(width: AppSpacing.sm),
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
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text(
            'Commentaires et avis',
            style: AppTextStyles.subtitle,
          ),
        ),
        
        // Champ pour ajouter un commentaire (uniquement pour les utilisateurs connectés)
        Container(
          padding: EdgeInsets.all(AppSpacing.smd),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
                                          SizedBox(width: AppSpacing.smd),
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
                          SizedBox(height: AppSpacing.smd),
              
              if (isLoggedIn)
                Column(
                  children: [
                    // Champ de texte pour le commentaire
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Partagez votre expérience...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 3,
                    ),
                          SizedBox(height: AppSpacing.smd),
                    
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
                          SizedBox(height: AppSpacing.smd),
                    
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
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
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
        AppSpacing.verticalMd,
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
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.smd),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
                                          SizedBox(width: AppSpacing.smd),
              // Informations sur l'auteur
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs / 2), // 2px pour espacement spécifique
                    Text(
                      date,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Note
              Row(
                children: [
                  Text(
                    rating.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                                        SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
                          SizedBox(height: AppSpacing.smd),
          // Commentaire
          Text(
            comment,
                    style: Theme.of(context).textTheme.bodySmall,
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
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
                                          SizedBox(width: AppSpacing.sm),
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
                          style: AppTextStyles.caption.copyWith(
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
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                ),
                child: Row(
                  children: [
                    Text(
                      rating.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                                        SizedBox(width: AppSpacing.xs),
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
                          SizedBox(height: AppSpacing.smd),
          
          // Contenu du commentaire
          Text(comment),
        ],
      ),
    );
  }

  // Méthode pour charger les vrais avis depuis l'API
  Future<Map<String, dynamic>> _loadRealReviews(String residenceId) async {
    try {
      final residenceService = await ResidenceService.initialize();
      return await residenceService.getResidenceReviews(residenceId, limit: 5);
    } catch (e) {
      debugPrint('Erreur lors du chargement des avis: $e');
      return {};
    }
  }

  // Widget pour afficher un vrai commentaire depuis l'API
  Widget _buildRealReviewComment(Map<String, dynamic> review) {
    final user = review['user'] as Map<String, dynamic>? ?? {};
    final rating = review['rating'] as Map<String, dynamic>? ?? {};
    final overallRating = (rating['overall'] as num?)?.toDouble() ?? 0.0;
    final comment = review['comment'] as String? ?? '';
    final createdAt = review['updatedAt'] as String? ?? review['createdAt'] as String?;
    
    final userName = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    String formattedDate = 'Récemment';
    if (createdAt != null) {
      try {
        final reviewDate = DateTime.parse(createdAt).toLocal();
        final now = DateTime.now();
        final difference = now.difference(reviewDate);
        
        if (difference.inDays > 30) {
          formattedDate = 'Il y a ${(difference.inDays / 30).floor()} mois';
        } else if (difference.inDays > 7) {
          formattedDate = 'Il y a ${(difference.inDays / 7).floor()} semaines';
        } else if (difference.inDays > 0) {
          formattedDate = 'Il y a ${difference.inDays} jours';
        } else if (difference.inHours > 0) {
          formattedDate = 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
        } else if (difference.inMinutes > 0) {
          formattedDate = 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
        } else {
          formattedDate = 'À l\'instant';
        }
      } catch (e) {
        formattedDate = 'Récemment';
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
                        userInitial,
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                                          SizedBox(width: AppSpacing.smd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName.isNotEmpty ? userName : 'Utilisateur anonyme',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              // Utilise Theme.of(context).textTheme.bodySmall
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: Colors.grey[600],
                              // Utilise AppTextStyles.caption
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Note avec étoiles
              Row(
                children: [
                  ...List.generate(5, (index) {
                    return Icon(
                      index < overallRating.floor() ? Icons.star : 
                      index < overallRating ? Icons.star_half : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                                        SizedBox(width: AppSpacing.xs),
                  Text(
                    overallRating.toStringAsFixed(1),
                    style: TextStyle(
                      color: Colors.grey[600],
                      // Utilise AppTextStyles.caption
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
                          SizedBox(height: AppSpacing.smd),
            Text(
              comment,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                height: 1.4,
              ),
            ),
          ],
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
              style: Theme.of(context).textTheme.bodySmall,
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
                    margin: EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _currentIndex == index ? AppTheme.primaryColor : Colors.transparent,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
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
            padding: AppSpacing.cardPadding,
            color: AppTheme.primaryColor,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: AppSpacing.smd),
              ),
              child: Text(
                'Choisir cette chambre',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour charger les vrais avis depuis l'API
  Future<Map<String, dynamic>> _loadRealReviews(String residenceId) async {
    try {
      final residenceService = await ResidenceService.initialize();
      return await residenceService.getResidenceReviews(residenceId, limit: 5);
    } catch (e) {
      debugPrint('Erreur lors du chargement des avis: $e');
      return {};
    }
  }

  // Widget pour afficher un vrai commentaire depuis l'API
  Widget _buildRealReviewComment(Map<String, dynamic> review) {
    final user = review['user'] as Map<String, dynamic>? ?? {};
    final rating = review['rating'] as Map<String, dynamic>? ?? {};
    final overallRating = (rating['overall'] as num?)?.toDouble() ?? 0.0;
    final comment = review['comment'] as String? ?? '';
    final createdAt = review['updatedAt'] as String? ?? review['createdAt'] as String?;
    
    final userName = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    String formattedDate = 'Récemment';
    if (createdAt != null) {
      try {
        final reviewDate = DateTime.parse(createdAt).toLocal();
        final now = DateTime.now();
        final difference = now.difference(reviewDate);
        
        if (difference.inDays > 30) {
          formattedDate = 'Il y a ${(difference.inDays / 30).floor()} mois';
        } else if (difference.inDays > 7) {
          formattedDate = 'Il y a ${(difference.inDays / 7).floor()} semaines';
        } else if (difference.inDays > 0) {
          formattedDate = 'Il y a ${difference.inDays} jours';
        } else if (difference.inHours > 0) {
          formattedDate = 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
        } else if (difference.inMinutes > 0) {
          formattedDate = 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
        } else {
          formattedDate = 'À l\'instant';
        }
      } catch (e) {
        formattedDate = 'Récemment';
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
                        userInitial,
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                                          SizedBox(width: AppSpacing.smd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName.isNotEmpty ? userName : 'Utilisateur anonyme',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              // Utilise Theme.of(context).textTheme.bodySmall
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: Colors.grey[600],
                              // Utilise AppTextStyles.caption
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Note avec étoiles
              Row(
                children: [
                  ...List.generate(5, (index) {
                    return Icon(
                      index < overallRating.floor() ? Icons.star : 
                      index < overallRating ? Icons.star_half : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                                        SizedBox(width: AppSpacing.xs),
                  Text(
                    overallRating.toStringAsFixed(1),
                    style: TextStyle(
                      color: Colors.grey[600],
                      // Utilise AppTextStyles.caption
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
                          SizedBox(height: AppSpacing.smd),
            Text(
              comment,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}