import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/notification_service.dart';
import 'common/inputs/advanced_phone_input_widget.dart';
import '../../core/models/phone_number.dart';

/// Widget permettant la vérification d'un numéro de téléphone par SMS
class PhoneVerificationWidget extends StatefulWidget {
  /// Callback appelé lorsque la vérification est réussie
  final Function(String) onVerificationSuccess;
  
  /// Callback appelé lorsque l'utilisateur annule la vérification
  final Function()? onCancel;
  
  /// Numéro de téléphone initial (optionnel)
  final String? initialPhoneNumber;
  
  const PhoneVerificationWidget({
    Key? key,
    required this.onVerificationSuccess,
    this.onCancel,
    this.initialPhoneNumber,
  }) : super(key: key);

  @override
  State<PhoneVerificationWidget> createState() => _PhoneVerificationWidgetState();
}

class _PhoneVerificationWidgetState extends State<PhoneVerificationWidget> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _codeSent = false;
  String? _codeId;
  DateTime? _expiresAt;
  int _remainingSeconds = 0;
  Timer? _timer;
  
  // Variables pour le widget de téléphone avancé
  PhoneNumber? _selectedPhoneNumber;
  bool _isPhoneValid = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.initialPhoneNumber != null) {
      // Extraire le code pays et le numéro du numéro initial
      String phoneNumber = widget.initialPhoneNumber!;
      String isoCode = 'CI'; // Par défaut Côte d'Ivoire
      
      if (phoneNumber.startsWith('+225')) {
        isoCode = 'CI';
        phoneNumber = phoneNumber.substring(4);
      } else if (phoneNumber.startsWith('+221')) {
        isoCode = 'SN';
        phoneNumber = phoneNumber.substring(4);
      } else if (phoneNumber.startsWith('+223')) {
        isoCode = 'ML';
        phoneNumber = phoneNumber.substring(4);
      } else if (phoneNumber.startsWith('+226')) {
        isoCode = 'BF';
        phoneNumber = phoneNumber.substring(4);
      } else if (phoneNumber.startsWith('+224')) {
        isoCode = 'GN';
        phoneNumber = phoneNumber.substring(4);
      }
      
      // Obtenir le dialCode selon l'isoCode
      String dialCode = '+225'; // Par défaut
      switch (isoCode) {
        case 'SN': dialCode = '+221'; break;
        case 'ML': dialCode = '+223'; break;
        case 'BF': dialCode = '+226'; break;
        case 'GN': dialCode = '+224'; break;
        default: dialCode = '+225'; break;
      }
      
      _selectedPhoneNumber = PhoneNumber(
        isoCode: isoCode, 
        phoneNumber: phoneNumber,
        dialCode: dialCode,
      );
    }
  }
  
  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }
  
  void _startTimer() {
    _timer?.cancel();
    
    if (_expiresAt != null) {
      final difference = _expiresAt!.difference(DateTime.now());
      _remainingSeconds = difference.inSeconds > 0 ? difference.inSeconds : 0;
      
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _timer?.cancel();
          }
        });
      });
    }
  }
  
  Future<void> _requestCode() async {
    print('🔍 DEBUG: _requestCode appelé');
    print('🔍 DEBUG: _selectedPhoneNumber: ${_selectedPhoneNumber?.completeNumber}');
    print('🔍 DEBUG: _isPhoneValid: $_isPhoneValid');
    print('🔍 DEBUG: _isLoading: $_isLoading');
    
    if (_selectedPhoneNumber?.phoneNumber == null || _selectedPhoneNumber.phoneNumber.isEmpty) {
      print('❌ DEBUG: Numéro de téléphone vide');
      _showSnackBar('Veuillez entrer un numéro de téléphone', isError: true);
      return;
    }
    
    // Utiliser le service locator au lieu du Provider
    final notificationService = await NotificationService.initialize();
    print('✅ DEBUG: NotificationService récupéré via service locator');
    
    if (!notificationService.isValidPhoneNumber(_selectedPhoneNumber!.completeNumber)) {
      print('❌ DEBUG: Numéro de téléphone invalide selon NotificationService');
      _showSnackBar('Numéro de téléphone invalide', isError: true);
      return;
    }
    
    print('🚀 DEBUG: Début de l\'envoi du code');
    setState(() => _isLoading = true);
    
    try {
      final result = await notificationService.requestVerificationCode(
        _selectedPhoneNumber!.completeNumber
      );
      
      if (result != null) {
        setState(() {
          _codeSent = true;
          _codeId = result['codeId'];
          _expiresAt = DateTime.parse(result['expiresAt']);
          _startTimer();
        });
        
        _showSnackBar('Code de vérification envoyé');
      } else {
        _showSnackBar('Erreur lors de l\'envoi du code', isError: true);
      }
    } catch (e) {
      _showSnackBar('Une erreur est survenue', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _resendCode() async {
    setState(() => _isLoading = true);
    
    try {
      final notificationService = await NotificationService.initialize();
      final success = await notificationService.resendVerificationCode(
        _selectedPhoneNumber!.completeNumber
      );
      
      if (success) {
        // Comme nous n'avons plus l'ID du code ni sa date d'expiration,
        // nous devons redemander un nouveau code
        await _requestCode();
      } else {
        _showSnackBar('Erreur lors du renvoi du code', isError: true);
      }
    } catch (e) {
      _showSnackBar('Une erreur est survenue', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _verifyCode() async {
    if (_codeController.text.length < 6) {
      _showSnackBar('Veuillez entrer un code valide à 6 chiffres', isError: true);
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final notificationService = await NotificationService.initialize();
      final success = await notificationService.verifyCode(
        _selectedPhoneNumber!.completeNumber,
        _codeController.text,
        codeId: _codeId,
      );
      
      if (success) {
        _timer?.cancel();
        
        // Appeler le callback de succès
        widget.onVerificationSuccess(_selectedPhoneNumber!.completeNumber);
        
        _showSnackBar('Numéro vérifié avec succès');
      } else {
        _showSnackBar('Code de vérification incorrect', isError: true);
      }
    } catch (e) {
      _showSnackBar('Une erreur est survenue', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
  
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Vérification du numéro de téléphone',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              AdvancedPhoneInputWidget(
                label: 'Numéro de téléphone',
                hint: 'Ex: +225 XX XX XX XX',
                isRequired: true,
                initialPhoneNumber: _selectedPhoneNumber,
                readOnly: _codeSent,
                onPhoneChanged: (PhoneNumber phoneNumber) {
                  setState(() {
                    _selectedPhoneNumber = phoneNumber;
                  });
                },
                onValidationChanged: (bool isValid) {
                  print('🔍 DEBUG: Validation changée - isValid: $isValid');
                  setState(() {
                    _isPhoneValid = isValid;
                  });
                },
                themeColor: Theme.of(context).primaryColor,
              ),
              
              const SizedBox(height: 16),
              
              if (!_codeSent)
                ElevatedButton(
                  onPressed: (_isLoading || !_isPhoneValid) ? null : () {
                    print('🔍 DEBUG: Bouton cliqué - _isLoading: $_isLoading, _isPhoneValid: $_isPhoneValid');
                    _requestCode();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Recevoir un code par SMS'),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Code de vérification',
                        hintText: 'Entrez le code à 6 chiffres',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Veuillez entrer le code à 6 chiffres';
                        }
                        return null;
                      },
                      maxLength: 6,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_remainingSeconds > 0)
                          Text(
                            'Expire dans: ${_formatTime(_remainingSeconds)}',
                            style: const TextStyle(color: Colors.grey),
                          )
                        else
                          const Text(
                            'Code expiré',
                            style: TextStyle(color: Colors.red),
                          ),
                        
                        TextButton(
                          onPressed: _isLoading || _remainingSeconds > 0 
                              ? null 
                              : _resendCode,
                          child: Text(_remainingSeconds > 0 
                              ? 'Renvoyer plus tard' 
                              : 'Renvoyer le code'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    ElevatedButton(
                      onPressed: _isLoading ? null : _verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Vérifier'),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _codeSent = false;
                          _codeId = null;
                          _expiresAt = null;
                          _codeController.clear();
                          _timer?.cancel();
                        });
                      },
                      child: const Text('Modifier le numéro'),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    TextButton(
                      onPressed: widget.onCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Annuler'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/notification_service.dart';
import 'common/inputs/advanced_phone_input_widget.dart';
import '../../core/models/phone_number.dart';

/// Widget permettant la vérification d'un numéro de téléphone par SMS
class PhoneVerificationWidget extends StatefulWidget {
  /// Callback appelé lorsque la vérification est réussie
  final Function(String) onVerificationSuccess;
  
  /// Callback appelé lorsque l'utilisateur annule la vérification
  final Function()? onCancel;
  
  /// Numéro de téléphone initial (optionnel)
  final String? initialPhoneNumber;
  
  const PhoneVerificationWidget({
    Key? key,
    required this.onVerificationSuccess,
    this.onCancel,
    this.initialPhoneNumber,
  }) : super(key: key);

  @override
  State<PhoneVerificationWidget> createState() => _PhoneVerificationWidgetState();
}

class _PhoneVerificationWidgetState extends State<PhoneVerificationWidget> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _codeSent = false;
  String? _codeId;
  DateTime? _expiresAt;
  int _remainingSeconds = 0;
  Timer? _timer;
  
  // Variables pour le widget de téléphone avancé
  PhoneNumber? _selectedPhoneNumber;
  bool _isPhoneValid = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.initialPhoneNumber != null) {
      // Extraire le code pays et le numéro du numéro initial
      String phoneNumber = widget.initialPhoneNumber!;
      String isoCode = 'CI'; // Par défaut Côte d'Ivoire
      
      if (phoneNumber.startsWith('+225')) {
        isoCode = 'CI';
        phoneNumber = phoneNumber.substring(4);
      } else if (phoneNumber.startsWith('+221')) {
        isoCode = 'SN';
        phoneNumber = phoneNumber.substring(4);
      } else if (phoneNumber.startsWith('+223')) {
        isoCode = 'ML';
        phoneNumber = phoneNumber.substring(4);
      } else if (phoneNumber.startsWith('+226')) {
        isoCode = 'BF';
        phoneNumber = phoneNumber.substring(4);
      } else if (phoneNumber.startsWith('+224')) {
        isoCode = 'GN';
        phoneNumber = phoneNumber.substring(4);
      }
      
      // Obtenir le dialCode selon l'isoCode
      String dialCode = '+225'; // Par défaut
      switch (isoCode) {
        case 'SN': dialCode = '+221'; break;
        case 'ML': dialCode = '+223'; break;
        case 'BF': dialCode = '+226'; break;
        case 'GN': dialCode = '+224'; break;
        default: dialCode = '+225'; break;
      }
      
      _selectedPhoneNumber = PhoneNumber(
        isoCode: isoCode, 
        phoneNumber: phoneNumber,
        dialCode: dialCode,
      );
    }
  }
  
  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }
  
  void _startTimer() {
    _timer?.cancel();
    
    if (_expiresAt != null) {
      final difference = _expiresAt!.difference(DateTime.now());
      _remainingSeconds = difference.inSeconds > 0 ? difference.inSeconds : 0;
      
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _timer?.cancel();
          }
        });
      });
    }
  }
  
  Future<void> _requestCode() async {
    print('🔍 DEBUG: _requestCode appelé');
    print('🔍 DEBUG: _selectedPhoneNumber: ${_selectedPhoneNumber?.completeNumber}');
    print('🔍 DEBUG: _isPhoneValid: $_isPhoneValid');
    print('🔍 DEBUG: _isLoading: $_isLoading');
    
    if (_selectedPhoneNumber?.phoneNumber == null || _selectedPhoneNumber!.phoneNumber!.isEmpty) {
      print('❌ DEBUG: Numéro de téléphone vide');
      _showSnackBar('Veuillez entrer un numéro de téléphone', isError: true);
      return;
    }
    
    // Utiliser le service locator au lieu du Provider
    final notificationService = await NotificationService.initialize();
    print('✅ DEBUG: NotificationService récupéré via service locator');
    
    if (!notificationService.isValidPhoneNumber(_selectedPhoneNumber!.completeNumber)) {
      print('❌ DEBUG: Numéro de téléphone invalide selon NotificationService');
      _showSnackBar('Numéro de téléphone invalide', isError: true);
      return;
    }
    
    print('🚀 DEBUG: Début de l\'envoi du code');
    setState(() => _isLoading = true);
    
    try {
      final result = await notificationService.requestVerificationCode(
        _selectedPhoneNumber!.completeNumber
      );
      
      if (result != null) {
        setState(() {
          _codeSent = true;
          _codeId = result['codeId'];
          _expiresAt = DateTime.parse(result['expiresAt']);
          _startTimer();
        });
        
        _showSnackBar('Code de vérification envoyé');
      } else {
        _showSnackBar('Erreur lors de l\'envoi du code', isError: true);
      }
    } catch (e) {
      _showSnackBar('Une erreur est survenue', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _resendCode() async {
    setState(() => _isLoading = true);
    
    try {
      final notificationService = await NotificationService.initialize();
      final success = await notificationService.resendVerificationCode(
        _selectedPhoneNumber!.completeNumber
      );
      
      if (success) {
        // Comme nous n'avons plus l'ID du code ni sa date d'expiration,
        // nous devons redemander un nouveau code
        await _requestCode();
      } else {
        _showSnackBar('Erreur lors du renvoi du code', isError: true);
      }
    } catch (e) {
      _showSnackBar('Une erreur est survenue', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _verifyCode() async {
    if (_codeController.text.length < 6) {
      _showSnackBar('Veuillez entrer un code valide à 6 chiffres', isError: true);
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final notificationService = await NotificationService.initialize();
      final success = await notificationService.verifyCode(
        _selectedPhoneNumber!.completeNumber,
        _codeController.text,
        codeId: _codeId,
      );
      
      if (success) {
        _timer?.cancel();
        
        // Appeler le callback de succès
        widget.onVerificationSuccess(_selectedPhoneNumber!.completeNumber);
        
        _showSnackBar('Numéro vérifié avec succès');
      } else {
        _showSnackBar('Code de vérification incorrect', isError: true);
      }
    } catch (e) {
      _showSnackBar('Une erreur est survenue', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
  
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Vérification du numéro de téléphone',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              AdvancedPhoneInputWidget(
                label: 'Numéro de téléphone',
                hint: 'Ex: +225 XX XX XX XX',
                isRequired: true,
                initialPhoneNumber: _selectedPhoneNumber,
                readOnly: _codeSent,
                onPhoneChanged: (PhoneNumber phoneNumber) {
                  setState(() {
                    _selectedPhoneNumber = phoneNumber;
                  });
                },
                onValidationChanged: (bool isValid) {
                  print('🔍 DEBUG: Validation changée - isValid: $isValid');
                  setState(() {
                    _isPhoneValid = isValid;
                  });
                },
                themeColor: Theme.of(context).primaryColor,
              ),
              
              const SizedBox(height: 16),
              
              if (!_codeSent)
                ElevatedButton(
                  onPressed: (_isLoading || !_isPhoneValid) ? null : () {
                    print('🔍 DEBUG: Bouton cliqué - _isLoading: $_isLoading, _isPhoneValid: $_isPhoneValid');
                    _requestCode();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Recevoir un code par SMS'),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Code de vérification',
                        hintText: 'Entrez le code à 6 chiffres',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Veuillez entrer le code à 6 chiffres';
                        }
                        return null;
                      },
                      maxLength: 6,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_remainingSeconds > 0)
                          Text(
                            'Expire dans: ${_formatTime(_remainingSeconds)}',
                            style: const TextStyle(color: Colors.grey),
                          )
                        else
                          const Text(
                            'Code expiré',
                            style: TextStyle(color: Colors.red),
                          ),
                        
                        TextButton(
                          onPressed: _isLoading || _remainingSeconds > 0 
                              ? null 
                              : _resendCode,
                          child: Text(_remainingSeconds > 0 
                              ? 'Renvoyer plus tard' 
                              : 'Renvoyer le code'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    ElevatedButton(
                      onPressed: _isLoading ? null : _verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Vérifier'),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _codeSent = false;
                          _codeId = null;
                          _expiresAt = null;
                          _codeController.clear();
                          _timer?.cancel();
                        });
                      },
                      child: const Text('Modifier le numéro'),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    TextButton(
                      onPressed: widget.onCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Annuler'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
