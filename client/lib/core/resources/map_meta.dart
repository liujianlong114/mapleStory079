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
      // 彩虹村/新手村
      if (mapId == 1000000 || mapId == 10000) 'assets/maps/1000000.json',
      if (mapId == 1000001 || mapId == 1000002) 'assets/maps/1000000.json',
      // 明珠港
      if (mapId == 104000000 || mapId == 10300 || mapId == 10400) 'assets/maps/104000000.json',
      // 射手村 → 101000000
      if (mapId == 10500 || mapId == 10501 || mapId == 10502 || mapId == 101000000) 'assets/maps/101000000.json',
      // 魔法密林 → 102000000
      if (mapId == 10800 || mapId == 10900 || mapId == 11000 || mapId == 102000000) 'assets/maps/102000000.json',
      // 勇士部落 → 103000000
      if (mapId == 11300 || mapId == 11400 || mapId == 11500 || mapId == 103000000) 'assets/maps/103000000.json',
      // 废弃都市/冰峰雪域/玩具城/天空之城/林中 → 100000000
      if (mapId == 11700 || mapId == 11800 || mapId == 11900) 'assets/maps/100000000.json',
      if (mapId == 12000 || mapId == 12100 || mapId == 12200 || mapId == 12300) 'assets/maps/100000000.json',
      if (mapId == 12400 || mapId == 12500 || mapId == 12600) 'assets/maps/100000000.json',
      if (mapId == 12700 || mapId == 12800 || mapId == 12900) 'assets/maps/100000000.json',
      if (mapId == 13000 || mapId == 13100 || mapId == 13200 || mapId == 13300) 'assets/maps/100000000.json',
      // BOSS/训练场/其他
      if (mapId >= 14000 && mapId < 20000) 'assets/maps/20000.json',
      if (mapId >= 20000 && mapId < 30000) 'assets/maps/20000.json',
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
