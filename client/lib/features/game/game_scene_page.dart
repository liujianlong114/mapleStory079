import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../main.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/game_provider.dart';
import '../../services/api_service.dart';
import '../../services/websocket_service.dart';
import '../../widgets/player_stats.dart';
import '../../widgets/mini_map.dart';
import '../../game/engine/game_world.dart';
import '../../models/mob.dart';
import '../../core/theme/app_theme.dart';

class GameScenePage extends StatefulWidget {
  final int mapId;
  final String mapName;
  final double mapWidth;
  final double mapHeight;
  final int characterId;
  final int jobId;
  final int initialHp;
  final int initialMaxHp;
  final int initialMp;
  final int initialMaxMp;
  final int initialLevel;
  final int initialExp;
  final int initialStr;
  final int initialDex;
  final int initialIntl;
  final int initialLuk;
  final String? bgmAsset;

  const GameScenePage({
    super.key,
    required this.mapId,
    required this.mapName,
    this.mapWidth = 1600,
    this.mapHeight = 900,
    this.characterId = 1,
    this.jobId = 0,
    this.initialHp = 50,
    this.initialMaxHp = 50,
    this.initialMp = 50,
    this.initialMaxMp = 50,
    this.initialLevel = 1,
    this.initialExp = 0,
    this.initialStr = 10,
    this.initialDex = 4,
    this.initialIntl = 4,
    this.initialLuk = 4,
    this.bgmAsset,
  });

  @override
  State<GameScenePage> createState() => _GameScenePageState();
}

