import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chapechape_client/core/models/booking_model.dart';
import 'package:chapechape_client/core/utils/booking_helpers.dart';

/// Widget pour afficher et gérer les QR codes de check-in/check-out
/// Supporte la génération, l'affichage, le partage et la régénération
class QRCodeDisplayWidget extends StatefulWidget {
  final Booking booking;
  final QRCodeType type;
  final double size;
  final bool showActions;
  final bool showInstructions;
  final VoidCallback? onRegenerate;
  final Function(String)? onShare;

  const QRCodeDisplayWidget({
    super.key,
    required this.booking,
    required this.type,
    this.size = 200.0,
    this.showActions = true,
    this.showInstructions = true,
    this.onRegenerate,
    this.onShare,
  });

  @override
  State<QRCodeDisplayWidget> createState() => _QRCodeDisplayWidgetState();
}

class _QRCodeDisplayWidgetState extends State<QRCodeDisplayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String? get _qrData {
    if (!BookingHelpers.hasCheckInQR(widget.booking)) return null;
    
    final qrCodes = widget.booking.qrCode;
    if (qrCodes == null || qrCodes.isEmpty) return null;

    switch (widget.type) {
      case QRCodeType.checkIn:
        return qrCodes['checkIn']?.toString();
      case QRCodeType.checkOut:
        return qrCodes['checkOut']?.toString();
      case QRCodeType.both:
        // Pour le type "both", privilégier check-in si disponible
        return qrCodes['checkIn']?.toString() ?? qrCodes['checkOut']?.toString();
    }
  }

  String get _title {
    switch (widget.type) {
      case QRCodeType.checkIn:
        return 'QR Code Check-in';
      case QRCodeType.checkOut:
        return 'QR Code Check-out';
      case QRCodeType.both:
        return 'QR Codes Réservation';
    }
  }

  String get _instructions {
    switch (widget.type) {
      case QRCodeType.checkIn:
        return 'Présentez ce QR code au partenaire lors de votre arrivée pour confirmer votre check-in.';
      case QRCodeType.checkOut:
        return 'Présentez ce QR code au partenaire lors de votre départ pour confirmer votre check-out.';
      case QRCodeType.both:
        return 'Utilisez ces QR codes pour vos check-in et check-out avec le partenaire.';
    }
  }

  Color get _primaryColor {
    if (!BookingHelpers.hasCheckInQR(widget.booking)) {
      return Colors.grey;
    }
    return Theme.of(context).primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Titre
              Text(
                _title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // QR Code principal
              _buildQRCode(),
              
              const SizedBox(height: 16),
              
              // Instructions
              if (widget.showInstructions)
                _buildInstructions(),
              
              // Actions
              if (widget.showActions)
                const SizedBox(height: 16),
              
              if (widget.showActions)
                _buildActions(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQRCode() {
    if (_qrData == null || _qrData!.isEmpty) {
      return _buildEmptyQRCode();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // QR Code Placeholder (À remplacer par vrai QR Code plus tard)
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Stack(
              children: [
                // Pattern QR simulé
                Positioned.fill(
                  child: CustomPaint(
                    painter: _QRPatternPainter(_qrData!),
                  ),
                ),
                // Texte informatif
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    color: Colors.white,
                    child: Text(
                      'QR CODE\n(Placeholder)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: widget.size * 0.08,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Code lisible
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _qrData!.length > 20 
                  ? '${_qrData!.substring(0, 20)}...'
                  : _qrData!,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyQRCode() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_2,
            size: widget.size * 0.3,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'QR Code non disponible',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Sera généré après confirmation',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: _primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _instructions,
              style: TextStyle(
                color: _primaryColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    if (_qrData == null || _qrData!.isEmpty) {
      return _buildRegenerateButton();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        // Copier
        _buildActionButton(
          icon: Icons.copy,
          label: 'Copier',
          onPressed: _copyQRData,
        ),
        
        // Partager
        _buildActionButton(
          icon: Icons.share,
          label: 'Partager',
          onPressed: _shareQRCode,
        ),
        
        // Régénérer
        if (widget.onRegenerate != null)
          _buildActionButton(
            icon: Icons.refresh,
            label: 'Régénérer',
            onPressed: _regenerateQRCode,
            isLoading: _isLoading,
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading 
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(_primaryColor),
              ),
            )
          : Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryColor,
        side: BorderSide(color: _primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildRegenerateButton() {
    return ElevatedButton.icon(
      onPressed: widget.onRegenerate != null ? _regenerateQRCode : null,
      icon: _isLoading 
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : const Icon(Icons.qr_code_2),
      label: Text(_isLoading ? 'Génération...' : 'Générer QR Code'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _copyQRData() {
    if (_qrData != null) {
      Clipboard.setData(ClipboardData(text: _qrData!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR Code copié dans le presse-papiers'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareQRCode() {
    if (_qrData != null) {
      final message = 'QR Code pour votre réservation ChapeChape:\n\n$_qrData\n\n'
                     'Utilisez ce code pour votre ${widget.type.name} avec le partenaire.';
      
      // Copier dans le presse-papier en attendant l'intégration share_plus
      Clipboard.setData(ClipboardData(text: message));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR Code copié pour partage'),
          duration: Duration(seconds: 2),
        ),
      );
      
      widget.onShare?.call(_qrData!);
    }
  }

  void _regenerateQRCode() async {
    if (widget.onRegenerate == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Animation de régénération
      await _animationController.reverse();
      
      widget.onRegenerate!();
      
      // Attendre un peu pour l'effet visuel
      await Future.delayed(const Duration(milliseconds: 500));
      
      await _animationController.forward();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

/// Types de QR Code
enum QRCodeType {
  checkIn,
  checkOut,
  both,
}

/// Extension pour faciliter l'utilisation
extension QRCodeTypeExtension on QRCodeType {
  String get name {
    switch (this) {
      case QRCodeType.checkIn:
        return 'check-in';
      case QRCodeType.checkOut:
        return 'check-out';
      case QRCodeType.both:
        return 'réservation';
    }
  }
}

/// Widget compact pour les listes
class CompactQRCodeWidget extends StatelessWidget {
  final Booking booking;
  final QRCodeType type;
  final VoidCallback? onTap;

  const CompactQRCodeWidget({
    super.key,
    required this.booking,
    required this.type,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasQR = BookingHelpers.hasCheckInQR(booking);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: hasQR 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasQR 
                ? Theme.of(context).primaryColor.withOpacity(0.3)
                : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasQR ? Icons.qr_code_2 : Icons.qr_code_2_outlined,
              color: hasQR 
                  ? Theme.of(context).primaryColor
                  : Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              'QR ${type.name}',
              style: TextStyle(
                color: hasQR 
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter pour simuler un pattern QR
class _QRPatternPainter extends CustomPainter {
  final String data;

  _QRPatternPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Créer un pattern simple basé sur les données
    final blockSize = size.width / 20; // 20x20 grid
    
    for (int i = 0; i < 20; i++) {
      for (int j = 0; j < 20; j++) {
        // Utiliser un hash simple des données pour déterminer les blocs
        final index = (i * 20 + j) % data.length;
        final charCode = data.codeUnitAt(index);
        
        // Dessiner un bloc si le code de caractère est pair
        if (charCode % 2 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(
              i * blockSize,
              j * blockSize,
              blockSize * 0.9, // Petit espace entre les blocs
              blockSize * 0.9,
            ),
            paint,
          );
        }
      }
    }
    
    // Ajouter les coins de référence typiques d'un QR Code
    _drawCornerMarker(canvas, paint, 0, 0, blockSize);
    _drawCornerMarker(canvas, paint, 17 * blockSize, 0, blockSize);
    _drawCornerMarker(canvas, paint, 0, 17 * blockSize, blockSize);
  }

  void _drawCornerMarker(Canvas canvas, Paint paint, double x, double y, double blockSize) {
    // Dessiner le carré extérieur
    canvas.drawRect(
      Rect.fromLTWH(x, y, blockSize * 3, blockSize * 3),
      paint,
    );
    
    // Dessiner le carré intérieur blanc
    canvas.drawRect(
      Rect.fromLTWH(x + blockSize * 0.5, y + blockSize * 0.5, blockSize * 2, blockSize * 2),
      Paint()..color = Colors.white,
    );
    
    // Dessiner le point central
    canvas.drawRect(
      Rect.fromLTWH(x + blockSize, y + blockSize, blockSize, blockSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! _QRPatternPainter || oldDelegate.data != data;
  }
}
