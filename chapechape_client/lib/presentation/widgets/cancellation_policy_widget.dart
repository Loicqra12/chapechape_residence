import 'package:flutter/material.dart';
import 'package:chapechape_client/config/theme.dart';
import 'package:chapechape_client/core/models/cancellation_policy_model.dart';

class CancellationPolicyWidget extends StatelessWidget {
  final CancellationPolicy policy;
  final DateTime? checkInDate;
  final double? totalPrice;

  const CancellationPolicyWidget({
    Key? key,
    required this.policy,
    this.checkInDate,
    this.totalPrice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cancel_outlined,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  policy.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              policy.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Règles d\'annulation :',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...policy.rules.map((rule) => _buildRuleItem(context, rule)),
            if (checkInDate != null && totalPrice != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _buildRefundEstimate(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(BuildContext context, CancellationRule rule) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${rule.refundPercentage}%',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Jusqu\'à ${rule.timeBeforeCheckIn} heures avant l\'arrivée',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundEstimate(BuildContext context) {
    final now = DateTime.now();
    final hoursBeforeCheckIn = checkInDate!.difference(now).inHours;
    final refundAmount = policy.calculateRefund(totalPrice!, hoursBeforeCheckIn);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estimation du remboursement :',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Montant estimé :',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '${refundAmount.toStringAsFixed(2)} FCFA',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '(${hoursBeforeCheckIn} heures avant l\'arrivée)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
} 