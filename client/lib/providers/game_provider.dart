import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../models/character.dart';
import '../models/game_map.dart';
import '../models/game_state.dart';
import '../services/api_service.dart';

class GameProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  WebSocketChannel? _channel;
  Character? _currentCharacter;
  GameMap? _currentMap;
  GameState _state = GameState();
  final List<Map<String, dynamic>> _players = [];
  final List<String> _messages = [];
  bool _isConnected = false;
  bool _isLoading = false;
  String? _errorMessage;

  Character? get currentCharacter => _currentCharacter;
  GameMap? get currentMap => _currentMap;
  GameState get state => _state;
  List<Map<String, dynamic>> get players => _players;
  List<String> get messages => List.unmodifiable(_messages);
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get posX => _state.posX;
  double get posY => _state.posY;
  String get serverStatus => _isConnected ? '在线' : '离线';

  /// 通过角色 ID 加载游戏状态：设置当前角色 + 拉取游戏状态
  Future<bool> loadCharacterState(int characterId) async {
    _currentCharacter = Character(
      id: characterId,
      accountId: 0,
      name: '加载中...',
      characterClass: 0,
      gender: 0,
      level: 1,
      experience: 0,
      mapId: 1,
      positionX: 0,
      positionY: 0,
      hp: 100,
      maxHp: 100,
      mp: 50,
      maxMp: 50,
      str: 4,
      dex: 4,
      intl: 4,
      luk: 4,
      mesos: 0,
    );
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.getGameState(characterId);
      final charData = data['character'] as Map<String, dynamic>?;
      if (charData != null) {
        _currentCharacter = Character.fromMap(charData);
      }
      _state = GameState.fromJson(data);
      if (data['map'] != null) {
        _currentMap = GameMap.fromJson(data['map'] as Map<String, dynamic>);
      }
      _isLoading = false;
      notifyListeners();
      await connectWebSocket();
      return true;
    } catch (e) {
      _errorMessage = '加载游戏状态失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  int get level => _state.level;
  int get exp => _state.exp;
  double get expProgress => _state.expProgress;
  int get hp => _state.hp;
  int get maxHp => _state.maxHp;
  int get mp => _state.mp;
  int get maxMp => _state.maxMp;
  int get str => _state.str;
  int get dex => _state.dex;
  int get intl => _state.intl;
  int get luk => _state.luk;
  int get ap => _state.ap;
  int get mesos => _state.mesos;

  void selectCharacter(Character character) {
    _currentCharacter = character;
    _state.characterName = character.name;
    _state.className = character.className;
    _state.posX = character.positionX.toDouble();
    _state.posY = character.positionY.toDouble();
    _state.level = character.level;
    _state.exp = character.experience;
    _state.hp = character.hp;
    _state.maxHp = character.maxHp;
    _state.mp = character.mp;
    _state.maxMp = character.maxMp;
    _state.str = character.str;
    _state.dex = character.dex;
    _state.intl = character.intl;
    _state.luk = character.luk;
    _state.mapId = character.mapId;
    _state.mesos = character.mesos;
    notifyListeners();
  }

  Future<bool> loadGameState() async {
    if (_currentCharacter == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _api.getGameState(_currentCharacter!.id);
      _state = GameState.fromJson(data);
      if (data['map'] != null) {
        _currentMap = GameMap.fromJson(data['map'] as Map<String, dynamic>);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '加载游戏状态失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> move(double newX, double newY) async {
    if (_currentCharacter == null) return false;

    _state.posX = newX;
    _state.posY = newY;

    final moveMsg = {
      'type': 'move',
      'character_id': _currentCharacter!.id,
      'x': newX,
      'y': newY,
    };
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(moveMsg.toString());
      } catch (_) {}
    }

    notifyListeners();

    try {
      await _api.moveCharacter(_currentCharacter!.id, newX, newY);
      return true;
    } catch (e) {
      debugPrint('移动请求失败: $e');
      return false;
    }
  }

  Future<bool> moveLeft() async {
    return move(posX - 10, posY);
  }

  Future<bool> moveRight() async {
    return move(posX + 10, posY);
  }

  Future<bool> moveUp() async {
    return move(posX, posY - 10);
  }

  Future<bool> moveDown() async {
    return move(posX, posY + 10);
  }

  Future<bool> gainExperience(int expAmount) async {
    if (_currentCharacter == null) return false;
    try {
      final data = await _api.gainExp(_currentCharacter!.id, expAmount);
      _state.updateFromJson(data);
      if (data['leveled_up'] == true) {
        _addMessage('🎉 升级了! 现在是 Lv.${_state.level}');
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '获取经验失败: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> doLevelUp() async {
    if (_currentCharacter == null) return false;
    try {
      final data = await _api.levelUp(_currentCharacter!.id);
      _state.updateFromJson(data);
      _addMessage('⬆️ 升级成功! Lv.${_state.level}');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '升级失败: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addAP(String stat, int points) async {
    if (_currentCharacter == null) return false;
    try {
      final data = await _api.addAbilityPoints(_currentCharacter!.id, stat, points);
      _state.updateFromJson(data);
      _addMessage('💪 $stat +$points');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '分配能力点失败: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> restoreHpMp(int hpAmount, int mpAmount) async {
    if (_currentCharacter == null) return false;
    try {
      final data = await _api.restore(_currentCharacter!.id, hpAmount, mpAmount);
      _state.updateFromJson(data);
      _addMessage('❤️ 恢复 HP+$hpAmount, MP+$mpAmount');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '恢复失败: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> connectWebSocket() async {
    if (_currentCharacter == null) return;

    try {
      final uri = Uri.parse(
        '${AppConfig.wsUrl}?character_id=${_currentCharacter!.id}&room=map_${_state.mapId}',
      );
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;
      notifyListeners();

      _channel!.stream.listen(
        (message) {
          _handleMessage(message.toString());
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _isConnected = false;
          notifyListeners();
        },
        onDone: () {
          debugPrint('WebSocket closed');
          _isConnected = false;
          notifyListeners();
        },
      );

      _addMessage('已连接到服务器');
    } catch (e) {
      debugPrint('Failed to connect WebSocket: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  void _handleMessage(String message) {
    _messages.add(message);
    if (_messages.length > 100) {
      _messages.removeAt(0);
    }
    notifyListeners();
  }

  void sendMessage(String content) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(content);
      _addMessage('你: $content');
    }
  }

  void _addMessage(String message) {
    _messages.add('[$_timeString] $message');
    if (_messages.length > 100) {
      _messages.removeAt(0);
    }
    notifyListeners();
  }

  String get _timeString {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  void setCurrentMap(GameMap map) {
    _currentMap = map;
    _state.mapId = map.id;
    _state.mapName = map.name;
    notifyListeners();
  }

  void updatePlayerPosition(int characterId, double x, double y) {
    final existingIndex = _players.indexWhere((p) => p['characterId'] == characterId);
    if (existingIndex >= 0) {
      _players[existingIndex]['x'] = x;
      _players[existingIndex]['y'] = y;
    } else {
      _players.add({
        'characterId': characterId,
        'x': x,
        'y': y,
      });
    }
    notifyListeners();
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _players.clear();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
