import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chapechape_client/core/utils/secure_storage.dart';
import '../models/chat_model.dart';
import '../services/api_service.dart';

class ChatService {
  final ApiService _apiService;
  final _storage = AppSecureStorage.instance;

  ChatService({required ApiService apiService}) : _apiService = apiService;

  Future<List<ChatConversation>> getConversations() async {
    try {
      // Vérifier si nous avons un token
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      debugPrint('Token found, fetching conversations...');
      final response = await _apiService.get('/messages/conversations');
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');
      
      if (response.statusCode == 200) {
        final jsonData = response.data['data'] as List? ?? [];
        
        return jsonData.map((conversationJson) {
          // Adapter le format de la réponse API au modèle ChatConversation
          final adaptedJson = {
            'id': conversationJson['_id'] ?? '',
            'participants': (conversationJson['participants'] as List? ?? []).map((participant) => {
              'id': participant['_id'] ?? '',
              'name': participant['name'] ?? 'Utilisateur',
              'avatarUrl': participant['avatar'],
              'role': participant['role'] ?? 'user',
            }).toList(),
            'messages': [],
            'residenceId': conversationJson['residenceId']?['_id'] ?? '',
            'residenceName': conversationJson['residenceId']?['name'] ?? '',
            'reservationId': conversationJson['reservationId']?['_id'] ?? '',
            'isUnread': conversationJson['unreadCount'] > 0,
            'createdAt': conversationJson['createdAt'] ?? DateTime.now().toIso8601String(),
            'updatedAt': conversationJson['updatedAt'] ?? DateTime.now().toIso8601String(),
          };
          
          return ChatConversation.fromJson(adaptedJson);
        }).toList();
      } else {
        debugPrint('Error fetching conversations: ${response.statusCode}');
        throw Exception('Failed to load conversations');
      }
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
      throw Exception('Failed to load conversations: ${e.toString()}');
    }
  }

  Future<ChatConversation> getConversation(String id) async {
    try {
      // Vérifier si nous avons un token
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      debugPrint('Token found, fetching conversation $id...');
      final response = await _apiService.get('/messages/conversations/$id');
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');
      final data = response.data['data'];
      final adaptedJson = {
        'id': data['_id'],
        'participants': (data['participants'] as List?)?.map((p) => {
          'id': p['_id'],
          'name': p['name'] ?? 'Utilisateur',
          'role': p['role'] ?? 'user',
        }).toList() ?? [],
        'createdAt': data['createdAt'],
        'updatedAt': data['updatedAt'],
        'messages': [],
      };
      return ChatConversation.fromJson(adaptedJson);
    } catch (e) {
      debugPrint('Error fetching conversation: $e');
      throw Exception('Failed to load conversation: ${e.toString()}');
    }
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    try {
      // Vérifier si nous avons un token
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      debugPrint('Token found, fetching messages for conversation $conversationId...');
      final response = await _apiService.get('/messages/conversations/$conversationId/messages');
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');
      
      // Corriger l'accès aux données - la réponse est un objet avec des messages et pagination
      final data = response.data['data'];
      final messages = data['messages'] as List? ?? [];
      
      return messages.map((messageData) => ChatMessage(
        id: messageData['_id'] ?? '',
        conversationId: messageData['conversation'] ?? conversationId,
        content: messageData['content'] ?? '',
        senderId: messageData['sender']?['_id'] ?? '',
        createdAt: DateTime.parse(messageData['createdAt']),
        isRead: messageData['read'] ?? false,
      )).toList();
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      throw Exception('Failed to load messages: ${e.toString()}');
    }
  }

