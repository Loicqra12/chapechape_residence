import 'package:dio/dio.dart';
import 'package:chapechape_client/core/models/user_model.dart';
import 'package:chapechape_client/core/services/api_service.dart';

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
  Future<String> uploadProfilePicture(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'profilePicture': await MultipartFile.fromFile(filePath),
      });

      final response = await _apiService.post(
        '/auth/profile/picture',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return response.data['profilePicture'];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Récupérer l'historique des réservations
  Future<List<dynamic>> getBookingHistory() async {
    try {
      final response = await _apiService.get('/bookings/user');
      return response.data;
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
