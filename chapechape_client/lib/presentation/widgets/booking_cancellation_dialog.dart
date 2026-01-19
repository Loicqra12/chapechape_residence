import 'package:flutter/material.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/core/models/cancellation_policy_model.dart';
import 'package:chapechape_client/core/models/booking_model.dart';

class BookingCancellationDialog extends StatefulWidget {
  final Booking booking;
  final CancellationPolicy policy;
  final Function(String?) onConfirm;
  final VoidCallback onCancel;

  const BookingCancellationDialog({
    Key? key,
    required this.booking,
    required this.policy,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<BookingCancellationDialog> createState() => _BookingCancellationDialogState();
}

class _BookingCancellationDialogState extends State<BookingCancellationDialog> {
  final TextEditingController _reasonController = TextEditingController();
  double? _refundAmount;

  @override
  void initState() {
    super.initState();
    _calculateRefund();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _calculateRefund() {
    final now = DateTime.now();
    final hoursBeforeCheckIn = widget.booking.checkIn.difference(now).inHours;
    setState(() {
      _refundAmount = widget.policy.calculateRefund(
        widget.booking.totalPrice,
        hoursBeforeCheckIn,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 28,
          ),
          const SizedBox(width: 8),
          const Text('Annuler la réservation'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Êtes-vous sûr de vouloir annuler cette réservation ?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (_refundAmount != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Remboursement estimé',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Montant :'),
                        Text(
                          '${_refundAmount!.toStringAsFixed(2)} FCFA',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison d\'annulation (optionnelle)',
                border: OutlineInputBorder(),
                hintText: 'Expliquez la raison de votre annulation...',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Retour'),
        ),
        FilledButton(
          onPressed: () {
            widget.onConfirm(
              _reasonController.text.isNotEmpty ? _reasonController.text : null,
            );
          },
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirmer l\'annulation'),
        ),
      ],
    );
  }
} 