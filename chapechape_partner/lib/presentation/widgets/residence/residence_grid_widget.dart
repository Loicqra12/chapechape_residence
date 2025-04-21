import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/residence/residence.dart';
import '../../../core/models/residence/residence_extensions.dart';
import 'residence_card.dart';

class ResidenceGridWidget extends StatelessWidget {
  final List<Residence> residences;
  final Function(Residence)? onResidenceTap;
  final Function(Residence)? onDeleteTap;
  final bool isLoading;

  const ResidenceGridWidget({
    Key? key,
    required this.residences,
    this.onResidenceTap,
    this.onDeleteTap,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (residences.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 72,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune résidence trouvée',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez par ajouter une nouvelle résidence',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      );
    }

    return MasonryGridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      padding: const EdgeInsets.all(10),
      itemCount: residences.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final residence = residences[index];
        
        // Déterminer le facteur d'extension vertical basé sur les caractéristiques de la résidence
        double extent = 1.0;
        
        // Résidences spéciales ou résidences de vacances légèrement plus grandes
        if (residence.isSpecialResidence || residence.isVacationResidence) {
          extent = 1.1;
        }
        
        // Les résidences avec piscine ou plus de chambres sont encore plus grandes
        if (residence.hasPool || residence.bedrooms > 3) {
          extent += 0.15;
        }
        
        return ResidenceCard(
          residence: residence,
          onTap: () => onResidenceTap?.call(residence),
          onDelete: onDeleteTap != null ? () => onDeleteTap!.call(residence) : null,
        )
        .animate(delay: Duration(milliseconds: 50 * index))
        .fadeIn(duration: const Duration(milliseconds: 300))
        .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 350));
      },
    );
  }
}
