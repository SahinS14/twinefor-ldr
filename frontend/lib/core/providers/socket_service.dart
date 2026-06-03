import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

typedef EventCallback = void Function(dynamic data);

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  static const String wsUrl = 'https://twine-api.onrender.com';

  IO.Socket? _socket;
  final _storage = const FlutterSecureStorage();
  final Map<String, List<EventCallback>> _listeners = {};

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (isConnected) return;
    final token = await _storage.read(key: 'access_token');
    if (token == null) return;

    _socket = IO.io(
      '$wsUrl/ws',
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      print('✅ Socket connected');
      _notifyListeners('connected', null);
    });

    _socket!.onDisconnect((_) {
      print('❌ Socket disconnected');
      _notifyListeners('disconnected', null);
    });

    _socket!.onError((e) => print('Socket error: $e'));

    // Forward all known events to local listeners
    for (final event in _knownEvents) {
      _socket!.on(event, (data) => _notifyListeners(event, data));
    }
  }

  void disconnect() { _socket?.disconnect(); _socket = null; }

  void emit(String event, dynamic data) {
    if (!isConnected) { print('⚠️ Socket not connected, cannot emit $event'); return; }
    _socket!.emit(event, data);
  }

  void emitWithAck(String event, dynamic data, Function(dynamic) callback) {
    _socket!.emitWithAck(event, data, ack: callback);
  }

  void on(String event, EventCallback callback) {
    _listeners.putIfAbsent(event, () => []).add(callback);
  }

  void off(String event, EventCallback callback) {
    _listeners[event]?.remove(callback);
  }

  void _notifyListeners(String event, dynamic data) {
    for (final cb in _listeners[event] ?? []) { try { cb(data); } catch (e) { print('Listener error [$event]: $e'); } }
  }

  // ─── CHAT EMITTERS ────────────────────────────────────────────────────────
  void sendMessage(String content, {String type = 'text', String? replyToId}) {
    emit('chat:send', {'content': content, 'type': type, 'replyToId': replyToId});
  }
  void setTyping(bool isTyping) { emit('chat:typing', {'isTyping': isTyping}); }
  void markRead() { emit('chat:read', {}); }
  void reactToMessage(String messageId, String emoji) { emit('chat:react', {'messageId': messageId, 'emoji': emoji}); }

  // ─── GAME EMITTERS ────────────────────────────────────────────────────────
  void joinGame(String sessionId) { emit('game:join', {'sessionId': sessionId}); }
  void makeMove(String sessionId, Map move) { emit('game:move', {'sessionId': sessionId, 'move': move}); }
  void resignGame(String sessionId) { emit('game:resign', {'sessionId': sessionId}); }

  // ─── LOCATION EMITTERS ────────────────────────────────────────────────────
  void updateLocation(double lat, double lng, {String? note}) { emit('location:update', {'lat': lat, 'lng': lng, 'note': note}); }

  // ─── VOICE EMITTERS ───────────────────────────────────────────────────────
  void joinVoiceRoom(String mode) { emit('voice:join', {'mode': mode}); }
  void leaveVoiceRoom() { emit('voice:leave', {}); }

  // ─── MOOD ─────────────────────────────────────────────────────────────────
  void updateMood(String mood) { emit('mood:update', {'mood': mood}); }

  static const List<String> _knownEvents = [
    'connected', 'disconnected',
    'chat:message', 'chat:typing', 'chat:read', 'chat:reaction',
    'game:state', 'game:end', 'game:player_joined',
    'presence:update', 'location:update', 'mood:partner_update',
    'voice:partner_joined', 'voice:partner_left', 'voice:signal',
    'notification:push',
  ];
}
