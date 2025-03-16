import 'package:dio/dio.dart';

abstract class ApiService {
  final Dio dio;

  ApiService(this.dio);

  Exception handleError(dynamic error) {
    if (error is DioException) {
      final response = error.response;
      if (response != null) {
        final data = response.data;
        if (data != null && data['message'] != null) {
          return Exception(data['message']);
        }
      }
      return Exception(error.message);
    }
    return Exception('Une erreur est survenue');
  }
}
