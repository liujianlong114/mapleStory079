import 'package:flutter/material.dart';

import 'ui/nine_patch_box.dart';

/// 079 小地图 — 左上角，UIWindow.img/MiniMap 边框。
class MapleMiniMap extends StatelessWidget {
  final double vrLeft;
  final double vrRight;
  final double vrTop;
  final double vrBottom;
  final double cameraX;
  final double cameraY;
  final double viewW;
  final double viewH;
  final double playerX;
  final double playerY;
  final String mapName;
  final List<Offset> npcDots;
  final List<Offset> mobDots;

  const MapleMiniMap({
    super.key,
    required this.vrLeft,
    required this.vrRight,
    required this.vrTop,
    required this.vrBottom,
    required this.cameraX,
    required this.cameraY,
    required this.viewW,
    required this.viewH,
    required this.playerX,
    required this.playerY,
    required this.mapName,
    this.npcDots = const [],
    this.mobDots = const [],
  });

  static const double _frameW = 196;
  static const double _frameH = 154;

  double get _vrW => (vrRight - vrLeft).clamp(1, 99999);
  double get _vrH => (vrBottom - vrTop).clamp(1, 99999);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _frameW,
      height: _frameH + 14,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 4,
            top: 0,
            right: 44,
            height: 14,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/ui/hud/minimap_title.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none,
                ),
                Positioned(
                  left: 8,
                  right: 4,
                  child: Text(
                    mapName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Image.asset(
              'assets/images/ui/hud/minimap_btn_map_normal.png',
              height: 14,
              filterQuality: FilterQuality.none,
            ),
          ),
          Positioned(
            left: 0,
            top: 14,
            child: NinePatchBox(
              assetPrefix: 'assets/images/ui/hud/minimap_frame_',
              width: _frameW,
              height: _frameH,
              child: CustomPaint(
                painter: _MapleMiniMapPainter(
                  vrLeft: vrLeft,
                  vrTop: vrTop,
                  vrW: _vrW,
                  vrH: _vrH,
                  cameraX: cameraX,
                  cameraY: cameraY,
                  viewW: viewW,
                  viewH: viewH,
                  playerX: playerX,
                  playerY: playerY,
                  npcDots: npcDots,
                  mobDots: mobDots,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapleMiniMapPainter extends CustomPainter {
  final double vrLeft;
  final double vrTop;
  final double vrW;
  final double vrH;
  final double cameraX;
  final double cameraY;
  final double viewW;
  final double viewH;
  final double playerX;
  final double playerY;
  final List<Offset> npcDots;
  final List<Offset> mobDots;

  _MapleMiniMapPainter({
    required this.vrLeft,
    required this.vrTop,
    required this.vrW,
    required this.vrH,
    required this.cameraX,
    required this.cameraY,
    required this.viewW,
    required this.viewH,
    required this.playerX,
    required this.playerY,
    required this.npcDots,
    required this.mobDots,
  });

  double _sx(double worldX, double w) => ((worldX - vrLeft) / vrW) * w;
  double _sy(double worldY, double h) => ((worldY - vrTop) / vrH) * h;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF2a4a32),
    );

    final groundY = _sy(vrTop + vrH * 0.72, size.height);
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.width, size.height - groundY),
      Paint()..color = const Color(0xFF5a4a32),
    );

    final vx = _sx(cameraX, size.width);
    final vy = _sy(cameraY, size.height);
    final vw = (viewW / vrW) * size.width;
    final vh = (viewH / vrH) * size.height;
    canvas.drawRect(
      Rect.fromLTWH(vx, vy, vw, vh),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    for (final p in npcDots) {
      _dot(canvas, size, p, const Color(0xFFf1c40f), 3);
    }
    for (final p in mobDots) {
      _dot(canvas, size, p, const Color(0xFFe74c3c), 2);
    }

    final px = _sx(playerX, size.width).clamp(3.0, size.width - 3.0);
    final py = _sy(playerY, size.height).clamp(3.0, size.height - 3.0);
    canvas.drawCircle(Offset(px, py), 3, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(px, py), 1.5, Paint()..color = const Color(0xFFf1c40f));
  }

  void _dot(Canvas canvas, Size size, Offset p, Color color, double r) {
    canvas.drawCircle(
      Offset(_sx(p.dx, size.width), _sy(p.dy, size.height)),
      r,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _MapleMiniMapPainter old) =>
      old.playerX != playerX ||
      old.playerY != playerY ||
      old.cameraX != cameraX ||
      old.cameraY != cameraY;
}
