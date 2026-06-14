import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

/// WebSocket 消息类型
///
/// 与服务端 `pkg/utils/constants.go` 中的 WSMessageTypes 保持一致。
/// 服务端仅接受白名单内的 type 字段，扩展时请同步更新两端。
class WsMessageType {
  // 服务端到客户端 / 双向
  static const String chat = 'chat';
  static const String position = 'position';
  static const String move = 'move';
  static const String attack = 'attack';
  static const String damage = 'damage';
  static const String exp = 'exp';
  static const String loot = 'loot';
  static const String dead = 'dead';
  static const String revive = 'revive';
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
    final payload = Map<String, dynamic>.from(
      json['payload'] as Map<String, dynamic>? ?? {},
    );
    for (final key in [
      'action', 'drop_id', 'item_id', 'quantity', 'mesos', 'x', 'y',
      'character_id', 'map_id', 'content', 'damage', 'critical',
      'exp_gained', 'level_up', 'target_id', 'skill_id', 'name',
    ]) {
      if (json.containsKey(key) && !payload.containsKey(key)) {
        payload[key] = json[key];
      }
    }
    final sender = json['sender_id'] ?? json['character_id'];
    return WsMessage(
      type: json['type'] as String? ?? WsMessageType.system,
      payload: payload,
      senderId: sender is int ? sender : int.tryParse('$sender'),
      room: json['room'] as String? ?? json['channel'] as String?,
      timestamp: json['ts'] != null
          ? DateTime.fromMillisecondsSinceEpoch((json['ts'] as num).toInt() * 1000)
          : DateTime.tryParse(json['timestamp'] as String? ?? '') ??
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

  /// 发送位置同步（对应服务端 WSMessageTypePosition，节流 50ms）
  void sendPosition({
    required int characterId,
    required double x,
    required double y,
    String? mapId,
  }) {
    send(WsMessage(
      type: WsMessageType.position,
      senderId: characterId,
      payload: {
        'character_id': characterId,
        'x': x,
        'y': y,
        if (mapId != null) 'map_id': mapId,
      },
    ));
  }

  /// 发送移动方向（对应服务端 WSMessageTypeMove，节流 50ms）
  void sendMove({
    required int characterId,
    required double x,
    required double y,
    String? mapId,
  }) {
    send(WsMessage(
      type: WsMessageType.move,
      senderId: characterId,
      payload: {
        'character_id': characterId,
        'x': x,
        'y': y,
        if (mapId != null) 'map_id': mapId,
      },
    ));
  }

  /// 发送攻击（对应服务端 WSMessageTypeAttack，节流 200ms）
  void sendAttack({
    required int characterId,
    required int? skillId,
    required int? targetId,
    required double x,
    required double y,
  }) {
    send(WsMessage(
      type: WsMessageType.attack,
      senderId: characterId,
      payload: {
        'character_id': characterId,
        if (skillId != null) 'skill_id': skillId,
        if (targetId != null) 'target_id': targetId,
        'x': x,
        'y': y,
      },
    ));
  }

  /// 广播伤害（用于本地预测，服务端会再次校验）
  void sendDamage({
    required int characterId,
    required int targetId,
    required int damage,
    required bool critical,
  }) {
    if (damage <= 0) return;
    send(WsMessage(
      type: WsMessageType.damage,
      senderId: characterId,
      payload: {
        'character_id': characterId,
        'target_id': targetId,
        'damage': damage,
        'critical': critical,
      },
    ));
  }

  /// 广播经验获取（含升级标志）
  void sendExp({
    required int characterId,
    required int expGained,
    bool levelUp = false,
  }) {
    if (expGained <= 0) return;
    send(WsMessage(
      type: WsMessageType.exp,
      senderId: characterId,
      payload: {
        'character_id': characterId,
        'exp_gained': expGained,
        'level_up': levelUp,
      },
    ));
  }

  /// 请求拾取地面掉落（服务端校验距离与归属）
  void sendLootPickup({
    required int characterId,
    required String dropId,
    required double x,
    required double y,
  }) {
    send(WsMessage(
      type: WsMessageType.loot,
      senderId: characterId,
      payload: {
        'action': 'pickup',
        'character_id': characterId,
        'drop_id': dropId,
        'x': x,
        'y': y,
      },
    ));
  }

  /// 广播拾取物品 / 金币
  void sendLoot({
    required int characterId,
    int? itemId,
    int quantity = 1,
    int mesos = 0,
  }) {
    if (itemId == null && mesos <= 0) return;
    send(WsMessage(
      type: WsMessageType.loot,
      senderId: characterId,
      payload: {
        'character_id': characterId,
        if (itemId != null) 'item_id': itemId,
        'quantity': quantity,
        'mesos': mesos,
      },
    ));
  }

  /// 广播死亡事件
  void sendDead({required int characterId, int? targetId}) {
    send(WsMessage(
      type: WsMessageType.dead,
      senderId: characterId,
      payload: {
        'character_id': characterId,
        if (targetId != null) 'target_id': targetId,
      },
    ));
  }

  /// 广播复活事件
  void sendRevive({
    required int characterId,
    required double x,
    required double y,
  }) {
    send(WsMessage(
      type: WsMessageType.revive,
      senderId: characterId,
      payload: {
        'character_id': characterId,
        'x': x,
        'y': y,
      },
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
