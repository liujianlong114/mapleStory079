import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/game_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/combat_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/skill_provider.dart';
import '../../widgets/player_stats.dart';
import '../../widgets/game_chat.dart';
import '../../widgets/mini_map.dart';
import '../../widgets/npc_dialogue_widget.dart';
import '../../widgets/skill_bar_widget.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1a1a2e), Color(0xFF0f3460)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Consumer<GameProvider>(
              builder: (ctx, game, _) {
                if (game.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.amber),
                        SizedBox(height: 12),
                        Text('加载游戏中...', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    _TopBar(),
                    const Expanded(
                      child: _GameField(),
                    ),
                    const SkillBarWidget(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _handleKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      final game = Provider.of<GameProvider>(context, listen: false);
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.keyA) {
        game.moveLeft();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.keyD) {
        game.moveRight();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.keyW) {
        game.moveUp();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.keyS) {
        game.moveDown();
      }
    }
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(child: PlayerStatsBar()),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${game.state.mapName}(${game.state.mapId})',
                style: const TextStyle(color: Colors.amber, fontSize: 12),
              ),
              Text(
                '在线: ${auth.username}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              game.disconnect();
              auth.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            icon: const Icon(Icons.exit_to_app, color: Colors.amber),
            tooltip: '退出游戏',
          ),
        ],
      ),
    );
  }
}

class _GameField extends StatelessWidget {
  const _GameField();

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final combat = Provider.of<CombatProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(builder: (ctx, constraints) {
        final field = Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight - 200);
        // 把相对坐标归一化到 0 ~ 100
        double cx = game.posX.clamp(0.0, 100.0) / 100.0 * (field.width - 64) + 32;
        double cy = game.posY.clamp(0.0, 100.0) / 100.0 * (field.height - 64) + 32;
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300.withOpacity(0.6)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: cx - 20,
                    top: cy - 20,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.amber,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.amber, blurRadius: 16, spreadRadius: 2),
                        ],
                      ),
                      child: const Icon(Icons.person, color: Colors.black),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 16,
                    child: MiniMap(
                      width: 180,
                      height: 120,
                      mapId: game.state.mapId,
                      players: const [],
                      npcs: const [],
                    ),
                  ),
                  Positioned(
                    right: 16,
                    top: 16,
                    child: CombatQuickPanel(combat: combat, game: game),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 180,
              child: Row(
                children: [
                  Expanded(flex: 2, child: GameChatWidget(messages: game.messages)),
                  const SizedBox(width: 8),
                  const Expanded(flex: 1, child: NpcDialogueWidget()),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class CombatQuickPanel extends StatelessWidget {
  const CombatQuickPanel({super.key, required this.combat, required this.game});
  final CombatProvider combat;
  final GameProvider game;

  @override
  Widget build(BuildContext context) {
    final inv = Provider.of<InventoryProvider>(context, listen: false);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '战斗快捷',
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final damage = await combat.attackMob(game.state.level + 1, game.state.str);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('⚔️ 对怪物造成 $damage 点伤害'), duration: const Duration(seconds: 1)),
                  );
                  await game.gainExperience(damage);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                child: const Text('攻击'),
              ),
              ElevatedButton(
                onPressed: () => game.restoreHpMp(50, 20),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('恢复'),
              ),
              ElevatedButton(
                onPressed: () => inv.load(game.state.characterId),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('背包'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
