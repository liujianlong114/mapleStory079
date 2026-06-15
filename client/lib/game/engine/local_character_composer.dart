import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/resources/assets.dart';
import '../../core/resources/avatar_assets.dart';
import 'sprite_loader.dart';

/// 本地角色合成器（离线时无需后端 /look/compose.png）。
/// 
/// 使用 extract_parts.py 导出的 {id}.json 元数据（origin/map_anchors/z_slot）
/// + WZ z-map（embedded）对部件进行正确的锚点链式定位 + z 排序叠层。
/// 
/// 合成流程（对照 wzpy/character.py CharacterRenderer.compose）：
/// 1. 加载所有装备部件的 PNG + JSON 元数据
/// 2. 按类别优先级排序：Body(0) → Head(1) → 其他(2)
/// 3. Body 放在世界坐标 (0,0)（以 navel 为锚点）
/// 4. 其他部件：查找最佳锚点（navel > neck > hand > brow），
///    从已放置部件的世界锚点表获取该锚点的世界坐标，
///    用 canvas 的 origin + map_anchors[anchor] 计算 top_left 进行定位
/// 5. 所有 canvas 按 z_index 排序后依次 alpha_composite 到画布
class LocalCharacterComposer {
  LocalCharacterComposer._();

  /// Z-map 嵌入（来自 wzpy/character.py _DEFAULT_ZMAP，index 越小越靠后/先画）
  /// 顺序：back→front
  static final List<String> _zMap = [
    'Bd', 'Hd', 'Hr', 'Fc', 'At', 'Af', 'Am', 'Ae', 'As', 'Ay',
    'Cp', 'Ri', 'Gv', 'Wp', 'Si', 'So', 'Pn', 'Ws', 'Ma', 'Wg',
    'Sr', 'Tm', 'Sd',
    'backTamingMobMid', 'backMobEquipUnderSaddle', 'backSaddle',
    'backMobEquipMid', 'backTamingMobFront', 'backMobEquipFront',
    'mobEquipRear', 'tamingMobRear', 'saddleRear',
    'characterEnd',
    'backWeaponEffectUnder', 'backWeapon', 'backWeaponEffectOver',
    'backHairBelowHead', 'backShieldBelowBody', 'backMailChestAccessory',
    'backCapAccessory', 'backAccessoryFace', 'backAccessoryEar',
    'backBody', 'backGlove', 'backGloveWrist',
    'backWeaponOverGloveEffectUnder', 'backWeaponOverGlove', 'backWeaponOverGloveEffectOver',
    'backMailChestBelowPants', 'backPantsBelowShoes', 'backShoesBelowPants',
    'backPants', 'backShoes', 'backPantsOverShoesBelowMailChest',
    'backMailChest', 'backPantsOverMailChest', 'backMailChestOverPants',
    'backHead', 'backAccessoryFaceOverHead', 'backAccessoryOverHead',
    'backCape', 'backHairBelowCap', 'backHairBelowCapNarrow', 'backHairBelowCapWide',
    'backWeaponOverHeadEffectUnder', 'backWeaponOverHead', 'backWeaponOverHeadEffectOver',
    'backCap', 'backHair', 'backCapOverHair',
    'backShield', 'backWeaponOverShieldEffectUnder', 'backWeaponOverShield', 'backWeaponOverShieldEffectOver',
    'backWing', 'backHairOverCape',
    'weaponBelowBodyEffectUnder', 'weaponBelowBody', 'weaponBelowBodyEffectOver',
    'hairBelowBody', 'capeBelowBody', 'shieldBelowBody',
    'capAccessoryBelowBody', 'gloveBelowBody', 'gloveWristBelowBody',
    'body', 'gloveOverBody', 'mailChestBelowPants', 'pantsBelowShoes',
    'shoes', 'pants', 'mailChestOverPants', 'shoesOverPants',
    'pantsOverShoesBelowMailChest', 'shoesTop', 'mailChest',
    'pantsOverMailChest', 'mailChestOverHighest', 'gloveWristOverBody',
    'mailChestTop', 'capeBelowWeapon',
    'weaponOverBodyEffectUnder', 'weaponOverBody', 'weaponOverBodyEffectOver',
    'armBelowHead', 'mailArmBelowHead', 'armBelowHeadOverMailChest',
    'gloveBelowHead', 'mailArmBelowHeadOverMailChest', 'gloveWristBelowHead',
    'weaponOverArmBelowHeadEffectUnder', 'weaponOverArmBelowHead', 'weaponOverArmBelowHeadEffectOver',
    'shield', 'weaponEffectUnder', 'weapon', 'weaponEffectOver',
    'arm', 'hand', 'glove', 'mailArm', 'gloveWrist',
    'cape', 'head', 'hairShade',
    'accessoryFaceBelowFace', 'accessoryEyeBelowFace',
    'face', 'accessoryFaceOverFaceBelowCap', 'capBelowAccessory',
    'accessoryEar', 'capAccessoryBelowAccFace', 'accessoryFace',
    'accessoryEyeShadow', 'accessoryEye', 'capeOverFace',
    'hair', 'cap', 'capAccessory', 'accessoryEyeOverCap',
    'hairOverHead', 'accessoryOverHair', 'accessoryEarOverHair',
    'capOverHair',
    'weaponBelowArmEffectUnder', 'weaponBelowArm', 'weaponBelowArmEffectOver',
    'armOverHairBelowWeapon', 'mailArmOverHairBelowWeapon', 'armOverHair',
    'gloveBelowMailArm', 'mailArmOverHair', 'gloveWristBelowMailArm',
    'weaponOverArmEffectUnder', 'weaponOverArm', 'weaponOverArmEffectOver',
    'handBelowWeapon', 'gloveBelowWeapon', 'gloveWristBelowWeapon',
    'shieldOverHair',
    'weaponOverHandEffectUnder', 'weaponOverHand', 'weaponOverHandEffectOver',
    'handOverHair', 'gloveOverHair', 'gloveWristOverHair',
    'weaponOverGloveEffectUnder', 'weaponOverGlove', 'weaponOverGloveEffectOver',
    'capeOverHead',
    'weaponWristOverGloveEffectUnder', 'weaponWristOverGlove', 'weaponWristOverGloveEffectOver',
    'emotionOverBody', 'characterStart',
    'backSaddleFront', 'saddleMid', 'tamingMobMid',
    'mobEquipUnderSaddle', 'saddleFront', 'mobEquipMid',
    'tamingMobFront', 'mobEquipFront',
  ];

