import 'dart:async';

import 'dart:math' as math;

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/resources/avatar_assets.dart';
import '../../core/resources/assets.dart';
import '../../core/resources/map_meta.dart';
import '../../models/char_look.dart';
import '../../models/mob.dart';
import '../../services/api_service.dart';
import '../../services/websocket_service.dart';
import 'game_controls.dart';
import 'map_foothold.dart';
import 'maple_island_map_layer.dart';
import 'portal_component.dart';
import 'wz_map_layer.dart';
import 'wz_map_foreground.dart';
import 'sprite_loader.dart';

/// 079 横版游戏主世界（Flame Game）
///
/// **在用模块**：
/// - [WzMapLayer] / [WzMapForegroundLayer] — WZ 地图 back + tile/obj（有 JSON 时）
/// - [MapleIslandMapLayer] — 无 JSON 时彩虹岛程序化回退
/// - [PlayerComponent] — 本地玩家（WZ 行走/站立动画 + 部件合成回退）
/// - [MobComponent] / [NPCComponent] — 怪物与 NPC
/// - [MapFootholds] — 地面碰撞与跳跃
///
/// **已弃用/回退**： [TileMapLayer] 仅在没有地图 JSON 时显示格子占位。
class GameWorld extends FlameGame with HasCollisionDetection, KeyboardEvents {
  GameWorld({
    this.mapId = 1,
    this.mapName = '未知地图',
    this.mapWidth = 1600,
    this.mapHeight = 900,
    this.tileSize = 80,
    this.playerInitial,
    this.characterId = 1,
    this.jobId = 0,
    this.ws,
    this.str = 10,
    this.dex = 4,
    this.intelligence = 4,
    this.luk = 4,
    this.exp = 0,
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
  })  : _spawnY = playerInitial?.y ?? 605,
        player = PlayerComponent(
          position: Vector2(
            playerInitial?.x ?? mapWidth / 2,
            playerInitial?.y ?? 605,
          ),
          size: Vector2(48, 64),
          gender: playerGender,
          face: playerFace,
          hair: playerHair,
          top: playerTop,
          bottom: playerBottom,
          shoes: playerShoes,
          weapon: playerWeapon,
          cap: playerCap,
          cape: playerCape,
          glove: playerGlove,
          shield: playerShield,
          faceAcc: playerFaceAcc,
          eyeAcc: playerEyeAcc,
          earring: playerEarring,
          longcoat: playerLongcoat,
        );

  // ===== 地图属性 =====
  final int mapId;
  final String mapName;
  final double mapWidth;
  final double mapHeight;
  final double tileSize;
  final Vector2? playerInitial;
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

  /// 地图默认出生点 Y（仅初始落点回退）
  final double _spawnY;
  MapFootholds? _footholds;
  final List<PortalComponent> _portals = [];
  double _portalCooldown = 0;
  double _vrLeft = 0;
  double _vrRight = 1600;
  double _vrTop = 0;
  double _vrBottom = 600;

  double get vrLeft => _vrLeft;
  double get vrRight => _vrRight;
  double get vrTop => _vrTop;
  double get vrBottom => _vrBottom;
  double get cameraWorldX => camera.viewfinder.position.x;
  double get cameraWorldY => camera.viewfinder.position.y;
  /// 079 固定逻辑视口（不读 game.size，避免布局前断言崩溃）
  double get viewportW => MapMeta.officialViewportW;
  double get viewportH => MapMeta.officialViewportH;

  /// 小地图 / HUD 刷新（相机跟随每帧，延迟到帧末避免 build 中 setState）
  VoidCallback? onViewChanged;
  bool _viewNotifyQueued = false;

