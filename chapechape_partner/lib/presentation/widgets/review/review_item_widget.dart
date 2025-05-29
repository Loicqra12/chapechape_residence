import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/review/review_model.dart';
import 'review_response_dialog.dart';

/// Widget pour afficher un avis individuel avec possibilité de réponse
class ReviewItemWidget extends StatelessWidget {
  final ReviewModel review;

  const ReviewItemWidget({
    Key? key,
    required this.review,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de l'avis avec info utilisateur et date
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: review.userProfileImage != null
                      ? NetworkImage(review.userProfileImage!)
                      : null,
                  child: review.userProfileImage == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userFullName ?? 'Utilisateur',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy').format(review.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getRatingColor(review.rating.overall),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    review.rating.overall.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Notes détaillées par catégorie
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildRatingChip('Propreté', review.rating.cleanliness),
                _buildRatingChip('Confort', review.rating.comfort),
                _buildRatingChip('Équipements', review.rating.facilities),
                _buildRatingChip('Rapport qualité/prix', review.rating.value),
                _buildRatingChip('Emplacement', review.rating.location),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Commentaire de l'utilisateur
            Text(
              review.comment,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            // Images de l'avis s'il y en a
            if (review.images.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          review.images[index],
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 80,
                              width: 80,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            const Divider(height: 24),
            
            // Réponse du partenaire ou bouton pour répondre
            if (review.response != null) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.business),
                ),
                title: Row(
                  children: [
                    const Text('Votre réponse'),
                    const Spacer(),
                    Text(
                      review.responseDate != null
                          ? DateFormat('dd MMM yyyy').format(review.responseDate!)
                          : '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(review.response!),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Modifier votre réponse'),
                onPressed: () => _showResponseDialog(context),
              ),
            ] else ...[
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.reply),
                  label: const Text('Répondre à cet avis'),
                  onPressed: () => _showResponseDialog(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Affiche la boîte de dialogue pour répondre à l'avis
  void _showResponseDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ReviewResponseDialog(review: review),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre réponse a été enregistrée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Construit une puce affichant une catégorie de notation
  Widget _buildRatingChip(String label, double rating) {
    return Chip(
      label: Text('$label: ${rating.toStringAsFixed(1)}'),
      backgroundColor: _getRatingColor(rating).withOpacity(0.2),
      labelStyle: TextStyle(
        color: _getRatingColor(rating).withOpacity(0.8),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Renvoie une couleur en fonction de la note
  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green[700]!;
    if (rating >= 4.0) return Colors.green;
    if (rating >= 3.5) return Colors.lightGreen;
    if (rating >= 3.0) return Colors.amber;
    if (rating >= 2.0) return Colors.orange;
    return Colors.red;
  }
}
