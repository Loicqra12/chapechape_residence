import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config_manager.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final _storage = const FlutterSecureStorage();
  bool _isConnected = false;
  String? _userId;

  // Callbacks
  Function(Map<String, dynamic>)? onNewMessage;
  
  // Initialisation du service
  Future<void> initialize() async {
    if (_socket != null) {
      _socket!.disconnect();
    }

    final baseUrl = AppConfigManager.apiBaseUrl;
    _userId = await _storage.read(key: 'userId');

    try {
      debugPrint('🔌 Initialisation Socket.io avec URL: $baseUrl');
      _socket = IO.io(baseUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build());

      _setupListeners();
      _socket!.connect();

      debugPrint('🔌 Socket.io initialisé avec succès');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation de Socket.io: $e');
    }
  }

  // Configuration des écouteurs d'événements
  void _setupListeners() {
    _socket!.on('connect', (_) {
      debugPrint('🔌 Socket connecté');
      _isConnected = true;
      
      // S'authentifier si l'ID utilisateur est disponible
      if (_userId != null) {
        _socket!.emit('auth_user', _userId);
        debugPrint('🔑 Utilisateur authentifié: $_userId');
      }
    });

    _socket!.on('disconnect', (_) {
      debugPrint('🔌 Socket déconnecté');
      _isConnected = false;
    });

    _socket!.on('error', (error) {
      debugPrint('❌ Erreur socket: $error');
    });

    // Événement de nouveau message
    _socket!.on('new_message', (data) {
      debugPrint('📩 Nouveau message reçu via WebSocket: ${data.toString()}');
      if (onNewMessage != null) {
        onNewMessage!(data);
      }
    });
  }

  // Rejoindre une conversation
  void joinConversation(String conversationId) {
    if (_isConnected && conversationId.isNotEmpty) {
      _socket!.emit('join_conversation', conversationId);
      debugPrint('🔌 Conversation rejointe: $conversationId');
    }
  }

  // Quitter une conversation
  void leaveConversation(String conversationId) {
    if (_isConnected && conversationId.isNotEmpty) {
      _socket!.emit('leave_conversation', conversationId);
      debugPrint('🔌 Conversation quittée: $conversationId');
    }
  }

  // Déconnexion
  void disconnect() {
    _socket?.disconnect();
    _isConnected = false;
    debugPrint('🔌 Socket déconnecté manuellement');
  }

  bool get isConnected => _isConnected;
}