  void _scheduleViewNotify() {
    final cb = onViewChanged;
    if (cb == null) return;
    if (_viewNotifyQueued) return;
    _viewNotifyQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewNotifyQueued = false;
      cb();
    });
  }

  // 垂直运动（079：Alt 跳跃 + 重力）
  double _vy = 0;
  bool _onGround = true;
  bool _jumpHeldLast = false;
  static const double _gravity = 2000;
  static const double _jumpSpeed = -640;
  static const double _cameraFootOffset = 300; // 由 _syncCamera 按 viewH/2 覆盖

  void Function()? onOpenKeyConfig;

  /// 当前玩家所在 x 的可走 foothold Y
  double get groundY => groundAt(player.position.x, feetY: player.position.y);

  double? tryGroundAt(double x, {double? feetY}) {
    if (_footholds == null) return null;
    return _footholds!.groundYAt(x, feetY: feetY ?? player.position.y);
  }

  double groundAt(double x, {double? feetY, bool allowFallback = false}) {
    final gy = tryGroundAt(x, feetY: feetY);
    if (gy != null) return gy;
    if (!allowFallback) return player.position.y;
    return _footholds?.lowestWalkableYAt(x) ?? _spawnY;
  }

  double _snapSpawnY(double x, double hintY) =>
      _footholds?.snapSpawnY(x, hintY) ?? hintY;

  // ===== 角色属性 =====
  final int characterId;
  final int jobId;
  int str = 10;
  int dex = 4;
  int intelligence = 4;
  int luk = 4;
  int exp = 0;
  int ap = 0;
  int sp = 0;

  // 玩家运行时数据（供 UI 读取）
  int hp = 50;
  int maxHp = 50;
  int mp = 50;
  int maxMp = 50;
  int level = 1;

  // 游戏循环统计
  int attackCount = 0;
  double uptime = 0;
  int killedMobs = 0;
  int damageDealt = 0;
  int mesosGained = 0;

  // 状态机
  bool _isDead = false;
  bool get isDead => _isDead;
  double _reviveTimer = 0;

  // ===== 外部回调（需在创建后、运行前设置）=====
  WebSocketService? ws;
  ApiService? api;
  void Function(int newLevel)? onLevelUp;
  void Function()? onPlayerDead;
  void Function({
    int? hp,
    int? maxHp,
    int? mp,
    int? maxMp,
    int? level,
    int? exp,
    int? mesos,
    double? posX,
    double? posY,
  })? onStatChange;
  void Function(NPCComponent npc)? onNpcInteract;
  void Function(int targetMapId, String targetPortalName)? onMapWarp;

  // ===== 实体集合 =====
  final PlayerComponent player;
  final List<MobComponent> mobs = [];
  final List<NPCComponent> npcs = [];
  final _mapReady = Completer<void>();

  /// 地图 foothold / 图层加载完成（供外部 spawn 实体前等待）
  Future<void> get mapReady => _mapReady.future;
  final Map<int, RemotePlayerComponent> remotePlayers = {};
  final Map<String, GroundLootComponent> _groundLoots = {};

  // ===== 节流器 =====
  double _positionThrottle = 0;
  static const double _positionThrottleMs = 50 / 1000;
  static const double _moveApiThrottleMs = 1500 / 1000;
  bool _serverMobSync = false;
  bool _moveApiInFlight = false;
  double _moveApiCooldown = 0;

  // 输入状态（由 Flame KeyboardEvents 同步）
  Set<LogicalKeyboardKey> _keysPressed = {};

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _keysPressed = Set<LogicalKeyboardKey>.from(keysPressed);

    if (event is KeyDownEvent && !isDead) {
      if (GameControls.isKeyConfig(event.logicalKey)) {
        onOpenKeyConfig?.call();
      } else if (GameControls.isAttack(event.logicalKey)) {
        _performAttack();
      } else if (GameControls.isPickup(event.logicalKey)) {
        if (!tryInteractNearestNpc()) {
          _tryAutoPickup(force: true);
        }
      }
    }
    return KeyEventResult.handled;
  }

  // ============ 键盘输入（兼容旧调用）============

  void handleKeyDown(LogicalKeyboardKey key, bool isDown) {
    if (isDown) {
      _keysPressed.add(key);
      if (GameControls.isAttack(key)) {
        _performAttack();
      } else if (GameControls.isPickup(key)) {
        if (!tryInteractNearestNpc()) {
          _tryAutoPickup(force: true);
        }
      }
    } else {
      _keysPressed.remove(key);
    }
  }

  bool get _useIslandMap =>
      mapId == 0 ||
      mapId == 10000 ||
      mapId == 1000000 ||
      mapId == 1000001 ||
      mapId == 1000002 ||
      (mapId >= 10000 && mapId <= 20000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await GameControls.ensureLoaded();

    // 079 固定逻辑视口 800×600（HeavenClient Configuration）
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(
        MapMeta.officialViewportW,
        MapMeta.officialViewportH,
      ),
    );

    final mapFull = await MapMetaFull.load(mapId);
    _footholds = mapFull?.footholds;
    if (mapFull != null) {
      _vrLeft = mapFull.meta.vrLeft.toDouble();
      _vrRight = mapFull.meta.vrRight.toDouble();
      _vrTop = mapFull.meta.vrTop.toDouble();
      _vrBottom = mapFull.meta.vrBottom.toDouble();
      camera.backdrop = WzMapLayer(
        mapId: mapId,
        width: mapWidth,
        height: mapHeight,
      );
      if (mapFull.mapLayers.isNotEmpty) {
        await world.add(WzMapForegroundLayer(
          mapId: mapId,
          basePriority: -4,
          width: mapWidth,
          height: mapHeight,
        ));
      }
    } else if (_useIslandMap) {
      await world.add(MapleIslandMapLayer(mapId: mapId, width: mapWidth, height: mapHeight));
    } else {
      await world.add(TileMapLayer(
        width: mapWidth,
        height: mapHeight,
        tileSize: tileSize,
        mapId: mapId,
      ));
      await world.add(_WorldBackground(width: mapWidth, height: mapHeight));
    }

    // 脚点对齐 foothold（079：出生点必须落在可走面上）
    final sx = playerInitial?.x ?? mapFull?.meta.spawnX.toDouble() ?? mapWidth / 2;
    final hintY = playerInitial?.y ?? mapFull?.meta.spawnY.toDouble() ?? _spawnY;
    final sy = _snapSpawnY(sx, hintY);
    player.position = Vector2(sx, sy);
    _onGround = true;
    _vy = 0;

    await world.add(player);

    if (mapFull != null) {
      await _spawnPortals(mapFull.portals);
    }

    camera.viewfinder.anchor = Anchor.topLeft;
    _syncCamera();
    // 不用 setBounds：边界外会露出纯色底，产生随镜头移动的「蓝框」

    // ===== 音频：优先服务端 music 字段，否则按 mapId 匹配 =====
    final bgm = bgmAsset ?? BgmAssets.byMapId(mapId);
    if (bgm != null) {
      try {
        await AudioManager().playBgm(bgm);
      } catch (_) {}
    }

    // ===== WebSocket：监听服务端消息（伤害/经验/死亡/复活/远程玩家位置） =====
    ws?.addListener(WsMessageType.damage, _onServerDamage);
    ws?.addListener(WsMessageType.exp, _onServerExp);
    ws?.addListener(WsMessageType.dead, _onServerDead);
    ws?.addListener(WsMessageType.revive, _onServerRevive);
    ws?.addListener(WsMessageType.position, _onServerRemotePosition);
    ws?.addListener(WsMessageType.loot, _onServerLoot);
    ws?.addListener(WsMessageType.mobSpawn, _onServerMobSpawn);
    ws?.addListener(WsMessageType.mobMove, _onServerMobMove);
    ws?.addListener(WsMessageType.mobDead, _onServerMobDead);
    ws?.addListener(WsMessageType.mobRespawn, _onServerMobRespawn);
    if (ws?.isConnected == true) {
      _serverMobSync = true;
    }
    _loadExistingGroundLoot();
    if (!_mapReady.isCompleted) _mapReady.complete();
  }

  Future<void> _loadExistingGroundLoot() async {
    if (api == null) return;
    final rows = await api!.listGroundLoot(mapId);
    for (final row in rows) {
      _spawnGroundLootFromMap(row);
    }
  }

  @override
  void onRemove() {
    ws?.removeListener(WsMessageType.damage, _onServerDamage);
    ws?.removeListener(WsMessageType.exp, _onServerExp);
    ws?.removeListener(WsMessageType.dead, _onServerDead);
    ws?.removeListener(WsMessageType.revive, _onServerRevive);
    ws?.removeListener(WsMessageType.position, _onServerRemotePosition);
    ws?.removeListener(WsMessageType.loot, _onServerLoot);
    ws?.removeListener(WsMessageType.mobSpawn, _onServerMobSpawn);
    ws?.removeListener(WsMessageType.mobMove, _onServerMobMove);
    ws?.removeListener(WsMessageType.mobDead, _onServerMobDead);
    ws?.removeListener(WsMessageType.mobRespawn, _onServerMobRespawn);
    try {
      AudioManager().stopBgm();
    } catch (_) {}
    super.onRemove();
  }

  // ============ 主循环 ============

  @override
  void update(double dt) {
    super.update(dt);
    uptime += dt;
    if (_moveApiCooldown > 0) {
      _moveApiCooldown -= dt;
    }

    // --- 死亡状态机：暂停移动与攻击，等待复活 ---
    if (isDead) {
      _reviveTimer -= dt;
      if (_reviveTimer <= 0) {
        _doRevive();
      }
      return;
    }

    if (_portalCooldown > 0) {
      _portalCooldown -= dt;
    }

    // --- 079 移动 + 跳跃 + foothold ---
    bool moved = false;
    final left = GameControls.anyMoveLeft(_keysPressed);
    final right = GameControls.anyMoveRight(_keysPressed);
    if (left && !right) {
      player.moveHorizontal(-1, dt);
      moved = true;
    } else if (right && !left) {
      player.moveHorizontal(1, dt);
      moved = true;
    }
    player.position.x = player.position.x.clamp(_vrLeft + 16, _vrRight - 16);

    final jumpNow = GameControls.anyJump(_keysPressed);
    if (jumpNow && !_jumpHeldLast && _onGround) {
      _vy = _jumpSpeed;
      _onGround = false;
      player.animationState = 'jump';
    }
    _jumpHeldLast = jumpNow;

    if (!_onGround) {
      _vy += _gravity * dt;
      player.position.y += _vy * dt;
      final landing = _footholds?.landingYAt(player.position.x, player.position.y);
      if (landing != null && player.position.y >= landing - 2 && _vy >= 0) {
        player.position.y = landing;
        _vy = 0;
        _onGround = true;
        if (!player.isAttacking) {
          player.animationState = moved ? 'walk' : 'idle';
        }
      } else if (player.position.y > _vrBottom + 120) {
        _respawnOnMap();
      }
    } else {
      final gy = tryGroundAt(player.position.x, feetY: player.position.y);
      if (gy == null) {
        _onGround = false;
        _vy = 0;
      } else if (gy > player.position.y + 4) {
        _onGround = false;
        _vy = 0;
      } else {
        player.position.y = gy;
        if (!moved && !player.isAttacking) player.animationState = 'idle';
      }
    }

    _syncCamera();
    _checkPortalWarp();

    if (moved) {
      _positionThrottle -= dt;
      if (_positionThrottle <= 0) {
        _positionThrottle = _positionThrottleMs;
        ws?.sendPosition(
          characterId: characterId,
          x: player.position.x,
          y: player.position.y,
        );
      }
      _scheduleMoveApiSave();
      if (_onGround && !player.isAttacking) player.animationState = 'walk';
    }

    // --- 怪物 AI（无 WS 同步时本地模拟）---
    if (!_serverMobSync) {
      for (final mob in mobs) {
        mob.updateAI(dt, player, onDealDamage: (dmg) {
          if (!mob.mob.isAlive) return;
          hp -= dmg;
          if (hp < 0) hp = 0;
          onStatChange?.call(hp: hp);
          if (hp <= 0) {
            _doDead();
          }
        });
      }
    } else {
      for (final mob in mobs) {
        mob.applyServerTick(dt);
      }
    }

    // --- 自动拾取附近掉落 ---
    _tryAutoPickup();

    // --- 经验与升级检查 ---
    if (exp >= GameConstants.expRequired(level)) {
      _doLevelUp();
    }
  }

  void _syncCamera() {
    const viewW = MapMeta.officialViewportW;
    const viewH = MapMeta.officialViewportH;
    // 079 HeavenClient：viewy = VHEIGHT/2 - playerY → camY = playerY - viewH/2
    var camX = player.position.x - viewW / 2;
    var camY = player.position.y - viewH / 2;
    camX = camX.clamp(_vrLeft, math.max(_vrLeft, _vrRight - viewW));
    camY = camY.clamp(_vrTop, math.max(_vrTop, _vrBottom - viewH));
    camera.viewfinder.position = Vector2(camX, camY);
    if (hasLayout) _scheduleViewNotify();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _syncCamera();
  }

  int? _lastTargetMobId;

  void _performAttack() {
    if (isDead) return;
    if (!player.attack()) return;
    attackCount += 1;
    _doMeleeHit(range: 160);
    ws?.sendAttack(
      characterId: characterId,
      skillId: null,
      targetId: _lastTargetMobId,
      x: player.position.x,
      y: player.position.y,
    );
    try {
      AudioManager().playSfx(SfxAssets.hit);
    } catch (_) {}
  }

  void _doMeleeHit({required double range}) {
    final r2 = range * range;
    MobComponent? nearest;
    double nearestD2 = double.infinity;
    for (final mob in mobs) {
      if (!mob.mob.isAlive) continue;
      final dx = mob.position.x - player.position.x;
      final dy = mob.position.y - player.position.y;
      final d2 = dx * dx + dy * dy;
      if (d2 > r2) continue;
      if (d2 < nearestD2) {
        nearestD2 = d2;
        nearest = mob;
      }
    }
    if (nearest == null) return;
    _lastTargetMobId = nearest.mob.mobId;

    if (api != null) {
      _resolveServerAttack(nearest);
      return;
    }

    // 离线回退：本地伤害计算
    final base = jobId == 1
        ? (str * 1.2 + level)
        : jobId == 2
            ? (intelligence * 1.3 + level)
            : jobId == 3
                ? (dex * 1.25 + level)
                : jobId == 4
                    ? (luk * 1.4 + level)
                    : jobId == 5
                        ? (str * 1.1 + dex * 0.8 + level)
                        : (str * 1.0 + level);
    final critRoll = math.Random().nextDouble();
    final critChance = 0.05 + luk * 0.005 + (jobId == 4 ? 0.1 : 0.0);
    final isCrit = critRoll < critChance;
    final dmgRaw = base.toInt() + math.Random().nextInt(4);
    final finalDmg = ((isCrit ? dmgRaw * 2 : dmgRaw).toInt()).clamp(1, 99999);
    _applyHitVisuals(nearest, finalDmg, isCrit);
    _applyLocalKillRewards(nearest);
  }

  Future<void> _resolveServerAttack(MobComponent nearest) async {
    final result = await api!.playerAttackMob(
      characterId: characterId,
      mobId: nearest.mob.mobId,
      instanceId: nearest.mob.id,
      mapId: mapId,
      x: nearest.position.x,
      y: nearest.position.y,
    );
    if (result['is_hit'] == false) return;

    final dmg = (result['damage'] as num?)?.toInt() ?? 1;
    final isCrit = result['is_critical'] == true;
    final targetHp = (result['target_hp'] as num?)?.toInt();
    _applyHitVisuals(nearest, dmg, isCrit, applyDamage: targetHp == null);
    if (targetHp != null) {
      nearest.setHp(targetHp);
    }

    if (result['mob_killed'] == true) {
      final expGain = (result['exp_gained'] as num?)?.toInt() ?? 0;
      final mesos = (result['mesos_gained'] as num?)?.toInt() ?? 0;
      if (expGain > 0) gainExp(expGain);
      if (mesos > 0) {
        mesosGained += mesos;
        onStatChange?.call(mesos: mesosGained);
        try {
          AudioManager().playSfx(SfxAssets.mesos);
        } catch (_) {}
      }
      killedMobs += 1;
      if (result['level_up'] == true) {
        onLevelUp?.call(level);
      }
      final loots = result['ground_loots'];
      if (loots is List) {
        for (final raw in loots) {
          if (raw is Map) {
            _spawnGroundLootFromMap(Map<String, dynamic>.from(raw));
          }
        }
      }
    }
  }

  void _applyHitVisuals(
    MobComponent nearest,
    int finalDmg,
    bool isCrit, {
    bool applyDamage = true,
  }) {
    damageDealt += finalDmg;
    if (applyDamage) nearest.takeDamage(finalDmg);
    world.add(DamagePopup(
      damage: finalDmg,
      origin: nearest.position.clone(),
      isCritical: isCrit,
    ));
    ws?.sendDamage(
      characterId: characterId,
      targetId: nearest.mob.mobId,
      damage: finalDmg,
      critical: isCrit,
    );
  }

  void _applyLocalKillRewards(MobComponent nearest) {
    if (!nearest.mob.isAlive) {
      killedMobs += 1;
      final expGain = nearest.mob.level * 4 + 10;
      gainExp(expGain);
      final mesos = nearest.mob.level * 2 + math.Random().nextInt(5);
      mesosGained += mesos;
      onStatChange?.call(mesos: mesosGained);
      try {
        AudioManager().playSfx(SfxAssets.mesos);
      } catch (_) {}
    }
  }

  void _spawnGroundLootFromMap(Map<String, dynamic> row) {
    final dropId = row['drop_id'] as String? ?? '';
    if (dropId.isEmpty || _groundLoots.containsKey(dropId)) return;
    final itemId = (row['item_id'] as num?)?.toInt() ?? 0;
    final qty = (row['quantity'] as num?)?.toInt() ?? 1;
    final x = (row['x'] as num?)?.toDouble() ?? player.position.x;
    final y = (row['y'] as num?)?.toDouble() ?? player.position.y;
    spawnGroundLoot(dropId: dropId, itemId: itemId, quantity: qty, x: x, y: y);
  }

  void spawnGroundLoot({
    required String dropId,
    required int itemId,
    required int quantity,
    required double x,
    required double y,
  }) {
    if (_groundLoots.containsKey(dropId)) return;
    final comp = GroundLootComponent(
      dropId: dropId,
      itemId: itemId,
      quantity: quantity,
      position: Vector2(x, y),
    );
    _groundLoots[dropId] = comp;
    world.add(comp);
  }

  void removeGroundLoot(String dropId) {
    _groundLoots.remove(dropId)?.removeFromParent();
  }

  void _tryAutoPickup({bool force = false}) {
    const pickupRange = 70.0;
    const r2 = pickupRange * pickupRange;
    for (final entry in _groundLoots.entries.toList()) {
      final loot = entry.value;
      final dx = loot.position.x - player.position.x;
      final dy = loot.position.y - player.position.y;
      if (!force && dx * dx + dy * dy > r2) continue;
      if (force && dx * dx + dy * dy > r2 * 2.25) continue;
      _pickupLoot(entry.key);
      break;
    }
  }

  void _pickupLoot(String dropId) async {
    removeGroundLoot(dropId);
    try {
      AudioManager().playSfx(SfxAssets.pickup);
    } catch (_) {}
    if (api != null) {
      await api!.pickupLoot(
        characterId: characterId,
        dropId: dropId,
        x: player.position.x,
        y: player.position.y,
      );
      onInventoryChanged?.call();
    } else {
      ws?.sendLootPickup(
        characterId: characterId,
        dropId: dropId,
        x: player.position.x,
        y: player.position.y,
      );
    }
  }

  /// 拾取后刷新背包（由 GameScenePage 绑定 InventoryProvider）
  void Function()? onInventoryChanged;

  void _onServerLoot(WsMessage msg) {
    final p = msg.payload;
    final action = p['action'] as String? ?? '';
    final dropId = p['drop_id'] as String? ?? '';
    if (action == 'spawn') {
      _spawnGroundLootFromMap(p);
    } else if (action == 'pickup' && dropId.isNotEmpty) {
      removeGroundLoot(dropId);
    }
  }

  // ============ 经验 / 升级 ============
  void gainExp(int amount) {
    if (amount <= 0) return;
    exp += amount;
    ws?.sendExp(characterId: characterId, expGained: amount);
    onStatChange?.call(exp: exp);
  }

  void _doLevelUp() {
    final required = GameConstants.expRequired(level);
    exp -= required;
    level += 1;
    ap += GameConstants.defaultLevelUpAp;
    sp += GameConstants.defaultLevelUpSp;
    // 自动恢复一部分 HP / MP
    maxHp += 10;
    maxMp += 6;
    hp = maxHp;
    mp = maxMp;
    try {
      AudioManager().playSfx(SfxAssets.levelUp);
    } catch (_) {}
    onLevelUp?.call(level);
    onStatChange?.call(
      hp: hp,
      maxHp: maxHp,
      mp: mp,
      maxMp: maxMp,
      level: level,
      exp: exp,
    );
    // 继续检测是否溢出经验连升
    if (exp >= GameConstants.expRequired(level)) {
      _doLevelUp();
    }
  }

  // ============ 死亡与复活 ============
  void _doDead() {
    if (isDead) return;
    try {
      AudioManager().playSfx(SfxAssets.dead);
    } catch (_) {}
    ws?.sendDead(characterId: characterId);
    onPlayerDead?.call();
    // 死亡状态标志 + 5 秒后复活
    hp = 0;
    _reviveTimer = 5.0;
    // 注意：isDead 通过字段存储，此处直接赋值
    _isDead = true;
    onStatChange?.call(hp: hp);
  }

  void _respawnOnMap() {
    final rx = playerInitial?.x ?? mapWidth / 2;
    final gy = groundAt(rx, allowFallback: true);
    player.position = Vector2(rx, gy);
    _vy = 0;
    _onGround = true;
    player.animationState = 'idle';
    _syncCamera();
  }

  void _doRevive() {
    hp = maxHp;
    mp = maxMp;
    final rx = playerInitial?.x ?? mapWidth / 2;
    player.position = Vector2(rx, groundAt(rx, allowFallback: true));
    try {
      AudioManager().playSfx(SfxAssets.revive);
    } catch (_) {}
    ws?.sendRevive(
      characterId: characterId,
      x: player.position.x,
      y: player.position.y,
    );
    _isDead = false;
    onStatChange?.call(hp: hp, maxHp: maxHp, mp: mp, maxMp: maxMp);
  }

  // ============ 外部 API ============

  Future<void> _spawnPortals(List<MapPortalDef> defs) async {
    for (final p in defs) {
      if (p.type == 0 || p.type == 9) continue; // spawn / scripted tutorial
      if (p.targetMap <= 0 || p.targetMap >= 999999999) continue;
      final comp = PortalComponent(
        portalId: p.id,
        portalName: p.name,
        portalType: p.type,
        targetMapId: p.targetMap,
        targetPortalName: p.targetName,
        worldPosition: Vector2(p.x.toDouble(), p.y.toDouble()),
        priority: 20,
      );
      _portals.add(comp);
      await world.add(comp);
    }
  }

  void _checkPortalWarp() {
    if (_portalCooldown > 0 || onMapWarp == null) return;
    final feet = player.position;
    for (final portal in _portals) {
      if (!portal.isVisible) continue;
      if (!portal.containsPoint(feet)) continue;
      if (portal.targetMapId <= 0) continue;
      _portalCooldown = 1.2;
      try {
        AudioManager().playSfx(SfxAssets.portal);
      } catch (_) {}
      onMapWarp?.call(portal.targetMapId, portal.targetPortalName);
      return;
    }
  }

  void movePlayer(Vector2 direction) {
    if (direction.x != 0) {
      player.moveHorizontal(direction.x > 0 ? 1 : -1, 1 / 60);
      player.position.y = groundAt(player.position.x, allowFallback: true);
    }
  }

  /// 横版：所有实体 Y 锁定地面
  double get entityGroundY => groundY;

  void playerAttack() => _performAttack();

  void playerUseSkill(int skillId) => player.useSkill(skillId);

  Vector2 get playerPosition => player.position.clone();

  Map<String, dynamic> get playerStatus => {
        'hp': hp,
        'maxHp': maxHp,
        'mp': mp,
        'maxMp': maxMp,
        'level': level,
        'exp': exp,
        'expRequired': GameConstants.expRequired(level),
        'str': str,
        'dex': dex,
        'int': intelligence,
        'luk': luk,
        'ap': ap,
        'sp': sp,
        'uptime': uptime,
        'attackCount': attackCount,
        'killedMobs': killedMobs,
        'damageDealt': damageDealt,
        'mesosGained': mesosGained,
        'isDead': isDead,
        'remotePlayers': remotePlayers.length,
        'position': {'x': player.position.x, 'y': player.position.y},
      };

  // ============ 服务端消息处理 ============
  void _onServerDamage(WsMessage msg) {
    final payload = msg.payload;
    final dmg = payload['damage'] as int? ?? 0;
    final target = payload['target_id'] as int? ?? 0;
    if (target == characterId) {
      // 服务端对玩家造成伤害
      if (dmg > 0) {
        hp -= dmg;
        if (hp < 0) hp = 0;
        world.add(DamagePopup(
          damage: dmg,
          origin: player.position.clone(),
          isCritical: payload['critical'] == true,
        ));
        if (hp <= 0) _doDead();
      }
    } else {
      // 服务端对某怪物造成伤害
      for (final mob in mobs) {
        if (mob.mob.id == target && mob.mob.isAlive) {
          mob.takeDamage(dmg);
          world.add(DamagePopup(
            damage: dmg,
            origin: mob.position.clone(),
            isCritical: payload['critical'] == true,
          ));
        }
      }
    }
  }

  void _onServerExp(WsMessage msg) {
    final payload = msg.payload;
    final gained = payload['exp_gained'] as int? ?? 0;
    if (gained > 0) exp += gained;
  }

  void _onServerDead(WsMessage msg) {
    final target = msg.payload['character_id'] as int? ?? 0;
    if (target == characterId) {
      _doDead();
    }
  }

  void _onServerRevive(WsMessage msg) {
    final target = msg.payload['character_id'] as int? ?? 0;
    if (target == characterId) {
      _doRevive();
    }
  }

  void _onServerRemotePosition(WsMessage msg) {
    final payload = msg.payload;
    final cid = payload['character_id'] as int?;
    if (cid == null || cid == characterId) return;
    final x = (payload['x'] as num?)?.toDouble() ?? 0.0;
    final name = payload['name'] as String? ?? '玩家$cid';
    updateRemotePlayer(
      characterId: cid,
      name: name,
      position: Vector2(x, groundAt(x, allowFallback: true)),
    );
  }

  void _scheduleMoveApiSave() {
    if (api == null || _moveApiInFlight || _moveApiCooldown > 0) return;
    _moveApiCooldown = _moveApiThrottleMs;
    _moveApiInFlight = true;
    final x = player.position.x;
    final y = player.position.y;
    api!
        .moveCharacter(characterId, x, y)
        .whenComplete(() {
          _moveApiInFlight = false;
        });
  }

  MobComponent? _mobByInstanceId(int instanceId) {
    for (final mob in mobs) {
      if (mob.mob.id == instanceId) return mob;
    }
    return null;
  }

  void _onServerMobSpawn(WsMessage msg) {
    _serverMobSync = true;
    final p = msg.payload;
    final instanceId = (p['instance_id'] as num?)?.toInt() ?? 0;
    if (instanceId == 0) return;
    final existing = _mobByInstanceId(instanceId);
    if (existing != null) {
      existing.applyServerState(p);
      return;
    }
    final templateId = (p['template_id'] as num?)?.toInt() ?? 0;
    final x = (p['x'] as num?)?.toDouble() ?? 0;
    final y = groundAt(x, allowFallback: true);
    final rx0 = (p['rx0'] as num?)?.toDouble() ?? (x - 100);
    final rx1 = (p['rx1'] as num?)?.toDouble() ?? (x + 100);
    final mob = Mob(
      id: instanceId,
      mobId: templateId,
      name: p['name'] as String? ?? '怪物',
      level: (p['mob_level'] as num?)?.toInt() ?? (p['level'] as num?)?.toInt() ?? 1,
      hp: (p['hp'] as num?)?.toInt() ?? 50,
      maxHp: (p['max_hp'] as num?)?.toInt() ?? 50,
      attack: 10,
      defense: 0,
      expReward: 0,
      mesoReward: 0,
      posX: x,
      posY: y,
      rx0: rx0,
      rx1: rx1,
      spawnY: y,
      speed: (p['speed'] as num?)?.toInt() ?? 60,
    );
    final component = MobComponent(mob: mob, position: Vector2(x, y), planeY: y);
    component.applyServerState(p);
    mobs.add(component);
    world.add(component);
  }

  void _onServerMobMove(WsMessage msg) {
    _serverMobSync = true;
    final p = msg.payload;
    final instanceId = (p['instance_id'] as num?)?.toInt() ?? 0;
    if (instanceId == 0) return;
    final mob = _mobByInstanceId(instanceId);
    if (mob == null) {
      final templateId = (p['template_id'] as num?)?.toInt() ?? 0;
      if (templateId > 0) {
        _onServerMobSpawn(msg);
      }
      return;
    }
    mob.applyServerState(p, minDelta: 1.0);
  }

  void _onServerMobDead(WsMessage msg) {
    final instanceId = (msg.payload['instance_id'] as num?)?.toInt() ?? 0;
    final mob = _mobByInstanceId(instanceId);
    if (mob == null) return;
    mob.setHp(0);
  }

  void _onServerMobRespawn(WsMessage msg) {
    final p = msg.payload;
    final instanceId = (p['instance_id'] as num?)?.toInt() ?? 0;
    var mob = _mobByInstanceId(instanceId);
    if (mob == null) {
      _onServerMobSpawn(msg);
      mob = _mobByInstanceId(instanceId);
    }
    if (mob == null) return;
    final hp = (p['hp'] as num?)?.toInt() ?? mob.mob.maxHp;
    mob.setHp(hp);
    mob.applyServerState(p);
  }

  /// 添加/更新远程玩家的位置信息（由 WebSocket 消息驱动）
  void updateRemotePlayer({
    required int characterId,
    required String name,
    required Vector2 position,
  }) {
    final existing = remotePlayers[characterId];
    if (existing != null) {
      existing.targetPosition = position;
      return;
    }
    final c = RemotePlayerComponent(
      characterId: characterId,
      name: name,
      position: position,
    );
    remotePlayers[characterId] = c;
    world.add(c);
  }

  void removeRemotePlayer(int characterId) {
    final c = remotePlayers.remove(characterId);
    if (c != null) remove(c);
  }

  void addMob(Mob mob, {Vector2? position}) {
    if (_mobByInstanceId(mob.id) != null) return;
    final x = position?.x ?? mob.posX;
    final y = groundAt(x, allowFallback: true);
    mob.posY = y;
    final component = MobComponent(
      mob: mob,
      position: Vector2(x, y),
      planeY: y,
    );
    mobs.add(component);
    world.add(component);
  }

  void addNPC({
    required int id,
    required String name,
    Vector2? position,
    bool hasShop = false,
    String dialogue = '',
  }) {
    final x = position?.x ?? mapWidth / 2;
    final npc = NPCComponent(
      npcId: id,
      npcName: name,
      dialogue: dialogue,
      hasShop: hasShop,
      position: Vector2(x, groundAt(x, allowFallback: true)),
      onInteract: _tryNpcInteract,
    );
    npcs.add(npc);
    world.add(npc);
  }

  void _tryNpcInteract(NPCComponent npc) {
    final dx = (player.position.x - npc.position.x).abs();
    final dy = (player.position.y - npc.position.y).abs();
    if (dx > 140 || dy > 80) return;
    onNpcInteract?.call(npc);
  }

  NPCComponent? _nearestNpc({double rangeX = 140, double rangeY = 80}) {
    NPCComponent? nearest;
    var best = double.infinity;
    for (final npc in npcs) {
      final dx = (player.position.x - npc.position.x).abs();
      final dy = (player.position.y - npc.position.y).abs();
      if (dx > rangeX || dy > rangeY) continue;
      final d = dx + dy * 0.5;
      if (d < best) {
        best = d;
        nearest = npc;
      }
    }
    return nearest;
  }

  bool tryInteractNearestNpc() {
    final npc = _nearestNpc();
    if (npc == null) return false;
    onNpcInteract?.call(npc);
    return true;
  }

  void showDamage(int damage, Vector2 origin, {bool critical = false}) {
    world.add(DamagePopup(damage: damage, origin: origin, isCritical: critical));
  }

  void updatePlayerStats({int? hp, int? maxHp, int? mp, int? maxMp, int? level}) {
    if (hp != null) this.hp = hp;
    if (maxHp != null) this.maxHp = maxHp;
    if (mp != null) this.mp = mp;
    if (maxMp != null) this.maxMp = maxMp;
    if (level != null) this.level = level;
  }

  @override
  Color backgroundColor() => const Color(0xFF5BA3D9);
}

