import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/adapters/booking_adapter.dart';
import '../../../core/blocs/reservation/reservation_bloc.dart';
import '../../../core/models/reservation/reservation.dart';
import '../../../core/services/api/reservation_service.dart';
import '../../widgets/booking/booking_sms_widget.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/reservation/reservation_timer_widget.dart';

class ReservationDetailsScreen extends StatefulWidget {
  final String reservationId;

  const ReservationDetailsScreen({
    Key? key,
    required this.reservationId,
  }) : super(key: key);

  @override
  State<ReservationDetailsScreen> createState() => _ReservationDetailsScreenState();
}

class _ReservationDetailsScreenState extends State<ReservationDetailsScreen> {
  final _noteController = TextEditingController();
  late ReservationBloc _reservationBloc;

  @override
  void initState() {
    super.initState();
    _reservationBloc = context.read<ReservationBloc>();
    _loadReservationDetails();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _loadReservationDetails() {
    print("Chargement des détails de la réservation avec ID: ${widget.reservationId}");
    _reservationBloc.add(LoadReservationDetails(widget.reservationId));
  }

  void _updateReservationStatus(ReservationStatus newStatus) {
    print("Mise à jour du statut de la réservation avec ID: ${widget.reservationId}");
    _reservationBloc.add(UpdateReservationStatus(widget.reservationId, newStatus));
    
    // Afficher un message de succès
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Statut mis à jour: ${newStatus.displayName}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _cancelReservation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la réservation'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler cette réservation? Cette action est irréversible.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NON'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _reservationBloc.add(CancelReservation(widget.reservationId));
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Réservation annulée'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('OUI, ANNULER'),
          ),
        ],
      ),
    );
  }

  void _addNote() {
    final note = _noteController.text.trim();
    if (note.isEmpty) return;

    _reservationBloc.add(AddReservationNote(widget.reservationId, note));
    _noteController.clear();
    
    // Fermer le clavier
    FocusScope.of(context).unfocus();
    
    // Afficher un message de succès
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note ajoutée'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la réservation'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReservationDetails,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: BlocBuilder<ReservationBloc, ReservationState>(
        builder: (context, state) {
          if (state is ReservationLoading) {
            return ShimmerLoading(
              child: _buildLoadingPlaceholder(context),
            );
          }
          
          if (state is ReservationError) {
            return EmptyState(
              icon: Icons.error_outline,
              message: 'Erreur',
              subtitle: state.message,
              onAction: _loadReservationDetails,
              actionLabel: 'Réessayer',
            );
          }
          
          if (state is ReservationDetailsLoaded) {
            final reservation = state.reservation;
            return _buildReservationDetails(context, reservation);
          }
          
          return EmptyState(
            icon: Icons.search,
            message: 'Réservation non trouvée',
            subtitle: 'Impossible de trouver les détails de cette réservation.',
            onAction: () => Navigator.pop(context),
            actionLabel: 'Retour',
          );
        },
      ),
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Title placeholder
          Container(
            height: 24,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Details placeholders
          for (int i = 0; i < 4; i++) ...[
            Row(
              children: [
                Container(
                  height: 20,
                  width: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildReservationDetails(BuildContext context, Reservation reservation) {
    final theme = Theme.of(context);
    final statusColor = Color(int.parse(reservation.status.color.replaceAll('#', '0xFF')));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec image et statut
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image de la résidence
                Stack(
                  children: [
                    Image.network(
                      reservation.residenceImage,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          reservation.status.displayName,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Nom de la résidence
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.residenceName,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Réservation #${reservation.id.substring(0, 8).toUpperCase()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Timer SLA d'approbation hôte
          if (reservation.status == ReservationStatus.awaitingApproval) ...[
            const SizedBox(height: 16),
            ReservationTimerWidget(
              reservation: reservation,
              displayMode: ReservationTimerDisplayMode.full,
              onApprove: () {
                _updateReservationStatus(ReservationStatus.confirmed);
              },
              onReject: () {
                _updateReservationStatus(ReservationStatus.rejected);
              },
              onExpired: () {
                // Auto-transition vers rejeté après expiration
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Délai d\'approbation expiré - Réservation automatiquement rejetée'),
                    backgroundColor: Colors.red,
                  ),
                );
                _loadReservationDetails(); // Recharger les détails
              },
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Informations client
          _buildSectionTitle(context, 'Informations client'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        reservation.clientName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      reservation.clientName,
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: Text(reservation.clientPhone),
                    trailing: IconButton(
                      icon: const Icon(Icons.phone),
                      onPressed: () {
                        // Action d'appel téléphonique
                      },
                      tooltip: 'Appeler le client',
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Détails de la réservation
          _buildSectionTitle(context, 'Détails de la réservation'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    'Dates',
                    reservation.formattedDates,
                    Icons.calendar_month,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    context,
                    'Durée',
                    '${reservation.durationInDays} jour${reservation.durationInDays > 1 ? 's' : ''}',
                    Icons.timer,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    context,
                    'Voyageurs',
                    '${reservation.guestsCount} personne${reservation.guestsCount > 1 ? 's' : ''}',
                    Icons.people,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    context,
                    'Montant total',
                    reservation.formattedTotalAmount,
                    Icons.attach_money,
                    valueColor: theme.colorScheme.primary,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    context,
                    'Créée le',
                    reservation.formattedCreatedAt,
                    Icons.access_time,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Communication SMS
          _buildSectionTitle(context, 'Communication SMS'),
          BookingSmsWidget(booking: BookingAdapter.fromReservation(reservation)),
          
          const SizedBox(height: 24),
          
          // Notes
          _buildSectionTitle(context, 'Notes'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Zone de saisie de note
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: 'Ajouter une note',
                      hintText: 'Informations supplémentaires, instructions...',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _addNote,
                      ),
                    ),
                    maxLines: 3,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Notes existantes
                  if (reservation.notes != null && reservation.notes!.isNotEmpty) ...[
                    const Text(
                      'Notes existantes:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.note,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              reservation.notes!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    const Text(
                      'Aucune note pour le moment.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Actions
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: reservation.status == ReservationStatus.pending
                      ? () => _updateReservationStatus(ReservationStatus.confirmed)
                      : null,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('CONFIRMER'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: reservation.status != ReservationStatus.cancelled
                      ? _cancelReservation
                      : null,
                  icon: const Icon(Icons.cancel),
                  label: const Text('ANNULER'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Bouton pour changer le statut
          if (reservation.status != ReservationStatus.cancelled)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Changer le statut'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: ReservationStatus.values
                            .where((s) => s != reservation.status)
                            .map((status) {
                          return ListTile(
                            title: Text(status.displayName),
                            leading: Icon(
                              Icons.circle,
                              color: Color(
                                int.parse(
                                  status.color.replaceAll('#', '0xFF'),
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _updateReservationStatus(status);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('MODIFIER LE STATUT'),
              ),
            ),
            
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
} 