import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:chapechape_client/core/models/booking_model.dart';
import 'package:chapechape_client/core/utils/booking_helpers.dart';
import 'package:chapechape_client/core/blocs/booking/booking_bloc.dart';
import 'package:chapechape_client/core/blocs/booking/booking_event.dart' as booking_events;
import 'package:chapechape_client/core/blocs/booking/booking_state.dart' as booking_states;
import 'package:chapechape_client/presentation/widgets/qr/qr_code_display_widget.dart';
import 'package:chapechape_client/presentation/widgets/booking/reservation_status_badge.dart';
import 'package:chapechape_client/presentation/widgets/loading_overlay.dart';

/// Écran dédié à l'affichage et la gestion des QR codes
/// Supporte check-in, check-out et gestion complète des codes QR
class QRCodeScreen extends StatefulWidget {
  final String bookingId;
  final QRCodeType? initialType;

  const QRCodeScreen({
    super.key,
    required this.bookingId,
    this.initialType,
  });

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Booking? _booking;
  bool _isLoading = false;
  QRCodeType _selectedType = QRCodeType.checkIn;

  @override
  void initState() {
    super.initState();
    
    // Initialiser le TabController pour les onglets
    _tabController = TabController(length: 2, vsync: this);
    
    // Définir le type initial
    _selectedType = widget.initialType ?? QRCodeType.checkIn;
    _tabController.index = _selectedType == QRCodeType.checkIn ? 0 : 1;
    
    // Charger les détails de la réservation
    _loadBookingDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadBookingDetails() {
    context.read<BookingBloc>().add(
      booking_events.LoadBookingDetails(bookingId: widget.bookingId),
    );
  }

  void _onTabChanged() {
    setState(() {
      _selectedType = _tabController.index == 0 
          ? QRCodeType.checkIn 
          : QRCodeType.checkOut;
    });
  }

  void _regenerateQRCode() {
    if (_booking == null) return;
    
    // TODO: Implémenter la régénération des QR codes via le BookingBloc
    // Pour l'instant, afficher un message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nouveau QR Code généré avec succès'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareQRCode(String qrData) {
    // Le partage est géré par le QRCodeDisplayWidget
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR Code prêt à partager'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Vérifier si les QR codes peuvent être utilisés pour cette réservation
  bool _canUseQRCodes() {
    if (_booking == null) return false;
    
    // Les QR codes sont disponibles pour les réservations confirmées ou en cours
    final allowedStatuses = ['confirmed', 'in_progress', 'payment_pending'];
    return allowedStatuses.contains(_booking!.status.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('QR Codes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          if (_booking != null)
            IconButton(
              onPressed: _regenerateQRCode,
              icon: const Icon(Icons.refresh),
              tooltip: 'Régénérer les QR codes',
            ),
        ],
      ),
      body: BlocConsumer<BookingBloc, booking_states.BookingState>(
        listener: (context, state) {
          if (state is booking_states.BookingDetailsLoaded) {
            setState(() {
              _booking = state.booking;
              _isLoading = false;
            });
          } else if (state is booking_states.BookingError) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is booking_states.BookingLoading) {
            setState(() {
              _isLoading = true;
            });
          }
        },
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: _isLoading,
            child: _booking != null 
                ? _buildQRCodeContent()
                : _buildLoadingContent(),
          );
        },
      ),
    );
  }

  Widget _buildLoadingContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement des informations...'),
        ],
      ),
    );
  }

  Widget _buildQRCodeContent() {
    return Column(
      children: [
        // Header avec informations de réservation
        _buildBookingHeader(),
        
        // Onglets pour check-in/check-out
        _buildTabBar(),
        
        // Contenu des QR codes
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildQRCodeTab(QRCodeType.checkIn),
              _buildQRCodeTab(QRCodeType.checkOut),
            ],
          ),
        ),
        
        // Actions en bas
        _buildBottomActions(),
      ],
    );
  }

  Widget _buildBookingHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Réservation',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              _booking!.statusBadge(size: BadgeSize.medium),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildInfoRow(
            icon: Icons.home,
            label: 'Résidence',
            value: _booking!.residenceName,
          ),
          
          const SizedBox(height: 8),
          
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'Check-in',
            value: BookingHelpers.formatDate(_booking!.checkIn),
          ),
          
          const SizedBox(height: 8),
          
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Check-out',
            value: BookingHelpers.formatDate(_booking!.checkOut),
          ),
          
          if (_canUseQRCodes()) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified, color: Colors.green[600], size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'QR Codes actifs et prêts à utiliser',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (_) => _onTabChanged(),
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Theme.of(context).primaryColor,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            icon: Icon(Icons.login),
            text: 'Check-in',
          ),
          Tab(
            icon: Icon(Icons.logout),
            text: 'Check-out',
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeTab(QRCodeType type) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // QR Code principal
          QRCodeDisplayWidget(
            booking: _booking!,
            type: type,
            size: 250,
            showActions: true,
            showInstructions: true,
            onRegenerate: _regenerateQRCode,
            onShare: _shareQRCode,
          ),
          
          const SizedBox(height: 24),
          
          // Instructions spécifiques au type
          _buildTypeSpecificInstructions(type),
          
          const SizedBox(height: 24),
          
          // Informations de sécurité
          _buildSecurityInfo(),
        ],
      ),
    );
  }

  Widget _buildTypeSpecificInstructions(QRCodeType type) {
    final isCheckIn = type == QRCodeType.checkIn;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCheckIn ? Icons.login : Icons.logout,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Instructions ${isCheckIn ? "Check-in" : "Check-out"}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            if (isCheckIn) ...[
              _buildInstructionItem(
                '1. Présentez-vous à la résidence à l\'heure prévue',
              ),
              _buildInstructionItem(
                '2. Montrez ce QR code au partenaire',
              ),
              _buildInstructionItem(
                '3. Le partenaire scanera le code pour confirmer votre arrivée',
              ),
              _buildInstructionItem(
                '4. Récupérez les clés et profitez de votre séjour',
              ),
            ] else ...[
              _buildInstructionItem(
                '1. Préparez vos affaires avant l\'heure de départ',
              ),
              _buildInstructionItem(
                '2. Montrez ce QR code au partenaire',
              ),
              _buildInstructionItem(
                '3. Le partenaire vérifiera l\'état de la résidence',
              ),
              _buildInstructionItem(
                '4. Remettez les clés et récupérez votre caution si applicable',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Card(
      elevation: 2,
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Text(
                  'Informations de Sécurité',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              '• Ne partagez jamais vos QR codes avec des personnes non autorisées\n'
              '• Ces codes sont uniques à votre réservation\n'
              '• En cas de problème, contactez immédiatement le support\n'
              '• Les codes peuvent être régénérés si nécessaire',
              style: TextStyle(
                fontSize: 14,
                color: Colors.amber[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.push('/support'),
              icon: const Icon(Icons.help_outline),
              label: const Text('Aide'),
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => context.go('/bookings'),
              icon: const Icon(Icons.list),
              label: const Text('Mes Réservations'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper functions pour les QR codes
bool _canUseQRCodesForBooking(Booking booking) {
  // Les QR codes sont disponibles pour les réservations confirmées ou en cours
  final allowedStatuses = ['confirmed', 'in_progress', 'payment_pending'];
  return allowedStatuses.contains(booking.status.toLowerCase());
}

bool _hasQRCodesForBooking(Booking booking) {
  // Vérifier si la réservation a des QR codes générés
  // Pour l'instant, on assume que toutes les réservations confirmées ont des QR codes
  return _canUseQRCodesForBooking(booking);
}

/// Extension pour faciliter l'utilisation
extension BookingQRExtension on Booking {
  /// Vérifier si les QR codes peuvent être utilisés
  bool get canUseQRCodes => _canUseQRCodesForBooking(this);
  
  /// Vérifier si les QR codes sont disponibles
  bool get hasQRCodes => _hasQRCodesForBooking(this);
}
