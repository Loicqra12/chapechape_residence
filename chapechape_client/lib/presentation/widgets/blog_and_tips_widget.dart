import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/blog_post_model.dart';
import '../../core/utils/responsive_utils.dart';
import 'dart:ui';
import '../../core/theme/app_theme.dart';
import '../../core/services/blog_service.dart';
import '../../core/services/logger_service.dart';
import 'common/premium_card.dart';

class BlogAndTipsWidget extends StatefulWidget {
  final List<BlogPost>? blogPosts;
  final bool isLoading;
  final VoidCallback? onSeeAllPressed;
  final EdgeInsets padding;
  final String title;
  final String emptyStateMessage;
  final bool enableAnimation;

  const BlogAndTipsWidget({
    Key? key,
    this.blogPosts,
    this.isLoading = false,
    this.onSeeAllPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.title = 'Blog & Conseils',
    this.emptyStateMessage = 'Aucun article de blog disponible',
    this.enableAnimation = true,
  }) : super(key: key);

  @override
  State<BlogAndTipsWidget> createState() => _BlogAndTipsWidgetState();
}

class _BlogAndTipsWidgetState extends State<BlogAndTipsWidget> {
  final BlogService _blogService = BlogService();
  final LoggerService _logger = LoggerService();
  List<BlogPost> _blogPosts = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadBlogPosts();
  }
  
  Future<void> _loadBlogPosts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (widget.blogPosts != null) {
        setState(() {
          _blogPosts = widget.blogPosts!;
          _isLoading = false;
        });
        return;
      }
      
      final blogPosts = await _blogService.getRecentBlogPosts();
      
      setState(() {
        _blogPosts = blogPosts;
        _isLoading = false;
      });
    } catch (e) {
      _logger.error('Erreur lors du chargement des articles de blog: $e');
      setState(() {
        _blogPosts = [];
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Initialisation de la locale française pour timeago
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        _isLoading || widget.isLoading 
            ? _buildLoadingSkeleton() 
            : _buildBlogPostsList(context),
      ],
    ).animate(
      target: widget.enableAnimation ? 1 : 0,
    ).fadeIn(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: context.responsiveFontSize(20),
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 100,
            child: TextButton(
              onPressed: widget.onSeeAllPressed ?? () {
                context.push('/blog');
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Voir tout',
                style: TextStyle(
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlogPostsList(BuildContext context) {
    if (_blogPosts.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return SizedBox(
      height: 280,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: widget.padding.horizontal / 2),
        scrollDirection: Axis.horizontal,
        itemCount: _blogPosts.length,
        itemBuilder: (context, index) {
          final blogPost = _blogPosts[index];
          return _buildBlogPostCard(context, blogPost);
        },
      ),
    );
  }

  Widget _buildBlogPostCard(BuildContext context, BlogPost blogPost) {
    return GestureDetector(
      onTap: () {
        context.push('/blog/${blogPost.id}');
      },
      child: PremiumCard(
        width: 280,
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        borderRadius: 16,
        elevation: 4,
        backgroundColor: Colors.white,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image du blog
              Stack(
                children: [
                  SizedBox(
                    height: 130,
                    width: double.infinity,
                    child: _buildImage(blogPost),
                  ),
                  
                  // Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Badge de catégorie Glassmorphic
                  if (blogPost.category != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(blogPost.category).withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getCategoryText(blogPost.category).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              
              // Contenu du blog
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Titre
                    Text(
                      blogPost.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                      const SizedBox(height: 3),
                      
                      // Sous-titre / résumé
                      if (blogPost.summary != null)
                        Flexible(
                          child: Text(
                            blogPost.summary!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      
                      const Spacer(flex: 1),
                      
                      // Informations de l'auteur et date
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          if (blogPost.authorImageUrl != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: CircleAvatar(
                                radius: 10,
                                backgroundImage: _getAuthorImage(blogPost),
                              ),
                            ),
                          
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  blogPost.authorName ?? 'Équipe ChapeChape',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _formatDate(blogPost.publishedDate),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          
                          // Badge de temps de lecture
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 10,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${blogPost.readTimeMinutes ?? 3} min',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BlogPost blogPost) {
    final imageUrl = blogPost.imageUrl;
    
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey,
            size: 32,
          ),
        ),
      );
    }
    
    // Si l'URL commence par "http" ou "https", c'est une URL en ligne
    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            color: Colors.white,
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(
              Icons.error_outline,
              color: Colors.grey,
              size: 32,
            ),
          ),
        ),
      );
    }
    
    // Sinon, c'est un asset local (nous utilisons désormais des URLs en ligne)
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey,
          size: 32,
        ),
      ),
    );
  }

  ImageProvider _getAuthorImage(BlogPost blogPost) {
    final imageUrl = blogPost.authorImageUrl;
    
    // Si l'URL est valide et c'est une URL en ligne
    if (imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
      return CachedNetworkImageProvider(imageUrl);
    }
    
    // Avatar par défaut avec une couleur générée par le nom de l'auteur
    return NetworkImage(
      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(blogPost.authorName ?? "User")}&background=random&color=fff&size=100'
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: widget.padding,
      alignment: Alignment.center,
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 48,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            widget.emptyStateMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadBlogPosts,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Actualiser'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image placeholder
                    Container(
                      height: 130,
                      color: Colors.white,
                    ),
                    
                    // Content placeholder
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title placeholder
                          Container(
                            width: double.infinity,
                            height: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 200,
                            height: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          
                          // Summary placeholder
                          Container(
                            width: double.infinity,
                            height: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 150,
                            height: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          
                          // Author info placeholder
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 80,
                                    height: 10,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                width: 50,
                                height: 20,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date inconnue';
    
    try {
      final now = DateTime.now();
      final difference = now.difference(date);
      
      // Utiliser timeago pour les dates récentes (moins de 7 jours)
      if (difference.inDays < 7) {
        return timeago.format(date, locale: 'fr');
      }
      
      // Pour les dates plus anciennes, utiliser un format standard
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Date inconnue';
    }
  }

  String _getCategoryText(String? category) {
    if (category == null) return 'Général';
    
    switch (category.toLowerCase()) {
      case 'tips':
        return 'Conseils';
      case 'news':
        return 'Actualités';
      case 'guide':
        return 'Guide';
      case 'market':
        return 'Marché';
      case 'lifestyle':
        return 'Style de vie';
      default:
        return category;
    }
  }

  Color _getCategoryColor(String? category) {
    if (category == null) return Colors.grey;
    
    switch (category.toLowerCase()) {
      case 'tips':
        return Colors.green;
      case 'news':
        return Colors.blue;
      case 'guide':
        return Colors.orange;
      case 'market':
        return Colors.purple;
      case 'lifestyle':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
