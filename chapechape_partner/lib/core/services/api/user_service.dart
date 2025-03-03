import 'package:dio/dio.dart';
import '../../models/user/user.dart';
import 'api_service.dart';

class UserService {
  final ApiService _apiService;

  UserService(this._apiService);

  Future<User> getUserById(String userId) async {
    try {
      final response = await _apiService.dio.get('/users/$userId');
      return User.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<User>> getContacts() async {
    try {
      final response = await _apiService.dio.get('/users/contacts');
      final List<dynamic> data = response.data['contacts'];
      return data.map((json) => User.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> updateLastSeen() async {
    try {
      await _apiService.dio.post('/users/lastseen');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      await _apiService.dio.post(
        '/users/status',
        data: {'isOnline': isOnline},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.response?.statusCode == 404) {
      return Exception('Utilisateur non trouvé');
    } else if (e.response?.statusCode == 403) {
      return Exception('Accès non autorisé');
    }
    return Exception('Une erreur est survenue: ${e.message}');
  }
}
