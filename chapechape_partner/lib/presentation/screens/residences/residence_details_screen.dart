import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../core/blocs/residence/residence_bloc.dart';
import '../../../core/services/event_bus/residence_event_bus.dart';
import '../../../core/blocs/review/review_bloc.dart';
import '../../../core/blocs/review/review_event.dart';
import '../../../core/blocs/review/review_state.dart';
import '../../../core/blocs/favorite/favorite_bloc.dart';
import '../../../core/blocs/favorite/favorite_event.dart';
import '../../../core/blocs/promotion/promotion_bloc.dart';
import '../../../core/blocs/promotion/promotion_event.dart';
import '../../../core/models/residence/residence.dart';
import '../../../core/models/residence/residence_extensions.dart';
import '../../../core/models/residence/nearby_place.dart';
import '../../../core/models/residence/faq.dart';
import '../../../core/models/promotion/promotion_model.dart';
import '../../../core/services/api/residence_service.dart';
import '../../../core/services/api/review_service.dart';
import '../../../core/services/api/favorite_service.dart';
import '../../../core/services/api/promotion_service.dart';
import '../../../core/services/api/api_service.dart';
import '../../../core/config/app_config_manager.dart';
import 'edit_residence_screen.dart';
import 'nearby_places_edit_screen.dart';
import 'faq_edit_screen.dart';
import '../../widgets/review/review_item_widget.dart';
import '../../widgets/favorite/favorite_button_widget.dart';
import '../../widgets/promotion/promotions_list_widget.dart';
import '../../widgets/promotion/promotion_form_dialog.dart';
import '../../../core/services/currency_service.dart';
import '../../widgets/currency_selector_widget.dart';

class ResidenceDetailsScreen extends StatefulWidget {
  final Residence residence;

  const ResidenceDetailsScreen({
    super.key,
    required this.residence,
  });

  @override
  State<ResidenceDetailsScreen> createState() => _ResidenceDetailsScreenState();
}

class _ResidenceDetailsScreenState extends State<ResidenceDetailsScreen> {
  // Abonnement au bus d'événements
  StreamSubscription? _residenceEventSubscription;

  @override
  void initState() {
    super.initState();
    
    // S'abonner au bus d'événements pour les mises à jour de résidences
    _residenceEventSubscription = ResidenceEventBus().stream.listen((event) {
      // Quand une résidence est mise à jour, recharger les détails
      if (event == ResidenceEventType.updated || event == ResidenceEventType.refreshNeeded) {
        // Vérifier si le widget est toujours monté
        if (mounted) {
          // Recharger les détails de cette résidence
          context.read<ResidenceBloc>().add(LoadResidenceDetails(widget.residence.id));
        }
      }
    });
  }

