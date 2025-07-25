import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;
import '../../utils/error_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../media/cloudinary_service.dart';
import '../../config/feature_flags.dart';
import '../../config/app_config_manager.dart';

class MediaService {
  final Dio _dio;

  MediaService(Dio? dio) : _dio = dio ?? Dio(BaseOptions(
    baseUrl: AppConfigManager.apiUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));
  
  /// S'assure que l'URL de base est disponible, sinon utilise l'URL par défaut
  String get _baseUrl {
    if (_dio.options.baseUrl.isEmpty) {
      // URL de base non configurée, utiliser l'URL du serveur local de développement
      final String url = 'http://192.168.1.70:4000/api';
      print('⚠️ URL de base non configurée, utilisation de l\'URL de développement locale: $url');
      return url;
    }
    return _dio.options.baseUrl;
  }


  /// Télécharge une photo de profil avec support Cloudinary
  Future<String> uploadProfilePicture(dynamic imageFile) async {
    try {
      print('⬆️ Démarrage de l\'upload de la photo de profil');
      print('🌐 Environnement: ${kIsWeb ? 'Web' : 'Mobile'}');
      print('☁️ Mode Cloudinary: ${FeatureFlags.useCloudinary ? 'Activé' : 'Désactivé'}');
      
      // Si Cloudinary est activé, utiliser l'upload direct
      if (FeatureFlags.useCloudinary) {
        try {
          print('☁️ Utilisation de Cloudinary pour l\'upload de la photo de profil');
          
          // Initialiser le service Cloudinary
          final cloudinaryService = CloudinaryService();
          
          // Upload vers Cloudinary
          final String cloudinaryUrl = await cloudinaryService.uploadImage(
            imageFile,
            folder: 'chapechape/profiles',
          );
          
          print('☁️ Image uploadée sur Cloudinary: $cloudinaryUrl');
          
          // Mettre à jour le profil avec l'URL Cloudinary
          print('🔍 URL de base Dio: ${_dio.options.baseUrl}');
          
          // S'assurer que l'URL est complète avec l'URL de base
          final completeUrl = '$_baseUrl/partners/profile';
          print('🔍 URL complète API: $completeUrl');
          
          final profileResponse = await _dio.put(
            completeUrl, // Utiliser l'URL complète avec hôte
            data: {
              'profileImage': cloudinaryUrl,
            },
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                'Authorization': await _getAuthHeader(),
              },
            ),
          );
          
          print('📥 Réponse reçue: ${profileResponse.statusCode}');
          
          if (profileResponse.statusCode == 200) {
            final data = profileResponse.data;
            if (data['success'] == true) {
              print('✅ Profil mis à jour avec succès via Cloudinary');
              return cloudinaryUrl;
            } else {
              print('❌ Erreur retournée par le serveur: ${data['message']}');
              throw Exception(data['message'] ?? 'Erreur lors de la mise à jour du profil');
            }
          } else {
            throw Exception('Erreur lors de la mise à jour du profil: ${profileResponse.statusCode}');
          }
        } catch (cloudinaryError) {
          print('☁️❌ Erreur Cloudinary: $cloudinaryError');
          print('🔄 Retour à la méthode traditionnelle d\'upload');
          // En cas d'erreur avec Cloudinary, revenir à la méthode traditionnelle
        }
      }
      
      // Méthode traditionnelle (multipart/form-data)
      FormData formData;

