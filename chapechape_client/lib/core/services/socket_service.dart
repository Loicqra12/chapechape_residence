import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chapechape_client/core/utils/secure_storage.dart';
import '../config/app_config_manager.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final _storage = AppSecureStorage.instance;
  bool _isConnected = false;

  // Callbacks
  Function(Map<String, dynamic>)? onNewMessage;
  Function(Map<String, dynamic>)? onBookingStatusUpdated;
  Function(Map<String, dynamic>)? onBookingExpired;
  Function(Map<String, dynamic>)? onBookingApproved;
  Function(Map<String, dynamic>)? onBookingRejected;

  Future<void> initialize() async {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    final socketUrl = AppConfigManager.apiBaseUrl;
    final token = await _storage.read(key: 'token');

    try {
      debugPrint('🔌 Initialisation Socket.io avec URL: $socketUrl');
      final builder = IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection();

      // JWT au handshake — le serveur ignore tout userId client
      if (token != null && token.isNotEmpty) {
        builder.setAuth({'token': token});
        builder.setExtraHeaders({'Authorization': 'Bearer $token'});
      }

      _socket = IO.io(socketUrl, builder.build());
      _setupListeners();
      _socket!.connect();
      debugPrint('🔌 Socket.io initialisé (JWT: ${token != null})');
    } catch (e) {
      debugPrint('❌ Erreur initialisation Socket.io: $e');
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  String? _bookingId(Map<String, dynamic> data) =>
      (data['bookingId'] ?? data['reservationId'])?.toString();

  void _setupListeners() {
    _socket!.on('connect', (_) {
      debugPrint('🔌 Socket connecté');
      _isConnected = true;
      // Compat : signale la présence ; l'identité vient du JWT handshake
      _socket!.emit('auth_user', null);
    });

    _socket!.on('socket_authenticated', (data) {
      debugPrint('🔑 Socket authentifié: $data');
    });

    _socket!.on('socket_error', (data) {
      debugPrint('⚠️ Socket error: $data');
    });

    _socket!.on('disconnect', (_) {
      debugPrint('🔌 Socket déconnecté');
      _isConnected = false;
    });

    _socket!.on('connect_error', (error) {
      debugPrint('❌ Socket connect_error: $error');
    });

    _socket!.on('error', (error) {
      debugPrint('❌ Erreur socket: $error');
    });

    _socket!.on('new_message', (data) {
      debugPrint('📩 Nouveau message WebSocket');
      onNewMessage?.call(_asMap(data));
    });

    // Noms canoniques backend + alias legacy
    void handleStatus(dynamic data) {
      final map = _asMap(data);
      onBookingStatusUpdated?.call(map);
      final status = map['newStatus']?.toString() ?? map['status']?.toString();
      if (status == 'confirmed' || status == 'payment_pending') {
        onBookingApproved?.call(map);
      }
      if (status == 'cancelled' || status == 'rejected') {
        onBookingRejected?.call(map);
      }
    }

    _socket!.on('reservation_status_changed', handleStatus);
    _socket!.on('booking_status_updated', handleStatus);

    void handleExpired(dynamic data) {
      final map = _asMap(data);
      if (_bookingId(map) != null) {
        onBookingExpired?.call(map);
      }
    }

    _socket!.on('reservation_expired', handleExpired);
    _socket!.on('booking_expired', handleExpired);

    _socket!.on('booking_approved', (data) {
      onBookingApproved?.call(_asMap(data));
    });

    _socket!.on('booking_rejected', (data) {
      onBookingRejected?.call(_asMap(data));
    });
  }

  void joinConversation(String conversationId) {
    if (_isConnected && conversationId.isNotEmpty) {
      _socket!.emit('join_conversation', conversationId);
      debugPrint('🔌 Conversation rejointe: $conversationId');
    }
  }

  void leaveConversation(String conversationId) {
    if (_isConnected && conversationId.isNotEmpty) {
      _socket!.emit('leave_conversation', conversationId);
    }
  }

  void joinBookingRoom(String bookingId) {
    if (_isConnected && bookingId.isNotEmpty) {
      _socket!.emit('join_booking', bookingId);
      debugPrint('🏠 Salle réservation rejointe: $bookingId');
    }
  }

  void leaveBookingRoom(String bookingId) {
    if (_isConnected && bookingId.isNotEmpty) {
      _socket!.emit('leave_booking', bookingId);
    }
  }

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

  void clearBookingCallbacks() {
    onBookingStatusUpdated = null;
    onBookingExpired = null;
    onBookingApproved = null;
    onBookingRejected = null;
  }

  /// Réinitialise la connexion avec le token à jour (après login / refresh)
  Future<void> reconnectWithFreshToken() => initialize();

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    debugPrint('🔌 Socket déconnecté manuellement');
  }

  bool get isConnected => _isConnected;
}
