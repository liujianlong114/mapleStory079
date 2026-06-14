import 'package:flutter/material.dart';

/// 079 小地图：按 VR 矩形缩放，白框表示当前镜头视野
class MiniMapWidget extends StatelessWidget {
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

  const MiniMapWidget({
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

  double get _vrW => (vrRight - vrLeft).clamp(1, 99999);
  double get _vrH => (vrBottom - vrTop).clamp(1, 99999);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      decoration: BoxDecoration(
        color: const Color(0xFF1a1208).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF8D6E63), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: const BoxDecoration(
              color: Color(0xFF2d1f10),
              borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
            ),
            child: Text(
              mapName,
              style: const TextStyle(
                color: Color(0xFFffe08a),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AspectRatio(
            aspectRatio: 1.35,
            child: CustomPaint(
              painter: _MiniMapPainter(
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 4),
            child: Text(
              '(${playerX.round()}, ${playerY.round()})',
              style: const TextStyle(color: Color(0xAAFFFFFF), fontSize: 9),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMapPainter extends CustomPainter {
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

  _MiniMapPainter({
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
    final bg = Paint()..color = const Color(0xFF3d5c3a);
    canvas.drawRect(Offset.zero & size, bg);

    // 地面带（彩虹村主地面约在 VR 中下段）
    final groundPaint = Paint()..color = const Color(0xFF5a4a32);
    final gy = _sy(vrTop + vrH * 0.72, size.height);
    canvas.drawRect(
      Rect.fromLTWH(0, gy, size.width, size.height - gy),
      groundPaint,
    );

    // 当前镜头视野（079 白框）
    final vx = _sx(cameraX, size.width);
    final vy = _sy(cameraY, size.height);
    final vw = (viewW / vrW) * size.width;
    final vh = (viewH / vrH) * size.height;
    canvas.drawRect(
      Rect.fromLTWH(vx, vy, vw, vh),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    for (final p in npcDots) {
      canvas.drawCircle(
        Offset(_sx(p.dx, size.width), _sy(p.dy, size.height)),
        2.2,
        Paint()..color = const Color(0xFFffe08a),
      );
    }
    for (final p in mobDots) {
      canvas.drawCircle(
        Offset(_sx(p.dx, size.width), _sy(p.dy, size.height)),
        1.8,
        Paint()..color = const Color(0xFFe74c3c),
      );
    }

    // 玩家（白点 + 黄心，079 风格）
    final px = _sx(playerX, size.width).clamp(2.0, size.width - 2.0);
    final py = _sy(playerY, size.height).clamp(2.0, size.height - 2.0);
    canvas.drawCircle(Offset(px, py), 3.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(px, py), 2, Paint()..color = const Color(0xFFffe08a));
  }

  @override
  bool shouldRepaint(covariant _MiniMapPainter old) =>
      old.playerX != playerX ||
      old.playerY != playerY ||
      old.cameraX != cameraX ||
      old.cameraY != cameraY;
}
