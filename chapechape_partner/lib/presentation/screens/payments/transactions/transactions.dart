import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/payment/payment_model.dart';
import '../../../../core/models/payment/payout_model.dart';
import '../../../../core/services/api/payment_service.dart';
import 'package:dio/dio.dart';

// Énumération pour les types de transaction unifiée
enum TransactionType { payment, payout, withdrawal }

// Classe de transaction unifiée pour l'affichage
class UnifiedTransaction {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final String formattedAmount;
  final DateTime date;
  final TransactionType type;
  final String status;
  final Color statusColor;
  final IconData icon;
  final Color iconColor;
  final String? sourceId;
  final Map<String, dynamic>? rawData;

  const UnifiedTransaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.formattedAmount,
    required this.date,
    required this.type,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.iconColor,
    this.sourceId,
    this.rawData,
  });

  // Factory pour créer à partir d'un PaymentModel
  factory UnifiedTransaction.fromPayment(PaymentModel payment) {
    final isCredit = payment.type == PaymentType.credit;
    return UnifiedTransaction(
      id: payment.id,
      title: isCredit ? 'Paiement reçu' : 'Retrait effectué',
      subtitle: payment.source,
      amount: payment.amount,
      formattedAmount: '${isCredit ? '+' : '-'}${payment.amount.toStringAsFixed(0)} XOF',
      date: payment.date,
      type: isCredit ? TransactionType.payment : TransactionType.withdrawal,
      status: _getPaymentStatusDisplay(payment.status),
      statusColor: _getPaymentStatusColor(payment.status),
      icon: isCredit ? Icons.arrow_downward : Icons.arrow_upward,
      iconColor: isCredit ? Colors.green : Colors.orange,
      sourceId: payment.sourceId,
      rawData: payment.toJson(),
    );
  }

  // Factory pour créer à partir d'un PayoutModel
  factory UnifiedTransaction.fromPayout(PayoutModel payout) {
    return UnifiedTransaction(
      id: payout.id,
      title: 'Reversement',
      subtitle: 'Payout #${payout.payoutId}',
      amount: payout.netAmount,
      formattedAmount: '+${payout.netAmount.toStringAsFixed(0)} XOF',
      date: payout.processedDate ?? payout.scheduledDate,
      type: TransactionType.payout,
      status: payout.status.displayName,
      statusColor: Color(int.parse(payout.status.color.replaceFirst('#', '0xFF'))),
      icon: Icons.account_balance,
      iconColor: Colors.blue,
      sourceId: payout.payoutId,
      rawData: payout.toJson(),
    );
  }

  static String _getPaymentStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
        return 'Terminé';
      case 'pending':
        return 'En attente';
      case 'failed':
        return 'Échec';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  static Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
  
  // Méthode factory pour créer l'écran avec son propre service
  static Widget withService(BuildContext context) {
    final dio = Dio();
    final paymentService = PaymentService(dio);
    return _TransactionsProvider(
      paymentService: paymentService,
      child: const TransactionsScreen(),
    );
  }
}

