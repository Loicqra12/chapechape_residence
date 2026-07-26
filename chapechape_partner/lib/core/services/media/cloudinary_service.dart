import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, compute, kDebugMode, kReleaseMode;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:logger/logger.dart';
import '../../config/app_config_manager.dart';
import '../../config/cloudinary_config.dart';
import '../../models/residence/residence_image.dart';
import '../../utils/secure_storage.dart';

/// Service Cloudinary — upload **signé** via backend (api_secret jamais dans l'APK).
class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  final logger = Logger(
    level: kReleaseMode ? Level.off : Level.debug,
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  Future<Map<String, dynamic>> _fetchSignedParams(String folder) async {
    final token = await AppSecureStorage.instance.read(key: AppSecureStorage.tokenKey);
    if (token == null || token.isEmpty) {
      throw Exception('Authentification requise pour uploader une image');
    }

    final base = AppConfigManager.apiUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/media/cloudinary-signature').replace(
      queryParameters: {'folder': folder},
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'x-mobile-app': 'true',
      },
    );

    if (response.statusCode != 200) {
      String detail = '';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['message'] != null) {
          detail = ': ${body['message']}';
        }
      } catch (_) {}
      throw Exception(
        'Signature Cloudinary refusée (${response.statusCode})$detail',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Réponse signature Cloudinary invalide');
    }
    return data;
  }

  Future<String> uploadImage(dynamic image, {String folder = 'chapechape/residences'}) async {
    try {
      if (kDebugMode) logger.i('Début upload Cloudinary signé — dossier: $folder');

      final signed = await _fetchSignedParams(folder);
      final cloudName = signed['cloudName'] as String? ?? CloudinaryConfig.cloudName;
      final uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.fields['api_key'] = signed['apiKey'].toString();
      request.fields['timestamp'] = signed['timestamp'].toString();
      request.fields['signature'] = signed['signature'].toString();
      request.fields['folder'] = signed['folder']?.toString() ?? folder;

      if (image is ResidenceImage) {
        if (image.url != null && image.url!.startsWith('http')) {
          return image.url!;
        } else if (image.isWeb && image.webImage != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            image.webImage!,
            filename: 'image_web.jpg',
            contentType: MediaType('image', 'jpeg'),
          ));
        } else if (image.file != null && !kIsWeb) {
          request.files.add(await http.MultipartFile.fromPath(
            'file',
            image.file!.path,
            contentType: MediaType('image', 'jpeg'),
          ));
        } else {
          throw Exception('Format d\'image non supporté dans ResidenceImage');
        }
      } else if (image is File && !kIsWeb) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          image.path,
          contentType: MediaType('image', path.extension(image.path).replaceAll('.', '')),
        ));
      } else if (image is Uint8List) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          image,
          filename: 'image.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      } else if (image is String && image.startsWith('http')) {
        return image;
      } else {
        throw Exception('Type d\'image non supporté: ${image.runtimeType}');
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          await compute((String s) => jsonDecode(s), response.body),
        );
        return data['secure_url'] as String;
      }

      throw Exception('Échec de l\'upload Cloudinary: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) logger.e('Exception upload Cloudinary: $e');
      throw Exception('Erreur lors de l\'upload vers Cloudinary: $e');
    }
  }

  Future<List<String>> uploadImages(List<dynamic> images, {String folder = 'chapechape/residences'}) async {
    final urls = <String>[];
    for (final image in images) {
      try {
        urls.add(await uploadImage(image, folder: folder));
      } catch (e) {
        if (kDebugMode) logger.e('Erreur upload image dans batch: $e');
      }
    }
    return urls;
  }

  String getOptimizedUrl(
    String url, {
    int? width,
    int? height,
    int quality = 80,
    bool isLowBandwidth = false,
    bool progressive = true,
  }) {
    try {
      if (!url.contains('cloudinary.com')) return url;

      final transformations = <String>[];
      if (width != null) transformations.add('w_$width');
      if (height != null) transformations.add('h_$height');
      transformations.add(isLowBandwidth ? 'q_auto:low' : 'q_$quality');
      transformations.add('f_auto');
      if (progressive) transformations.add('fl_progressive');

      final uploadIndex = url.indexOf('/upload/');
      if (uploadIndex == -1) return url;

      return '${url.substring(0, uploadIndex + 8)}${transformations.join(',')}/${url.substring(uploadIndex + 8)}';
    } catch (_) {
      return url;
    }
  }

  Future<bool> deleteImage(String url) async {
    return false;
  }
}
