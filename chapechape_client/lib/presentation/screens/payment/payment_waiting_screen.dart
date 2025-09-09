import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import 'package:chapechape_client/core/blocs/payment/payment_bloc.dart';
import 'package:chapechape_client/core/blocs/payment/payment_event.dart';
import 'package:chapechape_client/core/blocs/payment/payment_state.dart';
import 'package:chapechape_client/core/models/payment_model.dart';
import 'package:chapechape_client/presentation/widgets/loading_overlay.dart';
import 'package:chapechape_client/config/theme.dart';

class PaymentWaitingScreen extends StatefulWidget {
  final String method;
  final String transactionId;
  final String? paymentUrl;
  final DateTime expiresAt;
  final String? phoneNumber;

  const PaymentWaitingScreen({
    Key? key,
    required this.method,
    required this.transactionId,
    this.paymentUrl,
    required this.expiresAt,
    this.phoneNumber,
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
    context.pop();
  }

  void _launchExternalApp() async {
    if (widget.paymentUrl != null) {
      final uri = Uri.parse(widget.paymentUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
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
      onWillPop: () async {
        final confirm = await _showExitConfirmDialog();
        return confirm ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Paiement en cours'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<PaymentBloc>().add(
                    CheckPaymentStatus(paymentId: widget.transactionId),
                  ),
              tooltip: 'Actualiser le statut',
            ),
          ],
        ),
        body: BlocConsumer<PaymentBloc, PaymentState>(
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
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Animation et countdown
                  _buildAnimationSection(),

                  const SizedBox(height: 32),

                  // Instructions spécifiques au provider
                  _buildMethodSpecificInstructions(),

                  const SizedBox(height: 32),

                  // Détails du paiement
                  _buildPaymentDetails(),

                  const SizedBox(height: 32),

                  // Actions
                  _buildActionButtons(),
                ],
              ),
            );
          },
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
                      color: Colors.grey[600],
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
                children: [
                  Icon(icon, size: 20, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
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
                color: Colors.grey[600],
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
    return Column(
      children: [
        if (!_isExpired) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _retryPayment,
              icon: const Icon(Icons.refresh),
              label: const Text('Vérifier le statut'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
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
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _cancelPayment,
            icon: const Icon(Icons.cancel),
            label: const Text('Annuler le paiement'),
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
