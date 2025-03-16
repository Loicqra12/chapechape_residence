import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/blocs/residence/residence_bloc.dart';
import '../../../core/models/residence/residence.dart';
import '../../../core/extensions/residence_extensions.dart';
import '../../../core/services/api/residence_service.dart';
import '../../../core/config/app_config.dart';
import 'edit_residence_screen.dart';
import '../../widgets/layout/screen_app_bars.dart';
import 'residence_details_screen.dart'; // Importer l'écran de détail

class ResidencesScreen extends StatelessWidget {
  const ResidencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ResidenceBloc(
        ResidenceService(baseUrl: AppConfig.apiUrl),
      )..add(LoadResidences()),
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
  void _loadResidences() {
    context.read<ResidenceBloc>().add(LoadResidences());
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
                  return RefreshIndicator(
                    onRefresh: () async => _loadResidences(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: state.residences.map((residence) {
                          return _ResidenceCard(
                            residence: residence,
                            onEdit: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditResidenceScreen(
                                  residence: residence,
                                ),
                              ),
                            ).then((_) => _loadResidences()),
                            onDelete: () => _deleteResidence(context, residence),
                          );
                        }).toList(),
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

  Future<void> _deleteResidence(BuildContext context, Residence residence) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la résidence'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la résidence "${residence.title}" ?',
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

    if (confirmed == true && mounted) {
      // Afficher un indicateur de progression
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Suppression en cours...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Supprimer la résidence
      context.read<ResidenceBloc>().add(DeleteResidence(residence.id));
    }
  }
}

class _ResidenceCard extends StatelessWidget {
  final Residence residence;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ResidenceCard({
    required this.residence,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Vérifier d'abord si la résidence existe avant de naviguer
          final bloc = context.read<ResidenceBloc>();
          bloc.add(CheckResidenceExists(residence.id, onSuccess: () {
            // Naviguer vers les détails de la résidence seulement si elle existe
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResidenceDetailsScreen(residence: residence),
              ),
            );
          }));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de la résidence
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildResidenceImage(theme),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et statut
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          residence.title,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: residence.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          residence.status,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: residence.statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Prix
                  Text(
                    residence.formattedPrice,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Adresse et localisation
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${residence.address}, ${residence.city}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Caractéristiques
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FeatureChip(
                        icon: Icons.king_bed_outlined,
                        label: '${residence.bedrooms} chambre${residence.bedrooms > 1 ? 's' : ''}',
                      ),
                      _FeatureChip(
                        icon: Icons.bathtub_outlined,
                        label: '${residence.bathrooms} salle${residence.bathrooms > 1 ? 's' : ''} de bain',
                      ),
                      _FeatureChip(
                        icon: Icons.square_foot_outlined,
                        label: residence.formattedSurface,
                      ),
                      if (residence.hasPool)
                        const _FeatureChip(
                          icon: Icons.pool_outlined,
                          label: 'Piscine',
                        ),
                      if (residence.hasWifi)
                        const _FeatureChip(
                          icon: Icons.wifi_outlined,
                          label: 'Wi-Fi',
                        ),
                      if (residence.isFurnished)
                        const _FeatureChip(
                          icon: Icons.chair_outlined,
                          label: 'Meublé',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Modifier'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Supprimer'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
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

  Widget _buildResidenceImage(ThemeData theme) {
    if (residence.firstImageUrl != null) {
      return Image.network(
        residence.firstImageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage(theme);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }
    return _buildPlaceholderImage(theme);
  }

  Widget _buildPlaceholderImage(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
