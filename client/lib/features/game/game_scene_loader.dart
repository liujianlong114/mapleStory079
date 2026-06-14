import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/game_provider.dart';
import '../../core/resources/assets.dart';
import '../../core/resources/map_meta.dart';
import '../../core/storage/storage_service.dart';
import '../../services/api_service.dart';
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
  MapMeta? _mapMeta;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreSession());
  }

  Future<void> _restoreSession() async {
    final gp = context.read<GameProvider>();
    if (gp.currentCharacter != null) return;
    final storage = StorageService();
    final token = await storage.getToken();
    final charId = await storage.getCharacterId();
    if (token != null && token.isNotEmpty) {
      ApiService().setToken(token);
    }
    if (charId != null && charId > 0 && mounted) {
      await gp.loadCharacterState(charId);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMapMetaOnce();
  }

  bool _metaLoaded = false;

  Future<void> _loadMapMetaOnce() async {
    if (_metaLoaded) return;
    _metaLoaded = true;
    final gp = context.read<GameProvider>();
    final mapId = gp.currentMap?.id ?? gp.currentCharacter?.mapId ?? 1000000;
    final meta = await MapMeta.loadForMap(mapId);
    if (mounted && meta != null) setState(() => _mapMeta = meta);
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
        final mapName = map?.name ?? _mapMeta?.name ?? '彩虹村';
        final mapW = (_mapMeta?.width ?? map?.width ?? 1705).toDouble();
        // 079 地图逻辑高度 = VRBottom - VRTop（非视口 600px）
        final mapH = (_mapMeta?.height ?? 1230).toDouble();
        final groundY = (_mapMeta?.spawnY ?? 605).toDouble();
        final spawnX = char.positionX > 0
            ? char.positionX.toDouble()
            : (_mapMeta?.spawnX ?? 400).toDouble();
        final spawnY = char.positionY > 0
            ? char.positionY.toDouble()
            : (_mapMeta?.spawnY ?? groundY).toDouble();

        return FadeTransition(
          opacity: _fadeCtrl,
          child: GameScenePage(
            mapId: mapId,
            mapName: mapName,
            mapWidth: mapW,
            mapHeight: mapH,
            groundY: groundY,
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
            initialPosX: spawnX,
            initialPosY: spawnY,
            bgmAsset: BgmAssets.byMapId(mapId),
            playerGender: char.gender,
            playerFace: char.face,
            playerHair: char.hair,
            playerTop: char.top,
            playerBottom: char.bottom,
            playerShoes: char.shoes,
            playerWeapon: char.weapon,
            playerCap: char.cap,
            playerCape: char.cape,
            playerGlove: char.glove,
            playerShield: char.shield,
            playerFaceAcc: char.faceAcc,
            playerEyeAcc: char.eyeAcc,
            playerEarring: char.earring,
            playerLongcoat: char.longcoat,
          ),
        );
      },
    );
  }
}
