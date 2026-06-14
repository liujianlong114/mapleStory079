import 'package:audioplayers/audioplayers.dart';

/// ====== BGM 背景音乐资源 ======
class BgmAssets {
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

  /// 根据地图 ID 返回对应 BGM；找不到时返回 null（客户端可跳过播放）。
  /// 服务端 pkg/utils/constants.go 中 MapXX 常量与此处分支保持对齐。
  static String? byMapId(int mapId) {
    if (mapId >= 990000000) return 'audio/boss_zakum.ogg';     // BOSS 区
    if (mapId >= 220000000) return ludibrium;                    // 玩具城
    if (mapId >= 201000000) return orbis;                        // 天空之城
    if (mapId >= 200000000) return elNath;                        // 冰峰雪域
    if (mapId >= 103000000) return kerningCity;                   // 废弃都市
    if (mapId >= 102000000) return perion;                        // 勇士部落
    if (mapId >= 101000000) return ellinia;                       // 魔法密林
    if (mapId >= 100000000) return henesys;                       // 射手村
    if (mapId >= 10000) return mapleIsland;                       // 彩虹村/新手区
    return null;
  }
}

/// ====== SFX 系统音效 ======
class SfxAssets {
  static const String levelUp = 'audio/sfx_levelup.ogg';
  static const String hit     = 'audio/sfx_hit.ogg';
  static const String pickup  = 'audio/sfx_pickup.ogg';
  static const String mesos   = 'audio/sfx_meso.ogg';
  static const String portal  = 'audio/sfx_portal.ogg';
  static const String click   = 'audio/sfx_ui_click.ogg';
  static const String chat    = 'audio/sfx_chat.ogg';
  static const String dead    = 'audio/sfx_dead.ogg';
  static const String revive  = 'audio/sfx_revive.ogg';
}

/// ====== Sprite 精灵资源路径前缀 ======
class SpriteDirs {
  static const String player = 'sprites/player/';
  static const String mob    = 'sprites/mob/';
  static const String npc    = 'sprites/npc/';
  static const String portal = 'sprites/portal/';
  static const String item   = 'sprites/item/';
}

/// ====== 单例音频播放器 ======
class AudioManager {
  AudioManager._();
  static final AudioManager _instance = AudioManager._();
  factory AudioManager() => _instance;

  final AudioPlayer _bgm = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
  final AudioPlayer _sfx = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  double _bgmVolume = 0.6;
  double _sfxVolume = 0.8;
  bool _muted = false;

  double get bgmVolume => _bgmVolume;
  double get sfxVolume => _sfxVolume;
  bool   get muted     => _muted;

  Future<void> playBgm(String asset) async {
    if (_muted) return;
    try {
      await _bgm.setVolume(_bgmVolume);
      await _bgm.play(AssetSource(asset));
    } catch (_) {
      // 资源不存在时静默失败（开发期可接受）
    }
  }

  Future<void> stopBgm() async {
    try { await _bgm.stop(); } catch (_) {}
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

/// ====== 游戏数值常量（与服务端 pkg/utils/constants.go 对齐） ======
class GameConstants {
  static const int maxLevel = 200;
  static const int maxCharacterSlots = 6;
  static const int maxInventorySize = 96;
  static const int maxMesos = 999999999;
  static const int defaultStartHp = 50;
  static const int defaultStartMp = 50;
  static const int defaultStartStr = 10;
  static const int defaultStartDex = 4;
  static const int defaultStartInt = 4;
  static const int defaultStartLuk = 4;
  static const int defaultLevelUpAp = 5;
  static const int defaultLevelUpSp = 3;

  /// 升级经验公式：10 + level^2 * 8
  static int expRequired(int level) {
    final lv = level < 1 ? 1 : level;
    return 10 + lv * lv * 8;
  }

  /// 当前经验 → 到下一级还需多少
  static int expRemaining(int currentLevel, int currentExp) {
    final need = expRequired(currentLevel);
    final rest = need - currentExp;
    return rest < 0 ? 0 : rest;
  }
}

/// ====== 职业信息（客户端 UI 用） ======
class JobInfo {
  final int id;
  final String name;
  final String primaryStat;   // 主属性（STR/DEX/INT/LUK）
  final String secondaryStat; // 副属性
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
