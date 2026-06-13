import 'package:flutter/foundation.dart';

/// 聊天消息频道
enum ChatChannel {
  world,      // 世界频道
  guild,      // 公会频道
  party,      // 组队频道
  private,    // 私聊
}

/// 聊天消息
class ChatMessage {
  final String id;
  final int senderId;
  final String senderName;
  final int? receiverId;      // 私聊时的接收者
  final ChatChannel channel;
  final String content;
  final DateTime timestamp;
  final bool isSystem;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.receiverId,
    required(this.channel),
    required this.content,
    required this.timestamp,
    this.isSystem = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      senderId: json['sender_id'] as int? ?? 0,
      senderName: json['sender_name'] as String? ?? 'Unknown',
      receiverId: json['receiver_id'] as int?,
      channel: ChatChannel.values.firstWhere(
        (e) => e.index == (json['channel'] as int? ?? 0),
        orElse: () => ChatChannel.world,
      ),
      content: json['content'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      isSystem: json['is_system'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      if (receiverId != null) 'receiver_id': receiverId,
      'channel': channel.index,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'is_system': isSystem,
    };
  }
}

/// 聊天状态管理
class ChatProvider extends ChangeNotifier {
  ChatChannel _currentChannel = ChatChannel.world;
  final List<ChatMessage> _messages = [];
  final Map<ChatChannel, List<ChatMessage>> _channelMessages = {};
  bool _isConnected = false;
  int _currentCharacterId = 0;
  String _currentCharacterName = '';
  int _unreadCount = 0;

  ChatChannel get currentChannel => _currentChannel;
  List<ChatMessage> get messages =>
      _channelMessages[_currentChannel] ?? _messages;
  bool get isConnected => _isConnected;
  int get currentCharacterId => _currentCharacterId;
  int get unreadCount => _unreadCount;

  /// 初始化
  void init({required int characterId, required String characterName}) {
    _currentCharacterId = characterId;
    _currentCharacterName = characterName;
    _isConnected = true;
    _addSystemMessage('已连接到聊天服务器');
    notifyListeners();
  }

  /// 切换频道
  void switchChannel(ChatChannel channel) {
    if (_currentChannel == channel) return;
    _currentChannel = channel;
    notifyListeners();
  }

  /// 发送一条消息
  void sendMessage(String content, {int? receiverId}) {
    if (content.trim().isEmpty) return;
    if (_currentChannel == ChatChannel.private && receiverId == null) return;

    final message = ChatMessage(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      senderId: _currentCharacterId,
      senderName: _currentCharacterName,
      receiverId: receiverId,
      channel: _currentChannel,
      content: content.trim(),
      timestamp: DateTime.now(),
    );

    _appendMessage(message);
    notifyListeners();

    // TODO: 通过 WebSocket / API 实际发送消息
  }

  /// 接收到来自服务器的消息
  void receiveMessage(ChatMessage message) {
    _appendMessage(message);
    if (message.channel != _currentChannel && message.senderId != _currentCharacterId) {
      _unreadCount++;
    }
    notifyListeners();
  }

  /// 批量接收历史消息
  void loadHistory(ChatChannel channel, List<ChatMessage> history) {
    _channelMessages[channel] = history;
    notifyListeners();
  }

  /// 清空未读计数
  void clearUnread() {
    _unreadCount = 0;
    notifyListeners();
  }

  /// 断开连接
  void disconnect() {
    _isConnected = false;
    _addSystemMessage('已断开聊天连接');
    notifyListeners();
  }

  /// 添加系统消息（不会进入数据库）
  void _addSystemMessage(String text) {
    final msg = ChatMessage(
      id: 'sys_${DateTime.now().microsecondsSinceEpoch}',
      senderId: 0,
      senderName: '系统',
      channel: _currentChannel,
      content: text,
      timestamp: DateTime.now(),
      isSystem: true,
    );
    _appendMessage(msg);
  }

  void _appendMessage(ChatMessage message) {
    _messages.add(message);
    final list = _channelMessages[message.channel] ?? [];
    list.add(message);
    _channelMessages[message.channel] = list;
  }
}
