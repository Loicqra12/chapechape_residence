import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart' as http_parser;
import '../models/user_model.dart';
import './api_service.dart';
import '../config/feature_flags.dart';
import './media/cloudinary_service.dart';

class UserService {
  final ApiService _apiService;

  UserService._({
    required ApiService apiService,
  }) : _apiService = apiService;

  static Future<UserService> initialize() async {
    final apiService = await ApiService.initialize();
    return UserService._(apiService: apiService);
  }

  // Récupérer le profil de l'utilisateur
  Future<User> getUserProfile() async {
    try {
      final response = await _apiService.get('/auth/me');
      if (response.data['success'] == true && response.data['user'] != null) {
        return User.fromJson(response.data['user']);
      }
      throw Exception('Erreur lors de la récupération du profil');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Mettre à jour le profil utilisateur
  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profilePicture,
  }) async {
    try {
      final response = await _apiService.put('/auth/profile', data: {
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (profilePicture != null) 'profilePicture': profilePicture,
      });

      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Changer le mot de passe
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiService.put('/auth/password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Télécharger une photo de profil
  /// Upload une photo de profil avec support Cloudinary
  Future<String> uploadProfilePicture(String filePath) async {
    try {
      print('⬆️ Démarrage de l\'upload de la photo de profil');
      print('🌐 Mode Cloudinary: ${FeatureFlags.useCloudinary ? 'Activé' : 'Désactivé'}');
      
      // Si Cloudinary est activé, utiliser l'upload direct
      if (FeatureFlags.useCloudinary) {
        try {
          print('☁️ Utilisation de Cloudinary pour l\'upload de la photo de profil');
          
          // Initialiser le service Cloudinary
          final cloudinaryService = CloudinaryService();
          
          // Upload vers Cloudinary
          final String cloudinaryUrl = await cloudinaryService.uploadImage(
            filePath,
            folder: 'chapechape/profiles',
          );
          
          print('☁️ Image uploadée sur Cloudinary: $cloudinaryUrl');
          
          // Mettre à jour le profil avec l'URL Cloudinary
          final profileResponse = await _apiService.post(
            '/auth/profile/picture',
            data: {
              'profilePictureUrl': cloudinaryUrl,
            },
            options: Options(
              headers: {
                'Content-Type': 'application/json',
              },
            ),
          );
          
          print('📥 Réponse reçue: ${profileResponse.statusCode}');
          
          // Si le backend renvoie une URL, l'utiliser, sinon utiliser l'URL Cloudinary
          final profileUrl = profileResponse.data['profilePicture'] ?? cloudinaryUrl;
          print('🖼️ URL finale de l\'image de profil: $profileUrl');
          
          return profileUrl;
        } catch (cloudinaryError) {
          print('☁️❌ Erreur Cloudinary: $cloudinaryError');
          print('🔄 Retour à la méthode traditionnelle d\'upload');
          // En cas d'erreur avec Cloudinary, revenir à la méthode traditionnelle
        }
      }
      
      // Méthode traditionnelle (multipart/form-data)
      print('📦 Utilisation de la méthode traditionnelle d\'upload');
      
      // Créer une fonction pour générer FormData fraîche à chaque tentative
      FormData createFormData() {
        // Déterminer le type MIME basé sur l'extension du fichier
        String? mimeType;
        final extension = filePath.toLowerCase().split('.').last;
        switch (extension) {
          case 'jpg':
          case 'jpeg':
            mimeType = 'image/jpeg';
            break;
          case 'png':
            mimeType = 'image/png';
            break;
          case 'gif':
            mimeType = 'image/gif';
            break;
          case 'webp':
            mimeType = 'image/webp';
            break;
          default:
            mimeType = 'image/jpeg'; // Fallback
        }
        
        return FormData.fromMap({
          'profilePicture': MultipartFile.fromFileSync(
            filePath,
            contentType: http_parser.MediaType.parse(mimeType),
          ),
        });
      };

      final response = await _apiService.post(
        '/auth/profile/picture',
        data: createFormData(), // Utiliser une fonction pour créer FormData fraîche
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      // Extraire l'URL de la réponse selon la structure de l'API
      final responseData = response.data['data'];
      final profileUrl = responseData['profilePictureUrl'] ?? responseData['profileImage'];
      print('🖼️ URL finale de l\'image de profil (méthode traditionnelle): $profileUrl');
      
      if (profileUrl == null) {
        throw Exception('URL de l\'image de profil non trouvée dans la réponse');
      }
      
      return profileUrl;
    } on DioException catch (e) {
      print('❌ Erreur DIO lors de l\'upload: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      print('❌ Erreur inattendue lors de l\'upload: $e');
      throw Exception('Erreur lors de l\'upload de la photo de profil: $e');
    }
  }

  // Récupérer l'historique des réservations
  Future<List<dynamic>> getBookingHistory() async {
    try {
      final response = await _apiService.get('reservations/my-reservations');
      return response.data['data'];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Récupérer les résidences favorites
  Future<List<dynamic>> getFavoriteResidences() async {
    try {
      final response = await _apiService.get('/favorites');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Gérer les erreurs Dio
  Exception _handleDioError(DioException e) {
    switch (e.response?.statusCode) {
      case 400:
        return Exception(e.response?.data['message'] ?? 'Requête invalide');
      case 401:
        return Exception('Non autorisé');
      case 404:
        return Exception('Ressource non trouvée');
      case 422:
        return Exception('Données invalides');
      case 500:
        return Exception('Erreur serveur');
      default:
        return Exception('Une erreur est survenue');
    }
  }
}
