import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

/// 一个一次性播放的贴图动画组件（用于升级闪光 / 物品拾取等）。
///
/// 该组件只播放一轮动画，结束后自动从世界移除，适合 GameWorld.playEffect()
/// 这样的短暂特效场景。帧文件约定：
///
/// ```
/// assets/sprites/effect/{type}_0.png
/// assets/sprites/effect/{type}_1.png
/// ...
/// ```
class EffectSpriteComponent extends SpriteAnimationComponent {
  EffectSpriteComponent({
    required this.type,
    required super.position,
    super.size,
    super.anchor = Anchor.center,
    super.priority = 100,
    this.defaultStepTime = 0.1,
    required SpriteAnimation animation,
  }) : super(animation: animation);

  final String type;
  final double defaultStepTime;

  /// 从 assets 加载指定类型的动画帧；找不到则返回 null（调用方自行跳过）。
  static Future<EffectSpriteComponent?> load(
    String type, {
    required Vector2 position,
    double defaultStepTime = 0.1,
    Anchor anchor = Anchor.center,
  }) async {
    final frames = <Sprite>[];
    for (var i = 0; i < 64; i++) {
      final path = 'assets/sprites/effect/${type}_$i.png';
      try {
        final data = await rootBundle.load(path);
        final codec =
            await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frameInfo = await codec.getNextFrame();
        frames.add(Sprite(frameInfo.image));
      } catch (_) {
        break;
      }
    }
    if (frames.isEmpty) return null;
    final animation = SpriteAnimation.spriteList(
      frames,
      stepTime: defaultStepTime,
      loop: false,
    );
    final first = frames.first;
    final comp = EffectSpriteComponent(
      type: type,
      position: position,
      defaultStepTime: defaultStepTime,
      anchor: anchor,
      animation: animation,
      size: Vector2(first.src.width.toDouble(), first.src.height.toDouble()),
    )..removeOnFinish = true;
    return comp;
  }
}
