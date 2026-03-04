import 'package:flutter/material.dart';
import '../../../core/models/country_info.dart';
import '../../../core/services/api/country_service.dart';

/// Widget pour sélectionner un pays et afficher ses informations
class CountrySelectorWidget extends StatefulWidget {
  /// Pays actuellement sélectionné
  final CountryInfo? selectedCountry;
  
  /// Callback appelé lors de la sélection d'un pays
  final Function(CountryInfo) onCountrySelected;
  
  /// Afficher uniquement les pays actifs
  final bool activeOnly;
  
  /// Afficher les informations détaillées
  final bool showDetails;
  
  /// Style compact ou étendu
  final bool compact;
  
  /// Couleur du thème
  final Color? themeColor;
  
  /// Fonctionnalité requise pour filtrer les pays
  final String? requiredFeature;

  const CountrySelectorWidget({
    Key? key,
    this.selectedCountry,
    required this.onCountrySelected,
    this.activeOnly = true,
    this.showDetails = true,
    this.compact = false,
    this.themeColor,
    this.requiredFeature,
  }) : super(key: key);

  @override
  State<CountrySelectorWidget> createState() => _CountrySelectorWidgetState();
}

class _CountrySelectorWidgetState extends State<CountrySelectorWidget> {
  final _countryService = CountryService();
  List<CountryInfo> _countries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final countries = await _countryService.getAllCountries(
        activeOnly: widget.activeOnly,
      );
      
      // Filtrer selon la fonctionnalité requise
      List<CountryInfo> filteredCountries = countries;
      if (widget.requiredFeature != null) {
        final supportChecks = await Future.wait(
          countries.map((country) => 
            _countryService.checkCountrySupport(country.code, widget.requiredFeature!)
          )
        );
        
        filteredCountries = [];
        for (int i = 0; i < countries.length; i++) {
          if (supportChecks[i].isSupported) {
            filteredCountries.add(countries[i]);
          }
        }
      }
      
      setState(() {
        _countries = filteredCountries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.themeColor ?? theme.primaryColor;

    if (widget.compact) {
      return _buildCompactSelector(theme, primaryColor);
    } else {
      return _buildFullSelector(theme, primaryColor);
    }
  }

  Widget _buildCompactSelector(ThemeData theme, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: widget.selectedCountry?.flagEmoji != null
            ? Text(
                widget.selectedCountry!.flagEmoji!,
                style: const TextStyle(fontSize: 20),
              )
            : Icon(Icons.public, color: primaryColor),
        title: Text(
          widget.selectedCountry?.name ?? 'Sélectionner un pays',
          style: theme.textTheme.bodyMedium,
        ),
        subtitle: widget.selectedCountry != null
            ? Text(
                '${widget.selectedCountry!.callingCode} • ${widget.selectedCountry!.currency}',
                style: theme.textTheme.bodySmall,
              )
            : null,
        trailing: const Icon(Icons.arrow_drop_down),
        onTap: _showCountryPicker,
      ),
    );
  }

  Widget _buildFullSelector(ThemeData theme, Color primaryColor) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Icon(Icons.public, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Pays de destination',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Sélecteur
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              _buildErrorWidget(theme)
            else
              _buildCountryDisplay(theme, primaryColor),
            
            if (widget.showDetails && widget.selectedCountry != null) ...[
              const SizedBox(height: 16),
              _buildCountryDetails(theme, primaryColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Erreur: $_error',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.red[700],
              ),
            ),
          ),
          TextButton(
            onPressed: _loadCountries,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryDisplay(ThemeData theme, Color primaryColor) {
    if (widget.selectedCountry == null) {
      return InkWell(
        onTap: _showCountryPicker,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.add, color: primaryColor),
              const SizedBox(width: 12),
              Text(
                'Sélectionner un pays',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: primaryColor,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: _showCountryPicker,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: primaryColor),
          borderRadius: BorderRadius.circular(8),
          color: primaryColor.withOpacity(0.05),
        ),
        child: Row(
          children: [
            // Drapeau ou icône
            if (widget.selectedCountry!.flagEmoji != null)
              Text(
                widget.selectedCountry!.flagEmoji!,
                style: const TextStyle(fontSize: 32),
              )
            else
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.public, color: primaryColor, size: 20),
              ),
            
            const SizedBox(width: 16),
            
            // Informations pays
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.selectedCountry!.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        widget.selectedCountry!.callingCode,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.selectedCountry!.currency,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(widget.selectedCountry!.status, theme),
                    ],
                  ),
                ],
              ),
            ),
            
            Icon(Icons.edit, color: primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, ThemeData theme) {
    Color badgeColor;
    String statusText;
    
    switch (status) {
      case 'active':
        badgeColor = Colors.green;
        statusText = 'Actif';
        break;
      case 'beta':
        badgeColor = Colors.orange;
        statusText = 'Beta';
        break;
      case 'planned':
        badgeColor = Theme.of(context).colorScheme.primary;
        statusText = 'Prévu';
        break;
      default:
        badgeColor = Colors.grey;
        statusText = status;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statusText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCountryDetails(ThemeData theme, Color primaryColor) {
    final country = widget.selectedCountry!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations détaillées',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          _buildDetailRow('Code pays', country.code, Icons.flag),
          _buildDetailRow('Monnaie', country.currency, Icons.attach_money),
          _buildDetailRow('Opérateurs', '${country.operatorCount}', Icons.network_cell),
          _buildDetailRow('Paiements', '${country.paymentOptions}', Icons.payment),
          
          if (country.languages.isNotEmpty)
            _buildDetailRow(
              'Langues', 
              country.languages.join(', '), 
              Icons.language
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // En-tête
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Sélectionner un pays',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Liste des pays
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _countries.length,
                itemBuilder: (context, index) {
                  final country = _countries[index];
                  final isSelected = widget.selectedCountry?.code == country.code;
                  
                  return ListTile(
                    leading: country.flagEmoji != null
                        ? Text(country.flagEmoji!, style: const TextStyle(fontSize: 24))
                        : const Icon(Icons.public),
                    title: Text(country.name),
                    subtitle: Text('${country.callingCode} • ${country.currency}'),
                    trailing: isSelected 
                        ? Icon(Icons.check_circle, color: widget.themeColor ?? Theme.of(context).primaryColor)
                        : _buildStatusBadge(country.status, Theme.of(context)),
                    selected: isSelected,
                    onTap: () {
                      widget.onCountrySelected(country);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
