import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:video_compress/video_compress.dart';
import 'package:chapechape_partner/core/utils/app_logger.dart';
import 'package:chapechape_partner/core/utils/secure_storage.dart';
import 'package:chapechape_partner/core/config/app_config.dart';

/// Résultat d'un upload vidéo réussi.
class VideoUploadResult {
  final String url;
  final String publicId;
  final String? thumbnail;
  final int? durationSeconds;
  final int? sizeBytes;

  const VideoUploadResult({
    required this.url,
    required this.publicId,
    this.thumbnail,
    this.durationSeconds,
    this.sizeBytes,
  });
}

/// Gère l'upload vidéo depuis le device Partner vers Cloudinary,
/// puis l'enregistrement sur le backend.
class ResidenceVideoService {
  final String baseUrl;
  final Dio _dio;

  static const int _maxDurationSeconds = 90;
  static const int _maxSizeMB = 200;
  static const String _cloudinaryFolder = 'chapechape/residences/videos';

  ResidenceVideoService({String? baseUrl})
      : baseUrl = (baseUrl ?? AppConfig.apiUrl).replaceAll(RegExp(r'/+$'), ''),
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(minutes: 10),
        ));

  /// [AppConfig.apiUrl] vaut déjà `…/api` — ne pas préfixer encore `/api`.
  String get _apiRoot => baseUrl;

  Future<String?> _authToken() =>
      AppSecureStorage.instance.read(key: AppSecureStorage.tokenKey);

  // ---------------------------------------------------------------------------
  // Validation locale avant tout upload
  // ---------------------------------------------------------------------------

  /// Valide la durée de la vidéo. Lance une [Exception] si trop longue.
  Future<void> validateVideoDuration(File videoFile) async {
    final info = await VideoCompress.getMediaInfo(videoFile.path);
    final durationMs = info.duration ?? 0;
    final durationSec = (durationMs / 1000).ceil();
    if (durationSec > _maxDurationSeconds) {
      throw Exception(
        'Vidéo trop longue : ${durationSec}s (max ${_maxDurationSeconds}s).\n'
        'Rognez la vidéo avant de l\'importer.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Compression
  // ---------------------------------------------------------------------------

  /// Compresse la vidéo vers 720p / ~2 Mbps.
  /// Retourne le [File] compressé (ou l'original si la compression échoue).
  Future<File> compressVideo(
    File videoFile, {
    void Function(double progress)? onProgress,
  }) async {
    AppLogger.d('Compression vidéo : ${videoFile.path}');
    try {
      final subscription = VideoCompress.compressProgress$.subscribe((p) {
        onProgress?.call(p / 100.0);
      });

      final result = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
        frameRate: 30,
      );

      subscription.unsubscribe();

      if (result?.file == null) {
        AppLogger.d('Compression échouée, utilisation du fichier original');
        return videoFile;
      }

      final compressed = result!.file!;
      final compressedMb =
          (compressed.lengthSync() / 1024 / 1024).toStringAsFixed(1);
      AppLogger.d('Compression OK → $compressedMb Mo');
      return compressed;
    } catch (e) {
      AppLogger.e('Erreur compression vidéo', e);
      return videoFile;
    }
  }

  // ---------------------------------------------------------------------------
  // Signature Cloudinary
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _getCloudinarySignature() async {
    final token = await _authToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentification requise pour uploader une vidéo');
    }

    final url = '$_apiRoot/media/cloudinary-signature';
    AppLogger.d('Signature vidéo → GET $url');

    final response = await _dio.get(
      url,
      queryParameters: {
        'folder': _cloudinaryFolder,
        'resource_type': 'video',
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'x-mobile-app': 'true',
        },
      ),
    );

    if (response.statusCode != 200 || response.data?['success'] != true) {
      throw Exception('Impossible d\'obtenir la signature Cloudinary');
    }
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  // ---------------------------------------------------------------------------
  // Upload direct vers Cloudinary
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _uploadToCloudinary(
    File videoFile,
    Map<String, dynamic> signature, {
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final cloudName = signature['cloudName'] as String;
    final apiKey = signature['apiKey'] as String;
    final ts = signature['timestamp'].toString();
    final sig = signature['signature'] as String;
    final folder = signature['folder'] as String;

    // Ne pas renvoyer resource_type dans le form : Cloudinary l'exclut de la
    // signature (il est déjà dans l'URL /video/upload).
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        videoFile.path,
        contentType: DioMediaType('video', 'mp4'),
      ),
      'api_key': apiKey,
      'timestamp': ts,
      'signature': sig,
      'folder': folder,
    });

    final uploadUrl =
        'https://api.cloudinary.com/v1_1/$cloudName/video/upload';

    final response = await _dio.post(
      uploadUrl,
      data: formData,
      cancelToken: cancelToken,
      onSendProgress: (sent, total) {
        if (total > 0) onProgress?.call(sent / total);
      },
      options: Options(
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(minutes: 10),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Échec upload Cloudinary (${response.statusCode})');
    }
    return Map<String, dynamic>.from(response.data as Map);
  }

  // ---------------------------------------------------------------------------
  // Enregistrement backend
  // ---------------------------------------------------------------------------

  Future<void> _registerVideoOnBackend({
    required String residenceId,
    required String url,
    required String publicId,
    int? durationSeconds,
    int? sizeBytes,
  }) async {
    final token = await _authToken();
    final endpoint = '$_apiRoot/residences/$residenceId/videos';
    AppLogger.d('Enregistrement vidéo → POST $endpoint');

    final response = await _dio.post(
      endpoint,
      data: {
        'url': url,
        'publicId': publicId,
        if (durationSeconds != null) 'duration': durationSeconds,
        if (sizeBytes != null) 'size': sizeBytes,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'x-mobile-app': 'true',
        },
      ),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        'Backend a rejeté la vidéo (${response.statusCode}) : '
        '${response.data?['message'] ?? 'Erreur inconnue'}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Méthode publique principale
  // ---------------------------------------------------------------------------

  /// Flux complet : validation → compression → upload Cloudinary → backend.
  ///
  /// [onProgress] reçoit une valeur entre 0.0 et 1.0 (compression 0-0.4, upload 0.4-1.0).
  Future<VideoUploadResult> uploadVideo({
    required String residenceId,
    required File videoFile,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    // 1. Validation taille brute
    final rawSize = videoFile.lengthSync();
    if (rawSize > _maxSizeMB * 1024 * 1024) {
      throw Exception(
        'Vidéo trop volumineuse : ${(rawSize / 1024 / 1024).toStringAsFixed(0)} Mo (max $_maxSizeMB Mo)',
      );
    }

    // 2. Validation durée
    await validateVideoDuration(videoFile);

    // 3. Compression (0 → 40 % de la progression)
    final compressed = await compressVideo(
      videoFile,
      onProgress: (p) => onProgress?.call(p * 0.4),
    );

    // 4. Signature
    onProgress?.call(0.4);
    final signature = await _getCloudinarySignature();

    // 5. Upload Cloudinary (40 → 95 %)
    final cloudinaryResult = await _uploadToCloudinary(
      compressed,
      signature,
      cancelToken: cancelToken,
      onProgress: (p) => onProgress?.call(0.4 + p * 0.55),
    );

    final url = cloudinaryResult['secure_url'] as String;
    final publicId = cloudinaryResult['public_id'] as String;
    final duration = cloudinaryResult['duration'] != null
        ? (cloudinaryResult['duration'] as num).ceil()
        : null;
    final size = compressed.lengthSync();

    // 6. Enregistrement backend (95 → 100 %)
    await _registerVideoOnBackend(
      residenceId: residenceId,
      url: url,
      publicId: publicId,
      durationSeconds: duration,
      sizeBytes: size,
    );

    onProgress?.call(1.0);

    AppLogger.d('✅ Vidéo uploadée : $url');

    return VideoUploadResult(
      url: url,
      publicId: publicId,
      durationSeconds: duration,
      sizeBytes: size,
    );
  }

  // ---------------------------------------------------------------------------
  // Suppression
  // ---------------------------------------------------------------------------

  /// Supprime une vidéo par son [videoId] (subdoc MongoDB).
  Future<void> deleteVideo({
    required String residenceId,
    required String videoId,
  }) async {
    final token = await _authToken();
    final response = await _dio.delete(
      '$_apiRoot/residences/$residenceId/videos/$videoId',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'x-mobile-app': 'true',
        },
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Impossible de supprimer la vidéo (${response.statusCode})',
      );
    }
  }
}
