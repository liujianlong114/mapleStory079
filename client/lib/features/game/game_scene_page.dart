import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../core/resources/assets.dart';
import '../../main.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/game_provider.dart';
import '../../services/api_service.dart';
import '../../services/websocket_service.dart';
import '../../widgets/maple_game_panels.dart';
import '../../widgets/maple_mini_map.dart';
import '../../widgets/maple_status_bar.dart';
import '../../widgets/npc_dialogue_panel.dart';
import '../../game/engine/game_controls.dart';
import '../../game/engine/game_world.dart';
import '../../game/engine/map_life_loader.dart';
import '../../models/mob.dart';
import 'key_config_dialog.dart';
import 'npc_shop_panel.dart';
import 'official_game_viewport.dart';

/// 对话返回结果：用户选择了哪个分支/下一步/关闭
class _DialogueOutcome {
  final NpcDialogueChoice? choice;
  final int? choiceIndex;
  final bool isNext;
  final bool isClose;
  const _DialogueOutcome({
    this.choice,
    this.choiceIndex,
    this.isNext = false,
    this.isClose = false,
  });
  factory _DialogueOutcome.choice(NpcDialogueChoice c, int idx) =>
      _DialogueOutcome(choice: c, choiceIndex: idx);
  factory _DialogueOutcome.next() => const _DialogueOutcome(isNext: true);
  factory _DialogueOutcome.close() => const _DialogueOutcome(isClose: true);
}

/// 游戏场景页（Flutter 壳 + Flame [GameWorld]）
///
/// **流程**：等 [GameWorld.mapReady] → 按地图 foothold 生成玩家/NPC/怪 → WebSocket 同步。
/// **在用**：本页 + GameWorld + WzMapLayer；旧 TileMapLayer 仅作无 JSON 回退。
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
  final int playerCap;
  final int playerCape;
  final int playerGlove;
  final int playerShield;
  final int playerFaceAcc;
  final int playerEyeAcc;
  final int playerEarring;
  final int playerLongcoat;

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
    this.playerCap = 0,
    this.playerCape = 0,
    this.playerGlove = 0,
    this.playerShield = 0,
    this.playerFaceAcc = 0,
    this.playerEyeAcc = 0,
    this.playerEarring = 0,
    this.playerLongcoat = 0,
  });

  @override
  State<GameScenePage> createState() => _GameScenePageState();
}

