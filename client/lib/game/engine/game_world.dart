import 'dart:math' as math;

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/mob.dart';

/// Flame 游戏世界 —— 负责 Canvas 渲染循环、实体管理、输入处理
///
/// - 相机跟随玩家 (camera.follow)
/// - 世界坐标由 Vector2 维护
/// - 键盘输入使用 `KeyboardEvents` mixin
class GameWorld extends FlameGame with HasCollisionDetection, KeyboardEvents {
  GameWorld({
    this.mapId = 1,
    this.mapName = '未知地图',
    this.mapWidth = 1600,
    this.mapHeight = 900,
    this.playerInitial,
  });

  final int mapId;
  final String mapName;
  final double mapWidth;
  final double mapHeight;
  final Vector2? playerInitial;

  late final PlayerComponent player;
  final List<MobComponent> mobs = [];
  final List<NPCComponent> npcs = [];

  // 玩家运行时数据（供 UI 读取）
  int hp = 100;
  int maxHp = 100;
  int mp = 50;
  int maxMp = 50;
  int level = 1;

  // 输入状态
  final Set<LogicalKeyboardKey> _keysDown = {};

  @override
  Future<void> onLoad() async {
    await super.onLoad();

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

    // --- 键盘移动 ---
    final move = Vector2.zero();
    if (_keysDown.contains(LogicalKeyboardKey.keyA) ||
        _keysDown.contains(LogicalKeyboardKey.arrowLeft)) {
      move.x -= 1;
    }
    if (_keysDown.contains(LogicalKeyboardKey.keyD) ||
        _keysDown.contains(LogicalKeyboardKey.arrowRight)) {
      move.x += 1;
    }
    if (_keysDown.contains(LogicalKeyboardKey.keyW) ||
        _keysDown.contains(LogicalKeyboardKey.arrowUp)) {
      move.y -= 1;
    }
    if (_keysDown.contains(LogicalKeyboardKey.keyS) ||
        _keysDown.contains(LogicalKeyboardKey.arrowDown)) {
      move.y += 1;
    }
    if (move.length > 0.01) {
      player.move(move.normalized(), dt);
    }

    // --- 攻击键 (J / Space) ---
    if (_keysDown.contains(LogicalKeyboardKey.keyJ) ||
        _keysDown.contains(LogicalKeyboardKey.space)) {
      player.attack();
    }
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
        'position': {'x': player.position.x, 'y': player.position.y},
      };

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

  void attack() {
    if (_attackTimer <= 0) {
      _attackTimer = attackCooldown;
      animationState = 'attack';
    }
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

  MobComponent({required this.mob, required Vector2 position})
      : super(
          position: position,
          size: Vector2(60, 60),
          anchor: Anchor.center,
        );

  void updateAI(double dt, PlayerComponent player) {
    if (!mob.isAlive) return;

    _aiTimer += dt;

    // 简单 AI：当玩家距离 < 200 时朝玩家移动
    final dx = player.position.x - position.x;
    final dy = player.position.y - position.y;
    final distSq = dx * dx + dy * dy;

    if (distSq < 200 * 200 && distSq > 50 * 50) {
      final dist = math.sqrt(distSq);
      final dirX = dx / dist;
      final dirY = dy / dist;
      position.x += dirX * mob.speed * dt * 10;
      position.y += dirY * mob.speed * dt * 10;
      mob.posX = position.x;
      mob.posY = position.y;
    } else if (_aiTimer > 2) {
      position.x += (math.Random().nextDouble() - 0.5) * mob.speed * dt * 30;
      position.y += (math.Random().nextDouble() - 0.5) * mob.speed * dt * 30;
      _aiTimer = 0;
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