class _GameScenePageState extends State<GameScenePage> {
  late final GameWorld _gameWorld;
  late final WebSocketService _ws;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _ws = WebSocketService();
    _gameWorld = GameWorld(
      mapId: widget.mapId,
      mapName: widget.mapName,
      mapWidth: widget.mapWidth,
      mapHeight: widget.mapHeight,
      characterId: widget.characterId,
      jobId: widget.jobId,
      str: widget.initialStr,
      dex: widget.initialDex,
      intelligence: widget.initialIntl,
      luk: widget.initialLuk,
      exp: widget.initialExp,
      bgmAsset: widget.bgmAsset,
    );
    _gameWorld.ws = _ws;
    _gameWorld.api = ApiService();
    _gameWorld.hp = widget.initialHp;
    _gameWorld.maxHp = widget.initialMaxHp;
    _gameWorld.mp = widget.initialMp;
    _gameWorld.maxMp = widget.initialMaxMp;
    _gameWorld.level = widget.initialLevel;
    _setupStatSync();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _connectWebSocket();
      _spawnServerEntities();
    });
  }

  Future<void> _connectWebSocket() async {
    await _ws.connect(
      AppConfig.wsUrl,
      characterId: widget.characterId,
      room: 'map_${widget.mapId}',
    );
  }

  @override
  void dispose() {
    _ws.disconnect();
    _focusNode.dispose();
    super.dispose();
  }

  void _setupStatSync() {
    if (!mounted) return;
    final gp = context.read<GameProvider>();
    final inv = context.read<InventoryProvider>();
    _gameWorld.onStatChange = ({
      int? hp,
      int? maxHp,
      int? mp,
      int? maxMp,
      int? level,
      int? exp,
      int? mesos,
      double? posX,
      double? posY,
    }) {
      gp.syncFromGameWorld(
        hp: hp,
        maxHp: maxHp,
        mp: mp,
        maxMp: maxMp,
        level: level,
        exp: exp,
        mesos: mesos,
        posX: posX,
        posY: posY,
      );
    };
    _gameWorld.onLevelUp = (newLevel) {
      gp.syncFromGameWorld(level: newLevel);
      gp.doLevelUp();
    };
    _gameWorld.onPlayerDead = () {
      gp.syncFromGameWorld(hp: 0);
    };
    _gameWorld.onInventoryChanged = () {
      inv.loadInventory(widget.characterId);
    };
  }

  Future<void> _spawnServerEntities() async {
    final api = ApiService();
    final instances = await api.getMapMobInstances(widget.mapId);
    if (instances.isNotEmpty) {
      for (final row in instances) {
        final instanceId = (row['instance_id'] as num?)?.toInt() ?? 0;
        final templateId = (row['template_id'] as num?)?.toInt() ?? 0;
        if (instanceId == 0 || templateId == 0) continue;
        final mob = Mob(
          id: instanceId,
          mobId: templateId,
          name: row['name'] as String? ?? '怪物',
          level: (row['level'] as num?)?.toInt() ?? 1,
          hp: (row['hp'] as num?)?.toInt() ?? 50,
          maxHp: (row['max_hp'] as num?)?.toInt() ?? 50,
          attack: 10,
          defense: 0,
          expReward: 0,
          mesoReward: 0,
          posX: (row['x'] as num?)?.toDouble() ?? widget.mapWidth / 2,
          posY: (row['y'] as num?)?.toDouble() ?? widget.mapHeight / 2,
        );
        _gameWorld.addMob(
          mob,
          position: Vector2(mob.posX, mob.posY),
        );
      }
    } else {
      _spawnFallbackMobs();
    }
    _gameWorld.addNPC(
      id: 1,
      name: '卡姆伊',
      position: Vector2(widget.mapWidth / 2 - 200, widget.mapHeight / 2),
    );
  }

  void _spawnFallbackMobs() {
    for (int i = 0; i < 5; i++) {
      final template = MobCatalog.templates[i % MobCatalog.templates.length];
      final mob = Mob(
        id: 10000 + i,
        mobId: template.mobId,
        name: template.name,
        level: template.level,
        hp: template.maxHp,
        maxHp: template.maxHp,
        attack: template.attack,
        defense: template.defense,
        expReward: template.expReward,
        mesoReward: template.mesoReward,
        posX: (widget.mapWidth / 2) + (i - 2) * 140,
        posY: (widget.mapHeight / 2) + (i % 2 == 0 ? -60 : 60),
      );
      _gameWorld.addMob(mob);
    }
  }

  void _onAttack() {
    _gameWorld.playerAttack();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      _gameWorld.handleKeyDown(event.logicalKey, true);
      if (event.logicalKey == LogicalKeyboardKey.keyJ ||
          event.logicalKey == LogicalKeyboardKey.space) {
        _onAttack();
      }
    } else if (event is KeyUpEvent) {
      _gameWorld.handleKeyDown(event.logicalKey, false);
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Focus(
              focusNode: _focusNode,
              autofocus: true,
              onKeyEvent: _onKeyEvent,
              child: GameWidget(
                game: _gameWorld,
                backgroundBuilder: (_) => Container(
                  color: const Color(0xFF1a1a2e),
                ),
              ),
            ),
          ),
          const Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: PlayerStatsBar(),
          ),
          Positioned(
            top: 44,
            right: 10,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.menu, color: Colors.white),
              onSelected: (route) => Navigator.pushNamed(context, route),
              itemBuilder: (_) => const [
                PopupMenuItem(value: Routes.inventory, child: Text('背包')),
                PopupMenuItem(value: Routes.skills, child: Text('技能')),
                PopupMenuItem(value: Routes.chat, child: Text('聊天')),
                PopupMenuItem(value: Routes.combat, child: Text('战斗测试')),
                PopupMenuItem(value: Routes.social, child: Text('社交')),
              ],
            ),
          ),
          Positioned(
            top: 80,
            right: 10,
            child: MiniMapWidget(
              mapWidth: widget.mapWidth.toInt(),
              mapHeight: widget.mapHeight.toInt(),
              playerX: _gameWorld.playerPosition.x,
              playerY: _gameWorld.playerPosition.y,
              mapName: widget.mapName,
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: _onAttack,
                    icon: const Icon(Icons.bolt),
                    label: const Text('攻击 [J]'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFe94560),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      _gameWorld.playerUseSkill(1);
                    },
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('技能 1'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFe94560)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 4,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Text(
                  widget.mapName,
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
