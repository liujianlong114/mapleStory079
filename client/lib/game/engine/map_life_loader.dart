import 'dart:convert';

import 'package:flutter/services.dart';

/// WZ maplife 刷点（NPC/怪物坐标），与 data/maplife/*.json 同步。
class MapLifeNpcSpawn {
  const MapLifeNpcSpawn({
    required this.id,
    required this.x,
    required this.y,
    required this.name,
    required this.dialogue,
    this.footholdId = 0,
    this.hasShop = false,
  });

  final int id;
  final double x;
  final double y;
  final int footholdId;
  final String name;
  final String dialogue;
  final bool hasShop;
}

/// 彩虹岛新手地图 NPC 元数据（String.wz/Npc.img）。
const _npcCatalog = <int, ({String name, String dialogue, bool shop})>{
  2101: (
    name: '希娜',
    dialogue: '你是第一次到冒险岛来吗？怎么样？虽然还很陌生，不过很漂亮吧？希望你能在这里找到很多乐趣~',
    shop: false,
  ),
  2100: (
    name: '莎丽',
    dialogue: '真是个晒衣服的好天气~ 你不觉得吗？',
    shop: false,
  ),
  12100: (
    name: '麦加',
    dialogue: '呜呼。。。不要在那里逛来逛去的，来接受我的修炼怎么样？随时都可以来找我~我会让你变得更强壮。。。',
    shop: false,
  ),
  20100: (
    name: '尤娜',
    dialogue: '什么时候才能离开金银岛看更广阔的世界呢?',
    shop: false,
  ),
  20001: (
    name: '白瑞德',
    dialogue: '制作任何东东我都很有自信.因为彩虹村的皮奥可是我的叔叔哦,从小开始叔叔就教我这些技术.',
    shop: false,
  ),
};

/// 从 assets/maplife/{mapId}.json 读取 NPC 刷点；文件不存在时返回空列表。
Future<List<MapLifeNpcSpawn>> loadMapLifeNpcs(int mapId) async {
  try {
    final raw = await rootBundle.loadString('assets/maplife/$mapId.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final life = data['life'] as List<dynamic>? ?? [];
    final out = <MapLifeNpcSpawn>[];
    for (final entry in life) {
      final row = entry as Map<String, dynamic>;
      if (row['type'] != 'n' || (row['hide'] as num?)?.toInt() == 1) continue;
      final id = (row['id'] as num).toInt();
      final x = (row['x'] as num).toDouble();
      final y = (row['y'] as num?)?.toDouble() ?? 0;
      final fh = (row['fh'] as num?)?.toInt() ?? 0;
      final meta = _npcCatalog[id];
      out.add(MapLifeNpcSpawn(
        id: id,
        x: x,
        y: y,
        footholdId: fh,
        name: meta?.name ?? 'NPC',
        dialogue: meta?.dialogue ?? '你好，冒险者！',
        hasShop: meta?.shop ?? false,
      ));
    }
    return out;
  } catch (_) {
    return [];
  }
}