/// ==================== 世界背景 ====================
class _WorldBackground extends Component with HasGameRef {
  final double width;
  final double height;

  _WorldBackground({required this.width, required this.height});

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, width, height);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2c3e50), Color(0xFF1a1a2e)],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    final grid = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;
    const step = 80.0;
    for (double x = 0; x < width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), grid);
    }
    for (double y = 0; y < height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(width, y), grid);
    }
  }
}

/// 本地玩家 — WZ Character 条带动画，079 原尺寸 1:1 像素（无额外缩放）
class PlayerComponent extends PositionComponent {
  static const double moveSpeed = 220;
  int direction = 1; // 1 右 / -1 左
  String animationState = 'idle';
  double attackCooldown = 0.45;
  double _attackTimer = 0.0;

  SpriteAnimation? _standAnim;
  SpriteAnimationTicker? _standTicker;
  SpriteAnimation? _walkAnim;
  SpriteAnimationTicker? _walkTicker;
  SpriteAnimation? _attackAnim;
  SpriteAnimationTicker? _attackTicker;
  Sprite? _standSprite;
  Sprite? _attackSprite;
  Sprite? _jumpSprite;
  bool _composeReady = false;

  bool get isAttacking => _attackTimer > 0;

  final int gender;
  final int face;
  final int hair;
  final int top;
  final int bottom;
  final int shoes;
  final int weapon;
  final int cap;
  final int cape;
  final int glove;
  final int shield;
  final int faceAcc;
  final int eyeAcc;
  final int earring;
  final int longcoat;

