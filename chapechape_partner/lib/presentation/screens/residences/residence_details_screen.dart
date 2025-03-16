import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/blocs/residence/residence_bloc.dart';
import '../../../core/models/residence/residence.dart';
import '../../../core/extensions/residence_extensions.dart';
import '../../../core/services/api/residence_service.dart';
import '../../../core/config/app_config.dart';
import 'edit_residence_screen.dart';

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
          onSuccess: () {}, 
          onError: () {
            // Si la résidence n'existe plus, afficher un message et retourner
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cette résidence n\'existe plus ou a été supprimée.'),
                duration: Duration(seconds: 3),
              ),
            );
            // Retourner à la page précédente après un court délai
            Future.delayed(const Duration(milliseconds: 500), () {
              Navigator.of(context).pop();
            });
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
              appBar: AppBar(
                title: Text(residence.name),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // Vérifier si la résidence existe encore avant d'éditer
                      context.read<ResidenceBloc>().add(CheckResidenceExists(
                        residence.id,
                        onSuccess: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditResidenceScreen(
                                residence: residence,
                              ),
                            ),
                          ).then((_) {
                            // Rafraîchir les données après l'édition
                            context.read<ResidenceBloc>().add(CheckResidenceExists(residence.id, onSuccess: () {}));
                          });
                        },
                      ));
                    },
                  ),
                ],
                bottom: const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Aperçu'),
                    Tab(text: 'Disponibilités'),
                    Tab(text: 'Galerie'),
                    Tab(text: 'Avis'),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  // Onglet Aperçu
                  _OverviewTab(residence: residence),
                  // Onglet Disponibilités
                  _AvailabilityTab(residence: residence),
                  // Onglet Galerie
                  _GalleryTab(residence: residence),
                  // Onglet Avis
                  _ReviewsTab(residence: residence),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Residence residence;

  const _OverviewTab({required this.residence});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Carte d'informations principales
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informations générales',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Nom'),
                  subtitle: Text(residence.name),
                ),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Description'),
                  subtitle: Text(residence.description),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Adresse'),
                  subtitle: Text(residence.address),
                ),
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Prix'),
                  subtitle: Text(
                    residence.priceDisplay,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Carte des équipements
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Équipements',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (residence.hasWifi) _buildFeatureItem(Icons.wifi, 'WiFi'),
                    if (residence.hasPool) _buildFeatureItem(Icons.pool, 'Piscine'),
                    if (residence.hasRestaurant) _buildFeatureItem(Icons.restaurant, 'Restaurant'),
                    if (residence.isVacationResidence) _buildFeatureItem(Icons.beach_access, 'Résidence de vacances'),
                    if (residence.isSpecialResidence) _buildFeatureItem(Icons.star, 'Résidence spéciale'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Carte des statistiques
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistiques',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      icon: Icons.star,
                      value: residence.rating.toString(),
                      label: 'Note moyenne',
                      color: Colors.amber,
                    ),
                    _StatItem(
                      icon: Icons.reviews,
                      value: residence.reviewCount.toString(),
                      label: 'Avis',
                      color: Colors.blue,
                    ),
                    _StatItem(
                      icon: Icons.visibility,
                      value: '0', // TODO: Ajouter le nombre de vues
                      label: 'Vues',
                      color: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AvailabilityTab extends StatelessWidget {
  final Residence residence;

  const _AvailabilityTab({required this.residence});

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Disponibilité',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    FilledButton.icon(
                      icon: const Icon(Icons.edit_calendar),
                      label: const Text('Gérer'),
                      onPressed: () {
                        // TODO: Ouvrir le gestionnaire de disponibilités
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // TODO: Ajouter le calendrier des disponibilités
                const Center(
                  child: Text('Calendrier en cours de développement...'),
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
                      'Tarification',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    FilledButton.icon(
                      icon: const Icon(Icons.price_change),
                      label: const Text('Modifier'),
                      onPressed: () {
                        // TODO: Ouvrir le gestionnaire de tarifs
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // TODO: Ajouter la grille des tarifs
                const Center(
                  child: Text('Grille tarifaire en cours de développement...'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GalleryTab extends StatelessWidget {
  final Residence residence;

  const _GalleryTab({required this.residence});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Ajouter des photos'),
                    onPressed: () {
                      // TODO: Implémenter l'ajout de photos
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        if (residence.images.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Galerie photos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: residence.images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              residence.images[index],
                              width: 300,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  final Residence residence;

  const _ReviewsTab({required this.residence});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      residence.rating.toString(),
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              Icons.star,
                              color: index < residence.rating.floor()
                                  ? Colors.amber
                                  : Colors.grey[300],
                            ),
                          ),
                        ),
                        Text(
                          '${residence.reviewCount} avis',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // TODO: Ajouter la liste des avis
        const Center(
          child: Text('Liste des avis en cours de développement...'),
        ),
      ],
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AmenityChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

Widget _buildFeatureItem(IconData icon, String label) {
  return Row(
    children: [
      Icon(icon),
      const SizedBox(width: 8),
      Text(label),
    ],
  );
}
