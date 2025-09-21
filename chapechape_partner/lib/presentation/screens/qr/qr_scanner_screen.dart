import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import '../../../core/blocs/reservation/reservation_bloc.dart';
import '../../../core/models/reservation/reservation.dart';
import '../../../core/services/api/reservation_service.dart';

/// Écran de scan QR codes pour check-in/check-out
/// Permet aux partenaires de scanner les QR codes des clients
class QRScannerScreen extends StatefulWidget {
  final String? initialBookingId;
  final QRScanType scanType;

  const QRScannerScreen({
    super.key,
    this.initialBookingId,
    this.scanType = QRScanType.checkIn,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

enum QRScanType {
  checkIn,
  checkOut,
  general;

  String get displayName {
    switch (this) {
      case QRScanType.checkIn:
        return 'Check-in';
      case QRScanType.checkOut:
        return 'Check-out';
      case QRScanType.general:
        return 'Scan QR';
    }
  }

  IconData get icon {
    switch (this) {
      case QRScanType.checkIn:
        return Icons.login;
      case QRScanType.checkOut:
        return Icons.logout;
      case QRScanType.general:
        return Icons.qr_code_scanner;
    }
  }
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  bool _isScanning = false;
  bool _isCameraInitialized = false;
  String? _scannedData;
  Reservation? _scannedReservation;
  bool _isLoading = false;
  String? _errorMessage;
  CameraController? _cameraController;
  final ReservationService _reservationService = ReservationService.withDefaultDio();

  @override
  void initState() {
    super.initState();
    
    // Animation pour l'effet de scan
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _initializeCamera();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeCamera() async {
    try {
      // Vérifier les permissions de caméra
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        setState(() {
          _errorMessage = 'Permission caméra refusée';
        });
        return;
      }

      // Initialiser le contrôleur de caméra
      _cameraController = CameraController(
        CameraDescription(
          name: 'back',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        ),
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        _startScanning();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur d\'initialisation de la caméra: $e';
      });
    }
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });
    _animationController.repeat();
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
    });
    _animationController.stop();
  }

  void _onQRCodeScanned(String data) {
    if (!_isScanning) return;
    
    _stopScanning();
    setState(() {
      _scannedData = data;
      _isLoading = true;
    });
    
    // Traiter le QR code scanné
    _processScannedQR(data);
  }

  void _processScannedQR(String qrData) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Extraire l'ID de réservation du QR code
      final bookingId = _extractBookingIdFromQR(qrData);
      
      if (bookingId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'QR Code invalide ou non reconnu';
        });
        _showErrorDialog('QR Code invalide', 'Ce QR Code ne correspond à aucune réservation.');
        return;
      }

      // Charger les détails de la réservation
      context.read<ReservationBloc>().add(LoadReservationDetails(bookingId));
      
      // Attendre que les détails soient chargés
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors du traitement: $e';
      });
      _showErrorDialog('Erreur', 'Impossible de traiter ce QR Code.');
    }
  }

  String? _extractBookingIdFromQR(String qrData) {
    try {
      // Vérifier si c'est un URI ChapeChape
      if (qrData.startsWith('chapechape://')) {
        final uri = Uri.parse(qrData);
        
        // Vérifier le schéma et le host
        if (uri.scheme == 'chapechape' && uri.host == 'booking') {
          final pathSegments = uri.pathSegments;
          if (pathSegments.isNotEmpty) {
            return pathSegments[0]; // Premier segment = ID de réservation
          }
        }
      }
      
      // Vérifier si c'est un UUID direct
      if (RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(qrData)) {
        return qrData;
      }
      
      // Vérifier si c'est un ID numérique
      if (RegExp(r'^\d+$').hasMatch(qrData)) {
        return qrData;
      }
      
      // Essayer d'extraire un ID depuis une URL
      final urlMatch = RegExp(r'/(?:booking|reservation)/([a-zA-Z0-9-]+)').firstMatch(qrData);
      if (urlMatch != null) {
        return urlMatch.group(1);
      }
      
      return null;
    } catch (e) {
      debugPrint('Erreur lors de l\'extraction de l\'ID: $e');
      return null;
    }
  }

  void _performCheckInOut() async {
    if (_scannedReservation == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final action = widget.scanType == QRScanType.checkIn ? 'Check-in' : 'Check-out';
      final reservationId = _scannedReservation!.id;
      
      // Appel API pour check-in/check-out
      final response = await _reservationService.performCheckInOut(
        reservationId: reservationId,
        action: widget.scanType == QRScanType.checkIn ? 'checkin' : 'checkout',
        timestamp: DateTime.now(),
        location: 'QR Scanner', // Optionnel: géolocalisation
      );
      
      if (response['success'] == true) {
        setState(() {
          _isLoading = false;
        });
        
        _showSuccessDialog(
          '$action réussi !',
          '$action effectué avec succès pour ${_scannedReservation!.clientName}',
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Erreur', response['message'] ?? 'Échec de l\'opération');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      final actionName = widget.scanType == QRScanType.checkIn ? 'check-in' : 'check-out';
      _showErrorDialog('Erreur', 'Impossible d\'effectuer le $actionName: $e');
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 48,
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScanner();
            },
            child: const Text('Scanner un nouveau QR'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Retour à l'écran précédent
            },
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.error,
          color: Colors.red,
          size: 48,
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScanner();
            },
            child: const Text('Réessayer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Retour à l'écran précédent
            },
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _resetScanner() {
    setState(() {
      _scannedData = null;
      _scannedReservation = null;
      _isLoading = false;
      _errorMessage = null;
    });
    _startScanning();
  }

  void _toggleFlash() {
    // TODO: Implémenter le toggle de la lampe torche
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lampe torche basculée'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.scanType.displayName),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _toggleFlash,
            icon: const Icon(Icons.flash_on),
            tooltip: 'Lampe torche',
          ),
          IconButton(
            onPressed: _resetScanner,
            icon: const Icon(Icons.refresh),
            tooltip: 'Réinitialiser',
          ),
        ],
      ),
      body: BlocConsumer<ReservationBloc, ReservationState>(
        listener: (context, state) {
          if (state is ReservationDetailsLoaded) {
            setState(() {
              _scannedReservation = state.reservation;
              _isLoading = false;
            });
          } else if (state is ReservationError) {
            setState(() {
              _isLoading = false;
              _errorMessage = state.message;
            });
            _showErrorDialog('Erreur', state.message);
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Zone de scan de la caméra
              _buildCameraView(),
              
              // Overlay avec instructions et contrôles
              _buildScanOverlay(),
              
              // Zone d'informations en bas
              if (_scannedReservation != null)
                _buildReservationInfo(),
              
              // Loading overlay
              if (_isLoading)
                _buildLoadingOverlay(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCameraView() {
    if (!_isCameraInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Initialisation de la caméra...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    // TODO: Remplacer par une vraie vue caméra avec un package comme qr_code_scanner
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.black54, Colors.black87],
        ),
      ),
      child: const Center(
        child: Text(
          '📷\nVue Caméra\n(Simulation)',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Positioned.fill(
      child: Column(
        children: [
          // Espace du haut
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Pointez la caméra vers le QR Code\npour ${widget.scanType.displayName.toLowerCase()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Zone de scan centrale
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // Côté gauche
                Expanded(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
                
                // Zone de scan carrée
                Container(
                  width: 250,
                  height: 250,
                  child: _buildScanFrame(),
                ),
                
                // Côté droit
                Expanded(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          
          // Espace du bas
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: _buildBottomControls(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanFrame() {
    return Stack(
      children: [
        // Cadre de scan
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _isScanning ? Colors.green : Colors.white,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        
        // Coins du cadre
        _buildCornerBrackets(),
        
        // Ligne de scan animée
        if (_isScanning)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                top: _animation.value * 230,
                left: 10,
                right: 10,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.green,
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              );
            },
          ),
        
        // Icône au centre
        Center(
          child: Icon(
            widget.scanType.icon,
            color: Colors.white.withOpacity(0.7),
            size: 48,
          ),
        ),
      ],
    );
  }

  Widget _buildCornerBrackets() {
    const cornerSize = 20.0;
    const cornerThickness = 3.0;
    
    return Stack(
      children: [
        // Coin supérieur gauche
        Positioned(
          top: -1,
          left: -1,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.green, width: cornerThickness),
                left: BorderSide(color: Colors.green, width: cornerThickness),
              ),
            ),
          ),
        ),
        // Coin supérieur droit
        Positioned(
          top: -1,
          right: -1,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.green, width: cornerThickness),
                right: BorderSide(color: Colors.green, width: cornerThickness),
              ),
            ),
          ),
        ),
        // Coin inférieur gauche
        Positioned(
          bottom: -1,
          left: -1,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.green, width: cornerThickness),
                left: BorderSide(color: Colors.green, width: cornerThickness),
              ),
            ),
          ),
        ),
        // Coin inférieur droit
        Positioned(
          bottom: -1,
          right: -1,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.green, width: cornerThickness),
                right: BorderSide(color: Colors.green, width: cornerThickness),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          
          // Bouton de scan manuel (simulation)
          ElevatedButton.icon(
            onPressed: _isScanning ? () => _onQRCodeScanned('chapechape://booking/test123/checkin/1642511234') : null,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Simuler scan QR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize: const Size(200, 45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationInfo() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Réservation trouvée',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                _buildStatusBadge(_scannedReservation!.status),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Informations de la réservation
            _buildInfoItem(
              Icons.home,
              'Résidence',
              _scannedReservation!.residenceName,
            ),
            _buildInfoItem(
              Icons.person,
              'Client',
              _scannedReservation!.clientName,
            ),
            _buildInfoItem(
              Icons.calendar_today,
              'Check-in',
              DateFormat('dd/MM/yyyy à HH:mm').format(_scannedReservation!.checkIn),
            ),
            _buildInfoItem(
              Icons.calendar_today_outlined,
              'Check-out',
              DateFormat('dd/MM/yyyy à HH:mm').format(_scannedReservation!.checkOut),
            ),
            
            const SizedBox(height: 20),
            
            // Bouton d'action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _performCheckInOut,
                icon: Icon(widget.scanType.icon),
                label: Text('Effectuer le ${widget.scanType.displayName}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
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

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
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
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Traitement en cours...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


