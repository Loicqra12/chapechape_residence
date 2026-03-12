import 'package:flutter/material.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/core/services/cache_service.dart';
import 'package:chapechape_client/core/services/optimized_connectivity_service.dart';
import 'package:chapechape_client/presentation/widgets/residence_card.dart';
import 'package:chapechape_client/core/models/residence_model.dart';
import 'package:chapechape_client/core/service_locator.dart';
import 'package:chapechape_client/presentation/widgets/common/empty_state_widget.dart';

/// Écran affiché lorsque l'utilisateur est hors ligne
class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key});

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  late final CacheService _cacheService;
  final OptimizedConnectivityService _connectivityService = OptimizedConnectivityService();
  
  List<Residence> _cachedResidences = [];
  List<Residence> _favoriteResidences = [];
  List<String> _searchHistory = [];
  bool _isLoading = true;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _cacheService = sl<CacheService>();
    _loadOfflineData();
  }
  
  /// Charge les données disponibles en mode offline
  Future<void> _loadOfflineData() async {
    setState(() => _isLoading = true);
    
    try {
      // Simulation de données cached - dans une vraie app, on récupérerait depuis le cache
      final cachedData = await _cacheService.get('cached_residences');
      final favoritesData = await _cacheService.get('favorite_residences');
      final historyData = await _cacheService.get('search_history');
      
      setState(() {
        _cachedResidences = cachedData != null ? List<Residence>.from(cachedData) : [];
        _favoriteResidences = favoritesData != null ? List<Residence>.from(favoritesData) : [];
        _searchHistory = historyData != null ? List<String>.from(historyData) : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Erreur chargement données offline: $e');
    }
  }
  
  /// Effectue une recherche dans les données offline
  Future<void> _searchOffline(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchQuery = '';
      });
      _loadOfflineData(); // Recharger toutes les données
      return;
    }
    
    setState(() => _searchQuery = query);
    
    try {
      // Recherche simple dans les données déjà chargées
      final filteredResidences = _cachedResidences.where((residence) {
        final searchTerm = query.toLowerCase();
        return residence.title.toLowerCase().contains(searchTerm) ||
               residence.address.toLowerCase().contains(searchTerm) ||
               residence.description.toLowerCase().contains(searchTerm);
      }).toList();
      
      setState(() => _cachedResidences = filteredResidences);
    } catch (e) {
      debugPrint('Erreur recherche offline: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode Hors Ligne'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          StreamBuilder<bool>(
            stream: _connectivityService.connectivityStream,
            builder: (context, snapshot) {
              final isConnected = snapshot.data ?? false;
              if (isConnected) {
                return IconButton(
                  icon: const Icon(Icons.wifi),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  tooltip: 'Connexion rétablie',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildOfflineContent(),
    );
  }
  
  Widget _buildOfflineContent() {
    return Column(
      children: [
        // Bannière d'information
        _buildInfoBanner(),
        
        // Barre de recherche
        _buildSearchBar(),
        
        // Contenu principal
        Expanded(
          child: _cachedResidences.isEmpty
              ? _buildEmptyState()
              : _buildResidencesList(),
        ),
      ],
    );
  }
  
  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      margin: AppSpacing.pagePadding,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.orange.shade700),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Mode Hors Ligne',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          AppSpacing.verticalSm,
          Text(
            'Vous pouvez consulter les résidences mises en cache et vos favoris. '
            'La connexion sera rétablie automatiquement.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.orange.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: TextField(
        onChanged: _searchOffline,
        decoration: InputDecoration(
          hintText: 'Rechercher dans le cache...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchOffline(''),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      imagePath: 'assets/images/empty_states/empty_offline_illustration.png',
      title: 'Aucune donnée hors ligne',
      subtitle: 'Connectez-vous à Internet pour découvrir nos résidences et charger le contenu',
      fallbackIcon: Icons.cloud_off,
    );
  }
  
  Widget _buildResidencesList() {
    return Column(
      children: [
        // Statistiques
        _buildStats(),
        
        // Liste des résidences
        Expanded(
          child: ListView.builder(
            padding: AppSpacing.pagePadding,
            itemCount: _cachedResidences.length,
            itemBuilder: (context, index) {
              final residence = _cachedResidences[index];
              return Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: ResidenceCard(
                  residence: residence,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildStats() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      padding: EdgeInsets.all(AppSpacing.smd),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Résidences',
            _cachedResidences.length.toString(),
            Icons.home,
            Colors.blue,
          ),
          _buildStatItem(
            'Favoris',
            _favoriteResidences.length.toString(),
            Icons.favorite,
            Colors.red,
          ),
          _buildStatItem(
            'Recherches',
            _searchHistory.length.toString(),
            Icons.history,
            Colors.green,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        AppSpacing.verticalXs,
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}









