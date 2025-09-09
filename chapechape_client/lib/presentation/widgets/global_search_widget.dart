import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/models/residence_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/logger_service.dart';

/// Widget de recherche globale pour l'application ChapeChape
/// 
/// Permet aux utilisateurs de rechercher des résidences en temps réel
/// avec autocomplétion et suggestions
class GlobalSearchWidget extends StatefulWidget {
  const GlobalSearchWidget({super.key});

  @override
  State<GlobalSearchWidget> createState() => _GlobalSearchWidgetState();
}

class _GlobalSearchWidgetState extends State<GlobalSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LoggerService _logger = LoggerService();
  
  bool _isSearchExpanded = false;
  List<Residence> _searchResults = [];
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    
    if (query.length < 2) return; // Attendre au moins 2 caractères
    
    setState(() {
      _isSearching = true;
    });
    
    _logger.debug('Recherche globale: "$query"');
    
    // Déclencher la recherche via le bloc  
    context.read<ResidenceBloc>().add(
      SearchResidences(
        query: query,
        filters: const {}, // Recherche globale sans filtres
      ),
    );
  }
  
  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (_isSearchExpanded) {
        _focusNode.requestFocus();
      } else {
        _focusNode.unfocus();
        _searchController.clear();
        _searchResults = [];
      }
    });
    
    _logger.debug('Recherche globale ${_isSearchExpanded ? 'ouverte' : 'fermée'}');
  }
  
  void _selectResidence(Residence residence) {
    _logger.info('Résidence sélectionnée depuis recherche globale: ${residence.id}');
    
    // Fermer la recherche
    _toggleSearch();
    
    // Naviguer vers les détails de la résidence
    context.go('/residence/${residence.id}');
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocListener<ResidenceBloc, ResidenceState>(
      listener: (context, state) {
        if (state is ResidencesSearchResult) {
          setState(() {
            _searchResults = state.residences;
            _isSearching = false;
          });
        } else if (state is ResidencesLoaded) {
          setState(() {
            _searchResults = state.residences;
            _isSearching = false;
          });
        } else if (state is ResidenceError) {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isSearchExpanded ? 280 : 40,
        height: 40,
        child: Stack(
          children: [
            // Champ de recherche
            if (_isSearchExpanded)
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _focusNode.hasFocus ? AppTheme.primaryColor : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Rechercher une résidence...',
                    hintStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    prefixIcon: _isSearching
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          )
                        : Icon(
                            Icons.search,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: _toggleSearch,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            
            // Bouton de recherche (quand fermé)
            if (!_isSearchExpanded)
              Positioned(
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _toggleSearch,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.search,
                        color: AppTheme.primaryColor,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Overlay des résultats
            if (_isSearchExpanded && _searchResults.isNotEmpty)
              Positioned(
                top: 45,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(
                      maxHeight: 300,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.take(5).length, // Limiter à 5 résultats
                      itemBuilder: (context, index) {
                        final residence = _searchResults[index];
                        return _buildSearchResultItem(residence);
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchResultItem(Residence residence) {
    return ListTile(
      dense: true,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 40,
          height: 40,
          child: residence.images.isNotEmpty
              ? Image.network(
                  residence.images.first,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.home,
                      color: Colors.grey[400],
                    ),
                  ),
                )
              : Container(
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.home,
                    color: Colors.grey[400],
                  ),
                ),
        ),
      ),
      title: Text(
        residence.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${residence.location['city'] ?? 'Ville'}, ${residence.location['country'] ?? 'Pays'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${residence.price.toStringAsFixed(0)} FCFA / ${residence.pricePeriod}',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      onTap: () => _selectResidence(residence),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey[400],
      ),
    );
  }
}
