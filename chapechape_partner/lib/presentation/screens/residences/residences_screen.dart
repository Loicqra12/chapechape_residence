import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../../core/blocs/residence/residence_bloc.dart';
import '../../../core/models/residence/residence.dart';
import '../../../core/models/residence/residence_extensions.dart';
import '../../../core/services/api/residence_service.dart';
import '../../../core/config/app_config_manager.dart';
import 'edit_residence_screen.dart';
import '../../widgets/layout/screen_app_bars.dart';
import 'residence_details_screen.dart'; // Importer l'écran de détail
import '../../../core/constants/app_images.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/optimized_image.dart';
import '../../../core/utils/string_utils.dart';
import '../../../core/services/event_bus/residence_event_bus.dart';
import '../../widgets/residence/residence_grid_widget.dart';

class ResidencesScreen extends StatelessWidget {
  const ResidencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Créer un nouveau bloc avec le service de résidence
    // tout en s'assurant qu'il est configuré avec le bus d'événements
    final residenceService = ResidenceService(
      baseUrl: AppConfigManager.apiUrl,
    );
    
    return BlocProvider(
      create: (context) {
        // Créer un nouveau bloc avec le service
        final bloc = ResidenceBloc(residenceService);
        
        // Écouter le bus d'événements pour les résidences (plutôt que subscribe qui n'existe pas)
        // Cette ligne sera gérée directement dans le bloc, on peut la retirer ici
        
        // Charger les résidences
        bloc.add(RefreshResidences());
        
        return bloc;
      },
      child: const _ResidencesView(),
    );
  }
}

class _ResidencesView extends StatefulWidget {
  const _ResidencesView();

  @override
  State<_ResidencesView> createState() => _ResidencesViewState();
}

class _ResidencesViewState extends State<_ResidencesView> {
  String _sortBy = 'date'; // Par défaut, tri par date de création
  String _viewMode = 'list'; // Par défaut, vue en liste
  String _filterStatus = 'all'; // Par défaut, toutes les résidences
  StreamSubscription? _eventBusSubscription;

  void _loadResidences() {
    // Utiliser RefreshResidences pour forcer un rafraîchissement complet
    context.read<ResidenceBloc>().add(RefreshResidences());
  }
  
  @override
  void initState() {
    super.initState();
    
    // S'abonner au bus d'événements pour les résidences
    _eventBusSubscription = ResidenceEventBus().stream.listen((event) {
      debugPrint('🔔 ResidencesScreen: Événement reçu: $event');
      
      // Rafraîchir la liste des résidences lorsqu'un événement est reçu
      _loadResidences();
    });
  }
  
