import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/game_provider.dart';
import '../../core/resources/assets.dart';
import 'game_scene_page.dart';

/// 从 GameProvider 读取角色/地图信息后进入 Flame 场景（079 风格加载屏）
class GameSceneLoader extends StatefulWidget {
  const GameSceneLoader({super.key});

  @override
  State<GameSceneLoader> createState() => _GameSceneLoaderState();
}

class _GameSceneLoaderState extends State<GameSceneLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gp, _) {
        if (gp.isLoading || gp.currentCharacter == null) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF050818), Color(0xFF1B0F3A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '正在进入冒险世界...',
                      style: TextStyle(
                        color: Color(0xFFFFB13A),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(
                      width: 220,
                      child: LinearProgressIndicator(
                        color: Color(0xFFFFB13A),
                        backgroundColor: Color(0xFF3B2414),
                      ),
                    ),
                    if (gp.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        gp.errorMessage!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }

        final char = gp.currentCharacter!;
        final map = gp.currentMap;
        final mapId = map?.id ?? char.mapId;
        final mapName = map?.name ?? '彩虹村';
        final mapW = (map?.width ?? 1600).toDouble();
        final mapH = (map?.height ?? 900).toDouble();

        return FadeTransition(
          opacity: _fadeCtrl,
          child: GameScenePage(
            mapId: mapId,
            mapName: mapName,
            mapWidth: mapW,
            mapHeight: mapH,
            characterId: char.id,
            jobId: char.characterClass,
            initialHp: char.hp,
            initialMaxHp: char.maxHp,
            initialMp: char.mp,
            initialMaxMp: char.maxMp,
            initialLevel: char.level,
            initialExp: char.experience,
            initialStr: char.str,
            initialDex: char.dex,
            initialIntl: char.intl,
            initialLuk: char.luk,
            bgmAsset: BgmAssets.byMapId(mapId),
          ),
        );
      },
    );
  }
}
