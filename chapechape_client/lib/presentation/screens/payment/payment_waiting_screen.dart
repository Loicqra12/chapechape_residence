import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chapechape_client/core/blocs/payment/payment_bloc.dart';
import 'package:chapechape_client/core/blocs/payment/payment_event.dart';
import 'package:chapechape_client/core/blocs/payment/payment_state.dart';
import 'package:chapechape_client/core/models/payment_model.dart';
import 'package:chapechape_client/config/theme.dart';
import 'package:chapechape_client/core/theme/app_theme.dart' as chape_theme;

/// Bleu proche des flows Wave / concurrents (CTA « ouvrir Wave »).
const Color _kWaveBrandBlue = Color(0xFF0055D4);
const Color _kWaveLogoDisk = Color(0xFFE8F4FF);

String _userFacingPaymentError(String raw) {
  final t = raw.toLowerCase();
  if (t.contains('null') && t.contains('subtype')) {
    return 'Une erreur technique est survenue. Réessayez ou vérifiez le statut du paiement.';
  }
  if (t.contains('socket') || t.contains('timeout')) {
    return 'Problème de connexion. Vérifiez le réseau et réessayez.';
  }
  return raw;
}

class PaymentWaitingScreen extends StatefulWidget {
  final String method;
  final String transactionId;
  final String? paymentUrl;
  final DateTime expiresAt;
  final String? phoneNumber;
  /// Retour cible : `/payment/:reservationId` (flux réservation).
  final String? reservationId;
  /// Retour cible : `/payment/:paymentId` (flux consultation paiement).
  final String? paymentId;

  const PaymentWaitingScreen({
    Key? key,
    required this.method,
    required this.transactionId,
    this.paymentUrl,
    required this.expiresAt,
    this.phoneNumber,
    this.reservationId,
    this.paymentId,
  }) : super(key: key);

  @override
  State<PaymentWaitingScreen> createState() => _PaymentWaitingScreenState();
}

