import 'package:flutter/material.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiements'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Solde actuel
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Solde actuel',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '2,500.00 €',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implémenter le retrait
                    },
                    child: const Text('Retirer les fonds'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Historique des transactions
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Historique des transactions',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const Divider(height: 1),
                _TransactionItem(
                  title: 'Réservation #1234',
                  amount: '+500.00 €',
                  date: '01 Mars 2025',
                  isCredit: true,
                ),
                const Divider(height: 1),
                _TransactionItem(
                  title: 'Retrait vers compte bancaire',
                  amount: '-1,000.00 €',
                  date: '28 Fév 2025',
                  isCredit: false,
                ),
                const Divider(height: 1),
                _TransactionItem(
                  title: 'Réservation #1233',
                  amount: '+750.00 €',
                  date: '25 Fév 2025',
                  isCredit: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String title;
  final String amount;
  final String date;
  final bool isCredit;

  const _TransactionItem({
    required this.title,
    required this.amount,
    required this.date,
    required this.isCredit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      title: Text(title),
      subtitle: Text(date),
      trailing: Text(
        amount,
        style: theme.textTheme.titleMedium?.copyWith(
          color: isCredit ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
