import 'package:audioplayers/audioplayers.dart';

/// Flutter bundle 键必须以 `assets/` 开头；manifest / WZ 路径省略此前缀。
class AssetPaths {
  AssetPaths._();

  static String bundle(String path) {
    if (path.isEmpty) return path;
    if (path.startsWith('assets/')) return path;
    return 'assets/$path';
  }

  static List<String> bundleAll(Iterable<String> paths) =>
      paths.map(bundle).toList();
}

/// ms079 MapLogin2 — 全登录流程统一 BGM: BgmUI/Title
class BgmAssets {
  static const String login = 'audio/title.mp3';
  static const String loginWav = 'audio/title.wav';
  static const String title = login;
  static const String titleWav = loginWav;
  static const String charSelect = login;
  static const String charSelectWav = loginWav;
  static const String mapleIsland  = 'audio/00001000.ogg';
  static const String lithHarbor   = 'audio/00002000.ogg';
  static const String nautilus     = 'audio/00002001.ogg';
  static const String perion       = 'audio/00100000.ogg';
  static const String ellinia      = 'audio/00101000.ogg';
  static const String henesys      = 'audio/00102000.ogg';
  static const String kerningCity  = 'audio/00103000.ogg';
  static const String elNath       = 'audio/00200000.ogg';
  static const String orbis        = 'audio/00200001.ogg';
  static const String ludibrium    = 'audio/00300000.ogg';
  static const String aquaRoad     = 'audio/00500000.ogg';
  static const String koreanFolk   = 'audio/00600000.ogg';
  static const String muLung       = 'audio/00900000.ogg';
  static const String herbTown     = 'audio/01000000.ogg';

  static String? byMapId(int mapId) {
    if (mapId == 104000000 || mapId == 10300 || mapId == 10400) return lithHarbor;
    if (mapId >= 990000000) return 'audio/boss_zakum.wav';
    if (mapId >= 220000000) return 'audio/00300000.wav';
    if (mapId >= 201000000) return 'audio/00200001.wav';
    if (mapId >= 200000000) return 'audio/00200000.wav';
    if (mapId >= 103000000) return 'audio/00103000.wav';
    if (mapId >= 102000000) return 'audio/00100000.wav';
    if (mapId >= 101000000) return 'audio/00101000.wav';
    if (mapId >= 100000000) return 'audio/00102000.wav';
    if (mapId >= 10000) return 'audio/00001000.wav';
    return 'audio/00001000.wav';
  }
}

class SfxAssets {
  static const String levelUp = 'audio/sfx_levelup.wav';
  static const String hit     = 'audio/sfx_hit.wav';
  static const String pickup  = 'audio/sfx_pickup.wav';
  static const String mesos   = 'audio/sfx_meso.wav';
  static const String portal  = 'audio/sfx_portal.wav';
  static const String click   = 'audio/sfx_ui_click.wav';
  static const String chat    = 'audio/sfx_chat.wav';
  static const String dead    = 'audio/sfx_dead.wav';
  static const String revive  = 'audio/sfx_revive.wav';
}

class SpriteDirs {
  static const String player = 'sprites/player/';
  static const String mob    = 'sprites/mob/';
  static const String npc    = 'sprites/npc/';
  static const String portal = 'sprites/portal/';
  static const String item   = 'sprites/item/';
  static const String tiles  = 'images/tiles/';

  static String mobPath(int mobId) => '$mob$mobId.png';
  static String mobMovePath(int mobId) => '$mob${mobId}_move.png';
  static String npcPath(int npcId) => '$npc$npcId.png';
  static String playerStand() => '${player}stand.png';
  static String playerWalk() => '${player}walk.png';
  static String tileGrass() => '${tiles}grass.png';
  static String itemPath(int itemId) => '${item}${itemId}.png';
  static String tileDirt() => '${tiles}dirt.png';
}

class AudioManager {
  AudioManager._();
  static final AudioManager _instance = AudioManager._();
  factory AudioManager() => _instance;

  final AudioPlayer _bgm = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
  final AudioPlayer _sfx = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  double _bgmVolume = 0.6;
  double _sfxVolume = 0.8;
  bool _muted = false;
  String? _currentBgm;

  double get bgmVolume => _bgmVolume;
  double get sfxVolume => _sfxVolume;
  bool   get muted     => _muted;

