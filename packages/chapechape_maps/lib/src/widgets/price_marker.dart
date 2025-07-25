import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Classe utilitaire pour créer des marqueurs avec prix personnalisés
class PriceMarker {
  /// Crée un marqueur avec un prix affiché
  static Future<Marker> createPriceMarker({
    required String id,
    required LatLng position,
    required String price,
    required BuildContext context,
    VoidCallback? onTap,
    Color backgroundColor = Colors.blue,
    Color textColor = Colors.white,
    bool selected = false,
    String? title,
    String? snippet,
  }) async {
    // Créer une icône personnalisée
    final BitmapDescriptor icon = await _createPriceMarkerIcon(
      price: price,
      context: context,
      backgroundColor: backgroundColor,
      textColor: textColor,
      selected: selected,
    );
    
    // Créer et retourner le marqueur
    return Marker(
      markerId: MarkerId(id),
      position: position,
      icon: icon,
      onTap: onTap,
      infoWindow: title != null || snippet != null
          ? InfoWindow(
              title: title,
              snippet: snippet,
            )
          : InfoWindow.noText,
      // Animation simple lors de l'ajout du marqueur
      alpha: 0.9,
      // Priorité d'affichage (les marqueurs sélectionnés seront au-dessus)
      zIndex: selected ? 2.0 : 1.0,
    );
  }
  
  /// Crée une icône de marqueur personnalisée avec un prix affiché
  static Future<BitmapDescriptor> _createPriceMarkerIcon({
    required String price,
    required BuildContext context,
    required Color backgroundColor,
    required Color textColor,
    required bool selected,
  }) async {
    // Taille du marqueur
    final double size = selected ? 110 : 100;
    const double markerSize = 120;
    
    // Créer un widget de marqueur de prix
    final PriceMarkerPainter markerWidget = PriceMarkerPainter(
      price: price,
      backgroundColor: backgroundColor,
      textColor: textColor,
      selected: selected,
      size: size,
    );
    
    // Convertir le widget en image
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    
    markerWidget.paint(canvas, Size(markerSize, markerSize));
    
    final ui.Image image = await recorder.endRecording().toImage(
      markerSize.toInt(),
      markerSize.toInt(),
    );
    
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    
    if (byteData == null) {
      // Retourner une icône par défaut en cas d'échec
      return BitmapDescriptor.defaultMarker;
    }
    
    final Uint8List bytes = byteData.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(bytes);
  }
}

/// Classe pour dessiner un marqueur de prix personnalisé
class PriceMarkerPainter extends CustomPainter {
  final String price;
  final Color backgroundColor;
  final Color textColor;
  final bool selected;
  final double size;
  
  PriceMarkerPainter({
    required this.price,
    required this.backgroundColor,
    required this.textColor,
    required this.selected,
    required this.size,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Définir le centre
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    
    // Rayon du cercle principal
    final double radius = this.size / 2;
    
    // Peindre l'ombre
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    canvas.drawCircle(
      Offset(centerX, centerY + 2),
      radius,
      shadowPaint,
    );
    
    // Peindre le cercle principal
    final Paint circlePaint = Paint()..color = backgroundColor;
    
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      circlePaint,
    );
    
    // Peindre la bordure si sélectionné
    if (selected) {
      final Paint borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      
      canvas.drawCircle(
        Offset(centerX, centerY),
        radius + 2,
        borderPaint,
      );
    }
    
    // Dessiner la pointe du marqueur
    final Path path = Path()
      ..moveTo(centerX, centerY + radius - 2)
      ..lineTo(centerX - 8, centerY + radius + 8)
      ..lineTo(centerX + 8, centerY + radius + 8)
      ..close();
    
    final Paint pointPaint = Paint()..color = backgroundColor;
    canvas.drawPath(path, pointPaint);
    
    // Dessiner le prix
    final textStyle = TextStyle(
      color: textColor,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );
    
    final textSpan = TextSpan(
      text: price,
      style: textStyle,
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    textPainter.layout();
    
    final textX = centerX - textPainter.width / 2;
    final textY = centerY - textPainter.height / 2;
    
    textPainter.paint(canvas, Offset(textX, textY));
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
