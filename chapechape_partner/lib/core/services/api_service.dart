import 'package:dio/dio.dart';
import '../models/api/api_error.dart';

abstract class ApiService {
  final Dio dio;

  ApiService(this.dio);

  Exception handleError(dynamic error) {
    if (error is DioException) {
      return ApiError.fromDioError(error);
    } else if (error is ApiError) {
      return error;
    }
    return ApiError.generic(message: error?.toString() ?? 'Une erreur inconnue est survenue');
  }
}
