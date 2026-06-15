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
/// 所有资源在 assets/audio/（bgm 子目录用于精确地图映射），
/// 实际格式为 .wav（079 Sound.wz / Bgm00 提取产物）。
class BgmAssets {
  static const String login = 'audio/title.mp3';
  static const String loginWav = 'audio/title.wav';
  static const String title = loginWav;
  static const String titleWav = loginWav;
  static const String charSelect = loginWav;
  static const String charSelectWav = loginWav;
  static const String mapleIsland  = 'audio/00001000.wav';
  static const String lithHarbor   = 'audio/00002000.wav';
  static const String nautilus     = 'audio/00002001.wav';
  static const String perion       = 'audio/00100000.wav';
  static const String ellinia      = 'audio/00101000.wav';
  static const String henesys      = 'audio/00102000.wav';
  static const String kerningCity  = 'audio/00103000.wav';
  static const String elNath       = 'audio/00200000.wav';
  static const String orbis        = 'audio/00200001.wav';
  static const String ludibrium    = 'audio/00300000.wav';
  static const String aquaRoad     = 'audio/00500000.wav';
  static const String koreanFolk   = 'audio/00600000.wav';
  static const String muLung       = 'audio/00900000.wav';
  static const String herbTown     = 'audio/01000000.wav';

  /// 返回指定 mapId 对应的 BGM 资源路径。
  /// 优先使用 assets/audio/bgm/{mapId}.wav（mapId 精确匹配），
  /// 其次按大区范围映射到 audio/ 下的通用 BGM 文件。
  /// 所有返回路径使用 .wav 扩展名（与 Sound.wz 提取结果一致）。
  static String? byMapId(int mapId) {
    const exactMapIds = {
      1000000: 'audio/bgm/1000000.wav',
      20000: 'audio/bgm/20000.wav',
      30000: 'audio/bgm/30000.wav',
      100000000: 'audio/bgm/100000000.wav',
      101000000: 'audio/bgm/101000000.wav',
    };
    if (exactMapIds.containsKey(mapId)) return exactMapIds[mapId]!;

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
  static String itemPath(int itemId) => '$item$itemId.png';
  static String tileDirt() => '${tiles}dirt.png';
}

class AudioManager {
  AudioManager._();
  static final AudioManager _instance = AudioManager._();
  factory AudioManager() => _instance;

  final AudioPlayer _bgm = AudioPlayer()..setReleaseMode(ReleaseMode.loop);

  /// UI 点击音效专用通道（短小，优先级高；可并行其他 SFX）
  final AudioPlayer _uiSfx = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  /// 通用 SFX 通道池（避免新音效立即被挤掉：取空闲或最旧复用）
  static const int _sfxPoolSize = 4;
  final List<AudioPlayer> _sfxPool = List.generate(
    _sfxPoolSize,
    (_) => AudioPlayer()..setReleaseMode(ReleaseMode.stop),
  );
  int _sfxCursor = 0;

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
    await stopBgm();
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

  /// UI 按钮点击专用（079 BtMouseClick）。短、低延迟，与战斗 SFX 互不干扰
  Future<void> playUiClick() async {
    if (_muted) return;
    try {
      await _uiSfx.setVolume(_sfxVolume);
      await _uiSfx.play(AssetSource(SfxAssets.click));
    } catch (_) {}
  }

  /// 通用 SFX（战斗/拾取/升级等），用轮换池并行播放
  Future<void> playSfx(String asset) async {
    if (_muted) return;
    try {
      final player = _sfxPool[_sfxCursor % _sfxPoolSize];
      _sfxCursor = (_sfxCursor + 1) % _sfxPoolSize;
      await player.setVolume(_sfxVolume);
      await player.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> setBgmVolume(double v) async {
    _bgmVolume = v.clamp(0.0, 1.0);
    await _bgm.setVolume(_bgmVolume);
  }

  Future<void> setSfxVolume(double v) async {
    _sfxVolume = v.clamp(0.0, 1.0);
    for (final p in _sfxPool) {
      try { await p.setVolume(_sfxVolume); } catch (_) {}
    }
    try { await _uiSfx.setVolume(_sfxVolume); } catch (_) {}
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
    _uiSfx.dispose();
    for (final p in _sfxPool) { p.dispose(); }
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
