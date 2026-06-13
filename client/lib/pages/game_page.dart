// =============================================================
// DEPRECATED: 此文件已被 `lib/features/game/game_page.dart` 替代。
// 保留用于向后兼容，请勿在新代码中引用。
// =============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/game_chat.dart';
import '../widgets/player_stats.dart';
import '../widgets/mini_map.dart';
import 'inventory_page.dart';
import 'skills_page.dart';
import 'combat_page.dart';
import 'chat_page.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gp = Provider.of<GameProvider>(context, listen: false);
      gp.loadGameState();
      gp.connectWebSocket();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      Provider.of<GameProvider>(context, listen: false).sendMessage(message);
      _messageController.clear();
    }
  }

  void _logout() {
    Provider.of<GameProvider>(context, listen: false).disconnect();
    Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _showAddAPDialog(GameProvider gameProvider) async {
    String selectedStat = 'str';
    int points = 1;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1a1a2e),
              title: const Text('分配能力点', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('可用AP: ${gameProvider.ap}',
                      style: const TextStyle(color: Colors.orangeAccent, fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(
                    children: ['str', 'dex', 'int', 'luk']
                        .map((stat) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: selectedStat == stat
                                        ? Colors.orangeAccent
                                        : Colors.white.withOpacity(0.1),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedStat = stat;
                                    });
                                  },
                                  child: Text(_statName(stat),
                                      style: const TextStyle(color: Colors.white)),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [1, 5, 10]
                        .map((p) => ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: points == p
                                    ? Colors.greenAccent
                                    : Colors.white.withOpacity(0.1),
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  points = p;
                                });
                              },
                              child: Text('+$p',
                                  style: const TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                  onPressed: () {
                    gameProvider.addAP(selectedStat, points);
                    Navigator.pop(context);
                  },
                  child: const Text('确定', style: TextStyle(color: Colors.black)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _statName(String stat) {
    switch (stat) {
      case 'str':
        return '力量';
      case 'dex':
        return '敏捷';
      case 'int':
        return '智力';
      case 'luk':
        return '幸运';
      default:
        return stat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final character = gameProvider.currentCharacter;

    return Scaffold(
      appBar: AppBar(
        title: Text(character?.name ?? '游戏'),
        backgroundColor: const Color(0xFF1a1a2e),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: Row(
              children: [
                Icon(
                  gameProvider.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: gameProvider.isConnected ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  gameProvider.isConnected ? '在线' : '离线',
                  style: TextStyle(
                    fontSize: 12,
                    color: gameProvider.isConnected ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
        ),
        child: character == null
            ? const Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
            : Column(
                children: [
                  PlayerStats(character: character, gameProvider: gameProvider),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: _buildGameArea(gameProvider)),
                        Expanded(flex: 1, child: GameChat(messages: gameProvider.messages)),
                      ],
                    ),
                  ),
                  _buildControlButtons(gameProvider),
                  _buildMessageInput(),
                ],
              ),
      ),
    );
  }

  Widget _buildGameArea(GameProvider gameProvider) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '地图: ${gameProvider.state.mapName ?? '未知'}  (${gameProvider.posX.toStringAsFixed(0)}, ${gameProvider.posY.toStringAsFixed(0)})',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: MiniMapWidget(
              mapWidth: 800,
              mapHeight: 600,
              playerX: gameProvider.posX,
              playerY: gameProvider.posY,
              mapName: gameProvider.state.mapName ?? '地图',
            ),
          ),
          Positioned(
            left: gameProvider.posX.clamp(0.0, 600.0) + 40,
            bottom: gameProvider.posY.clamp(0.0, 300.0) + 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orangeAccent.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person, size: 20, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    gameProvider.state.characterName,
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Lv.${gameProvider.level}',
                    style: const TextStyle(fontSize: 9, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildMiniButton(Icons.arrow_upward, () => gameProvider.moveUp()),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildMiniButton(Icons.arrow_back, () => gameProvider.moveLeft()),
                    const SizedBox(width: 4),
                    _buildMiniButton(Icons.arrow_forward, () => gameProvider.moveRight()),
                  ],
                ),
                const SizedBox(height: 4),
                _buildMiniButton(Icons.arrow_downward, () => gameProvider.moveDown()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildControlButtons(GameProvider gameProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildActionChip(Icons.inventory_2, '背包', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryPage())), Colors.brown),
                const SizedBox(width: 8),
                _buildActionChip(Icons.sports_martial_arts, '技能', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SkillsPage())), Colors.purple),
                const SizedBox(width: 8),
                _buildActionChip(Icons.bolt, '战斗', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CombatPage())), Colors.red),
                const SizedBox(width: 8),
                _buildActionChip(Icons.chat, '聊天', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatPage())), Colors.blue),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildActionChip(Icons.refresh, '刷新', () => gameProvider.loadGameState(), Colors.blue),
                const SizedBox(width: 8),
                _buildActionChip(Icons.star, '经验+50', () => gameProvider.gainExperience(50), Colors.yellow),
                const SizedBox(width: 8),
                _buildActionChip(Icons.trending_up, '升级', () => gameProvider.doLevelUp(), Colors.green),
                const SizedBox(width: 8),
                _buildActionChip(Icons.add, '加AP', () => _showAddAPDialog(gameProvider), Colors.orange),
                const SizedBox(width: 8),
                _buildActionChip(Icons.healing, '恢复', () => gameProvider.restoreHpMp(100, 50), Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(IconData icon, String label, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '发送消息...',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orangeAccent)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send, color: Colors.orangeAccent),
          ),
        ],
      ),
    );
  }
}
