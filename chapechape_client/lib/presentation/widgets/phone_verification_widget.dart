import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/notification_service.dart';

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
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _codeSent = false;
  String? _codeId;
  DateTime? _expiresAt;
  int _remainingSeconds = 0;
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    if (widget.initialPhoneNumber != null) {
      _phoneController.text = widget.initialPhoneNumber!;
    }
  }
  
  @override
  void dispose() {
    _phoneController.dispose();
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
    if (_phoneController.text.isEmpty) {
      _showSnackBar('Veuillez entrer un numéro de téléphone', isError: true);
      return;
    }
    
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    if (!notificationService.isValidPhoneNumber(_phoneController.text)) {
      _showSnackBar('Numéro de téléphone invalide', isError: true);
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final result = await notificationService.requestVerificationCode(
        _phoneController.text
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
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      final success = await notificationService.resendVerificationCode(
        _phoneController.text
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
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      final success = await notificationService.verifyCode(
        _phoneController.text,
        _codeController.text,
        codeId: _codeId,
      );
      
      if (success) {
        _timer?.cancel();
        
        // Appeler le callback de succès
        widget.onVerificationSuccess(_phoneController.text);
        
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
              
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone',
                  hintText: 'Ex: +225 XX XX XX XX',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                enabled: !_codeSent,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un numéro de téléphone';
                  }
                  
                  final notificationService = Provider.of<NotificationService>(
                    context, 
                    listen: false
                  );
                  
                  if (!notificationService.isValidPhoneNumber(value)) {
                    return 'Numéro de téléphone invalide';
                  }
                  
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              if (!_codeSent)
                ElevatedButton(
                  onPressed: _isLoading ? null : _requestCode,
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
