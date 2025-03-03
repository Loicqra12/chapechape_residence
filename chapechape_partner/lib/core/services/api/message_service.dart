import 'dart:async';
import 'package:dio/dio.dart';
import '../../models/message/message.dart';
import 'api_service.dart';

class MessageService {
  final ApiService _apiService;
  final _mockMessages = <Message>[];
  Timer? _mockMessageTimer;

  MessageService(this._apiService) {
    // Simulation de messages pour le test
    _mockMessages.addAll([
      Message(
        id: '1',
        senderId: 'client_1',
        receiverId: 'partner_1',
        receiverName: 'John Doe',
        receiverRole: 'client',
        content: 'Bonjour, je suis intéressé par votre résidence',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Message(
        id: '2',
        senderId: 'partner_1',
        receiverId: 'client_1',
        receiverName: 'John Doe',
        receiverRole: 'client',
        content: 'Bonjour ! Bien sûr, je peux vous donner plus d\'informations',
        timestamp: DateTime.now().subtract(const Duration(hours: 23)),
      ),
      Message(
        id: '3',
        senderId: 'client_1',
        receiverId: 'partner_1',
        receiverName: 'John Doe',
        receiverRole: 'client',
        content: 'Quel est le prix par nuit ?',
        timestamp: DateTime.now().subtract(const Duration(hours: 22)),
      ),
    ]);

    // Simulation de nouveaux messages
    _startMockMessageTimer();
  }

  void _startMockMessageTimer() {
    _mockMessageTimer?.cancel();
    _mockMessageTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final mockClientMessages = [
        'Est-ce que la résidence est disponible le mois prochain ?',
        'Y a-t-il une piscine ?',
        'Combien de chambres y a-t-il ?',
        'Le wifi est-il inclus ?',
        'Y a-t-il un parking ?',
      ];

      final randomMessage = mockClientMessages[DateTime.now().second % mockClientMessages.length];
      
      _mockMessages.add(Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'client_1',
        receiverId: 'partner_1',
        receiverName: 'John Doe',
        receiverRole: 'client',
        content: randomMessage,
        timestamp: DateTime.now(),
      ));
    });
  }

  void dispose() {
    _mockMessageTimer?.cancel();
  }

  Future<List<Message>> getMessages(String userId) async {
    // En production, nous utiliserions l'API
    // try {
    //   final response = await _apiService.dio.get('/messages/$userId');
    //   final List<dynamic> data = response.data['messages'];
    //   return data.map((json) => Message.fromJson(json)).toList();
    // } catch (e) {
    //   throw _handleError(e);
    // }

    // Pour le test, on retourne les messages simulés
    await Future.delayed(const Duration(milliseconds: 500)); // Simulation de latence
    return _mockMessages.where((m) => 
      m.senderId == userId || m.receiverId == userId
    ).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<Message> sendMessage(Message message) async {
    // En production, nous utiliserions l'API
    // try {
    //   final response = await _apiService.dio.post(
    //     '/messages',
    //     data: message.toJson(),
    //   );
    //   return Message.fromJson(response.data['message']);
    // } catch (e) {
    //   throw _handleError(e);
    // }

    // Pour le test, on ajoute le message à notre liste simulée
    await Future.delayed(const Duration(milliseconds: 300)); // Simulation de latence
    _mockMessages.add(message);

    // Simulation d'une réponse automatique du client
    Timer(const Duration(seconds: 2), () {
      final responses = [
        'D\'accord, merci pour l\'information !',
        'Je vais y réfléchir.',
        'Pouvez-vous m\'en dire plus ?',
        'C\'est parfait !',
        'Je comprends.',
      ];

      final randomResponse = responses[DateTime.now().second % responses.length];
      
      _mockMessages.add(Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'client_1',
        receiverId: 'partner_1',
        receiverName: message.receiverName,
        receiverRole: 'client',
        content: randomResponse,
        timestamp: DateTime.now(),
      ));
    });

    return message;
  }

  Future<void> markMessageAsRead(String messageId) async {
    // En production, nous utiliserions l'API
    // try {
    //   await _apiService.dio.patch(
    //     '/messages/$messageId/read',
    //   );
    // } catch (e) {
    //   throw _handleError(e);
    // }

    // Pour le test, on marque le message comme lu dans notre liste simulée
    await Future.delayed(const Duration(milliseconds: 200)); // Simulation de latence
    final index = _mockMessages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _mockMessages[index] = _mockMessages[index].copyWith(isRead: true);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      final response = error.response;
      if (response != null) {
        final message = response.data['message'] ?? 'Une erreur est survenue';
        return Exception(message);
      }
    }
    return Exception('Une erreur est survenue lors de la communication avec le serveur');
  }
}
