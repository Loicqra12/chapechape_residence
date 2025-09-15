import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
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
  
  /// Crée un marqueur personnalisé avec le prix de la résidence directement intégré
  /// Format exact de la capture d'écran - bulle rose avec icône de lit et prix F CFA
  static Future<BitmapDescriptor> createPriceMarker({
    required double price,
    required Color backgroundColor,
    String? iconEmoji, // Icône de lit/maison
    double width = 100, // Largeur adaptée au format "XX XXX F CFA"
    double height = 36, // Hauteur pour contenir l'icône et le texte
  }) async {
    // Créer un PictureRecorder pour dessiner le marqueur personnalisé
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    // Arrondir les coins du rectangle comme dans la capture d'écran
    final RRect rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(8),  // Coins modérément arrondis comme dans la capture
    );
    
    // Dessiner le fond - ROSE COMME DANS LA CAPTURE D'ÉCRAN
    final Paint backgroundPaint = Paint()
      ..color = const Color(0xFFE91E63) // Rose comme dans la capture d'écran
      ..style = PaintingStyle.fill;
    
    // Dessiner d'abord l'ombre pour qu'elle apparaisse sous l'étiquette
    canvas.drawShadow(
      Path()..addRRect(rRect),
      Colors.black,
      3.0,  // Ombre plus prononcée pour améliorer le contraste
      true,
    );
    
    // Dessiner l'étiquette bleue
    canvas.drawRRect(rRect, backgroundPaint);
    
    // Ajouter un triangle en bas pour le style "bulle de dialogue" (augmenté proportionnellement)
    final Path trianglePath = Path();
    trianglePath.moveTo(width / 2 - 8, height); // Point gauche élargi
    trianglePath.lineTo(width / 2 + 8, height); // Point droit élargi
    trianglePath.lineTo(width / 2, height + 8); // Point bas allongé
    trianglePath.close();
    
    canvas.drawPath(trianglePath, backgroundPaint);
    
    // Dessiner l'icône de lit/maison à gauche (comme dans la capture)
    if (iconEmoji != null && iconEmoji.isNotEmpty) {
      final iconStyle = ui.TextStyle(
        color: Colors.white,
        fontSize: 14, // Taille pour l'icône de lit visible
        fontWeight: FontWeight.bold,
      );
      
      final iconBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.center,
        maxLines: 1,
      ))
        ..pushStyle(iconStyle)
        ..addText(iconEmoji);
      
      final iconParagraph = iconBuilder.build();
      iconParagraph.layout(ui.ParagraphConstraints(width: 20)); // Espace fixe pour l'icône
      
      // Positionner l'icône à gauche avec padding
      canvas.drawParagraph(
        iconParagraph,
        Offset(8, (height - iconParagraph.height) / 2),
      );
    }
    
    // Configurer le texte du prix - taille adaptée à la capture d'écran
    final textStyle = ui.TextStyle(
      color: Colors.white,
      fontSize: 14,  // Taille réduite pour correspondre à la capture
      fontWeight: FontWeight.bold,
      letterSpacing: -0.2,
    );
    
    // Formater le prix exactement comme dans la capture d'écran : "XX XXX F CFA"
    String formattedPrice;
    final priceInt = price.toInt();
    
    // Format exact de la capture : "27 146 F CFA", "31 872 F CFA", "52 873 F CFA"
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'F CFA',
      decimalDigits: 0,
    );
    formattedPrice = formatter.format(priceInt);
    
    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
      maxLines: 1,
    ))
      ..pushStyle(textStyle)
      ..addText(formattedPrice);
    
    final paragraph = paragraphBuilder.build();
    paragraph.layout(ui.ParagraphConstraints(width: width - (iconEmoji != null ? 30 : 0)));
    
    // Positionner le prix à droite de l'icône (comme dans la capture)
    final priceOffset = iconEmoji != null 
        ? Offset(32, (height - paragraph.height) / 2) // 32px pour laisser place à l'icône
        : Offset((width - paragraph.maxIntrinsicWidth) / 2, (height - paragraph.height) / 2);
    
    canvas.drawParagraph(paragraph, priceOffset);
    
    // Convertir le dessin en image
    final ui.Image image = await pictureRecorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
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
}
