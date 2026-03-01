import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/models/phone_number.dart';

/// Widget avancé pour la saisie de numéro de téléphone avec sélection de pays
class AdvancedPhoneInputWidget extends StatefulWidget {
  /// Libellé du champ
  final String label;
  
  /// Texte d'aide
  final String hint;
  
  /// Couleur du thème
  final Color? themeColor;
  
  /// Widget activé ou non
  final bool enabled;
  
  /// Champ requis ou non
  final bool isRequired;
  
  /// Champ en lecture seule
  final bool readOnly;
  
  /// Callback appelé quand le numéro change
  final Function(PhoneNumber) onPhoneChanged;
  
  /// Callback appelé quand la validation change
  final Function(bool)? onValidationChanged;
  
  /// Numéro initial
  final PhoneNumber? initialPhoneNumber;

  const AdvancedPhoneInputWidget({
    Key? key,
    required this.label,
    required this.hint,
    required this.onPhoneChanged,
    this.themeColor,
    this.enabled = true,
    this.isRequired = false,
    this.readOnly = false,
    this.onValidationChanged,
    this.initialPhoneNumber,
  }) : super(key: key);

  @override
  State<AdvancedPhoneInputWidget> createState() => _AdvancedPhoneInputWidgetState();
}

class _AdvancedPhoneInputWidgetState extends State<AdvancedPhoneInputWidget> {
  late TextEditingController _phoneController;
  String _selectedCountryCode = 'CI'; // Par défaut Côte d'Ivoire
  late ValueNotifier<bool> _isValidNotifier;

  // Liste des pays supportés
  final List<Map<String, String>> _countries = [
    {'code': 'CI', 'name': 'Côte d\'Ivoire', 'dial': '+225', 'flag': '🇨🇮'},
    {'code': 'SN', 'name': 'Sénégal', 'dial': '+221', 'flag': '🇸🇳'},
    {'code': 'ML', 'name': 'Mali', 'dial': '+223', 'flag': '🇲🇱'},
    {'code': 'BF', 'name': 'Burkina Faso', 'dial': '+226', 'flag': '🇧🇫'},
    {'code': 'GN', 'name': 'Guinée', 'dial': '+224', 'flag': '🇬🇳'},
    {'code': 'GH', 'name': 'Ghana', 'dial': '+233', 'flag': '🇬🇭'},
    {'code': 'NG', 'name': 'Nigeria', 'dial': '+234', 'flag': '🇳🇬'},
    {'code': 'TG', 'name': 'Togo', 'dial': '+228', 'flag': '🇹🇬'},
    {'code': 'BJ', 'name': 'Bénin', 'dial': '+229', 'flag': '🇧🇯'},
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialiser avec le numéro fourni ou vide
    if (widget.initialPhoneNumber != null) {
      _selectedCountryCode = widget.initialPhoneNumber!.isoCode;
      _phoneController = TextEditingController(text: widget.initialPhoneNumber!.phoneNumber);
      // Initialiser l'état de validation avec ValueNotifier
      _isValidNotifier = ValueNotifier<bool>(widget.initialPhoneNumber!.isValid);
    } else {
      _phoneController = TextEditingController();
      _isValidNotifier = ValueNotifier<bool>(false);
    }
    
    // Programmer la validation pour après le build initial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _validatePhoneNumber(_phoneController.text);
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _isValidNotifier.dispose();
    super.dispose();
  }

  /// Validation du numéro de téléphone
  bool _validatePhoneNumber(String phoneNumber) {
    final phone = PhoneNumber(
      isoCode: _selectedCountryCode,
      phoneNumber: phoneNumber,
    );
    
    final isValid = phone.isValid;
    
    // Mettre à jour le ValueNotifier au lieu de setState
    _isValidNotifier.value = isValid;
    
    // Notifier le changement de validation
    if (widget.onValidationChanged != null) {
      widget.onValidationChanged!(isValid);
    }
    
    return isValid;
  }

  /// Appelé quand le numéro change
  void _onPhoneChanged(String phoneNumber) {
    _validatePhoneNumber(phoneNumber);
    
    // Créer l'objet PhoneNumber et notifier le parent
    final phone = PhoneNumber(
      isoCode: _selectedCountryCode,
      phoneNumber: phoneNumber,
    );
    
    widget.onPhoneChanged(phone);
  }

  /// Appelé quand le pays change
  void _onCountryChanged(String? countryCode) {
    if (countryCode != null && countryCode != _selectedCountryCode) {
      setState(() {
        _selectedCountryCode = countryCode;
      });
      
      // Re-valider avec le nouveau pays
      _onPhoneChanged(_phoneController.text);
    }
  }

  /// Obtenir les données du pays sélectionné
  Map<String, String> get _selectedCountry {
    return _countries.firstWhere(
      (country) => country['code'] == _selectedCountryCode,
      orElse: () => _countries.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCountry = _selectedCountry;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Libellé (même style que TextInput : noir, sans astérisque)
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        
        // Champ de saisie avec sélecteur de pays
        SizedBox(
          height: 56,
          child: ValueListenableBuilder<bool>(
            valueListenable: _isValidNotifier,
            builder: (context, isValid, child) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outline,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
            child: Row(
              children: [
                // Sélecteur de pays
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: theme.dividerColor,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedCountryCode,
                    onChanged: widget.enabled && !widget.readOnly ? _onCountryChanged : null,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    items: _countries.map((country) {
                      return DropdownMenuItem<String>(
                        value: country['code'],
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              country['flag']!,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              country['dial']!,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                // Champ de saisie du numéro
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    enabled: widget.enabled,
                    readOnly: widget.readOnly,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: widget.enabled && !widget.readOnly ? _onPhoneChanged : null,
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 16.0,
                      ),
                      hintStyle: TextStyle(
                        color: theme.hintColor,
                      ),
                    ),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                
                // Indicateur de validation (discret, pas de rouge)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Icon(
                    isValid ? Icons.check_circle : Icons.phone_android,
                    color: isValid ? Colors.green : theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ],
            ),
          );
            },
          ),
        ),
        
        // Numéro formaté (aperçu)
        if (_phoneController.text.isNotEmpty)
          ValueListenableBuilder<bool>(
            valueListenable: _isValidNotifier,
            builder: (context, isValid, child) {
              return Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Format: ${selectedCountry['dial']} ${PhoneNumber(
                    isoCode: _selectedCountryCode,
                    phoneNumber: _phoneController.text,
                  ).formattedNumber}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isValid ? Colors.green : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
