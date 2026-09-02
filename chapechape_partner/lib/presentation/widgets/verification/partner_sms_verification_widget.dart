import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/phone_number.dart';
import '../../../core/services/api/partner_verification_service.dart';
import '../../../core/blocs/auth/auth_bloc.dart';
import '../../../core/blocs/auth/auth_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'channel_selector_widget.dart';

/// Widget spécialisé pour la vérification SMS des partenaires
class PartnerSMSVerificationWidget extends StatefulWidget {
  /// Numéro de téléphone à vérifier
  final PhoneNumber phoneNumber;
  
  /// Callback appelé lorsque la vérification est réussie
  final Function(PartnerVerificationResult) onVerified;
  
  /// Callback appelé en cas d'erreur
  final Function(String)? onError;
  
  /// Callback appelé lorsque l'utilisateur annule
  final Function()? onCancel;
  
  /// Configurer automatiquement les canaux de paiement
  final bool enablePayoutSetup;
  
  /// Valider l'opérateur automatiquement
  final bool requireCarrierValidation;
  
  /// Afficher le contexte business
  final bool showBusinessContext;
  
  /// Raison de la vérification
  final String reason;
  
  /// Canal de vérification préféré
  final String preferredChannel;
  
  /// Couleur du thème
  final Color? themeColor;

  const PartnerSMSVerificationWidget({
    Key? key,
    required this.phoneNumber,
    required this.onVerified,
    this.onError,
    this.onCancel,
    this.enablePayoutSetup = true,
    this.requireCarrierValidation = true,
    this.showBusinessContext = true,
    this.reason = 'profile_update',
    this.preferredChannel = 'sms',
    this.themeColor,
  }) : super(key: key);

  @override
  State<PartnerSMSVerificationWidget> createState() => _PartnerSMSVerificationWidgetState();
}

