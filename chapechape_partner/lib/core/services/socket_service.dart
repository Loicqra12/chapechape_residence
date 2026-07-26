import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chapechape_partner/core/utils/secure_storage.dart';
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
  Function(Map<String, dynamic>)? onReservationStatusChanged;
  Function(Map<String, dynamic>)? onNewReservationReceived;
  Function(Map<String, dynamic>)? onReservationExpired;

  Future<void> initialize() async {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    final baseUrl = AppConfigManager.apiBaseUrl;
    // Même clé que AuthBloc / ApiService
    final token = await _storage.read(key: 'token');

    try {
      debugPrint('🔌 Initialisation Socket.io partenaire: $baseUrl');
      final builder = IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection();

      if (token != null && token.isNotEmpty) {
        builder.setAuth({'token': token});
        builder.setExtraHeaders({'Authorization': 'Bearer $token'});
      }

      _socket = IO.io(baseUrl, builder.build());
      _setupListeners();
      _socket!.connect();
      debugPrint('🔌 Socket.io partenaire initialisé (JWT: ${token != null})');
    } catch (e) {
      debugPrint('❌ Erreur Socket.io partenaire: $e');
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  void _setupListeners() {
    _socket!.on('connect', (_) {
      debugPrint('🔌 Socket partenaire connecté');
      _isConnected = true;
      _socket!.emit('auth_user', null);
    });

    _socket!.on('socket_authenticated', (data) {
      debugPrint('🔑 Socket partenaire authentifié: $data');
    });

    _socket!.on('socket_error', (data) {
      debugPrint('⚠️ Socket partenaire error: $data');
    });

    _socket!.on('disconnect', (_) {
      debugPrint('🔌 Socket partenaire déconnecté');
      _isConnected = false;
    });

    _socket!.on('connect_error', (error) {
      debugPrint('❌ Socket partenaire connect_error: $error');
    });

    _socket!.on('error', (error) {
      debugPrint('❌ Erreur socket partenaire: $error');
    });

    _socket!.on('new_message', (data) {
      debugPrint('📩 Nouveau message WebSocket partenaire');
      onNewMessage?.call(_asMap(data));
    });

    _socket!.on('partner_reservation_status_changed', (data) {
      onReservationStatusChanged?.call(_asMap(data));
    });

    _socket!.on('new_reservation_received', (data) {
      onNewReservationReceived?.call(_asMap(data));
    });

    _socket!.on('partner_reservation_expired', (data) {
      onReservationExpired?.call(_asMap(data));
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

  void joinResidence(String residenceId) {
    if (_isConnected && residenceId.isNotEmpty) {
      _socket!.emit('join_residence', residenceId);
    }
  }

  void leaveResidence(String residenceId) {
    if (_isConnected && residenceId.isNotEmpty) {
      _socket!.emit('leave_residence', residenceId);
    }
  }

  Future<void> reconnectWithFreshToken() => initialize();

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    debugPrint('🔌 Socket partenaire déconnecté manuellement');
  }

  bool get isConnected => _isConnected;
}