  @override
  void dispose() {
    // Se désabonner du bus d'événements
    _residenceEventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ResidenceBloc>(
          create: (context) => ResidenceBloc(
            ResidenceService(baseUrl: AppConfigManager.apiUrl),
          )..add(CheckResidenceExists(widget.residence.id, 
              onSuccess: (exists) {
                if (exists) {
                  context.read<ResidenceBloc>().add(LoadResidenceDetails(widget.residence.id));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cette résidence n\'existe plus'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
              onError: (errorMessage) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $errorMessage'),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.of(context).pop();
              }
            )),
        ),
        BlocProvider<ReviewBloc>(
          create: (context) => ReviewBloc(
            reviewService: ReviewService.withApiService(
              apiService: ApiService(authBloc: null),
            ),
          )..add(LoadReviews(widget.residence.id)),
        ),
        BlocProvider<FavoriteBloc>(
          create: (context) => FavoriteBloc(
            favoriteService: FavoriteService.withApiService(
              apiService: ApiService(authBloc: null),
            ),
          )..add(CheckFavoriteStatus(residenceId: widget.residence.id)),
        ),
        BlocProvider<PromotionBloc>(
          create: (context) => PromotionBloc(
            promotionService: PromotionService(
              apiService: context.read<ApiService>(),
            ),
          ),
        ),
      ],
      child: BlocConsumer<ResidenceBloc, ResidenceState>(
        listener: (context, state) {
          if (state is ResidenceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ResidenceLoading) {
            return Scaffold(
              appBar: AppBar(title: Text(widget.residence.displayName)),
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          return DefaultTabController(
            length: 5,
            child: Scaffold(
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      expandedHeight: 240.0,
                      floating: false,
                      pinned: true,
                      elevation: 0,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      title: Text(
                        widget.residence.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: innerBoxIsScrolled ? Theme.of(context).colorScheme.onSurface : Colors.white,
                        ),
                      ),
                      actions: [
                        // Bouton de favori
                        FavoriteButtonWidget(
                          residenceId: widget.residence.id,
                          activeColor: Colors.red,
                          inactiveColor: innerBoxIsScrolled ? Theme.of(context).colorScheme.onSurface : Colors.white,
                          size: 26.0,
                        ),
                        // Bouton d'édition
                        IconButton(
                          style: IconButton.styleFrom(
                            shape: const CircleBorder(),
                            side: BorderSide(
                              color: innerBoxIsScrolled
                                  ? Colors.grey.shade300
                                  : Colors.white24,
                            ),
                            backgroundColor: Colors.transparent,
                          ),
                          icon: Icon(
                            Icons.edit,
                            color: innerBoxIsScrolled ? Theme.of(context).colorScheme.onSurface : Colors.white,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditResidenceScreen(
                                  residence: widget.residence,
                                ),
                              ),
                            ).then((_) {
                              // Rafraîchir les données après l'édition
                                context.read<ResidenceBloc>().add(CheckResidenceExists(
                                  widget.residence.id, 
                                  onSuccess: (exists) {
                                    if (exists) {
                                      context.read<ResidenceBloc>().add(LoadResidenceDetails(widget.residence.id));
                                    }
                                  }
                                ));
                            });
                          },
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: innerBoxIsScrolled ? Theme.of(context).colorScheme.onSurface : Colors.white,
                          ),
                          onSelected: (value) {
                            if (value == 'delete') {
                              _showDeleteConfirmation(context);
                            } else if (value == 'share') {
                              _showShareOptions(context);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'share',
                              child: ListTile(
                                leading: Icon(Icons.share),
                                title: Text('Partager'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: _ImageGalleryHeader(residence: widget.residence),
                      ),
                    ),
                    SliverPersistentHeader(
                      delegate: _SliverTabBarDelegate(
                        TabBar(
                          isScrollable: true,
                          labelColor: Theme.of(context).colorScheme.primary,
                          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicatorWeight: 3,
                          tabs: const [
                            Tab(icon: Icon(Icons.home_outlined), text: 'Aperçu'),
                            Tab(icon: Icon(Icons.calendar_month_outlined), text: 'Disponibilités'),
                            Tab(icon: Icon(Icons.photo_library_outlined), text: 'Galerie'),
                            Tab(icon: Icon(Icons.star_outline), text: 'Avis'),
                            Tab(icon: Icon(Icons.local_offer_outlined), text: 'Promotions'),
                  ],
                ),
              ),
                      pinned: true,
                    ),
                    // Ajouter une section de résumé clé en dessous des onglets
                    SliverToBoxAdapter(
                      child: _ResidenceStatsBar(residence: widget.residence),
                    ),
                  ];
                },
              body: Container(
                color: Theme.of(context).colorScheme.background.withOpacity(0.05),
                child: TabBarView(
                  children: [
                    // Onglet Aperçu
                      _EnhancedOverviewTab(residence: widget.residence),
                    // Onglet Disponibilités
                      _EnhancedAvailabilityTab(residence: widget.residence),
                    // Onglet Galerie
                      _EnhancedGalleryTab(residence: widget.residence),
                    // Onglet Avis
                      _EnhancedReviewsTab(residence: widget.residence),
                    // Onglet Promotions
                      _EnhancedPromotionsTab(residence: widget.residence),
                  ],
                ),
              ),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditResidenceScreen(
                        residence: widget.residence,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Modifier'),
                elevation: 4,
              ),
            ),
          );
        },
      ),
    );
  }
  
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la résidence'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la résidence "${widget.residence.displayName}" ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ResidenceBloc>().add(DeleteResidence(widget.residence.id));
              // Retourner à la liste des résidences
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
  
  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Copier le lien'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lien copié dans le presse-papier'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Partager par message'),
              onTap: () {
                Navigator.pop(context);
                // Code pour partager par message
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Partager par email'),
              onTap: () {
                Navigator.pop(context);
                // Code pour partager par email
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageGalleryHeader extends StatefulWidget {
  final Residence residence;

  const _ImageGalleryHeader({required this.residence});

  @override
  State<_ImageGalleryHeader> createState() => _ImageGalleryHeaderState();
}

class _ImageGalleryHeaderState extends State<_ImageGalleryHeader> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  double _scale = 1.0;
  Offset _position = Offset.zero;
  bool _isZooming = false;

  @override
  void initState() {
    super.initState();
    // S'assurer que PageController est initialisé correctement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  String _buildImageUrl(String url) {
    if (url.isEmpty) {
      debugPrint('URL de résidence vide détectée');
      return '';
    }
    
    // Vérifier les URLs problématiques
    if (url.contains('placeholder') || url.contains('undefined') || url.contains('null')) {
      debugPrint('URL de résidence problématique détectée: $url');
      return '';
    }
    
    // Si c'est une URL Cloudinary, la retourner telle quelle
    if (url.contains('cloudinary.com') || url.contains('res.cloudinary.com')) {
      debugPrint('URL Cloudinary de résidence détectée: $url');
      return url;
    }
    
    // Si l'URL est déjà complète, la retourner telle quelle
    if (url.startsWith('http')) {
      debugPrint('URL d\'image de résidence déjà complète: $url');
      return url;
    }
    
    // Utiliser AppConfigManager pour construire l'URL complète
    String completeUrl = AppConfigManager.getResidenceImageUrl(url);
    debugPrint('URL de résidence construite: $completeUrl');
    return completeUrl;
  }
  
  void _resetZoom() {
    setState(() {
      _scale = 1.0;
      _position = Offset.zero;
      _isZooming = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Méthode pour filtrer les images problématiques
  List<dynamic> _filterProblematicImages(List<dynamic> images) {
    List<dynamic> filteredImages = [];
    
    // Liste des patterns d'images problématiques
    final problematicPatterns = [
      ...AppConfigManager.getProblematicImagePatterns(),
      ...AppConfigManager.getProblematicResidenceImagePatterns(),
      'placeholder', 'undefined', 'null'
    ];
    
    for (var image in images) {
      String imageStr = image.toString();
      bool isProblematic = false;
      
      // Vérifier si l'image est vide
      if (imageStr.isEmpty) {
        isProblematic = true;
      }
      
      // Vérifier si l'image correspond à un pattern problématique
      for (var pattern in problematicPatterns) {
        if (imageStr.contains(pattern)) {
          isProblematic = true;
          debugPrint('Image problématique filtrée: $imageStr');
          break;
        }
      }
      
      // Ajouter l'image si elle n'est pas problématique
      if (!isProblematic) {
        filteredImages.add(image);
      }
    }
    
    debugPrint('Images filtrées: ${filteredImages.length} sur ${images.length}');
    return filteredImages;
  }
  
  @override
  Widget build(BuildContext context) {
    // Filtrer les images problématiques avant affichage
    final allImages = widget.residence.images;
    final images = _filterProblematicImages(allImages);
    
    debugPrint("Images dans la résidence après filtrage: ${images.length}");
    for (var img in images) {
      debugPrint(" - $img");
    }
    
    if (images.isEmpty) {
      debugPrint("Aucune image valide trouvée pour la résidence ${widget.residence.id}");
      return Container(
        height: 300,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
        ),
      );
    }
    
    return Stack(
      children: [
        // Images carousel
        GestureDetector(
          // Ajouter GestureDetector pour améliorer la réactivité aux gestes
          onHorizontalDragEnd: (details) {
            if (_isZooming) return;
            
            if (details.primaryVelocity! > 0) {
              // Swipe de droite à gauche (précédent)
              if (_currentIndex > 0) {
                _pageController.animateToPage(
                  _currentIndex - 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            } else if (details.primaryVelocity! < 0) {
              // Swipe de gauche à droite (suivant)
              if (_currentIndex < images.length - 1) {
                _pageController.animateToPage(
                  _currentIndex + 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            }
          },
          child: PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            physics: _isZooming ? NeverScrollableScrollPhysics() : null,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _resetZoom();
              });
            },
            itemBuilder: (context, index) {
              final imageUrl = images[index];
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Hero(
                  key: ValueKey<int>(index),
                  tag: 'residence_image_$index',
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onScaleStart: (_) {
                        setState(() {
                          _isZooming = true;
                        });
                      },
                      onScaleUpdate: (details) {
                        setState(() {
                          // Limiter le zoom entre 1.0 et 3.0
                          _scale = (_scale * details.scale).clamp(1.0, 3.0);
                          
                          // Calculer la nouvelle position
                          if (_scale > 1.0) {
                            _position += details.focalPointDelta;
                            
                            // Limiter le panoramique
                            final width = context.size!.width;
                            final height = context.size!.height;
                            final maxDx = width * (_scale - 1) / 2;
                            final maxDy = height * (_scale - 1) / 2;
                            
                            _position = Offset(
                              _position.dx.clamp(-maxDx, maxDx),
                              _position.dy.clamp(-maxDy, maxDy),
                            );
                          }
                        });
                      },
                      onScaleEnd: (_) {
                        if (_scale == 1.0) {
                          setState(() {
                            _isZooming = false;
                          });
                        }
                      },
                      onTap: () {
                        if (_scale > 1.0) {
                          _resetZoom();
                        }
                      },
                      onDoubleTap: () {
                        setState(() {
                          if (_scale > 1.0) {
                            _resetZoom();
                          } else {
                            _scale = 2.0;
                            _isZooming = true;
                          }
                        });
                      },
                      child: Transform.scale(
                        scale: _scale,
                        origin: _position,
                        child: Transform.translate(
                          offset: _position,
                          child: ClipRRect(
                            child: Image.network(
                              _buildImageUrl(imageUrl.toString()),
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Overlay gradient for better text visibility
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),
        // Navigation arrows
        if (images.length > 1 && !_isZooming)
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Flèche gauche (précédent)
                if (_currentIndex > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      tooltip: 'Photo précédente',
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                const Spacer(),
                // Flèche droite (suivant)
                if (_currentIndex < images.length - 1)
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                      tooltip: 'Photo suivante',
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        // Indicators
        if (images.length > 1 && !_isZooming)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _currentIndex == index ? 20 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentIndex == index ? Colors.white : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Aide au zoom
        if (_isZooming)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Touchez pour réinitialiser le zoom',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        // Status badge
        Positioned(
          top: 60,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.residence.isAvailable ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.residence.isAvailable ? 'Disponible' : 'Non disponible',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        // Photo count
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentIndex + 1}/${images.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResidenceStatsBar extends StatelessWidget {
  final Residence residence;

  const _ResidenceStatsBar({required this.residence});

  @override
  Widget build(BuildContext context) {
    final priceFormatter = NumberFormat('#,###', 'fr');
    final formattedPrice = priceFormatter.format(residence.price.toInt());
    
    String pricePeriod = '';
    switch (residence.pricePeriod) {
      case 'hour':
        pricePeriod = '/heure';
        break;
      case 'day':
        pricePeriod = '/jour';
        break;
      case 'week':
        pricePeriod = '/semaine';
        break;
      case 'month':
      default:
        pricePeriod = '/mois';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primary.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$formattedPrice FCFA$pricePeriod',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${residence.address}, ${residence.city}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildStatItem(context, '${residence.bedrooms}', 'Chambres'),
                  const SizedBox(width: 16),
                  _buildStatItem(context, '${residence.bathrooms}', 'SDB'),
                  const SizedBox(width: 16),
                  _buildStatItem(context, '${residence.surface.toInt()}', 'm²'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _EnhancedOverviewTab extends StatefulWidget {
  final Residence residence;

  const _EnhancedOverviewTab({required this.residence});

  @override
  State<_EnhancedOverviewTab> createState() => _EnhancedOverviewTabState();
}

class _EnhancedOverviewTabState extends State<_EnhancedOverviewTab> {
  @override
  Widget build(BuildContext context) {
    final residence = widget.residence;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Description
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(residence.description),
        const SizedBox(height: 24),
        
        // Caractéristiques
        Text(
          'Caractéristiques',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),

        _buildFeatureGrid(context),
        
        const SizedBox(height: 24),
        
        // Tarification
        Card(
          clipBehavior: Clip.antiAlias,
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tarification',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Prix avec sélecteur de devise
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Prix standard:',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Row(
                      children: [
                        Text(
                          widget.residence.formattedPrice,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        CurrencySelectorIcon(
                          onCurrencyChanged: (String newCurrency) {
                            // Forcer la mise à jour de l'interface
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Affichage des conversions
                FutureBuilder<void>(
                  future: Future.delayed(Duration.zero), // Pour déclencher un chargement asynchrone
                  builder: (context, snapshot) {
                    final currencyService = CurrencyService();
                    
                    // N'afficher les conversions que si la devise sélectionnée est différente de la devise d'origine
                    if (currencyService.currentCurrency != widget.residence.currency) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Prix converti: ${currencyService.convertAndFormat(widget.residence.price, widget.residence.currency)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return SizedBox.shrink(); // Ne rien afficher si la devise est la même
                  },
                ),
                
                // Autres informations de prix
                if (widget.residence.pricePeriod.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Période:',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          _getPeriodLabel(widget.residence.pricePeriod),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Type et catégorie
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                  'Catégorisation',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildInfoRow(context, 'Type', residence.typeDisplay),
                _buildInfoRow(context, 'Catégorie', _getCategoryLabel(residence.category)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        
        // Règles et options
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Règles et options',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildRuleRow(context, 'Usage illicite', false),
                _buildRuleRow(context, 'Surveillance cachée', false),
                _buildRuleRow(context, 'Publication non autorisée', false),
                if (residence.maxGuests > 0)
                  _buildInfoRow(context, 'Capacité maximale', 'À respecter'),
              ],
            ),
          ),
        ),
        
        // Section pour les Points d'intérêt à proximité
        if (residence.nearbyPlaces.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Points d\'intérêt à proximité',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                            onPressed: () {
                              // Convertir les Map en objets NearbyPlace
                              final places = residence.nearbyPlaces
                                  .map((map) => NearbyPlace.fromJson(map))
                                  .toList();
                              
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NearbyPlacesEditScreen(
                                    residenceId: residence.id,
                                    initialPlaces: places,
                                  ),
                                ),
                              ).then((updatedPlaces) {
                                if (updatedPlaces != null) {
                                  // Recharger les détails de la résidence pour voir les modifications
                                  context.read<ResidenceBloc>().add(
                                    LoadResidenceDetails(residence.id),
                                  );
                                }
                              });
                            },
                            tooltip: 'Modifier les points d\'intérêt',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...residence.nearbyPlaces.map((place) => _buildNearbyPlaceItem(context, place)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
        // Section pour les FAQ
        if (residence.faqs.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Questions fréquentes',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                            onPressed: () {
                              // Convertir les Map en objets Faq
                              final faqs = residence.faqs
                                  .map((map) => Faq.fromJson(map))
                                  .toList();

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FaqEditScreen(
                                    residenceId: residence.id,
                                    initialFaqs: faqs,
                                  ),
                                ),
                              ).then((updatedFaqs) {
                                if (updatedFaqs != null) {
                                  // Recharger les détails de la résidence pour voir les modifications
                                  setState(() {});
                                  // Rafraîchir les données
                                  context.read<ResidenceBloc>().add(
                                    LoadResidenceDetails(residence.id),
                                  );
                                }
                              });
                            },
                            tooltip: 'Modifier les FAQ',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...residence.faqs.map((faq) => _buildFaqItem(context, faq)),
                    ],
                  ),
                ),
              ),
            ],
          ),
            
        const SizedBox(height: 80), // Espace pour le floating action button
      ],
    );
  }
  
  String _getPeriodLabel(String period) {
    switch (period) {
      case 'hour':
        return 'Heure';
      case 'day':
        return 'Jour';
      case 'week':
        return 'Semaine';
      case 'month':
        return 'Mois';
      default:
        return period;
    }
  }
  
  String _getTypeLabel(String type) {
    if (type.isEmpty) return type;
    switch (type.toLowerCase()) {
      case 'studio_meuble':
        return 'Studio meublé';
      case 'appartement':
      case 'apartment':
        return 'Appartement';
      case 'villa':
        return 'Villa';
      case 'house':
        return 'Maison';
      case 'studio':
        return 'Studio';
      default:
        return type;
    }
  }
  
  String _getCategoryLabel(String category) {
    // Exemple simple, à compléter avec les vrais labels
    switch (category) {
      case 'residence_meublee':
        return 'Résidence meublée';
      case 'residence_vacances':
        return 'Résidence de vacances';
      default:
        return category;
    }
  }
  
  Widget _buildFeatureGrid(BuildContext context) {
    // Créer une liste des équipements disponibles
    final features = <_Feature>[];
    
    // Ajouter les équipements standards si présents
    if (widget.residence.hasPool) features.add(_Feature(Icons.pool, 'Piscine'));
    if (widget.residence.hasWifi) features.add(_Feature(Icons.wifi, 'Wi-Fi'));
    if (widget.residence.hasRestaurant) features.add(_Feature(Icons.restaurant, 'Restaurant'));
    
    // Ajouter les équipements depuis la liste amenities
    if (widget.residence.amenities.isNotEmpty) {
      for (final amenity in widget.residence.amenities) {
        // Mapper les amenities avec des icônes appropriées
        IconData icon;
        String label;
        
        switch (amenity) {
          // Format snake_case comme utilisé dans edit_residence_screen.dart
          case 'running_water':
            icon = Icons.water_drop;
            label = 'Eau courante';
            break;
          case 'hot_water':
            icon = Icons.hot_tub;
            label = 'Eau chaude';
            break;
          case 'water_tank':
            icon = Icons.water;
            label = 'Réservoir d\'eau';
            break;
          case 'electricity':
            icon = Icons.bolt;
            label = 'Électricité';
            break;
          case 'generator':
            icon = Icons.power_settings_new;
            label = 'Générateur';
            break;
          case 'solar_power':
            icon = Icons.wb_sunny;
            label = 'Énergie solaire';
            break;
          case 'inverter':
            icon = Icons.battery_charging_full;
            label = 'Onduleur';
            break;
          case 'air_conditioning':
            icon = Icons.ac_unit;
            label = 'Climatisation';
            break;
          case 'kitchen':
            icon = Icons.kitchen;
            label = 'Cuisine';
            break;
          case 'parking':
            icon = Icons.local_parking;
            label = 'Parking';
            break;
          case 'wifi':
            icon = Icons.wifi;
            label = 'Wi-Fi';
            break;
          case 'pool':
            icon = Icons.pool;
            label = 'Piscine';
            break;
          case 'gym':
            icon = Icons.fitness_center;
            label = 'Salle de sport';
            break;
          case 'spa':
            icon = Icons.spa;
            label = 'Spa';
            break;
          case 'meeting_room':
            icon = Icons.meeting_room;
            label = 'Salle de réunion';
            break;
          case 'terrace':
            icon = Icons.deck;
            label = 'Terrasse';
            break;
          case 'balcony':
            icon = Icons.balcony;
            label = 'Balcon';
            break;
          case 'fiber_optic':
            icon = Icons.wifi;
            label = 'Fibre optique';
            break;
          case 'ethernet':
            icon = Icons.settings_ethernet;
            label = 'Ethernet';
            break;
          case 'full_kitchen':
            icon = Icons.kitchen;
            label = 'Cuisine complète';
            break;
          case 'kitchenette':
            icon = Icons.soup_kitchen;
            label = 'Kitchenette';
            break;
          case 'refrigerator':
            icon = Icons.kitchen;
            label = 'Réfrigérateur';
            break;
          case 'microwave':
            icon = Icons.microwave;
            label = 'Micro-ondes';
            break;
          case 'oven':
            icon = Icons.local_fire_department;
            label = 'Four';
            break;
          case 'fan':
            icon = Icons.air;
            label = 'Ventilateur';
            break;
          case 'ceiling_fan':
            icon = Icons.air;
            label = 'Ventilateur de plafond';
            break;
          case 'alarm_system':
            icon = Icons.security;
            label = 'Système d\'alarme';
            break;
          case 'cctv':
            icon = Icons.videocam;
            label = 'Vidéosurveillance';
            break;
          case 'security_guard':
            icon = Icons.security;
            label = 'Gardien de sécurité';
            break;
          // Ajouter d'autres cas selon vos besoins
          default:
            // Pour les amenities qui n'ont pas de mapping spécifique
            icon = Icons.check_circle;
            // Transformer snake_case en format lisible
            label = amenity.replaceAll('_', ' ').split(' ')
                .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
                .join(' ');
        }
        
        features.add(_Feature(icon, label));
      }
    }
    
    // Ajouter les équipements améliorés (enhancedAmenities)
    if (widget.residence.enhancedAmenities.isNotEmpty) {
      widget.residence.enhancedAmenities.forEach((category, amenities) {
        if (amenities is List && amenities.isNotEmpty) {
          for (final amenity in amenities) {
            if (amenity is String) {
              // Vous pouvez personnaliser les icônes selon les catégories
              IconData icon = Icons.star;
              
              if (category == 'water') {
                icon = Icons.water_drop;
              } else if (category == 'electricity') {
                icon = Icons.electrical_services;
              } else if (category == 'internet') {
                icon = Icons.wifi;
              } else if (category == 'kitchen') {
                icon = Icons.kitchen;
              } else if (category == 'bedroom') {
                icon = Icons.bed;
              } else if (category == 'bathroom') {
                icon = Icons.bathtub;
              }
              
              features.add(_Feature(icon, amenity));
            }
          }
        }
      });
    }
    
    // Ajouter d'autres équipements depuis les options (si disponibles)
    final options = widget.residence.options;
    if (options != null) {
      if (options['hasAirConditioning'] == true) features.add(_Feature(Icons.ac_unit, 'Climatisation'));
      if (options['hasParking'] == true) features.add(_Feature(Icons.local_parking, 'Parking'));
      if (options['hasSecurity'] == true) features.add(_Feature(Icons.security, 'Sécurité'));
      if (options['hasGym'] == true) features.add(_Feature(Icons.fitness_center, 'Salle de sport'));
      if (options['hasSpa'] == true) features.add(_Feature(Icons.spa, 'Spa'));
      if (options['hasTv'] == true) features.add(_Feature(Icons.tv, 'TV'));
      if (options['hasBalcony'] == true) features.add(_Feature(Icons.balcony, 'Balcon'));
      if (options['hasGarden'] == true) features.add(_Feature(Icons.grass, 'Jardin'));
      // Ajouter d'autres équipements selon les besoins
    }
    
    // Si la résidence est meublée
    if (widget.residence.isFurnished) features.add(_Feature(Icons.chair, 'Meublé'));
    
    // Si aucun équipement n'est spécifié
    if (features.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Aucun équipement spécifié'),
        ),
      );
    }
    
    // Afficher les équipements en grille avec défilement
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grille limitée en hauteur avec défilement
        Container(
          constraints: const BoxConstraints(maxHeight: 240), // Hauteur fixe pour montrer qu'il y a du contenu supplémentaire
          child: GridView.builder(
            shrinkWrap: true,
            // Permettre le défilement vertical
            physics: const AlwaysScrollableScrollPhysics(), 
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
        final feature = features[index];
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  feature.icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  feature.label,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
            ),
          ),
          // Indicateur visuel pour montrer qu'on peut défiler
          if (features.length > 9) // Si plus de 9 équipements (3x3 grille initiale)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.keyboard_arrow_down, 
                      size: 16, 
                      color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    Text('Faites défiler pour voir plus',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
  
  Widget _buildPriceRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
                    ),
                  ],
                ),
    );
  }
  
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }
  
  Widget _buildRuleRow(BuildContext context, String label, bool allowed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                allowed ? Icons.check_circle : Icons.cancel,
                color: allowed ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                allowed ? 'Autorisé' : 'Interdit',
                style: const TextStyle(fontSize: 13),
              ),
      ],
          ),
        ],
      ),
    );
  }
  
  // Nouvelle méthode pour construire un item de point d'intérêt
  Widget _buildNearbyPlaceItem(BuildContext context, Map<String, dynamic> place) {
    final name = place['name'] as String? ?? 'Point d\'intérêt';
    final description = place['description'] as String? ?? '';
    final distance = place['distance'] as String? ?? '';
    final category = place['category'] as String? ?? 'general';
    
    IconData icon;
    switch (category.toLowerCase()) {
      case 'restaurant':
      case 'restauration':
        icon = Icons.restaurant;
        break;
      case 'shopping':
      case 'magasin':
        icon = Icons.shopping_bag;
        break;
      case 'transport':
        icon = Icons.directions_bus;
        break;
      case 'loisir':
      case 'divertissement':
        icon = Icons.movie;
        break;
      case 'education':
      case 'école':
        icon = Icons.school;
        break;
      case 'santé':
      case 'hopital':
        icon = Icons.local_hospital;
        break;
      default:
        icon = Icons.place;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (distance.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          distance,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if (description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Nouvelle méthode pour construire un item de FAQ
  Widget _buildFaqItem(BuildContext context, Map<String, dynamic> faq) {
    final question = faq['question'] as String? ?? 'Question';
    final answer = faq['answer'] as String? ?? 'Réponse non disponible';
    
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          question,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        children: [
          Text(
            answer,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final String label;
  
  _Feature(this.icon, this.label);
}

class _EnhancedAvailabilityTab extends StatelessWidget {
  final Residence residence;

  const _EnhancedAvailabilityTab({required this.residence});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statut actuel',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: residence.isAvailable ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      residence.isAvailable ? 'Disponible' : 'Non disponible',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                    ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                      onPressed: () {
                        // Modifier la disponibilité
                        final bool newStatus = !residence.isAvailable;
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: Text(newStatus ? 'Rendre disponible' : 'Rendre indisponible'),
                            content: Text('Êtes-vous sûr de vouloir ${newStatus ? 'rendre disponible' : 'rendre indisponible'} cette résidence?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                  context.read<ResidenceBloc>().add(
                                    UpdateResidenceAvailability(
                                      residence.id,
                                      newStatus,
                                    ),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Statut de disponibilité mis à jour'),
                                    ),
                                  );
                                },
                                child: const Text('Confirmer'),
                              ),
                            ],
                          ),
                        );
                      },
                  icon: const Icon(Icons.edit),
                  label: const Text('Modifier la disponibilité'),
                    ),
                  ],
                ),
          ),
        ),
        
                const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calendrier de disponibilité',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('Le calendrier sera disponible bientôt'),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Ouvrir le gestionnaire de calendrier
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Calendrier de disponibilité'),
                          content: const SizedBox(
                            width: 300,
                            height: 300,
                            child: Center(
                              child: Text('Fonctionnalité à venir dans la prochaine mise à jour'),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Fermer'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Gérer les disponibilités'),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Réservations à venir',
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8), // Espacement pour éviter le débordement
                    Text(
                      '0 réservations',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune réservation à venir',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                ),
              ],
            ),
          ),
        ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 80), // Espace pour le floating action button
      ],
    );
  }
}

