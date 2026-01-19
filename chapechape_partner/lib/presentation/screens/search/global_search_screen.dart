import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/services/global_search_service.dart';
import '../../../core/models/residence/residence.dart';
import '../../../core/models/reservation/reservation.dart';
import '../../widgets/search/search_result_card.dart';
import '../../widgets/search/search_filters_sheet.dart';
import 'package:go_router/go_router.dart';

/// Écran de recherche globale avancée
class GlobalSearchScreen extends StatefulWidget {
  final String? initialQuery;

  const GlobalSearchScreen({
    super.key,
    this.initialQuery,
  });

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalSearchService _searchService = GlobalSearchService(Dio());
  
  bool _isSearching = false;
  GlobalSearchResults? _results;
  SearchCategory _selectedCategory = SearchCategory.all;
  SearchFilters? _activeFilters;
  SearchSort _currentSort = SearchSort.relevance;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final categories = _selectedCategory == SearchCategory.all
          ? null
          : [_selectedCategory];

      final results = await _searchService.search(
        query: query,
        categories: categories,
        filters: _activeFilters,
        sort: _currentSort,
      );

      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      debugPrint('Erreur lors de la recherche: $e');
    }
  }

  void _showFiltersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchFiltersSheet(
        currentFilters: _activeFilters,
        currentCategory: _selectedCategory,
        onApplyFilters: (filters) {
          setState(() {
            _activeFilters = filters;
          });
          _performSearch(_searchController.text);
        },
        onClearFilters: () {
          setState(() {
            _activeFilters = null;
          });
          _performSearch(_searchController.text);
        },
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Trier par',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Fermer',
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...SearchSort.values.map((sort) {
              return ListTile(
                leading: Icon(
                  _currentSort == sort 
                      ? Icons.radio_button_checked 
                      : Icons.radio_button_unchecked,
                  color: _currentSort == sort 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey,
                ),
                title: Text(sort.label),
                onTap: () {
                  setState(() {
                    _currentSort = sort;
                  });
                  Navigator.pop(context);
                  _performSearch(_searchController.text);
                },
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: widget.initialQuery == null,
          decoration: InputDecoration(
            hintText: 'Rechercher...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: Colors.grey[400],
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Effacer la recherche',
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _results = null;
                      });
                    },
                  )
                : null,
          ),
          style: const TextStyle(fontSize: 16),
          onSubmitted: _performSearch,
          onChanged: (value) {
            if (value.isEmpty) {
              setState(() {
                _results = null;
              });
            }
          },
        ),
        actions: [
          // Bouton de filtres
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_activeFilters != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFiltersSheet,
            tooltip: 'Filtres',
          ),
          // Bouton de tri
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
            tooltip: 'Trier',
          ),
        ],
      ),
      body: Column(
        children: [
          // Chips de catégories
          _buildCategoryChips(theme),
          
          // Résultats de recherche
          Expanded(
            child: _buildSearchResults(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: SearchCategory.values.map((category) {
            final isSelected = _selectedCategory == category;
            final count = _getCategoryCount(category);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text(
                  '${_getCategoryLabel(category)}${count > 0 ? ' ($count)' : ''}',
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                  if (_searchController.text.isNotEmpty) {
                    _performSearch(_searchController.text);
                  }
                },
                selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                checkmarkColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected 
                      ? theme.colorScheme.primary 
                      : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getCategoryLabel(SearchCategory category) {
    switch (category) {
      case SearchCategory.all:
        return 'Tout';
      case SearchCategory.residences:
        return 'Résidences';
      case SearchCategory.reservations:
        return 'Réservations';
      case SearchCategory.messages:
        return 'Messages';
      case SearchCategory.notifications:
        return 'Notifications';
    }
  }

  int _getCategoryCount(SearchCategory category) {
    if (_results == null) return 0;

    switch (category) {
      case SearchCategory.all:
        return _results!.totalResults;
      case SearchCategory.residences:
        return _results!.residences.length;
      case SearchCategory.reservations:
        return _results!.reservations.length;
      case SearchCategory.messages:
        return _results!.conversations.length;
      case SearchCategory.notifications:
        return _results!.notifications.length;
    }
  }

  Widget _buildSearchResults(ThemeData theme) {
    // État initial - pas de recherche
    if (_results == null && !_isSearching) {
      return _buildEmptyState(theme);
    }

    // Chargement
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Aucun résultat
    if (_results!.isEmpty) {
      return _buildNoResultsState(theme);
    }

    // Résultats trouvés
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // En-tête des résultats
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_results!.totalResults} résultat${_results!.totalResults > 1 ? 's' : ''}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_activeFilters != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _activeFilters = null;
                    });
                    _performSearch(_searchController.text);
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Effacer filtres'),
                ),
            ],
          ),
        ),

        // Résidences
        if (_results!.residences.isNotEmpty) ...[
          _buildSectionHeader('Résidences', _results!.residences.length),
          ..._results!.residences.map((residence) {
            return SearchResultCard.residence(
              residence: residence,
              query: _results!.query,
              onTap: () {
                context.push('/residences/${residence.id}');
              },
            );
          }).toList(),
          const SizedBox(height: 24),
        ],

        // Réservations
        if (_results!.reservations.isNotEmpty) ...[
          _buildSectionHeader('Réservations', _results!.reservations.length),
          ..._results!.reservations.map((reservation) {
            return SearchResultCard.reservation(
              reservation: reservation,
              query: _results!.query,
              onTap: () {
                context.push('/reservations/${reservation.id}');
              },
            );
          }).toList(),
          const SizedBox(height: 24),
        ],

        // Messages
        if (_results!.conversations.isNotEmpty) ...[
          _buildSectionHeader('Messages', _results!.conversations.length),
          ..._results!.conversations.map((conversation) {
            return SearchResultCard.conversation(
              conversation: conversation,
              query: _results!.query,
              onTap: () {
                context.push('/messages', extra: conversation);
              },
            );
          }).toList(),
          const SizedBox(height: 24),
        ],

        // Notifications
        if (_results!.notifications.isNotEmpty) ...[
          _buildSectionHeader('Notifications', _results!.notifications.length),
          ..._results!.notifications.map((notification) {
            return SearchResultCard.notification(
              notification: notification,
              query: _results!.query,
              onTap: () {
                context.push('/notifications');
              },
            );
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        '$title ($count)',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Recherchez ce que vous voulez',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Résidences, réservations, messages...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun résultat trouvé',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez avec d\'autres mots-clés',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          if (_activeFilters != null)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _activeFilters = null;
                });
                _performSearch(_searchController.text);
              },
              icon: const Icon(Icons.clear),
              label: const Text('Effacer les filtres'),
            ),
        ],
      ),
    );
  }
}