  static int _zIndex(String? slot) {
    if (slot == null) return _zMap.length;
    final idx = _zMap.indexOf(slot);
    if (idx >= 0) return idx;
    // Heuristic for unknown slots
    final s = slot.toLowerCase();
    if (s.startsWith('back')) {
      final base = s.length > 4 ? s[4].toUpperCase() + s.substring(5) : slot;
      final bi = _zMap.indexOf(base);
      if (bi >= 0) return (bi - 5).clamp(0, _zMap.length - 1);
      return (_zMap.indexOf('body') - 1).clamp(0, _zMap.length - 1);
    }
    if (s.contains('below')) {
      final parts = s.split('below');
      if (parts.length > 1) {
        final target = parts.last.trim();
        final capitalized = target.isNotEmpty ? target[0].toUpperCase() + target.substring(1) : target;
        final ti = _zMap.indexOf(capitalized);
        if (ti >= 0) return (ti - 1).clamp(0, _zMap.length - 1);
      }
    }
    if (s.contains('over')) {
      final parts = s.split('over');
      if (parts.length > 1) {
        final target = parts.last.trim();
        final capitalized = target.isNotEmpty ? target[0].toUpperCase() + target.substring(1) : target;
        final ti = _zMap.indexOf(capitalized);
        if (ti >= 0) return (ti + 1).clamp(0, _zMap.length - 1);
      }
    }
    return _zMap.length - 1;
  }

  /// 按 ID 前缀识别部件类别（对照 wzpy/character.py _CATEGORY_BY_ID_PREFIX）
  static String? _categoryForId(int id) {
    final prefix = id ~/ 10000;
    switch (prefix) {
      case 0: return 'Body';
      case 1: return 'Head';
      case 2: return 'Face';
      case 3: return 'Hair';
      case 4: return 'Hair';
      case 5: return 'Face';
      case 6: return 'Hair';
      case 100: return 'Cap';
      case 101: return 'FaceAcc';
      case 102: return 'Glass';
      case 103: return 'Earring';
      case 104: return 'Coat';
      case 105: return 'Longcoat';
      case 106: return 'Pants';
      case 107: return 'Shoes';
      case 108: return 'Glove';
      case 109: return 'Shield';
      case 110: return 'Cape';
      default:
        if (prefix >= 121 && prefix <= 160) return 'Weapon';
        if (prefix == 170) return 'Weapon';
        return null;
    }
  }

  /// 部件类别优先级（body=0 最低，先放；head=1；其他=2）
  static int _categoryPriority(String? cat) {
    switch (cat) {
      case 'Body': return 0;
      case 'Head': return 1;
      default: return 2;
    }
  }

  static const _anchorPriority = ['navel', 'neck', 'hand', 'brow', 'handMove'];

