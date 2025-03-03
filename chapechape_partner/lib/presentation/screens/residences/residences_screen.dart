import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/blocs/residence/residence_bloc.dart';
import '../../../core/models/residence/residence.dart';
import '../../../core/extensions/residence_extensions.dart';
import '../../../core/services/api/residence_service.dart';
import '../../../core/config/app_config.dart';
import 'edit_residence_screen.dart';
import '../../widgets/layout/screen_app_bars.dart';

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
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _loadResidences,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
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

    if (confirmed == true && mounted) {
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
                        residence.name,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: residence.isAvailable
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        residence.isAvailable ? 'Disponible' : 'Indisponible',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: residence.isAvailable
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Adresse
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${residence.address}, ${residence.city}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Caractéristiques
                Row(
                  children: [
                    _FeatureChip(
                      icon: Icons.king_bed,
                      label: '${residence.bedrooms} chambres',
                    ),
                    const SizedBox(width: 8),
                    _FeatureChip(
                      icon: Icons.bathtub,
                      label: '${residence.bathrooms} SDB',
                    ),
                    const SizedBox(width: 8),
                    _FeatureChip(
                      icon: Icons.square_foot,
                      label: residence.formattedSurface,
                    ),
                    if (residence.hasPool) ...[
                      const SizedBox(width: 8),
                      _FeatureChip(
                        icon: Icons.pool,
                        label: 'Piscine',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Prix
                Text(
                  residence.formattedPrice,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete),
                      label: const Text('Supprimer'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('Modifier'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidenceImage(ThemeData theme) {
    final imageUrl = residence.firstImageUrl;
    
    if (imageUrl != null) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultImage(theme);
        },
      );
    }
    
    return _buildDefaultImage(theme);
  }

  Widget _buildDefaultImage(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceVariant,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'Image non disponible',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
