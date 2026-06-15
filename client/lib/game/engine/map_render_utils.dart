import 'dart:ui';

import 'package:flame/game.dart';

import '../../core/resources/map_meta.dart';

/// 079 地图渲染坐标（对照 HeavenClient Camera + Stage::draw）
///
/// 官方没有世界矩阵：tile/obj 用 `世界坐标 + viewpos` 画到屏幕；
/// 背景用 `viewx/viewy` 做视差，画在**屏幕坐标**（0..视口宽高）。
class MapRenderUtils {
  MapRenderUtils._();

  /// 079 逻辑视口（HeavenClient Configuration 默认 800×600）
  static const double officialViewW = MapMeta.officialViewportW;
  static const double officialViewH = MapMeta.officialViewportH;

  /// 从 Flame 相机推导 079 viewpos / viewx / viewy
  static ({double viewx, double viewy, double viewW, double viewH, Vector2 cam}) msView(
    FlameGame game,
  ) {
    const viewW = officialViewW;
    const viewH = officialViewH;
    final cam = game.camera.viewfinder.position;
    // Flame 相机 = 世界左上角；079 viewx = 半屏宽 - 玩家世界X = -cam.x
    return (viewx: -cam.x, viewy: -cam.y, viewW: viewW, viewH: viewH, cam: cam);
  }

  /// 取消 Flame 相机变换，使后续 draw 落在屏幕坐标（背景层用）
  static void beginScreenSpace(Canvas canvas, Vector2 cam) {
    canvas.save();
    canvas.translate(cam.x, cam.y);
  }

  static void endScreenSpace(Canvas canvas) {
    canvas.restore();
  }

  /// 079 背景层屏幕 X（MapBackgrounds.cpp）
  static double backScreenX({
    required int type,
    required int layerX,
    required int rx,
    required double viewx,
    required double wOffset,
  }) {
    final isHMobile = type == 4 || type == 6;
    if (isHMobile) return layerX + viewx;
    return rx * (wOffset - viewx) / 100 + wOffset + layerX;
  }

  static double backScreenY({
    required int type,
    required int layerY,
    required int ry,
    required double viewy,
    required double hOffset,
  }) {
    final isVMobile = type == 5 || type == 7;
    if (isVMobile) return layerY + viewy;
    return ry * (hOffset - viewy) / 100 + hOffset + layerY;
  }

  /// tile/obj 屏幕左上角（世界锚点 - origin）
  static double tileLeft(double worldX, double ox, double viewx) => worldX - ox + viewx;

  static double tileTop(double worldY, double oy, double viewy) => worldY - oy + viewy;
}
