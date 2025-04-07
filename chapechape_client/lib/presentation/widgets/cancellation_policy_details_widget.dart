import 'package:flutter/material.dart';
import 'package:chapechape_client/core/models/cancellation_policy_model.dart';
import 'package:chapechape_client/config/theme.dart';

class CancellationPolicyDetailsWidget extends StatelessWidget {
  final CancellationPolicy policy;
  final DateTime checkInDate;
  final double totalPrice;

  const CancellationPolicyDetailsWidget({
    Key? key,
    required this.policy,
    required this.checkInDate,
    required this.totalPrice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
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
                  'Politique d\'annulation',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              policy.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'Règles d\'annulation :',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...policy.rules.map((rule) => _buildRuleItem(context, rule)),
            const SizedBox(height: 24),
            _buildRefundEstimate(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(BuildContext context, CancellationRule rule) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
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
                  '${rule.timeBeforeCheckIn} heures avant le check-in',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (rule.description != null)
                  Text(
                    rule.description!,
                    style: Theme.of(context).textTheme.bodySmall,
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
    final hoursBeforeCheckIn = checkInDate.difference(now).inHours;
    final refundAmount = policy.calculateRefund(totalPrice, hoursBeforeCheckIn);
    final refundPercentage = (refundAmount / totalPrice * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estimation du remboursement :',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Montant estimé',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${refundAmount.toStringAsFixed(0)} FCFA',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pourcentage',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '$refundPercentage%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 