  PlayerComponent({
    required Vector2 position,
    Vector2? size,
    this.gender = 0,
    this.face = 20100,
    this.hair = 30000,
    this.top = 0,
    this.bottom = 0,
    this.shoes = 0,
    this.weapon = 0,
    this.cap = 0,
    this.cape = 0,
    this.glove = 0,
    this.shield = 0,
    this.faceAcc = 0,
    this.eyeAcc = 0,
    this.earring = 0,
    this.longcoat = 0,
  }) : super(
          position: position,
          size: size ?? Vector2(52, 80),
          anchor: Anchor.bottomCenter,
        );

  @override
  Future<void> onLoad() async {
    final look = CharLook.fromCharacterFields(
      gender: gender,
      face: AvatarAssets.resolveFace(gender, face),
      hair: AvatarAssets.resolveHair(gender, hair),
      top: top != 0 ? top : AvatarAssets.defaultTop(gender),
      bottom: bottom != 0 ? bottom : AvatarAssets.defaultBottom(gender),
      shoes: shoes != 0 ? shoes : AvatarAssets.defaultShoes(),
      weapon: weapon != 0 ? weapon : AvatarAssets.defaultBeginnerWeapon,
      cap: cap,
      cape: cape,
      glove: glove,
      shield: shield,
      faceAcc: faceAcc,
      eyeAcc: eyeAcc,
      earring: earring,
      longcoat: longcoat,
    );

    // 1) Phase 1：后端 CharLook 合成（含 Head；walk1 多帧动画，对齐 HeavenClient CharLook::update）
    _standSprite = await SpriteLoader.tryLoadCompose(look, pose: 'stand1', scale: 1);
    if (_standSprite != null) {
      _composeReady = true;
      _walkAnim = await SpriteLoader.tryLoadComposeAnimation(
        look,
        pose: 'walk1',
        scale: 1,
        maxFrames: 4,
        stepTime: 0.18,
      );
      if (_walkAnim == null) {
        for (final strip in AvatarAssets.animStripCandidates(
          gender: gender,
          face: face,
          hair: hair,
          top: top,
          bottom: bottom,
          shoes: shoes,
          weapon: weapon,
          pose: 'walk1',
        )) {
          final manifest = strip.replaceAll('.png', '_manifest.json');
          _walkAnim = await SpriteLoader.tryLoadStripManifest(strip, manifest);
          if (_walkAnim != null) break;
        }
      }
      if (_walkAnim != null) {
        _walkTicker = SpriteAnimationTicker(_walkAnim!);
      }
      _attackAnim = await SpriteLoader.tryLoadComposeAnimation(
        look,
        pose: 'swingO1',
        scale: 1,
        maxFrames: 4,
        stepTime: 0.08,
        loop: false,
      );
      if (_attackAnim != null) {
        _attackTicker = SpriteAnimationTicker(_attackAnim!);
      } else {
        _attackSprite =
            (await SpriteLoader.tryLoadCompose(look, pose: 'swingO1', scale: 1)) ??
                _standSprite;
      }
      _jumpSprite =
          (await SpriteLoader.tryLoadCompose(look, pose: 'jump', scale: 1)) ??
              _standSprite;
      _applyDisplaySize();
      return;
    }

    // 2) 本地烘焙立绘回退
    _standSprite = await SpriteLoader.tryLoadFirst(
      AvatarAssets.candidatePaths(
        gender: gender, face: face, hair: hair,
        top: top, bottom: bottom, shoes: shoes, weapon: weapon,
      ),
    );

    // 3) walk1/stand1 动画条带（仅 compose 失败时使用）
    for (final strip in AvatarAssets.animStripCandidates(
      gender: gender, face: face, hair: hair,
      top: top, bottom: bottom, shoes: shoes, weapon: weapon, pose: 'walk1',
    )) {
      final manifest = strip.replaceAll('.png', '_manifest.json');
      final anim = await SpriteLoader.tryLoadStripManifest(strip, manifest);
      if (anim != null) {
        _walkAnim = anim;
        _walkTicker = SpriteAnimationTicker(anim);
        break;
      }
    }
    for (final strip in AvatarAssets.animStripCandidates(
      gender: gender, face: face, hair: hair,
      top: top, bottom: bottom, shoes: shoes, weapon: weapon, pose: 'stand1',
    )) {
      final manifest = strip.replaceAll('.png', '_manifest.json');
      final anim = await SpriteLoader.tryLoadStripManifest(strip, manifest, loop: true);
      if (anim != null) {
        _standAnim = anim;
        _standTicker = SpriteAnimationTicker(anim);
        break;
      }
    }
    if (_attackAnim == null) {
      for (final strip in AvatarAssets.animStripCandidates(
        gender: gender, face: face, hair: hair,
        top: top, bottom: bottom, shoes: shoes, weapon: weapon, pose: 'swingO1',
      )) {
        final manifest = strip.replaceAll('.png', '_manifest.json');
        final anim = await SpriteLoader.tryLoadStripManifest(strip, manifest, loop: false);
        if (anim != null) {
          _attackAnim = anim;
          _attackTicker = SpriteAnimationTicker(anim);
          break;
        }
      }
    }

    // 4) 最终回退：同性别默认立绘（禁止 parts 碎片叠层）
    if (_standSprite == null) {
      final d = AvatarAssets.resolveLook(
        gender: gender, face: face, hair: hair,
        top: top, bottom: bottom, shoes: shoes, weapon: weapon,
      );
      _standSprite = await SpriteLoader.tryLoadFirst(
        AvatarAssets.candidatePaths(
          gender: d.gender, face: d.face, hair: d.hair,
          top: d.top, bottom: d.bottom, shoes: d.shoes, weapon: d.weapon,
        ),
      );
    }

    _applyDisplaySize();
  }

