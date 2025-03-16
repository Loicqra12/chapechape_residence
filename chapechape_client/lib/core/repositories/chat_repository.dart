import 'package:dio/dio.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import '../services/api_service.dart';

class ChatRepository {
  final ChatService _chatService;

  ChatRepository({required ApiService apiService})
      : _chatService = ChatService(apiService: apiService);

  static Future<ChatRepository> initialize() async {
    final apiService = await ApiService.initialize();
    return ChatRepository(apiService: apiService);
  }

  Future<List<ChatConversation>> getConversations() async {
    return await _chatService.getConversations();
  }

  Future<ChatConversation> getConversation(String id) async {
    return await _chatService.getConversation(id);
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    return await _chatService.getMessages(conversationId);
  }

  Future<ChatConversation> createConversation({
    required String userId,
    String? residenceId,
    String? bookingId,
  }) async {
    return await _chatService.createConversation(
      userId: userId,
      residenceId: residenceId,
      bookingId: bookingId,
    );
  }

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    return await _chatService.sendMessage(
      conversationId: conversationId,
      content: content,
    );
  }

  Future<ChatMessage> sendFile({
    required String conversationId,
    required String filePath,
    String? type,
  }) async {
    return await _chatService.sendFile(
      conversationId: conversationId,
      filePath: filePath,
      type: type,
    );
  }

  Future<ChatMessage> sendImage({
    required String conversationId,
    required String imagePath,
  }) async {
    return await _chatService.sendImage(
      conversationId: conversationId,
      imagePath: imagePath,
    );
  }

  Future<void> markMessageAsRead({
    required String messageId,
    required String conversationId,
  }) async {
    await _chatService.markAsRead(messageId);
  }

  Future<void> markAllMessagesAsRead(String conversationId) async {
    await _chatService.markAllAsRead(conversationId);
  }
}