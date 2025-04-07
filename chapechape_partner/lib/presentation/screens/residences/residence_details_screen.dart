import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/blocs/residence/residence_bloc.dart';
import '../../../core/models/residence/residence.dart';
import '../../../core/models/residence/residence_extensions.dart';
import '../../../core/services/api/residence_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/app_images.dart';
import 'edit_residence_screen.dart';
import '../../widgets/layout/screen_app_bars.dart';

class ResidenceDetailsScreen extends StatelessWidget {
  final Residence residence;

  const ResidenceDetailsScreen({
    super.key,
    required this.residence,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ResidenceBloc(
        ResidenceService(baseUrl: AppConfig.apiUrl),
      )..add(CheckResidenceExists(residence.id, 
          onSuccess: (exists) {
            if (exists) {
              context.read<ResidenceBloc>().add(LoadResidenceDetails(residence.id));
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
              appBar: AppBar(title: Text(residence.name)),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          
          return DefaultTabController(
            length: 4,
            child: Scaffold(
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      expandedHeight: 240.0,
                      floating: false,
                      pinned: true,
                title: Text(residence.name),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditResidenceScreen(
                                residence: residence,
                              ),
                            ),
                          ).then((_) {
                            // Rafraîchir les données après l'édition
                              context.read<ResidenceBloc>().add(CheckResidenceExists(
                                residence.id, 
                                onSuccess: (exists) {
                                  if (exists) {
                                    context.read<ResidenceBloc>().add(LoadResidenceDetails(residence.id));
                                  }
                                }
                              ));
                          });
                        },
                        ),
                        PopupMenuButton<String>(
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
                        background: _ImageGalleryHeader(residence: residence),
                      ),
                    ),
                    SliverPersistentHeader(
                      delegate: _SliverTabBarDelegate(
                        TabBar(
                          labelColor: Theme.of(context).colorScheme.primary,
                          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicatorWeight: 3,
                          tabs: const [
                            Tab(icon: Icon(Icons.home_outlined), text: 'Aperçu'),
                            Tab(icon: Icon(Icons.calendar_month_outlined), text: 'Disponibilités'),
                            Tab(icon: Icon(Icons.photo_library_outlined), text: 'Galerie'),
                            Tab(icon: Icon(Icons.star_outline), text: 'Avis'),
                  ],
                ),
              ),
                      pinned: true,
                    ),
                    // Ajouter une section de résumé clé en dessous des onglets
                    SliverToBoxAdapter(
                      child: _ResidenceStatsBar(residence: residence),
                    ),
                  ];
                },
              body: TabBarView(
                children: [
                  // Onglet Aperçu
                    _EnhancedOverviewTab(residence: residence),
                  // Onglet Disponibilités
                    _EnhancedAvailabilityTab(residence: residence),
                  // Onglet Galerie
                    _EnhancedGalleryTab(residence: residence),
                  // Onglet Avis
                    _EnhancedReviewsTab(residence: residence),
                ],
                ),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditResidenceScreen(
                        residence: residence,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Modifier'),
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
          'Êtes-vous sûr de vouloir supprimer la résidence "${residence.name}" ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ResidenceBloc>().add(DeleteResidence(residence.id));
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

  String _getFullImageUrl(String url) {
    if (url.startsWith('http')) {
      // L'URL est déjà complète
      return url;
    }
    
    // Vérifier si l'URL commence par /uploads
    if (url.startsWith('/uploads/')) {
      // C'est un chemin relatif correct, ajouter juste le domaine
      return 'http://localhost:4000${url}';
    } else if (url.startsWith('/')) {
      // URL relative mais sans uploads, ajouter le chemin complet
      return 'http://localhost:4000${url}';
    } else {
      // URL sans slash initial, ajouter le chemin complet avec slash
      return 'http://localhost:4000/uploads/residences/${url}';
    }
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

  String _getFullImageUrl(String url) {
    if (url.startsWith('http')) {
      // L'URL est déjà complète
      return url;
    }
    
    // Vérifier si l'URL commence par /uploads
    if (url.startsWith('/uploads/')) {
      // C'est un chemin relatif correct, ajouter juste le domaine
      return 'http://localhost:4000${url}';
    } else if (url.startsWith('/')) {
      // URL relative mais sans uploads, ajouter le chemin complet
      return 'http://localhost:4000${url}';
    } else {
      // URL sans slash initial, ajouter le chemin complet avec slash
      return 'http://localhost:4000/uploads/residences/${url}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.residence.images;
    
    print("Images dans la résidence: ${images.length}");
    for (var img in images) {
      print(" - $img");
    }
    
    if (images.isEmpty) {
      print("Aucune image trouvée pour la résidence ${widget.residence.id}");
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
        PageView.builder(
          controller: _pageController,
          itemCount: images.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final imageUrl = images[index];
            print("Chargement de l'image $index: $imageUrl");
            return Image.network(
              _getFullImageUrl(imageUrl.toString()),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print("Erreur de chargement d'image: $error pour URL $imageUrl");
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  ),
                );
              },
            );
          },
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
                Colors.black.withOpacity(0.7),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Indicators
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index ? Colors.white : Colors.white.withOpacity(0.5),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
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
                Text(
                      '$formattedPrice FCFA$pricePeriod',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                    const SizedBox(height: 4),
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
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _EnhancedOverviewTab extends StatelessWidget {
  final Residence residence;

  const _EnhancedOverviewTab({required this.residence});

  @override
  Widget build(BuildContext context) {
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tarification',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildPriceRow(context, 'Prix standard', '${NumberFormat('#,###', 'fr').format(residence.price.toInt())} FCFA/${_getPeriodLabel(residence.pricePeriod)}'),
                if (residence.hourlyRate > 0)
                  _buildPriceRow(context, 'Tarif horaire', '${NumberFormat('#,###', 'fr').format(residence.hourlyRate.toInt())} FCFA/heure'),
                if (residence.halfDayRate > 0)
                  _buildPriceRow(context, 'Tarif demi-journée', '${NumberFormat('#,###', 'fr').format(residence.halfDayRate.toInt())} FCFA'),
                if (residence.fullDayRate > 0)
                  _buildPriceRow(context, 'Tarif journée', '${NumberFormat('#,###', 'fr').format(residence.fullDayRate.toInt())} FCFA/jour'),
                if (residence.weekendRate > 0)
                  _buildPriceRow(context, 'Tarif weekend', '${NumberFormat('#,###', 'fr').format(residence.weekendRate.toInt())} FCFA/weekend'),
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
                _buildInfoRow(context, 'Type', _getTypeLabel(residence.type)),
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
                _buildRuleRow(context, 'Fumeurs', residence.allowsSmoking),
                _buildRuleRow(context, 'Animaux', residence.allowsPets),
                _buildRuleRow(context, 'Événements', residence.allowsParties),
                if (residence.maxGuests > 0)
                  _buildInfoRow(context, 'Capacité maximale', '${residence.maxGuests} personnes'),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 80), // Espace pour le floating action button
      ],
    );
  }
  
  String _getPeriodLabel(String period) {
    switch (period) {
      case 'hour':
        return 'heure';
      case 'day':
        return 'jour';
      case 'week':
        return 'semaine';
      case 'month':
      default:
        return 'mois';
    }
  }
  
  String _getTypeLabel(String type) {
    // Exemple simple, à compléter avec les vrais labels
    switch (type) {
      case 'studio_meuble':
        return 'Studio meublé';
      case 'appartement':
        return 'Appartement';
      case 'villa':
        return 'Villa';
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
    if (residence.hasPool) features.add(_Feature(Icons.pool, 'Piscine'));
    if (residence.hasWifi) features.add(_Feature(Icons.wifi, 'Wi-Fi'));
    if (residence.hasRestaurant) features.add(_Feature(Icons.restaurant, 'Restaurant'));
    
    // Ajouter d'autres équipements depuis les options (si disponibles)
    final options = residence.options;
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
    if (residence.isFurnished) features.add(_Feature(Icons.chair, 'Meublé'));
    
    // Si aucun équipement n'est spécifié
    if (features.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Aucun équipement spécifié'),
        ),
      );
    }
    
    // Afficher les équipements en grille
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
                  children: [
              Icon(feature.icon, size: 20, color: Theme.of(context).colorScheme.primary),
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
          Text(label),
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
          Text(label),
          Row(
            children: [
              Icon(
                allowed ? Icons.check_circle : Icons.cancel,
                color: allowed ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(allowed ? 'Autorisé' : 'Non autorisé'),
      ],
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
                    Text(
                      'Réservations à venir',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
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

  String _getFullImageUrl(String url) {
    if (url.startsWith('http')) {
      // L'URL est déjà complète
      return url;
    }
    
    // Vérifier si l'URL commence par /uploads
    if (url.startsWith('/uploads/')) {
      // C'est un chemin relatif correct, ajouter juste le domaine
      return 'http://localhost:4000${url}';
    } else if (url.startsWith('/')) {
      // URL relative mais sans uploads, ajouter le chemin complet
      return 'http://localhost:4000${url}';
    } else {
      // URL sans slash initial, ajouter le chemin complet avec slash
      return 'http://localhost:4000/uploads/residences/${url}';
    }
  }

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
                        OutlinedButton.icon(
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
                          label: const Text('Ajouter des photos'),
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
                              _getFullImageUrl(imageUrl.toString()),
                              height: double.infinity,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print("Erreur de chargement d'image: $error pour URL $imageUrl");
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                        Text(
                              'Basé sur ${residence.reviewCount} avis',
                          style: Theme.of(context).textTheme.bodyMedium,
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
          
        const SizedBox(height: 16),
          
          if (residence.reviewCount > 0)
            Text(
              'Avis récents',
              style: Theme.of(context).textTheme.titleLarge,
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
            ),
            
          const SizedBox(height: 80), // Espace pour le floating action button
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
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