class _PartnerSMSVerificationWidgetState extends State<PartnerSMSVerificationWidget>
    with TickerProviderStateMixin {
  
  final _codeController = TextEditingController();
  final _verificationService = PartnerVerificationService();
  
  bool _isLoading = false;
  bool _codeSent = false;
  String? _error;
  int _remainingSeconds = 0;
  int _attemptsRemaining = 3;
  Timer? _timer;
  String _currentChannel = 'sms';
  
  // Informations détectées sur le numéro
  String? _detectedCarrier;
  List<String> _supportedPayments = [];
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _analyzePhoneNumber();
    _currentChannel = widget.preferredChannel;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut)
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));
    
    _fadeController.forward();
    _slideController.forward();
  }

  /// Analyser le numéro pour détecter l'opérateur et les paiements supportés
  void _analyzePhoneNumber() {
    final phoneStr = widget.phoneNumber.completeNumber;
    
    // Détecter l'opérateur
    if (phoneStr.contains('+225')) {
      // Côte d'Ivoire
      if (phoneStr.contains('07') || phoneStr.contains('47')) {
        _detectedCarrier = 'Orange CI';
        _supportedPayments = ['Orange Money', 'Wave'];
      } else if (phoneStr.contains('05') || phoneStr.contains('45')) {
        _detectedCarrier = 'MTN CI';
        _supportedPayments = ['MTN Money', 'Wave'];
      } else if (phoneStr.contains('01') || phoneStr.contains('41')) {
        _detectedCarrier = 'Moov CI';
        _supportedPayments = ['Moov Money', 'Wave'];
      }
    } else if (phoneStr.contains('+221')) {
      // Sénégal
      if (phoneStr.contains('77') || phoneStr.contains('78')) {
        _detectedCarrier = 'Orange SN';
        _supportedPayments = ['Orange Money', 'Wave'];
      } else {
        _detectedCarrier = 'Autre SN';
        _supportedPayments = ['Wave'];
      }
    }
    
    if (mounted) setState(() {});
  }

  /// Demander le code de vérification
  Future<void> _requestCode() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _verificationService.requestVerification(
        phoneNumber: widget.phoneNumber.completeNumber,
        reason: widget.reason,
        channel: _currentChannel,
      );

      if (result.success) {
        setState(() {
          _codeSent = true;
          _remainingSeconds = result.expiresIn ?? 300; // 5 minutes
          _attemptsRemaining = result.attemptsRemaining ?? 3;
        });
        _startTimer();
        
        // Afficher une confirmation
        _showSuccessSnackBar('Code envoyé par ${_currentChannel.toUpperCase()}');
        
      } else {
        _setError(result.message ?? 'Erreur lors de l\'envoi du code');
      }
    } catch (e) {
      _setError('Erreur réseau : ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Vérifier le code saisi
  Future<void> _verifyCode() async {
    if (_isLoading || _codeController.text.length < 6) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _verificationService.confirmVerification(
        code: _codeController.text,
        setupPayouts: widget.enablePayoutSetup,
      );

      if (result.success) {
        _timer?.cancel();

        try {
          context.read<AuthBloc>().add(AuthProfileRefreshRequested());
        } catch (_) {}
        
        // Notifier le succès avec résultat complet
        widget.onVerified(PartnerVerificationResult(
          phoneNumber: result.partner?.phoneNumber ?? widget.phoneNumber.completeNumber,
          isVerified: true,
          verifiedAt: DateTime.now(),
          payoutChannels: result.payoutChannels ?? [],
          detectedCarrier: _detectedCarrier,
          supportedPayments: _supportedPayments,
        ));
        
      } else {
        _setError(result.message ?? 'Code incorrect');
        _codeController.clear();
      }
    } catch (e) {
      _setError('Erreur de vérification : ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setError(String error) {
    setState(() => _error = error);
    if (widget.onError != null) {
      widget.onError!(error);
    }
  }

  /// Changer de canal de vérification
  Future<void> _switchChannel() async {
    if (_isLoading) return;
    
    setState(() {
      _currentChannel = _currentChannel == 'sms' ? 'whatsapp' : 'sms';
      _codeSent = false;
      _error = null;
      _timer?.cancel();
    });
    
    // Redemander le code avec le nouveau canal
    await _requestCode();
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        setState(() => _codeSent = false);
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.themeColor ?? theme.primaryColor;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                _buildHeader(theme, primaryColor),
                
                const SizedBox(height: 16),
                
                // Sélecteur de canal
                ChannelSelectorWidget(
                  selectedChannel: _currentChannel,
                  onChannelChanged: (channel) {
                    setState(() {
                      _currentChannel = channel;
                    });
                  },
                  themeColor: primaryColor,
                ),
                
                const SizedBox(height: 16),
                
                // Contexte business si activé
                if (widget.showBusinessContext) ...[
                  _buildBusinessContext(theme),
                  const SizedBox(height: 16),
                ],
                
                // Informations sur le numéro
                _buildPhoneInfo(theme, primaryColor),
                
                const SizedBox(height: 20),
                
                // Zone de saisie du code ou bouton d'envoi
                if (!_codeSent) 
                  _buildRequestSection(primaryColor)
                else 
                  _buildVerificationSection(theme, primaryColor),
                
                const SizedBox(height: 16),
                
                // Erreur
                if (_error != null) _buildError(theme),
                
                const SizedBox(height: 16),
                
                // Boutons d'action
                _buildActionButtons(theme, primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Color primaryColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.security,
            color: primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vérification Business',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Sécurisez votre compte partenaire',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessContext(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Pourquoi cette vérification ?',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Recevoir vos commissions par mobile money\n'
            '• Notifications importantes (réservations, paiements)\n'
            '• Sécuriser votre compte business',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInfo(ThemeData theme, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.phone, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.phoneNumber.completeNumber,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (_detectedCarrier != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.network_cell, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Opérateur: $_detectedCarrier',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
          if (_supportedPayments.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.payment, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Paiements: ${_supportedPayments.join(', ')}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestSection(Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _requestCode,
        icon: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.sms),
        label: Text(_isLoading ? 'Envoi en cours...' : 'Recevoir le code SMS'),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildVerificationSection(ThemeData theme, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Code de vérification (6 chiffres)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // Champ de saisie du code
        TextFormField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: '000000',
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            suffixIcon: _codeController.text.length == 6
                ? Icon(Icons.check_circle, color: Colors.green)
                : null,
          ),
          onChanged: (value) {
            setState(() {});
            if (value.length == 6) {
              _verifyCode();
            }
          },
        ),
        
        const SizedBox(height: 12),
        
        // Timer et informations
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Expire dans: ${_formatTime(_remainingSeconds)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange[700],
              ),
            ),
            Text(
              '$_attemptsRemaining tentatives restantes',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Bouton vérifier
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_isLoading || _codeController.text.length < 6) 
                ? null 
                : _verifyCode,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.verified_user),
            label: Text(_isLoading ? 'Vérification...' : 'Vérifier le code'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Renvoyer le code ou changer de canal
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: _remainingSeconds == 0 ? _requestCode : null,
              child: Text(
                _remainingSeconds == 0 
                    ? 'Renvoyer le code'
                    : 'Renvoyer dans ${_formatTime(_remainingSeconds)}',
                style: TextStyle(color: primaryColor),
              ),
            ),
            TextButton(
              onPressed: _switchChannel,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _currentChannel == 'sms' ? Icons.chat : Icons.sms,
                    size: 16,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Changer vers ${_currentChannel == 'sms' ? 'WhatsApp' : 'SMS'}',
                    style: TextStyle(color: primaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildError(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, Color primaryColor) {
    return Row(
      children: [
        if (widget.onCancel != null)
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onCancel,
              child: const Text('Annuler'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        if (widget.onCancel != null) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, color: Colors.grey[600], size: 16),
                const SizedBox(width: 4),
                Text(
                  'Sécurisé par SMS',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Résultat de la vérification partner
class PartnerVerificationResult {
  final String phoneNumber;
  final bool isVerified;
  final DateTime verifiedAt;
  final List<String> payoutChannels;
  final String? detectedCarrier;
  final List<String> supportedPayments;

  PartnerVerificationResult({
    required this.phoneNumber,
    required this.isVerified,
    required this.verifiedAt,
    this.payoutChannels = const [],
    this.detectedCarrier,
    this.supportedPayments = const [],
  });
}
