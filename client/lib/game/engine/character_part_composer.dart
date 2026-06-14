import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/resources/avatar_assets.dart';
import 'sprite_loader.dart';

/// **已弃用**：parts/*.png 是 WZ 单部件碎片，无 BodyDrawInfo 锚点不能叠层。
/// 请用 extract_avatars.py / extract_beginner_avatars.py 导出的 characters/avatars/*.png。
@Deprecated('Use CharacterRenderer.compose avatars, not raw parts stacking')
class CharacterPartComposer {
  CharacterPartComposer._();

  static Future<Sprite?> composeStand({
    required int gender,
    required int face,
    required int hair,
    int top = 0,
    int bottom = 0,
    int shoes = 0,
    int weapon = 0,
  }) async {
    final faceId = AvatarAssets.resolveFace(gender, face);
    final hairId = AvatarAssets.resolveHair(gender, hair);
    final topId = top != 0 ? top : AvatarAssets.defaultTop(gender);
    final bottomId = bottom != 0 ? bottom : AvatarAssets.defaultBottom(gender);
    final shoesId = shoes != 0 ? shoes : AvatarAssets.defaultShoes();
    final bodyId = gender == 1 ? 2001 : 2000;

    final layers = <int>[
      bodyId,
      bottomId,
      shoesId,
      topId,
      hairId,
      faceId,
      if (weapon != 0) weapon,
      if (weapon == 0) AvatarAssets.defaultBeginnerWeapon,
    ];

    final images = <ui.Image>[];
    for (final id in layers) {
      final img = await SpriteLoader.loadImage('characters/parts/$id.png');
      if (img != null) images.add(img);
    }
    if (images.isEmpty) return null;

    var maxW = 0.0;
    var maxH = 0.0;
    for (final img in images) {
      if (img.width > maxW) maxW = img.width.toDouble();
      if (img.height > maxH) maxH = img.height.toDouble();
    }
    if (maxW < 8 || maxH < 8) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..filterQuality = FilterQuality.none;
    for (final img in images) {
      final dx = (maxW - img.width) / 2;
      final dy = maxH - img.height;
      canvas.drawImage(img, Offset(dx, dy), paint);
    }
    final picture = recorder.endRecording();
    final composed = await picture.toImage(maxW.round(), maxH.round());
    for (final img in images) {
      img.dispose();
    }
    return Sprite(composed);
  }
}
