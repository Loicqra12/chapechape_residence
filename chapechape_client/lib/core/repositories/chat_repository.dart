import '../models/chat_model.dart';
import '../services/chat_service.dart';

class ChatRepository {
  final ChatService _chatService;

  ChatRepository._({
    required ChatService chatService,
  }) : _chatService = chatService;

  static Future<ChatRepository> initialize() async {
    final chatService = await ChatService.initialize();
    return ChatRepository._(chatService: chatService);
  }

  // Getter pour le service
  ChatService get chatService => _chatService;
  
  // Récupérer les conversations
  Future<List<ChatConversation>> getConversations() async {
    return await _chatService.getConversations();
  }
  
  // Récupérer les messages d'une conversation
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    return await _chatService.getMessages(conversationId);
  }
  
  // Envoyer un message
  Future<ChatMessage?> sendMessage(String conversationId, String content) async {
    return await _chatService.sendMessage(conversationId, content);
  }
  
  // Marquer un message comme lu
  Future<bool> markMessageAsRead(String messageId) async {
    return await _chatService.markMessageAsRead(messageId);
  }
  
  // Marquer tous les messages d'une conversation comme lus
  Future<bool> markAllAsRead(String conversationId) async {
    return await _chatService.markAllAsRead(conversationId);
  }
  
  // Créer une nouvelle conversation
  Future<ChatConversation?> createConversation(String recipientId) async {
    return await _chatService.createConversation(recipientId);
  }
}