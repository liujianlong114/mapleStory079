import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Alignment, LinearGradient, TextDirection, TextPainter, TextSpan, TextStyle;

/// 彩虹岛 / 新手村专用地图渲染（无 WZ 贴图时的高保真程序化还原）
class MapleIslandMapLayer extends PositionComponent {
  final int mapId;
  final double mapW;
  final double mapH;

  MapleIslandMapLayer({
    required this.mapId,
    required double width,
    required double height,
  })  : mapW = width,
        mapH = height,
        super(size: Vector2(width, height), priority: -10);

  late final math.Random _rng;
  late final List<_Cloud> _clouds;
  late final List<_Tree> _trees;
  late final List<_House> _houses;

  bool get _isTutorial => mapId == 0;
  bool get _isRainbowVillage =>
      mapId == 10000 ||
      mapId == 1000000 ||
      mapId == 1000001 ||
      mapId == 1000002 ||
      (mapId >= 10000 && mapId < 20000);

  @override
  Future<void> onLoad() async {
    _rng = math.Random(mapId + 79);
    _clouds = List.generate(8, (i) {
      return _Cloud(
        x: _rng.nextDouble() * mapW,
        y: 40 + _rng.nextDouble() * 120,
        scale: 0.6 + _rng.nextDouble() * 0.8,
        speed: 8 + _rng.nextDouble() * 12,
      );
    });
    _trees = [];
    _houses = [];
    if (_isRainbowVillage) {
      for (int i = 0; i < 6; i++) {
        _trees.add(_Tree(
          x: 80.0 + i * 140 + _rng.nextInt(40),
          y: groundY - 20,
          variant: i % 3,
        ));
      }
      _houses.addAll([
        _House(x: 120, y: groundY - 8, w: 90, h: 70, roof: const Color(0xFF8B4513)),
        _House(x: mapW - 210, y: groundY - 8, w: 100, h: 75, roof: const Color(0xFFCD853F)),
      ]);
    }
  }