  void _applyDisplaySize() {
    double maxW = 52, maxH = 80;
    void scan(SpriteAnimation? anim) {
      if (anim == null) return;
      for (final f in anim.frames) {
        maxW = math.max(maxW, f.sprite.srcSize.x);
        maxH = math.max(maxH, f.sprite.srcSize.y);
      }
    }
    scan(_walkAnim);
    scan(_standAnim);
    scan(_attackAnim);
    for (final s in [_standSprite, _attackSprite, _jumpSprite]) {
      if (s != null) {
        maxW = math.max(maxW, s.srcSize.x);
        maxH = math.max(maxH, s.srcSize.y);
      }
    }
    size = Vector2(maxW, maxH);
  }

  Sprite? _activeSprite() {
    if (animationState == 'attack' && _attackTicker != null) {
      return _attackTicker!.getSprite();
    }
    if (animationState == 'walk' && _walkTicker != null) {
      return _walkTicker!.getSprite();
    }
    if (_composeReady) {
      if (animationState == 'attack' && _attackSprite != null) return _attackSprite;
      if (animationState == 'jump' && _jumpSprite != null) return _jumpSprite;
      return _standSprite;
    }
    if (animationState == 'walk' && _walkTicker != null) {
      return _walkTicker!.getSprite();
    }
    if (_standTicker != null) return _standTicker!.getSprite();
    return _standSprite;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_attackTimer > 0) {
      _attackTimer -= dt;
      if (_attackTimer < 0) _attackTimer = 0;
    } else if (animationState == 'attack') {
      animationState = 'idle';
    }
    if (animationState == 'attack' && _attackTicker != null) {
      _attackTicker!.update(dt);
    } else if (animationState == 'walk' && _walkTicker != null) {
      _walkTicker!.update(dt);
    } else if (animationState == 'idle' && _standTicker != null) {
      _standTicker!.update(dt);
    }
  }

  void moveHorizontal(int dir, double dt) {
    if (dir != 0) {
      direction = dir > 0 ? 1 : -1;
      position.x += direction * moveSpeed * dt;
      if (!isAttacking) animationState = 'walk';
    }
  }

  void move(Vector2 dir, double dt) {
    if (dir.x != 0) {
      moveHorizontal(dir.x > 0 ? 1 : -1, dt);
    }
  }

  bool attack() {
    if (_attackTimer <= 0) {
      _attackTimer = attackCooldown;
      animationState = 'attack';
      _attackTicker?.reset();
      return true;
    }
    return false;
  }

  void useSkill(int skillId) {
    animationState = 'skill_$skillId';
  }

  @override
  void render(Canvas canvas) {
    final sprite = _activeSprite();
    if (sprite != null) {
      _drawSprite(canvas, sprite);
      _renderAttackGlow(canvas);
      return;
    }

    // 最终回退：程序化火柴人（无 WZ 资源时）
    // 阴影
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y + 4),
        width: size.x * 0.7,
        height: 10,
      ),
      Paint()..color = Colors.black.withOpacity(0.35),
    );

    // 身体
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFf1c40f), Color(0xFFd35400)],
      ).createShader(Offset.zero & Size(size.x, size.y));
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.2, size.y * 0.25, size.x * 0.6, size.y * 0.5),
      bodyPaint,
    );

    // 头部
    canvas.drawCircle(
      Offset(size.x / 2, size.y * 0.18),
      size.x * 0.22,
      Paint()..color = const Color(0xFFf5deb3),
    );

    // 朝向指示
    final arrowPaint = Paint()..color = Colors.white;
    final ax = direction > 0 ? size.x * 0.78 : size.x * 0.22;
    final path = Path();
    if (direction > 0) {
      path.moveTo(ax, size.y * 0.35);
      path.lineTo(ax + 6, size.y * 0.42);
      path.lineTo(ax, size.y * 0.49);
    } else {
      path.moveTo(ax, size.y * 0.35);
      path.lineTo(ax - 6, size.y * 0.42);
      path.lineTo(ax, size.y * 0.49);
    }
    path.close();
    canvas.drawPath(path, arrowPaint);

    // 腿
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.3, size.y * 0.75, size.x * 0.15, size.y * 0.2),
      Paint()..color = const Color(0xFF34495e),
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.55, size.y * 0.75, size.x * 0.15, size.y * 0.2),
      Paint()..color = const Color(0xFF34495e),
    );

    // 攻击光效
    _renderAttackGlow(canvas);
  }

  /// 079 bottomCenter 锚点：局部 (0,0) 为脚底中心
  void _drawSprite(Canvas canvas, Sprite sprite) {
    final w = sprite.srcSize.x;
    final h = sprite.srcSize.y;
    final paint = Paint()..filterQuality = FilterQuality.none;

    canvas.save();
    if (direction > 0) {
      canvas.scale(-1, 1);
      sprite.render(
        canvas,
        position: Vector2(-w / 2, -h),
        size: Vector2(w, h),
        overridePaint: paint,
      );
    } else {
      sprite.render(
        canvas,
        position: Vector2(-w / 2, -h),
        size: Vector2(w, h),
        overridePaint: paint,
      );
    }
    canvas.restore();
  }

  void _renderAttackGlow(Canvas canvas) {
    if (_attackTimer > 0) {
      final glow = Paint()
        ..color = Colors.yellow.withOpacity(_attackTimer / attackCooldown * 0.8);
      canvas.drawCircle(
        Offset(direction * 24.0, -size.y * 0.45),
        size.x * 0.3,
        glow,
      );
    }
  }
}

