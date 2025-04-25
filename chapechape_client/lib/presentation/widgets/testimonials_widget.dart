import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/models/testimonial_model.dart';
import '../../core/data/testimonials_data.dart';

class TestimonialsWidget extends StatelessWidget {
  final bool showTitle;
  
  const TestimonialsWidget({
    Key? key,
    this.showTitle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<TestimonialModel> testimonials = TestimonialsData.testimonials;

    // Vérifier si la liste est vide pour éviter les erreurs de null
    if (testimonials.isEmpty) {
      return Container(
        width: double.infinity,
        padding: context.responsiveMargin,
        child: const Center(
          child: Text('Aucun témoignage disponible'),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: context.responsiveMargin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre et description, conditionnellement affichés
          if (showTitle) ...[
            Text(
              'Ce que disent nos clients',
              style: TextStyle(
                fontSize: context.responsiveFontSize(24),
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Découvrez les expériences de nos clients satisfaits',
              style: TextStyle(
                fontSize: context.responsiveFontSize(16),
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Carousel de témoignages - Ajout d'une vérification supplémentaire
          if (testimonials.isNotEmpty) 
            _buildSafeCarousel(context, testimonials),
        ],
      ),
    );
  }

  double _getViewportFraction(BuildContext context) {
    if (context.screenWidth < 500) {
      return 0.9; // Mobile petit écran
    } else if (context.screenWidth < 800) {
      return 0.8; // Mobile grand écran / tablette
    } else if (context.screenWidth < 1200) {
      return 0.6; // Tablette / petit desktop
    } else {
      return 0.4; // Grand desktop
    }
  }

  Widget _buildTestimonialCard(BuildContext context, TestimonialModel testimonial) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  backgroundImage: testimonial.userAvatar != null && testimonial.userAvatar!.isNotEmpty
                      ? AssetImage(testimonial.userAvatar!)
                      : null,
                  onBackgroundImageError: testimonial.userAvatar != null && testimonial.userAvatar!.isNotEmpty
                      ? (exception, stackTrace) {
                          debugPrint('Erreur de chargement de l\'image: $exception');
                        }
                      : null,
                  child: testimonial.userAvatar == null || testimonial.userAvatar!.isEmpty
                      ? Text(
                          testimonial.userName != null && testimonial.userName!.isNotEmpty
                              ? testimonial.userName![0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        testimonial.userName ?? 'Client anonyme',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < (testimonial.rating ?? 0).floor()
                                ? Icons.star
                                : index < (testimonial.rating ?? 0)
                                    ? Icons.star_half
                                    : Icons.star_border,
                            color: Colors.amber,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Text(
                testimonial.content ?? 'Aucun commentaire',
                style: TextStyle(
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 5,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'il y a 2 jours',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Méthode sécurisée pour créer le carousel avec gestion des erreurs
  Widget _buildSafeCarousel(BuildContext context, List<TestimonialModel> testimonials) {
    try {
      return FlutterCarousel(
        items: testimonials.map((testimonial) => 
          _buildTestimonialCard(context, testimonial)
        ).toList(),
        options: CarouselOptions(
          height: context.responsiveHeight(300),
          viewportFraction: _getViewportFraction(context),
          // Désactiver complètement l'autoplay pour éviter les erreurs de timer
          autoPlay: false,
          enlargeCenterPage: true,
          enableInfiniteScroll: testimonials.length > 1,
          onPageChanged: (index, reason) {
            // Gestionnaire d'événements vide intentionnellement
          },
        ),
      );
    } catch (e) {
      debugPrint('Erreur dans le carousel: $e');
      // Fallback en cas d'erreur - afficher le premier témoignage de manière statique
      return testimonials.isNotEmpty
          ? Container(
              constraints: BoxConstraints(
                maxHeight: context.responsiveHeight(300),
              ),
              child: _buildTestimonialCard(context, testimonials[0]),
            )
          : const SizedBox.shrink();
    }
  }
}
