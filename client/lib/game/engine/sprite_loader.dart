import 'dart:convert';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/components.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../core/resources/assets.dart';
import '../../models/char_look.dart';

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

  /// Phase 1：后端 wzpy 实时合成完整 CharLook
  /// [scale] 游戏内用 1（与地图/NPC 1:1 WZ 像素一致）；选角 UI 用 3 更清晰。
  /// 079 姿势帧数与 delay（ms），来自 Character.wz Body pose_frame_delays
  static const Map<String, ({int frames, List<double> stepTimes})> wzPoseTiming = {
    'swingO1': (frames: 3, stepTimes: [0.30, 0.15, 0.35]),
    'proneStab': (frames: 2, stepTimes: [0.30, 0.40]),
    'walk1': (frames: 4, stepTimes: [0.18, 0.18, 0.18, 0.18]),
    'stand1': (frames: 3, stepTimes: [0.50, 0.50, 0.50]),
  };

  /// Phase 1：按帧拉取 compose PNG 组成动画（HeavenClient stance + stframe）
  static Future<SpriteAnimation?> tryLoadComposeAnimation(
    CharLook look, {
    required String pose,
    int scale = 1,
    int maxFrames = 4,
    double stepTime = 0.18,
    List<double>? stepTimes,
    bool loop = true,
    int minFrameW = 40,
    int minFrameH = 38,
  }) async {
    final timing = wzPoseTiming[pose];
    final frameLimit = timing?.frames ?? maxFrames;
    final perFrameTimes = stepTimes ?? timing?.stepTimes;

    final sprites = <Sprite>[];
    for (var frame = 0; frame < frameLimit; frame++) {
      final params = look.toQueryParams(pose: pose, frame: frame);
      params['scale'] = '$scale';
      if (scale <= 1) params['pad'] = '0';
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/look/compose.png')
          .replace(queryParameters: params);
      try {
        final resp = await http.get(uri).timeout(const Duration(seconds: 20));
        if (resp.statusCode != 200 || resp.bodyBytes.length < 256) break;
        final codec = await ui.instantiateImageCodec(resp.bodyBytes);
        final img = (await codec.getNextFrame()).image;
        if (img.width < minFrameW || img.height < minFrameH) break;
        sprites.add(Sprite(img));
      } catch (_) {
        break;
      }
    }
    if (sprites.isEmpty) return null;
    if (sprites.length == 1) {
      return SpriteAnimation.spriteList(
        sprites,
        stepTime: perFrameTimes?.first ?? stepTime,
        loop: loop,
      );
    }
    final times = perFrameTimes != null && perFrameTimes.length >= sprites.length
        ? perFrameTimes.sublist(0, sprites.length)
        : List.filled(sprites.length, stepTime);
    return SpriteAnimation.variableSpriteList(
      sprites,
      stepTimes: times,
      loop: loop,
    );
  }

  static double poseDurationSeconds(String pose) {
    final t = wzPoseTiming[pose];
    if (t == null) return 0.45;
    return t.stepTimes.fold<double>(0, (a, b) => a + b);
  }

  static Future<Sprite?> tryLoadCompose(
    CharLook look, {
    String pose = 'stand1',
    int frame = 0,
    int scale = 1,
  }) async {
    try {
      final params = look.toQueryParams(pose: pose, frame: frame);
      params['scale'] = '$scale';
      if (scale <= 1) params['pad'] = '0';
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/look/compose.png')
          .replace(queryParameters: params);
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200 || resp.bodyBytes.length < 256) return null;
      final codec = await ui.instantiateImageCodec(resp.bodyBytes);
      final decoded = await codec.getNextFrame();
      return Sprite(decoded.image);
    } catch (_) {
      return null;
    }
  }

  static Future<Sprite?> tryLoad(String assetPath) =>
      tryLoadFirst([assetPath]);

  /// 079 bottomCenter 锚点：局部 (0,0) 为脚底中心
  static void renderFeetAnchored(
    Canvas canvas,
    Sprite sprite,
    Vector2 boxSize, {
    int direction = -1,
  }) {
    final w = sprite.srcSize.x;
    final h = sprite.srcSize.y;
    final paint = Paint()..filterQuality = FilterQuality.none;

    canvas.save();
    if (direction > 0) {
      canvas.scale(-1, 1);
      sprite.render(
        canvas,
        position: Vector2(-w / 2, -h),
        size: Vector2(w, h),
        overridePaint: paint,
      );
    } else {
      sprite.render(
        canvas,
        position: Vector2(-w / 2, -h),
        size: Vector2(w, h),
        overridePaint: paint,
      );
    }
    canvas.restore();
  }

  /// 079 不等宽动画条带：靠 manifest 中每帧宽度切分（CharacterRenderer.compose_animation）
  static Future<SpriteAnimation?> tryLoadStripManifest(
    String stripPath,
    String manifestPath, {
    bool loop = true,
  }) async {
    try {
      final raw = await rootBundle.loadString(_bundle(manifestPath));
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final widths = (j['widths'] as List?)?.map((e) => (e as num).toDouble()).toList();
      if (widths == null || widths.isEmpty) return null;
      final stepTime = (j['stepTime'] as num?)?.toDouble() ?? 0.18;
      final image = await loadImage(stripPath);
      if (image == null) return null;
      var x = 0.0;
      final sprites = <Sprite>[];
      for (final w in widths) {
        if (w < 1) continue;
        sprites.add(
          Sprite(
            image,
            srcPosition: Vector2(x, 0),
            srcSize: Vector2(w, image.height.toDouble()),
          ),
        );
        x += w;
      }
      if (sprites.isEmpty) return null;
      return SpriteAnimation.spriteList(sprites, stepTime: stepTime, loop: loop);
    } catch (_) {
      return null;
    }
  }

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