  /// 合成角色立绘（stand1）
  /// 
  /// [gender] 0=男 1=女
  /// [face] 脸型 ID
  /// [hair] 发型 ID
  /// [top] 上衣 ID（0=默认）
  /// [bottom] 裤子 ID（0=默认）
  /// [shoes] 鞋子 ID（0=默认）
  /// [weapon] 武器 ID（0=默认）
  /// [cap/cape/glove/shield/faceAcc/eyeAcc/earring/longcoat] 其他装备（可选）
  static Future<Sprite?> composeStand({
    required int gender,
    required int face,
    required int hair,
    int top = 0,
    int bottom = 0,
    int shoes = 0,
    int weapon = 0,
    int cap = 0,
    int cape = 0,
    int glove = 0,
    int shield = 0,
    int faceAcc = 0,
    int eyeAcc = 0,
    int earring = 0,
    int longcoat = 0,
  }) async {
    final faceId = AvatarAssets.resolveFace(gender, face);
    final hairId = AvatarAssets.resolveHair(gender, hair);
    final topId = top != 0 ? top : AvatarAssets.defaultTop(gender);
    final bottomId = bottom != 0 ? bottom : AvatarAssets.defaultBottom(gender);
    final shoesId = shoes != 0 ? shoes : AvatarAssets.defaultShoes();
    final weaponId = weapon != 0 ? weapon : AvatarAssets.defaultBeginnerWeapon;
    final bodyId = gender == 1 ? 2001 : 2000;
    final headId = bodyId + 10000;

    // 构建装备 ID 列表（Body→Head→Hair→Face→装备）
    final equipIds = <int>{
      bodyId,
      headId,
      hairId,
      faceId,
      if (longcoat != 0) longcoat,
      if (topId != 0) topId,
      if (bottomId != 0) bottomId,
      if (shoesId != 0) shoesId,
      if (cap != 0) cap,
      if (cape != 0) cape,
      if (glove != 0) glove,
      if (shield != 0) shield,
      if (faceAcc != 0) faceAcc,
      if (eyeAcc != 0) eyeAcc,
      if (earring != 0) earring,
      if (weaponId != 0) weaponId,
    }.toList();

    // 加载所有部件的 PNG + 元数据
    final loadedParts = <_LoadedPart>[];
    for (final id in equipIds) {
      final part = await _loadPart(id);
      if (part != null) loadedParts.add(part);
    }
    if (loadedParts.isEmpty) return null;

    // 收集所有 canvas 以便 z 排序
    final allCanvases = <_CanvasRef>[];
    for (final part in loadedParts) {
      for (final cv in part.canvases) {
        allCanvases.add(cv);
      }
    }

    // 世界锚点表：{anchorName: (worldX, worldY)}
    final worldAnchors = <String, _Point>{};

    // 按类别优先级排序：Body → Head → 其他
    loadedParts.sort((a, b) {
      final pa = _categoryPriority(a.category);
      final pb = _categoryPriority(b.category);
      if (pa != pb) return pa.compareTo(pb);
      // 同类别按名字排序保序
      return a.partId.compareTo(b.partId);
    });

    // 遍历放置部件（建立锚点链）
    for (final part in loadedParts) {
      for (final cv in part.canvases) {
        if (cv.topLeft != null) continue; // 已放置

        if (part.category == 'Body' && cv.name == 'body') {
          // Body: 世界 (0,0) = navel 锚点
          // top_left = -origin - navel_offset
          final navelOffset = cv.anchors['navel'];
          final ox = cv.originX.toDouble();
          final oy = cv.originY.toDouble();
          if (navelOffset != null) {
            cv.topLeft = _Point(-ox - navelOffset.x, -oy - navelOffset.y);
          } else {
            cv.topLeft = _Point(-ox, -oy);
          }
          _registerAnchors(cv, worldAnchors);
          continue;
        }

        // 查找最佳锚点
        String? bestAnchor;
        _Point? bestWorld;
        for (final anchor in _anchorPriority) {
          if (cv.anchors.containsKey(anchor)) {
            final world = worldAnchors[anchor];
            if (world != null) {
              bestAnchor = anchor;
              bestWorld = world;
              break;
            }
          }
        }

        if (bestWorld != null && bestAnchor != null) {
          final anchorOffset = cv.anchors[bestAnchor]!;
          final ox = cv.originX.toDouble();
          final oy = cv.originY.toDouble();
          // top_left = world_anchor - origin - anchor_offset
          cv.topLeft = _Point(
            bestWorld.x - ox - anchorOffset.x,
            bestWorld.y - oy - anchorOffset.y,
          );
        } else {
          // 无锚点可追踪，使用 bodyNavel 参考
          final ox = cv.originX.toDouble();
          final oy = cv.originY.toDouble();
          final navelOff = cv.anchors['navel'];
          if (navelOff != null) {
            cv.topLeft = _Point(-ox - navelOff.x, -oy - navelOff.y);
          } else {
            cv.topLeft = _Point(-ox, -oy);
          }
        }
        _registerAnchors(cv, worldAnchors);
      }
    }

    // Z 排序并合成
    allCanvases.sort((a, b) {
      final za = _zIndex(a.zSlot);
      final zb = _zIndex(b.zSlot);
      if (za != zb) return za.compareTo(zb);
      return a.name.compareTo(b.name);
    });

    // 计算边界框
    double minX = 0, minY = 0, maxX = 0, maxY = 0;
    var hasAny = false;
    for (final cv in allCanvases) {
      final tl = cv.topLeft;
      if (tl == null || cv.image == null) continue;
      hasAny = true;
      final w = cv.image!.width.toDouble();
      final h = cv.image!.height.toDouble();
      if (tl.x < minX) minX = tl.x;
      if (tl.y < minY) minY = tl.y;
      if (tl.x + w > maxX) maxX = tl.x + w;
      if (tl.y + h > maxY) maxY = tl.y + h;
    }
    if (!hasAny) return null;

    final width = (maxX - minX).clamp(1, 9999).toInt();
    final height = (maxY - minY).clamp(1, 9999).toInt();
    if (width < 4 || height < 4) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..filterQuality = FilterQuality.none;

    for (final cv in allCanvases) {
      final tl = cv.topLeft;
      if (tl == null || cv.image == null) continue;
      final dx = tl.x - minX;
      final dy = tl.y - minY;
      canvas.drawImage(cv.image!, Offset(dx, dy), paint);
    }

    final picture = recorder.endRecording();
    final composed = await picture.toImage(width, height);

    // 释放 PNG 图像内存
    for (final part in loadedParts) {
      for (final cv in part.canvases) {
        cv.image?.dispose();
      }
    }

    return Sprite(composed);
  }

