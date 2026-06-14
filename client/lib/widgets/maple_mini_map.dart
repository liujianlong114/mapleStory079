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
  final int mapId;
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
    this.mapId = 1000000,
    this.npcDots = const [],
    this.mobDots = const [],
  });

  static const double _frameW = 196;
  static const double _frameH = 154;
  static const double _titleH = 14;

  double get _vrW => (vrRight - vrLeft).clamp(1, 99999);
  double get _vrH => (vrBottom - vrTop).clamp(1, 99999);

  String get _mapThumbAsset => 'assets/images/ui/hud/minimap_$mapId.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _frameW,
      height: _frameH + _titleH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 4,
            top: 0,
            right: 44,
            height: _titleH,
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
              height: _titleH,
              filterQuality: FilterQuality.none,
            ),
          ),
          Positioned(
            left: 0,
            top: _titleH,
            child: NinePatchBox(
              assetPrefix: 'assets/images/ui/hud/minimap_frame_',
              width: _frameW,
              height: _frameH,
              child: _MapleMiniMapBody(
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
                mapThumbAsset: _mapThumbAsset,
                npcDots: npcDots,
                mobDots: mobDots,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapleMiniMapBody extends StatelessWidget {
  const _MapleMiniMapBody({
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
    required this.mapThumbAsset,
    required this.npcDots,
    required this.mobDots,
  });

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
  final String mapThumbAsset;
  final List<Offset> npcDots;
  final List<Offset> mobDots;

  double _sx(double worldX, double w) => ((worldX - vrLeft) / vrW) * w;
  double _sy(double worldY, double h) => ((worldY - vrTop) / vrH) * h;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final vx = _sx(cameraX, w);
        final vy = _sy(cameraY, h);
        final vw = (viewW / vrW) * w;
        final vh = (viewH / vrH) * h;
        final px = _sx(playerX, w).clamp(3.0, w - 3.0);
        final py = _sy(playerY, h).clamp(3.0, h - 3.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              mapThumbAsset,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
              errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF2a4a32)),
            ),
            Positioned(
              left: vx,
              top: vy,
              width: vw,
              height: vh,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1),
                ),
              ),
            ),
            for (final p in npcDots)
              Positioned(
                left: _sx(p.dx, w) - 2,
                top: _sy(p.dy, h) - 3,
                child: Image.asset(
                  'assets/images/ui/hud/marker_npc.png',
                  filterQuality: FilterQuality.none,
                ),
              ),
            for (final p in mobDots)
              Positioned(
                left: _sx(p.dx, w) - 1,
                top: _sy(p.dy, h) - 1,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFFe74c3c),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Positioned(
              left: px - 3,
              top: py - 3,
              child: Image.asset(
                'assets/images/ui/hud/marker_user.png',
                filterQuality: FilterQuality.none,
              ),
            ),
          ],
        );
      },
    );
  }
}
