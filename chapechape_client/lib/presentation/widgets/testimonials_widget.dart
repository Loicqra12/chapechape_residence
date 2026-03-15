import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/models/testimonial_model.dart';
import '../../core/data/testimonials_data.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'common/premium_card.dart';

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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
    return PremiumCard(
      borderRadius: 20,
      elevation: 5,
      backgroundColor: Theme.of(context).cardColor,
      child: Stack(
        children: [
          // Background Quote Icon
          Positioned(
            top: -10,
            right: -10,
            child: Icon(
              FontAwesomeIcons.quoteRight,
              size: 80,
              color: AppTheme.primaryColor.withOpacity(0.05),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        backgroundImage: testimonial.userAvatar != null && testimonial.userAvatar!.isNotEmpty
                            ? AssetImage(testimonial.userAvatar!)
                            : null,
                        child: testimonial.userAvatar == null || testimonial.userAvatar!.isEmpty
                            ? Text(
                                testimonial.userName != null && testimonial.userName!.isNotEmpty
                                    ? testimonial.userName![0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            testimonial.userName ?? 'Utilisateur',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < (testimonial.rating ?? 0).toInt()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: const Color(0xFFD4AF37), // Gold
                                size: 14,
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Text(
                    testimonial.content ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    _formatDate(testimonial.date),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.labelSmall?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    // Example: "2 days ago" or "12/03/2023"
    final Duration diff = DateTime.now().difference(date);
    if (diff.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays} jours';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
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
