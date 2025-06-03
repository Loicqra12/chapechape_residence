import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:logger/logger.dart';
import '../../config/cloudinary_config.dart';

/// Service pour gérer les interactions avec Cloudinary
class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();
  
  final Logger logger = Logger();

  /// Upload une image vers Cloudinary
  /// 
  /// Prend en charge différents formats d'entrée: File, String (chemin de fichier), Uint8List, Base64
  Future<String> uploadImage(dynamic imageFile, {String? folder}) async {
    try {
      logger.i('🚀 Début upload Cloudinary - Dossier: $folder');
      
      // Construire l'URL d'upload
      final uploadUrl = 'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload';
      
      // Créer la requête multipart
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      
      // Ajouter les paramètres nécessaires
      request.fields['api_key'] = CloudinaryConfig.apiKey;
      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
      if (folder != null) {
        request.fields['folder'] = folder;
      }
      
      // Générer un timestamp et une signature si nécessaire
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      request.fields['timestamp'] = timestamp.toString();
      
      // Préparer le fichier selon son type
      if (imageFile is String && !imageFile.startsWith('http') && !imageFile.startsWith('data:')) {
        // C'est un chemin de fichier
        final file = File(imageFile);
        final fileName = path.basename(file.path);
        final extension = path.extension(fileName).toLowerCase().replaceAll('.', '');
        
        logger.i('📁 Préparation du fichier: $fileName (.$extension)');
        
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
        
        logger.i('📁 Préparation du fichier: $fileName (.$extension)');
        
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
        logger.i('📊 Préparation des bytes: ${imageFile.length} bytes');
        
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageFile,
            filename: 'image.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      } else if (imageFile is String && imageFile.startsWith('data:image')) {
        // Base64 image
        logger.i('📊 Décodage de l\'image base64');
        
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
      
      logger.i('Envoi de la requête Cloudinary...');
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final secureUrl = jsonData['secure_url'] as String;
        logger.i('✅ Upload Cloudinary réussi: $secureUrl');
        return secureUrl;
      } else {
        logger.e('❌ Erreur Cloudinary: ${jsonData['error']}');
        throw Exception('Échec de l\'upload Cloudinary: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('❌ Exception lors de l\'upload Cloudinary: $e');
      throw Exception('Erreur lors de l\'upload vers Cloudinary: $e');
    }
  }
  
  /// Upload multiple images vers Cloudinary
  Future<List<String>> uploadImages(List<dynamic> images, {String? folder}) async {
    final List<String> uploadedUrls = [];
    
    for (final image in images) {
      try {
        final url = await uploadImage(image, folder: folder);
        uploadedUrls.add(url);
      } catch (e) {
        logger.e('❌ Erreur lors de l\'upload d\'une image: $e');
        // Continuer avec les autres images même en cas d'erreur
      }
    }
    
    return uploadedUrls;
  }
  
  /// Obtient une URL Cloudinary optimisée avec transformations
  String getOptimizedUrl(String url, {int? width, int? height, int? quality}) {
    try {
      // Si ce n'est pas une URL Cloudinary, la retourner telle quelle
      if (!url.contains('cloudinary.com')) return url;
      
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      // Trouver l'index de "upload" dans le chemin
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) return url;
      
      // Construire les transformations
      final transformations = [];
      
      if (width != null) transformations.add('w_$width');
      if (height != null) transformations.add('h_$height');
      if (quality != null) transformations.add('q_$quality');
      
      // Format automatique et chargement progressif
      transformations.add('f_auto');
      transformations.add('fl_progressive');
      
      // Si aucune transformation, retourner l'URL originale
      if (transformations.isEmpty) return url;
      
      // Insérer les transformations dans le chemin
      final newPathSegments = List<String>.from(pathSegments);
      newPathSegments.insert(uploadIndex + 1, transformations.join(','));
      
      // Reconstruire l'URL avec les transformations
      final newUri = uri.replace(pathSegments: newPathSegments);
      
      return newUri.toString();
    } catch (e) {
      logger.e('❌ Erreur lors de l\'optimisation de l\'URL: $e');
      return url; // En cas d'erreur, retourner l'URL originale
    }
  }
  
  /// Supprimer une image de Cloudinary
  Future<bool> deleteImage(String url) async {
    try {
      final publicId = _extractPublicId(url);
      if (publicId == null) {
        logger.e('❌ Impossible d\'extraire le public_id de l\'URL: $url');
        return false;
      }
      
      // Générer le timestamp et la signature
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signature = _generateSignature({
        'public_id': publicId,
        'timestamp': timestamp.toString(),
      });
      
      // Construire la requête
      final response = await http.post(
        Uri.parse(
          'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/destroy'
        ),
        body: {
          'public_id': publicId,
          'timestamp': timestamp.toString(),
          'signature': signature,
          'api_key': CloudinaryConfig.apiKey,
        },
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['result'] == 'ok') {
          logger.i('✅ Image supprimée avec succès: $publicId');
          return true;
        } else {
          logger.e('❌ Erreur lors de la suppression: ${jsonData['result']}');
          return false;
        }
      } else {
        logger.e('❌ Erreur HTTP: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      logger.e('❌ Exception lors de la suppression: $e');
      return false;
    }
  }
  
  /// Extraire le public_id d'une URL Cloudinary
  String? _extractPublicId(String url) {
    try {
      // Format: https://res.cloudinary.com/djeares5m/image/upload/v1234567890/chapechape/residences/image.jpg
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      // Trouver l'index de "upload"
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) return null;
      
      // Ignorer le segment de version qui commence par 'v'
      int startIndex = uploadIndex + 1;
      if (startIndex < pathSegments.length && pathSegments[startIndex].startsWith('v')) {
        startIndex++;
      }
      
      // Construire le public_id
      if (startIndex < pathSegments.length) {
        final segments = pathSegments.sublist(startIndex);
        final fileName = segments.last;
        final extension = path.extension(fileName);
        
        // Retirer l'extension du dernier segment
        segments[segments.length - 1] = fileName.substring(0, fileName.length - extension.length);
        
        return segments.join('/');
      }
      
      return null;
    } catch (e) {
      logger.e('❌ Erreur lors de l\'extraction du public_id: $e');
      return null;
    }
  }
  
  /// Générer une signature pour les requêtes Cloudinary
  String _generateSignature(Map<String, String> params) {
    // Trier les paramètres par clé
    final sortedKeys = params.keys.toList()..sort();
    
    // Construire la chaîne à signer
    String toSign = '';
    for (final key in sortedKeys) {
      toSign += '$key=${params[key]}&';
    }
    
    // Ajouter la clé secrète
    toSign = toSign.substring(0, toSign.length - 1) + CloudinaryConfig.apiSecret;
    
    // Calculer le hash SHA-1
    final bytes = utf8.encode(toSign);
    final digest = sha1.convert(bytes);
    
    return digest.toString();
  }
}
