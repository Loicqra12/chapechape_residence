import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/blocs/auth/auth_bloc.dart';
import '../../../core/blocs/dashboard/dashboard_bloc.dart';
import '../settings/settings_screen.dart';
import '../payments/payments_screen.dart' hide PaymentBloc;
import '../help/help_screen.dart' hide HelpBloc;
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'documents_screen.dart';
import 'security_history_screen.dart';
import '../../widgets/layout/screen_app_bars.dart';
import '../../../core/blocs/payment/payment_bloc.dart';
import '../../../core/blocs/help/help_bloc.dart';
import '../residences/residences_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../../../core/config/app_config_manager.dart';
import '../../../core/utils/string_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isOffline = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    // Vérifier l'état de la connectivité au démarrage
    _checkConnectivity();
    // Écouter les changements de connectivité
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _isOffline = result == ConnectivityResult.none;
      });
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (mounted) {
        setState(() {
          _isOffline = connectivityResult == ConnectivityResult.none;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification de la connectivité: $e');
    }
  }
  
  // Méthode pour construire une image de profil mise en cache et optimisée
  // Liste blanche des images qui existent réellement sur le serveur
  final List<String> validProfileImages = [
    // Priorité aux URLs Cloudinary
    'res.cloudinary.com',
    'cloudinary.com',
    
    // Patterns pour les images locales
    'profile-', // Préfixe pour toutes les images de profil valides
    
    // Extensions de fichiers
    '.jpg',
    '.jpeg',
    '.png',
    '.webp'
  ];

  // Méthode pour valider l'URL d'une image
  bool _isValidImageUrl(String imageUrl) {
    // Si l'URL est vide ou contient seulement des espaces, invalide
    if (imageUrl.isEmpty || imageUrl.trim().isEmpty) {
      debugPrint('URL vide ou contient seulement des espaces: "$imageUrl"');
      return false;
    }
    
    // Vérifier si l'URL est exactement une chaîne vide entre guillemets
    if (imageUrl == '""' || imageUrl == "''" || imageUrl == 'null' || imageUrl == 'undefined') {
      debugPrint('URL invalide détectée: $imageUrl');
      return false;
    }
    
    // Valider la structure de l'URL
    bool isValidUrl = Uri.tryParse(imageUrl)?.hasAuthority ?? false;
    
    // Rechercher des termes problématiques
    bool hasProblematicTerms = imageUrl.contains('placeholder') || 
                               imageUrl.contains('undefined') ||
                               imageUrl.contains('null') ||
                               imageUrl.contains('file:///') || // Éviter les URLs de fichiers locaux
                               imageUrl.startsWith('data:') && !imageUrl.contains('base64'); // Data URLs invalides

    // Vérifier si c'est une URL Cloudinary
    bool isCloudinaryUrl = imageUrl.contains('cloudinary.com') || 
                           imageUrl.contains('res.cloudinary.com');
    
    // Si c'est une URL Cloudinary, considérer comme valide
    if (isCloudinaryUrl) {
      return isValidUrl && !hasProblematicTerms;
    }
    
    // Vérifier si l'URL correspond à un pattern de la liste blanche
    bool matchesWhitelist = false;
    for (final validPattern in validProfileImages) {
      if (imageUrl.contains(validPattern)) {
        matchesWhitelist = true;
        break;
      }
    }
    
    // Vérifier l'extension de fichier
    bool hasValidExtension = imageUrl.toLowerCase().endsWith('.jpg') ||
                            imageUrl.toLowerCase().endsWith('.jpeg') ||
                            imageUrl.toLowerCase().endsWith('.png') ||
                            imageUrl.toLowerCase().endsWith('.webp');
    
    return isValidUrl && !hasProblematicTerms && (matchesWhitelist || hasValidExtension);
  }
  
  Widget _buildCachedProfileImage(String originalImageUrl, ThemeData theme, String fullName) {
    // Vérifier si l'URL originale est vide ou invalide
    if (originalImageUrl.isEmpty || originalImageUrl.trim().isEmpty) {
      return CircleAvatar(
        radius: 60,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : 'U',
          style: TextStyle(
            fontSize: 48,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      );
    }
    
    // Corriger l'URL de l'image en utilisant AppConfigManager
    String imageUrl = originalImageUrl;
    
    // Vérifier si c'est une URL Cloudinary
    bool isCloudinaryUrl = originalImageUrl.contains('cloudinary.com') || 
                         originalImageUrl.contains('res.cloudinary.com');
    
    // Si ce n'est pas une URL Cloudinary, utiliser AppConfigManager pour obtenir l'URL complète
    if (!isCloudinaryUrl) {
      imageUrl = AppConfigManager.getProfileImageUrl(originalImageUrl);
    }
    
    // Log pour déboguer les URLs d'images
    debugPrint('Image URL originale: $originalImageUrl');
    debugPrint('Image URL corrigée: $imageUrl');
    
    // Utiliser la nouvelle méthode de validation d'URL d'image
    bool isValidImage = _isValidImageUrl(imageUrl);
    
    // Si l'URL n'est pas valide, utiliser l'avatar par défaut
    if (!isValidImage) {
      debugPrint('URL d\'image non valide ou non autorisée: $imageUrl. Utilisation de l\'avatar par défaut.');
      return CircleAvatar(
        radius: 60,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : 'U',
          style: TextStyle(
            fontSize: 48,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      );
    }

    // Vérification finale de l'URL avant CachedNetworkImage
    if (imageUrl.isEmpty || imageUrl.trim().isEmpty) {
      return CircleAvatar(
        radius: 60,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : 'U',
          style: TextStyle(
            fontSize: 48,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      );
    }

    // Gérer les tentatives de chargement et les erreurs
    try {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: 60,
        backgroundImage: imageProvider,
      ),
        // Utiliser progressIndicatorBuilder au lieu de placeholder
        // pour éviter les problèmes d'assertion dans octo_image
        progressIndicatorBuilder: (context, url, progress) => CircleAvatar(
        radius: 60,
        backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.5),
          child: CircularProgressIndicator(
            value: progress.progress,
            color: theme.colorScheme.primary,
          ),
      ),
      errorWidget: (context, url, error) {
        debugPrint('Erreur de chargement d\'image: $error, URL: $url');
        // Fallback à l'initiale du nom en cas d'erreur
        return CircleAvatar(
          radius: 60,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
              fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : 'U',
            style: TextStyle(
              fontSize: 48,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        );
      },
        // Optimisation pour réseaux africains à débit limité
        memCacheHeight: 300,
        memCacheWidth: 300,
        maxHeightDiskCache: 600,
        maxWidthDiskCache: 600,
        // Timeouts adaptés aux réseaux lents
      fadeOutDuration: const Duration(milliseconds: 200),
      fadeInDuration: const Duration(milliseconds: 300),
        // Configuration du cache et de la politique de rechargement
        cacheKey: 'profile_${DateTime.now().millisecondsSinceEpoch}',
        useOldImageOnUrlChange: false,
        // Ne pas mettre en cache pour éviter les 404 sur les anciennes images
        cacheManager: null,
      );
    } catch (e) {
      debugPrint('Exception lors de la création de CachedNetworkImage: $e');
      // Fallback en cas d'exception
      return CircleAvatar(
        radius: 60,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : 'U',
          style: TextStyle(
            fontSize: 48,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Déclencher le chargement des statistiques si nécessaire
    if (context.read<DashboardBloc>().state is! DashboardLoaded) {
      context.read<DashboardBloc>().add(LoadDashboardData());
    }
    
    // Récupérer les données du partenaire avec validation
    final partner = context.select((AuthBloc bloc) {
      if (bloc.state is AuthAuthenticated) {
        final currentPartner = (bloc.state as AuthAuthenticated).partner;
        debugPrint('Données partenaire récupérées: ${currentPartner.fullName}');
        debugPrint('URL photo de profil: "${currentPartner.profilePictureUrl}"');
        return currentPartner;
      }
      return null;
    });
    
    // Récupérer les statistiques
    final dashboardState = context.select((DashboardBloc bloc) => bloc.state);
    final dashboardStats = dashboardState is DashboardLoaded ? dashboardState.partnerStats : null;
    
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Indicateur de mode hors ligne
          if (_isOffline)
            Container(
              color: Colors.orange.shade700,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: const Center(
                child: Text(
                  'Mode hors ligne - Photos et données en cache',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          Expanded(
            child: CustomScrollView(
              slivers: [
          ScreenAppBars.getProfileAppBar(context),
          SliverToBoxAdapter(
            // Utilisez un padding négatif au lieu de Transform.translate pour éviter le rognage
            child: Padding(
              // Padding négatif uniquement en bas pour garder l'espace sur les côtés
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                children: [
                  // Espace pour que l'avatar apparaisse partiellement superposé à l'app bar
                  const SizedBox(height: 20),
                  
                  // Photo de profil et bouton d'édition
                  Stack(
                    clipBehavior: Clip.none, // Empêche que les enfants soient rognés
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Hero(
                            tag: 'profile_photo',
                            child: Builder(
                              builder: (context) {
                                final profileUrl = partner?.profilePictureUrl;
                                debugPrint('🖼️ Rendu image profil - URL: "$profileUrl"');
                                debugPrint('🖼️ URL non null: ${profileUrl != null}');
                                debugPrint('🖼️ URL non vide: ${profileUrl?.trim().isNotEmpty == true}');
                                
                                return partner?.profilePictureUrl != null && 
                                       partner!.profilePictureUrl!.trim().isNotEmpty
                                  ? _buildCachedProfileImage(partner.profilePictureUrl!, theme, partner.fullName)
                                  : CircleAvatar(
                                    radius: 60,
                                    backgroundColor: theme.colorScheme.primaryContainer,
                                    child: Text(
                                      partner?.fullName.substring(0, 1).toUpperCase() ?? 'P',
                                      style: TextStyle(
                                        fontSize: 48,
                                        color: theme.colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  );
                              },
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                          right: 0,
                          bottom: 0,
                          child: Material(
                            color: theme.colorScheme.primary,
                            shape: const CircleBorder(),
                            elevation: 4,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EditProfileScreen(),
                                  ),
                                );
                              },
                              customBorder: const CircleBorder(),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                    const SizedBox(height: 16),

                    // Nom et badge vérifié
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          StringUtils.toTitleCase(partner?.fullName ?? ''),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (partner?.isVerified ?? false)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Vérifié',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    // Rôle en badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        partner?.role.toUpperCase() ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Informations sur les résidences
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.1),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.home_work_outlined,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Vos résidences',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            BlocBuilder<DashboardBloc, DashboardState>(
                              builder: (context, state) {
                                final int totalResidences = state is DashboardLoaded 
                                    ? state.dashboardData.performance.totalResidences
                                    : 0;
                                
                                final int availableResidences = state is DashboardLoaded
                                    ? state.residenceStats.where((r) => r.status == 'available').length
                                    : 0;
                                
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildResidenceIndicator(
                                      context,
                                      count: totalResidences,
                                      label: 'Résidences',
                                      icon: Icons.home,
                                      color: theme.colorScheme.primary,
                                    ),
                                    _buildResidenceIndicator(
                                      context,
                                      count: availableResidences,
                                      label: 'Disponibles',
                                      icon: Icons.check_circle_outline,
                                      color: theme.colorScheme.primary,
                                    ),
                                    _buildResidenceIndicator(
                                      context,
                                      count: totalResidences - availableResidences,
                                      label: 'Occupées',
                                      icon: Icons.timer,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  // Naviguer vers la liste des résidences
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ResidencesScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text('Gérer mes résidences'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Informations de contact
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.1),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoTile(
                              icon: Icons.email_outlined,
                              title: 'Email',
                              subtitle: partner?.email ?? '',
                              theme: theme,
                            ),
                            const Divider(),
                            _buildInfoTile(
                              icon: Icons.phone_outlined,
                              title: 'Téléphone',
                              subtitle: partner?.phoneNumber ?? '',
                              theme: theme,
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn().slideX(),

                    const SizedBox(height: 24),

                    // Statistiques
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.home_outlined,
                            value: dashboardState is DashboardLoaded 
                                ? '${dashboardState.dashboardData.performance.totalResidences}'
                                : '-',
                            label: 'Résidences',
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.star_outline,
                            value: dashboardState is DashboardLoaded 
                                ? '${dashboardState.dashboardData.stats.rating}'
                                : '-',
                            label: 'Note moyenne',
                            theme: theme,
                          ),
                        ),
                      ],
                    ).animate().fadeIn().slideY(),

                    const SizedBox(height: 16),

                    // Deuxième rangée de statistiques
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.calendar_today_outlined,
                            value: dashboardState is DashboardLoaded 
                                ? '${dashboardState.dashboardData.performance.totalReservations}'
                                : '-',
                            label: 'Réservations',
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.monetization_on_outlined,
                            value: dashboardState is DashboardLoaded 
                                ? _formatRevenueFcfa(dashboardState.dashboardData.revenue.totalRevenue)
                                : '-',
                            label: 'Revenus',
                            theme: theme,
                          ),
                        ),
                      ],
                    ).animate().fadeIn().slideY(),

                    const SizedBox(height: 24),

                    // Menu
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildMenuTile(
                            icon: Icons.settings_outlined,
                            title: 'Paramètres',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SettingsScreen.withBloc(context),
                                ),
                              );
                            },
                            theme: theme,
                          ),
                          const Divider(height: 1),
                          _buildMenuTile(
                            icon: Icons.lock_outline,
                            title: 'Changer le mot de passe',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ChangePasswordScreen(),
                                ),
                              );
                            },
                            theme: theme,
                          ),
                          const Divider(height: 1),
                          _buildMenuTile(
                            icon: Icons.security_outlined,
                            title: 'Historique de sécurité',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SecurityHistoryScreen(),
                                ),
                              );
                            },
                            theme: theme,
                          ),
                          const Divider(height: 1),
                          _buildMenuTile(
                            icon: Icons.verified_user_outlined,
                            title: 'Documents et vérification',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DocumentsScreen(),
                                ),
                              );
                            },
                            theme: theme,
                            trailing: partner?.isVerified == true
                                ? const Icon(Icons.verified, color: Colors.green, size: 20)
                                : Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Non vérifié',
                                      style: TextStyle(fontSize: 12, color: Colors.orange),
                                    ),
                                  ),
                          ),
                          const Divider(height: 1),
                          _buildMenuTile(
                            icon: Icons.payment_outlined,
                            title: 'Paiements',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PaymentsScreen.withBloc(context),
                                ),
                              );
                            },
                            theme: theme,
                          ),
                          const Divider(height: 1),
                          _buildMenuTile(
                            icon: Icons.notifications_outlined,
                            title: 'Notifications',
                            onTap: () => context.push('/notifications'),
                            theme: theme,
                          ),
                          const Divider(height: 1),
                          _buildMenuTile(
                            icon: Icons.help_outline,
                            title: 'Aide',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HelpScreen.withBloc(context),
                                ),
                              );
                            },
                            theme: theme,
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideX(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ],
    ));
  } // Fin de la méthode build

  /// Affiche un montant en FCFA sans décimale inutile pour zéro (ex. "0 FCFA" au lieu de "0.0 FCFA").
  static String _formatRevenueFcfa(double value) {
    if (value == 0) return '0 FCFA';
    return '${value.round()} FCFA';
  }
   
   Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ThemeData theme,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
        ),
      ),
      title: Text(title),
      trailing: trailing ?? Icon(
        Icons.chevron_right,
        color: theme.colorScheme.outline,
      ),
      onTap: onTap,
    );
  }

  Widget _buildResidenceIndicator(
    BuildContext context, {
    required int count,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
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