class _EnhancedGalleryTab extends StatelessWidget {
  final Residence residence;

  const _EnhancedGalleryTab({required this.residence});

  @override
  Widget build(BuildContext context) {
    final images = residence.images;
    
    return Padding(
          padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Photos (${images.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton.icon(
                    onPressed: () {
                      // Action pour ajouter des photos
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fonctionnalité d\'ajout de photos en développement'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Ajouter'),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Expanded(
            child: images.isEmpty
                ? Center(
              child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                  Text(
                          'Aucune photo disponible',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                  ),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          onPressed: () {
                            // Action pour ajouter des photos
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Fonctionnalité d\'ajout de photos en développement'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Text('Ajouter des photos'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: images.length,
                      itemBuilder: (context, index) {
                      final imageUrl = images[index];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              AppConfigManager.getResidenceImageUrl(imageUrl.toString()),
                              height: double.infinity,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                tooltip: 'Supprimer la photo',
                                onPressed: () {
                                  // Action pour supprimer la photo
                                  showDialog(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: const Text('Supprimer cette photo'),
                                      content: const Text(
                                        'Êtes-vous sûr de vouloir supprimer cette photo ? Cette action est irréversible.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dialogContext),
                                          child: const Text('Annuler'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(dialogContext);
                                            context.read<ResidenceBloc>().add(
                                              DeleteResidencePhoto(
                                                residence.id,
                                                imageUrl: imageUrl.toString(),
                                              ),
                                            );
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Photo supprimée avec succès'),
                                              ),
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('Supprimer'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                constraints: const BoxConstraints.tightFor(
                                  width: 36,
                                  height: 36,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                    ),
                  ),
                ],
                      );
                    },
            ),
          ),
      ],
      ),
    );
  }
}

class _EnhancedReviewsTab extends StatelessWidget {
  final Residence residence;

  const _EnhancedReviewsTab({required this.residence});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section de la note globale
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Note globale',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _getRatingColor(residence.rating),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            residence.rating.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ...List.generate(5, (index) {
                                    return Icon(
                                      index < residence.rating.floor() ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: 24,
                                    );
                                  }),
                                ],
                              ),
                              const SizedBox(height: 8),
                              BlocBuilder<ReviewBloc, ReviewState>(
                                builder: (context, state) {
                                  int reviewCount = residence.reviewCount;
                                  if (state is ReviewsLoaded) {
                                    reviewCount = state.reviews.length;
                                  }
                                  return Text(
                                    'Basé sur $reviewCount avis',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Section des statistiques par catégorie
            BlocBuilder<ReviewBloc, ReviewState>(
              builder: (context, state) {
                // On affiche les stats uniquement si nous avons les statistiques chargées
                if (state is ReviewStatsLoaded) {
                  return Card(
                    margin: const EdgeInsets.only(top: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notes détaillées',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          _buildRatingCategory(context, 'Propreté', 
                              state.stats['cleanliness']?.toDouble() ?? 0.0),
                          _buildRatingCategory(context, 'Confort', 
                              state.stats['comfort']?.toDouble() ?? 0.0),
                          _buildRatingCategory(context, 'Équipements', 
                              state.stats['facilities']?.toDouble() ?? 0.0),
                          _buildRatingCategory(context, 'Rapport qualité/prix', 
                              state.stats['value']?.toDouble() ?? 0.0),
                          _buildRatingCategory(context, 'Emplacement', 
                              state.stats['location']?.toDouble() ?? 0.0),
                        ],
                      ),
                    ),
                  );
                } else if (residence.stars > 0) {
                  // Sinon, on utilise les valeurs statiques comme auparavant
                  return Card(
                    margin: const EdgeInsets.only(top: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notes détaillées',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          _buildRatingCategory(context, 'Propreté', 4.7),
                          _buildRatingCategory(context, 'Confort', 4.5),
                          _buildRatingCategory(context, 'Équipements', 4.2),
                          _buildRatingCategory(context, 'Rapport qualité/prix', 4.6),
                          _buildRatingCategory(context, 'Emplacement', 4.3),
                        ],
                      ),
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Section de la liste des avis
            BlocBuilder<ReviewBloc, ReviewState>(
              builder: (context, state) {
                // État de chargement des avis
                if (state is ReviewsLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                // État d'erreur de chargement
                if (state is ReviewsLoadFailure) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text('Erreur: ${state.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<ReviewBloc>().add(
                                RefreshReviews(residence.id),
                              );
                            },
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                // État des avis chargés avec succès
                if (state is ReviewsLoaded) {
                  if (state.reviews.isEmpty) {
                    // Aucun avis disponible
                    return Container(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.rate_review_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun avis pour le moment',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Les avis de vos clients apparaîtront ici',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  // Affichage de la liste des avis
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Avis récents (${state.reviews.length})',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (state.hasMore)
                            TextButton(
                              onPressed: () {
                                context.read<ReviewBloc>().add(
                                  LoadMoreReviews(
                                    residence.id,
                                    page: state.page + 1,
                                  ),
                                );
                              },
                              child: const Text('Voir plus'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Liste des avis avec possibilité de réponse
                      ...state.reviews.map((review) {
                        return ReviewItemWidget(
                          review: review,
                        );
                      }).toList(),
                      
                      // Chargement de plus d'avis
                      if (state is ReviewsLoadingMore)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  );
                }
                
                // État par défaut (initial)
                return Container(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Chargement des avis...',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 80), // Espace pour le floating action button
          ],
        ),
      ),
    );
  }
  
  // Méthode pour afficher une catégorie de notation
  Widget _buildRatingCategory(BuildContext context, String category, double rating) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              category,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  height: 8,
                  width: 220 * (rating / 5), // Largeur proportionnelle à la note
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getRatingColor(rating),
                        _getRatingColor(rating).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 4.0) return Colors.lightGreen;
    if (rating >= 3.5) return Colors.amber;
    if (rating >= 3.0) return Colors.orange;
    return Colors.red;
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}

/// Onglet de gestion des promotions pour une résidence
class _EnhancedPromotionsTab extends StatefulWidget {
  final Residence residence;

  const _EnhancedPromotionsTab({required this.residence});

  @override
  State<_EnhancedPromotionsTab> createState() => _EnhancedPromotionsTabState();
}

class _EnhancedPromotionsTabState extends State<_EnhancedPromotionsTab> {
  late PromotionBloc _promotionBloc;

  @override
  void initState() {
    super.initState();
    
    // Obtenir et stocker l'instance du PromotionBloc pour une utilisation ultérieure
    _promotionBloc = context.read<PromotionBloc>();
    
    // Charger les promotions de cette résidence au démarrage
    _promotionBloc.add(LoadResidencePromotions(widget.residence.id));
  }
  
  /// Afficher le formulaire de création/édition de promotion
  void _showPromotionForm(BuildContext context, {PromotionModel? promotion}) {
    // Récupérer le bloc depuis le contexte racine pour éviter l'erreur
    final promotionBloc = context.read<PromotionBloc>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: promotionBloc, // Utiliser l'instance récupérée précédemment
        child: PromotionFormDialog(
          residenceId: widget.residence.id,
          promotion: promotion,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Rafraîchir la liste des promotions après création/modification
        promotionBloc.add(LoadResidencePromotions(widget.residence.id));
      }
    });
  }
  
  /// Afficher la confirmation de suppression d'une promotion
  void _showDeleteConfirmation(BuildContext context, PromotionModel promotion) {
    // Récupérer le bloc depuis le contexte racine pour éviter l'erreur
    final promotionBloc = context.read<PromotionBloc>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer la promotion'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la promotion "${promotion.title}" ? Cette action est irréversible.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              promotionBloc.add(DeletePromotion(promotion.id));
              Navigator.of(dialogContext).pop(true);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    ).then((result) {
      if (result == true) {
        // Rafraîchir la liste après suppression
        promotionBloc.add(LoadResidencePromotions(widget.residence.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // En-tête avec titre et bouton d'ajout (non scrollable)
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Promotions et offres spéciales',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => _showPromotionForm(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0), // Ajouter un grand padding en bas pour éviter le FAB
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    'Créez des promotions pour attirer plus de clients et augmenter vos réservations. '
                    'Vous pouvez offrir des réductions, des offres spéciales ou des packages exclusifs.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  
                  // Liste des promotions
                  BlocProvider.value(
                    value: context.read<PromotionBloc>(),
                    child: PromotionsListWidget(
                      residenceId: widget.residence.id,
                      showControls: true,
                      showEmptyMessage: true,
                      physics: const NeverScrollableScrollPhysics(), // Désactiver le défilement interne
                      emptyMessage: 'Aucune promotion n\'a été créée pour cette résidence',
                      onPromotionEdit: (promotion) => _showPromotionForm(context, promotion: promotion),
                      onPromotionDelete: (promotion) => _showDeleteConfirmation(context, promotion),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