  double get groundY {
    if (_isRainbowVillage) return mapH * (470 / 750);
    return _isTutorial ? mapH * 0.78 : mapH * 0.82;
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final c in _clouds) {
      c.x += c.speed * dt;
      if (c.x > mapW + 120) c.x = -120;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_isTutorial) {
      _renderTutorial(canvas);
    } else if (_isRainbowVillage) {
      _renderRainbowVillage(canvas);
    } else {
      _renderGenericIsland(canvas);
    }
  }

  void _renderTutorial(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, mapW, mapH);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0a0a18), Color(0xFF1a1030), Color(0xFF0d0820)],
        ).createShader(rect),
    );
    // 星星
    final starPaint = Paint()..color = const Color(0xCCFFFFFF);
    for (int i = 0; i < 60; i++) {
      final sx = (i * 137 + mapId * 17) % mapW.toInt();
      final sy = (i * 89) % (mapH * 0.55).toInt();
      canvas.drawCircle(Offset(sx.toDouble(), sy.toDouble()), (i % 3 == 0) ? 1.5 : 1.0, starPaint);
    }
    _drawPlatform(canvas, 0, groundY, mapW, 28, dark: true);
    _drawSign(canvas, mapW * 0.5, groundY - 90, '开始冒险', const Color(0xFFFFD54F));
    _drawSign(canvas, mapW * 0.5, groundY - 130, '彩虹岛', const Color(0xFF81D4FA));
  }

  void _renderRainbowVillage(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, mapW, mapH);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF87CEEB), Color(0xFFB3E5FC), Color(0xFFE1F5FE)],
        ).createShader(rect),
    );
    // 远山
    _drawHill(canvas, 0, mapH * 0.55, mapW * 0.45, const Color(0xFF66BB6A));
    _drawHill(canvas, mapW * 0.35, mapH * 0.58, mapW * 0.5, const Color(0xFF4CAF50));
    _drawHill(canvas, mapW * 0.6, mapH * 0.52, mapW * 0.5, const Color(0xFF81C784));
    // 云
    for (final c in _clouds) {
      _drawCloud(canvas, c.x, c.y, c.scale);
    }
    // 房屋
    for (final h in _houses) {
      _drawHouse(canvas, h);
    }
    // 树
    for (final t in _trees) {
      _drawTree(canvas, t);
    }
    // 地面草皮
    _drawGrassGround(canvas);
    _drawPlatform(canvas, 0, groundY, mapW, 32, dark: false);
    // 村牌
    _drawSign(canvas, mapW * 0.5, groundY - 110, '彩虹村', const Color(0xFFFFE082));
    _drawSign(canvas, mapW * 0.5, groundY - 145, 'Maple Island', const Color(0xFFEF5350));
    // 彩虹装饰
    _drawRainbow(canvas, mapW * 0.72, 60, 80);
  }

  void _renderGenericIsland(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, mapW, mapH);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF4FC3F7), Color(0xFF81D4FA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect),
    );
    _drawGrassGround(canvas);
    _drawPlatform(canvas, 0, groundY, mapW, 28, dark: false);
  }

  void _drawGrassGround(Canvas canvas) {
    final gy = groundY;
    // 横版：仅平台下方一条暗色填充，不是整块可走绿地板
    canvas.drawRect(
      Rect.fromLTWH(0, gy + 24, mapW, mapH - gy - 24),
      Paint()..color = const Color(0xFF2E4A2E),
    );
    final grass = Paint()..color = const Color(0xFF66BB6A);
    for (double x = 0; x < mapW; x += 12) {
      final h = 6 + (x.toInt() % 5);
      canvas.drawRect(Rect.fromLTWH(x, gy - h, 3, h.toDouble()), grass);
    }
  }

  void _drawPlatform(Canvas canvas, double x, double y, double w, double h, {required bool dark}) {
    final top = dark ? const Color(0xFF424242) : const Color(0xFF8D6E63);
    final edge = dark ? const Color(0xFF212121) : const Color(0xFF5D4037);
    canvas.drawRect(Rect.fromLTWH(x, y, w, h), Paint()..color = top);
    canvas.drawRect(Rect.fromLTWH(x, y, w, 4), Paint()..color = edge);
    if (!dark) {
      for (double gx = x; gx < x + w; gx += 40) {
        canvas.drawRect(Rect.fromLTWH(gx, y + h - 6, 36, 4), Paint()..color = const Color(0xFF6D4C41));
      }
    }
  }

  void _drawHill(Canvas canvas, double x, double y, double w, Color color) {
    final path = Path()
      ..moveTo(x, y + 80)
      ..quadraticBezierTo(x + w * 0.5, y - 40, x + w, y + 80)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withOpacity(0.85));
  }

  void _drawCloud(Canvas canvas, double x, double y, double scale) {
    final p = Paint()..color = const Color(0xEBFFFFFF);
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 60 * scale, height: 24 * scale), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(x - 20 * scale, y + 4), width: 40 * scale, height: 18 * scale), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(x + 22 * scale, y + 6), width: 44 * scale, height: 20 * scale), p);
  }

  void _drawTree(Canvas canvas, _Tree t) {
    canvas.drawRect(
      Rect.fromCenter(center: Offset(t.x, t.y - 25), width: 14, height: 35),
      Paint()..color = const Color(0xFF5D4037),
    );
    final leaf = t.variant == 1
        ? const Color(0xFF2E7D32)
        : (t.variant == 2 ? const Color(0xFF43A047) : const Color(0xFF388E3C));
    if (t.variant == 2) {
      // 蘑菇树
      canvas.drawOval(
        Rect.fromCenter(center: Offset(t.x, t.y - 55), width: 50, height: 30),
        Paint()..color = const Color(0xFFE53935),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(t.x, t.y - 58), width: 44, height: 24),
        Paint()..color = const Color(0xFFFFCDD2),
      );
    } else {
      canvas.drawCircle(Offset(t.x, t.y - 55), 28, Paint()..color = leaf);
      canvas.drawCircle(Offset(t.x - 14, t.y - 48), 20, Paint()..color = leaf.withOpacity(0.9));
      canvas.drawCircle(Offset(t.x + 14, t.y - 48), 20, Paint()..color = leaf.withOpacity(0.9));
    }
  }

  void _drawHouse(Canvas canvas, _House h) {
    canvas.drawRect(Rect.fromLTWH(h.x, h.y - h.h, h.w, h.h), Paint()..color = const Color(0xFFFFF8E1));
    final roof = Path()
      ..moveTo(h.x - 8, h.y - h.h)
      ..lineTo(h.x + h.w * 0.5, h.y - h.h - 35)
      ..lineTo(h.x + h.w + 8, h.y - h.h)
      ..close();
    canvas.drawPath(roof, Paint()..color = h.roof);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(h.x + h.w * 0.5, h.y - h.h * 0.45), width: 18, height: 28),
      Paint()..color = const Color(0xFF6D4C41),
    );
  }

  void _drawSign(Canvas canvas, double cx, double cy, String text, Color color) {
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: 140, height: 32), Paint()..color = const Color(0xFF5D4037));
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: 134, height: 26), Paint()..color = color.withOpacity(0.35));
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  void _drawRainbow(Canvas canvas, double cx, double cy, double r) {
    const colors = [
      Color(0x88EF5350),
      Color(0x88FF9800),
      Color(0x88FFEB3B),
      Color(0x884CAF50),
      Color(0x882196F3),
      Color(0x889C27B0),
    ];
    for (int i = 0; i < colors.length; i++) {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, cy), width: r * 2 - i * 8, height: r - i * 4),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );
    }
  }
}

class _Cloud {
  _Cloud({required this.x, required this.y, required this.scale, required this.speed});
  double x, y, scale, speed;
}

class _Tree {
  _Tree({required this.x, required this.y, required this.variant});
  final double x, y;
  final int variant;
}

class _House {
  _House({required this.x, required this.y, required this.w, required this.h, required this.roof});
  final double x, y, w, h;
  final Color roof;
}
