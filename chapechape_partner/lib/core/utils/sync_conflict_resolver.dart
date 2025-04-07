import 'dart:convert';
import 'package:logging/logging.dart';

/// Utilitaire pour résoudre les conflits de synchronisation entre les données locales et du serveur
class SyncConflictResolver {
  static final Logger _logger = Logger('SyncConflictResolver');
  
  /// Résout les conflits entre les résidences locales et celles du serveur
  static Future<List<dynamic>> resolveResidenceConflicts(
    List<dynamic> cachedResidences, 
    List<dynamic> serverResidences
  ) async {
    final Map<String, dynamic> resolvedResidencesMap = {};
    
    // Créer une map des résidences du serveur pour un accès facile par ID
    final Map<String, dynamic> serverResidencesMap = {};
    for (var serverResidence in serverResidences) {
      final String id = _extractId(serverResidence);
      if (id.isNotEmpty) {
        serverResidencesMap[id] = serverResidence;
      }
    }
    
    // Parcourir les résidences en cache
    for (var cachedResidence in cachedResidences) {
      final String id = _extractId(cachedResidence);
      if (id.isEmpty) continue;
      
      // Vérifier si la résidence existe sur le serveur
      if (serverResidencesMap.containsKey(id)) {
        // Résidence présente dans les deux: comparer les dates de mise à jour
        final serverResidence = serverResidencesMap[id];
        final resolvedResidence = _resolveEntityConflict(cachedResidence, serverResidence, 'residence');
        
        resolvedResidencesMap[id] = resolvedResidence;
        // Supprimer de la map serveur pour traquer les résidences uniquement sur le serveur
        serverResidencesMap.remove(id);
      } else {
        // Résidence en local mais pas sur le serveur - conserver seulement si elle a un flag local
        if (_hasLocalFlag(cachedResidence)) {
          _logger.info('Résidence locale conservée (non présente sur le serveur): $id');
          resolvedResidencesMap[id] = cachedResidence;
        }
      }
    }
    
    // Ajouter les résidences uniquement présentes sur le serveur
    for (var entry in serverResidencesMap.entries) {
      resolvedResidencesMap[entry.key] = entry.value;
    }
    
    // Convertir la map en liste
    return resolvedResidencesMap.values.toList();
  }
  
  /// Résout les conflits entre les réservations locales et celles du serveur
  static Future<List<dynamic>> resolveReservationConflicts(
    List<dynamic> cachedReservations, 
    List<dynamic> serverReservations
  ) async {
    final Map<String, dynamic> resolvedReservationsMap = {};
    
    // Créer une map des réservations du serveur pour un accès facile par ID
    final Map<String, dynamic> serverReservationsMap = {};
    for (var serverReservation in serverReservations) {
      final String id = _extractId(serverReservation);
      if (id.isNotEmpty) {
        serverReservationsMap[id] = serverReservation;
      }
    }
    
    // Parcourir les réservations en cache
    for (var cachedReservation in cachedReservations) {
      final String id = _extractId(cachedReservation);
      if (id.isEmpty) continue;
      
      // Vérifier si la réservation existe sur le serveur
      if (serverReservationsMap.containsKey(id)) {
        // Réservation présente dans les deux: comparer les dates de mise à jour
        final serverReservation = serverReservationsMap[id];
        final resolvedReservation = _resolveEntityConflict(cachedReservation, serverReservation, 'reservation');
        
        resolvedReservationsMap[id] = resolvedReservation;
        // Supprimer de la map serveur pour traquer les réservations uniquement sur le serveur
        serverReservationsMap.remove(id);
      } else {
        // Réservation en local mais pas sur le serveur
        // Pour les réservations, conserver uniquement celles qui ont été modifiées localement
        if (_hasLocalFlag(cachedReservation)) {
          _logger.info('Réservation locale conservée (non présente sur le serveur): $id');
          resolvedReservationsMap[id] = cachedReservation;
        }
      }
    }
    
    // Ajouter les réservations uniquement présentes sur le serveur
    for (var entry in serverReservationsMap.entries) {
      resolvedReservationsMap[entry.key] = entry.value;
    }
    
    // Convertir la map en liste
    return resolvedReservationsMap.values.toList();
  }
  