  static void _registerAnchors(_CanvasRef cv, Map<String, _Point> worldAnchors) {
    final tl = cv.topLeft;
    if (tl == null) return;
    final ox = cv.originX.toDouble();
    final oy = cv.originY.toDouble();
    for (final entry in cv.anchors.entries) {
      final anchorName = entry.key;
      if (!worldAnchors.containsKey(anchorName)) {
        worldAnchors[anchorName] = _Point(tl.x + ox + entry.value.x, tl.y + oy + entry.value.y);
      }
    }
  }

  static Future<_LoadedPart?> _loadPart(int id) async {
    final jsonPath = 'characters/parts/$id.json';
    try {
      final jsonData = await rootBundle.loadString(AssetPaths.bundle(jsonPath));
      final Map<String, dynamic> meta = jsonDecode(jsonData);
      final canvasesList = meta['canvases'] as List;
      final canvases = <_CanvasRef>[];

      for (final c in canvasesList) {
        final canvasName = c['name'] as String;
        final originX = c['origin_x'] as int;
        final originY = c['origin_y'] as int;
        final zSlot = c['z_slot'] as String?;
        final zIndex = c['z_index'] as int? ?? _zIndex(zSlot);

        final anchors = <String, _Point>{};
        final mapAnchors = c['map_anchors'] as Map<String, dynamic>?;
        if (mapAnchors != null) {
          for (final entry in mapAnchors.entries) {
            final v = entry.value as Map<String, dynamic>;
            anchors[entry.key] = _Point((v['x'] as num).toDouble(), (v['y'] as num).toDouble());
          }
        }

        // 加载 PNG
        ui.Image? img;
        try {
          img = await SpriteLoader.loadImage('characters/parts/$id.png');
        } catch (_) {}

        canvases.add(_CanvasRef(
          name: canvasName,
          originX: originX,
          originY: originY,
          anchors: anchors,
          zSlot: zSlot,
          zIndex: zIndex,
          image: img,
        ));
      }

      final cat = _categoryForId(id);
      return _LoadedPart(partId: id, category: cat ?? 'Unknown', canvases: canvases);
    } catch (_) {
      return null;
    }
  }
}

class _Point {
  final double x, y;
  _Point(this.x, this.y);
}

class _CanvasRef {
  final String name;
  final int originX;
  final int originY;
  final Map<String, _Point> anchors;
  final String? zSlot;
  final int zIndex;
  ui.Image? image;
  _Point? topLeft;

  _CanvasRef({
    required this.name,
    required this.originX,
    required this.originY,
    required this.anchors,
    this.zSlot,
    required this.zIndex,
    this.image,
  });
}

class _LoadedPart {
  final int partId;
  final String category;
  final List<_CanvasRef> canvases;

  _LoadedPart({required this.partId, required this.category, required this.canvases});
}
