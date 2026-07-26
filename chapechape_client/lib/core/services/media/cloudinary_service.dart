import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:logger/logger.dart';
import '../../config/app_config_manager.dart';
import '../../config/cloudinary_config.dart';
import '../../utils/secure_storage.dart';

/// Service Cloudinary — upload **signé** via backend (api_secret jamais dans l'APK).
class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  final Logger logger = Logger(level: kReleaseMode ? Level.off : Level.debug);

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
      throw Exception('Signature Cloudinary refusée (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Réponse signature Cloudinary invalide');
    }
    return data;
  }

  Future<String> uploadImage(dynamic imageFile, {String? folder}) async {
    final targetFolder = folder ?? CloudinaryConfig.profilesFolder;
    try {
      final signed = await _fetchSignedParams(targetFolder);
      final cloudName = signed['cloudName'] as String? ?? CloudinaryConfig.cloudName;
      final uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.fields['api_key'] = signed['apiKey'].toString();
      request.fields['timestamp'] = signed['timestamp'].toString();
      request.fields['signature'] = signed['signature'].toString();
      request.fields['folder'] = signed['folder']?.toString() ?? targetFolder;

      if (imageFile is String && !imageFile.startsWith('http') && !imageFile.startsWith('data:')) {
        final file = File(imageFile);
        final fileName = path.basename(file.path);
        final extension = path.extension(fileName).toLowerCase().replaceAll('.', '');
        request.files.add(
          http.MultipartFile(
            'file',
            file.readAsBytes().asStream(),
            await file.length(),
            filename: fileName,
            contentType: MediaType('image', extension),
          ),
        );
      } else if (imageFile is File) {
        final fileName = path.basename(imageFile.path);
        final extension = path.extension(fileName).toLowerCase().replaceAll('.', '');
        request.files.add(
          http.MultipartFile(
            'file',
            imageFile.readAsBytes().asStream(),
            await imageFile.length(),
            filename: fileName,
            contentType: MediaType('image', extension),
          ),
        );
      } else if (imageFile is Uint8List) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageFile,
            filename: 'image.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      } else if (imageFile is String && imageFile.startsWith('data:image')) {
        final bytes = base64Decode(imageFile.split(',')[1]);
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: 'image.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      } else {
        throw Exception("Format d'image non supporté: ${imageFile.runtimeType}");
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonData['secure_url'] as String;
      }
      throw Exception('Échec de l\'upload Cloudinary: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) logger.e('Exception upload Cloudinary: $e');
      throw Exception('Erreur lors de l\'upload vers Cloudinary: $e');
    }
  }

  Future<List<String>> uploadImages(List<dynamic> images, {String? folder}) async {
    final uploadedUrls = <String>[];
    for (final image in images) {
      try {
        uploadedUrls.add(await uploadImage(image, folder: folder));
      } catch (e) {
        if (kDebugMode) logger.e('Erreur upload image: $e');
      }
    }
    return uploadedUrls;
  }

  String getOptimizedUrl(String url, {int? width, int? height, int? quality}) {
    try {
      if (!url.contains('cloudinary.com')) return url;
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) return url;

      final transformations = <String>[];
      if (width != null) transformations.add('w_$width');
      if (height != null) transformations.add('h_$height');
      if (quality != null) transformations.add('q_$quality');
      transformations.add('f_auto');
      transformations.add('fl_progressive');
      if (transformations.isEmpty) return url;

      final newPathSegments = List<String>.from(pathSegments);
      newPathSegments.insert(uploadIndex + 1, transformations.join(','));
      return uri.replace(pathSegments: newPathSegments).toString();
    } catch (_) {
      return url;
    }
  }

  Future<bool> deleteImage(String url) async => false;
}
