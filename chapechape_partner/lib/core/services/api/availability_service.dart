import '../../models/availability/availability_model.dart';
import 'api_service.dart';

class AvailabilityService {
  final ApiService _apiService;

  AvailabilityService(this._apiService);

  // Récupérer les disponibilités d'une résidence
  Future<List<Availability>> getAvailabilities(String residenceId) async {
    try {
      final response = await _apiService.get('/residences/$residenceId/availabilities');
      final List<dynamic> data = response.data['availabilities'];
      return data.map((json) => Availability.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Créer une nouvelle disponibilité
  Future<Availability> createAvailability(String residenceId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(
        '/residences/$residenceId/availabilities',
        data: data,
      );
      return Availability.fromJson(response.data['availability']);
    } catch (e) {
      rethrow;
    }
  }

  // Mettre à jour une disponibilité
  Future<Availability> updateAvailability(
    String residenceId,
    String availabilityId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.put(
        '/residences/$residenceId/availabilities/$availabilityId',
        data: data,
      );
      return Availability.fromJson(response.data['availability']);
    } catch (e) {
      rethrow;
    }
  }

  // Supprimer une disponibilité
  Future<void> deleteAvailability(String residenceId, String availabilityId) async {
    try {
      await _apiService.delete(
        '/residences/$residenceId/availabilities/$availabilityId',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Mettre à jour le statut d'une disponibilité
  Future<Availability> updateAvailabilityStatus(
    String residenceId,
    String availabilityId,
    AvailabilityStatus status,
  ) async {
    try {
      final response = await _apiService.patch(
        '/residences/$residenceId/availabilities/$availabilityId/status',
        data: {'status': status.toString().split('.').last},
      );
      return Availability.fromJson(response.data['availability']);
    } catch (e) {
      rethrow;
    }
  }

  // Mettre à jour le prix d'une disponibilité
  Future<Availability> updateAvailabilityPrice(
    String residenceId,
    String availabilityId,
    double price,
  ) async {
    try {
      final response = await _apiService.patch(
        '/residences/$residenceId/availabilities/$availabilityId/price',
        data: {'price': price},
      );
      return Availability.fromJson(response.data['availability']);
    } catch (e) {
      rethrow;
    }
  }

  // Créer plusieurs disponibilités en même temps
  Future<List<Availability>> createBulkAvailabilities(
    String residenceId,
    List<Map<String, dynamic>> availabilities,
  ) async {
    try {
      final response = await _apiService.post(
        '/residences/$residenceId/availabilities/bulk',
        data: {'availabilities': availabilities},
      );
      final List<dynamic> data = response.data['availabilities'];
      return data.map((json) => Availability.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
