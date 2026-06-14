import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/resources/assets.dart';
import '../../core/resources/map_meta.dart';
import 'map_foothold.dart';

/// 079 横版地图视差层（官方 Map.wz back PNG）
class WzMapLayer extends PositionComponent with HasGameReference<FlameGame> {
  final int mapId;
  final double mapW;
  final double mapH;

  WzMapLayer({
    required this.mapId,
    required double width,
    required double height,
  })  : mapW = width,
        mapH = height,
        super(size: Vector2(width, height), priority: -10);

  MapMeta? _meta;
  MapFootholds? _footholds;
  List<MapLayerDef> _layers = [];
  final Map<String, ui.Image> _images = {};
  double get groundY => _meta?.spawnY.toDouble() ?? mapH * 605 / 600;

  MapFootholds? get footholds => _footholds;

  @override
  Future<void> onLoad() async {
    final full = await MapMetaFull.load(mapId);
    _meta = full?.meta;
    _layers = full?.layers ?? [];
    _footholds = full?.footholds;

    for (final layer in _layers) {
      final key = '${layer.bS}_${layer.no}';
      if (_images.containsKey(key)) continue;
      final paths = [
        AssetPaths.bundle('maps/back/${layer.bS}/${layer.no}.png'),
        AssetPaths.bundle(
          'images/ui/login/back/${layer.no.toString().padLeft(2, '0')}.png',
        ),
      ];
      for (final path in paths) {
        if (await _tryLoadPath(key, path)) break;
      }
    }
  }

  Future<bool> _tryLoadPath(String key, String bundledPath) async {
    try {
      final data = await rootBundle.load(bundledPath);
      if (data.lengthInBytes < 400) return false;
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _images[key] = frame.image;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_images.isEmpty) {
      _renderSideScrollerFallback(canvas);
      return;
    }
    final cam = game.camera.viewfinder.position;
    final sorted = [..._layers]..sort((a, b) => a.ry.compareTo(b.ry));
    for (final layer in sorted) {
      final img = _images['${layer.bS}_${layer.no}'];
      if (img == null) continue;
      final alpha = (layer.alpha / 255).clamp(0.0, 1.0);
      // Flame 画布已含相机变换；视差世界坐标 = layer + camera * (r/100)
      final drawX = layer.x + cam.x * (layer.rx / 100.0);
      final drawY = layer.y + cam.y * (layer.ry / 100.0);
      canvas.drawImage(
        img,
        Offset(drawX, drawY),
        Paint()..color = Color.fromRGBO(255, 255, 255, alpha),
      );
    }
  }

  void _renderSideScrollerFallback(Canvas canvas) {
    final gy = groundY;
    final sky = Rect.fromLTWH(0, 0, mapW, gy);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF87CEEB), Color(0xFFB3E5FC), Color(0xFFE1F5FE)],
        ).createShader(sky),
    );
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

class MapLayerDef {
  final int no;
  final int type;
  final int x;
  final int y;
  final int rx;
  final int ry;
  final int alpha;
  final String bS;

  const MapLayerDef({
    required this.no,
    required this.type,
    required this.x,
    required this.y,
    required this.rx,
    required this.ry,
    required this.alpha,
    required this.bS,
  });

  factory MapLayerDef.fromJson(Map<String, dynamic> j) => MapLayerDef(
        no: (j['no'] as num?)?.toInt() ?? 0,
        type: (j['type'] as num?)?.toInt() ?? 0,
        x: (j['x'] as num?)?.toInt() ?? 0,
        y: (j['y'] as num?)?.toInt() ?? 0,
        rx: (j['rx'] as num?)?.toInt() ?? 0,
        ry: (j['ry'] as num?)?.toInt() ?? 0,
        alpha: (j['a'] as num?)?.toInt() ?? 255,
        bS: j['bS'] as String? ?? 'grassySoil',
      );
}

class MapForegroundLayerDef {
  final int id;
  final String tS;
  final List<MapTileDef> tiles;
  final List<MapObjDef> objs;

