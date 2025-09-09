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
  Function(Map<String, dynamic>)? onBookingStatusUpdated;
  Function(Map<String, dynamic>)? onBookingExpired;
  Function(Map<String, dynamic>)? onBookingApproved;
  Function(Map<String, dynamic>)? onBookingRejected;
  
  // Initialisation du service
  Future<void> initialize() async {
    if (_socket != null) {
      _socket!.disconnect();
    }

    // Utiliser directement l'URL de base du serveur pour Socket.IO (sans /api)
    final socketUrl = AppConfigManager.apiBaseUrl;
    _userId = await _storage.read(key: 'userId');

    try {
      debugPrint('🔌 Initialisation Socket.io avec URL: $socketUrl');
      _socket = IO.io(socketUrl, IO.OptionBuilder()
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

    // Événements de réservation temps réel
    _socket!.on('booking_status_updated', (data) {
      debugPrint('🔄 Statut de réservation mis à jour via WebSocket: ${data.toString()}');
      if (onBookingStatusUpdated != null) {
        onBookingStatusUpdated!(data);
      }
    });

    _socket!.on('booking_expired', (data) {
      debugPrint('⏰ Réservation expirée via WebSocket: ${data.toString()}');
      if (onBookingExpired != null) {
        onBookingExpired!(data);
      }
    });

    _socket!.on('booking_approved', (data) {
      debugPrint('✅ Réservation approuvée via WebSocket: ${data.toString()}');
      if (onBookingApproved != null) {
        onBookingApproved!(data);
      }
    });

    _socket!.on('booking_rejected', (data) {
      debugPrint('❌ Réservation rejetée via WebSocket: ${data.toString()}');
      if (onBookingRejected != null) {
        onBookingRejected!(data);
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

  // Rejoindre une salle de réservation pour écouter les transitions
  void joinBookingRoom(String bookingId) {
    if (_isConnected && bookingId.isNotEmpty) {
      _socket!.emit('join_booking', bookingId);
      debugPrint('🏠 Salle de réservation rejointe: $bookingId');
    }
  }

  // Quitter une salle de réservation
  void leaveBookingRoom(String bookingId) {
    if (_isConnected && bookingId.isNotEmpty) {
      _socket!.emit('leave_booking', bookingId);
      debugPrint('🏠 Salle de réservation quittée: $bookingId');
    }
  }

  // Méthodes pour enregistrer les callbacks de réservation
  void setBookingCallbacks({
    Function(Map<String, dynamic>)? onStatusUpdated,
    Function(Map<String, dynamic>)? onExpired,
    Function(Map<String, dynamic>)? onApproved,
    Function(Map<String, dynamic>)? onRejected,
  }) {
    onBookingStatusUpdated = onStatusUpdated;
    onBookingExpired = onExpired;
    onBookingApproved = onApproved;
    onBookingRejected = onRejected;
  }

  // Nettoyer les callbacks de réservation
  void clearBookingCallbacks() {
    onBookingStatusUpdated = null;
    onBookingExpired = null;
    onBookingApproved = null;
    onBookingRejected = null;
  }

  // Déconnexion
  void disconnect() {
    _socket?.disconnect();
    _isConnected = false;
    debugPrint('🔌 Socket déconnecté manuellement');
  }

  bool get isConnected => _isConnected;
}
