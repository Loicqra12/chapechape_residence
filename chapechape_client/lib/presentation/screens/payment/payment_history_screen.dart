import 'package:chapechape_client/core/blocs/payment/payment_bloc.dart';
import 'package:chapechape_client/core/blocs/payment/payment_event.dart';
import 'package:chapechape_client/core/blocs/payment/payment_state.dart';
import 'package:chapechape_client/core/models/payment_model.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

enum _PaymentFilter { all, pending, paid, failed, refunded }

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final DateFormat _df = DateFormat('dd/MM/yyyy HH:mm');
  _PaymentFilter _filter = _PaymentFilter.all;
  List<Payment> _all = const [];
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PaymentBloc>().add(const LoadPaymentHistory());
    });
  }

  Future<void> _refresh() async {
    context.read<PaymentBloc>().add(const LoadPaymentHistory());
  }

  List<Payment> get _filtered {
    switch (_filter) {
      case _PaymentFilter.all:
        return _all;
      case _PaymentFilter.pending:
        return _all
            .where((p) =>
                p.status == PaymentStatus.pending ||
                p.status == PaymentStatus.processing)
            .toList();
      case _PaymentFilter.paid:
        return _all.where((p) => p.status == PaymentStatus.succeeded).toList();
      case _PaymentFilter.failed:
        return _all
            .where((p) =>
                p.status == PaymentStatus.failed ||
                p.status == PaymentStatus.cancelled)
            .toList();
      case _PaymentFilter.refunded:
        return _all.where((p) => p.status == PaymentStatus.refunded).toList();
    }
  }

  String _money(double value) =>
      '${NumberFormat('#,##0', 'fr_FR').format(value)} FCFA';

  String _statusCheckId(Payment p) =>
      (p.transactionId != null && p.transactionId!.isNotEmpty)
          ? p.transactionId!
          : p.id;

  void _checkStatus(Payment p) {
    context
        .read<PaymentBloc>()
        .add(CheckPaymentStatus(paymentId: _statusCheckId(p)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vérification du statut...')),
    );
  }

  Future<void> _openReceipt(Payment p) async {
    final url = p.receiptUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Justificatif indisponible.')),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir le justificatif.')),
      );
    }
  }

  Future<void> _shareReceipt(Payment p) async {
    final text = StringBuffer()
      ..writeln('ChapeChape - Justificatif de paiement')
      ..writeln('Montant: ${_money(p.amount)}')
      ..writeln('Méthode: ${p.method.displayName}')
      ..writeln('Statut: ${p.status.displayName}')
      ..writeln('Transaction: ${p.transactionId ?? p.id}')
      ..writeln('Réservation: ${p.bookingId}');
    if (p.receiptUrl != null && p.receiptUrl!.isNotEmpty) {
      text.writeln('Reçu: ${p.receiptUrl}');
    }
    await Share.share(text.toString(), subject: 'Justificatif de paiement');
  }

  Widget _chip(_PaymentFilter value, String label) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppTheme.lightGold,
      side: BorderSide(
        color: selected ? AppTheme.primaryColor : AppTheme.dividerColor,
      ),
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  void _showDetails(Payment p) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Détail du paiement',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _row('Montant', _money(p.amount)),
              _row('Méthode', p.method.displayName),
              _row('Statut', p.status.displayName),
              _row('Date', _df.format(p.createdAt)),
              _row('Transaction', p.transactionId ?? p.id),
              _row('Réservation', p.bookingId),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _checkStatus(p);
                      },
                      icon: const Icon(Icons.sync_rounded),
                      label: const Text('Vérifier'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _shareReceipt(p);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.textPrimary,
                      ),
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Partager'),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openReceipt(p);
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('Télécharger / ouvrir justificatif'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
              width: 108,
              child: Text(k,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  )),
            ),
            Expanded(child: Text(v)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentHistoryLoaded) {
            setState(() {
              _loadedOnce = true;
              _all = state.payments;
            });
          } else if (state is PaymentStatusChecked) {
            setState(() {
              _all = _all.map((p) {
                final idMatch = p.id == state.payment.id;
                final txnMatch = p.transactionId != null &&
                    state.payment.transactionId != null &&
                    p.transactionId == state.payment.transactionId;
                return (idMatch || txnMatch) ? state.payment : p;
              }).toList();
            });
          } else if (state is PaymentError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final list = _filtered;
          final firstLoading = !_loadedOnce && state is PaymentLoading;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xl30,
              ),
              children: [
                Text(
                  'Mes paiements & justificatifs',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Suivez vos paiements, vérifiez le statut et partagez vos justificatifs.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.75),
                      ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(_PaymentFilter.all, 'Tous'),
                    _chip(_PaymentFilter.pending, 'En attente'),
                    _chip(_PaymentFilter.paid, 'Payé'),
                    _chip(_PaymentFilter.failed, 'Échoué'),
                    _chip(_PaymentFilter.refunded, 'Remboursé'),
                  ],
                ),
                const SizedBox(height: 14),
                if (firstLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 52),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/empty_states/empty_payementjustificatif_illustration.png',
                          height: 150,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.receipt_long_outlined,
                              size: 72,
                              color: Colors.grey.shade500,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aucun paiement pour ce filtre',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                else
                  ...list.map(
                    (p) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        onTap: () => _showDetails(p),
                        leading: CircleAvatar(
                          backgroundColor: p.status.color.withOpacity(0.12),
                          child: Icon(Icons.receipt_long_rounded,
                              color: p.status.color),
                        ),
                        title: Text(
                          _money(p.amount),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                              '${p.method.displayName} • ${_df.format(p.createdAt)}'),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              p.status.displayName,
                              style: TextStyle(
                                color: p.status.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _checkStatus(p);
                              },
                              child: Text(
                                'Vérifier',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