  MapForegroundLayerDef({
    required this.id,
    required this.tS,
    required this.tiles,
    required this.objs,
  });

  factory MapForegroundLayerDef.fromJson(Map<String, dynamic> j) =>
      MapForegroundLayerDef(
        id: (j['id'] as num?)?.toInt() ?? 0,
        tS: j['tS'] as String? ?? '',
        tiles: (j['tiles'] as List?)
                ?.map((e) => MapTileDef.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        objs: (j['objs'] as List?)
                ?.map((e) => MapObjDef.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class MapTileDef {
  final int x;
  final int y;
  final String u;
  final int no;
  final int zM;
  final int ox;
  final int oy;

  MapTileDef({
    required this.x,
    required this.y,
    required this.u,
    required this.no,
    required this.zM,
    this.ox = 0,
    this.oy = 0,
  });

  factory MapTileDef.fromJson(Map<String, dynamic> j) => MapTileDef(
        x: (j['x'] as num?)?.toInt() ?? 0,
        y: (j['y'] as num?)?.toInt() ?? 0,
        u: j['u'] as String? ?? '',
        no: (j['no'] as num?)?.toInt() ?? 0,
        zM: (j['zM'] as num?)?.toInt() ?? 0,
        ox: (j['ox'] as num?)?.toInt() ?? 0,
        oy: (j['oy'] as num?)?.toInt() ?? 0,
      );
}

class MapObjDef {
  final int x;
  final int y;
  final String oS;
  final String l0;
  final String l1;
  final String l2;
  final int z;
  final int f;
  final int zM;
  final int ox;
  final int oy;

  MapObjDef({
    required this.x,
    required this.y,
    required this.oS,
    required this.l0,
    required this.l1,
    required this.l2,
    required this.z,
    this.f = 0,
    this.zM = 0,
    this.ox = 0,
    this.oy = 0,
  });

  factory MapObjDef.fromJson(Map<String, dynamic> j) => MapObjDef(
        x: (j['x'] as num?)?.toInt() ?? 0,
        y: (j['y'] as num?)?.toInt() ?? 0,
        oS: j['oS'] as String? ?? '',
        l0: j['l0'] as String? ?? '',
        l1: j['l1'] as String? ?? '',
        l2: '${j['l2'] ?? '0'}',
        z: (j['z'] as num?)?.toInt() ?? 0,
        f: (j['f'] as num?)?.toInt() ?? 0,
        zM: (j['zM'] as num?)?.toInt() ?? 0,
        ox: (j['ox'] as num?)?.toInt() ?? 0,
        oy: (j['oy'] as num?)?.toInt() ?? 0,
      );
}

class MapMetaFull {
  final MapMeta meta;
  final List<MapLayerDef> layers;
  final List<MapForegroundLayerDef> mapLayers;
  final MapFootholds? footholds;

  MapMetaFull({
    required this.meta,
    required this.layers,
    required this.mapLayers,
    this.footholds,
  });

  static Future<MapMetaFull?> load(int mapId) async {
    final paths = <String>{
      if (mapId == 1000000 || mapId == 10000) 'assets/maps/1000000.json',
      if (mapId == 1000001 || mapId == 1000002) 'assets/maps/1000000.json',
      if (mapId == 100000000 || mapId == 10000000) 'assets/maps/100000000.json',
      'assets/maps/$mapId.json',
    };
    for (final p in paths) {
      try {
        final raw = await rootBundle.loadString(p);
        final j = jsonDecode(raw) as Map<String, dynamic>;
        final meta = MapMeta.fromJson(j);
        final layers = (j['layers'] as List?)
                ?.map((e) => MapLayerDef.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        final mapLayers = (j['mapLayers'] as List?)
                ?.map(
                  (e) => MapForegroundLayerDef.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            [];
        final fh = MapFootholds.fromJson(
          j['footholds'] as List?,
          fallbackY: meta.spawnY.toDouble(),
        );
        return MapMetaFull(
          meta: meta,
          layers: layers,
          mapLayers: mapLayers,
          footholds: fh,
        );
      } catch (_) {}
    }
    return null;
  }
}
