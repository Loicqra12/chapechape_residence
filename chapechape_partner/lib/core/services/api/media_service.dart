import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;
import '../../utils/error_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MediaService {
  final Dio _dio;

  MediaService(this._dio);

  /// Télécharge une photo de profil
  Future<String> uploadProfilePicture(dynamic imageFile) async {
    try {
      print('⬆️ Démarrage de l\'upload de la photo de profil');
      print('🌐 Environnement: ${kIsWeb ? 'Web' : 'Mobile'}');
      
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

      // Utiliser l'URL complète au lieu du chemin relatif
      const String url = 'http://localhost:4000/api/partners/profile';
      print('📤 Envoi vers: $url');
      
      final response = await Dio().put(
        url,
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
        print('📊 Données reçues: $data');
        
        if (data['success'] == true) {
          print('✅ Profil mis à jour avec succès');
          // Retourner l'URL de l'image si disponible
          if (data['data'] != null && data['data']['profileImage'] != null) {
            return data['data']['profileImage'];
          }
          return '';
        } else {
          print('❌ Erreur retournée par le serveur: ${data['message']}');
          throw Exception(data['message'] ?? 'Erreur lors du téléchargement de l\'image');
        }
      } else {
        print('❌ Mauvais code de statut: ${response.statusCode}');
        throw Exception(response.data['message'] ?? 'Erreur lors du téléchargement de l\'image');
      }
    } catch (e) {
      print('❌ Erreur lors du téléchargement de la photo de profil: $e');
      throw ErrorHandler.handleError(e);
    }
  }
  
  /// Obtient le header d'authentification
  Future<String> _getAuthHeader() async {
    try {
      // Créer un Dio séparé pour obtenir le token
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      if (token != null) {
        return 'Bearer $token';
      }
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