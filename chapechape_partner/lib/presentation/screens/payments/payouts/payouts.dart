import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/payment/payout_model.dart';
import '../../../../core/services/api/payment_service.dart';
import 'package:dio/dio.dart';

class PayoutHistoryScreen extends StatefulWidget {
  const PayoutHistoryScreen({super.key});

  @override
  State<PayoutHistoryScreen> createState() => _PayoutHistoryScreenState();
  
  // Méthode factory pour créer l'écran avec son propre service
  static Widget withService(BuildContext context) {
    final dio = Dio();
    final paymentService = PaymentService(dio);
    return _PayoutHistoryProvider(
      paymentService: paymentService,
      child: const PayoutHistoryScreen(),
    );
  }
}

class _PayoutHistoryScreenState extends State<PayoutHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  List<PayoutModel> _payouts = [];
  PayoutStats? _stats;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMoreData = true;
  PayoutStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadPayouts();
    _loadStats();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom && !_isLoading && _hasMoreData) {
      _loadMorePayouts();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  Future<void> _loadPayouts() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
      _currentPage = 1;
    });

    try {
      final paymentService = context.read<PaymentService>();
      final payouts = await paymentService.getPayouts(
        page: 1,
        status: _selectedStatus,
      );
      
      setState(() {
        _payouts = payouts;
        _hasMoreData = payouts.length >= 20; // Si on a reçu une page complète
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMorePayouts() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final paymentService = context.read<PaymentService>();
      final newPayouts = await paymentService.getPayouts(
        page: _currentPage + 1,
        status: _selectedStatus,
      );
      
      setState(() {
        _payouts.addAll(newPayouts);
        _currentPage++;
        _hasMoreData = newPayouts.length >= 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $e')),
        );
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final paymentService = context.read<PaymentService>();
      final stats = await paymentService.getPayoutStats();
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      // Silencieux, les stats ne sont pas critiques
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _loadPayouts(),
      _loadStats(),
    ]);
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterBottomSheet(
        selectedStatus: _selectedStatus,
        onStatusChanged: (status) {
          setState(() {
            _selectedStatus = status;
          });
          _loadPayouts();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Reversements'),
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
            icon: Icon(
              Icons.filter_list,
              color: _selectedStatus != null ? Colors.amber : Colors.white,
            ),
            onPressed: _showFilterDialog,
            tooltip: 'Filtrer',
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
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Section Statistiques
            if (_stats != null)
              SliverToBoxAdapter(
                child: _buildStatsSection(),
              ),
            
            // Section Filtres actifs
            if (_selectedStatus != null)
              SliverToBoxAdapter(
                child: _buildActiveFilters(),
              ),
            
            // Section Liste des payouts
            if (_hasError)
              SliverFillRemaining(
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
                        onPressed: _loadPayouts,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_payouts.isEmpty && !_isLoading)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucun reversement',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedStatus != null
                            ? 'Aucun reversement trouvé avec ce filtre'
                            : 'Vous n\'avez pas encore reçu de reversement',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_selectedStatus != null) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedStatus = null;
                            });
                            _loadPayouts();
                          },
                          child: const Text('Supprimer le filtre'),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < _payouts.length) {
                      return _buildPayoutCard(_payouts[index]);
                    } else if (_isLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return null;
                  },
                  childCount: _payouts.length + (_isLoading ? 1 : 0),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final stats = _stats!;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mes revenus',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total reçu',
                    stats.formattedTotalEarned,
                    Icons.account_balance_wallet,
                    Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'En attente',
                    stats.formattedTotalPending,
                    Icons.schedule,
                    Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Commissions',
                    stats.formattedTotalCommission,
                    Icons.percent,
                    Colors.white60,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Taux réussite',
                    '${(stats.successRate * 100).toStringAsFixed(1)}%',
                    Icons.trending_up,
                    Colors.white60,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (_selectedStatus != null)
            Chip(
              label: Text(_selectedStatus!.displayName),
              backgroundColor: _parseColor(_selectedStatus!.color),
              labelStyle: const TextStyle(color: Colors.white),
              deleteIcon: const Icon(Icons.close, color: Colors.white, size: 18),
              onDeleted: () {
                setState(() {
                  _selectedStatus = null;
                });
                _loadPayouts();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPayoutCard(PayoutModel payout) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showPayoutDetails(payout),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _parseColor(payout.status.color),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      payout.status.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    payout.formattedNetAmount,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Payout #${payout.payoutId}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Commission: ${payout.formattedCommissionAmount} (${payout.formattedCommissionRate})',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    payout.status == PayoutStatus.scheduled
                        ? 'Programmé le ${DateFormat('dd/MM/yyyy à HH:mm').format(payout.scheduledDate)}'
                        : payout.processedDate != null
                            ? 'Traité le ${DateFormat('dd/MM/yyyy à HH:mm').format(payout.processedDate!)}'
                            : 'Créé le ${DateFormat('dd/MM/yyyy').format(payout.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (payout.sourceTransactions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.receipt_long, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${payout.sourceTransactions.length} transaction(s) incluse(s)',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showPayoutDetails(PayoutModel payout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PayoutDetailsSheet(payout: payout),
    );
  }
}