  @override
  void dispose() {
    // Se désabonner du bus d'événements pour éviter les fuites mémoire
    _eventBusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          ScreenAppBars.getResidencesAppBar(context),
          SliverToBoxAdapter(
            child: BlocBuilder<ResidenceBloc, ResidenceState>(
              builder: (context, state) {
                if (state is ResidenceLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is ResidenceError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          state.isNetworkError 
                              ? Icons.signal_wifi_off
                              : state.isAuthError
                                  ? Icons.lock
                                  : Icons.error_outline,
                          size: 48,
                          color: state.isNetworkError || state.isAuthError
                              ? Colors.orange
                              : Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _loadResidences,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                        ),
                        if (state.isAuthError)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: TextButton(
                              onPressed: () {
                                // Rediriger vers la page de connexion
                                Navigator.of(context).pushReplacementNamed('/login');
                              },
                              child: const Text('Se reconnecter'),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                if (state is ResidenceLoaded) {
                  final residences = state.residences;
                  
                  if (residences.isEmpty) {
                    return _buildEmptyState(context);
                  }
                  
                  // Diviser les résidences par statut
                  final availableResidences = residences.where((r) => r.isAvailable).toList();
                  final unavailableResidences = residences.where((r) => !r.isAvailable).toList();
                  
                  // Appliquer le tri sélectionné
                  _sortResidences(availableResidences);
                  _sortResidences(unavailableResidences);
                  
                  return RefreshIndicator(
                    onRefresh: () async => _loadResidences(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Options de filtrage et tri
                            _buildFilterOptions(context, residences.length),
                            const SizedBox(height: 16),
                            
                            // Afficher les résidences selon le filtre sélectionné et le mode d'affichage
                            if (_filterStatus == 'all' || _filterStatus == 'available')
                              if (availableResidences.isNotEmpty) ...[
                                _buildSectionTitle(context, 'Résidences disponibles', availableResidences.length),
                                const SizedBox(height: 8),
                                
                                // Mode d'affichage en liste ou en grille
                                if (_viewMode == 'list')
                                  Container(
                                    height: MediaQuery.of(context).size.height * 0.6,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      physics: const ClampingScrollPhysics(),
                                      itemCount: availableResidences.length,
                                      itemBuilder: (context, index) {
                                        return _buildEnhancedResidenceCard(
                                          context, 
                                          availableResidences[index]
                                        );
                                      },
                                    ),
                                  )
                                else
                                  SizedBox(
                                    // Définir une hauteur pour la grille
                                    height: availableResidences.length > 2 
                                        ? MediaQuery.of(context).size.height * 0.6 
                                        : MediaQuery.of(context).size.height * 0.3,
                                    child: ResidenceGridWidget(
                                      residences: availableResidences,
                                      onResidenceTap: (residence) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ResidenceDetailsScreen(residence: residence),
                                          ),
                                        );
                                      },
                                      onDeleteTap: (residence) => _deleteResidence(context, residence),
                                    ),
                                  ),
                                
                                const SizedBox(height: 16),
                              ],
                              
                            if (_filterStatus == 'all' || _filterStatus == 'unavailable')
                              if (unavailableResidences.isNotEmpty) ...[
                                _buildSectionTitle(context, 'Résidences non disponibles', unavailableResidences.length),
                                const SizedBox(height: 8),
                                
                                // Mode d'affichage en liste ou en grille
                                if (_viewMode == 'list')
                                  Container(
                                    height: MediaQuery.of(context).size.height * 0.6,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      physics: const ClampingScrollPhysics(),
                                      itemCount: unavailableResidences.length,
                                      itemBuilder: (context, index) {
                                        return _buildEnhancedResidenceCard(
                                          context, 
                                          unavailableResidences[index]
                                        );
                                      },
                                    ),
                                  )
                                else
                                  SizedBox(
                                    // Définir une hauteur pour la grille
                                    height: unavailableResidences.length > 2 
                                        ? MediaQuery.of(context).size.height * 0.6 
                                        : MediaQuery.of(context).size.height * 0.3,
                                    child: ResidenceGridWidget(
                                      residences: unavailableResidences,
                                      onResidenceTap: (residence) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ResidenceDetailsScreen(residence: residence),
                                          ),
                                        );
                                      },
                                      onDeleteTap: (residence) => _deleteResidence(context, residence),
                                    ),
                                  ),
                              ],
                            // Bouton pour ajouter une nouvelle résidence
                            const SizedBox(height: 24),
                            _buildAddResidenceCard(context),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return const Center(
                  child: Text('Chargement des résidences...'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterOptions(BuildContext context, int totalCount) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterStatus,
                    isDense: true,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('Toutes ($totalCount)'),
                      ),
                      DropdownMenuItem(
                        value: 'available',
                        child: Text('Disponibles'),
                      ),
                      DropdownMenuItem(
                        value: 'unavailable',
                        child: Text('Non disponibles'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterStatus = value!;
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    isDense: true,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'date',
                        child: Text('Date'),
                      ),
                      DropdownMenuItem(
                        value: 'price_asc',
                        child: Text('Prix croissant'),
                      ),
                      DropdownMenuItem(
                        value: 'price_desc',
                        child: Text('Prix décroissant'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _sortBy = value!;
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Boutons de changement de vue
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('Vue :'),
            const SizedBox(width: 8),
            ToggleButtons(
              isSelected: [_viewMode == 'list', _viewMode == 'grid'],
              onPressed: (index) {
                setState(() {
                  _viewMode = index == 0 ? 'list' : 'grid';
                });
              },
              borderRadius: BorderRadius.circular(8),
              selectedColor: Theme.of(context).colorScheme.onPrimary,
              fillColor: Theme.of(context).colorScheme.primary,
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.view_list),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.grid_view),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _sortResidences(List<Residence> residences) {
    switch (_sortBy) {
      case 'price_asc':
        residences.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        residences.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'date':
      default:
        residences.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
    }
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.home_work_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Vous n\'avez pas encore de résidences',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Commencez par ajouter votre première résidence pour la mettre en location.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditResidenceScreen(),
                ),
              ).then((_) => _loadResidences());
            },
            icon: const Icon(Icons.add_home_outlined),
            label: const Text('Ajouter une résidence'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAddResidenceCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditResidenceScreen(),
            ),
          ).then((_) => _loadResidences());
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_home,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Ajouter une nouvelle résidence',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedResidenceCard(BuildContext context, Residence residence) {
    // Statut de la résidence
    final bool isAvailable = residence.isAvailable;
    final Color statusColor = isAvailable ? Colors.green : Colors.orange;
    final String statusText = isAvailable ? 'Disponible' : 'Non disponible';
    
    // Debug: afficher les données brutes pour comprendre la structure des images
    print('====== DÉTAILS DE LA RÉSIDENCE ======');
    print('Residence ID: ${residence.id}');
    print('mainImage: ${residence.mainImage}');
    print('images list: ${residence.images}');
    