  Future<void> playBgm(String asset) async {
    await playBgmAsset(asset);
  }

  Future<void> playBgmAsset(String primary) async {
    if (_muted) return;
    final fallbacks = <String>[];
    if (primary.endsWith('.wav')) {
      fallbacks.add(primary.replaceAll('.wav', '.mp3'));
    }
    fallbacks.add(primary);
    if (primary.endsWith('.mp3')) {
      fallbacks.add(primary.replaceAll('.mp3', '.wav'));
    }
    if (_currentBgm != null && fallbacks.contains(_currentBgm)) return;
    for (final path in fallbacks) {
      try {
        await _bgm.setVolume(_bgmVolume);
        await _bgm.play(AssetSource(path));
        _currentBgm = path;
        return;
      } catch (_) {}
    }
  }

  Future<void> stopBgm() async {
    try {
      await _bgm.stop();
      _currentBgm = null;
    } catch (_) {}
  }

  Future<void> playSfx(String asset) async {
    if (_muted) return;
    try {
      await _sfx.setVolume(_sfxVolume);
      await _sfx.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> setBgmVolume(double v) async {
    _bgmVolume = v.clamp(0.0, 1.0);
    await _bgm.setVolume(_bgmVolume);
  }

  Future<void> setSfxVolume(double v) async {
    _sfxVolume = v.clamp(0.0, 1.0);
    await _sfx.setVolume(_sfxVolume);
  }

  Future<void> toggleMute() async {
    _muted = !_muted;
    if (_muted) {
      await _bgm.pause();
    } else {
      await _bgm.resume();
    }
  }

  void dispose() {
    _bgm.dispose();
    _sfx.dispose();
  }
}

class GameConstants {
  static const int maxLevel = 200;
  static const int maxCharacterSlots = 6;
  static const int maxInventorySize = 96;
  static const int maxMesos = 999999999;
  static const int defaultStartHp = 50;
  static const int defaultStartMp = 50;
  static const int defaultStartStr = 12;
  static const int defaultStartDex = 5;
  static const int defaultStartInt = 4;
  static const int defaultStartLuk = 4;
  static const int defaultLevelUpAp = 5;
  static const int defaultLevelUpSp = 3;
  static const int accountGenderUnset = 10;

  static int expRequired(int level) {
    final lv = level < 1 ? 1 : level;
    return 10 + lv * lv * 8;
  }

  static int expRemaining(int currentLevel, int currentExp) {
    final need = expRequired(currentLevel);
    final rest = need - currentExp;
    return rest < 0 ? 0 : rest;
  }

  static double expPercent(int level, int exp) {
    final need = expRequired(level);
    if (need <= 0) return 0;
    final pct = (exp / need) * 100.0;
    return pct.clamp(0.0, 100.0);
  }
}

class JobInfo {
  final int id;
  final String name;
  final String primaryStat;
  final String secondaryStat;
  final double critMultiplier;

  const JobInfo({
    required this.id,
    required this.name,
    required this.primaryStat,
    required this.secondaryStat,
    required this.critMultiplier,
  });

  static const JobInfo beginner = JobInfo(
    id: 0, name: '新手', primaryStat: 'STR', secondaryStat: 'DEX', critMultiplier: 1.5,
  );
  static const JobInfo warrior = JobInfo(
    id: 1, name: '战士', primaryStat: 'STR', secondaryStat: 'DEX', critMultiplier: 1.5,
  );
  static const JobInfo magician = JobInfo(
    id: 2, name: '法师', primaryStat: 'INT', secondaryStat: 'LUK', critMultiplier: 1.5,
  );
  static const JobInfo bowman = JobInfo(
    id: 3, name: '弓箭手', primaryStat: 'DEX', secondaryStat: 'STR', critMultiplier: 1.6,
  );
  static const JobInfo thief = JobInfo(
    id: 4, name: '飞侠', primaryStat: 'LUK', secondaryStat: 'DEX', critMultiplier: 2.0,
  );
  static const JobInfo pirate = JobInfo(
    id: 5, name: '海盗', primaryStat: 'STR', secondaryStat: 'DEX', critMultiplier: 1.6,
  );

  static const List<JobInfo> all = [beginner, warrior, magician, bowman, thief, pirate];

  static JobInfo byId(int id) => all.firstWhere((j) => j.id == id, orElse: () => beginner);
}
