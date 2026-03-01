import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:typed_data';
import '../extensions/residence_marker_extension.dart';

/// Classe utilitaire pour générer des marqueurs personnalisés
class CustomMarkerGenerator {
  /// Cache statique pour les marqueurs de cluster
  static final Map<int, BitmapDescriptor> _clusterMarkers = {};
  
  /// Crée un marqueur personnalisé pour un cluster de résidences
  static Future<BitmapDescriptor> createClusterMarker({
    required int count,
    double radius = 50,  // Rayon augmenté pour une meilleure visibilité
    Color backgroundColor = const Color(0xFF003580), // Bleu foncé de Booking.com
    Color textColor = Colors.white,
  }) async {
    // Vérifier si le marqueur est déjà en cache
    if (_clusterMarkers.containsKey(count)) {
      return _clusterMarkers[count]!;
    }
    
    // Créer un recorder pour dessiner sur un Canvas
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = backgroundColor;
    final double circleRadius = radius;
    
    // Dessiner le cercle principal
    canvas.drawCircle(
      Offset(circleRadius, circleRadius),
      circleRadius,
      paint,
    );
    
    // Ajouter une ombre légère
    canvas.drawCircle(
      Offset(circleRadius, circleRadius),
      circleRadius,
      Paint()
        ..color = Colors.black26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    
    // Configurer la police et le style du texte avec une taille augmentée
    final textStyle = TextStyle(
      fontSize: count < 100 ? 22 : 20,  // Taille de police augmentée
      fontWeight: FontWeight.bold,
      color: textColor,
    );
    
    // Préparer le texte à afficher
    final textSpan = TextSpan(
      text: count.toString(),
      style: textStyle,
    );
    
    // Dessiner le texte
    final textPainter = TextPainter(
  text: textSpan,
  textDirection: ui.TextDirection.ltr,
  textAlign: TextAlign.center,
);
    
    textPainter.layout();
    
    // Centrer le texte
    textPainter.paint(
      canvas,
      Offset(
        circleRadius - textPainter.width / 2,
        circleRadius - textPainter.height / 2,
      ),
    );
    
    // Convertir l'image en BitmapDescriptor
    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(
      (2 * circleRadius).toInt(),
      (2 * circleRadius).toInt(),
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List data = byteData!.buffer.asUint8List();
    
    // Créer et mettre en cache le BitmapDescriptor
    final BitmapDescriptor markerIcon = BitmapDescriptor.fromBytes(data);
    _clusterMarkers[count] = markerIcon;
    
    return markerIcon;
  }
  /// Retourne une couleur de marqueur selon la catégorie de résidence
  static BitmapDescriptor getMarkerByCategory(String category) {
    switch (category) {
      case ResidenceMarkerExtension.categoryMeubles:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case ResidenceMarkerExtension.categoryHotels:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case ResidenceMarkerExtension.categoryInsolites:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      case ResidenceMarkerExtension.categoryColocations:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
  }
  
  /// Génère un BitmapDescriptor personnalisé si nécessaire
  /// Cette fonction est plus légère et plus fiable
  static Future<BitmapDescriptor> createSimpleMarker({
    required Color markerColor,
    double size = 150,
  }) async {
    // Créer un PictureRecorder pour dessiner le marqueur personnalisé
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Dessiner un cercle de la couleur spécifiée
    final Paint circlePaint = Paint()
      ..color = markerColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 4,
      circlePaint,
    );

    // Convertir le dessin en image
    final ui.Image image = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    
    // Convertir l'image en ByteData
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    
    // Convertir ByteData en Uint8List pour BitmapDescriptor
    final Uint8List uint8List = byteData!.buffer.asUint8List();
    
    // Créer le BitmapDescriptor
    return BitmapDescriptor.fromBytes(uint8List);
  }

  /// Obtenir les couleurs pour les marqueurs selon la catégorie
  static Color getMeubleColor() => Colors.blue.shade800;
  static Color getHotelColor() => Colors.red.shade800;
  static Color getInsoliteColor() => Colors.purple.shade800;
  static Color getColocationColor() => Colors.green.shade800;
  static Color getAutreColor() => Colors.orange.shade800;
  
  /// Méthode pour obtenir les couleurs d'InfoWindow selon catégorie
  static Color getInfoWindowColor(String category) {
    switch (category) {
      case ResidenceMarkerExtension.categoryMeubles:
        return getMeubleColor();
      case ResidenceMarkerExtension.categoryHotels:
        return getHotelColor();
      case ResidenceMarkerExtension.categoryInsolites:
        return getInsoliteColor();
      case ResidenceMarkerExtension.categoryColocations:
        return getColocationColor();
      default:
        return getAutreColor();
    }
  }
  
  /// Crée un marqueur complètement transparent pour masquer les pins standards
  /// tout en conservant leur fonctionnalité d'ancrage pour les overlays
  static Future<BitmapDescriptor> createTransparentMarker() async {
    // Créer un PictureRecorder pour dessiner un marqueur transparent
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 1.0; // Très petite taille
    
    // Dessiner un point transparent (invisible)
    final Paint transparentPaint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      transparentPaint,
    );
    
    // Convertir le dessin en image
    final ui.Image image = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    
    // Convertir l'image en ByteData
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    
    // Convertir ByteData en Uint8List pour BitmapDescriptor
    final Uint8List uint8List = byteData!.buffer.asUint8List();
    
    // Créer le BitmapDescriptor transparent
    return BitmapDescriptor.fromBytes(uint8List);
  }
  
  /// Obtient un marqueur transparent simplifié
  static BitmapDescriptor getTransparentMarker() {
    // Utiliser une teinte très claire pour rendre le marqueur difficile à voir
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
  }
  
  /// Marqueur prix style Google Hotels — or royal #D4AF37, largeur dynamique, icône Material
  /// [isSelected] : fond blanc + bordure or + texte or (état sélectionné)
  static Future<BitmapDescriptor> createPriceMarker({
    required double price,
    bool isSelected = false,
  }) async {
    // ── Constantes de mise en page ──────────────────────────────────────────
    const double scale     = 2.5;   // rendu hi-DPI
    const double bubbleH   = 42.0;
    const double arrowH    = 9.0;
    const double hPad      = 11.0;
    const double iconSz    = 17.0;
    const double gap       = 5.0;
    const double fontSize  = 13.0;
    const double radius    = bubbleH / 2;
    const Color  gold      = Color(0xFFD4AF37);

    final Color bgColor = isSelected ? Colors.white : gold;
    final Color fgColor = isSelected ? gold : Colors.white;

    // ── Formatage du prix ────────────────────────────────────────────────────
    final String priceStr = _formatPriceCFA(price.toInt());

    // ── Mesure du texte prix ─────────────────────────────────────────────────
    final TextPainter tpPrice = TextPainter(
      text: TextSpan(
        text: priceStr,
        style: const TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // ── Mesure de l'icône ────────────────────────────────────────────────────
    final TextPainter tpIcon = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.hotel.codePoint),
        style: TextStyle(
          fontSize: iconSz,
          fontFamily: Icons.hotel.fontFamily,
          package: Icons.hotel.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final double iconW   = tpIcon.width;
    final double bubbleW = hPad + iconW + gap + tpPrice.width + hPad;
    final double totalH  = bubbleH + arrowH;

    // ── Canvas ──────────────────────────────────────────────────────────────
    final recorder = ui.PictureRecorder();
    final canvas   = Canvas(recorder);
    canvas.scale(scale, scale);

    // Ombre portée
    canvas.drawShadow(
      Path()..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, bubbleW - 2, bubbleH - 2),
        const Radius.circular(radius),
      )),
      Colors.black54,
      5.0,
      true,
    );

    // Fond pill
    final pillRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, bubbleW, bubbleH),
      const Radius.circular(radius),
    );
    canvas.drawRRect(pillRRect, Paint()..color = bgColor);

    // Bordure
    canvas.drawRRect(
      pillRRect,
      Paint()
        ..color = isSelected ? gold : Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.5 : 1.0,
    );

    // Triangle pointeur bas-centre
    final double ax = bubbleW / 2;
    final arrowFill = Path()
      ..moveTo(ax - 7, bubbleH)
      ..lineTo(ax + 7, bubbleH)
      ..lineTo(ax, totalH)
      ..close();
    canvas.drawPath(arrowFill, Paint()..color = bgColor);
    if (isSelected) {
      canvas.drawPath(
        Path()
          ..moveTo(ax - 7, bubbleH)
          ..lineTo(ax, totalH)
          ..lineTo(ax + 7, bubbleH),
        Paint()
          ..color = gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Icône hotel (Material Icons font — rendu fiable sur tous appareils)
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.hotel.codePoint),
        style: TextStyle(
          fontSize: iconSz,
          fontFamily: Icons.hotel.fontFamily,
          package: Icons.hotel.fontPackage,
          color: fgColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(canvas, Offset(hPad, (bubbleH - iconPainter.height) / 2));

    // Texte prix
    final para = (ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.left,
      maxLines: 1,
    ))
      ..pushStyle(ui.TextStyle(
        color: fgColor,
        fontSize: fontSize,
        fontWeight: ui.FontWeight.w700,
      ))
      ..addText(priceStr))
      .build()
      ..layout(ui.ParagraphConstraints(width: tpPrice.width + 4));

    canvas.drawParagraph(
      para,
      Offset(hPad + iconW + gap, (bubbleH - para.height) / 2),
    );

    // ── Conversion en BitmapDescriptor ──────────────────────────────────────
    final img = await recorder.endRecording().toImage(
      (bubbleW * scale).ceil(),
      (totalH  * scale).ceil(),
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  /// Formate un prix entier en "28 424 F CFA" (espace fine insécable)
  static String _formatPriceCFA(int price) {
    final str = price.toString();
    final buf = StringBuffer();
    final len = str.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buf.write('\u202F');
      buf.write(str[i]);
    }
    return '${buf.toString()} F CFA';
  }
}