    // Récupérer l'URL de l'image directement
    String imageUrl = residence.mainImage ?? '';
    if (imageUrl.isEmpty && residence.images.isNotEmpty) {
      if (residence.images.first is String) {
        imageUrl = residence.images.first as String;
      } else if (residence.images.first is Map) {
        final imgMap = residence.images.first as Map;
        imageUrl = imgMap['url'] ?? '';
      }
    }
    
    // Ajouter le domaine si nécessaire
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      // Récupérer l'URL de base en enlevant /api si présent
      String baseUrl = AppConfigManager.apiUrl;
      if (baseUrl.endsWith("/api")) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 4);
      }
      
      // Construire l'URL complète
      if (imageUrl.startsWith('/')) {
        if (imageUrl.startsWith('/uploads/') && !imageUrl.startsWith('/uploads/residences/')) {
          imageUrl = imageUrl.replaceAll('/uploads/', '/uploads/residences/');
        }
        imageUrl = '$baseUrl$imageUrl';
      } else {
        imageUrl = '$baseUrl/uploads/residences/$imageUrl';
      }
    }
    
    // Si c'est une URL complète, ajouter /residences/ si nécessaire
    if (imageUrl.startsWith('http') && imageUrl.contains('/uploads/') && !imageUrl.contains('/uploads/residences/')) {
      imageUrl = imageUrl.replaceAll('/uploads/', '/uploads/residences/');
    }
    
    print('URL finale de l\'image: $imageUrl');
    
    // Formatage du prix avec le séparateur de milliers
    final priceFormatter = NumberFormat('#,###', 'fr');
    final String formattedPrice = priceFormatter.format(residence.price.toInt());
    
    // Déterminer la période du prix
    String pricePeriod;
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

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // Vérifier d'abord si la résidence existe avant de naviguer
          context
            .read<ResidenceBloc>()
            .add(
              CheckResidenceExists(
                residence.id,
                onSuccess: (exists) {
                  if (exists) {
                    // Obtenir une référence au service pour le passer à l'écran de détails
                    final residenceService = ResidenceService(baseUrl: AppConfigManager.apiUrl);
                    
                    // Utiliser MaterialPageRoute avec BlocProvider
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider(
                          create: (context) => ResidenceBloc(residenceService),
                          child: ResidenceDetailsScreen(residence: residence),
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cette résidence n\'existe plus'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                onError: (errorMessage) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $errorMessage'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              ),
            );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image et informations de base
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          // Désactiver le cache complètement
                          cacheHeight: null,
                          cacheWidth: null,
                          // Ajouter un timestamp pour éviter tout cache
                          headers: {
                            'Cache-Control': 'no-cache, no-store, must-revalidate',
                            'Pragma': 'no-cache',
                            'Expires': '0',
                            'If-Modified-Since': DateTime.now().toUtc().toString(),
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('ERREUR CHARGEMENT IMAGE: $error');
                            print('URL qui a causé l\'erreur: $imageUrl');
                            return Container(
                              height: 180,
                              width: double.infinity,
                              color: Colors.grey[300],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                  const SizedBox(height: 8),
                                  Text('Erreur: $error', textAlign: TextAlign.center),
                                ],
                              ),
                            );
                          },
                        )
                      : Container(
                          height: 180,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Icon(Icons.home, size: 50, color: Colors.grey),
                        ),
                ),
                // Badge de statut
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Informations de la résidence
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          residence.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$formattedPrice FCFA$pricePeriod',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${residence.address}, ${residence.city}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Caractéristiques
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFeatureItem(context, Icons.bedroom_parent_outlined, '${residence.bedrooms} chambre${residence.bedrooms > 1 ? 's' : ''}'),
                      _buildFeatureItem(context, Icons.bathroom_outlined, '${residence.bathrooms} salle${residence.bathrooms > 1 ? 's' : ''} de bain'),
                      _buildFeatureItem(context, Icons.square_foot, '${residence.surface.toInt()} m²'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Statistiques simplifiées
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(context, '0', 'Réservations'),
                        // 🚫 TEMPORAIREMENT MASQUÉ POUR GOOGLE PLAY SUBMISSION
                        // _buildStatItem(context, '0 FCFA', 'Revenus'),
                        _buildStatItem(context, '${residence.reviewCount} avis', '${residence.rating} ★'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditResidenceScreen(
                                residence: residence,
                              ),
                            ),
                          ).then((_) => _loadResidences()),
                          icon: const Icon(Icons.edit),
                        label: const Text('Modifier'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _deleteResidence(context, residence),
                        icon: const Icon(Icons.delete),
                        label: const Text('Supprimer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          minimumSize: const Size(0, 40),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
  
  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
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

  Future<void> _deleteResidence(BuildContext context, Residence residence) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la résidence'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la résidence "${residence.name}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final bloc = context.read<ResidenceBloc>();
      bloc.add(DeleteResidence(residence.id));
      
      // Attendre un court instant pour que la suppression soit traitée
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Forcer un rechargement complet
      _loadResidences();
    }
  }
}
