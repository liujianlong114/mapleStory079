import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 079 地图传送门（MapHelper portalContinue 动画 + 碰撞传送）
class PortalComponent extends SpriteAnimationComponent {
  PortalComponent({
    required this.portalId,
    required this.portalName,
    required this.portalType,
    required this.targetMapId,
    required this.targetPortalName,
    required Vector2 worldPosition,
    this.onEnter,
    int priority = 20,
  }) : super(
          position: worldPosition,
          anchor: Anchor.bottomCenter,
          size: Vector2(104, 118),
          priority: priority,
        );

  final int portalId;
  final String portalName;
  final int portalType;
  final int targetMapId;
  final String targetPortalName;
  final VoidCallback? onEnter;

  static const Set<int> _visibleTypes = {2, 3, 7, 8}; // REGULAR, TOUCH, SCRIPTED, etc.

  bool get isVisible => _visibleTypes.contains(portalType) || portalType == 9;

  @override
  bool containsPoint(Vector2 point) {
    final dx = (point.x - position.x).abs();
    final dy = (point.y - position.y).abs();
    return dx <= 36 && dy <= 56;
  }

  static Future<SpriteAnimation?> loadPortalAnimation() async {
    final frames = <Sprite>[];
    for (var i = 0; i < 7; i++) {
      final path = 'assets/sprites/portal/continue_$i.png';
      try {
        final data = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        frames.add(Sprite(frame.image));
      } catch (_) {
        break;
      }
    }
    if (frames.isEmpty) return null;
    return SpriteAnimation.spriteList(frames, stepTime: 0.12, loop: true);
  }

  @override
  Future<void> onLoad() async {
    if (!isVisible) {
      removeFromParent();
      return;
    }
    final anim = await loadPortalAnimation();
    if (anim != null) {
      animation = anim;
      size = Vector2(anim.frames.first.sprite.srcSize.x, anim.frames.first.sprite.srcSize.y);
    }
  }

  @override
  void render(Canvas canvas) {
    if (animation != null) {
      super.render(canvas);
      return;
    }
    final paint = Paint()..color = const Color(0xAA00BFFF);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 18, paint);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 10, Paint()..color = const Color(0xFFFFFFFF));
  }
}
