import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/resources/map_meta.dart';

/// 079 原版游戏视口：800×600 逻辑分辨率 + letterbox（与 WzSceneScreen 一致）
class OfficialGameViewport extends StatelessWidget {
  final Widget child;

  const OfficialGameViewport({super.key, required this.child});

  static const double logicalW = MapMeta.officialViewportW;
  static const double logicalH = MapMeta.officialViewportH;

  static double fitScale(BoxConstraints c) {
    final sx = c.maxWidth / logicalW;
    final sy = c.maxHeight / logicalH;
    return math.min(sx, sy);
  }

  static Rect gameRect(BoxConstraints c) {
    final scale = fitScale(c);
    final w = logicalW * scale;
    final h = logicalH * scale;
    final left = (c.maxWidth - w) / 2;
    final top = (c.maxHeight - h) / 2;
    return Rect.fromLTWH(left, top, w, h);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rect = gameRect(constraints);
        return Container(
          color: Colors.black,
          child: Stack(
            children: [
              Positioned.fromRect(
                rect: rect,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: SizedBox(
                    width: logicalW,
                    height: logicalH,
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 游戏场景：Flame 画布 + HUD 叠在 800×600 逻辑区域内（对齐原版 UI 位置）
class OfficialGameSceneShell extends StatelessWidget {
  final Widget game;
  final List<Widget> overlays;

  const OfficialGameSceneShell({
    super.key,
    required this.game,
    this.overlays = const [],
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rect = OfficialGameViewport.gameRect(constraints);
        return Container(
          color: Colors.black,
          child: Stack(
            children: [
              Positioned.fromRect(
                rect: rect,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: SizedBox(
                    width: OfficialGameViewport.logicalW,
                    height: OfficialGameViewport.logicalH,
                    child: game,
                  ),
                ),
              ),
              for (final overlay in overlays)
                Positioned.fromRect(
                  rect: rect,
                  child: overlay,
                ),
            ],
          ),
        );
      },
    );
  }
}
