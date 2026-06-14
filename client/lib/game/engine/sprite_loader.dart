import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/components.dart';

import '../../core/resources/assets.dart';

/// 079 精灵加载：rootBundle 解码 PNG（Web 上 Flame.images 路径常失效）。
class SpriteLoader {
  SpriteLoader._();

  static const int minRealPngBytes = 400;

  static String _bundle(String path) => AssetPaths.bundle(path);

  static Future<bool> _isRealAsset(String path) async {
    try {
      final data = await rootBundle.load(_bundle(path));
      return data.lengthInBytes >= minRealPngBytes;
    } catch (_) {
      return false;
    }
  }

  static Future<ui.Image?> loadImage(String assetPath) async {
    if (!await _isRealAsset(assetPath)) return null;
    try {
      final data = await rootBundle.load(_bundle(assetPath));
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  /// 按候选路径顺序加载，命中第一个有效 PNG。
  static Future<Sprite?> tryLoadFirst(Iterable<String> paths) async {
    for (final path in paths) {
      final img = await loadImage(path);
      if (img != null) return Sprite(img);
    }
    return null;
  }

  static Future<Sprite?> tryLoad(String assetPath) =>
      tryLoadFirst([assetPath]);

  static Future<SpriteAnimation?> tryLoadAnimation(
    String assetPath, {
    required int frames,
    double stepTime = 0.12,
    bool loop = true,
  }) async {
    final image = await loadImage(assetPath);
    if (image == null || frames < 1) return null;
    final fw = image.width / frames;
    if (fw < 1) return null;
    return SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: frames,
        stepTime: stepTime,
        textureSize: Vector2(fw, image.height.toDouble()),
        loop: loop,
      ),
    );
  }

  static Sprite placeholder({
    required int width,
    required int height,
    Color color = const Color(0xFFf1c40f),
    Color accent = const Color(0xFFd35400),
  }) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, accent],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
    canvas.drawCircle(
      Offset(width / 2, height / 2),
      width * 0.2,
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.4),
    );
    final picture = recorder.endRecording();
    final image = picture.toImageSync(width, height);
    return Sprite(image);
  }
}
