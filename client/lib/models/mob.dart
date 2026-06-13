import 'package:flutter/foundation.dart';

enum MobStatus { idle, moving, attacking, hit, dead }

class Mob {
  final int id;
  final int mobId;
  final String name;
  final int level;
  int hp;
  int maxHp;
  final int attack;
  final int defense;
  final int expReward;
  final int mesoReward;
  double posX;
  double posY;
  MobStatus status;
  final int speed;
  final double attackRange;
  final int attackCooldown;
  DateTime? _lastAttack;
  final String sprite;

  Mob({
    required this.id,
    required this.mobId,
    required this.name,
    required this.level,
    required this.hp,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.expReward,
    required this.mesoReward,
    required this.posX,
    required this.posY,
    this.status = MobStatus.idle,
    this.speed = 2,
    this.attackRange = 50.0,
    this.attackCooldown = 1500,
    this.sprite = '',
  });

  bool canAttack() {
    if (_lastAttack == null) return true;
    return DateTime.now().difference(_lastAttack!).inMilliseconds >= attackCooldown;
  }

  void markAttacked() {
    _lastAttack = DateTime.now();
  }

  double get hpPercent => maxHp > 0 ? hp / maxHp * 100 : 0;
  bool get isAlive => hp > 0;

  factory Mob.fromJson(Map<String, dynamic> json) {
    return Mob(
      id: (json['id'] ?? json['mob_id'] ?? 0) as int,
      mobId: (json['mob_id'] ?? json['id'] ?? 0) as int,
      name: (json['name'] ?? 'Unknown') as String,
      level: (json['level'] ?? 1) as int,
      hp: (json['hp'] ?? json['max_hp'] ?? 50) as int,
      maxHp: (json['max_hp'] ?? json['hp'] ?? 50) as int,
      attack: (json['attack'] ?? 5) as int,
      defense: (json['defense'] ?? 0) as int,
      expReward: (json['exp_reward'] ?? json['exp'] ?? 5) as int,
      mesoReward: (json['meso_reward'] ?? json['mesos'] ?? 5) as int,
      posX: ((json['position_x'] ?? json['x'] ?? 0) as num).toDouble(),
      posY: ((json['position_y'] ?? json['y'] ?? 0) as num).toDouble(),
      speed: (json['speed'] ?? 2) as int,
      attackRange: ((json['attack_range'] ?? 50.0) as num).toDouble(),
      attackCooldown: (json['attack_cooldown'] ?? 1500) as int,
      sprite: (json['sprite'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mob_id': mobId,
      'name': name,
      'level': level,
      'hp': hp,
      'max_hp': maxHp,
      'attack': attack,
      'defense': defense,
      'exp_reward': expReward,
      'meso_reward': mesoReward,
      'position_x': posX,
      'position_y': posY,
      'status': status.name,
      'hp_percent': hpPercent,
      'is_alive': isAlive,
    };
  }
}

class MobTemplate {
  final int mobId;
  final String name;
  final int level;
  final int maxHp;
  final int attack;
  final int defense;
  final int expReward;
  final int mesoReward;
  final double attackRange;
  final int attackCooldown;

  MobTemplate({
    required this.mobId,
    required this.name,
    required this.level,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.expReward,
    required this.mesoReward,
    this.attackRange = 50.0,
    this.attackCooldown = 1500,
  });
}

class MobCatalog {
  static final List<MobTemplate> templates = [
    MobTemplate(
      mobId: 100100,
      name: '蜗牛',
      level: 1,
      maxHp: 15,
      attack: 5,
      defense: 0,
      expReward: 8,
      mesoReward: 3,
    ),
    MobTemplate(
      mobId: 100101,
      name: '蓝蜗牛',
      level: 2,
      maxHp: 25,
      attack: 8,
      defense: 1,
      expReward: 12,
      mesoReward: 5,
    ),
    MobTemplate(
      mobId: 100200,
      name: '蘑菇怪',
      level: 3,
      maxHp: 40,
      attack: 12,
      defense: 2,
      expReward: 20,
      mesoReward: 8,
    ),
    MobTemplate(
      mobId: 110100,
      name: '野猪',
      level: 5,
      maxHp: 80,
      attack: 20,
      defense: 5,
      expReward: 40,
      mesoReward: 15,
    ),
    MobTemplate(
      mobId: 120100,
      name: '史莱姆',
      level: 4,
      maxHp: 50,
      attack: 15,
      defense: 3,
      expReward: 25,
      mesoReward: 10,
    ),
    MobTemplate(
      mobId: 130100,
      name: '蝙蝠',
      level: 7,
      maxHp: 60,
      attack: 25,
      defense: 2,
      expReward: 50,
      mesoReward: 18,
    ),
  ];

  static MobTemplate? getTemplate(int mobId) {
    try {
      return templates.firstWhere((t) => t.mobId == mobId);
    } catch (_) {
      return null;
    }
  }

  static Mob createMob(int mobId, {required int spawnId, double x = 0, double y = 0}) {
    final template = getTemplate(mobId);
    if (template == null) {
      return Mob(
        id: spawnId,
        mobId: mobId,
        name: 'Unknown',
        level: 1,
        hp: 10,
        maxHp: 10,
        attack: 5,
        defense: 0,
        expReward: 5,
        mesoReward: 1,
        posX: x,
        posY: y,
      );
    }
    return Mob(
      id: spawnId,
      mobId: template.mobId,
      name: template.name,
      level: template.level,
      hp: template.maxHp,
      maxHp: template.maxHp,
      attack: template.attack,
      defense: template.defense,
      expReward: template.expReward,
      mesoReward: template.mesoReward,
      posX: x,
      posY: y,
      attackRange: template.attackRange,
      attackCooldown: template.attackCooldown,
    );
  }
}