class _PaymentWaitingScreenState extends State<PaymentWaitingScreen>
    with TickerProviderStateMixin {
  Timer? _statusCheckTimer;
  Timer? _countdownTimer;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  int _remainingSeconds = 0;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();

    // Calculer le temps restant
    _remainingSeconds = widget.expiresAt.difference(DateTime.now()).inSeconds;

    // Initialiser les animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Démarrer le polling du statut (toutes les 8 secondes)
    _startStatusPolling();

    // Démarrer le countdown
    _startCountdown();
  }

  void _startStatusPolling() {
    // Garde-fou: ne pas démarrer le polling sans transactionId valide
    if (widget.transactionId.isEmpty) {
      setState(() {
        _isExpired = true;
      });
      return;
    }
    
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && !_isExpired) {
        context.read<PaymentBloc>().add(
              CheckPaymentStatus(paymentId: widget.transactionId),
            );
      }
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
          if (_remainingSeconds <= 0) {
            _isExpired = true;
            _countdownTimer?.cancel();
            _statusCheckTimer?.cancel();
          }
        });
      }
    });
  }

  void _retryPayment() {
    // ✅ ANTI-DOUBLON : Relancer le polling au lieu de créer un nouveau paiement
    if (widget.transactionId.isNotEmpty) {
      context.read<PaymentBloc>().add(
        CheckPaymentStatus(paymentId: widget.transactionId),
      );
      
      // Redémarrer le timer de polling
      _startStatusPolling();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vérification du statut du paiement...'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _cancelPayment() {
    context.read<PaymentBloc>().add(
          CancelPayment(
            paymentId: widget.transactionId,
            reason: 'Annulation utilisateur',
          ),
        );
    _navigateBackFromWaiting();
  }

  /// Après confirmation : pile si possible, sinon écran paiement de la même réservation / même id, sinon accueil.
  void _navigateBackFromWaiting() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
      return;
    }
    final rid = widget.reservationId?.trim();
    if (rid != null && rid.isNotEmpty) {
      context.go('/payment/$rid');
      return;
    }
    final pid = widget.paymentId?.trim();
    if (pid != null && pid.isNotEmpty) {
      context.go('/payment/$pid');
      return;
    }
    context.go('/home');
  }

  Future<void> _handleBack() async {
    final confirm = await _showExitConfirmDialog();
    if (confirm != true || !mounted) return;
    _navigateBackFromWaiting();
  }

  Future<bool> _onWillPop() async {
    final confirm = await _showExitConfirmDialog();
    if (confirm != true || !mounted) return false;
    _navigateBackFromWaiting();
    return false;
  }

  Future<void> _launchExternalApp() async {
    final url = widget.paymentUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lien de paiement indisponible.')),
        );
      }
      return;
    }
    try {
      var ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impossible d\'ouvrir le lien. Copiez l\'URL depuis les détails ou utilisez votre navigateur.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ouverture impossible : ${e.toString()}')),
        );
      }
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Retour',
            onPressed: _handleBack,
          ),
          iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
          title: Text(
            'Paiement en cours',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              color: Theme.of(context).colorScheme.onSurface,
              onPressed: () => context.read<PaymentBloc>().add(
                    CheckPaymentStatus(paymentId: widget.transactionId),
                  ),
              tooltip: 'Actualiser le statut',
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          maintainBottomViewPadding: true,
          child: BlocConsumer<PaymentBloc, PaymentState>(
          listener: (context, state) {
            if (state is PaymentStatusChecked) {
              if (state.payment.status == PaymentStatus.succeeded) {
                context.go('/payment/success/${widget.transactionId}');
              } else if (state.payment.status == PaymentStatus.failed) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Le paiement a échoué'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } else if (state is PaymentError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_userFacingPaymentError(state.message)),
                ),
              );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: widget.method == 'wave'
                  ? _buildWaveWaitingLayout()
                  : Column(
                      children: [
                        _buildAnimationSection(),
                        const SizedBox(height: 32),
                        _buildMethodSpecificInstructions(),
                        const SizedBox(height: 32),
                        _buildPaymentDetails(),
                        const SizedBox(height: 32),
                        _buildActionButtons(),
                      ],
                    ),
            );
          },
        ),
        ),
      ),
    );
  }

  Widget _buildAnimationSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Animation principale
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.1),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isExpired
                          ? Colors.red.withOpacity(0.2)
                          : AppTheme.primaryColor.withOpacity(0.2),
                      border: Border.all(
                        color: _isExpired ? Colors.red : AppTheme.primaryColor,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      _getMethodIcon(),
                      size: 60,
                      color: _isExpired ? Colors.red : AppTheme.primaryColor,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Countdown
            if (!_isExpired) ...[
              Text(
                'Temps restant',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatTime(_remainingSeconds),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _remainingSeconds < 60
                          ? Colors.red
                          : AppTheme.primaryColor,
                    ),
              ),
            ] else ...[
              Text(
                'Temps expiré',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Flux Wave : hiérarchie type app concurrente (logo + arc, message, CTA flèche, pied de page).
  Widget _buildWaveWaitingLayout() {
    final theme = Theme.of(context);
    final subtle = theme.colorScheme.onSurface.withOpacity(0.72);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildWaveHeroCard(),
        const SizedBox(height: 28),
        Text(
          'Validez depuis l’application Wave',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Vous pouvez aussi ouvrir le lien dans votre navigateur pour finaliser le paiement.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: subtle, height: 1.4),
        ),
        const SizedBox(height: 16),
        Text(
          'Après validation, patientez quelques instants. Vous serez informé du statut de votre paiement.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: subtle, height: 1.45),
        ),
        const SizedBox(height: 28),
        if (widget.paymentUrl != null && widget.paymentUrl!.isNotEmpty)
          _buildWaveOpenButton()
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Lien Wave indisponible. Utilisez « Vérifier le statut » ou contactez le support.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: subtle),
            ),
          ),
        const SizedBox(height: 24),
        _buildWaveQuickSteps(),
        const SizedBox(height: 28),
        _buildPaymentDetails(),
        const SizedBox(height: 28),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildWaveHeroCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          children: [
            SizedBox(
              width: 158,
              height: 158,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(158, 158),
                        painter: _WaveWaitingArcPainter(
                          progress: _rotationController.value,
                          color: _isExpired ? Colors.red : _kWaveBrandBlue,
                        ),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.05),
                        child: _buildWaveLogoCore(),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (!_isExpired) ...[
              Text(
                'Temps restant',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.75),
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatTime(_remainingSeconds),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: _remainingSeconds < 60
                          ? Colors.red
                          : _kWaveBrandBlue,
                    ),
              ),
            ] else
              Text(
                'Temps expiré',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveLogoCore() {
    return Container(
      width: 96,
      height: 96,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: _kWaveLogoDisk,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Image.asset(
          'assets/images/payment/wave_money.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/icons/wave.png',
              fit: BoxFit.contain,
              errorBuilder: (context, e, st) {
                return Icon(Icons.waves_rounded, size: 44, color: _kWaveBrandBlue);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildWaveOpenButton() {
    return Material(
      color: _kWaveBrandBlue,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: _launchExternalApp,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.smartphone_rounded, color: Colors.white, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ouvrir Wave',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaveQuickSteps() {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded, color: _kWaveBrandBlue, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Rappel',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildWaveStepLine(
              '1',
              'Ouvrez votre application Wave ou le lien dans le navigateur.',
            ),
            const SizedBox(height: 10),
            _buildWaveStepLine(
              '2',
              'Validez le paiement avec votre code PIN Wave.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveStepLine(String index, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _kWaveBrandBlue,
            shape: BoxShape.circle,
          ),
          child: Text(
            index,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodSpecificInstructions() {
    switch (widget.method) {
      case 'wave':
        return _buildWaveInstructions();
      case 'orange_money':
      case 'om':
        return _buildOrangeMoneyInstructions();
      case 'moov_money':
        return _buildMoovMoneyInstructions();
      case 'mtn_money':
      case 'momo':
        return _buildMtnMoneyInstructions();
      default:
        return _buildGenericInstructions();
    }
  }

  Widget _buildWaveInstructions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/icons/wave.png',
                  width: 32,
                  height: 32,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.payment, size: 32),
                ),
                const SizedBox(width: 12),
                Text(
                  'Instructions Wave',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInstructionStep(
              step: '1',
              title: 'Ouvrez votre app Wave',
              description: 'Lancez l\'application Wave sur votre téléphone',
              icon: Icons.phone_android,
            ),
            const SizedBox(height: 16),
            _buildInstructionStep(
              step: '2',
              title: 'Validez avec votre PIN',
              description: 'Confirmez le paiement avec votre code PIN Wave',
              icon: Icons.lock,
            ),
            const SizedBox(height: 20),
            if (widget.paymentUrl != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _launchExternalApp,
                  icon: const Icon(Icons.launch),
                  label: const Text('Ouvrir Wave'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4AA),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrangeMoneyInstructions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/icons/orange_money.png',
                  width: 32,
                  height: 32,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.payment, size: 32),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Instructions Orange Money',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInstructionStep(
              step: '1',
              title: 'Vérifiez votre téléphone',
              description: 'Un SMS avec le code USSD a été envoyé',
              icon: Icons.sms,
            ),
            const SizedBox(height: 16),
            _buildInstructionStep(
              step: '2',
              title: 'Composez le code USSD',
              description:
                  'Composez le code reçu par SMS ou approuvez la notification',
              icon: Icons.dialpad,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Code USSD marchand: *144*1*1#',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMtnMoneyInstructions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/icons/mtn_money.png',
                  width: 32,
                  height: 32,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.payment, size: 32),
                ),
                const SizedBox(width: 12),
                Text(
                  'MTN Money',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.yellow[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInstructionStep(
              step: '1',
              title: 'Composez *133#',
              description: 'Depuis votre téléphone MTN',
              icon: Icons.dialpad,
            ),
            const SizedBox(height: 12),
            _buildInstructionStep(
              step: '2',
              title: 'Paiement marchand',
              description: 'Choisissez "Paiement marchand" puis entrez les détails',
              icon: Icons.arrow_forward,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.yellow[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Code USSD marchand: *133*1*1#',
                      style: TextStyle(
                        color: Colors.yellow[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoovMoneyInstructions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/icons/moov_money.png',
                  width: 32,
                  height: 32,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.payment, size: 32),
                ),
                const SizedBox(width: 12),
                Text(
                  'Moov Money',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInstructionStep(
              step: '1',
              title: 'Composez *155#',
              description: 'Depuis votre téléphone Moov',
              icon: Icons.dialpad,
            ),
            const SizedBox(height: 12),
            _buildInstructionStep(
              step: '2',
              title: 'Paiement marchand',
              description: 'Choisissez "Paiement marchand" puis entrez les détails',
              icon: Icons.arrow_forward,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Code USSD marchand: *155*1*1#',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMtnMoovInstructions() {
    final providerName =
        widget.method == 'mtn_money' ? 'MTN Money' : 'Moov Money';
    final color =
        widget.method == 'mtn_money' ? Colors.yellow[700] : Colors.blue[700];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  widget.method == 'mtn_money'
                      ? 'assets/icons/mtn_money.png'
                      : 'assets/icons/moov_money.png',
                  width: 32,
                  height: 32,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.payment, size: 32),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Instructions $providerName',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInstructionStep(
              step: '1',
              title: 'Notification reçue',
              description:
                  'Une notification push a été envoyée sur votre téléphone',
              icon: Icons.notifications,
            ),
            const SizedBox(height: 16),
            _buildInstructionStep(
              step: '2',
              title: 'Approuvez le paiement',
              description: 'Confirmez avec votre code secret $providerName',
              icon: Icons.verified_user,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color?.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: color?.withOpacity(0.3) ?? Colors.grey),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vérifiez votre téléphone ${widget.phoneNumber ?? ''}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenericInstructions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: Theme.of(context).primaryColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'Instructions de Paiement',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInstructionStep(
              step: '1',
              title: 'Vérifiez votre téléphone',
              description: 'Une notification a été envoyée sur votre téléphone',
              icon: Icons.phone_android,
            ),
            const SizedBox(height: 16),
            _buildInstructionStep(
              step: '2',
              title: 'Confirmez le paiement',
              description: 'Suivez les instructions pour confirmer',
              icon: Icons.check_circle_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep({
    required String step,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryColor,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(icon, size: 20, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetails() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détails du paiement',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 24),
            _buildDetailRow('Méthode', _getMethodDisplayName()),
            if (widget.phoneNumber != null)
              _buildDetailRow('Téléphone', widget.phoneNumber!),
            _buildDetailRow('Transaction ID', widget.transactionId),
            _buildDetailRow('Expire à', _formatDateTime(widget.expiresAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final waveChapeGold = widget.method == 'wave';
    return Column(
      children: [
        if (!_isExpired) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _retryPayment,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Vérifier le statut'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: waveChapeGold
                    ? chape_theme.AppTheme.primaryColor
                    : null,
                foregroundColor: waveChapeGold
                    ? chape_theme.AppTheme.textPrimary
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _retryPayment,
              icon: const Icon(Icons.replay),
              label: const Text('Réessayer le paiement'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: waveChapeGold
                    ? chape_theme.AppTheme.primaryColor
                    : null,
                foregroundColor: waveChapeGold
                    ? chape_theme.AppTheme.textPrimary
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _cancelPayment,
            icon: Icon(
              Icons.cancel_outlined,
              color: waveChapeGold
                  ? chape_theme.AppTheme.darkGold
                  : null,
            ),
            label: Text(
              'Annuler le paiement',
              style: waveChapeGold
                  ? TextStyle(
                      color: chape_theme.AppTheme.darkGold,
                      fontWeight: FontWeight.w600,
                    )
                  : null,
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<bool?> _showExitConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Êtes-vous sûr ?'),
        content: const Text(
            'Si vous quittez maintenant, votre paiement pourrait être interrompu. '
            'Êtes-vous sûr de vouloir quitter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('RESTER'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('QUITTER'),
          ),
        ],
      ),
    );
  }

  IconData _getMethodIcon() {
    switch (widget.method) {
      case 'wave':
        return Icons.waves;
      case 'orange_money':
      case 'om':
        return Icons.phone_android;
      case 'moov_money':
        return Icons.mobile_friendly;
      case 'mtn_money':
      case 'momo':
        return Icons.smartphone;
      default:
        return Icons.payment;
    }
  }

  String _getMethodDisplayName() {
    switch (widget.method) {
      case 'wave':
        return 'Wave';
      case 'orange_money':
      case 'om':
        return 'Orange Money';
      case 'moov_money':
        return 'Moov Money';
      case 'mtn_money':
      case 'momo':
        return 'MTN Money';
      default:
        return 'Paiement mobile';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} à '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }
}

/// Arc animé autour du logo (effet « en cours », proche des apps de référence Wave).
class _WaveWaitingArcPainter extends CustomPainter {
  _WaveWaitingArcPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2 - 4;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    const start = -math.pi * 0.88;
    final sweep = math.pi * 1.76 * (0.32 + 0.68 * progress);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      start,
      sweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _WaveWaitingArcPainter old) =>
      old.progress != progress || old.color != color;
}
