import 'package:dio/dio.dart';
import '../models/chat_model.dart';
import 'api_service.dart';

class ChatService {
  final ApiService _apiService;

  ChatService._({
    required ApiService apiService,
  }) : _apiService = apiService;

  static Future<ChatService> initialize() async {
    final apiService = await ApiService.initialize();
    return ChatService._(apiService: apiService);
  }

  // Récupérer les conversations de l'utilisateur
  Future<List<ChatConversation>> getConversations() async {
    try {
      // Comme nous n'avons pas trouvé d'endpoint spécifique pour les messages/chat dans le backend,
      // nous allons utiliser des données fictives pour le moment
      // Dans une implémentation réelle, vous appelleriez l'API comme ceci:
      // final response = await _apiService.get('/api/messages/conversations');
      
      await Future.delayed(const Duration(milliseconds: 500)); // Simuler un délai réseau
      
      return _getMockConversations();
    } on DioException catch (e) {
      print('Erreur lors de la récupération des conversations: ${e.message}');
      return [];
    }
  }
  
  // Récupérer les messages d'une conversation
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    try {
      // Dans une implémentation réelle, vous appelleriez l'API comme ceci:
      // final response = await _apiService.get('/api/messages/conversations/$conversationId');
      
      await Future.delayed(const Duration(milliseconds: 500)); // Simuler un délai réseau
      
      return _getMockMessages(conversationId);
    } on DioException catch (e) {
      print('Erreur lors de la récupération des messages: ${e.message}');
      return [];
    }
  }
  
  // Envoyer un message
  Future<ChatMessage?> sendMessage(String conversationId, String content) async {
    try {
      // Dans une implémentation réelle, vous appelleriez l'API comme ceci:
      // final response = await _apiService.post(
      //   '/api/messages',
      //   data: {
      //     'conversationId': conversationId,
      //     'content': content,
      //   },
      // );
      
      await Future.delayed(const Duration(milliseconds: 300)); // Simuler un délai réseau
      
      // Créer un message fictif
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'user1', // ID de l'utilisateur actuel
        content: content,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
      );
    } on DioException catch (e) {
      print('Erreur lors de l\'envoi du message: ${e.message}');
      return null;
    }
  }
  
  // Marquer un message comme lu
  Future<bool> markMessageAsRead(String messageId) async {
    try {
      final response = await _apiService.patch(
        '/api/messages/$messageId/read',
        data: {'read': true},
      );
      
      if (response.data['success'] != true) {
        throw Exception('Erreur lors du marquage du message comme lu');
      }
      
      return true;
    } on DioException catch (e) {
      print('Erreur lors du marquage du message comme lu: ${e.message}');
      return false;
    }
  }
  
  // Marquer tous les messages d'une conversation comme lus
  Future<bool> markAllAsRead(String conversationId) async {
    try {
      // Dans une implémentation réelle, vous appelleriez l'API comme ceci:
      // final response = await _apiService.put('/api/messages/conversations/$conversationId/read-all');
      
      await Future.delayed(const Duration(milliseconds: 200)); // Simuler un délai réseau
      
      return true;
    } on DioException catch (e) {
      print('Erreur lors du marquage de tous les messages: ${e.message}');
      return false;
    }
  }
  
  // Créer une nouvelle conversation
  Future<ChatConversation?> createConversation(String recipientId) async {
    try {
      // Dans une implémentation réelle, vous appelleriez l'API comme ceci:
      // final response = await _apiService.post(
      //   '/api/messages/conversations',
      //   data: {
      //     'recipientId': recipientId,
      //   },
      // );
      
      await Future.delayed(const Duration(milliseconds: 300)); // Simuler un délai réseau
      
      // Créer une conversation fictive
      return ChatConversation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        participants: [
          ChatParticipant(id: 'user1', name: 'Vous'),
          ChatParticipant(id: recipientId, name: 'Agent Immobilier'),
        ],
        lastMessage: null,
        unreadCount: 0,
        updatedAt: DateTime.now(),
        isArchived: false,
      );
    } on DioException catch (e) {
      print('Erreur lors de la création de la conversation: ${e.message}');
      return null;
    }
  }
  
  // Données fictives pour les conversations
  List<ChatConversation> _getMockConversations() {
    return [
      ChatConversation(
        id: '1',
        participants: [
          ChatParticipant(id: 'user1', name: 'Vous'),
          ChatParticipant(id: 'agent1', name: 'Agent Immobilier', avatarUrl: 'assets/images/agent1.jpg'),
        ],
        lastMessage: ChatMessage(
          id: 'm1',
          senderId: 'agent1',
          content: 'Bonjour, je suis disponible pour répondre à vos questions sur la résidence Cocody.',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          status: MessageStatus.read,
        ),
        unreadCount: 0,
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        isArchived: false,
      ),
      ChatConversation(
        id: '2',
        participants: [
          ChatParticipant(id: 'user1', name: 'Vous'),
          ChatParticipant(id: 'agent2', name: 'Support Client', avatarUrl: 'assets/images/agent2.jpg'),
        ],
        lastMessage: ChatMessage(
          id: 'm2',
          senderId: 'agent2',
          content: 'Votre réservation a été confirmée. N\'hésitez pas si vous avez des questions.',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          status: MessageStatus.delivered,
        ),
        unreadCount: 1,
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        isArchived: false,
      ),
    ];
  }
  
  // Données fictives pour les messages
  List<ChatMessage> _getMockMessages(String conversationId) {
    if (conversationId == '1') {
      return [
        ChatMessage(
          id: 'm1-1',
          senderId: 'agent1',
          content: 'Bonjour, je suis l\'agent immobilier responsable de la résidence Cocody. Comment puis-je vous aider?',
          timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'm1-2',
          senderId: 'user1',
          content: 'Bonjour, je suis intéressé par cette résidence. Est-elle disponible pour le mois prochain?',
          timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 45)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'm1-3',
          senderId: 'agent1',
          content: 'Oui, la résidence est disponible à partir du 15 du mois prochain. Souhaitez-vous la visiter?',
          timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 30)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'm1-4',
          senderId: 'user1',
          content: 'Ce serait parfait. Quels sont les horaires de visite possibles?',
          timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'm1-5',
          senderId: 'agent1',
          content: 'Nous pouvons organiser une visite du lundi au samedi, de 9h à 17h. Quelle date vous conviendrait?',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          status: MessageStatus.read,
        ),
      ];
    } else if (conversationId == '2') {
      return [
        ChatMessage(
          id: 'm2-1',
          senderId: 'agent2',
          content: 'Bonjour, je suis du service client. Bienvenue sur ChapeChape Residence!',
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'm2-2',
          senderId: 'user1',
          content: 'Merci! J\'ai une question concernant le processus de réservation.',
          timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 12)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'm2-3',
          senderId: 'agent2',
          content: 'Bien sûr, je serais ravi de vous aider. Que souhaitez-vous savoir?',
          timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 11)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'm2-4',
          senderId: 'user1',
          content: 'Comment puis-je modifier une réservation déjà confirmée?',
          timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 10)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'm2-5',
          senderId: 'agent2',
          content: 'Vous pouvez modifier votre réservation jusqu\'à 48h avant la date d\'arrivée. Allez dans "Mes réservations" et cliquez sur "Modifier".',
          timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'm2-6',
          senderId: 'agent2',
          content: 'Votre réservation a été confirmée. N\'hésitez pas si vous avez des questions.',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          status: MessageStatus.delivered,
        ),
      ];
    }
    return [];
  }
}