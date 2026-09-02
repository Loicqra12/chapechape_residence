import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../core/blocs/reservation/reservation_bloc.dart';
import '../../../core/models/stay_credential_preview.dart';
import '../../../core/services/api/reservation_service.dart';

/// Mode explicite — le purpose n'est jamais déduit du token.
enum QRScanType {
  checkIn,
  checkOut;

  String get purpose => this == QRScanType.checkIn ? 'checkin' : 'checkout';

  String get displayName =>
      this == QRScanType.checkIn ? 'Scanner QR d\'arrivée' : 'Scanner QR de départ';

  String get previewTitle =>
      this == QRScanType.checkIn ? 'Check-in QR' : 'Check-out QR';
}

/// Scanner Partner — raw string → resolve → preview → confirm → canonical /checkin|/checkout.
class QRScannerScreen extends StatefulWidget {
  final QRScanType scanType;

  const QRScannerScreen({
    super.key,
    required this.scanType,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _controller;
  PermissionStatus _cameraPermission = PermissionStatus.denied;
  bool _scanLocked = false;
  bool _resolveInFlight = false;
  bool _commitInFlight = false;
  bool _isCommitting = false;
  String? _errorCode;
  StayCredentialPreview? _preview;
  String? _scannedCredential;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clearCredentialMemory();
    _controller?.stop();
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller?.stop();
    } else if (state == AppLifecycleState.resumed &&
        _preview == null &&
        _errorCode == null &&
        !_scanLocked &&
        !_resolveInFlight &&
        _cameraPermission.isGranted) {
      _controller?.start();
    }
  }

  void _clearCredentialMemory() {
    _scannedCredential = null;
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    setState(() => _cameraPermission = status);

    if (status.isGranted) {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
      setState(() {});
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanLocked || _resolveInFlight || _preview != null) return;

    final raw = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;
    if (!raw.startsWith('CCSTAY1.')) return;

    _scanLocked = true;
    _controller?.stop();
    _resolveCredential(raw);
  }

  Future<void> _resolveCredential(String credential) async {
    if (_resolveInFlight) return;
    _resolveInFlight = true;

    if (mounted) {
      setState(() {
        _errorCode = null;
        _scannedCredential = credential;
      });
    }

    try {
      final service = context.read<ReservationService>();
      final preview = await service.resolveStayCredential(
        credential: credential,
        purpose: widget.scanType.purpose,
      );

      if (!mounted) return;
      setState(() {
        _preview = preview;
      });
    } on StayCredentialApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorCode = e.code;
        _clearCredentialMemory();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorCode = 'NETWORK_ERROR';
        _clearCredentialMemory();
      });
    } finally {
      _resolveInFlight = false;
    }
  }

  Future<void> _confirmCommit() async {
    if (_preview == null ||
        _scannedCredential == null ||
        _commitInFlight ||
        _isCommitting) {
      return;
    }

    _commitInFlight = true;
    if (mounted) {
      setState(() => _isCommitting = true);
    }

    final reservationId = _preview!.reservationId;
    final credential = _scannedCredential!;

    try {
      final service = context.read<ReservationService>();

      if (widget.scanType == QRScanType.checkIn) {
        await service.performCheckin(reservationId, credential: credential);
      } else {
        await service.performCheckout(reservationId, credential: credential);
      }

      if (!mounted) return;
      await _controller?.stop();
      _clearCredentialMemory();
      setState(() {
        _preview = null;
      });
      context.read<ReservationBloc>().add(LoadReservationDetails(reservationId));
      Navigator.of(context).pop(true);
    } on StayCredentialApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isCommitting = false;
        _errorCode = e.code;
        _preview = null;
        _clearCredentialMemory();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCommitting = false;
        _errorCode = 'NETWORK_ERROR';
        _preview = null;
        _clearCredentialMemory();
      });
    } finally {
      _commitInFlight = false;
    }
  }

  void _resumeScan() {
    _clearCredentialMemory();
    setState(() {
      _scanLocked = false;
      _preview = null;
      _errorCode = null;
      _isCommitting = false;
    });
    _resolveInFlight = false;
    _commitInFlight = false;
    _controller?.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scanType.displayName),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_cameraPermission.isPermanentlyDenied) {
      return _permissionFallback(
        'Permission caméra refusée définitivement.',
        showSettings: true,
      );
    }

    if (!_cameraPermission.isGranted) {
      return _permissionFallback(
        'Autorisez l\'accès à la caméra pour scanner le QR client.',
      );
    }

    if (_preview != null) {
      return _buildPreview();
    }

    if (_errorCode != null) {
      return _buildError();
    }

    return Stack(
      children: [
        if (_controller != null)
          MobileScanner(
            controller: _controller!,
            onDetect: _onDetect,
          ),
        if (_resolveInFlight)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator()),
          ),
        _buildScanOverlay(),
      ],
    );
  }

  Widget _buildScanOverlay() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        color: Colors.black54,
        child: Text(
          'Placez le QR ${widget.scanType == QRScanType.checkIn ? 'd\'arrivée' : 'de départ'} dans le cadre',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final preview = _preview!;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.scanType.previewTitle,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (preview.residenceTitle != null)
                    Text(
                      preview.residenceTitle!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  if (preview.residenceCity != null)
                    Text(preview.residenceCity!),
                  const Divider(),
                  Text('Réf. ${preview.reservationId.substring(0, 8)}'),
                  if (preview.clientDisplayName != null)
                    Text('Client : ${preview.clientDisplayName}'),
                  if (preview.checkIn != null)
                    Text('Arrivée : ${dateFormat.format(preview.checkIn!)}'),
                  if (preview.checkOut != null)
                    Text('Départ : ${dateFormat.format(preview.checkOut!)}'),
                  Text('Statut : ${preview.status}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: (_isCommitting || _commitInFlight) ? null : _confirmCommit,
            child: _isCommitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(preview.actionLabel),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: (_isCommitting || _commitInFlight) ? null : _resumeScan,
            child: const Text('Scanner à nouveau'),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            stayCredentialErrorMessage(_errorCode!),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _resumeScan,
            child: const Text('Reprendre le scan'),
          ),
        ],
      ),
    );
  }

  Widget _permissionFallback(String message, {bool showSettings = false}) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt_outlined, size: 64),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          if (showSettings)
            FilledButton(
              onPressed: openAppSettings,
              child: const Text('Ouvrir les paramètres'),
            )
          else
            FilledButton(
              onPressed: _initCamera,
              child: const Text('Autoriser la caméra'),
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Retour (check-in/out manuel)'),
          ),
        ],
      ),
    );
  }
}
