class GameState {
  double posX;
  double posY;
  int level;
  int exp;
  double expProgress;
  int hp;
  int maxHp;
  int mp;
  int maxMp;
  int str;
  int dex;
  int intl;
  int luk;
  int ap;
  int sp;
  int mesos;
  String characterName;
  String className;
  int mapId;
  String? mapName;
  double hpPercent;
  double mpPercent;
  double criticalRate;
  double hitRate;

  GameState({
    this.posX = 0.0,
    this.posY = 0.0,
    this.level = 1,
    this.exp = 0,
    this.expProgress = 0.0,
    this.hp = 50,
    this.maxHp = 50,
    this.mp = 5,
    this.maxMp = 5,
    this.str = 12,
    this.dex = 5,
    this.intl = 4,
    this.luk = 4,
    this.ap = 0,
    this.sp = 0,
    this.mesos = 0,
    this.characterName = '',
    this.className = '新手',
    this.mapId = 1,
    this.mapName,
    this.hpPercent = 100.0,
    this.mpPercent = 100.0,
    this.criticalRate = 5.0,
    this.hitRate = 95.0,
  });

  factory GameState.fromJson(Map<String, dynamic> json) {
    final character = json['character'] as Map<String, dynamic>? ?? {};
    final state = json['state'] as Map<String, dynamic>? ?? {};
    final map = json['map'] as Map<String, dynamic>? ?? {};

    return GameState(
      posX: ((character['position_x'] ?? 0) as num).toDouble(),
      posY: ((character['position_y'] ?? 0) as num).toDouble(),
      level: (character['level'] ?? 1) as int,
      exp: (character['experience'] ?? character['exp'] ?? 0) as int,
      expProgress: ((state['exp_progress'] ?? 0.0) as num).toDouble(),
      hp: (character['hp'] ?? 50) as int,
      maxHp: (character['max_hp'] ?? 50) as int,
      mp: (character['mp'] ?? 5) as int,
      maxMp: (character['max_mp'] ?? 5) as int,
      str: (character['str'] ?? 12) as int,
      dex: (character['dex'] ?? 5) as int,
      intl: (character['int'] ?? 4) as int,
      luk: (character['luk'] ?? 4) as int,
      ap: (character['ability_points'] ?? character['ability_point'] ?? 0) as int,
      sp: (character['skill_points'] ?? character['skill_point'] ?? 0) as int,
      mesos: (character['mesos'] ?? 0) as int,
      characterName: (character['name'] ?? '') as String,
      className: (state['class_name'] ?? '新手') as String,
      mapId: (map['id'] ?? character['map_id'] ?? 1) as int,
      mapName: (map['name'] as String?) ?? '',
      hpPercent: ((state['hp_percentage'] ?? 100.0) as num).toDouble(),
      mpPercent: ((state['mp_percentage'] ?? 100.0) as num).toDouble(),
      criticalRate: ((state['critical_rate'] ?? 5.0) as num).toDouble(),
      hitRate: ((state['hit_rate'] ?? 95.0) as num).toDouble(),
    );
  }

  void updateFromJson(Map<String, dynamic> json) {
    if (json['level'] != null) level = json['level'] as int;
    if (json['experience'] != null) exp = json['experience'] as int;
    if (json['hp'] != null) hp = json['hp'] as int;
    if (json['max_hp'] != null) maxHp = json['max_hp'] as int;
    if (json['mp'] != null) mp = json['mp'] as int;
    if (json['max_mp'] != null) maxMp = json['max_mp'] as int;
    if (json['position_x'] != null) {
      posX = ((json['position_x'] as num)).toDouble();
    }
    if (json['position_y'] != null) {
      posY = ((json['position_y'] as num)).toDouble();
    }
    if (json['str'] != null) str = json['str'] as int;
    if (json['dex'] != null) dex = json['dex'] as int;
    if (json['int'] != null) intl = json['int'] as int;
    if (json['luk'] != null) luk = json['luk'] as int;
    if (json['ability_points'] != null) ap = json['ability_points'] as int;
    if (json['mesos'] != null) mesos = json['mesos'] as int;

    hpPercent = maxHp > 0 ? (hp / maxHp * 100) : 0;
    mpPercent = maxMp > 0 ? (mp / maxMp * 100) : 0;
  }
}
