import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/models/phone_number.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/spacing.dart';

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
    final countryInfo = _getCountryInfo(_selectedCountryCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Text(
                  widget.label,
                  style: AppTextStyles.title.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.isRequired)
                  Text(
                    ' *',
                    style: AppTextStyles.title.copyWith(
                      color: AppTheme.errorColor,
                    ),
                  ),
              ],
            ),
          ),

        /// Pays sur une ligne, numéro sur la ligne suivante en pleine largeur
        /// (évite le champ trop étroit + scroll horizontal à 10 chiffres).
        ValueListenableBuilder<bool>(
          valueListenable: _isValidNotifier,
          builder: (context, isValid, _) {
            return ListenableBuilder(
              listenable: _phoneController,
              builder: (context, _) {
                final hasText = _phoneController.text.isNotEmpty;
                final borderColor = isValid && hasText
                    ? AppTheme.successColor
                    : (hasText && !isValid
                        ? AppTheme.errorColor
                        : AppTheme.dividerColor);
                final borderWidth =
                    (isValid && hasText) || (hasText && !isValid) ? 2.0 : 1.0;

                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: borderColor,
                      width: borderWidth,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.enabled && !widget.readOnly
                              ? _showCountryPicker
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  countryInfo['flag']!,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontSize: 22,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  countryInfo['dial']!,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_drop_down_rounded,
                                  color: widget.enabled && !widget.readOnly
                                      ? theme.colorScheme.onSurface
                                          .withOpacity(0.75)
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.45),
                                  size: 26,
                                ),
                                const Spacer(),
                                Text(
                                  'Pays',
                                  style: AppTextStyles.caption.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.45),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppTheme.dividerColor.withOpacity(0.9),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
                        child: Text(
                          'Numéro local uniquement — l’indicatif ${countryInfo['dial']} est déjà choisi.',
                          style: AppTextStyles.caption.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            height: 1.25,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
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
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.4,
                                ),
                                decoration: InputDecoration(
                                  hintText: widget.hint,
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                ),
                                onChanged: _onPhoneChanged,
                              ),
                            ),
                            if (hasText)
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Icon(
                                  isValid
                                      ? Icons.check_circle_rounded
                                      : Icons.error_rounded,
                                  color: isValid
                                      ? AppTheme.successColor
                                      : AppTheme.errorColor,
                                  size: 26,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),

        ListenableBuilder(
          listenable: _phoneController,
          builder: (context, _) {
            if (_phoneController.text.isEmpty) {
              return const SizedBox.shrink();
            }
            return ValueListenableBuilder<bool>(
              valueListenable: _isValidNotifier,
              builder: (context, isValid, _) {
                return Column(
                  children: [
                    SizedBox(height: AppSpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isValid ? Icons.check_circle : Icons.error,
                          size: 16,
                          color: isValid
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            isValid
                                ? 'Format du numéro correct.'
                                : 'Format de numéro invalide pour ${countryInfo['name']}',
                            style: AppTextStyles.caption.copyWith(
                              color: isValid
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final maxH = MediaQuery.of(context).size.height * 0.6;
        return SizedBox(
          height: maxH,
          child: Container(
            padding: AppSpacing.cardPadding,
            child: ListView(
              children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Sélectionner un pays',
                  style: AppTextStyles.title.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ..._countries.map((country) => ListTile(
                leading: Text(
                  country['flag']!,
                  style: AppTextStyles.headline.copyWith(fontSize: 24),
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
              )),
            ],
          ),
        ),
      );
      },
    );
  }
}
