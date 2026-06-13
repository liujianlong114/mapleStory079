class Skill {
  final int id;
  final String name;
  final String description;
  final int characterClass;
  final int requiredLevel;
  final int maxLevel;
  final int currentLevel;
  final int mpCost;
  final int cooldown;
  final double damageMultiplier;
  final double range;
  final String icon;
  final String type;

  const Skill({
    required this.id,
    required this.name,
    required this.description,
    required this.characterClass,
    required this.requiredLevel,
    required this.maxLevel,
    this.currentLevel = 0,
    required this.mpCost,
    required this.cooldown,
    required this.damageMultiplier,
    required this.range,
    this.icon = '',
    this.type = 'attack',
  });

  double get damageAtCurrentLevel => damageMultiplier * (1 + currentLevel * 0.2);
  bool get isUnlocked => currentLevel > 0;
  bool get isMaxed => currentLevel >= maxLevel;

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      characterClass: (json['class'] ?? json['character_class'] ?? 0) as int,
      requiredLevel: (json['required_level'] ?? 1) as int,
      maxLevel: (json['max_level'] ?? 1) as int,
      currentLevel: (json['current_level'] ?? json['level'] ?? 0) as int,
      mpCost: (json['mp_cost'] ?? json['mp'] ?? 0) as int,
      cooldown: (json['cooldown'] ?? 0) as int,
      damageMultiplier: ((json['damage_multiplier'] ?? json['damage'] ?? 1.0) as num).toDouble(),
      range: ((json['range'] ?? 60.0) as num).toDouble(),
      icon: (json['icon'] ?? '') as String,
      type: (json['type'] ?? 'attack') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'class': characterClass,
      'required_level': requiredLevel,
      'max_level': maxLevel,
      'current_level': currentLevel,
      'mp_cost': mpCost,
      'cooldown': cooldown,
      'damage_multiplier': damageMultiplier,
      'range': range,
      'type': type,
    };
  }

  Skill copyWith({
    int? id,
    String? name,
    String? description,
    int? characterClass,
    int? requiredLevel,
    int? maxLevel,
    int? currentLevel,
    int? mpCost,
    int? cooldown,
    double? damageMultiplier,
    double? range,
    String? icon,
    String? type,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      characterClass: characterClass ?? this.characterClass,
      requiredLevel: requiredLevel ?? this.requiredLevel,
      maxLevel: maxLevel ?? this.maxLevel,
      currentLevel: currentLevel ?? this.currentLevel,
      mpCost: mpCost ?? this.mpCost,
      cooldown: cooldown ?? this.cooldown,
      damageMultiplier: damageMultiplier ?? this.damageMultiplier,
      range: range ?? this.range,
      icon: icon ?? this.icon,
      type: type ?? this.type,
    );
  }
}

class SkillCatalog {
  static const List<Skill> allSkills = [
    // 新手
    Skill(
      id: 0,
      name: '蜗牛投掷',
      description: '投掷蜗牛壳造成少量伤害',
      characterClass: 0,
      requiredLevel: 1,
      maxLevel: 1,
      mpCost: 5,
      cooldown: 500,
      damageMultiplier: 1.0,
      range: 60.0,
      type: 'attack',
    ),
    // 战士技能
    Skill(
      id: 100,
      name: '强力攻击',
      description: '对单个敌人造成强力物理攻击',
      characterClass: 1,
      requiredLevel: 1,
      maxLevel: 20,
      mpCost: 8,
      cooldown: 300,
      damageMultiplier: 1.5,
      range: 60.0,
      type: 'attack',
    ),
    Skill(
      id: 101,
      name: '群体攻击',
      description: '对前方区域内多个敌人造成伤害',
      characterClass: 1,
      requiredLevel: 10,
      maxLevel: 20,
      mpCost: 20,
      cooldown: 800,
      damageMultiplier: 1.2,
      range: 80.0,
      type: 'aoe',
    ),
    // 法师技能
    Skill(
      id: 200,
      name: '魔法弹',
      description: '发射魔法弹对敌人造成魔法伤害',
      characterClass: 2,
      requiredLevel: 1,
      maxLevel: 20,
      mpCost: 10,
      cooldown: 400,
      damageMultiplier: 1.8,
      range: 120.0,
      type: 'magic',
    ),
    Skill(
      id: 201,
      name: '火球术',
      description: '召唤火球造成范围魔法伤害',
      characterClass: 2,
      requiredLevel: 15,
      maxLevel: 20,
      mpCost: 30,
      cooldown: 1200,
      damageMultiplier: 2.5,
      range: 100.0,
      type: 'magic',
    ),
    // 弓箭手
    Skill(
      id: 300,
      name: '精准射击',
      description: '发射箭矢精准命中敌人',
      characterClass: 3,
      requiredLevel: 1,
      maxLevel: 20,
      mpCost: 8,
      cooldown: 350,
      damageMultiplier: 1.4,
      range: 200.0,
      type: 'attack',
    ),
    Skill(
      id: 301,
      name: '爆炸箭',
      description: '发射爆炸箭对敌人造成范围伤害',
      characterClass: 3,
      requiredLevel: 15,
      maxLevel: 20,
      mpCost: 25,
      cooldown: 1000,
      damageMultiplier: 1.8,
      range: 180.0,
      type: 'aoe',
    ),
    // 飞侠
    Skill(
      id: 400,
      name: '双飞斩',
      description: '快速挥动武器对敌人造成两次伤害',
      characterClass: 4,
      requiredLevel: 1,
      maxLevel: 20,
      mpCost: 10,
      cooldown: 400,
      damageMultiplier: 1.3,
      range: 60.0,
      type: 'attack',
    ),
    Skill(
      id: 401,
      name: '幸运骰子',
      description: '掷出骰子，根据点数获得额外暴击',
      characterClass: 4,
      requiredLevel: 15,
      maxLevel: 20,
      mpCost: 20,
      cooldown: 800,
      damageMultiplier: 2.0,
      range: 80.0,
      type: 'attack',
    ),
    // 海盗
    Skill(
      id: 500,
      name: '快速射击',
      description: '快速发射多发子弹',
      characterClass: 5,
      requiredLevel: 1,
      maxLevel: 20,
      mpCost: 12,
      cooldown: 300,
      damageMultiplier: 1.2,
      range: 150.0,
      type: 'attack',
    ),
  ];

  static List<Skill> skillsForClass(int characterClass) {
    return allSkills.where((s) => s.characterClass == characterClass).toList();
  }
}
