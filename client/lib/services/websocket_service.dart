import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

/// WebSocket 消息类型
class WsMessageType {
  static const String chat = 'chat';
  static const String move = 'move';
  static const String attack = 'attack';
  static const String levelup = 'levelup';
  static const String system = 'system';
  static const String ping = 'ping';
  static const String pong = 'pong';
}

/// WebSocket 消息包装器
class WsMessage {
  final String type;
  final Map<String, dynamic> payload;
  final int? senderId;
  final String? room;
  final DateTime timestamp;

  WsMessage({
    required this.type,
    required this.payload,
    this.senderId,
    this.room,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory WsMessage.fromJson(Map<String, dynamic> json) {
    return WsMessage(
      type: json['type'] as String? ?? WsMessageType.system,
      payload: json['payload'] as Map<String, dynamic>? ?? {},
      senderId: json['sender_id'] as int?,
      room: json['room'] as String?,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'payload': payload,
      if (senderId != null) 'sender_id': senderId,
      if (room != null) 'room': room,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// WebSocket 服务封装
class WebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  final Map<String, List<Function(WsMessage)>> _listeners = {};
  final List<Function(bool)> _connectionListeners = [];

  bool get isConnected => _isConnected;

  /// 连接到 WebSocket 服务器
  Future<bool> connect(
    String baseUrl, {
    required int characterId,
    String room = 'default',
  }) async {
    try {
      final uri = _buildUri(baseUrl, characterId: characterId, room: room);
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;
      _notifyConnectionListeners(true);
      _startHeartbeat();

      _channel!.stream.listen(
        (dynamic data) {
          _onData(data);
        },
        onError: (dynamic error) {
          _isConnected = false;
          _notifyConnectionListeners(false);
          _scheduleReconnect(baseUrl, characterId: characterId, room: room);
        },
        onDone: () {
          _isConnected = false;
          _notifyConnectionListeners(false);
          _scheduleReconnect(baseUrl, characterId: characterId, room: room);
        },
        cancelOnError: false,
      );

      return true;
    } catch (e) {
      _isConnected = false;
      _notifyConnectionListeners(false);
      _scheduleReconnect(baseUrl, characterId: characterId, room: room);
      return false;
    }
  }

  /// 关闭连接
  void disconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    try {
      _channel?.sink.close(status.goingAway);
    } catch (_) {}
    _channel = null;
    _isConnected = false;
    _notifyConnectionListeners(false);
  }

  /// 发送消息
  void send(WsMessage message) {
    if (_channel == null || !_isConnected) return;
    try {
      final jsonStr = jsonEncode(message.toJson());
      _channel!.sink.add(jsonStr);
    } catch (_) {}
  }

  /// 快速发送聊天消息
  void sendChat({
    required String content,
    required int channel,
    required int senderId,
    required String senderName,
    int? receiverId,
  }) {
    send(WsMessage(
      type: WsMessageType.chat,
      senderId: senderId,
      payload: {
        'content': content,
        'channel': channel,
        'sender_name': senderName,
        if (receiverId != null) 'receiver_id': receiverId,
      },
    ));
  }

  /// 发送移动坐标更新
  void sendMove({
    required int characterId,
    required double x,
    required double y,
    required String mapId,
  }) {
    send(WsMessage(
      type: WsMessageType.move,
      senderId: characterId,
      payload: {'x': x, 'y': y, 'map_id': mapId},
    ));
  }

  /// 添加消息监听
  void addListener(String type, Function(WsMessage) handler) {
    _listeners.putIfAbsent(type, () => []).add(handler);
  }

  /// 移除消息监听
  void removeListener(String type, Function(WsMessage) handler) {
    _listeners[type]?.remove(handler);
  }

  /// 添加连接状态监听
  void addConnectionListener(Function(bool) listener) {
    _connectionListeners.add(listener);
  }

  void removeConnectionListener(Function(bool) listener) {
    _connectionListeners.remove(listener);
  }

  // ==================== 内部方法 ====================

  Uri _buildUri(String baseUrl, {required int characterId, required String room}) {
    final query = <String, String>{
      'character_id': characterId.toString(),
      'room': room,
    };
    if (baseUrl.startsWith('ws://') || baseUrl.startsWith('wss://')) {
      return Uri.parse(baseUrl).replace(queryParameters: query);
    }
    return Uri.parse('ws://$baseUrl').replace(queryParameters: query);
  }

  void _onData(dynamic data) {
    try {
      final text = data is String ? data : utf8.decode(data as List<int>);
      final json = jsonDecode(text) as Map<String, dynamic>;
      final msg = WsMessage.fromJson(json);
      // 心跳响应
      if (msg.type == WsMessageType.ping) {
        send(WsMessage(type: WsMessageType.pong, payload: {}));
        return;
      }
      // 分发给类型对应的监听器
      for (final handler in _listeners[msg.type] ?? <Function(WsMessage)>[]) {
        try {
          handler(msg);
        } catch (_) {}
      }
      // 通配符监听器
      for (final handler in _listeners['*'] ?? <Function(WsMessage)>[]) {
        try {
          handler(msg);
        } catch (_) {}
      }
    } catch (_) {}
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      send(WsMessage(type: WsMessageType.ping, payload: {}));
    });
  }

  void _scheduleReconnect(String baseUrl,
      {required int characterId, required String room}) {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!_isConnected) {
        connect(baseUrl, characterId: characterId, room: room);
      }
    });
  }

  void _notifyConnectionListeners(bool connected) {
    for (final listener in _connectionListeners) {
      try {
        listener(connected);
      } catch (_) {}
    }
  }
}