/// ==================== NPC 组件 ====================
class NPCComponent extends PositionComponent with TapCallbacks {
  final int npcId;
  final String npcName;
  final String dialogue;
  final bool hasShop;
  final void Function(NPCComponent npc)? onInteract;

  NPCComponent({
    required this.npcId,
    required this.npcName,
    this.dialogue = '',
    this.hasShop = false,
    required Vector2 position,
    this.onInteract,
  }) : super(
          position: position,
          size: Vector2(48, 64),
          anchor: Anchor.bottomCenter,
        );

  Sprite? _sprite;

  @override
  Future<void> onLoad() async {
    _sprite = await SpriteLoader.tryLoad(SpriteDirs.npcPath(npcId));
    if (_sprite != null) {
      size = Vector2(_sprite!.srcSize.x, _sprite!.srcSize.y);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    onInteract?.call(this);
    super.onTapDown(event);
  }

  @override
  void render(Canvas canvas) {
    if (_sprite != null) {
      SpriteLoader.renderFeetAnchored(canvas, _sprite!, size);
      _renderNpcName(canvas);
      return;
    }

    // 阴影
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y + 4),
        width: size.x * 0.7,
        height: 10,
      ),
      Paint()..color = Colors.black.withOpacity(0.3),
    );

    // 身体
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3498db), Color(0xFF2c3e50)],
      ).createShader(Offset.zero & Size(size.x, size.y));
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.18, size.y * 0.25, size.x * 0.64, size.y * 0.5),
      paint,
    );

    // 头部
    canvas.drawCircle(
      Offset(size.x / 2, size.y * 0.18),
      size.x * 0.22,
      Paint()..color = const Color(0xFFecf0f1),
    );

    // 名字
    _renderNpcName(canvas);
  }

  void _renderNpcName(Canvas canvas) {
    final tp = TextPainter(
      text: TextSpan(
        text: npcName,
        style: const TextStyle(
          color: Color(0xFFf1c40f),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(size.x / 2 - tp.width / 2, -tp.height - 4),
    );
  }
}

/// ==================== 怪物组件（079：水平巡逻 rx0–rx1，近距追击） ====================
class MobComponent extends PositionComponent {
  final Mob mob;
  double _attackCooldown = 0.0;
  int _facing = 1;
  Sprite? _standSprite;
  SpriteAnimation? _moveAnim;
  SpriteAnimationTicker? _moveTicker;
  double _targetX = 0;
  double _targetY = 0;
  bool _serverMoving = false;

  MobComponent({required this.mob, required Vector2 position, this.planeY})
      : super(
          position: position,
          size: Vector2(64, 64),
          anchor: Anchor.bottomCenter,
        ) {
    _targetX = position.x;
    _targetY = planeY ?? position.y;
  }

  /// 横版地面 Y；服务端 Y 忽略，统一锁在此高度
  final double? planeY;

  double get _rx0 => mob.rx0 > 0 || mob.rx1 > 0 ? mob.rx0 : mob.posX - 100;
  double get _rx1 => mob.rx0 > 0 || mob.rx1 > 0 ? mob.rx1 : mob.posX + 100;

  @override
  Future<void> onLoad() async {
    final id = mob.mobId;
    _standSprite = await SpriteLoader.tryLoad(SpriteDirs.mobPath(id));
    final movePath = SpriteDirs.mobMovePath(id);
    for (var frames = 6; frames >= 2; frames--) {
      final anim = await SpriteLoader.tryLoadAnimation(movePath, frames: frames, stepTime: 0.14);
      if (anim != null) {
        _moveAnim = anim;
        _moveTicker = SpriteAnimationTicker(anim);
        break;
      }
    }
    if (_standSprite != null) {
      _applyNativeDisplaySize(_standSprite!);
    }
  }

  void _applyNativeDisplaySize(Sprite sprite) {
    var maxW = sprite.srcSize.x;
    var maxH = sprite.srcSize.y;
    if (_moveAnim != null) {
      for (final f in _moveAnim!.frames) {
        maxW = math.max(maxW, f.sprite.srcSize.x);
        maxH = math.max(maxH, f.sprite.srcSize.y);
      }
    }
    size = Vector2(maxW, maxH);
  }

  void applyServerState(Map<String, dynamic> p, {double minDelta = 0}) {
    final x = (p['x'] as num?)?.toDouble();
    final lockY = planeY ?? _targetY;
    if (x != null && (minDelta <= 0 || (x - _targetX).abs() >= minDelta)) {
      _targetX = x;
      mob.posX = x;
    }
    _targetY = lockY;
    mob.posY = lockY;
    final facing = (p['facing'] as num?)?.toInt();
    if (facing != null && facing != 0) {
      _facing = facing;
    }
    _serverMoving = p['moving'] == true;
    if (_serverMoving) {
      mob.status = MobStatus.moving;
    } else if (mob.isAlive) {
      mob.status = MobStatus.idle;
    }
  }

  void applyServerTick(double dt) {
    if (!mob.isAlive) return;
    final lerp = (dt * 12).clamp(0.0, 1.0);
    final lockY = planeY ?? _targetY;
    position.y = lockY;
    mob.posY = lockY;
    _targetY = lockY;
    position.x += (_targetX - position.x) * lerp;
    mob.posX = position.x;
    if (_serverMoving) {
      mob.status = MobStatus.moving;
      _moveTicker?.update(dt);
    }
  }

  void updateAI(double dt, PlayerComponent player, {void Function(int dmg)? onDealDamage}) {
    if (!mob.isAlive) return;

    _attackCooldown -= dt;
    final lockY = planeY ?? mob.spawnY;
    position.y = lockY;
    mob.posY = lockY;

    final dx = player.position.x - position.x;
    final dy = player.position.y - position.y;
    final horizDist = dx.abs();
    const aggroRange = 220.0;
    const vertTolerance = 72.0;
    final attackRange = mob.attackRange > 0 ? mob.attackRange : 55.0;
    final speed = mob.moveSpeedPx;

    if (horizDist <= attackRange && dy.abs() <= vertTolerance) {
      mob.status = MobStatus.attacking;
      if (_attackCooldown <= 0) {
        _attackCooldown = mob.attackCooldown / 1000.0;
        if (_attackCooldown <= 0) _attackCooldown = 1.0;
        final dmg = (mob.attack > 0 ? mob.attack : 1) + math.Random().nextInt(3);
        onDealDamage?.call(dmg);
      }
      return;
    }

    if (horizDist < aggroRange && horizDist > attackRange && dy.abs() <= vertTolerance) {
      mob.status = MobStatus.moving;
      _facing = dx > 0 ? 1 : -1;
      position.x += _facing * speed * dt;
    } else {
      mob.status = MobStatus.moving;
      if (position.x >= _rx1 - 4) _facing = -1;
      if (position.x <= _rx0 + 4) _facing = 1;
      position.x += _facing * speed * dt * 0.55;
    }

    position.x = position.x.clamp(_rx0, _rx1);
    mob.posX = position.x;
    _moveTicker?.update(dt);
  }

  void takeDamage(int damage) {
    mob.hp -= damage;
    if (mob.hp <= 0) {
      mob.hp = 0;
      mob.status = MobStatus.dead;
    }
  }

  void setHp(int hp) {
    mob.hp = hp.clamp(0, mob.maxHp);
    if (mob.hp <= 0) {
      mob.status = MobStatus.dead;
    } else if (mob.status == MobStatus.dead) {
      mob.status = MobStatus.idle;
    }
  }

  @override
  void render(Canvas canvas) {
    final moving = mob.status == MobStatus.moving && _moveTicker != null;
    final sprite = moving ? _moveTicker!.getSprite() : _standSprite;
    if (mob.isAlive && sprite != null) {
      SpriteLoader.renderFeetAnchored(canvas, sprite, size, direction: _facing);
      _renderMobHud(canvas);
      return;
    }

    // 阴影
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y + 2),
        width: size.x * 0.8,
        height: 10,
      ),
      Paint()..color = Colors.black.withOpacity(0.4),
    );

    // 身体
    final color = mob.isAlive
        ? const Color(0xFFc0392b)
        : Colors.grey.withOpacity(0.4);
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, color.withOpacity(0.6)],
      ).createShader(Offset.zero & Size(size.x, size.y));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * 0.1, size.y * 0.2, size.x * 0.8, size.y * 0.7),
        const Radius.circular(8),
      ),
      bodyPaint,
    );

    // 眼睛
    if (mob.isAlive) {
      canvas.drawCircle(
        Offset(size.x * 0.35, size.y * 0.4),
        4,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(size.x * 0.65, size.y * 0.4),
        4,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(size.x * 0.35, size.y * 0.4),
        2,
        Paint()..color = Colors.black,
      );
      canvas.drawCircle(
        Offset(size.x * 0.65, size.y * 0.4),
        2,
        Paint()..color = Colors.black,
      );
    }

    // 血条与名字
    _renderMobHud(canvas);
  }

  void _renderMobHud(Canvas canvas) {
    final hpRatio = mob.maxHp > 0 ? mob.hp / mob.maxHp : 0.0;
    canvas.drawRect(
      Rect.fromLTWH(0, -12, size.x, 6),
      Paint()..color = Colors.black.withOpacity(0.5),
    );
    canvas.drawRect(
      Rect.fromLTWH(1, -11, (size.x - 2) * hpRatio.clamp(0.0, 1.0), 4),
      Paint()
        ..color = hpRatio > 0.5
            ? Colors.greenAccent
            : hpRatio > 0.25
                ? Colors.orangeAccent
                : Colors.redAccent,
    );
    if (mob.name.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: '${mob.name} Lv.${mob.level}',
          style: const TextStyle(
            color: Color(0xFFf1c40f),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black, blurRadius: 2)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.x / 2 - tp.width / 2, -tp.height - 16));
    }
  }
}

