import 'package:dio/dio.dart';
import '../../models/message/message.dart';
import '../../models/message/conversation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chapechape_partner/core/utils/secure_storage.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../config/feature_flags.dart';
import '../media/cloudinary_service.dart';
import 'package:chapechape_partner/core/utils/app_logger.dart';

class MessageService {
  late final Dio _dio;
  final _storage = AppSecureStorage.instance;

  MessageService(Dio dio) {
    _dio = dio;
    // Ajouter l'intercepteur pour le token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  String? get currentUserId {
    final headers = _dio.options.headers;
    final authHeader = headers['Authorization'] as String?;
    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      return authHeader.split(' ')[1];
    }
    return null;
  }
  
  // Getter pour accéder à l'instance Dio
  Dio get dio => _dio;
  
  // Retourne l'instance Dio pour les requêtes externes
  Dio getDio() {
    return _dio;
  }

  /// Recherche des messages dans une conversation
  Future<List<Message>> searchMessages({
    required String conversationId,
    required String query,
  }) async {
    try {
      final response = await _dio.get(
        '/messages/search',
        queryParameters: {
          'conversationId': conversationId,
          'query': query,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> messagesData = response.data['data'] ?? [];
        return messagesData.map((data) => Message.fromJson(data)).toList();
      } else {
        throw Exception('Erreur lors de la recherche: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur lors de la recherche de messages: $e');
      rethrow;
    }
  }

  /// Récupère toutes les conversations de l'utilisateur
  Future<List<Conversation>> getConversations() async {
    try {
      // Suppression du préfixe /api/ pour éviter la duplication avec l'URL de base qui contient déjà /api
      final response = await _dio.get('/messages/conversations');
      
      if (response.statusCode == 200 || response.statusCode == 304) {
        final data = response.data;
        if (data == null) {
          return [];
        }

        // Extraire la liste des conversations
        final List conversationsList = data['data'] as List? ?? [];

        // Convertir chaque conversation au format attendu
        return conversationsList.map((json) {
          // Adapter le format de l'API à notre modèle
          final adaptedJson = {
            'id': json['_id'],
            'participants': (json['participants'] as List?)?.map((p) => {
              'id': p['_id'],
              'name': p['name'] ?? 'Utilisateur',
              'role': p['role'] ?? 'user',
              'isActive': p['isActive'] ?? true,
            }).toList() ?? [],
            'unreadCount': json['unreadCount'] ?? 0,
            'createdAt': json['createdAt'],
            'updatedAt': json['updatedAt'],
            'residenceId': json['residenceId']?['_id'] ?? '',
            'residenceName': json['residenceId']?['name'] ?? '',
          };

          // Adapter le lastMessage s'il existe
          if (json['lastMessage'] != null) {
            adaptedJson['lastMessage'] = {
              'id': json['lastMessage']['_id'],
              'conversationId': json['_id'],
              'content': json['lastMessage']['content'] ?? '',
              'senderId': json['lastMessage']['sender'],
              'senderName': 'Utilisateur', // Valeur par défaut
              'timestamp': json['lastMessage']['createdAt'],
              'read': json['lastMessage']['read'] ?? false,
              'attachments': (json['lastMessage']['attachments'] as List?)?.map((a) => {
                'id': a['_id'] ?? '',
                'url': a['url'] ?? '',
                'type': a['type'] ?? 'file',
                'name': a['name'],
                'size': a['size'] ?? 0,
              }).toList() ?? []
            };
          }

          return Conversation.fromJson(adaptedJson);
        }).toList();
      } else {
        throw Exception('Erreur lors du chargement des conversations: Status ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.d('Exception détaillée: $e');
      AppLogger.d('Stack trace: $stackTrace');
      throw Exception('Erreur lors du chargement des conversations: $e');
    }
  }

  /// Récupère tous les messages de toutes les conversations
  Future<List<Message>> getAllMessages() async {
    try {
      // D'abord récupérer toutes les conversations
      final conversations = await getConversations();
      
      // Ensuite récupérer tous les messages de chaque conversation
      final allMessages = <Message>[];
      for (final conversation in conversations) {
        try {
          final messages = await getMessages(conversation.id);
          allMessages.addAll(messages);
        } catch (e) {
          AppLogger.d('Erreur lors de la récupération des messages pour la conversation ${conversation.id}: $e');
          // Continuer avec la prochaine conversation même si celle-ci échoue
        }
      }
      
      return allMessages;
    } catch (e) {
      AppLogger.d('Erreur lors de la récupération de tous les messages: $e');
      return [];
    }
  }

  /// Crée une nouvelle conversation
  Future<Conversation> createConversation({
    required List<String> participants, 
    String? title, 
    String? reservationId,
    String? initialMessage
  }) async {
    try {
      final response = await _dio.post(
        '/messages/conversations',
        data: {
          'participants': participants,
          if (title != null) 'title': title,
          if (reservationId != null) 'reservationId': reservationId,
          if (initialMessage != null) 'initialMessage': initialMessage,
        },
      );
      
      // Adapter le format de la réponse pour inclure residenceId et residenceName
      final data = response.data['data'];
      final adaptedData = {
        ...data as Map<String, dynamic>,
        'residenceId': data['residenceId']?['_id'] ?? '',
        'residenceName': data['residenceId']?['name'] ?? '',
      };
      
      return Conversation.fromJson(adaptedData);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Récupère une conversation
  Future<Conversation?> getConversation(String conversationId) async {
    try {
      final response = await _dio.get('/api/messages/conversations/$conversationId');
      final data = response.data['data'];
      
      // Adapter le format de la réponse pour inclure residenceId et residenceName
      final adaptedData = {
        ...data as Map<String, dynamic>,
        'residenceId': data['residenceId']?['_id'] ?? '',
        'residenceName': data['residenceId']?['name'] ?? '',
      };
      
      return Conversation.fromJson(adaptedData);
    } catch (e) {
      return null;
    }
  }

  /// Envoie un nouveau message
  Future<Message> sendMessage(String conversationId, String content, {List<MessageAttachment>? attachments}) async {
    try {
      final response = await _dio.post(
        '/messages/conversations/$conversationId/messages',
        data: {
          'content': content,
          if (attachments != null && attachments.isNotEmpty)
            'attachments': attachments.map((a) => {
              '_id': a.id,
              'type': a.type,
              'url': a.url,
              'name': a.name,
              'size': a.size,
            }).toList(),
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        final messageData = response.data['data'];
        return Message(
          id: messageData['_id'] ?? '',
          conversationId: messageData['conversation'] ?? conversationId,
          content: messageData['content'] ?? '',
          senderId: messageData['sender']?['_id'] ?? '',
          senderName: messageData['sender']?['name'] ?? 'Utilisateur',
          senderAvatar: messageData['sender']?['avatar'],
          timestamp: DateTime.parse(messageData['createdAt']),
          read: messageData['read'] ?? false,
          attachments: (messageData['attachments'] as List?)?.map((a) => MessageAttachment(
            id: a['_id'] ?? '',
            url: a['url'] ?? '',
            type: a['type'] ?? 'file',
            name: a['name'],
            size: a['size'] ?? 0,
          )).toList() ?? [],
        );
      }

      throw Exception('Erreur lors de l\'envoi du message');
    } catch (e) {
      AppLogger.d('Erreur détaillée lors de l\'envoi du message: $e');
      throw Exception('Erreur lors de l\'envoi du message');
    }
  }

  /// Récupère les messages d'une conversation
  Future<List<Message>> getMessages(String conversationId, {int? page, int? limit}) async {
    try {
      final response = await _dio.get(
        '/messages/conversations/$conversationId/messages',
        queryParameters: {
          if (page != null) 'page': page,
          if (limit != null) 'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data == null) return [];
        
        if (data is List) {
          return data.map((messageData) => Message(
            id: messageData['_id'] ?? '',
            conversationId: messageData['conversation'] ?? conversationId,
            content: messageData['content'] ?? '',
            senderId: messageData['sender']?['_id'] ?? '',
            senderName: messageData['sender']?['name'] ?? 'Utilisateur',
            senderAvatar: messageData['sender']?['avatar'],
            timestamp: DateTime.parse(messageData['createdAt']),
            read: messageData['read'] ?? false,
            attachments: (messageData['attachments'] as List?)?.map((a) => MessageAttachment(
              id: a['_id'] ?? '',
              url: a['url'] ?? '',
              type: a['type'] ?? 'file',
              name: a['name'],
              size: a['size'] ?? 0,
            )).toList() ?? [],
            reservationId: messageData['reservationId'],
            reservationStatus: messageData['reservationStatus'],
            metadata: messageData['metadata'] as Map<String, dynamic>?,
          )).toList();
        }
      }
      return [];
    } catch (e) {
      AppLogger.d('Erreur lors de la récupération des messages: $e');
      throw Exception('Erreur lors de la récupération des messages');
    }
  }

  /// Upload un fichier pour une conversation avec support Cloudinary
  Future<MessageAttachment> uploadAttachment(String conversationId, String filePath, {String? name}) async {
    try {
      AppLogger.d('⬆️ Début de l\'upload de pièce jointe pour la conversation $conversationId');
      AppLogger.d('☁️ Mode Cloudinary: ${FeatureFlags.useCloudinary ? 'Activé' : 'Désactivé'}');
      
      // Si Cloudinary est activé, utiliser l'upload direct
      if (FeatureFlags.useCloudinary) {
        try {
          AppLogger.d('☁️ Utilisation de Cloudinary pour l\'upload de pièce jointe');
          
          // Initialiser le service Cloudinary
          final cloudinaryService = CloudinaryService();
          
          // Préparer le fichier pour l'upload
          dynamic fileContent;
          String fileName = name ?? 'attachment.jpg';
          
          if (kIsWeb) {
            // Pour le web, on utilise les données brutes du fichier
            AppLogger.d('🖥️ Web: Décodage des données base64');
            fileContent = base64Decode(filePath.split(',').last);
            // Essayer de déterminer le type de fichier depuis les données base64
            if (filePath.startsWith('data:')) {
              final mimeType = filePath.split(',')[0].split(':')[1].split(';')[0];
              if (mimeType.isNotEmpty) {
                final ext = mimeType.split('/').last;
                fileName = name ?? 'attachment.$ext';
              }
            }
          } else {
            // Pour mobile/desktop, utiliser le chemin du fichier
            AppLogger.d('📱 Mobile: Préparation du fichier $filePath');
            fileContent = filePath; // Le service Cloudinary peut gérer les chemins de fichier
            fileName = name ?? filePath.split('/').last;
          }
          
          // Upload vers Cloudinary
          final String cloudinaryUrl = await cloudinaryService.uploadImage(
            fileContent,
            folder: 'chapechape/messages/$conversationId',
          );
          
          AppLogger.d('☁️ Fichier uploadé sur Cloudinary: $cloudinaryUrl');
          
          // Envoyer l'URL Cloudinary au backend
          final attachmentResponse = await _dio.post(
            '/messages/conversations/$conversationId/attachments',
            data: {
              'fileUrl': cloudinaryUrl,
              'fileName': fileName,
              'fileType': _getFileType(fileName),
            },
            options: Options(
              headers: {
                'Content-Type': 'application/json',
              },
            ),
          );
          
          if (attachmentResponse.statusCode == 201 && attachmentResponse.data['success'] == true) {
            final attachmentData = attachmentResponse.data['data']['attachments']?[0];
            if (attachmentData == null) {
              throw Exception('Aucune pièce jointe dans la réponse');
            }
            
            AppLogger.d('✅ Pièce jointe enregistrée avec succès via Cloudinary');
            
            return MessageAttachment(
              id: attachmentData['_id'] ?? '',
              url: attachmentData['url'] ?? cloudinaryUrl, // Utiliser l'URL Cloudinary si pas d'URL retournée
              type: attachmentData['type'] ?? _getFileType(fileName),
              name: attachmentData['name'] ?? fileName,
              size: attachmentData['size'] ?? 0,
            );
          } else {
            throw Exception('Erreur lors de l\'enregistrement de la pièce jointe');
          }
        } catch (cloudinaryError) {
          AppLogger.d('☁️❌ Erreur Cloudinary: $cloudinaryError');
          AppLogger.d('🔄 Retour à la méthode traditionnelle d\'upload');
          // En cas d'erreur avec Cloudinary, revenir à la méthode traditionnelle
        }
      }
      
      // Méthode traditionnelle (multipart/form-data)
      AppLogger.d('💾 Utilisation de la méthode traditionnelle d\'upload');
      FormData formData;
      
      if (kIsWeb) {
        // Pour le web, on utilise les données brutes du fichier
        formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            base64Decode(filePath.split(',').last),
            filename: name ?? 'file.jpg',
          ),
        });
      } else {
        // Pour mobile/desktop
        formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            filePath,
            filename: name ?? filePath.split('/').last,
          ),
        });
      }

      final response = await _dio.post(
        '/messages/conversations/$conversationId/attachments',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        final attachmentData = response.data['data']['attachments']?[0];
        if (attachmentData == null) {
          throw Exception('Aucune pièce jointe dans la réponse');
        }
        
        AppLogger.d('✅ Pièce jointe enregistrée avec succès via méthode traditionnelle');
        
        return MessageAttachment(
          id: attachmentData['_id'] ?? '',
          url: attachmentData['url'] ?? '',
          type: attachmentData['type'] ?? 'file',
          name: attachmentData['name'],
          size: attachmentData['size'] ?? 0,
        );
      }
      throw Exception('Erreur lors de l\'upload du fichier');
    } catch (e) {
      AppLogger.d('Erreur détaillée lors de l\'upload: $e');
      throw Exception('Erreur lors de l\'upload du fichier');
    }
  }

  /// Détermine le type de fichier en fonction de l'extension
  String _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return 'image';
      case 'pdf':
        return 'pdf';
      case 'doc':
      case 'docx':
        return 'document';
      case 'mp4':
      case 'mov':
      case 'avi':
        return 'video';
      case 'mp3':
      case 'wav':
      case 'ogg':
        return 'audio';
      default:
        return 'file';
    }
  }

  /// Marque une conversation comme lue
  Future<void> markAsRead(String conversationId) async {
    try {
      await _dio.patch('/messages/conversations/$conversationId/read');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      final response = error.response;
      if (response != null) {
        final data = response.data;
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          return Exception(data['message']);
        }
      }
      return Exception(error.message);
    }
    return Exception('Une erreur est survenue');
  }
}