class _TransactionsScreenState extends State<TransactionsScreen> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  
  List<UnifiedTransaction> _allTransactions = [];
  List<UnifiedTransaction> _filteredTransactions = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  
  // Filtres
  TransactionType? _selectedType;
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _searchQuery;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Tous, Paiements, Reversements, Retraits
    _loadTransactions();
    _searchController.addListener(_onSearchChanged);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterTransactions();
  }

  void _onTabChanged() {
    switch (_tabController.index) {
      case 0:
        _selectedType = null;
        break;
      case 1:
        _selectedType = TransactionType.payment;
        break;
      case 2:
        _selectedType = TransactionType.payout;
        break;
      case 3:
        _selectedType = TransactionType.withdrawal;
        break;
    }
    _filterTransactions();
  }

  void _filterTransactions() {
    setState(() {
      _filteredTransactions = _allTransactions.where((transaction) {
        // Filtre par type
        if (_selectedType != null && transaction.type != _selectedType) {
          return false;
        }
        
        // Filtre par date
        if (_fromDate != null && transaction.date.isBefore(_fromDate!)) {
          return false;
        }
        if (_toDate != null && transaction.date.isAfter(_toDate!.add(const Duration(days: 1)))) {
          return false;
        }
        
        // Filtre par recherche
        if (_searchQuery != null && _searchQuery!.isNotEmpty) {
          final query = _searchQuery!.toLowerCase();
          return transaction.title.toLowerCase().contains(query) ||
                 transaction.subtitle.toLowerCase().contains(query) ||
                 transaction.formattedAmount.toLowerCase().contains(query);
        }
        
        return true;
      }).toList();
      
      // Trier par date (plus récent en premier)
      _filteredTransactions.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  Future<void> _loadTransactions() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final paymentService = context.read<PaymentService>();
      
      // Charger les transactions et payouts en parallèle
      final futures = await Future.wait([
        paymentService.getTransactions(),
        paymentService.getPayouts(),
      ]);
      
      final transactionResult = futures[0] as TransactionResult;
      final payouts = futures[1] as List<PayoutModel>;
      
      // Convertir en transactions unifiées
      final unifiedTransactions = <UnifiedTransaction>[];
      
      // Ajouter les payments
      for (final payment in transactionResult.transactions) {
        unifiedTransactions.add(UnifiedTransaction.fromPayment(payment));
      }
      
      // Ajouter les payouts
      for (final payout in payouts) {
        unifiedTransactions.add(UnifiedTransaction.fromPayout(payout));
      }
      
      setState(() {
        _allTransactions = unifiedTransactions;
        _isLoading = false;
      });
      
      _filterTransactions();
      
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadTransactions();
  }

  void _showDateFilter() {
    showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    ).then((dateRange) {
      if (dateRange != null) {
        setState(() {
          _fromDate = dateRange.start;
          _toDate = dateRange.end;
        });
        _filterTransactions();
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _searchQuery = null;
      _searchController.clear();
    });
    _filterTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            style: IconButton.styleFrom(
              shape: const CircleBorder(),
              side: const BorderSide(color: Colors.white54),
              backgroundColor: Colors.transparent,
            ),
            icon: const Icon(Icons.date_range),
            onPressed: _showDateFilter,
            tooltip: 'Filtrer par date',
          ),
          if (_fromDate != null || _toDate != null || _searchQuery != null)
            IconButton(
              style: IconButton.styleFrom(
                shape: const CircleBorder(),
                side: const BorderSide(color: Colors.white54),
                backgroundColor: Colors.transparent,
              ),
              icon: const Icon(Icons.clear),
              onPressed: _clearFilters,
              tooltip: 'Effacer les filtres',
            ),
          IconButton(
            style: IconButton.styleFrom(
              shape: const CircleBorder(),
              side: const BorderSide(color: Colors.white54),
              backgroundColor: Colors.transparent,
            ),
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Toutes'),
            Tab(text: 'Paiements'),
            Tab(text: 'Reversements'),
            Tab(text: 'Retraits'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Column(
          children: [
            // Barre de recherche
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher une transaction...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: (value) {
                  _searchQuery = value.isEmpty ? null : value;
                  _filterTransactions();
                },
              ),
            ),
            
            // Filtres actifs
            if (_fromDate != null || _toDate != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.date_range, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            _fromDate != null && _toDate != null
                                ? '${DateFormat('dd/MM').format(_fromDate!)} - ${DateFormat('dd/MM').format(_toDate!)}'
                                : 'Période sélectionnée',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _fromDate = null;
                                _toDate = null;
                              });
                              _filterTransactions();
                            },
                            child: const Icon(Icons.close, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            // Liste des transactions
            Expanded(
              child: _buildTransactionsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Une erreur est survenue',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadTransactions,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_filteredTransactions.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aucune transaction',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedType != null || _searchQuery != null || _fromDate != null
                      ? 'Aucune transaction trouvée avec ces filtres'
                      : 'Vous n\'avez pas encore de transactions',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_selectedType != null || _searchQuery != null || _fromDate != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _clearFilters,
                    child: const Text('Effacer les filtres'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _filteredTransactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(UnifiedTransaction transaction) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showTransactionDetails(transaction),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône du type de transaction
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: transaction.iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  transaction.icon,
                  color: transaction.iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Informations de la transaction
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: transaction.statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            transaction.status,
                            style: TextStyle(
                              fontSize: 12,
                              color: transaction.statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd/MM/yyyy à HH:mm').format(transaction.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Montant
              Text(
                transaction.formattedAmount,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: transaction.type == TransactionType.withdrawal
                      ? Colors.orange
                      : Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(UnifiedTransaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _TransactionDetailsSheet(transaction: transaction),
    );
  }
}

// Bottom Sheet pour les détails d'une transaction
class _TransactionDetailsSheet extends StatelessWidget {
  final UnifiedTransaction transaction;

  const _TransactionDetailsSheet({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Détails de la transaction',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailCard('Informations générales', [
                    _buildDetailRow('Type', transaction.title),
                    _buildDetailRow('Description', transaction.subtitle),
                    _buildDetailRow('Montant', transaction.formattedAmount, isHighlighted: true),
                    _buildDetailRow('Statut', transaction.status),
                    _buildDetailRow('Date', DateFormat('dd/MM/yyyy à HH:mm').format(transaction.date)),
                    if (transaction.sourceId != null)
                      _buildDetailRow('ID source', transaction.sourceId!),
                  ]),
                  const SizedBox(height: 16),
                  if (transaction.rawData != null) ...[
                    _buildDetailCard('Données techniques', [
                      _buildDetailRow('ID transaction', transaction.id),
                      _buildDetailRow('Type système', transaction.type.name),
                    ]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                color: isHighlighted ? Colors.green : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Provider pour injecter le PaymentService
class _TransactionsProvider extends StatelessWidget {
  final PaymentService paymentService;
  final Widget child;

  const _TransactionsProvider({
    required this.paymentService,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Provider<PaymentService>.value(
      value: paymentService,
      child: child,
    );
  }
}