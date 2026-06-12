import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/blocs/payment/payment_bloc.dart';
import '../../../core/models/payment/payment_model.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../../core/services/api/payment_service.dart';
import './payments_methods_tab.dart';
import 'package:dio/dio.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
  
  // Méthode factory pour créer l'écran avec son propre BlocProvider
  static Widget withBloc(BuildContext context) {
    return BlocProvider<PaymentBloc>(
      create: (context) {
        final dio = Dio();
        final paymentService = PaymentService(dio);
        return PaymentBloc(paymentService: paymentService);
      },
      child: const PaymentsScreen(),
    );
  }
}

class _PaymentsScreenState extends State<PaymentsScreen> with SingleTickerProviderStateMixin {  
  // TabController pour gérer les onglets
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    // Initialiser le TabController
    _tabController = TabController(length: 2, vsync: this);
    
    // Charger les données de paiement au démarrage
    context.read<PaymentBloc>().add(const LoadPayments());
    
    // Configuration du scroll pour la pagination
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    if (_isBottom) {
      final state = context.read<PaymentBloc>().state;
      if (state is PaymentsLoaded && !state.hasReachedMax) {
        context.read<PaymentBloc>().add(
          LoadPayments(page: state.currentPage + 1),
        );
      }
    }
  }
  
  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
  
  void _showWithdrawDialog() {
    final TextEditingController amountController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer des fonds'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Montant',
                  hintText: 'Entrez le montant à retirer',
                  prefixText: 'FCFA ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un montant';
                  }
                  
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return 'Montant invalide';
                  }
                  
                  if (amount <= 0) {
                    return 'Le montant doit être supérieur à 0';
                  }
                  
                  final state = context.read<PaymentBloc>().state;
                  if (state is PaymentsLoaded) {
                    if (amount > state.balance) {
                      return 'Montant supérieur à votre solde';
                    }
                  }
                  
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Méthode de paiement',
                  border: OutlineInputBorder(),
                ),
                value: 'bank_transfer',
                items: const [
                  DropdownMenuItem(
                    value: 'bank_transfer',
                    child: Text('Virement bancaire'),
                  ),
                  DropdownMenuItem(
                    value: 'mobile_money',
                    child: Text('Mobile Money'),
                  ),
                ],
                onChanged: (value) {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Les reversements sont automatiques après chaque réservation payée. '
                    'Consultez l\'onglet Reversements pour le détail.',
                  ),
                  duration: Duration(seconds: 5),
                ),
              );
            },
            child: const Text('COMPRIS'),
          ),
        ],
      ),
    );
  }
  
  void _showTransactionDetails(PaymentModel transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          transaction.type == PaymentType.credit 
              ? 'Détails du paiement reçu'
              : 'Détails du retrait',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ID Transaction', transaction.id),
            _buildDetailRow('Statut', _getStatusText(transaction.status)),
            _buildDetailRow('Date', DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(transaction.date)),
            
            // Si c'est un crédit, on affiche la source (réservation)
            if (transaction.type == PaymentType.credit)
              _buildDetailRow('Source', transaction.source),
            
            // Si la transaction a un ID source (réservation), on l'affiche
            if (transaction.sourceId != null)
              _buildDetailRow('ID Réservation', transaction.sourceId!),
            
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            
            // Section financière
            Text(
              'Détails financiers',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Afficher le montant original si disponible
            if (transaction.originalAmount != null)
              _buildDetailRow(
                'Montant brut', 
                _formatCurrency(transaction.originalAmount!),
                valueStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            
            // Afficher la commission si disponible
            if (transaction.commissionRate != null && transaction.commissionAmount != null)
              _buildDetailRow(
                'Commission ChapeChape (${(transaction.commissionRate! * 100).toStringAsFixed(0)}%)',
                '- ${_formatCurrency(transaction.commissionAmount!)}',
                valueStyle: const TextStyle(color: Colors.red),
              ),
              
            // Ajouter un séparateur si commission
            if (transaction.commissionRate != null) 
              const Divider(height: 16, indent: 100, endIndent: 20),
            
            // Montant net (toujours affiché)
            _buildDetailRow(
              transaction.commissionRate != null ? 'Montant net reçu' : 'Montant',
              _formatCurrency(transaction.amount),
              valueStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: transaction.commissionRate != null ? Colors.green.shade700 : null,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Fermer'),
          ),
          if (transaction.type == PaymentType.withdrawal && transaction.status == 'pending')
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Demander confirmation avant d'annuler
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmer l\'annulation'),
                    content: const Text('Êtes-vous sûr de vouloir annuler cette demande de retrait ?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Non'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Annuler le retrait
                          context.read<PaymentBloc>().add(
                            CancelWithdrawal(transactionId: transaction.id),
                          );
                          Navigator.of(context).pop();
                        },
                        child: const Text('Oui, annuler'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Annuler le retrait'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
        ],
      ),
    );
  }
  
  // Formater un montant en devise
  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'completed':
        return 'Complété';
      case 'cancelled':
        return 'Annulé';
      case 'failed':
        return 'Échoué';
      default:
        return status;
    }
  }

  Widget _buildDetailRow(
    String label, 
    String value, {
    TextStyle? labelStyle,
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: labelStyle ?? const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is PaymentActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is PaymentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiements'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Transactions', icon: Icon(Icons.account_balance_wallet)),
            Tab(text: 'Méthodes de paiement', icon: Icon(Icons.payment)),
          ],
        ),
        actions: [
              IconButton(
                style: IconButton.styleFrom(
                  shape: const CircleBorder(),
                  side: BorderSide(color: Colors.grey.shade300),
                  backgroundColor: Colors.transparent,
                ),
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  context.read<PaymentBloc>().add(const RefreshPayments());
                },
              ),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildTransactionsTab(context, state),
              _buildPaymentMethodsTab(context),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildTransactionsTab(BuildContext context, PaymentState state) {
    if (state is PaymentInitial || (state is PaymentLoading && state is! PaymentsLoaded)) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state is PaymentError && state is! PaymentsLoaded) {
      return ErrorStateWidget(
        message: state.message,
        onRetry: () {
          context.read<PaymentBloc>().add(const LoadPayments());
        },
      );
    }
    
    if (state is PaymentsLoaded) {
      return RefreshIndicator(
        onRefresh: () async {
          context.read<PaymentBloc>().add(const RefreshPayments());
        },
        child: ListView(
          controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          // Solde actuel
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Solde actuel',
                      style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                      NumberFormat.currency(
                        locale: 'fr_FR',
                        symbol: 'FCFA',
                        decimalDigits: 0,
                      ).format(state.balance),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: state.balance > 0 ? _showWithdrawDialog : null,
                    child: const Text('Retirer les fonds'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
            
            // Résumé des revenus
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Résumé',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryItem(
                            context,
                            'Revenus du mois',
                            NumberFormat.currency(
                              locale: 'fr_FR',
                              symbol: 'FCFA',
                              decimalDigits: 0,
                            ).format(state.monthlyRevenue),
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryItem(
                            context,
                            'Total des retraits',
                            NumberFormat.currency(
                              locale: 'fr_FR',
                              symbol: 'FCFA',
                              decimalDigits: 0,
                            ).format(state.totalWithdrawals),
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Historique des transactions
            if (state.transactions.isEmpty)
              const EmptyStateWidget(
                icon: Icons.payment,
                title: 'Aucune transaction',
                message: 'Vous n\'avez pas encore de transactions',
              )
            else
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Historique des transactions',
                        style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Divider(height: 1),
                    ...state.transactions.map((transaction) {
                      return Column(
                        children: [
                _TransactionItem(
                            transaction: transaction,
                            onTap: () => _showTransactionDetails(transaction),
                          ),
                          if (transaction != state.transactions.last)
                const Divider(height: 1),
                        ],
                      );
                    }).toList(),
                    
                    if (state.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    
                    if (!state.hasReachedMax && !state.isLoading)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: TextButton(
                            onPressed: () {
                              context.read<PaymentBloc>().add(
                                LoadPayments(page: state.currentPage + 1),
                              );
                            },
                            child: const Text('Charger plus'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      );
    }
    
    return const EmptyStateWidget(
      icon: Icons.payment,
      title: 'Aucune transaction',
      message: 'Vous n\'avez pas encore de transactions',
    );
  }
  
  Widget _buildSummaryItem(
    BuildContext context,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsTab(BuildContext context) {
    return const PaymentMethodsTab();
  }
}

class _TransactionItem extends StatelessWidget {
  final PaymentModel transaction;
  final VoidCallback onTap;

  const _TransactionItem({
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');

    return ListTile(
      title: Text(transaction.source),
      subtitle: Text(dateFormat.format(transaction.date)),
      trailing: Text(
        NumberFormat.currency(
          locale: 'fr_FR',
          symbol: 'FCFA',
          decimalDigits: 0,
        ).format(transaction.amount),
        style: theme.textTheme.titleMedium?.copyWith(
          color: transaction.type == PaymentType.credit ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: onTap,
    );
  }
}