/// ==================== 地面掉落组件 ====================
class GroundLootComponent extends PositionComponent {
  GroundLootComponent({
    required this.dropId,
    required this.itemId,
    required this.quantity,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(28, 28),
          anchor: Anchor.center,
        );

  final String dropId;
  final int itemId;
  final int quantity;
  double _bob = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _bob += dt * 3;
  }

  @override
  void render(Canvas canvas) {
    final bobY = math.sin(_bob) * 3;
    canvas.save();
    canvas.translate(0, bobY);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: itemId > 0
            ? [const Color(0xFFf1c40f), const Color(0xFFe67e22)]
            : [const Color(0xFFf9e79f), const Color(0xFFf4d03f)],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(6),
      ),
      paint,
    );
    if (itemId > 0) {
      final tp = TextPainter(
        text: TextSpan(
          text: '$itemId',
          style: const TextStyle(color: Colors.white, fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.x);
      tp.paint(canvas, Offset(2, size.y / 2 - tp.height / 2));
    }
    canvas.restore();
  }
}

/// ==================== TileMap 背景层 ====================
/// 程序化生成的 Tile 图案 —— 不依赖外部图片即可显示有层次感的"地图纹理"。
/// 不同的 mapId 会采用不同的配色（例如 10000 射手村森林 / 20000 勇士部落岩石）。
class TileMapLayer extends Component with HasGameRef {
  final double width;
  final double height;
  final double tileSize;
  final int mapId;

