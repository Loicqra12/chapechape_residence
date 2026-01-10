import 'package:dio/dio.dart';
import '../models/residence/residence.dart';
import '../models/reservation/reservation.dart';
import '../models/message/conversation.dart';
import '../models/notification/notification_model.dart';

/// Service pour la recherche globale multi-entités
class GlobalSearchService {
  final Dio _dio;

  GlobalSearchService(this._dio);

  /// Effectue une recherche globale dans toutes les entités
  Future<GlobalSearchResults> search({
    required String query,
    List<SearchCategory>? categories,
    SearchFilters? filters,
    SearchSort sort = SearchSort.relevance,
  }) async {
    try {
      final response = await _dio.get(
        '/search/global',
        queryParameters: {
          'q': query,
          if (categories != null && categories.isNotEmpty)
            'categories': categories.map((c) => c.value).join(','),
          if (filters != null) ...filters.toQueryParameters(),
          'sort': sort.value,
        },
      );

      if (response.statusCode == 200) {
        return GlobalSearchResults.fromJson(response.data);
      }

      throw Exception('Erreur lors de la recherche');
    } catch (e) {
      // En mode développement, retourner des résultats factices
      return _getMockResults(query, categories ?? SearchCategory.values);
    }
  }

  /// Recherche uniquement dans les résidences
  Future<List<Residence>> searchResidences({
    required String query,
    ResidenceFilters? filters,
  }) async {
    try {
      final response = await _dio.get(
        '/residences/search',
        queryParameters: {
          'q': query,
          if (filters != null) ...filters.toQueryParameters(),
        },
      );

      if (response.statusCode == 200) {
        return (response.data['data'] as List)
            .map((json) => Residence.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      return _getMockResidences(query);
    }
  }

  /// Recherche uniquement dans les réservations
  Future<List<Reservation>> searchReservations({
    required String query,
    ReservationFilters? filters,
  }) async {
    try {
      final response = await _dio.get(
        '/reservations/search',
        queryParameters: {
          'q': query,
          if (filters != null) ...filters.toQueryParameters(),
        },
      );

      if (response.statusCode == 200) {
        return (response.data['data'] as List)
            .map((json) => Reservation.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Recherche uniquement dans les messages
  Future<List<Conversation>> searchConversations({
    required String query,
  }) async {
    try {
      final response = await _dio.get(
        '/messages/search',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        return (response.data['data'] as List)
            .map((json) => Conversation.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Résultats factices pour développement
  GlobalSearchResults _getMockResults(String query, List<SearchCategory> categories) {
    final results = GlobalSearchResults(
      query: query,
      residences: categories.contains(SearchCategory.residences) 
          ? _getMockResidences(query) 
          : [],
      reservations: categories.contains(SearchCategory.reservations) 
          ? []
          : [],
      conversations: categories.contains(SearchCategory.messages) 
          ? []
          : [],
      notifications: categories.contains(SearchCategory.notifications) 
          ? []
          : [],
      totalResults: 0,
    );

    results.totalResults = results.residences.length +
        results.reservations.length +
        results.conversations.length +
        results.notifications.length;

    return results;
  }

  List<Residence> _getMockResidences(String query) {
    // Retourner des résultats factices pour développement
    return [];
  }
}

/// Résultats de recherche globale
class GlobalSearchResults {
  final String query;
  final List<Residence> residences;
  final List<Reservation> reservations;
  final List<Conversation> conversations;
  final List<NotificationModel> notifications;
  int totalResults;

  GlobalSearchResults({
    required this.query,
    required this.residences,
    required this.reservations,
    required this.conversations,
    required this.notifications,
    this.totalResults = 0,
  });

  factory GlobalSearchResults.fromJson(Map<String, dynamic> json) {
    return GlobalSearchResults(
      query: json['query'] ?? '',
      residences: (json['residences'] as List?)
              ?.map((e) => Residence.fromJson(e))
              .toList() ??
          [],
      reservations: (json['reservations'] as List?)
              ?.map((e) => Reservation.fromJson(e))
              .toList() ??
          [],
      conversations: (json['conversations'] as List?)
              ?.map((e) => Conversation.fromJson(e))
              .toList() ??
          [],
      notifications: (json['notifications'] as List?)
              ?.map((e) => NotificationModel.fromJson(e))
              .toList() ??
          [],
      totalResults: json['totalResults'] ?? 0,
    );
  }

  bool get isEmpty => totalResults == 0;
  bool get isNotEmpty => totalResults > 0;
}

/// Catégories de recherche
enum SearchCategory {
  all('all'),
  residences('residences'),
  reservations('reservations'),
  messages('messages'),
  notifications('notifications');

  final String value;
  const SearchCategory(this.value);
}

/// Filtres de recherche globale
class SearchFilters {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? status;
  final double? minPrice;
  final double? maxPrice;
  final String? city;
  final List<String>? amenities;

  SearchFilters({
    this.startDate,
    this.endDate,
    this.status,
    this.minPrice,
    this.maxPrice,
    this.city,
    this.amenities,
  });

  Map<String, dynamic> toQueryParameters() {
    final Map<String, dynamic> params = {};

    if (startDate != null) params['startDate'] = startDate!.toIso8601String();
    if (endDate != null) params['endDate'] = endDate!.toIso8601String();
    if (status != null) params['status'] = status;
    if (minPrice != null) params['minPrice'] = minPrice;
    if (maxPrice != null) params['maxPrice'] = maxPrice;
    if (city != null) params['city'] = city;
    if (amenities != null && amenities!.isNotEmpty) {
      params['amenities'] = amenities!.join(',');
    }

    return params;
  }
}

/// Filtres spécifiques aux résidences
class ResidenceFilters extends SearchFilters {
  final int? minCapacity;
  final int? maxCapacity;
  final List<String>? types;

  ResidenceFilters({
    super.startDate,
    super.endDate,
    super.status,
    super.minPrice,
    super.maxPrice,
    super.city,
    super.amenities,
    this.minCapacity,
    this.maxCapacity,
    this.types,
  });

  @override
  Map<String, dynamic> toQueryParameters() {
    final params = super.toQueryParameters();

    if (minCapacity != null) params['minCapacity'] = minCapacity;
    if (maxCapacity != null) params['maxCapacity'] = maxCapacity;
    if (types != null && types!.isNotEmpty) {
      params['types'] = types!.join(',');
    }

    return params;
  }
}

/// Filtres spécifiques aux réservations
class ReservationFilters extends SearchFilters {
  final List<String>? paymentStatuses;
  final bool? isPaid;

  ReservationFilters({
    super.startDate,
    super.endDate,
    super.status,
    super.minPrice,
    super.maxPrice,
    this.paymentStatuses,
    this.isPaid,
  });

  @override
  Map<String, dynamic> toQueryParameters() {
    final params = super.toQueryParameters();

    if (paymentStatuses != null && paymentStatuses!.isNotEmpty) {
      params['paymentStatuses'] = paymentStatuses!.join(',');
    }
    if (isPaid != null) params['isPaid'] = isPaid;

    return params;
  }
}

/// Options de tri
enum SearchSort {
  relevance('relevance'),
  dateDesc('dateDesc'),
  dateAsc('dateAsc'),
  priceDesc('priceDesc'),
  priceAsc('priceAsc'),
  nameAsc('nameAsc'),
  nameDesc('nameDesc');

  final String value;
  const SearchSort(this.value);

  String get label {
    switch (this) {
      case SearchSort.relevance:
        return 'Pertinence';
      case SearchSort.dateDesc:
        return 'Plus récent';
      case SearchSort.dateAsc:
        return 'Plus ancien';
      case SearchSort.priceDesc:
        return 'Prix décroissant';
      case SearchSort.priceAsc:
        return 'Prix croissant';
      case SearchSort.nameAsc:
        return 'Nom (A-Z)';
      case SearchSort.nameDesc:
        return 'Nom (Z-A)';
    }
  }
}