  Future<ChatConversation> createConversation({
    required String userId,
    String? residenceId,
    String? reservationId,
  }) async {
    try {
      // Vérifier si nous avons un token
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      debugPrint('Token found, creating conversation...');
      
      final response = await _apiService.post(
        '/messages/conversations',
        data: {
          'participants': [userId],
          'residenceId': residenceId,
          'reservationId': reservationId,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ChatConversation.fromJson(response.data);
      } else {
        debugPrint('Error creating conversation: ${response.statusCode}');
        throw Exception('Failed to create conversation');
      }
    } catch (e) {
      // Vérifier si l'erreur est liée à l'activation de la messagerie
      if (e.toString().contains('messagerie n\'est pas encore activée') || 
          e.toString().contains('paiement doit être effectué')) {
        throw Exception('La messagerie n\'est pas activée pour cette réservation. Veuillez effectuer le paiement pour débloquer cette fonctionnalité.');
      }
      
      debugPrint('Error creating conversation: $e');
      throw Exception('Failed to create conversation: ${e.toString()}');
    }
  }

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    try {
      // Vérifier si nous avons un token
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      debugPrint('Token found, sending message...');
      
      final response = await _apiService.post(
        '/messages/conversations/$conversationId/messages',
        data: {
          'content': content,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final messageData = response.data['data'];
        return ChatMessage(
          id: messageData['_id'] ?? '',
          conversationId: conversationId,
          content: messageData['content'] ?? '',
          senderId: messageData['sender']['_id'] ?? '',
          createdAt: DateTime.parse(messageData['createdAt']),
          isRead: messageData['read'] ?? false,
          type: 'text',
        );
      } else {
        debugPrint('Error sending message: ${response.statusCode}');
        throw Exception('Failed to send message');
      }
    } catch (e) {
      // Vérifier si l'erreur est liée à l'activation de la messagerie
      if (e.toString().contains('messagerie n\'est pas encore activée') || 
          e.toString().contains('paiement doit être effectué')) {
        throw Exception('La messagerie n\'est pas activée pour cette conversation. Veuillez effectuer le paiement pour débloquer cette fonctionnalité.');
      }
      
      debugPrint('Error sending message: $e');
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  Future<ChatMessage> sendFile({
    required String conversationId,
    required String filePath,
    String? type,
  }) async {
    try {
      // Vérifier si nous avons un token
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      debugPrint('Token found, sending file...');
      final file = File(filePath);
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'conversationId': conversationId,
        'type': type,
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _apiService.post(
        '/messages/files',
        data: formData,
      );
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');
      return ChatMessage.fromJson(response.data);
    } catch (e) {
      // Vérifier si l'erreur est liée à l'activation de la messagerie
      if (e.toString().contains('messagerie n\'est pas encore activée') || 
          e.toString().contains('paiement doit être effectué')) {
        throw Exception('La messagerie n\'est pas activée pour cette conversation. Veuillez effectuer le paiement pour débloquer cette fonctionnalité.');
      }
      
      debugPrint('Error sending file: $e');
      throw Exception('Failed to send file: ${e.toString()}');
    }
  }

  Future<ChatMessage> sendImage({
    required String conversationId,
    required String imagePath,
  }) async {
    try {
      // Vérifier si nous avons un token
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      debugPrint('Token found, sending image...');
      final file = File(imagePath);
      final fileName = imagePath.split('/').last;
      final formData = FormData.fromMap({
        'conversationId': conversationId,
        'type': 'image',
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _apiService.post(
        '/messages/images',
        data: formData,
      );
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');
      return ChatMessage.fromJson(response.data);
    } catch (e) {
      debugPrint('Error sending image: $e');
      throw Exception('Failed to send image: ${e.toString()}');
    }
  }

  Future<void> markAsRead(String messageId) async {
    try {
      // Vérifier si nous avons un token
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      debugPrint('Token found, marking message as read...');
      await _apiService.patch(
        '/messages/$messageId/read',
      );
      debugPrint('Message marked as read');
    } catch (e) {
      debugPrint('Error marking message as read: $e');
      throw Exception('Failed to mark message as read: ${e.toString()}');
    }
  }

  Future<void> markAllAsRead(String conversationId) async {
    try {
      // Vérifier si nous avons un token
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      debugPrint('Token found, marking all messages as read...');
      await _apiService.patch(
        '/messages/conversations/$conversationId/read',
      );
      debugPrint('All messages marked as read');
    } catch (e) {
      debugPrint('Error marking all messages as read: $e');
      throw Exception('Failed to mark all messages as read: ${e.toString()}');
    }
  }
}