import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/config/app_config_manager.dart';

/// Service pour gérer l'audit et la sécurité
class AuditService {
  final Dio _dio;

  AuditService(this._dio);

  /// Obtenir l'historique de sécurité d'un utilisateur
  Future<SecurityHistoryResult> getSecurityHistory({int limit = 50}) async {
    try {
      final response = await _dio.get(
        '/audit/security-history',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> historyData = response.data['data'] ?? [];
        final history = historyData.map((item) => SecurityActivity.fromJson(item)).toList();

        return SecurityHistoryResult(
          success: true,
          history: history,
        );
      } else {
        return SecurityHistoryResult(
          success: false,
          message: response.data['message'] ?? 'Erreur lors de la récupération de l\'historique',
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur getSecurityHistory: $e');
      return SecurityHistoryResult(
        success: false,
        message: 'Erreur de connexion: $e',
      );
    }
  }

  /// Obtenir les statistiques de sécurité
  Future<SecurityStatsResult> getSecurityStats({int days = 30}) async {
    try {
      final response = await _dio.get(
        '/audit/security-stats',
        queryParameters: {'days': days},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final statsData = response.data['data'];
        final stats = SecurityStats.fromJson(statsData);

        return SecurityStatsResult(
          success: true,
          stats: stats,
        );
      } else {
        return SecurityStatsResult(
          success: false,
          message: response.data['message'] ?? 'Erreur lors de la récupération des statistiques',
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur getSecurityStats: $e');
      return SecurityStatsResult(
        success: false,
        message: 'Erreur de connexion: $e',
      );
    }
  }

  /// Obtenir le journal d'activité complet
  Future<ActivityLogResult> getActivityLog({
    int page = 1,
    int limit = 20,
    String? module,
    String? action,
    String? severity,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (module != null) queryParams['module'] = module;
      if (action != null) queryParams['action'] = action;
      if (severity != null) queryParams['severity'] = severity;

      final response = await _dio.get(
        '/audit/activity-log',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final List<dynamic> activitiesData = data['activities'] ?? [];
        final activities = activitiesData.map((item) => SecurityActivity.fromJson(item)).toList();
        
        final paginationData = data['pagination'];
        final pagination = PaginationInfo.fromJson(paginationData);

        return ActivityLogResult(
          success: true,
          activities: activities,
          pagination: pagination,
        );
      } else {
        return ActivityLogResult(
          success: false,
          message: response.data['message'] ?? 'Erreur lors de la récupération du journal',
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur getActivityLog: $e');
      return ActivityLogResult(
        success: false,
        message: 'Erreur de connexion: $e',
      );
    }
  }
}

/// Modèle pour une activité de sécurité
class SecurityActivity {
  final String id;
  final String action;
  final String module;
  final String description;
  final String ipAddress;
  final String? userAgent;
  final LocationInfo? location;
  final DeviceInfo? device;
  final String status;
  final String severity;
  final int riskScore;
  final bool isSuspicious;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  SecurityActivity({
    required this.id,
    required this.action,
    required this.module,
    required this.description,
    required this.ipAddress,
    this.userAgent,
    this.location,
    this.device,
    required this.status,
    required this.severity,
    required this.riskScore,
    required this.isSuspicious,
    required this.createdAt,
    required this.metadata,
  });

  factory SecurityActivity.fromJson(Map<String, dynamic> json) {
    return SecurityActivity(
      id: json['_id'] ?? '',
      action: json['action'] ?? '',
      module: json['module'] ?? '',
      description: json['description'] ?? '',
      ipAddress: json['ipAddress'] ?? '',
      userAgent: json['userAgent'],
      location: json['location'] != null ? LocationInfo.fromJson(json['location']) : null,
      device: json['device'] != null ? DeviceInfo.fromJson(json['device']) : null,
      status: json['status'] ?? '',
      severity: json['severity'] ?? '',
      riskScore: json['riskScore'] ?? 0,
      isSuspicious: json['isSuspicious'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Obtenir l'icône selon l'action
  String get actionIcon {
    switch (action) {
      case 'login':
        return '🔐';
      case 'logout':
        return '🚪';
      case 'login_failed':
        return '❌';
      case 'password_change':
        return '🔑';
      case 'email_change':
        return '📧';
      case 'phone_change':
        return '📱';
      case 'bank_account_change':
        return '🏦';
      case 'payout_initiated':
        return '💸';
      case 'security_alert':
        return '⚠️';
      default:
        return '📝';
    }
  }

  /// Obtenir la couleur selon la gravité
  String get severityColor {
    switch (severity) {
      case 'low':
        return 'green';
      case 'medium':
        return 'orange';
      case 'high':
        return 'red';
      case 'critical':
        return 'purple';
      default:
        return 'grey';
    }
  }
}

/// Informations de localisation
class LocationInfo {
  final String country;
  final String region;
  final String city;

  LocationInfo({
    required this.country,
    required this.region,
    required this.city,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      country: json['country'] ?? 'Unknown',
      region: json['region'] ?? 'Unknown',
      city: json['city'] ?? 'Unknown',
    );
  }
}

/// Informations de l'appareil
class DeviceInfo {
  final String type;
  final String os;
  final String browser;

  DeviceInfo({
    required this.type,
    required this.os,
    required this.browser,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      type: json['type'] ?? 'unknown',
      os: json['os'] ?? 'unknown',
      browser: json['browser'] ?? 'unknown',
    );
  }
}

/// Statistiques de sécurité
class SecurityStats {
  final int totalActivities;
  final int suspiciousActivities;
  final int failedLogins;
  final int highRiskActivities;
  final double averageRiskScore;

  SecurityStats({
    required this.totalActivities,
    required this.suspiciousActivities,
    required this.failedLogins,
    required this.highRiskActivities,
    required this.averageRiskScore,
  });

  factory SecurityStats.fromJson(Map<String, dynamic> json) {
    return SecurityStats(
      totalActivities: json['totalActivities'] ?? 0,
      suspiciousActivities: json['suspiciousActivities'] ?? 0,
      failedLogins: json['failedLogins'] ?? 0,
      highRiskActivities: json['highRiskActivities'] ?? 0,
      averageRiskScore: (json['averageRiskScore'] ?? 0).toDouble(),
    );
  }
}

/// Informations de pagination
class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int pages;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 1,
    );
  }
}

/// Résultat de l'historique de sécurité
class SecurityHistoryResult {
  final bool success;
  final String? message;
  final List<SecurityActivity> history;

  SecurityHistoryResult({
    required this.success,
    this.message,
    this.history = const [],
  });
}

/// Résultat des statistiques de sécurité
class SecurityStatsResult {
  final bool success;
  final String? message;
  final SecurityStats? stats;

  SecurityStatsResult({
    required this.success,
    this.message,
    this.stats,
  });
}

/// Résultat du journal d'activité
class ActivityLogResult {
  final bool success;
  final String? message;
  final List<SecurityActivity> activities;
  final PaginationInfo? pagination;

  ActivityLogResult({
    required this.success,
    this.message,
    this.activities = const [],
    this.pagination,
  });
}


