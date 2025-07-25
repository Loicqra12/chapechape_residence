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
      textDirection: TextDirection.ltr,
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
  /// Format similaire à Booking.com - fond bleu foncé avec prix en blanc
  static Future<BitmapDescriptor> createPriceMarker({
    required double price,
    required Color backgroundColor,
    double width = 120, // Largeur augmentée
    double height = 50, // Hauteur augmentée
  }) async {
    // Créer un PictureRecorder pour dessiner le marqueur personnalisé
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    // Arrondir les coins du rectangle avec un rayon plus important
    final RRect rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(14),  // Coins plus arrondis pour s'adapter à la taille augmentée
    );
    
    // Dessiner le fond
    final Paint backgroundPaint = Paint()
      ..color = const Color(0xFF003580) // Bleu Booking.com exact
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
    
    // Configurer le texte du prix - taille augmentée pour une meilleure lisibilité
    final textStyle = ui.TextStyle(
      color: Colors.white,
      fontSize: 24,  // Taille augmentée pour plus de lisibilité
      fontWeight: FontWeight.bold, // Plus gras pour une meilleure visibilité
      letterSpacing: -0.2, // Espacement des lettres optimisé
    );
    
    // Formater le prix en gérant correctement les grands nombres
    String formattedPrice;
    final priceInt = price.toInt();
    
    // Format compact pour tous les prix
    if (priceInt >= 1000000) {
      // Pour les prix élevés en millions
      formattedPrice = 'XOF ${(priceInt / 1000000).toStringAsFixed(1)}M';
    } else if (priceInt >= 1000) {
      // Pour les prix en milliers, format plus compact
      formattedPrice = 'XOF ${(priceInt / 1000).toStringAsFixed(0)}K';
    } else {
      // Pour les petits prix
      formattedPrice = 'XOF $priceInt';
    }
    
    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
      maxLines: 1,
    ))
      ..pushStyle(textStyle)
      ..addText(formattedPrice);
    
    final paragraph = paragraphBuilder.build();
    paragraph.layout(ui.ParagraphConstraints(width: width));
    
    // Positionner et dessiner le texte
    canvas.drawParagraph(
      paragraph,
      Offset((width - paragraph.maxIntrinsicWidth) / 2, (height - paragraph.height) / 2),
    );
    
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
