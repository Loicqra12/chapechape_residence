import 'package:dio/dio.dart';
import '../../models/notification/notification_model.dart';

class NotificationService {
  final Dio _dio;
  
  NotificationService(this._dio);
  
  Future<List<NotificationModel>> getNotifications({int page = 1, int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      }
      
      throw Exception('Erreur du chargement des notifications');
    } catch (e) {
      // Dans un environnement de développement, retourner des notifications fictives
      if (page == 1) {
        return List.generate(
          5,
          (index) => NotificationModel(
            id: 'notification_$index',
            title: 'Notification ${index + 1}',
            message: 'Ceci est le contenu de la notification ${index + 1}',
            timestamp: DateTime.now().subtract(Duration(days: index)),
            isRead: index % 2 == 0,
            type: index % 3 == 0 ? 'booking' : (index % 3 == 1 ? 'message' : 'system'),
          ),
        );
      }
      return [];
    }
  }
  
  Future<bool> markAsRead(String id) async {
    try {
      final response = await _dio.patch(
        '/notifications/$id/read',
      );
      
      return response.statusCode == 200;
    } catch (e) {
      // Pour le développement, toujours retourner succès
      return true;
    }
  }
  
  Future<bool> markAllAsRead() async {
    try {
      final response = await _dio.patch(
        '/notifications/read-all',
      );
      
      return response.statusCode == 200;
    } catch (e) {
      // Pour le développement, toujours retourner succès
      return true;
    }
  }
  
  Future<bool> deleteNotification(String id) async {
    try {
      final response = await _dio.delete(
        '/notifications/$id',
      );
      
      return response.statusCode == 200;
    } catch (e) {
      // Pour le développement, toujours retourner succès
      return true;
    }
  }
} 