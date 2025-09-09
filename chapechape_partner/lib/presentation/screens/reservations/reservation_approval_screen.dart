import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/blocs/reservation/reservation_bloc.dart';
import '../../../core/models/reservation/reservation.dart';
import '../../widgets/reservation/reservation_timer_widget.dart';

/// Écran dédié à la gestion des demandes d'approbation de réservation
/// Permet aux partenaires d'approuver ou rejeter les réservations en attente
class ReservationApprovalScreen extends StatefulWidget {
  const ReservationApprovalScreen({super.key});

  @override
  State<ReservationApprovalScreen> createState() => _ReservationApprovalScreenState();
}

class _ReservationApprovalScreenState extends State<ReservationApprovalScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Reservation> _pendingReservations = [];
  List<Reservation> _processedReservations = [];
  bool _isLoading = false;
  String _filterStatus = 'all'; // ✅ RESTAURÉ : utilisé dans le menu de filtrage ligne 231

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReservations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadReservations() {
    setState(() {
      _isLoading = true;
    });
    
    context.read<ReservationBloc>().add(LoadMyReservations());
  }

  void _filterReservations(List<Reservation> allReservations) {
    // Appliquer le filtre sélectionné
    List<Reservation> filteredReservations = allReservations;
    
    if (_filterStatus == 'urgent') {
      // Filtrer les réservations urgentes (moins de 6h pour répondre)
      filteredReservations = allReservations.where((r) {
        if (r.status == ReservationStatus.awaitingApproval) {
          final deadline = r.createdAt.add(const Duration(hours: 24));
          final remainingTime = deadline.difference(DateTime.now());
          return remainingTime.inHours <= 6;
        }
        return false;
      }).toList();
    } else if (_filterStatus == 'today') {
      // Filtrer les réservations d'aujourd'hui
      final today = DateTime.now();
      filteredReservations = allReservations.where((r) {
        return r.createdAt.day == today.day &&
               r.createdAt.month == today.month &&
               r.createdAt.year == today.year;
      }).toList();
    }
    
    _pendingReservations = filteredReservations
        .where((r) => r.status == ReservationStatus.awaitingApproval)
        .toList();
    
    _processedReservations = filteredReservations
        .where((r) => r.status == ReservationStatus.rejected || 
                      r.status == ReservationStatus.confirmed)
        .toList();
  }

  void _approveReservation(Reservation reservation) {
    _showApprovalDialog(reservation, true);
  }

  void _rejectReservation(Reservation reservation) {
    _showApprovalDialog(reservation, false);
  }

  void _showApprovalDialog(Reservation reservation, bool isApproval) {
    final action = isApproval ? 'approuver' : 'rejeter';
    // final actionPast = isApproval ? 'approuvée' : 'rejetée'; // Unused for now
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isApproval ? 'Approuver' : 'Rejeter'} la réservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Êtes-vous sûr de vouloir $action cette réservation ?'),
            const SizedBox(height: 16),
            _buildReservationSummary(reservation),
            if (!isApproval) ...[
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Motif du rejet (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) {
                  // TODO: Stocker le motif du rejet
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processReservationApproval(reservation, isApproval);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproval ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isApproval ? 'Approuver' : 'Rejeter'),
          ),
        ],
      ),
    );
  }

  void _processReservationApproval(Reservation reservation, bool isApproval) async {
    // ✅ IMPLÉMENTATION RÉELLE - INTEGRATION RESERVATIONMODE
    try {
      // Afficher le loading
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Text(isApproval ? 'Approbation en cours...' : 'Rejet en cours...'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 30), // Long timeout pour l'API call
        ),
      );

      // Appel API réel
      final reservationService = context.read<ReservationBloc>().reservationService;
      Reservation? updatedReservation;

      if (isApproval) {
        updatedReservation = await reservationService.approveReservation(reservation.id);
      } else {
        // TODO: Récupérer le motif du rejet depuis le TextField si disponible
        updatedReservation = await reservationService.rejectReservation(reservation.id);
      }

      // Masquer le loading
      messenger.clearSnackBars();

      if (updatedReservation != null) {
        // Succès - Afficher la confirmation
        final action = isApproval ? 'approuvée' : 'rejetée';
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isApproval ? Icons.check_circle : Icons.cancel,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text('Réservation $action avec succès')),
              ],
            ),
            backgroundColor: isApproval ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );

        // Recharger les données pour refléter les changements
        _loadReservations();
      } else {
        // Erreur - Afficher le message d'erreur
        messenger.showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Erreur lors de l\'opération. Veuillez réessayer.')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      // Gestion d'erreur robuste
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Erreur: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 7),
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: Colors.white,
            onPressed: () => _processReservationApproval(reservation, isApproval),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Approbations'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadReservations,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('Toutes'),
              ),
              const PopupMenuItem(
                value: 'urgent',
                child: Text('Urgentes'),
              ),
              const PopupMenuItem(
                value: 'today',
                child: Text('Aujourd\'hui'),
              ),
            ],
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrer',
          ),
        ],
      ),
      body: BlocConsumer<ReservationBloc, ReservationState>(
        listener: (context, state) {
          if (state is ReservationLoaded) {
            setState(() {
              _isLoading = false;
            });
            _filterReservations(state.reservations);
          } else if (state is ReservationError) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is ReservationLoading) {
            setState(() {
              _isLoading = true;
            });
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Header avec statistiques
              _buildStatsHeader(),
              
              // Onglets
              _buildTabBar(),
              
              // Contenu des onglets
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPendingReservations(),
                          _buildProcessedReservations(),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'En attente',
              _pendingReservations.length.toString(),
              Icons.pending_actions,
              Colors.white,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: _buildStatItem(
              'Traitées',
              _processedReservations.length.toString(),
              Icons.check_circle,
              Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Theme.of(context).primaryColor,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            icon: Badge(
              label: Text(_pendingReservations.length.toString()),
              child: const Icon(Icons.pending_actions),
            ),
            text: 'En attente',
          ),
          Tab(
            icon: Badge(
              label: Text(_processedReservations.length.toString()),
              child: const Icon(Icons.history),
            ),
            text: 'Traitées',
          ),
        ],
      ),
    );
  }

  Widget _buildPendingReservations() {
    if (_pendingReservations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        title: 'Aucune demande en attente',
        message: 'Toutes les réservations ont été traitées !',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadReservations(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingReservations.length,
        itemBuilder: (context, index) {
          return _buildReservationCard(
            _pendingReservations[index],
            showActions: true,
          );
        },
      ),
    );
  }

  Widget _buildProcessedReservations() {
    if (_processedReservations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'Aucune réservation traitée',
        message: 'L\'historique de vos décisions apparaîtra ici.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadReservations(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _processedReservations.length,
        itemBuilder: (context, index) {
          return _buildReservationCard(
            _processedReservations[index],
            showActions: false,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(Reservation reservation, {required bool showActions}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    reservation.residenceName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(reservation.status),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Informations principales
            _buildReservationInfo(reservation),
            
            const SizedBox(height: 16),
            
            // Timer SLA d'approbation hôte
            if (reservation.status == ReservationStatus.awaitingApproval)
              ReservationTimerWidget(
                reservation: reservation,
                displayMode: ReservationTimerDisplayMode.banner,
                onApprove: () => _approveReservation(reservation),
                onReject: () => _rejectReservation(reservation),
                onExpired: () {
                  // Auto-transition vers rejeté après expiration
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Délai d\'approbation expiré - Réservation automatiquement rejetée'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  _loadReservations(); // Recharger la liste
                },
              ),
            
            // Urgence si applicable (garde l'existant)
            if (_isUrgent(reservation) && reservation.status != ReservationStatus.awaitingApproval)
              _buildUrgencyBanner(),
            
            if (showActions) ...[
              const Divider(),
              _buildActionButtons(reservation),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ReservationStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(int.parse('0xFF${status.color.substring(1)}')),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildReservationInfo(Reservation reservation) {
    return Column(
      children: [
        _buildInfoRow(
          Icons.calendar_today,
          'Check-in',
          DateFormat('dd/MM/yyyy à HH:mm').format(reservation.checkIn),
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          Icons.calendar_today_outlined,
          'Check-out',
          DateFormat('dd/MM/yyyy à HH:mm').format(reservation.checkOut),
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          Icons.people,
          'Invités',
          '${reservation.guestsCount} personne${reservation.guestsCount > 1 ? 's' : ''}',
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          Icons.payments,
          'Montant total',
          reservation.formattedTotalAmount,
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReservationSummary(Reservation reservation) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reservation.residenceName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('${DateFormat('dd/MM/yyyy').format(reservation.checkIn)} - ${DateFormat('dd/MM/yyyy').format(reservation.checkOut)}'),
          Text('${reservation.guestsCount} invité${reservation.guestsCount > 1 ? 's' : ''}'),
          Text(reservation.formattedTotalAmount),
        ],
      ),
    );
  }

  bool _isUrgent(Reservation reservation) {
    final now = DateTime.now();
    final checkIn = reservation.checkIn;
    final hoursUntilCheckIn = checkIn.difference(now).inHours;
    
    // Urgent si check-in dans moins de 24h
    return hoursUntilCheckIn < 24 && hoursUntilCheckIn > 0;
  }

  Widget _buildUrgencyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange[700], size: 16),
          const SizedBox(width: 6),
          Text(
            'URGENT: Check-in dans moins de 24h',
            style: TextStyle(
              color: Colors.orange[700],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Reservation reservation) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _rejectReservation(reservation),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Rejeter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _approveReservation(reservation),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Approuver'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
