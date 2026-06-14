import 'dart:convert';

import 'package:flutter/services.dart';

/// 079 地图元数据（从 WZ XML 导出，无贴图时用于尺寸/BGM/视差）
class MapMeta {
  final int mapId;
  final String name;
  final String bgm;
  final int width;
  final int height;
  final int spawnX;
  final int spawnY;
  final int vrLeft;
  final int vrRight;
  final int vrTop;
  final int vrBottom;

  static const double sideScrollerViewportH = 600;

  /// 079 客户端逻辑视口（HeavenClient Configuration 默认 800×600）
  static const double officialViewportW = 800;
  static const double officialViewportH = 600;

  const MapMeta({
    required this.mapId,
    required this.name,
    required this.bgm,
    required this.width,
    required this.height,
    this.spawnX = 400,
    this.spawnY = 605,
    this.vrLeft = 0,
    this.vrRight = 1600,
    this.vrTop = 0,
    this.vrBottom = 600,
  });

  factory MapMeta.fromJson(Map<String, dynamic> j) => MapMeta(
        mapId: (j['mapId'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
        bgm: j['bgm'] as String? ?? '',
        width: (j['width'] as num?)?.toInt() ?? 1600,
        height: (j['height'] as num?)?.toInt() ?? 900,
        spawnX: (j['spawnX'] as num?)?.toInt() ?? 400,
        spawnY: (j['spawnY'] as num?)?.toInt() ?? 605,
        vrLeft: (j['vrLeft'] as num?)?.toInt() ?? 0,
        vrRight: (j['vrRight'] as num?)?.toInt() ?? 1600,
        vrTop: (j['vrTop'] as num?)?.toInt() ?? 0,
        vrBottom: (j['vrBottom'] as num?)?.toInt() ?? 600,
      );

  /// 按 mapId 加载地图 JSON 元数据（批量导出城镇后统一走 assets/maps/{id}.json）
  static Future<MapMeta?> loadForMap(int mapId) async {
    final paths = <String>[
      'assets/maps/$mapId.json',
      // 旧 ID 别名（服务端/存档可能仍用短 ID）
      if (mapId == 1000000 || mapId == 10000) 'assets/maps/1000000.json',
      if (mapId == 1000001 || mapId == 1000002) 'assets/maps/1000000.json',
      if (mapId == 104000000 || mapId == 10300 || mapId == 10400) 'assets/maps/104000000.json',
      if (mapId == 100000000 || mapId == 10000000) 'assets/maps/100000000.json',
    ];
    for (final p in paths) {
      try {
        final raw = await rootBundle.loadString(p);
        return MapMeta.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    return null;
  }
}
