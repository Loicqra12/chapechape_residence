import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:logger/logger.dart';
import '../../config/cloudinary_config.dart';
import '../../models/residence/residence_image.dart';

/// Service pour gérer les interactions avec Cloudinary
class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  final logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  /// Upload une image vers Cloudinary
  /// Retourne l'URL de l'image uploadée
  Future<String> uploadImage(dynamic image, {String folder = 'chapechape/residences'}) async {
    try {
      logger.i('🚀 Début upload Cloudinary - Dossier: $folder');
      
      // Construire l'URL d'upload
      final uploadUrl = 'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload';
      logger.d('URL upload: $uploadUrl');

      // Créer la requête
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      
      // Ajouter les paramètres d'authentification
      request.fields['api_key'] = CloudinaryConfig.apiKey;
      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
      request.fields['folder'] = folder;
      
      // Préparation de l'image selon son type
      if (image is ResidenceImage) {
        // Cas 1: C'est une instance de ResidenceImage
        if (image.url != null && image.url!.startsWith('http')) {
          // C'est déjà une URL, la retourner
          logger.i('Image déjà en ligne: ${image.url}');
          return image.url!;
        } else if (image.isWeb && image.webImage != null) {
          // Image web (Uint8List)
          logger.d('Préparation image web (${image.webImage!.length} octets)');
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            image.webImage!,
            filename: 'image_web.jpg',
            contentType: MediaType('image', 'jpeg'),
          ));
        } else if (image.file != null && !kIsWeb) {
          // Image fichier (mobile)
          logger.d('Préparation image mobile: ${image.file!.path}');
          request.files.add(await http.MultipartFile.fromPath(
            'file',
            image.file!.path,
            contentType: MediaType('image', 'jpeg'),
          ));
        } else {
          throw Exception('Format d\'image non supporté dans ResidenceImage');
        }
      } else if (image is File && !kIsWeb) {
        // Cas 2: C'est un fichier (mobile)
        logger.d('Préparation fichier: ${image.path}');
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          image.path,
          contentType: MediaType('image', path.extension(image.path).replaceAll('.', '')),
        ));
      } else if (image is Uint8List) {
        // Cas 3: C'est un tableau d'octets (web principalement)
        logger.d('Préparation bytes: ${image.length} octets');
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          image,
          filename: 'image.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      } else if (image is String && image.startsWith('http')) {
        // Cas 4: C'est déjà une URL
        logger.i('Image déjà en ligne: $image');
        return image;
      } else {
        throw Exception('Type d\'image non supporté: ${image.runtimeType}');
      }

      // Envoi de la requête
      logger.i('Envoi de la requête Cloudinary...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      // Vérification de la réponse
      if (response.statusCode == 200) {
        final responseData = response.body;
        logger.d('Réponse: $responseData');
        
        // Extraire l'URL de l'image
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          await compute((String s) => jsonDecode(s), responseData)
        );
        
        final secureUrl = data['secure_url'] as String;
        logger.i('✅ Upload réussi: $secureUrl');
        
        return secureUrl;
      } else {
        logger.e('❌ Erreur upload: ${response.statusCode} - ${response.body}');
        throw Exception('Échec de l\'upload Cloudinary: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('❌❌ Exception complète: $e');
      throw Exception('Erreur lors de l\'upload vers Cloudinary: $e');
    }
  }

  /// Upload multiple images vers Cloudinary
  Future<List<String>> uploadImages(List<dynamic> images, {String folder = 'chapechape/residences'}) async {
    List<String> urls = [];
    
    for (var image in images) {
      try {
        final url = await uploadImage(image, folder: folder);
        urls.add(url);
      } catch (e) {
        logger.e('Erreur upload image dans batch: $e');
        // Continuer avec les autres images
      }
    }
    
    return urls;
  }

  /// Générer une URL optimisée pour l'affichage
  String getOptimizedUrl(String url, {
    int? width,
    int? height,
    int quality = 80,
    bool isLowBandwidth = false,
    bool progressive = true,
  }) {
    try {
      // Si ce n'est pas une URL Cloudinary, la retourner telle quelle
      if (!url.contains('cloudinary.com')) return url;
      
      // Construire les transformations
      final List<String> transformations = [];
      
      // Dimensions
      if (width != null) transformations.add('w_$width');
      if (height != null) transformations.add('h_$height');
      
      // Qualité adaptée à la bande passante
      final qualityParam = isLowBandwidth ? 'q_auto:low' : 'q_$quality';
      transformations.add(qualityParam);
      
      // Format adaptatif et chargement progressif
      transformations.add('f_auto');
      if (progressive) transformations.add('fl_progressive');
      
      // Appliquer les transformations à l'URL
      final transformation = transformations.join(',');
      
      // Trouver où insérer la transformation
      final uploadIndex = url.indexOf('/upload/');
      if (uploadIndex == -1) return url;
      
      final optimizedUrl = 
          url.substring(0, uploadIndex + 8) + 
          '$transformation/' + 
          url.substring(uploadIndex + 8);
      
      logger.d('URL optimisée: $optimizedUrl');
      return optimizedUrl;
    } catch (e) {
      logger.e('Erreur optimisation URL: $e');
      return url; // En cas d'erreur, retourner l'URL originale
    }
  }
  
  /// Supprimer une image de Cloudinary
  Future<bool> deleteImage(String url) async {
    try {
      // Extraire le public_id de l'URL
      final publicId = _extractPublicId(url);
      if (publicId == null) {
        logger.e('Impossible d\'extraire le public_id de l\'URL: $url');
        return false;
      }
      
      logger.i('Suppression de l\'image: $publicId');
      
      // Construire l'URL de suppression
      final deleteUrl = Uri.parse(
        'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/destroy'
      );
      
      // Préparer les paramètres
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signature = _generateSignature({
        'public_id': publicId,
        'timestamp': timestamp.toString(),
      });
      
      // Envoi de la requête
      final response = await http.post(
        deleteUrl,
        body: {
          'public_id': publicId,
          'api_key': CloudinaryConfig.apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      );
      
      if (response.statusCode == 200) {
        logger.i('✅ Image supprimée avec succès');
        return true;
      } else {
        logger.e('❌ Échec de la suppression: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      logger.e('Exception lors de la suppression: $e');
      return false;
    }
  }
  
  /// Extraire le public_id d'une URL Cloudinary
  String? _extractPublicId(String url) {
    try {
      // Format: https://res.cloudinary.com/djeares5m/image/upload/v1234567890/chapechape/residences/image.jpg
      final regex = RegExp(r'\/v\d+\/(.+)\.\w+$');
      final match = regex.firstMatch(url);
      return match?.group(1);
    } catch (e) {
      logger.e('Erreur extraction public_id: $e');
      return null;
    }
  }
  
  /// Générer une signature pour les requêtes authentifiées
  String _generateSignature(Map<String, String> params) {
    try {
      // Trier les paramètres par clé
      final sortedKeys = params.keys.toList()..sort();
      
      // Construire la chaîne à signer
      String toSign = '';
      for (var key in sortedKeys) {
        toSign += '$key=${params[key]}&';
      }
      toSign = toSign.substring(0, toSign.length - 1) + CloudinaryConfig.apiSecret;
      
      // Calculer le hash SHA-1
      final bytes = utf8.encode(toSign);
      final digest = sha1.convert(bytes);
      
      return digest.toString();
    } catch (e) {
      logger.e('Erreur génération signature: $e');
      throw Exception('Erreur de signature: $e');
    }
  }
}
