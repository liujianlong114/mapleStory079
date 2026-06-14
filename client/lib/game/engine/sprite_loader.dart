import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';

/// Sprite 资源说明
///
/// 真实的冒险岛资源需要从 wz 中提取，以下只是一个通用的"精灵加载器"：
/// - 优先使用 `assets/sprites/` 下的图像资源（png / jpg / webp）
/// - 如果资源不存在，则回退到程序化绘制的占位精灵
/// - 动画采用水平序列帧的方式（`srcFrames`：帧数，`stepTime`：每帧时长）
///
/// 资源路径约定：
///   - 玩家：assets/sprites/player/player_idle.png / player_walk.png / player_attack.png
///   - 怪物：assets/sprites/mobs/<mob_id>/mob.png
///   - NPC：  assets/sprites/npcs/<npc_id>/npc.png
class SpriteLoader {
  SpriteLoader._();

  /// 加载单帧精灵（若资源不存在则返回 null，由调用方决定回退逻辑）
  static Future<Sprite?> tryLoad(String assetPath) async {
    try {
      return await Flame.images.load(assetPath).then(Sprite.new);
    } catch (_) {
      return null;
    }
  }

  /// 加载动画精灵（水平序列帧）
  static Future<SpriteAnimation?> tryLoadAnimation(
    String assetPath, {
    required int frames,
    double stepTime = 0.12,
    bool loop = true,
  }) async {
    try {
      final image = await Flame.images.load(assetPath);
      return SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
          amount: frames,
          stepTime: stepTime,
          textureSize: Vector2(
            image.width / frames,
            image.height.toDouble(),
          ),
          loop: loop,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// 生成一个程序化的占位精灵（用于快速渲染演示，不依赖外部图片）
  static Sprite placeholder({
    required int width,
    required int height,
    Color color = const Color(0xFFf1c40f),
    Color accent = const Color(0xFFd35400),
  }) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, accent],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    // 简单装饰: 一个圆圈 + 十字
    canvas.drawCircle(
      Offset(width / 2, height / 2),
      width * 0.2,
      Paint()..color = const Color(0xFFFFFFFF).withOpacity(0.4),
    );
    canvas.drawLine(
      const Offset(10, 10),
      Offset(width - 10, height - 10),
      Paint()
        ..color = const Color(0xFFFFFFFF).withOpacity(0.25)
        ..strokeWidth = 2,
    );

    final picture = recorder.endRecording();
    final image = picture.toImageSync(width, height);
    return Sprite(image);
  }
}
