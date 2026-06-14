class Character {
  final int id;
  final int accountId;
  final String name;
  final int characterClass;
  final int gender;
  final int face;
  final int hair;
  final int skin;
  final int level;
  final int experience;
  final int mapId;
  final int positionX;
  final int positionY;
  final int hp;
  final int maxHp;
  final int mp;
  final int maxMp;
  final int str;
  final int dex;
  final int intl;
  final int luk;
  final int mesos;
  final int top;
  final int bottom;
  final int shoes;
  final int weapon;

  Character({
    required this.id,
    required this.accountId,
    required this.name,
    required this.characterClass,
    required this.gender,
    this.face = 20100,
    this.hair = 30000,
    this.skin = 0,
    required this.level,
    required this.experience,
    required this.mapId,
    required this.positionX,
    required this.positionY,
    required this.hp,
    required this.maxHp,
    required this.mp,
    required this.maxMp,
    required this.str,
    required this.dex,
    required this.intl,
    required this.luk,
    required this.mesos,
    this.top = 0,
    this.bottom = 0,
    this.shoes = 0,
    this.weapon = 0,
  });

  factory Character.fromJson(Map<String, dynamic> json) =>
      Character.fromMap(json);

  factory Character.fromMap(Map<String, dynamic> json) {
    int asInt(dynamic v, [int d = 0]) {
      if (v == null) return d;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? d;
    }
    return Character(
      id: asInt(json['id']),
      accountId: asInt(json['account_id']),
      name: (json['name'] ?? '') as String,
      characterClass: asInt(json['class'] ?? json['character_class']),
      gender: asInt(json['gender']),
      face: asInt(json['face'], 20100),
      hair: asInt(json['hair'], 30000),
      skin: asInt(json['skin']),
      level: asInt(json['level'], 1),
      experience: asInt(json['experience'] ?? json['exp']),
      mapId: asInt(json['map_id'], 10000),
      positionX: asInt(json['position_x']),
      positionY: asInt(json['position_y']),
      hp: asInt(json['hp'], 50),
      maxHp: asInt(json['max_hp'], 50),
      mp: asInt(json['mp'], 50),
      maxMp: asInt(json['max_mp'], 50),
      str: asInt(json['str'], 12),
      dex: asInt(json['dex'], 5),
      intl: asInt(json['int'], 4),
      luk: asInt(json['luk'], 4),
      mesos: asInt(json['mesos']),
      top: asInt(json['top']),
      bottom: asInt(json['bottom']),
      shoes: asInt(json['shoes']),
      weapon: asInt(json['weapon']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_id': accountId,
      'name': name,
      'class': characterClass,
      'gender': gender,
      'face': face,
      'hair': hair,
      'skin': skin,
      'level': level,
      'experience': experience,
      'map_id': mapId,
      'position_x': positionX,
      'position_y': positionY,
      'hp': hp,
      'max_hp': maxHp,
      'mp': mp,
      'max_mp': maxMp,
      'str': str,
      'dex': dex,
      'int': intl,
      'luk': luk,
      'mesos': mesos,
      'top': top,
      'bottom': bottom,
      'shoes': shoes,
      'weapon': weapon,
    };
  }

  String get className {
    if (characterClass == 0) return '新手';
    switch (characterClass) {
      case 100:
        return '战士';
      case 200:
        return '法师';
      case 300:
        return '弓箭手';
      case 400:
        return '飞侠';
      case 500:
        return '海盗';
      case 1:
        return 'Warrior';
      case 2:
        return 'Magician';
      case 3:
        return 'Bowman';
      case 4:
        return 'Thief';
      case 5:
        return 'Pirate';
      default:
        return 'Unknown';
    }
  }

  String get genderName {
    return gender == 0 ? 'Male' : 'Female';
  }
}
