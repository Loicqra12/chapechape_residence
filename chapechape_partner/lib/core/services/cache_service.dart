import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

/// Service qui gère le cache local de l'application
class CacheService {
  // Singleton
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();
  
  // Logger
  final Logger _logger = Logger('CacheService');
  
  // Noms des boîtes de stockage
  static const String _residencesBox = 'residences';
  static const String _reservationsBox = 'reservations';
  static const String _pendingOperationsBox = 'pending_operations';
  static const String _userDataBox = 'user_data';
  static const String _messagesBox = 'messages';
  static const String _pendingMessagesBox = 'pending_messages';
  
  // Générateur UUID pour les IDs temporaires
  final Uuid _uuid = Uuid();
  
  // Flag d'initialisation
  bool _isInitialized = false;
  
  /// Initialise le service de cache
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await Hive.initFlutter();
    await Hive.openBox(_residencesBox);
    await Hive.openBox(_reservationsBox);
    await Hive.openBox(_pendingOperationsBox);
    await Hive.openBox(_userDataBox);
    await Hive.openBox(_messagesBox);
    await Hive.openBox(_pendingMessagesBox);
    
    // Marquer comme initialisé avant de purger pour éviter l'erreur
    _isInitialized = true;
    _logger.info('Service de cache initialisé');
    
