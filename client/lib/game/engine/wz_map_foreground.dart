import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/resources/assets.dart';
import 'map_render_utils.dart';
import 'wz_map_layer.dart';

/// 079 地图 Tile + Obj 前景层（HeavenClient MapTilesObjs）
///
/// **世界坐标 1:1 像素**：`screen = world + viewpos`，origin 从锚点减去。
class WzMapForegroundLayer extends PositionComponent
    with HasGameReference<FlameGame> {
  WzMapForegroundLayer({
    required this.mapId,
    required this.basePriority,
    required double width,
    required double height,
  }) : super(
          size: Vector2(width, height),
          priority: basePriority,
        );

  final int mapId;
  final int basePriority;

  final Map<String, ui.Image> _images = {};
  final List<MapForegroundLayerDef> _layerDefs = [];
  final List<_DrawItem> _items = [];

  /// WZ 无法解码时，用相近真实贴图代替（禁止渲染 placeholder 色块）
  static const Map<String, String> _tileFallback = {
    'enH0': 'bsc',
    'enV0': 'bsc',
    'enV1': 'bsc',
    'edU': 'bsc',
    'slLU': 'slLD',
    'slRU': 'slRD',
  };

  static const int _minTileBytes = 350;

  @override
  Future<void> onLoad() async {
    final full = await MapMetaFull.load(mapId);
    final layers = full?.mapLayers ?? [];
    if (layers.isEmpty) return;
    _layerDefs.addAll(layers);

    for (final layer in layers) {
      final tS = layer.tS.isNotEmpty ? layer.tS : 'grassySoil';
      for (final o in layer.objs) {
        final path = AssetPaths.bundle(
          'maps/obj/${o.oS}/${o.l0}_${o.l1}_${o.l2}.png',
        );
        final img = await _loadObjImage(path);
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
        final img = await _loadTileImage(tS, t.u, t.no);
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

    // 079：按层 id → obj 先于 tile → z 升序
    _items.sort((a, b) {
      final lc = a.layerId.compareTo(b.layerId);
      if (lc != 0) return lc;
      if (a.isObj != b.isObj) return a.isObj ? -1 : 1;
      return a.z.compareTo(b.z);
    });
  }

  Future<ui.Image?> _loadTileImage(String tS, String u, int no) async {
    final primary = AssetPaths.bundle('maps/tiles/$tS/${u}_$no.png');
    // 先尝试 primary（即使 placeholder 也尝试，因为可能有 fallback）
    var img = await _loadImage(primary, skipPlaceholder: false);
    if (img != null) return img;
    // primary 失败或不存在，尝试 fallback
    final alt = _tileFallback[u];
    if (alt != null) {
      img = await _loadImage(AssetPaths.bundle('maps/tiles/$tS/${alt}_$no.png'));
      if (img != null) return img;
    }
    return null;
  }

  Future<bool> _isPlaceholderAsset(String bundledPath) async {
    try {
      final metaPath = bundledPath.replaceFirst('.png', '.png.json');
      final raw = await rootBundle.loadString(metaPath);
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return j['placeholder'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<ui.Image?> _loadObjImage(String bundledPath) async {
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

  Future<ui.Image?> _loadImage(String bundledPath, {bool skipPlaceholder = true}) async {
    if (_images.containsKey(bundledPath)) return _images[bundledPath];
    try {
      final data = await rootBundle.load(bundledPath);
      if (data.lengthInBytes < _minTileBytes) return null;
      if (skipPlaceholder && await _isPlaceholderAsset(bundledPath)) return null;
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

    final v = MapRenderUtils.msView(game);
    final paint = Paint()..filterQuality = FilterQuality.none;

    // 079 Stage::draw：按 mapLayer id 0→7 逐层绘制（层内已 obj→tile 排序）
    for (final layerDef in _layerDefs) {
      for (final item in _items.where((i) => i.layerId == layerDef.id)) {
      final left = item.x - item.ox;
      final top = item.y - item.oy;
      final iw = item.image.width.toDouble();
      final ih = item.image.height.toDouble();

      // 视口外剔除（世界坐标）
      final cam = v.cam;
      if (left + iw < cam.x ||
          left > cam.x + v.viewW ||
          top + ih < cam.y ||
          top > cam.y + v.viewH) {
        continue;
      }

      if (!item.flip) {
        canvas.drawImage(item.image, Offset(left, top), paint);
        continue;
      }
      canvas.save();
      canvas.translate(left + item.ox, top);
      canvas.scale(-1, 1);
      canvas.drawImage(item.image, Offset(-item.ox, 0), paint);
      canvas.restore();
      }
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
