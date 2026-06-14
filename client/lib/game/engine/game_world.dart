import 'dart:math' as math;

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/resources/assets.dart';
import '../../models/mob.dart';
import '../../services/websocket_service.dart';
import 'sprite_loader.dart';

/// Flame 游戏世界 —— 负责 Canvas 渲染循环、实体管理、输入处理
///
/// 主要特性：
/// - 相机跟随玩家 (camera.follow)
/// - 键盘输入 WASD / 方向键 / 攻击 J / 攻击 Space
/// - 程序化 TileMap 背景层（无需外部图片，不同 mapId 不同配色）
/// - 玩家/怪物/NPC/远程玩家 Canvas 组件（阴影 + 血条 + 名字 + 朝向）
/// - 怪物 AI：近距离追击玩家、远距离随机巡逻
/// - 伤害飘字 DamagePopup（暴击黄字 + 向上淡出）
/// - WebSocket 集成：sendPosition / sendAttack / sendDamage / sendDead / sendRevive
/// - AudioManager：按 mapId 自动播放 BGM；攻击/升级/死亡音效
/// - 角色属性：HP/MP/EXP/STR/DEX/INT/LUK/AP/SP
/// - 死亡与复活：HP/回生点（死亡状态机）
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
  });

  // ===== 地图属性 =====
  final int mapId;
  final String mapName;
  final double mapWidth;
  final double mapHeight;
  final double tileSize;
  final Vector2? playerInitial;

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
  late final void Function(int newLevel)? onLevelUp;
  late final void Function()? onPlayerDead;
  late final void Function({
    int? hp,
    int? maxHp,
    int? mp,
    int? maxMp,
    int? level,
    int? exp,
    int? mesos,
  })? onStatChange;

  // ===== 实体集合 =====
  late final PlayerComponent player;
  final List<MobComponent> mobs = [];
  final List<NPCComponent> npcs = [];
  final Map<int, RemotePlayerComponent> remotePlayers = {};

  // ===== 节流器 =====
  double _positionThrottle = 0;
  static const double _positionThrottleMs = 50 / 1000;

  // 输入状态
  final Set<LogicalKeyboardKey> _keysDown = {};

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // ===== 程序化 TileMap 背景层 =====
    add(TileMapLayer(
      width: mapWidth,
      height: mapHeight,
      tileSize: tileSize,
      mapId: mapId,
    ));

    // ===== 世界背景 (渐变 + 网格) =====
    add(_WorldBackground(width: mapWidth, height: mapHeight));

    // ===== 玩家 =====
    player = PlayerComponent(
      position: playerInitial ?? Vector2(mapWidth / 2, mapHeight / 2),
      size: Vector2(48, 64),
    );
    await add(player);

    // ===== 相机 =====
    camera.follow(
      player,
      snap: true,
      maxSpeed: 600,
    );
    camera.worldBounds = Rect.fromLTWH(0, 0, mapWidth, mapHeight);

    // ===== 音频：自动播放当前地图 BGM =====
    final bgm = BgmAssets.byMapId(mapId);
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
  }

  @override
  void onRemove() {
    ws?.removeListener(WsMessageType.damage, _onServerDamage);
    ws?.removeListener(WsMessageType.exp, _onServerExp);
    ws?.removeListener(WsMessageType.dead, _onServerDead);
    ws?.removeListener(WsMessageType.revive, _onServerRevive);
    ws?.removeListener(WsMessageType.position, _onServerRemotePosition);
    try {
      AudioManager().stopBgm();
    } catch (_) {}
    super.onRemove();
  }

  // ============ 键盘输入 ============

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _keysDown
      ..clear()
      ..addAll(keysPressed);
    return KeyEventResult.handled;
  }

  // ============ 主循环 ============

  @override
  void update(double dt) {
    super.update(dt);
    uptime += dt;

    // --- 死亡状态机：暂停移动与攻击，等待复活 ---
    if (isDead) {
      _reviveTimer -= dt;
      if (_reviveTimer <= 0) {
        _doRevive();
      }
      return;
    }

    // --- 键盘移动 ---
    bool moved = false;
    final move = Vector2.zero();
    if (_keysDown.contains(LogicalKeyboardKey.keyA) ||
        _keysDown.contains(LogicalKeyboardKey.arrowLeft)) {
      move.x -= 1;
      moved = true;
    }
    if (_keysDown.contains(LogicalKeyboardKey.keyD) ||
        _keysDown.contains(LogicalKeyboardKey.arrowRight)) {
      move.x += 1;
      moved = true;
    }
    if (_keysDown.contains(LogicalKeyboardKey.keyW) ||
        _keysDown.contains(LogicalKeyboardKey.arrowUp)) {
      move.y -= 1;
      moved = true;
    }
    if (_keysDown.contains(LogicalKeyboardKey.keyS) ||
        _keysDown.contains(LogicalKeyboardKey.arrowDown)) {
      move.y += 1;
      moved = true;
    }
    if (moved) {
      player.move(move.normalized(), dt);
      // 防止角色飘出地图边界
      player.position.x = player.position.x.clamp(16.0, mapWidth - 16);
      player.position.y = player.position.y.clamp(16.0, mapHeight - 16);

      // 节流发送位置（50ms）
      _positionThrottle -= dt;
      if (_positionThrottle <= 0) {
        _positionThrottle = _positionThrottleMs;
        ws?.sendPosition(
          characterId: characterId,
          x: player.position.x,
          y: player.position.y,
        );
      }
    }

    // --- 攻击键 (J / Space) ---
    if (_keysDown.contains(LogicalKeyboardKey.keyJ) ||
        _keysDown.contains(LogicalKeyboardKey.space)) {
      if (player.attack()) {
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
    }

    // --- 怪物 AI ---
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

    // --- 经验与升级检查 ---
    if (exp >= GameConstants.expRequired(level)) {
      _doLevelUp();
    }
  }

  int? _lastTargetMobId;

  void _doMeleeHit({required double range}) {
    final r2 = range * range;
    // 按职业简单估算伤害（与服务端 combat_service.go 对齐：战士=STR, 法师=INT, 弓=DEX, 飞侠=LUK）
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
    _lastTargetMobId = null;
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
    _lastTargetMobId = nearest.mob.id;
    // 暴击：LUK 影响，飞侠天生高
    final critRoll = math.Random().nextDouble();
    final critChance = 0.05 + luk * 0.005 + (jobId == 4 ? 0.1 : 0.0);
    final isCrit = critRoll < critChance;
    final dmgRaw = base.toInt() + math.Random().nextInt(4);
    final dmg = (isCrit ? dmgRaw * 2 : dmgRaw).toInt();
    final finalDmg = dmg < 1 ? 1 : dmg;
    damageDealt += finalDmg;
    nearest.takeDamage(finalDmg);
    add(DamagePopup(
      damage: finalDmg,
      origin: nearest.position.clone(),
      isCritical: isCrit,
    ));

    // 通知服务端：本次攻击（本地伤害先渲染，服务端最终裁决会覆盖）
    ws?.sendDamage(
      characterId: characterId,
      targetId: nearest.mob.id,
      damage: finalDmg,
      critical: isCrit,
    );

    if (!nearest.mob.isAlive) {
      killedMobs += 1;
      // 经验 = 怪物等级 * 4 + 10
      final expGain = (nearest.mob.level * 4 + 10);
      gainExp(expGain);
      // 金币 = 怪物等级 * 2 + 随机
      final mesos = nearest.mob.level * 2 + math.Random().nextInt(5);
      mesosGained += mesos;
      onStatChange?.call(mesos: mesosGained);
      try {
        AudioManager().playSfx(SfxAssets.mesos);
      } catch (_) {}
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

  void _doRevive() {
    hp = maxHp;
    mp = maxMp;
    player.position = playerInitial ?? Vector2(mapWidth / 2, mapHeight / 2);
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

  void movePlayer(Vector2 direction) {
    player.move(direction, 1 / 60);
  }

  void playerAttack() => player.attack();

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
        add(DamagePopup(
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
          add(DamagePopup(
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
    final x = payload['x'] as double? ?? 0.0;
    final y = payload['y'] as double? ?? 0.0;
    final name = payload['name'] as String? ?? '玩家$cid';
    updateRemotePlayer(
      characterId: cid,
      name: name,
      position: Vector2(x, y),
    );
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
    add(c);
  }

  void removeRemotePlayer(int characterId) {
    final c = remotePlayers.remove(characterId);
    if (c != null) remove(c);
  }

  void addMob(Mob mob, {Vector2? position}) {
    final component = MobComponent(
      mob: mob,
      position: position ?? Vector2(mob.posX, mob.posY),
    );
    mobs.add(component);
    add(component);
  }

  void addNPC({required int id, required String name, Vector2? position}) {
    final npc = NPCComponent(
      npcId: id,
      npcName: name,
      position: position ?? Vector2(mapWidth / 2, mapHeight / 2),
    );
    npcs.add(npc);
    add(npc);
  }

  void showDamage(int damage, Vector2 origin, {bool critical = false}) {
    add(DamagePopup(damage: damage, origin: origin, isCritical: critical));
  }

  void updatePlayerStats({int? hp, int? maxHp, int? mp, int? maxMp, int? level}) {
    if (hp != null) this.hp = hp;
    if (maxHp != null) this.maxHp = maxHp;
    if (mp != null) this.mp = mp;
    if (maxMp != null) this.maxMp = maxMp;
    if (level != null) this.level = level;
  }

  @override
  Color backgroundColor() => const Color(0xFF1a1a2e);
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

/// ==================== 玩家组件 ====================
class PlayerComponent extends PositionComponent {
  static const double moveSpeed = 220; // 像素/秒
  int direction = 1; // 1: 右, -1: 左
  String animationState = 'idle';
  double attackCooldown = 0.45;
  double _attackTimer = 0.0;

  PlayerComponent({required Vector2 position, Vector2? size})
      : super(
          position: position,
          size: size ?? Vector2(48, 64),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    if (_attackTimer > 0) {
      _attackTimer -= dt;
      if (_attackTimer < 0) _attackTimer = 0;
    }
  }

  void move(Vector2 dir, double dt) {
    if (dir.x != 0) {
      direction = dir.x > 0 ? 1 : -1;
    }
    position.add(dir * moveSpeed * dt);
    animationState = 'walk';
  }

  bool attack() {
    if (_attackTimer <= 0) {
      _attackTimer = attackCooldown;
      animationState = 'attack';
      return true;
    }
    return false;
  }

  void useSkill(int skillId) {
    animationState = 'skill_$skillId';
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
      Paint()..color = Colors.black.withOpacity(0.35),
    );

    // 身体
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFf1c40f), Color(0xFFd35400)],
      ).createShader(Offset.zero & size.toSize());
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
    if (_attackTimer > 0) {
      final glow = Paint()
        ..color = Colors.yellow.withOpacity(_attackTimer / attackCooldown * 0.8);
      canvas.drawCircle(
        Offset(size.x / 2 + direction * size.x * 0.6, size.y * 0.4),
        size.x * 0.3,
        glow,
      );
    }
  }
}

/// ==================== NPC 组件 ====================
class NPCComponent extends PositionComponent {
  final int npcId;
  final String npcName;

  NPCComponent({
    required this.npcId,
    required this.npcName,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(48, 64),
          anchor: Anchor.center,
        );

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

    // 身体
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3498db), Color(0xFF2c3e50)],
      ).createShader(Offset.zero & size.toSize());
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

/// ==================== 怪物组件 ====================
class MobComponent extends PositionComponent {
  final Mob mob;
  double _aiTimer = 0.0;
  double _attackCooldown = 0.0;

  MobComponent({required this.mob, required Vector2 position})
      : super(
          position: position,
          size: Vector2(60, 60),
          anchor: Anchor.center,
        );

  void updateAI(double dt, PlayerComponent player, {void Function(int dmg)? onDealDamage}) {
    if (!mob.isAlive) return;

    _aiTimer += dt;
    _attackCooldown -= dt;

    // 简单 AI：当玩家距离 < 200 时朝玩家移动；距离 < 60 时发起攻击
    final dx = player.position.x - position.x;
    final dy = player.position.y - position.y;
    final distSq = dx * dx + dy * dy;

    if (distSq < 200 * 200 && distSq > 50 * 50) {
      final dist = math.sqrt(distSq);
      final dirX = dx / dist;
      final dirY = dy / dist;
      position.x += dirX * mob.speed * dt * 30;
      position.y += dirY * mob.speed * dt * 30;
      mob.posX = position.x;
      mob.posY = position.y;
    } else if (_aiTimer > 3) {
      position.x += (math.Random().nextDouble() - 0.5) * mob.speed * dt * 30;
      position.y += (math.Random().nextDouble() - 0.5) * mob.speed * dt * 30;
      _aiTimer = 0;
    }

    // 近身攻击：玩家距离 < 60 时造成伤害
    if (distSq < 60 * 60 && _attackCooldown <= 0) {
      _attackCooldown = 1.2;
      final dmg = (mob.attack > 0 ? mob.attack : 1) + math.Random().nextInt(3);
      onDealDamage?.call(dmg);
    }
  }

  void takeDamage(int damage) {
    mob.hp -= damage;
    if (mob.hp <= 0) {
      mob.hp = 0;
      mob.status = MobStatus.dead;
    }
  }

  @override
  void render(Canvas canvas) {
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
      ).createShader(Offset.zero & size.toSize());
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

    // 血条
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

    // 名字
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

// 扩展：Vector2 -> Size
extension _Vector2ToSize on Vector2 {
  Size toSize() => Size(x, y);
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
      ).createShader(Offset.zero & size.toSize());
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
