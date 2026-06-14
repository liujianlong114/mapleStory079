import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/game_provider.dart';
import '../../core/resources/assets.dart';
import 'game_scene_page.dart';

/// 从 GameProvider 读取角色/地图信息后进入 Flame 场景
class GameSceneLoader extends StatelessWidget {
  const GameSceneLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gp, _) {
        if (gp.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final char = gp.currentCharacter;
        final map = gp.currentMap;
        final mapId = map?.id ?? char?.mapId ?? 100000000;
        final mapName = map?.name ?? '冒险世界';
        final mapW = (map?.width ?? 1600).toDouble();
        final mapH = (map?.height ?? 900).toDouble();
        return GameScenePage(
          mapId: mapId,
          mapName: mapName,
          mapWidth: mapW,
          mapHeight: mapH,
          characterId: char?.id ?? 1,
          jobId: char?.characterClass ?? 0,
          initialHp: char?.hp ?? 50,
          initialMaxHp: char?.maxHp ?? 50,
          initialMp: char?.mp ?? 50,
          initialMaxMp: char?.maxMp ?? 50,
          initialLevel: char?.level ?? 1,
          initialExp: char?.experience ?? 0,
          initialStr: char?.str ?? 10,
          initialDex: char?.dex ?? 4,
          initialIntl: char?.intl ?? 4,
          initialLuk: char?.luk ?? 4,
          bgmAsset: BgmAssets.byMapId(mapId),
        );
      },
    );
  }
}
