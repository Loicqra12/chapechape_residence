import '../../models/calendar/partner_calendar.dart';
import 'api_service.dart';

class PartnerCalendarService {
  final ApiService _api;

  PartnerCalendarService(this._api);

  Future<PartnerCalendar> getPartnerCalendar({
    required String residenceId,
    required DateTime start,
    required DateTime end,
  }) async {
    final response = await _api.get(
      '/availability/calendar/partner',
      queryParameters: {
        'residenceId': residenceId,
        'startDate': start.toUtc().toIso8601String(),
        'endDate': end.toUtc().toIso8601String(),
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return PartnerCalendar.fromJson(data);
  }

  Future<Map<String, dynamic>> createBlock({
    required String residenceId,
    required DateTime start,
    required DateTime end,
    String bookingType = 'day',
    String type = 'other',
    String reason = '',
  }) async {
    final response = await _api.post('/availability/blocks', data: {
      'residenceId': residenceId,
      'startDate': start.toUtc().toIso8601String(),
      'endDate': end.toUtc().toIso8601String(),
      'bookingType': bookingType,
      'type': type,
      'reason': reason,
    });
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  Future<void> releaseBlock(String blockId) async {
    await _api.delete('/availability/blocks/$blockId');
  }

  Future<Map<String, dynamic>> createExternal({
    required String residenceId,
    required DateTime checkIn,
    required DateTime checkOut,
    String bookingType = 'day',
    String channel = 'other',
    String guestName = '',
    String guestPhone = '',
    String notes = '',
    String externalReference = '',
  }) async {
    final response = await _api.post('/availability/external', data: {
      'residenceId': residenceId,
      'checkIn': checkIn.toUtc().toIso8601String(),
      'checkOut': checkOut.toUtc().toIso8601String(),
      'bookingType': bookingType,
      'channel': channel,
      'guestName': guestName,
      'guestPhone': guestPhone,
      'notes': notes,
      'externalReference': externalReference,
    });
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  Future<void> updateExternal({
    required String id,
    DateTime? checkIn,
    DateTime? checkOut,
    String? channel,
    String? guestName,
    String? guestPhone,
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    if (checkIn != null) body['checkIn'] = checkIn.toUtc().toIso8601String();
    if (checkOut != null) body['checkOut'] = checkOut.toUtc().toIso8601String();
    if (channel != null) body['channel'] = channel;
    if (guestName != null) body['guestName'] = guestName;
    if (guestPhone != null) body['guestPhone'] = guestPhone;
    if (notes != null) body['notes'] = notes;
    await _api.patch('/availability/external/$id', data: body);
  }

  Future<void> cancelExternal(String id) async {
    await _api.delete('/availability/external/$id');
  }

  Future<void> completeExternal(String id) async {
    await _api.post('/availability/external/$id/complete');
  }
}
