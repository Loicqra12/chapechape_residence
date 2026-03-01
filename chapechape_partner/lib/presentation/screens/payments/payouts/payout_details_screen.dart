import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/payment/payout_model.dart';
import '../../../../core/services/api/payment_service.dart';
import 'package:dio/dio.dart';

class PayoutDetailsScreen extends StatefulWidget {
  final String payoutId;

  const PayoutDetailsScreen({
    Key? key,
    required this.payoutId,
  }) : super(key: key);

  @override
  State<PayoutDetailsScreen> createState() => _PayoutDetailsScreenState();
}

class _PayoutDetailsScreenState extends State<PayoutDetailsScreen> {
  PayoutModel? _payout;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  late PaymentService _paymentService;

  @override
  void initState() {
    super.initState();
    final dio = Dio();
    _paymentService = PaymentService(dio);
    _loadPayoutDetails();
  }

  void _loadPayoutDetails() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final payout = await _paymentService.getPayoutDetails(widget.payoutId);
      setState(() {
        _payout = payout;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du reversement'),
        centerTitle: true,
        actions: [
          IconButton(
            style: IconButton.styleFrom(
              shape: const CircleBorder(),
              side: BorderSide(color: Colors.grey.shade300),
              backgroundColor: Colors.transparent,
            ),
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayoutDetails,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_payout == null) {
      return _buildEmptyState();
    }

    return _buildPayoutDetails();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Une erreur inattendue s\'est produite',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPayoutDetails,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Reversement introuvable',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Ce reversement n\'existe pas ou a été supprimé',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildAmountCard(),
          const SizedBox(height: 16),
          _buildDatesCard(),
          const SizedBox(height: 16),
          _buildPartnerCard(),
          if (_payout!.failureReason != null) ...[
            const SizedBox(height: 16),
            _buildErrorCard(),
          ],
          if (_payout!.sourceTransactions.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildTransactionsCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final statusColor = _getStatusColor(_payout!.status);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Statut du reversement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _payout!.status.displayName,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('ID Reversement', _payout!.payoutId),
            if (_payout!.transactionId != null)
              _buildDetailRow('ID CinetPay', _payout!.transactionId!),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.monetization_on, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Détails financiers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Montant brut', _payout!.formattedGrossAmount),
            _buildDetailRow(
              'Commission (${_payout!.formattedCommissionRate})',
              '- ${_payout!.formattedCommissionAmount}',
            ),
            const Divider(),
            _buildDetailRow(
              'Montant net',
              _payout!.formattedNetAmount,
              isHighlighted: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.schedule, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Dates importantes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Programmé le',
              DateFormat('dd/MM/yyyy à HH:mm').format(_payout!.scheduledDate),
            ),
            if (_payout!.processedDate != null)
              _buildDetailRow(
                'Traité le',
                DateFormat('dd/MM/yyyy à HH:mm').format(_payout!.processedDate!),
              ),
            _buildDetailRow(
              'Créé le',
              DateFormat('dd/MM/yyyy à HH:mm').format(_payout!.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Informations partenaire',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Partenaire', _payout!.partnerId),
            if (_payout!.partnerName != null)
              _buildDetailRow('Nom', _payout!.partnerName!),
            if (_payout!.partnerPhone != null)
              _buildDetailRow('Téléphone', _payout!.partnerPhone!),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Informations d\'erreur',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _payout!.failureReason!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Transactions sources',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._payout!.sourceTransactions.map(
              (transactionId) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_forward, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(transactionId),
                    ),
                  ],
                ),
              ),
            ),
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

  Color _getStatusColor(PayoutStatus status) {
    switch (status) {
      case PayoutStatus.scheduled:
        return Colors.blue;
      case PayoutStatus.pending:
        return Colors.orange;
      case PayoutStatus.success:
        return Colors.green;
      case PayoutStatus.failed:
        return Colors.red;
    }
  }
}