    // Purger les résidences problématiques du cache après initialisation
    await _purgeDeletedResidencesFromCache();
  }
  
  /// Purge les résidences supprimées du cache
  Future<void> _purgeDeletedResidencesFromCache() async {
    try {
      final box = _getBox(_residencesBox);
      
      // Purger les résidences problématiques par ID connu
      const knownDeletedIds = ['67e2ecd94408a95a7b598b0d'];
      for (var id in knownDeletedIds) {
        if (box.containsKey(id)) {
          await box.delete(id);
          _logger.info('Résidence supprimée purgée du cache: $id');
        }
      }
      
      // Vérifier toutes les autres entrées
      final keys = box.keys.where((key) => key != 'lastUpdated').toList();
      int purgedCount = 0;
      
      for (var key in keys) {
        final data = box.get(key);
        if (data == null) continue;
        
        try {
          Map<String, dynamic> residenceMap;
          if (data is String) {
            residenceMap = jsonDecode(data);
          } else if (data is Map) {
            residenceMap = Map<String, dynamic>.from(data);
          } else {
            continue;
          }
          
          // Purger si marquée comme supprimée ou si le titre est vide/null
          final isDeleted = residenceMap['deleted'] == true;
          final hasEmptyTitle = residenceMap['name'] == null || 
                               residenceMap['name'] == '' || 
                               residenceMap['title'] == null || 
                               residenceMap['title'] == '';
                               
          if (isDeleted || hasEmptyTitle) {
            await box.delete(key);
            purgedCount++;
          }
        } catch (e) {
          _logger.warning('Erreur lors de la vérification de la résidence $key: $e');
        }
      }
      
      if (purgedCount > 0) {
        _logger.info('$purgedCount résidences supprimées purgées du cache');
      }
    } catch (e) {
      _logger.warning('Erreur lors de la purge des résidences supprimées: $e');
    }
  }
  
  // Récupère une boîte de stockage par son nom
  Box _getBox(String boxName) {
    if (!_isInitialized) {
      throw Exception('Le service de cache n\'a pas été initialisé');
    }
    return Hive.box(boxName);
  }
  
  // Gestion des résidences
  
  /// Stocke une liste de résidences dans le cache
  Future<void> cacheResidences(List<dynamic> residences) async {
    final box = _getBox(_residencesBox);
    await box.clear(); // Efface les anciennes données
    
    // Stocker chaque résidence individuellement avec son ID comme clé
    for (var residence in residences) {
      // S'assurer que les données sont au format JSON
      final data = residence is String 
          ? residence 
          : jsonEncode(residence);
      
      // Extraire l'ID pour l'utiliser comme clé
      String id;
      if (residence is Map) {
        id = residence['id'] ?? residence['_id'] ?? _uuid.v4();
      } else if (residence is String) {
        try {
          final map = jsonDecode(residence);
          id = map['id'] ?? map['_id'] ?? _uuid.v4();
        } catch (e) {
          id = _uuid.v4();
        }
      } else {
        id = _uuid.v4();
      }
      
      await box.put(id, data);
      _logger.fine('Résidence mise en cache: $id');
    }
    
    // Stocker aussi la date de dernière mise à jour
    await box.put('lastUpdated', DateTime.now().toIso8601String());
    _logger.info('${residences.length} résidences mises en cache');
  }
  
  /// Récupère toutes les résidences du cache
  Future<List<dynamic>> getCachedResidences() async {
    final box = _getBox(_residencesBox);
    
    // Filtrer les clés spéciales comme 'lastUpdated'
    final keys = box.keys.where((key) => key != 'lastUpdated').toList();
    
    // Récupérer les données pour chaque clé
    final residences = <dynamic>[];
    for (var key in keys) {
      final data = box.get(key);
      if (data != null) {
        try {
          // Si c'est une chaîne JSON, la convertir en objet
          Map<String, dynamic> residenceMap;
          if (data is String) {
            residenceMap = jsonDecode(data);
          } else if (data is Map) {
            residenceMap = Map<String, dynamic>.from(data);
          } else {
            continue;
          }
          
          // Filtrer les résidences marquées comme supprimées
          if (residenceMap['deleted'] == true) {
            _logger.info('Résidence $key ignorée car marquée comme supprimée');
            continue;
          }
          
          residences.add(residenceMap);
        } catch (e) {
          _logger.warning('Erreur lors de la lecture de la résidence $key: $e');
        }
      }
    }
    
    _logger.info('${residences.length} résidences actives récupérées du cache');
    return residences;
  }
  
  /// Récupère une résidence spécifique par son ID
  Future<Map<String, dynamic>?> getResidenceById(String id) async {
    final box = _getBox(_residencesBox);
    final data = box.get(id);
    
    if (data == null) return null;
    
    try {
      if (data is String) {
        return jsonDecode(data);
      } else if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      _logger.warning('Erreur lors de la récupération de la résidence $id: $e');
    }
    
    return null;
  }
  
  /// Cache une résidence individuelle
  Future<void> cacheResidence(dynamic residence) async {
    if (residence == null) return;
    
    try {
      final id = residence is Map ? 
                (residence['id'] ?? residence['_id'])?.toString() : 
                null;
      
      if (id == null) {
        _logger.warning('Impossible de cacher la résidence: ID manquant');
        return;
      }
      
      final box = _getBox(_residencesBox);
      
      // Convertir en JSON si nécessaire
      final String jsonData = residence is Map ? 
                             jsonEncode(residence) : 
                             residence.toString();
      
      await box.put(id, jsonData);
      _logger.info('Résidence $id mise en cache');
    } catch (e) {
      _logger.warning('Erreur lors de la mise en cache de la résidence: $e');
    }
  }
  
  /// Vérifie si les résidences sont en cache et pas trop anciennes
  bool areResidencesValid() {
    final box = _getBox(_residencesBox);
    final lastUpdatedStr = box.get('lastUpdated');
    
    if (lastUpdatedStr == null) return false;
    
    try {
      final lastUpdated = DateTime.parse(lastUpdatedStr);
      final now = DateTime.now();
      final difference = now.difference(lastUpdated);
      
      // Considérer les données valides si elles ont moins de 1 heure
      return difference.inHours < 1;
    } catch (e) {
      return false;
    }
  }
  
  /// Marque une résidence comme ayant des modifications locales en attente de synchronisation
  Future<void> markResidenceForSync(String id) async {
    final box = _getBox(_residencesBox);
    final data = box.get(id);
    
    if (data == null) return;
    
    try {
      Map<String, dynamic> residenceMap;
      if (data is String) {
        residenceMap = jsonDecode(data);
      } else if (data is Map) {
        residenceMap = Map<String, dynamic>.from(data);
      } else {
        return;
      }
      
      // Ajouter le flag de synchronisation
      residenceMap['needsSync'] = true;
      residenceMap['lastModified'] = DateTime.now().toIso8601String();
      
      // Réécrire dans le cache
      await box.put(id, jsonEncode(residenceMap));
      _logger.info('Résidence $id marquée pour synchronisation');
    } catch (e) {
      _logger.warning('Erreur lors du marquage de la résidence $id pour synchronisation: $e');
    }
  }
  
  /// Récupère les résidences qui ont été modifiées localement
  Future<List<Map<String, dynamic>>> getLocallyModifiedResidences() async {
    final box = _getBox(_residencesBox);
    final List<Map<String, dynamic>> modifiedResidences = [];
    
    try {
      for (var key in box.keys) {
        // Ignorer les clés spéciales
        if (key == 'lastUpdated') continue;
        
        final data = box.get(key);
        if (data == null) continue;
        
        Map<String, dynamic> residenceMap;
        if (data is String) {
          residenceMap = jsonDecode(data);
        } else if (data is Map) {
          residenceMap = Map<String, dynamic>.from(data);
        } else {
          continue;
        }
        
        // Vérifier si la résidence a besoin d'être synchronisée
        if (residenceMap['needsSync'] == true || 
            residenceMap['isLocal'] == true || 
            residenceMap['modifiedLocally'] == true) {
          modifiedResidences.add(residenceMap);
        }
      }
      
      _logger.info('${modifiedResidences.length} résidences modifiées localement trouvées');
      return modifiedResidences;
    } catch (e) {
      _logger.warning('Erreur lors de la récupération des résidences modifiées localement: $e');
      return [];
    }
  }
  
  /// Marque une résidence comme synchronisée (supprime les flags de modification locale)
  Future<void> markResidenceAsSynced(String id) async {
    final box = _getBox(_residencesBox);
    final data = box.get(id);
    
    if (data == null) return;
    
    try {
      Map<String, dynamic> residenceMap;
      if (data is String) {
        residenceMap = jsonDecode(data);
      } else if (data is Map) {
        residenceMap = Map<String, dynamic>.from(data);
      } else {
        return;
      }
      
      // Supprimer les flags de modification locale
      residenceMap.remove('needsSync');
      residenceMap.remove('isLocal');
      residenceMap.remove('modifiedLocally');
      residenceMap.remove('modifiedFields');
      
      // Mettre à jour la date de dernière synchronisation
      residenceMap['lastSynced'] = DateTime.now().toIso8601String();
      
      // Réécrire dans le cache
      await box.put(id, jsonEncode(residenceMap));
      _logger.info('Résidence $id marquée comme synchronisée');
    } catch (e) {
      _logger.warning('Erreur lors du marquage de la résidence $id comme synchronisée: $e');
    }
  }
  
  /// Supprime une résidence spécifique du cache par son ID
  Future<bool> deleteResidenceFromCache(String id) async {
    try {
      final box = _getBox(_residencesBox);
      
      // Vérifier si l'ID existe dans le cache
      if (box.containsKey(id)) {
        await box.delete(id);
        _logger.info('Résidence $id supprimée du cache');
        return true;
      } else {
        // Vérifier si la résidence existe avec un autre format de clé
        // Parcourir toutes les résidences pour trouver celle avec le bon ID
        for (var key in box.keys) {
          if (key == 'lastUpdated') continue;
          
          final data = box.get(key);
          if (data == null) continue;
          
          try {
            Map<String, dynamic> residenceMap;
            if (data is String) {
              residenceMap = jsonDecode(data);
            } else if (data is Map) {
              residenceMap = Map<String, dynamic>.from(data);
            } else {
              continue;
            }
            
            final residenceId = residenceMap['id'] ?? residenceMap['_id'];
            if (residenceId == id) {
              await box.delete(key);
              _logger.info('Résidence $id (clé: $key) supprimée du cache');
              return true;
            }
          } catch (e) {
            _logger.warning('Erreur lors de la lecture de la résidence pour la suppression: $e');
          }
        }
        
        _logger.warning('Résidence $id non trouvée dans le cache');
        return false;
      }
    } catch (e) {
      _logger.severe('Erreur lors de la suppression de la résidence $id du cache: $e');
      return false;
    }
  }
  
  // Gestion des réservations
  
  /// Stocke une liste de réservations dans le cache
  Future<void> cacheReservations(List<dynamic> reservations) async {
    final box = _getBox(_reservationsBox);
    await box.clear();
    
    // Même principe que pour les résidences
    for (var reservation in reservations) {
      final data = reservation is String ? reservation : jsonEncode(reservation);
      
      String id;
      if (reservation is Map) {
        id = reservation['id'] ?? reservation['_id'] ?? _uuid.v4();
      } else if (reservation is String) {
        try {
          final map = jsonDecode(reservation);
          id = map['id'] ?? map['_id'] ?? _uuid.v4();
        } catch (e) {
          id = _uuid.v4();
        }
      } else {
        id = _uuid.v4();
      }
      
      await box.put(id, data);
    }
    
    await box.put('lastUpdated', DateTime.now().toIso8601String());
    _logger.info('${reservations.length} réservations mises en cache');
  }
  
  /// Récupère toutes les réservations du cache
  Future<List<dynamic>> getCachedReservations() async {
    final box = _getBox(_reservationsBox);
    final keys = box.keys.where((key) => key != 'lastUpdated').toList();
    
    final reservations = <dynamic>[];
    for (var key in keys) {
      final data = box.get(key);
      if (data != null) {
        try {
          if (data is String) {
            reservations.add(jsonDecode(data));
          } else {
            reservations.add(data);
          }
        } catch (e) {
          _logger.warning('Erreur lors de la lecture de la réservation $key: $e');
        }
      }
    }
    
    _logger.info('${reservations.length} réservations récupérées du cache');
    return reservations;
  }
  
  /// Récupère une réservation spécifique par son ID
  Future<dynamic> getCachedReservationById(String id) async {
    final box = _getBox(_reservationsBox);
    final data = box.get(id);
    
    if (data == null) return null;
    
    try {
      if (data is String) {
        return jsonDecode(data);
      }
      return data;
    } catch (e) {
      _logger.warning('Erreur lors de la lecture de la réservation $id: $e');
      return null;
    }
  }
  
  /// Vérifie si les réservations sont en cache et pas trop anciennes
  bool areReservationsValid() {
    final box = _getBox(_reservationsBox);
    final lastUpdatedStr = box.get('lastUpdated');
    
    if (lastUpdatedStr == null) return false;
    
    try {
      final lastUpdated = DateTime.parse(lastUpdatedStr);
      final now = DateTime.now();
      final difference = now.difference(lastUpdated);
      
      // Considérer les données valides si elles ont moins de 30 minutes
      return difference.inMinutes < 30;
    } catch (e) {
      return false;
    }
  }
  
  /// Marque une réservation comme ayant des modifications locales
  Future<void> markReservationForSync(String id) async {
    final box = _getBox(_reservationsBox);
    final data = box.get(id);
    
    if (data == null) return;
    
    try {
      Map<String, dynamic> reservationMap;
      if (data is String) {
        reservationMap = jsonDecode(data);
      } else if (data is Map) {
        reservationMap = Map<String, dynamic>.from(data);
      } else {
        return;
      }
      
      // Ajouter le flag de synchronisation
      reservationMap['needsSync'] = true;
      reservationMap['lastModified'] = DateTime.now().toIso8601String();
      
      // Réécrire dans le cache
      await box.put(id, jsonEncode(reservationMap));
      _logger.info('Réservation $id marquée pour synchronisation');
    } catch (e) {
      _logger.warning('Erreur lors du marquage de la réservation $id pour synchronisation: $e');
    }
  }
  
  /// Récupère les réservations qui ont été modifiées localement
  Future<List<Map<String, dynamic>>> getLocallyModifiedReservations() async {
    final box = _getBox(_reservationsBox);
    final List<Map<String, dynamic>> modifiedReservations = [];
    
    try {
      for (var key in box.keys) {
        // Ignorer les clés spéciales
        if (key == 'lastUpdated') continue;
        
        final data = box.get(key);
        if (data == null) continue;
        
        Map<String, dynamic> reservationMap;
        if (data is String) {
          reservationMap = jsonDecode(data);
        } else if (data is Map) {
          reservationMap = Map<String, dynamic>.from(data);
        } else {
          continue;
        }
        
        // Vérifier si la réservation a besoin d'être synchronisée
        if (reservationMap['needsSync'] == true || 
            reservationMap['isLocal'] == true || 
            reservationMap['modifiedLocally'] == true) {
          modifiedReservations.add(reservationMap);
        }
      }
      
      _logger.info('${modifiedReservations.length} réservations modifiées localement trouvées');
      return modifiedReservations;
    } catch (e) {
      _logger.warning('Erreur lors de la récupération des réservations modifiées localement: $e');
      return [];
    }
  }
  
  /// Marque une réservation comme synchronisée (supprime les flags de modification locale)
  Future<void> markReservationAsSynced(String id) async {
    final box = _getBox(_reservationsBox);
    final data = box.get(id);
    
    if (data == null) return;
    
    try {
      Map<String, dynamic> reservationMap;
      if (data is String) {
        reservationMap = jsonDecode(data);
      } else if (data is Map) {
        reservationMap = Map<String, dynamic>.from(data);
      } else {
        return;
      }
      
      // Supprimer les flags de modification locale
      reservationMap.remove('needsSync');
      reservationMap.remove('isLocal');
      reservationMap.remove('modifiedLocally');
      reservationMap.remove('modifiedFields');
      
      // Mettre à jour la date de dernière synchronisation
      reservationMap['lastSynced'] = DateTime.now().toIso8601String();
      
      // Réécrire dans le cache
      await box.put(id, jsonEncode(reservationMap));
      _logger.info('Réservation $id marquée comme synchronisée');
    } catch (e) {
      _logger.warning('Erreur lors du marquage de la réservation $id comme synchronisée: $e');
    }
  }
  
  // Gestion des messages
  
  /// Cache une liste de messages
  Future<void> cacheMessages(List<dynamic> messages) async {
    final box = _getBox(_messagesBox);
    await box.clear();
    
    // Même principe que pour les autres entités
    for (var message in messages) {
      final data = message is String ? message : jsonEncode(message);
      
      String id;
      if (message is Map) {
        id = message['id'] ?? message['_id'] ?? _uuid.v4();
      } else if (message is String) {
        try {
          final map = jsonDecode(message);
          id = map['id'] ?? map['_id'] ?? _uuid.v4();
        } catch (e) {
          id = _uuid.v4();
        }
      } else {
        id = _uuid.v4();
      }
      
      await box.put(id, data);
    }
    
    await box.put('lastUpdated', DateTime.now().toIso8601String());
    _logger.info('${messages.length} messages mis en cache');
  }
  
  /// Récupère tous les messages du cache
  Future<List<dynamic>> getCachedMessages() async {
    final box = _getBox(_messagesBox);
    final keys = box.keys.where((key) => key != 'lastUpdated').toList();
    
    final messages = <dynamic>[];
    for (var key in keys) {
      final data = box.get(key);
      if (data != null) {
        try {
          if (data is String) {
            messages.add(jsonDecode(data));
          } else {
            messages.add(data);
          }
        } catch (e) {
          _logger.warning('Erreur lors de la lecture du message $key: $e');
        }
      }
    }
    
    _logger.info('${messages.length} messages récupérés du cache');
    return messages;
  }
  
  /// Ajoute un message en attente d'envoi
  Future<String> addPendingMessage(String conversationId, String content, {Map<String, dynamic>? additionalData}) async {
    final box = _getBox(_pendingMessagesBox);
    
    final messageId = _uuid.v4();
    final message = {
      'id': messageId,
      'conversationId': conversationId,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
      'sender': 'me', // Toujours l'utilisateur actuel pour les messages en attente
      'status': 'pending',
      ...?additionalData,
    };
    
    await box.put(messageId, jsonEncode(message));
    _logger.info('Message ajouté à la file d\'attente: $messageId');
    
    return messageId;
  }
  
  /// Récupère tous les messages en attente d'envoi
  Future<List<Map<String, dynamic>>> getPendingMessages() async {
    final box = _getBox(_pendingMessagesBox);
    final keys = box.keys.toList();
    
    final messages = <Map<String, dynamic>>[];
    for (var key in keys) {
      final data = box.get(key);
      if (data != null && data is String) {
        try {
          final message = jsonDecode(data);
          messages.add({
            'id': key,
            ...message,
          });
        } catch (e) {
          _logger.warning('Erreur lors de la lecture du message en attente $key: $e');
        }
      }
    }
    
    _logger.info('${messages.length} messages en attente récupérés');
    return messages;
  }
  
  /// Supprime un message en attente après envoi réussi
  Future<void> removePendingMessage(String id) async {
    final box = _getBox(_pendingMessagesBox);
    await box.delete(id);
    _logger.info('Message en attente supprimé: $id');
  }
  
  // Gestion des opérations en attente
  
  /// Enregistre une opération à effectuer lorsque la connexion sera rétablie
  Future<void> addPendingOperation(String operation, Map<String, dynamic> data, {String? operationId}) async {
    final box = _getBox(_pendingOperationsBox);
    final pendingOp = {
      'operation': operation,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    final id = operationId ?? '${operation}_${DateTime.now().millisecondsSinceEpoch}';
    await box.put(id, jsonEncode(pendingOp));
    _logger.info('Opération en attente ajoutée: $operation (ID: $id)');
  }
  
  /// Récupère toutes les opérations en attente
  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    final box = _getBox(_pendingOperationsBox);
    final keys = box.keys.toList();
    
    final operations = <Map<String, dynamic>>[];
    for (var key in keys) {
      final data = box.get(key);
      if (data != null && data is String) {
        try {
          final op = jsonDecode(data);
          operations.add({
            'id': key,
            ...op,
          });
        } catch (e) {
          _logger.warning('Erreur lors de la lecture de l\'opération $key: $e');
        }
      }
    }
    
    _logger.info('${operations.length} opérations en attente récupérées');
    return operations;
  }
  
  /// Supprime une opération en attente
  Future<void> removePendingOperation(String id) async {
    final box = _getBox(_pendingOperationsBox);
    await box.delete(id);
    _logger.info('Opération en attente supprimée: $id');
  }
  
  /// Stocke des données utilisateur dans le cache
  Future<void> saveUserData(String key, dynamic value) async {
    final box = _getBox(_userDataBox);
    if (value is Map || value is List) {
      await box.put(key, jsonEncode(value));
    } else {
      await box.put(key, value);
    }
    _logger.fine('Données utilisateur enregistrées: $key');
  }
  
  /// Récupère des données utilisateur du cache
  Future<dynamic> getUserData(String key) async {
    final box = _getBox(_userDataBox);
    final value = box.get(key);
    
    if (value == null) return null;
    
    // Tenter de parser la valeur si c'est une chaîne JSON
    if (value is String) {
      try {
        return jsonDecode(value);
      } catch (e) {
        // Si ce n'est pas un JSON valide, retourner la chaîne telle quelle
        return value;
      }
    }
    
    return value;
  }
  
  /// Récupère les réservations créées offline
  Future<List<dynamic>> getOfflineReservations() async {
    final box = _getBox(_reservationsBox);
    final reservations = <dynamic>[];
    
    for (final key in box.keys) {
      if (key == 'lastUpdated') continue;
      
      try {
        final data = box.get(key);
        if (data is String) {
          final reservation = jsonDecode(data);
          if (reservation['isLocal'] == true || reservation['isOffline'] == true) {
            reservations.add(reservation);
          }
        }
      } catch (e) {
        _logger.warning('Erreur lors de la lecture de la réservation $key: $e');
      }
    }
    
    return reservations;
  }

  /// Marque une réservation comme créée offline
  Future<void> markReservationAsOffline(String reservationId) async {
    final box = _getBox(_reservationsBox);
    final data = box.get(reservationId);
    
    if (data is String) {
      try {
        final reservation = jsonDecode(data);
        reservation['isLocal'] = true;
        reservation['isOffline'] = true;
        reservation['needsSync'] = true;
        await box.put(reservationId, jsonEncode(reservation));
        _logger.info('Réservation marquée comme offline: $reservationId');
      } catch (e) {
        _logger.warning('Erreur lors du marquage offline de la réservation: $e');
      }
    }
  }

  /// Efface toutes les données du cache (utile lors de la déconnexion)
  Future<void> clearAllData() async {
    final boxes = [
      _residencesBox,
      _reservationsBox,
      _pendingOperationsBox,
      _userDataBox,
      _messagesBox,
      _pendingMessagesBox,
    ];
    
    for (var boxName in boxes) {
      final box = _getBox(boxName);
      await box.clear();
    }
    
    _logger.info('Toutes les données du cache ont été effacées');
  }
} 