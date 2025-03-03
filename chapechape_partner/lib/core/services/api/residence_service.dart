import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/residence/residence.dart';
import '../../models/residence/residence_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';

class ResidenceService {
  final String baseUrl;
  final http.Client client;
  final FlutterSecureStorage storage;

  ResidenceService({
    required this.baseUrl,
    http.Client? client,
    FlutterSecureStorage? storage,
  }) : client = client ?? http.Client(),
       storage = storage ?? const FlutterSecureStorage();

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await storage.read(key: 'token');
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'contentType': 'application/json',
      'responseType': 'ResponseType.json',
      'followRedirects': 'true',
      'connectTimeout': '0:00:30.000000',
      'receiveTimeout': '0:00:30.000000',
    };
  }

  Future<List<Residence>> getResidences() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await client.get(
        Uri.parse('$baseUrl/residences'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> residences = responseData['data'];
          return residences.map((json) {
            // Convertir les amenities en propriétés booléennes
            final amenities = (json['amenities'] as List<dynamic>?)?.cast<String>() ?? [];
            json['hasWifi'] = amenities.contains('wifi');
            json['hasPool'] = amenities.contains('pool');
            
            // Ajouter d'autres propriétés nécessaires
            json['isAvailable'] = json['status'] == 'available';
            json['surface'] = json['area'];
            json['name'] = json['title'];
            
            return Residence.fromJson(json);
          }).toList();
        }
      }
      throw Exception('Failed to load residences: ${response.body}');
    } catch (e) {
      throw Exception('Failed to load residences: $e');
    }
  }

  Future<Residence> createResidence(Map<String, dynamic> data, List<ResidenceImage> images) async {
    final token = await storage.read(key: 'token');
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/residences'));
    
    // Ajouter le token d'authentification
    request.headers['Authorization'] = 'Bearer $token';
    
    // Adapter les données au format du backend
    final adaptedData = {
      'title': data['name'],
      'description': data['description'],
      'price': data['price'],
      'type': data['type'],
      'status': data['isAvailable'] ? 'available' : 'unavailable',
      
      // Champs requis directement à la racine
      'address': data['location']?['address'] ?? data['address'] ?? '',
      'city': data['location']?['city'] ?? data['city'] ?? '',
      'latitude': data['location']?['coordinates']?[0] ?? 0,
      'longitude': data['location']?['coordinates']?[1] ?? 0,
      
      // Features comme propriétés directes
      'bedrooms': data['features']?['bedrooms'] ?? data['bedrooms'] ?? 1,
      'bathrooms': data['features']?['bathrooms'] ?? data['bathrooms'] ?? 1,
      'area': data['features']?['area'] ?? data['surface'] ?? 0,
      'isFurnished': data['features']?['furnished'] ?? data['isFurnished'] ?? false,
      
      // Rules comme objet
      'rules': {
        'smoking': data['rules']?['smoking'] ?? data['allowsSmoking'] ?? false,
        'pets': data['rules']?['pets'] ?? data['allowsPets'] ?? false,
        'parties': data['rules']?['parties'] ?? data['allowsParties'] ?? false,
        'maxGuests': data['rules']?['maxGuests'] ?? data['maxGuests'] ?? 2,
      },
      
      // Amenities comme liste
      'amenities': [
        if (data['features']?['wifi'] ?? data['hasWifi'] ?? false) 'wifi',
        if (data['features']?['pool'] ?? data['hasPool'] ?? false) 'pool',
        if (data['features']?['airConditioned'] ?? false) 'air_conditioning',
        if (data['features']?['parking'] ?? false) 'parking',
        if (data['features']?['security'] ?? false) 'security',
      ],
    };
    
    // Ajouter les données adaptées à la requête
    adaptedData.forEach((key, value) {
      if (value != null) {
        if (value is List || value is Map) {
          request.fields[key] = json.encode(value);
        } else {
          request.fields[key] = value.toString();
        }
      }
    });

    // Ajouter les images
    for (var i = 0; i < images.length; i++) {
      final image = images[i];
      if (image.isWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'images',
            image.webImage!,
            filename: 'image_$i.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            image.file!.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      if (responseData['success'] == true && responseData['data'] != null) {
        return Residence.fromJson(responseData['data']);
      }
    }
    throw Exception('Failed to create residence: ${response.body}');
  }

  Future<Residence> getResidenceById(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await client.get(
        Uri.parse('$baseUrl/residences/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final json = responseData['data'];
          
          // Convertir les amenities en propriétés booléennes
          final amenities = (json['amenities'] as List<dynamic>?)?.cast<String>() ?? [];
          json['hasWifi'] = amenities.contains('wifi');
          json['hasPool'] = amenities.contains('pool');
          
          // Ajouter d'autres propriétés nécessaires
          json['isAvailable'] = json['status'] == 'available';
          json['surface'] = json['area'];
          json['name'] = json['title'];
          
          // Ajouter les propriétés du partenaire si présentes
          if (json['partner'] != null) {
            json['partnerInfo'] = {
              'id': json['partner']['_id'],
              'name': '${json['partner']['firstName']} ${json['partner']['lastName']}',
              'email': json['partner']['email'],
              'phoneNumber': json['partner']['phoneNumber'],
            };
          }
          
          // Ajouter les règles si présentes
          if (json['rules'] != null) {
            json['maxGuests'] = json['rules']['maxGuests'];
            json['allowsSmoking'] = json['rules']['smoking'];
            json['allowsPets'] = json['rules']['pets'];
            json['allowsParties'] = json['rules']['parties'];
          }
          
          return Residence.fromJson(json);
        }
      }
      throw Exception('Failed to load residence: ${response.body}');
    } catch (e) {
      throw Exception('Failed to load residence: $e');
    }
  }

  Future<void> updateResidence(String id, Map<String, dynamic> data) async {
    final headers = await _getAuthHeaders();
    
    // Adapter les données au format du backend
    final adaptedData = {
      'title': data['name'],
      'description': data['description'],
      'price': data['price'],
      'type': data['type'],
      'status': data['isAvailable'] ? 'available' : 'unavailable',
      
      // Champs requis directement à la racine
      'address': data['location']?['address'] ?? data['address'] ?? '',
      'city': data['location']?['city'] ?? data['city'] ?? '',
      'latitude': data['location']?['coordinates']?[0] ?? 0,
      'longitude': data['location']?['coordinates']?[1] ?? 0,
      
      // Features comme propriétés directes
      'bedrooms': data['features']?['bedrooms'] ?? data['bedrooms'] ?? 1,
      'bathrooms': data['features']?['bathrooms'] ?? data['bathrooms'] ?? 1,
      'area': data['features']?['area'] ?? data['surface'] ?? 0,
      'isFurnished': data['features']?['furnished'] ?? data['isFurnished'] ?? false,
      
      // Rules comme objet
      'rules': {
        'smoking': data['rules']?['smoking'] ?? data['allowsSmoking'] ?? false,
        'pets': data['rules']?['pets'] ?? data['allowsPets'] ?? false,
        'parties': data['rules']?['parties'] ?? data['allowsParties'] ?? false,
        'maxGuests': data['rules']?['maxGuests'] ?? data['maxGuests'] ?? 2,
      },
      
      // Amenities comme liste
      'amenities': [
        if (data['features']?['wifi'] ?? data['hasWifi'] ?? false) 'wifi',
        if (data['features']?['pool'] ?? data['hasPool'] ?? false) 'pool',
        if (data['features']?['airConditioned'] ?? false) 'air_conditioning',
        if (data['features']?['parking'] ?? false) 'parking',
        if (data['features']?['security'] ?? false) 'security',
      ],
    };

    headers['Content-Type'] = 'application/json';
    
    final response = await client.put(
      Uri.parse('$baseUrl/residences/$id'),
      headers: headers,
      body: json.encode(adaptedData),
    );

    if (response.statusCode != 200) {
      final responseData = json.decode(response.body);
      throw Exception('Failed to update residence: ${responseData['message'] ?? response.body}');
    }
  }

  Future<void> uploadResidenceImages(String residenceId, List<ResidenceImage> images) async {
    final token = await storage.read(key: 'token');
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/residences/$residenceId/images'),
    );

    // Ajouter tous les headers nécessaires
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      'contentType': 'application/json',
      'responseType': 'ResponseType.json',
      'followRedirects': 'true',
      'connectTimeout': '0:00:30.000000',
      'receiveTimeout': '0:00:30.000000',
    });

    for (var i = 0; i < images.length; i++) {
      final image = images[i];
      if (image.isWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'images',
            image.webImage!,
            filename: 'image_$i.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            image.file!.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode != 200) {
      final responseData = json.decode(response.body);
      throw Exception('Failed to upload images: ${responseData['message'] ?? response.body}');
    }
  }

  Future<void> deleteResidence(String id) async {
    final headers = await _getAuthHeaders();
    final response = await client.delete(
      Uri.parse('$baseUrl/residences/$id'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete residence');
    }
  }

  Future<Map<String, dynamic>> searchResidences({
    String? city,
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
    int? bathrooms,
    String? type,
    bool? isFurnished,
    List<String>? amenities,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      
      // Construire l'URL avec les paramètres de recherche
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (city != null) queryParams['city'] = city;
      if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
      if (bedrooms != null) queryParams['bedrooms'] = bedrooms.toString();
      if (bathrooms != null) queryParams['bathrooms'] = bathrooms.toString();
      if (type != null) queryParams['type'] = type;
      if (isFurnished != null) queryParams['isFurnished'] = isFurnished.toString();
      if (amenities != null && amenities.isNotEmpty) {
        queryParams['amenities'] = amenities.join(',');
      }

      final uri = Uri.parse('$baseUrl/residences/search').replace(queryParameters: queryParams);
      final response = await client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          // Convertir les résidences
          final residences = (responseData['data'] as List<dynamic>).map((json) {
            // Convertir les amenities en propriétés booléennes
            final amenities = (json['amenities'] as List<dynamic>?)?.cast<String>() ?? [];
            json['hasWifi'] = amenities.contains('wifi');
            json['hasPool'] = amenities.contains('pool');
            
            // Ajouter d'autres propriétés nécessaires
            json['isAvailable'] = json['status'] == 'available';
            json['surface'] = json['area'];
            json['name'] = json['title'];
            
            return Residence.fromJson(json);
          }).toList();

          // Retourner les résultats avec les informations de pagination
          return {
            'residences': residences,
            'pagination': responseData['pagination'],
            'total': responseData['total'],
            'count': responseData['count'],
          };
        }
      }
      throw Exception('Failed to search residences: ${response.body}');
    } catch (e) {
      throw Exception('Failed to search residences: $e');
    }
  }
}
