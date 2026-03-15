import 'package:flutter/material.dart';
import 'country_flag_widget.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/models/country.dart';
import '../../core/services/location_service.dart';

class CountrySelectorWidget extends StatefulWidget {
  final Function(Country) onCountrySelected;
  final Country? initialCountry;
  final bool showBorder;
  final bool showLabel;
  final bool showCompact;

  const CountrySelectorWidget({
    Key? key,
    required this.onCountrySelected,
    this.initialCountry,
    this.showBorder = true,
    this.showLabel = true,
    this.showCompact = false,
  }) : super(key: key);

  @override
  State<CountrySelectorWidget> createState() => _CountrySelectorWidgetState();
}

class _CountrySelectorWidgetState extends State<CountrySelectorWidget> {
  late Country _selectedCountry;
  bool _isSelecting = false;
  final LocationService _locationService = LocationService();
  
  // Filtre pour la recherche de pays
  String _searchQuery = '';
  List<Country> _filteredCountries = [];

  @override
  void initState() {
    super.initState();
    // Utiliser le pays initial ou la Côte d'Ivoire par défaut
    _selectedCountry = widget.initialCountry ?? 
        Country(code: 'ci', name: 'Côte d\'Ivoire', phoneCode: '+225');
    
    // Initialiser la liste des pays
    _filteredCountries = _locationService.getCountries();
  }

  // Filtrer les pays en fonction de la recherche
  void _filterCountries(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      
      // Si la recherche est vide, afficher tous les pays
      if (_searchQuery.isEmpty) {
        _filteredCountries = _locationService.getCountries();
        return;
      }
      
      // Normaliser la recherche (retirer les accents)
      String normalizedQuery = _normalizeString(_searchQuery);
      
      _filteredCountries = _locationService.getCountries()
          .where((country) {
            // Normaliser le nom du pays
            String normalizedName = _normalizeString(country.name.toLowerCase());
            
            // Vérifier si le nom normalisé contient la recherche normalisée
            return normalizedName.contains(normalizedQuery) ||
                   country.code.toLowerCase().contains(_searchQuery) ||
                   country.phoneCode.toLowerCase().contains(_searchQuery);
          })
          .toList();
          
      // Si aucun résultat, essayer avec une recherche partielle
      if (_filteredCountries.isEmpty && _searchQuery.length > 2) {
        _filteredCountries = _locationService.getCountries()
            .where((country) => 
                _normalizeString(country.name.toLowerCase()).contains(
                    normalizedQuery.substring(0, normalizedQuery.length > 2 ? 3 : normalizedQuery.length)
                )
            )
            .toList();
      }
    });
  }
  
  // Fonction pour normaliser les chaînes (enlever les accents)
  String _normalizeString(String input) {
    // Mapping des caractères accentués vers leurs équivalents sans accent
    const accents = {
      'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
      'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
      'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
      'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
      'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
      'ÿ': 'y', 'ñ': 'n', 'ç': 'c',
    };
    
    return input.split('').map((char) => accents[char] ?? char).join('');
  }

  void _showCountryPicker() {
    setState(() {
      _isSelecting = true;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  // Poignée de glissement
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 15),
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  // Titre
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sélectionner un pays',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Barre de recherche
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Rechercher un pays',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      ),
                      onChanged: (value) {
                        _filterCountries(value);
                        setModalState(() {});
                      },
                    ),
                  ),
                  // Liste des pays
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _filteredCountries.length,
                      itemBuilder: (context, index) {
                        final country = _filteredCountries[index];
                        final bool isSelected = _selectedCountry.code == country.code;
                        
                        return ListTile(
                          leading: CountryFlagWidget.fromCountry(
                            country: country,
                            size: 30,
                          ),
                          title: Text(country.name),
                          subtitle: Text(country.phoneCode),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: AppTheme.primaryColor)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedCountry = country;
                              _isSelecting = false;
                            });
                            widget.onCountrySelected(country);
                            Navigator.pop(context);
                          },
                          selected: isSelected,
                          selectedTileColor: AppTheme.primaryColor.withOpacity(0.05),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        }
      ),
    ).then((_) {
      setState(() {
        _isSelecting = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Version compacte pour utilisation dans des espaces restreints
    if (widget.showCompact) {
      return InkWell(
        onTap: _showCountryPicker,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: CountryFlagWidget.fromCountry(
            country: _selectedCountry,
            size: 24,
            showDropdownIndicator: true,
            isSelected: _isSelecting,
          ),
        ),
      );
    }
    
    // Version normale
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLabel) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Pays',
              style: TextStyle(
                fontSize: context.responsiveFontSize(16),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        InkWell(
          onTap: _showCountryPicker,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              border: widget.showBorder
                  ? Border.all(color: Theme.of(context).colorScheme.outline)
                  : null,
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Row(
              children: [
                CountryFlagWidget.fromCountry(
                  country: _selectedCountry,
                  size: 24,
                  showName: true,
                  isSelected: _isSelecting,
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_drop_down,
                  color: _isSelecting ? AppTheme.primaryColor : Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 