// Bottom Sheet pour les filtres
class _FilterBottomSheet extends StatelessWidget {
  final PayoutStatus? selectedStatus;
  final Function(PayoutStatus?) onStatusChanged;

  const _FilterBottomSheet({
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrer par statut',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatusOption(null, 'Tous les statuts'),
          ...PayoutStatus.values.map((status) => _buildStatusOption(status, status.displayName)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatusOption(PayoutStatus? status, String label) {
    return RadioListTile<PayoutStatus?>(
      value: status,
      groupValue: selectedStatus,
      onChanged: onStatusChanged,
      title: Text(label),
      dense: true,
    );
  }
}

// Bottom Sheet pour les détails d'un payout
class _PayoutDetailsSheet extends StatelessWidget {
  final PayoutModel payout;

  const _PayoutDetailsSheet({required this.payout});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Détails du reversement',
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
                    _buildDetailRow('ID', payout.payoutId),
                    _buildDetailRow('Statut', payout.status.displayName),
                    _buildDetailRow('Date programmée', DateFormat('dd/MM/yyyy à HH:mm').format(payout.scheduledDate)),
                    if (payout.processedDate != null)
                      _buildDetailRow('Date traitement', DateFormat('dd/MM/yyyy à HH:mm').format(payout.processedDate!)),
                  ]),
                  const SizedBox(height: 16),
                  _buildDetailCard('Montants', [
                    _buildDetailRow('Montant brut', payout.formattedGrossAmount),
                    _buildDetailRow('Commission (${payout.formattedCommissionRate})', '- ${payout.formattedCommissionAmount}'),
                    _buildDetailRow('Montant net', payout.formattedNetAmount, isHighlighted: true),
                  ]),
                  if (payout.failureReason != null) ...[
                    const SizedBox(height: 16),
                    _buildDetailCard('Informations d\'erreur', [
                      _buildDetailRow('Raison', payout.failureReason!),
                    ]),
                  ],
                  if (payout.sourceTransactions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDetailCard('Transactions sources', 
                      payout.sourceTransactions.map((id) => _buildDetailRow('Transaction', id)).toList(),
                    ),
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
class _PayoutHistoryProvider extends StatelessWidget {
  final PaymentService paymentService;
  final Widget child;

  const _PayoutHistoryProvider({
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

extension _PayoutScreenHelpers on _PayoutHistoryScreenState {
  /// Parse une couleur hexadécimale de manière sécurisée
  Color _parseColor(String colorString) {
    try {
      // Nettoyer la chaîne
      String cleanColor = colorString.trim();
      
      // Ajouter # si manquant
      if (!cleanColor.startsWith('#')) {
        cleanColor = '#$cleanColor';
      }
      
      // Remplacer # par 0xFF pour Flutter
      final hexColor = cleanColor.replaceFirst('#', '0xFF');
      
      return Color(int.parse(hexColor));
    } catch (e) {
      // Fallback couleur par défaut si parsing échoue
      return Colors.grey;
    }
  }
}

// Alias pour faciliter l'import
typedef PayoutsScreen = PayoutHistoryScreen;