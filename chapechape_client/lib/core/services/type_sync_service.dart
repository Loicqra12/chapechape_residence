import 'package:shared_preferences/shared_preferences.dart';
import '../models/residence_type_enum.dart';
import 'api_service.dart';
import 'logger_service.dart';

class TypeSyncService {
  final ApiService apiService;
  final LoggerService logger;
  
  TypeSyncService({
    required this.apiService,
    required this.logger,
  });
  
  // Méthode d'initialisation similaire aux autres services
  static Future<TypeSyncService> initialize() async {
    final apiService = await ApiService.initialize();
    final logger = LoggerService();
    
    return TypeSyncService(
      apiService: apiService,
      logger: logger,
    );
  }
  
  Future<String> frontendToBackendType(ResidenceType type) async {
    logger.debug('Conversion type frontend vers backend: ${type.name}');
    return type.typeCode;
  }
  
  Future<ResidenceType> backendToFrontendType(String backendType) async {
    logger.debug('Conversion type backend vers frontend: $backendType');
    return ResidenceType.values.firstWhere(
      (type) => type.typeCode == backendType,
      orElse: () => ResidenceType.other,
    );
  }
} 