  late final List<Color> _tilePalette;
  late final List<List<int>> _tileGrid;

  TileMapLayer({
    required this.width,
    required this.height,
    required this.tileSize,
    required this.mapId,
  }) {
    _tilePalette = _paletteFor(mapId);
    _tileGrid = _generateGrid();
  }

  List<Color> _paletteFor(int id) {
    // 简单的 hash 映射到固定风格
    if (id >= 20000) {
      // 勇士部落 - 岩石/红棕色
      return const [
        Color(0xFF6d4c41),
        Color(0xFF8d6e63),
        Color(0xFF5d4037),
        Color(0xFFa1887f),
      ];
    }
    if (id >= 10000) {
      // 射手村 - 森林绿
      return const [
        Color(0xFF2e7d32),
        Color(0xFF388e3c),
        Color(0xFF1b5e20),
        Color(0xFF66bb6a),
      ];
    }
    // 默认 - 彩虹岛浅蓝
    return const [
      Color(0xFF4fc3f7),
      Color(0xFF81d4fa),
      Color(0xFF0288d1),
      Color(0xFFb3e5fc),
    ];
  }

  List<List<int>> _generateGrid() {
    final cols = (width / tileSize).ceil();
    final rows = (height / tileSize).ceil();
    final grid = List.generate(rows, (_) => List.filled(cols, 0));
    // 伪随机但确定性
    final rand = math.Random(mapId + 42);
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        grid[y][x] = rand.nextInt(_tilePalette.length);
      }
    }
    return grid;
  }

  @override
  void render(Canvas canvas) {
    final cols = _tileGrid[0].length;
    final rows = _tileGrid.length;
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final color = _tilePalette[_tileGrid[y][x]];
        final rect = Rect.fromLTWH(
          x * tileSize,
          y * tileSize,
          tileSize,
          tileSize,
        );
        canvas.drawRect(
          rect,
          Paint()..color = color.withOpacity(0.85),
        );
        // 每格内的小装饰点，增加像素感
        if ((x + y) % 2 == 0) {
          canvas.drawCircle(
            Offset(x * tileSize + tileSize / 2, y * tileSize + tileSize / 2),
            3,
            Paint()..color = color.withOpacity(0.4),
          );
        }
      }
    }
  }
}

/// ==================== 伤害飘字 ====================
class DamagePopup extends PositionComponent {
  final int damage;
  final bool isCritical;
  final Vector2 origin;

  double _life = 0.9;

  DamagePopup({required this.damage, required this.origin, this.isCritical = false})
      : super(
          position: origin,
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) {
      removeFromParent();
      return;
    }
    position.y -= 60 * dt; // 向上飘
  }

  @override
  void render(Canvas canvas) {
    final text = isCritical ? '$damage!' : '$damage';
    final style = TextStyle(
      color: isCritical ? Colors.yellowAccent : Colors.white,
      fontSize: isCritical ? 22 : 18,
      fontWeight: FontWeight.bold,
      shadows: const [
        Shadow(color: Colors.black, blurRadius: 3),
      ],
    );
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }
}

/// ==================== 远程玩家组件 ====================
/// 表示其他玩家在本地世界中的位置显示，位置采用线性插值平滑移动。
class RemotePlayerComponent extends PositionComponent {
  final int characterId;
  final String name;
  Vector2 targetPosition;

  static const double _lerpSpeed = 6.0;

  RemotePlayerComponent({
    required this.characterId,
    required this.name,
    required Vector2 position,
  })  : targetPosition = position,
        super(
          position: position,
          size: Vector2(48, 64),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    position.lerp(targetPosition, (dt * _lerpSpeed).clamp(0.0, 1.0));
  }

  @override
  void render(Canvas canvas) {
    // 阴影
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y + 4),
        width: size.x * 0.7,
        height: 10,
      ),
      Paint()..color = Colors.black.withOpacity(0.3),
    );

    // 身体（紫色系，与本地玩家区分）
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF9b59b6), Color(0xFF6c3483)],
      ).createShader(Offset.zero & Size(size.x, size.y));
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.2, size.y * 0.25, size.x * 0.6, size.y * 0.5),
      bodyPaint,
    );

    // 头部
    canvas.drawCircle(
      Offset(size.x / 2, size.y * 0.18),
      size.x * 0.22,
      Paint()..color = const Color(0xFFf5d7a3),
    );

    // 名字
    final tp = TextPainter(
      text: TextSpan(
        text: name,
        style: const TextStyle(
          color: Color(0xFF81d4fa),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.x / 2 - tp.width / 2, -tp.height - 4));
  }
}
