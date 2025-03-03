import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class ResidenceImage {
  final File? file;
  final Uint8List? webImage;

  ResidenceImage.fromFile(File file)
      : file = file,
        webImage = null;

  ResidenceImage.fromWeb(Uint8List bytes)
      : file = null,
        webImage = bytes;

  bool get isWeb => webImage != null;
  
  static List<ResidenceImage> fromMixed(dynamic images) {
    if (kIsWeb && images is List<Uint8List>) {
      return images.map((bytes) => ResidenceImage.fromWeb(bytes)).toList();
    } else if (!kIsWeb && images is List<File>) {
      return images.map((file) => ResidenceImage.fromFile(file)).toList();
    }
    return [];
  }
}
