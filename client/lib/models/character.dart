class Character {
  final int id;
  final int accountId;
  final String name;
  final int characterClass;
  final int gender;
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

  Character({
    required this.id,
    required this.accountId,
    required this.name,
    required this.characterClass,
    required this.gender,
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
  });

  factory Character.fromJson(Map<String, dynamic> json) =>
      Character.fromMap(json);

  factory Character.fromMap(Map<String, dynamic> json) {
    return Character(
      id: (json['id'] ?? 0) as int,
      accountId: (json['account_id'] ?? 0) as int,
      name: (json['name'] ?? '') as String,
      characterClass: (json['class'] ?? json['character_class'] ?? 0) as int,
      gender: (json['gender'] ?? 0) as int,
      level: (json['level'] ?? 1) as int,
      experience: (json['experience'] ?? json['exp'] ?? 0) as int,
      mapId: (json['map_id'] ?? 10000) as int,
      positionX: (json['position_x'] ?? 0) as int,
      positionY: (json['position_y'] ?? 0) as int,
      hp: (json['hp'] ?? 100) as int,
      maxHp: (json['max_hp'] ?? 100) as int,
      mp: (json['mp'] ?? 50) as int,
      maxMp: (json['max_mp'] ?? 50) as int,
      str: (json['str'] ?? 4) as int,
      dex: (json['dex'] ?? 4) as int,
      intl: (json['int'] ?? 4) as int,
      luk: (json['luk'] ?? 4) as int,
      mesos: (json['mesos'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_id': accountId,
      'name': name,
      'class': characterClass,
      'gender': gender,
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
    };
  }

  String get className {
    switch (characterClass) {
      case 0:
        return 'Beginner';
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
