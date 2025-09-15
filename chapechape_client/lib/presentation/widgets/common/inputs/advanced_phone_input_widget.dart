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
    {'code': 'FR', 'name': 'France', 'dial': '+33', 'flag': '🇫🇷'},
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
      dialCode: _getDialCode(_selectedCountryCode),
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
      dialCode: _getDialCode(_selectedCountryCode),
    );
    
    widget.onPhoneChanged(phone);
  }

  /// Appelé quand le pays change
  void _onCountryChanged(String countryCode) {
    setState(() {
      _selectedCountryCode = countryCode;
    });
    
    // Re-valider avec le nouveau pays
    _onPhoneChanged(_phoneController.text);
  }

  /// Obtenir le code d'appel d'un pays
  String _getDialCode(String countryCode) {
    final country = _countries.firstWhere(
      (c) => c['code'] == countryCode,
      orElse: () => _countries.first,
    );
    return country['dial']!;
  }

  /// Obtenir les informations d'un pays
  Map<String, String> _getCountryInfo(String countryCode) {
    return _countries.firstWhere(
      (c) => c['code'] == countryCode,
      orElse: () => _countries.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.themeColor ?? theme.primaryColor;
    final countryInfo = _getCountryInfo(_selectedCountryCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Libellé
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Text(
                  widget.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.isRequired)
                  Text(
                    ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: theme.textTheme.titleSmall?.fontSize,
                    ),
                  ),
              ],
            ),
          ),

        // Champ de saisie avec sélecteur de pays
        ValueListenableBuilder<bool>(
          valueListenable: _isValidNotifier,
          builder: (context, isValid, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: isValid
                      ? Colors.green
                      : (_phoneController.text.isNotEmpty ? Colors.red : Colors.grey[300]!),
                  width: isValid || (_phoneController.text.isNotEmpty && !isValid) ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // Sélecteur de pays
              InkWell(
                onTap: widget.enabled && !widget.readOnly ? _showCountryPicker : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        countryInfo['flag']!,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        countryInfo['dial']!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        color: widget.enabled && !widget.readOnly 
                            ? Colors.grey[600] 
                            : Colors.grey[400],
                        size: 20,
                      ),
                    ],
                  ),
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
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 16.0,
                    ),
                    suffixIcon: _phoneController.text.isNotEmpty
                        ? Icon(
                            isValid ? Icons.check_circle : Icons.error,
                            color: isValid ? Colors.green : Colors.red,
                          )
                        : null,
                  ),
                  onChanged: _onPhoneChanged,
                ),
              ),
            ],
          ),
            );
          },
        ),

        // Informations supplémentaires
        if (_phoneController.text.isNotEmpty) 
          ValueListenableBuilder<bool>(
            valueListenable: _isValidNotifier,
            builder: (context, isValid, child) {
              return Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isValid ? Icons.check_circle : Icons.error,
                        size: 16,
                        color: isValid ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          isValid 
                              ? 'Numéro valide • ${PhoneNumber(
                                  isoCode: _selectedCountryCode,
                                  phoneNumber: _phoneController.text,
                                  dialCode: _getDialCode(_selectedCountryCode),
                                ).operatorName}'
                              : 'Format de numéro invalide pour ${countryInfo['name']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isValid ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  /// Afficher le sélecteur de pays
  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sélectionner un pays',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...(_countries.map((country) => ListTile(
              leading: Text(
                country['flag']!,
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(country['name']!),
              subtitle: Text(country['dial']!),
              trailing: _selectedCountryCode == country['code']
                  ? Icon(Icons.check, color: widget.themeColor ?? Theme.of(context).primaryColor)
                  : null,
              onTap: () {
                _onCountryChanged(country['code']!);
                Navigator.pop(context);
              },
            )).toList()),
          ],
        ),
      ),
    );
  }
}