class _GameScenePageState extends State<GameScenePage> {
  late final GameWorld _gameWorld;
  late final WebSocketService _ws;
  final ValueNotifier<int> _minimapTick = ValueNotifier(0);
  bool _shopOpen = false;
  GameUiPanel? _openPanel;
  NPCComponent? _shopNpc;
  bool _debugShowFh = false;
  bool _debugShowFoot = false;

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
      playerInitial: Vector2(widget.initialPosX, widget.initialPosY),
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
      playerCap: widget.playerCap,
      playerCape: widget.playerCape,
      playerGlove: widget.playerGlove,
      playerShield: widget.playerShield,
      playerFaceAcc: widget.playerFaceAcc,
      playerEyeAcc: widget.playerEyeAcc,
      playerEarring: widget.playerEarring,
      playerLongcoat: widget.playerLongcoat,
    );
    _gameWorld.ws = _ws;
    _gameWorld.api = ApiService();
    _gameWorld.hp = widget.initialHp;
    _gameWorld.maxHp = widget.initialMaxHp;
    _gameWorld.mp = widget.initialMp;
    _gameWorld.maxMp = widget.initialMaxMp;
    _gameWorld.level = widget.initialLevel;
    _gameWorld.onNpcInteract = _onNpcInteract;
    _gameWorld.onViewChanged = () => _minimapTick.value++;
    _gameWorld.onMapWarp = _onPortalWarp;
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
    _gameWorld.onViewChanged = null;
    _minimapTick.dispose();
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
        final dialogue = row['description'] as String? ?? '';
        final hasShop = row['has_shop'] == true;
        final x = (row['position_x'] as num?)?.toDouble() ??
            (row['pos_x'] as num?)?.toDouble() ??
            (row['x'] as num?)?.toDouble() ??
            widget.mapWidth / 2;
        if (id == 0) continue;
        _gameWorld.addNPC(
          id: id,
          name: name,
          position: Vector2(x, 0),
          hasShop: hasShop,
          dialogue: dialogue,
        );
      }
    } else if (widget.mapId == 1000000 || widget.mapId == 1000001) {
      final spawns = await loadMapLifeNpcs(widget.mapId);
      for (final npc in spawns) {
        _gameWorld.addNPC(
          id: npc.id,
          name: npc.name,
          dialogue: npc.dialogue,
          hasShop: npc.hasShop,
          feetY: npc.y,
          footholdId: npc.footholdId,
          position: Vector2(npc.x, npc.y),
        );
      }
    }
  }

  Future<void> _onPortalWarp(int targetMapId, String targetPortalName) async {
    if (!mounted) return;
    final gp = context.read<GameProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('传送中 → 地图 $targetMapId ($targetPortalName)')),
    );
    final ok = await gp.warpToMap(targetMapId, portalName: targetPortalName);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('目标地图尚未就绪，请稍后再试')),
      );
      return;
    }
    Navigator.of(context).pushReplacementNamed(Routes.gameScene);
  }

  void _onNpcInteract(NPCComponent npc) {
    if (npc.hasShop) {
      setState(() {
        _shopNpc = npc;
        _shopOpen = true;
      });
      return;
    }
    _showServerNpcDialogue(npc.npcId, npc.npcName);
  }

  Future<void> _showServerNpcDialogue(int npcId, String fallbackName) async {
    final api = ApiService();
    try {
      final res = await api.startNpcDialogue(
        npcId: npcId,
        characterId: widget.characterId,
      );
      if (!mounted) return;
      final data = res['data'] as Map<String, dynamic>? ?? res;
      final nodeJson = data['node'] as Map<String, dynamic>?;
      if (nodeJson == null) {
        _showFallbackDialogue(fallbackName);
        return;
      }
      await _runDialogueLoop(npcId, NpcDialogueNode.fromJson(nodeJson));
    } catch (_) {
      if (mounted) _showFallbackDialogue(fallbackName);
    }
  }

  void _showFallbackDialogue(String npcName) {
    showDialog<void>(
      context: context,
      builder: (ctx) => NpcDialoguePanel(
        node: NpcDialogueNode(
          id: 'start',
          speaker: npcName,
          text: '你好，冒险者！',
          choices: const [NpcDialogueChoice(text: '再见', action: 'close')],
        ),
        onChoice: (_, __) => Navigator.of(ctx).pop(),
        onNext: () => Navigator.of(ctx).pop(),
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  Future<void> _runDialogueLoop(int npcId, NpcDialogueNode node) async {
    while (mounted) {
      final result = await showDialog<_DialogueOutcome>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => NpcDialoguePanel(
          node: node,
          onChoice: (c, idx) => Navigator.of(ctx).pop(_DialogueOutcome.choice(c, idx)),
          onNext: () => Navigator.of(ctx).pop(_DialogueOutcome.next()),
          onClose: () => Navigator.of(ctx).pop(_DialogueOutcome.close()),
        ),
      );
      if (!mounted) return;
      if (result == null) return;

      if (result.isClose) return;

      // 纯台词节点的"下一步"：带 nextId 时按 nextId 推进；无 nextId 时按 choiceIndex=-1 走默认分支
      // choice 节点的某个选项：按 choiceIndex 走
      final api = ApiService();
      try {
        String? effectiveNextId;
        if (result.isNext) {
          if (node.nextId != null && node.nextId!.isNotEmpty) {
            effectiveNextId = node.nextId;
          } else if (node.choices.isNotEmpty) {
            effectiveNextId = node.choices.first.nextId;
          }
        }
        final res = await api.continueNpcDialogue(
          npcId: npcId,
          characterId: widget.characterId,
          nodeId: node.id,
          choiceIndex: result.choiceIndex ?? -1,
          nextId: effectiveNextId,
        );
        if (!mounted) return;
        final effectsPayload = res['effects'] as Map<String, dynamic>? ??
            (res['data'] as Map<String, dynamic>?)?['effects'] as Map<String, dynamic>?;
        if (effectsPayload != null) {
          final gp = context.read<GameProvider>();
          final mesos = (effectsPayload['new_mesos'] as num?)?.toInt();
          final hp = (effectsPayload['new_hp'] as num?)?.toInt();
          final mp = (effectsPayload['new_mp'] as num?)?.toInt();
          gp.syncFromGameWorld(mesos: mesos, hp: hp, mp: mp);
          _gameWorld.onStatChange?.call(mesos: mesos, hp: hp, mp: mp);
          // 传送门：检测到新地图 id 时调用 warpToMap 并刷新场景
          final newMapId = (effectsPayload['new_map_id'] as num?)?.toInt();
          if (newMapId != null && newMapId > 0) {
            final px = (effectsPayload['new_position_x'] as num?)?.toDouble();
            final py = (effectsPayload['new_position_y'] as num?)?.toDouble();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('传送中 → 地图 $newMapId')),
              );
            }
            // 先尝试走 /game/change-map（确保服务端坐标落位）
            final ok = await gp.warpToMap(newMapId);
            if (!mounted) return;
            if (ok) {
              if (px != null || py != null) {
                gp.syncFromGameWorld(posX: px, posY: py);
              }
              Navigator.of(context).pushReplacementNamed(Routes.gameScene);
              return;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('目标地图尚未就绪')),
              );
            }
          }
        }
        final data = res['data'] as Map<String, dynamic>? ?? res;
        final nodeJson = data['node'] as Map<String, dynamic>?;
        if (nodeJson == null) return;
        node = NpcDialogueNode.fromJson(nodeJson);
        if (node.isEnd && node.choices.isEmpty && node.nodeType != 'say') return;
      } catch (_) {
        return;
      }
    }
  }

  int _currentMesos() {
    return context.read<GameProvider>().mesos;
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

  void _togglePanel(GameUiPanel panel) {
    AudioManager().playUiClick();
    setState(() {
      _openPanel = _openPanel == panel ? null : panel;
    });
    if (_openPanel == GameUiPanel.inventory) {
      context.read<InventoryProvider>().loadInventory(widget.characterId);
    }
  }

  void _closePanel() => setState(() => _openPanel = null);

  void _openMenu(String route) {
    AudioManager().playUiClick();
    Navigator.pushNamed(context, route);
  }

  void _showGameMenu(BuildContext context) {
    AudioManager().playUiClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF2d1f10),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.keyboard, color: Color(0xFFffe08a)),
              title: const Text('键盘设置', style: TextStyle(color: Colors.white)),
              onTap: () {
                AudioManager().playUiClick();
                Navigator.pop(ctx);
                KeyConfigDialog.show(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2, color: Color(0xFFffe08a)),
              title: const Text('背包', style: TextStyle(color: Colors.white)),
              onTap: () {
                AudioManager().playUiClick();
                Navigator.pop(ctx);
                _openMenu(Routes.inventory);
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: Color(0xFFffe08a)),
              title: const Text('技能', style: TextStyle(color: Colors.white)),
              onTap: () {
                AudioManager().playUiClick();
                Navigator.pop(ctx);
                _openMenu(Routes.skills);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Color(0xFFffe08a)),
              title: const Text('社交', style: TextStyle(color: Colors.white)),
              onTap: () {
                AudioManager().playUiClick();
                Navigator.pop(ctx);
                _openMenu(Routes.social);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: OfficialGameSceneShell(
        game: GameWidget(
          game: _gameWorld,
          autofocus: true,
        ),
        overlays: [
          SizedBox(
            width: 800,
            height: 600,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
              if (_shopOpen && _shopNpc != null)
                NpcShopPanel(
                  npcId: _shopNpc!.npcId,
                  npcName: _shopNpc!.npcName,
                  characterId: widget.characterId,
                  mesos: _currentMesos(),
                  onClose: () => setState(() {
                    _shopOpen = false;
                    _shopNpc = null;
                  }),
                  onMesosChanged: (m) {
                    context.read<GameProvider>().syncFromGameWorld(mesos: m);
                    _gameWorld.onStatChange?.call(mesos: m);
                  },
                ),
              if (_openPanel == GameUiPanel.inventory)
                MapleInventoryPanel(onClose: _closePanel),
              if (_openPanel == GameUiPanel.equip)
                MapleEquipPanel(onClose: _closePanel),
              if (_openPanel == GameUiPanel.stat)
                MapleStatPanel(onClose: _closePanel),
              if (_openPanel == GameUiPanel.skill)
                MapleSkillPanel(onClose: _closePanel),
              Positioned(
                left: 10,
                top: 10,
                child: ValueListenableBuilder<int>(
                  valueListenable: _minimapTick,
                  builder: (_, __, ___) => MapleMiniMap(
                    vrLeft: _gameWorld.vrLeft,
                    vrRight: _gameWorld.vrRight,
                    vrTop: _gameWorld.vrTop,
                    vrBottom: _gameWorld.vrBottom,
                    cameraX: _gameWorld.cameraWorldX,
                    cameraY: _gameWorld.cameraWorldY,
                    viewW: _gameWorld.viewportW,
                    viewH: _gameWorld.viewportH,
                    playerX: _gameWorld.playerPosition.x,
                    playerY: _gameWorld.playerPosition.y,
                    mapName: widget.mapName,
                    mapId: widget.mapId,
                    miniMapAsset: _gameWorld.miniMapAsset,
                    npcDots: _gameWorld.npcs
                        .map((n) => Offset(n.position.x, n.position.y))
                        .toList(),
                    mobDots: _gameWorld.mobs
                        .map((m) => Offset(m.position.x, m.position.y))
                        .toList(),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                bottom: 0,
                child: MapleStatusBar(
                  onMenu: () => _showGameMenu(context),
                  onChat: () => _openMenu(Routes.chat),
                  onShop: () {},
                  onEquip: () => _togglePanel(GameUiPanel.equip),
                  onInventory: () => _togglePanel(GameUiPanel.inventory),
                  onSkills: () => _togglePanel(GameUiPanel.skill),
                  onStats: () => _togglePanel(GameUiPanel.stat),
                  onKeyConfig: () => showDialog(
                    context: context,
                    builder: (_) => const KeyConfigDialog(),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: ValueListenableBuilder<int>(
                  valueListenable: _minimapTick,
                  builder: (_, __, ___) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _debugChip('FH', _debugShowFh, (v) {
                          setState(() {
                            _debugShowFh = v;
                            GameWorld.debugShowFootholds = v;
                          });
                        }),
                        const SizedBox(width: 6),
                        _debugChip('脚点', _debugShowFoot, (v) {
                          setState(() {
                            _debugShowFoot = v;
                            GameWorld.debugShowFootPoint = v;
                          });
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _debugChip(String label, bool value, void Function(bool) onChange) {
    return GestureDetector(
      onTap: () => onChange(!value),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: value ? Colors.green.withOpacity(0.8) : Colors.grey.withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    ),
  );
}

}
