import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chapechape_client/core/models/modification_fees_model.dart';

class BookingModificationDialog extends StatelessWidget {
  final DateTime? newCheckIn;
  final DateTime? newCheckOut;
  final int? newNumberOfGuests;
  final ModificationFees fees;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const BookingModificationDialog({
    Key? key,
    this.newCheckIn,
    this.newCheckOut,
    this.newNumberOfGuests,
    required this.fees,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern('fr');

    return AlertDialog(
      title: const Text('Confirmer les modifications'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (newCheckIn != null || newCheckOut != null) ...[
            const Text('Nouvelles dates :',
                style: TextStyle(fontWeight: FontWeight.bold)),
            if (newCheckIn != null)
              Text('Arrivée : ${DateFormat.yMMMd('fr').format(newCheckIn!)}'),
            if (newCheckOut != null)
              Text('Départ : ${DateFormat.yMMMd('fr').format(newCheckOut!)}'),
            const SizedBox(height: 16),
          ],
          if (newNumberOfGuests != null) ...[
            const Text('Nouveau nombre de voyageurs :',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('$newNumberOfGuests voyageurs'),
            const SizedBox(height: 16),
          ],
          const Text('Frais de modification :',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Frais de base : ${numberFormat.format(fees.baseFee)} FCFA'),
          if (fees.priceDifference != 0)
            Text(
              'Différence de prix : ${fees.priceDifference > 0 ? '+' : ''}${numberFormat.format(fees.priceDifference)} FCFA',
              style: TextStyle(
                color: fees.priceDifference > 0 ? Colors.red : Colors.green,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Total : ${numberFormat.format(fees.totalFee)} FCFA',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          child: const Text('Confirmer'),
        ),
      ],
    );
  }
}
