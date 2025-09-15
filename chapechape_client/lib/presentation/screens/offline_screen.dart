import 'package:flutter/material.dart';
import 'package:chapechape_client/core/services/cache_service.dart';
import 'package:chapechape_client/core/services/optimized_connectivity_service.dart';
import 'package:chapechape_client/presentation/widgets/residence_card.dart';
import 'package:chapechape_client/core/models/residence_model.dart';
import 'package:chapechape_client/core/service_locator.dart';

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
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                'Mode Hors Ligne',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Vous pouvez consulter les résidences mises en cache et vos favoris. '
            'La connexion sera rétablie automatiquement.',
            style: TextStyle(
              color: Colors.orange.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune donnée en cache',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connectez-vous à Internet pour charger des résidences',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
            padding: const EdgeInsets.all(16),
            itemCount: _cachedResidences.length,
            itemBuilder: (context, index) {
              final residence = _cachedResidences[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
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
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}









