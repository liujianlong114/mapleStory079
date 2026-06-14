import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../main.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/game_provider.dart';
import '../../services/api_service.dart';
import '../../services/websocket_service.dart';
import '../../widgets/player_stats.dart';
import '../../widgets/mini_map.dart';
import '../../game/engine/game_controls.dart';
import '../../game/engine/game_world.dart';
import '../../models/mob.dart';
import 'key_config_dialog.dart';

class GameScenePage extends StatefulWidget {
  final int mapId;
  final String mapName;
  final double mapWidth;
  final double mapHeight;
  final double groundY;
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
  final double initialPosX;
  final double initialPosY;
  final String? bgmAsset;
  final int playerGender;
  final int playerFace;
  final int playerHair;
  final int playerTop;
  final int playerBottom;
  final int playerShoes;
  final int playerWeapon;

  const GameScenePage({
    super.key,
    required this.mapId,
    required this.mapName,
    this.mapWidth = 1600,
    this.mapHeight = 600,
    this.groundY = 605,
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
    this.initialPosX = 400,
    this.initialPosY = 605,
    this.bgmAsset,
    this.playerGender = 0,
    this.playerFace = 20100,
    this.playerHair = 30000,
    this.playerTop = 0,
    this.playerBottom = 0,
    this.playerShoes = 0,
    this.playerWeapon = 0,
  });

  @override
  State<GameScenePage> createState() => _GameScenePageState();
}

class _GameScenePageState extends State<GameScenePage> {
  late final GameWorld _gameWorld;
  late final WebSocketService _ws;

  @override
  void initState() {
    super.initState();
    GameControls.ensureLoaded();
    _ws = WebSocketService();
    _gameWorld = GameWorld(
      mapId: widget.mapId,
      mapName: widget.mapName,
      mapWidth: widget.mapWidth,
      mapHeight: widget.mapHeight,
      characterId: widget.characterId,
      jobId: widget.jobId,
      playerInitial: Vector2(widget.initialPosX, widget.groundY),
      str: widget.initialStr,
      dex: widget.initialDex,
      intelligence: widget.initialIntl,
      luk: widget.initialLuk,
      exp: widget.initialExp,
      bgmAsset: widget.bgmAsset,
      playerGender: widget.playerGender,
      playerFace: widget.playerFace,
      playerHair: widget.playerHair,
      playerTop: widget.playerTop,
      playerBottom: widget.playerBottom,
      playerShoes: widget.playerShoes,
      playerWeapon: widget.playerWeapon,
    );
    _gameWorld.ws = _ws;
    _gameWorld.api = ApiService();
    _gameWorld.hp = widget.initialHp;
    _gameWorld.maxHp = widget.initialMaxHp;
    _gameWorld.mp = widget.initialMp;
    _gameWorld.maxMp = widget.initialMaxMp;
    _gameWorld.level = widget.initialLevel;
    _setupStatSync();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _connectWebSocket();
      await _gameWorld.mapReady;
      if (!mounted) return;
      await _spawnServerEntities();
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
    _gameWorld.onOpenKeyConfig = () {
      if (mounted) KeyConfigDialog.show(context);
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
        final x = (row['x'] as num?)?.toDouble() ?? widget.mapWidth / 2;
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
          posX: x,
          posY: 0,
          rx0: (row['rx0'] as num?)?.toDouble() ?? (x - 100),
          rx1: (row['rx1'] as num?)?.toDouble() ?? (x + 100),
          spawnY: 0,
          speed: (row['speed'] as num?)?.toInt() ?? 60,
        );
        _gameWorld.addMob(mob, position: Vector2(x, 0));
      }
    } else {
      _spawnFallbackMobs();
    }
    final npcs = await api.getNPCsByMap(widget.mapId);
    if (npcs.isNotEmpty) {
      for (final row in npcs) {
        final id = (row['id'] as num?)?.toInt() ?? (row['npc_id'] as num?)?.toInt() ?? 0;
        final name = row['name'] as String? ?? 'NPC';
        final x = (row['pos_x'] as num?)?.toDouble() ??
            (row['position_x'] as num?)?.toDouble() ??
            (row['x'] as num?)?.toDouble() ??
            widget.mapWidth / 2;
        if (id == 0) continue;
        _gameWorld.addNPC(id: id, name: name, position: Vector2(x, 0));
      }
    } else if (widget.mapId == 1000000 || widget.mapId == 10000) {
      _gameWorld.addNPC(
        id: 12000,
        name: '希娜',
        position: Vector2(400, 0),
      );
    }
  }

  void _spawnFallbackMobs() {
    for (int i = 0; i < 5; i++) {
      final template = MobCatalog.templates[i % MobCatalog.templates.length];
      final x = (widget.mapWidth / 2) + (i - 2) * 140;
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
        posX: x,
        posY: 0,
        rx0: x - 100,
        rx1: x + 100,
        spawnY: 0,
        speed: 60,
        attackRange: template.attackRange,
        attackCooldown: template.attackCooldown,
      );
      _gameWorld.addMob(mob);
    }
  }

  void _openMenu(String route) {
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GameWidget(
              game: _gameWorld,
              autofocus: true,
              backgroundBuilder: (_) => Container(color: const Color(0xFF87CEEB)),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 88,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0),
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: PlayerStatsBar(),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.settings, color: Color(0xFFFFD54F), size: 22),
              color: const Color(0xFF1a1208),
              onSelected: (value) {
                if (value == 'keys') {
                  KeyConfigDialog.show(context);
                } else {
                  _openMenu(value);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'keys', child: Text('键盘设置')),
                const PopupMenuItem(value: Routes.inventory, child: Text('背包 (I)')),
                const PopupMenuItem(value: Routes.skills, child: Text('技能')),
                const PopupMenuItem(value: Routes.chat, child: Text('聊天')),
                const PopupMenuItem(value: Routes.social, child: Text('社交')),
              ],
            ),
          ),
          Positioned(
            top: 72,
            right: 8,
            child: MiniMapWidget(
              mapWidth: widget.mapWidth.toInt(),
              mapHeight: widget.mapHeight.toInt(),
              playerX: _gameWorld.playerPosition.x,
              playerY: _gameWorld.playerPosition.y,
              mapName: widget.mapName,
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Text(
              GameControls.hint,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11,
                shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
