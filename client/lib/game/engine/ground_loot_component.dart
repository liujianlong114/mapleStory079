import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/resources/assets.dart';
import 'sprite_loader.dart';

/// 地面掉落物组件（MapleItem / mesos）
///
/// 特性：
///  1) 掉落瞬间 y 有一段弹跳动画（参考 079 MapleItem.drop）
///  2) 恒定浮动（y 方向 ±3px，周期 ~1.8s）
///  3) 20 秒后自动消失；最后 3 秒闪烁提示
///  4) 有 quantity > 1 时右下角叠加数字标签
///  5) 图标优先使用 `sprites/item/{itemId}.png`；mesos 用 gold 占位
///
/// 由 [GameWorld] 在收到怪物死亡/服务器 loot spawn 消息时创建。
class GroundLootComponent extends PositionComponent {
  GroundLootComponent({
    required this.dropId,
    required this.itemId,
    this.quantity = 1,
    this.isMesos = false,
    required Vector2 position,
    this.initialBounce = true,
    Duration? lifetime,
  })  : lifetime = lifetime ?? const Duration(seconds: 20),
        super(
          position: position,
          size: Vector2.all(40),
          anchor: Anchor.bottomCenter,
          priority: 1000,
        );

  final String dropId;
  final int itemId;
  final int quantity;
  final bool isMesos;
  final bool initialBounce;
  final Duration lifetime;

  Sprite? _sprite;
  bool _spriteLoaded = false;
  bool _expired = false;

  // 动画时间累加
  double _t = 0.0;
  // 初始弹跳的起始 y（用于弹跳动画幅度）
  double _baseY = 0.0;

  /// 是否已超时（GameWorld 会据此将其从地图中移除）
  bool get expired => _expired;

  @override
  Future<void> onLoad() async {
    _baseY = position.y;
    await _loadSprite();
    return super.onLoad();
  }

  Future<void> _loadSprite() async {
    try {
      final path = isMesos ? SpriteDirs.itemPath(400) : SpriteDirs.itemPath(itemId);
      _sprite = await SpriteLoader.tryLoad(path);
    } catch (_) {
      _sprite = null;
    }
    _spriteLoaded = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;

    // 生命结束 → 标记过期，GameWorld 下一帧清理
    if (_t >= lifetime.inSeconds.toDouble()) {
      _expired = true;
      return;
    }

    // 1) 初始掉落弹跳（约前 0.6s，y 向高处弹起再落下）
    double dy = 0.0;
    if (initialBounce && _t < 0.6) {
      // 一条简单抛物线：起点 0 → 高点 -12 → 落回 0
      final p = _t / 0.6;
      dy = -12.0 * math.sin(p * math.pi);
    }

    // 2) 常规浮动（弹跳结束后开始）
    if (!initialBounce || _t >= 0.6) {
      dy += math.sin((_t - (initialBounce ? 0.6 : 0.0)) * 3.5) * 2.5;
    }

    position.y = _baseY + dy;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 最后 3 秒闪烁：每 0.2s 切换透明度
    final remain = lifetime.inSeconds.toDouble() - _t;
    final blink = remain <= 3.0 && (_t * 5).floor().isEven;
    if (blink) return;

    // Shadow（079 MapleItem：脚下一个灰色椭圆）
    final shadowPaint = Paint()
      ..color = const Color(0x55000000)
      ..filterQuality = FilterQuality.none;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y - 2),
        width: size.x * 0.55,
        height: 6,
      ),
      shadowPaint,
    );

    if (_sprite != null) {
      final paint = Paint()..filterQuality = FilterQuality.none;
      final sw = _sprite!.srcSize.x;
      final sh = _sprite!.srcSize.y;
      // 让精灵大小以 32px 为基准，但不超过容器
      final scale = 32.0 / math.max(sw, sh);
      final renderW = sw * scale;
      final renderH = sh * scale;
      final dx = (size.x - renderW) / 2;
      final dy = (size.y - renderH) - 4; // 底部对齐 shadow 上方
      _sprite!.render(
        canvas,
        position: Vector2(dx, dy),
        size: Vector2(renderW, renderH),
        overridePaint: paint,
      );
    } else {
      // 占位绘制：一个方形 + 颜色标识
      final paint = Paint()
        ..color = isMesos ? const Color(0xFFF1C40F) : const Color(0xFF2980B9)
        ..filterQuality = FilterQuality.none;
      canvas.drawRect(
        Rect.fromLTWH(size.x / 2 - 14, size.y - 32, 28, 28),
        paint,
      );
      final borderPaint = Paint()
        ..color = const Color(0xFF111111)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRect(
        Rect.fromLTWH(size.x / 2 - 14, size.y - 32, 28, 28),
        borderPaint,
      );
      if (_spriteLoaded) {
        // 显示文字 itemId
        final textPainter = TextPainter(
          text: TextSpan(
            text: isMesos ? 'meso' : '$itemId',
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(size.x / 2 - textPainter.width / 2, size.y - 28),
        );
      }
    }

    // 数量标签：仅 quantity > 1 显示
    if (quantity > 1) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '×$quantity',
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Color(0xAA000000), offset: Offset(1, 1), blurRadius: 1),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(size.x - textPainter.width - 2, size.y - textPainter.height - 2),
      );
    }
  }
}
