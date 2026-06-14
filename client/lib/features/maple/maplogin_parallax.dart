import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 079 MapLogin2 视差背景（优先使用 WZ 提取的 back/*.png）
class MapLoginParallax extends StatefulWidget {
  final int width;
  final int height;
  /// MapLogin2 镜头中心（世界坐标）。选角屏约 (290, -1220)。
  final double cameraX;
  final double cameraY;

  const MapLoginParallax({
    super.key,
    this.width = 800,
    this.height = 600,
    this.cameraX = 0,
    this.cameraY = 0,
  });

  @override
  State<MapLoginParallax> createState() => _MapLoginParallaxState();
}

class _MapLoginParallaxState extends State<MapLoginParallax>
    with SingleTickerProviderStateMixin {
  List<_LoginLayer> _layers = [];
  final Map<int, ui.Image> _backImages = {};
  late final AnimationController _ctrl;
  double _t = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(() {
        setState(() => _t += 0.016);
      })
      ..repeat();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/scenes/maplogin2_layers.json');
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final list = (j['layers'] as List?)
              ?.map((e) => _LoginLayer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      if (mounted) setState(() => _layers = list);
    } catch (_) {}
    await _loadBackImages();
  }

  Future<void> _loadBackImages() async {
    for (var i = 0; i <= 37; i++) {
      final path = 'assets/images/ui/login/back/${i.toString().padLeft(2, '0')}.png';
      try {
        final data = await rootBundle.load(path);
        if (data.lengthInBytes < 512) continue;
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        if (mounted) {
          setState(() => _backImages[i] = frame.image);
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    for (final img in _backImages.values) {
      img.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(widget.width.toDouble(), widget.height.toDouble()),
      painter: _MapLoginPainter(
        layers: _layers,
        t: _t,
        backImages: _backImages,
        cameraX: widget.cameraX,
        cameraY: widget.cameraY,
      ),
    );
  }
}

class _LoginLayer {
  final int no, type, rx, ry, cx, alpha;
  final int worldX, worldY;
  final double w, h;

  _LoginLayer({
    required this.no,
    required this.type,
    required this.rx,
    required this.ry,
    required this.cx,
    required this.alpha,
    required this.worldX,
    required this.worldY,
    required this.w,
    required this.h,
  });

  factory _LoginLayer.fromJson(Map<String, dynamic> j) => _LoginLayer(
        no: (j['no'] as num?)?.toInt() ?? 0,
        type: (j['type'] as num?)?.toInt() ?? 0,
        rx: (j['rx'] as num?)?.toInt() ?? 0,
        ry: (j['ry'] as num?)?.toInt() ?? 0,
        cx: (j['cx'] as num?)?.toInt() ?? 0,
        alpha: (j['a'] as num?)?.toInt() ?? 255,
        worldX: (j['x'] as num?)?.toInt() ?? 0,
        worldY: (j['y'] as num?)?.toInt() ?? 0,
        w: (j['w'] as num?)?.toDouble() ?? 120,
        h: (j['h'] as num?)?.toDouble() ?? 80,
      );

  double screenX(double cameraX) => 400.0 + (worldX - cameraX) * 0.52;
  double screenY(double cameraY) => 300.0 + (worldY - cameraY) * 0.11;
}

class _MapLoginPainter extends CustomPainter {
  final List<_LoginLayer> layers;
  final double t;
  final Map<int, ui.Image> backImages;
  final double cameraX;
  final double cameraY;

  _MapLoginPainter({
    required this.layers,
    required this.t,
    required this.backImages,
    required this.cameraX,
    required this.cameraY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);
    final sorted = [...layers]..sort((a, b) => a.ry.compareTo(b.ry));
    for (final layer in sorted) {
      _drawLayer(canvas, size, layer);
    }
    _drawVignette(canvas, size);
  }

  void _drawSky(Canvas canvas, Size size) {
    if (backImages.containsKey(0)) {
      _drawBackImage(canvas, backImages[0]!, Offset.zero, size, 1.0);
      return;
    }
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0E1238),
            Color(0xFF1A2850),
            Color(0xFF2D4A28),
            Color(0xFF1E3A1E),
          ],
          stops: [0.0, 0.45, 0.78, 1.0],
        ).createShader(rect),
    );
    final rng = math.Random(79);
    for (int i = 0; i < 120; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.55;
      canvas.drawCircle(
        Offset(x, y),
        rng.nextDouble() * 1.2 + 0.3,
        Paint()..color = Color.fromRGBO(220, 220, 255, 0.4 + rng.nextDouble() * 0.5),
      );
    }
    canvas.drawCircle(
      const Offset(620, 72),
      36,
      Paint()..color = const Color(0xFFFFF5D0),
    );
    canvas.drawCircle(
      const Offset(632, 72),
      36,
      Paint()..color = const Color(0xFF1A2850),
    );
  }

  void _drawBackImage(Canvas canvas, ui.Image img, Offset pos, Size size, double alpha) {
    final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    final dst = Rect.fromLTWH(pos.dx, pos.dy, size.width, size.height);
    canvas.drawImageRect(
      img,
      src,
      dst,
      Paint()..color = Color.fromRGBO(255, 255, 255, alpha.clamp(0.0, 1.0)),
    );
  }

  void _drawLayer(Canvas canvas, Size size, _LoginLayer L) {
    final baseX = L.screenX(cameraX);
    final baseY = L.screenY(cameraY);
    final img = backImages[L.no];
    if (img != null && L.no != 0) {
      final parallax = L.rx == 0 ? 0.0 : math.sin(t * 0.3 + L.no) * (L.rx.abs() / 100.0) * 8;
      final ox = (baseX + parallax - img.width / 2).clamp(-400.0, size.width);
      final oy = (baseY - img.height / 2).clamp(-size.height * 0.3, size.height);
      final alpha = (L.alpha / 255).clamp(0.0, 1.0);
      canvas.drawImage(
        img,
        Offset(ox, oy),
        Paint()..color = Color.fromRGBO(255, 255, 255, alpha),
      );
      return;
    }

    final parallax = L.rx == 0 ? 0.0 : math.sin(t * 0.3 + L.no) * (L.rx.abs() / 100.0) * 12;
    final scrollW = L.cx > 0 ? L.cx.toDouble() : 0.0;
    var dx = parallax;
    if (scrollW > 0) {
      dx = (t * 18 + baseX) % scrollW - scrollW / 2;
    }
    final ox = (baseX + dx).clamp(-200.0, size.width + 200);
    final oy = baseY.clamp(-size.height * 0.5, size.height);

    final alpha = (L.alpha / 255).clamp(0.0, 1.0);
    Paint p(int c) => Paint()..color = Color(c).withValues(alpha: alpha);

    switch (L.type) {
      case 3:
        break;
      case 4:
        final cw = (L.w > 20 ? L.w.clamp(80, 280) : 180.0).toDouble();
        final ch = (L.h > 20 ? L.h.clamp(40, 120) : 60.0).toDouble();
        _drawCloud(canvas, Offset(ox % (size.width + cw) - cw / 2, oy), cw, ch, p(0xAA8899BB));
        if (scrollW > 0) {
          _drawCloud(
            canvas,
            Offset((ox + scrollW * 0.55) % (size.width + cw) - cw / 2, oy + 8),
            cw * 0.85,
            ch * 0.75,
            p(0x998899BB),
          );
        }
        break;
      case 1:
        if (L.no == 33) {
          _drawSidePillar(canvas, Offset(ox, 0), L.w, size.height, p(0xFF152018));
        } else {
          _drawHill(canvas, size, oy + 60, 0xFF1A3020, 0.55);
        }
        break;
      case 0:
        if (L.no >= 34 || L.w >= 700) {
          _drawGroundPlate(canvas, size, oy, L.no, alpha);
        } else if (L.no >= 16 && L.no <= 18) {
          _drawHorizonStrip(canvas, size, oy, L.h, p(0xFF2A4A28));
        } else if (L.no == 9 || L.no == 10 || L.no == 11) {
          _drawMushroom(canvas, Offset(ox.clamp(60, size.width - 60), oy + 140), L.no);
        } else if (L.no >= 12 && L.no <= 14) {
          _drawTree(canvas, Offset(ox, oy + 80), L.w.clamp(80, 200), L.h.clamp(100, 400));
        } else {
          _drawMushroom(canvas, Offset(ox.clamp(40, size.width - 40), oy + 120), L.no);
        }
        break;
      case 2:
        _drawHill(canvas, size, oy + 50, 0xFF234422, 0.8);
        break;
      default:
        _drawCloud(canvas, Offset(ox, oy), L.w.clamp(60, 200), L.h.clamp(30, 80), p(0x668888AA));
    }
  }

  void _drawSidePillar(Canvas c, Offset o, double w, double h, Paint paint) {
    final ww = w > 10 ? w : 20.0;
    c.drawRect(Rect.fromLTWH(o.dx, o.dy, ww, h), paint);
  }

  void _drawGroundPlate(Canvas c, Size size, double baseY, int seed, double alpha) {
    final path = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 6) {
      final y = baseY + math.sin(x * 0.008 + seed) * 12 + math.sin(x * 0.02) * 5;
      path.lineTo(x, y.clamp(baseY - 20, size.height));
    }
    path.lineTo(size.width, size.height);
    path.close();
    c.drawPath(
      path,
      Paint()
        ..color = Color.lerp(
          const Color(0xFF1E4020),
          const Color(0xFF3A6830),
          (seed % 5) / 5.0,
        )!.withValues(alpha: alpha),
    );
  }

  void _drawHorizonStrip(Canvas c, Size size, double y, double h, Paint paint) {
    final hh = h > 10 ? h : 80.0;
    c.drawRect(Rect.fromLTWH(0, y, size.width, hh), paint);
  }

  void _drawCloud(Canvas c, Offset o, double w, double h, Paint paint) {
    final ww = w > 10 ? w : 180.0;
    final hh = h > 10 ? h : 60.0;
    c.drawOval(Rect.fromCenter(center: o, width: ww, height: hh), paint);
    c.drawOval(Rect.fromCenter(center: o + Offset(-ww * 0.25, hh * 0.1), width: ww * 0.55, height: hh * 0.7), paint);
    c.drawOval(Rect.fromCenter(center: o + Offset(ww * 0.2, hh * 0.05), width: ww * 0.5, height: hh * 0.65), paint);
  }

  void _drawHill(Canvas c, Size size, double baseY, int color, double amp) {
    final path = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 8) {
      final y = baseY + math.sin(x * 0.012) * 18 * amp + math.sin(x * 0.004) * 8 * amp;
      path.lineTo(x, y.clamp(0, size.height));
    }
    path.lineTo(size.width, size.height);
    path.close();
    c.drawPath(path, Paint()..color = Color(color));
  }

  void _drawMushroom(Canvas c, Offset o, int seed) {
    final rng = math.Random(seed + 79);
    final capR = 22.0 + rng.nextDouble() * 12;
    c.drawCircle(o + Offset(0, -8), capR, Paint()..color = Color.lerp(const Color(0xFFCC3333), const Color(0xFFDD6644), rng.nextDouble())!);
    c.drawRect(
      Rect.fromCenter(center: o + Offset(0, 12), width: 14, height: 28),
      Paint()..color = const Color(0xFFF5E6C8),
    );
  }

  void _drawTree(Canvas c, Offset o, double w, double h) {
    c.drawRect(
      Rect.fromCenter(center: o + Offset(0, 20), width: 12, height: 40),
      Paint()..color = const Color(0xFF5D4037),
    );
    c.drawCircle(o + Offset(0, -10), 28, Paint()..color = const Color(0xFF2E7D32));
    c.drawCircle(o + Offset(-12, 0), 20, Paint()..color = const Color(0xFF388E3C));
    c.drawCircle(o + Offset(12, 0), 20, Paint()..color = const Color(0xFF43A047));
  }

  void _drawVignette(Canvas c, Size size) {
    c.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
          stops: const [0.65, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant _MapLoginPainter old) =>
      old.t != t ||
      old.backImages.length != backImages.length ||
      old.cameraX != cameraX ||
      old.cameraY != cameraY;
}
