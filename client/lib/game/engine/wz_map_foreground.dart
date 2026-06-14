import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/resources/assets.dart';
import 'wz_map_layer.dart';

/// 079 地图 Tile + Obj 前景层（HeavenClient MapTilesObjs）
class WzMapForegroundLayer extends PositionComponent
    with HasGameReference<FlameGame> {
  WzMapForegroundLayer({
    required this.mapId,
    required this.basePriority,
  }) : super(priority: basePriority);

  final int mapId;
  final int basePriority;

  final Map<String, ui.Image> _images = {};
  final List<_DrawItem> _items = [];

  @override
  Future<void> onLoad() async {
    final full = await MapMetaFull.load(mapId);
    final layers = full?.mapLayers ?? [];
    if (layers.isEmpty) return;

    for (final layer in layers) {
      final tS = layer.tS.isNotEmpty ? layer.tS : 'grassySoil';
      for (final o in layer.objs) {
        final path = AssetPaths.bundle(
          'maps/obj/${o.oS}/${o.l0}_${o.l1}_${o.l2}.png',
        );
        final img = await _loadImage(path);
        if (img == null) continue;
        _items.add(
          _DrawItem(
            layerId: layer.id,
            z: o.z,
            isObj: true,
            x: o.x.toDouble(),
            y: o.y.toDouble(),
            ox: o.ox.toDouble(),
            oy: o.oy.toDouble(),
            flip: o.f != 0,
            image: img,
          ),
        );
      }
      for (final t in layer.tiles) {
        final path = AssetPaths.bundle(
          'maps/tiles/$tS/${t.u}_${t.no}.png',
        );
        final img = await _loadImage(path);
        if (img == null) continue;
        _items.add(
          _DrawItem(
            layerId: layer.id,
            z: t.zM,
            isObj: false,
            x: t.x.toDouble(),
            y: t.y.toDouble(),
            ox: t.ox.toDouble(),
            oy: t.oy.toDouble(),
            image: img,
          ),
        );
      }
    }

    // 079：按层 → obj(z) → tile(zM) 排序
    _items.sort((a, b) {
      final lc = a.layerId.compareTo(b.layerId);
      if (lc != 0) return lc;
      if (a.isObj != b.isObj) return a.isObj ? -1 : 1;
      return a.z.compareTo(b.z);
    });
  }

  Future<ui.Image?> _loadImage(String bundledPath) async {
    if (_images.containsKey(bundledPath)) return _images[bundledPath];
    try {
      final data = await rootBundle.load(bundledPath);
      if (data.lengthInBytes < 40) return null;
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _images[bundledPath] = frame.image;
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_items.isEmpty) return;
    final paint = Paint()..filterQuality = FilterQuality.none;
    for (final item in _items) {
      final dx = item.x - item.ox;
      final dy = item.y - item.oy;
      if (!item.flip) {
        canvas.drawImage(item.image, Offset(dx, dy), paint);
        continue;
      }
      canvas.save();
      canvas.translate(item.x + item.ox, item.y - item.oy);
      canvas.scale(-1, 1);
      canvas.drawImage(item.image, Offset(-item.ox, 0), paint);
      canvas.restore();
    }
  }

  @override
  void onRemove() {
    for (final img in _images.values) {
      img.dispose();
    }
    _images.clear();
    super.onRemove();
  }
}

class _DrawItem {
  _DrawItem({
    required this.layerId,
    required this.z,
    required this.isObj,
    required this.x,
    required this.y,
    required this.ox,
    required this.oy,
    required this.image,
    this.flip = false,
  });

  final int layerId;
  final int z;
  final bool isObj;
  final double x;
  final double y;
  final double ox;
  final double oy;
  final bool flip;
  final ui.Image image;
}