  /// Résout un conflit entre deux instances de la même entité
  static dynamic _resolveEntityConflict(dynamic localEntity, dynamic serverEntity, String entityType) {
    try {
      // Convertir en Maps si ce sont des objets JSON
      final Map<String, dynamic> localMap = _ensureMapFormat(localEntity);
      final Map<String, dynamic> serverMap = _ensureMapFormat(serverEntity);
      
      // Extraire les dates de mise à jour
      final DateTime? localUpdatedAt = _extractUpdatedAt(localMap);
      final DateTime? serverUpdatedAt = _extractUpdatedAt(serverMap);
      
      // Si l'entité locale a un flag indiquant qu'elle a été modifiée localement
      // mais n'a pas encore été synchronisée, privilégier la version locale
      if (_hasLocalModificationFlag(localMap)) {
        _logger.info('$entityType: version locale privilégiée car modifications locales');
        return localEntity;
      }
      
      // Si les deux ont des dates de mise à jour, comparer les dates
      if (localUpdatedAt != null && serverUpdatedAt != null) {
        if (localUpdatedAt.isAfter(serverUpdatedAt)) {
          _logger.info('$entityType: version locale plus récente');
          return localEntity;
        } else {
          _logger.info('$entityType: version serveur plus récente ou identique');
          return serverEntity;
        }
      }
      
      // Par défaut, privilégier la version du serveur
      return serverEntity;
    } catch (e) {
      _logger.warning('Erreur lors de la résolution de conflit pour $entityType: $e');
      // En cas d'erreur, privilégier la version du serveur
      return serverEntity;
    }
  }
  
  /// Extrait l'ID d'une entité, qu'elle soit sous forme de Map ou de String JSON
  static String _extractId(dynamic entity) {
    try {
      if (entity is Map) {
        return entity['id']?.toString() ?? 
               entity['_id']?.toString() ?? 
               '';
      } else if (entity is String) {
        final map = jsonDecode(entity);
        return map['id']?.toString() ?? 
               map['_id']?.toString() ?? 
               '';
      }
      return '';
    } catch (e) {
      _logger.warning('Erreur lors de l\'extraction de l\'ID: $e');
      return '';
    }
  }
  
  /// Extrait la date de mise à jour d'une entité
  static DateTime? _extractUpdatedAt(Map<String, dynamic> entityMap) {
    try {
      final String? updatedAtStr = entityMap['updatedAt']?.toString() ?? 
                                   entityMap['updated_at']?.toString() ?? 
                                   entityMap['lastModified']?.toString();
      
      if (updatedAtStr != null) {
        return DateTime.parse(updatedAtStr);
      }
      return null;
    } catch (e) {
      _logger.warning('Erreur lors de l\'extraction de la date de mise à jour: $e');
      return null;
    }
  }
  
  /// Vérifie si l'entité a un flag local indiquant qu'elle a été créée localement
  static bool _hasLocalFlag(dynamic entity) {
    try {
      final map = _ensureMapFormat(entity);
      return map['isLocal'] == true || 
             map['local'] == true ||
             map['pendingSync'] == true ||
             map['needsSync'] == true;
    } catch (e) {
      return false;
    }
  }
  
  /// Vérifie si l'entité a un flag de modification locale
  static bool _hasLocalModificationFlag(Map<String, dynamic> entityMap) {
    return entityMap['pendingSync'] == true || 
           entityMap['needsSync'] == true ||
           entityMap['modifiedLocally'] == true;
  }
  
  /// Assure qu'une entité est au format Map
  static Map<String, dynamic> _ensureMapFormat(dynamic entity) {
    if (entity is Map<String, dynamic>) {
      return entity;
    } else if (entity is String) {
      try {
        return jsonDecode(entity);
      } catch (e) {
        _logger.warning('Erreur lors de la conversion JSON: $e');
        return {};
      }
    } else if (entity is Map) {
      // Convertir Map<dynamic, dynamic> en Map<String, dynamic>
      return Map<String, dynamic>.from(entity);
    }
    return {};
  }
} 