      if (imageFile is File) {
        // Mobile
        final fileName = path.basename(imageFile.path);
        final extension = path.extension(fileName).toLowerCase().replaceAll('.', '');
        print('📱 Mobile: Préparation de l\'image $fileName (.$extension)');
        
        formData = FormData.fromMap({
          'profileImage': await MultipartFile.fromFile(
            imageFile.path,
            filename: fileName,
            contentType: MediaType('image', extension),
          ),
        });
      } else if (imageFile is Uint8List && kIsWeb) {
        // Web
        print('🖥️ Web: Préparation de l\'image en bytes (${imageFile.length} bytes)');
        
        formData = FormData.fromMap({
          'profileImage': MultipartFile.fromBytes(
            imageFile,
            filename: 'profile_picture.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        });
      } else {
        print('❌ Format non supporté: ${imageFile.runtimeType}');
        throw Exception('Format de fichier non pris en charge');
      }

      // Utiliser l'URL dynamique à partir du gestionnaire de configuration
      final String url = '$_baseUrl/partners/profile';
      print('📤 Envoi vers: $url');
      
      try {
        final response = await _dio.put(
          url, // Utiliser l'URL complète avec hôte
          data: formData,
          options: Options(
            headers: {
              'Content-Type': 'multipart/form-data',
              'Authorization': await _getAuthHeader(),
            },
          ),
        );
        
        print('📥 Réponse reçue: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final data = response.data;
          print('📈 Données reçues: $data');

          if (data['success'] == true) {
            print('✅ Profil mis à jour avec succès');
            // Retourner l'URL de l'image si disponible
            String imageUrl = '';
            if (data['data'] != null && data['data']['profilePictureUrl'] != null) {
              imageUrl = data['data']['profilePictureUrl'];
            } else if (data['data'] != null && data['data']['profileImage'] != null) {
              imageUrl = data['data']['profileImage'];
            }
            
            // S'assurer que l'URL est complète
            if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
              imageUrl = _buildCompleteUrl(imageUrl);
            }
            
            print('🖼️ URL d\'image finale: $imageUrl');
            return imageUrl;
          } else {
            print('❌ Erreur retournée par le serveur: ${data['message']}');
            throw Exception(data['message'] ?? 'Erreur lors du téléchargement de l\'image');
          }
        } else {
          print('❌ Mauvais code de statut: ${response.statusCode}');
          throw Exception(response.data['message'] ?? 'Erreur lors du téléchargement de l\'image');
        }
      } catch (dioError) {
        print('❌ Erreur Dio lors de l\'upload: $dioError');
        throw ErrorHandler.handleError(dioError);
      }
    } catch (e) {
      print('❌ Erreur lors du téléchargement de la photo de profil: $e');
      throw ErrorHandler.handleError(e);
    }
  }
  
  // Méthode utilitaire pour construire une URL complète
  String _buildCompleteUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    
    // Vérifier les URLs problématiques
    if (url.contains('images-')) {
      // Corriger le format en remplaçant 'images-' par 'profile-'
      String correctedUrl = url.replaceAll('images-', 'profile-');
      
      // S'assurer que le chemin pointe vers le bon répertoire
      if (!correctedUrl.contains('/profiles/')) {
        correctedUrl = correctedUrl.replaceAll('/uploads/', '/uploads/profiles/');
        correctedUrl = correctedUrl.replaceAll('uploads/', '/uploads/profiles/');
      }
      
      // S'assurer que le chemin commence par un slash
      if (!correctedUrl.startsWith('/')) {
        correctedUrl = '/$correctedUrl';
      }
      
      print('⚠️ URL corrigée: $url -> $correctedUrl');
      url = correctedUrl;
    }
    
    // S'assurer que les images de profil sont dans le bon dossier
    if (url.contains('profile-') && !url.contains('/profiles/')) {
      url = url.replaceAll('/uploads/', '/uploads/profiles/');
      url = url.replaceAll('uploads/', '/uploads/profiles/');
      if (!url.startsWith('/')) {
        url = '/$url';
      }
    }
    
    final baseUrl = _dio.options.baseUrl.replaceAll('/api', '');
    if (url.startsWith('/')) {
      return '$baseUrl$url';
    } else {
      return '$baseUrl/$url';
    }
  }

  /// Obtient le header d'authentification
  Future<String> _getAuthHeader() async {
    try {
      // Récupérer le token d'authentification (même clé que dans AuthService)
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      
      if (token != null) {
        print('🔑 Token d\'authentification trouvé');
        return 'Bearer $token';
      }
      
      print('⚠️ Aucun token d\'authentification trouvé');
      return '';
    } catch (e) {
      print('❌ Erreur lors de la récupération du token: $e');
      return '';
    }
  }

  /// Télécharge un document d'identité
  Future<String> uploadDocument(String type, dynamic documentFile) async {
    try {
      FormData formData;

      if (documentFile is File) {
        // Mobile
        final fileName = path.basename(documentFile.path);
        final extension = path.extension(fileName).toLowerCase().replaceAll('.', '');
        formData = FormData.fromMap({
          'documentType': type,
          'document': await MultipartFile.fromFile(
            documentFile.path,
            filename: fileName,
            contentType: _getContentType(extension),
          ),
        });
      } else if (documentFile is Uint8List && kIsWeb) {
        // Web
        formData = FormData.fromMap({
          'documentType': type,
          'document': MultipartFile.fromBytes(
            documentFile,
            filename: 'document.$type',
            contentType: _getContentType(type),
          ),
        });
      } else {
        throw Exception('Format de fichier non pris en charge');
      }

      final response = await _dio.post(
        '/partners/upload/document',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final String documentUrl = data['data']['url'];
          return documentUrl;
        } else {
          throw Exception(data['message'] ?? 'Erreur lors du téléchargement du document');
        }
      } else {
        throw Exception(response.data['message'] ?? 'Erreur lors du téléchargement du document');
      }
    } catch (e) {
      print('Erreur lors du téléchargement du document: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  /// Retourne le type de contenu en fonction de l'extension
  MediaType _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'pdf':
        return MediaType('application', 'pdf');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
} 