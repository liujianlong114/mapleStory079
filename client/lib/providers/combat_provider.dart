import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/mob.dart';
import '../models/skill.dart';
import 'game_provider.dart';

enum CombatStatus { idle, playerTurn, enemyTurn, victory, defeat, running }

class CombatResult {
  final bool playerWon;
  final int expGained;
  final int mesosGained;
  final List<String> log;

  const CombatResult({
    required this.playerWon,
    required this.expGained,
    required this.mesosGained,
    required this.log,
  });
}

class CombatProvider with ChangeNotifier {
  final GameProvider game;
  final Random _random = Random();

  CombatStatus _status = CombatStatus.idle;
  Mob? _target;
  final List<Mob> _mobs = [];
  final List<String> _combatLog = [];
  int _turnCount = 0;
  bool _autoFight = false;

  CombatStatus get status => _status;
  Mob? get target => _target;
  List<Mob> get mobs => List.unmodifiable(_mobs);
  List<String> get combatLog => List.unmodifiable(_combatLog);
  int get turnCount => _turnCount;
  bool get autoFight => _autoFight;
  bool get inCombat => _status == CombatStatus.running || _status == CombatStatus.playerTurn;

  CombatProvider(this.game);

  void setAutoFight(bool value) {
    _autoFight = value;
    notifyListeners();
  }

  void clearCombat() {
    _target = null;
    _mobs.clear();
    _combatLog.clear();
    _turnCount = 0;
    _status = CombatStatus.idle;
    notifyListeners();
  }

  void spawnMobs({int count = 3, int? mapId}) {
    _mobs.clear();
    final templateIds = MobCatalog.templates.map((t) => t.mobId).toList();
    for (int i = 0; i < count; i++) {
      final mobId = templateIds[_random.nextInt(templateIds.length)];
      final mob = MobCatalog.createMob(
        mobId,
        spawnId: DateTime.now().millisecondsSinceEpoch + i,
        x: 200 + i * 80.0,
        y: 100 + _random.nextDouble() * 50,
      );
      _mobs.add(mob);
    }
    if (_mobs.isNotEmpty) {
      _target = _mobs.first;
    }
    notifyListeners();
  }

  void selectTarget(Mob mob) {
    _target = mob;
    notifyListeners();
  }

  void startCombat({Mob? initialMob}) {
    if (game.currentCharacter == null) return;
    _combatLog.clear();
    _turnCount = 0;
    if (initialMob != null) {
      _mobs.clear();
      _mobs.add(initialMob);
      _target = initialMob;
    }
    _status = CombatStatus.playerTurn;
    _addLog('🎮 战斗开始!');
    notifyListeners();
  }

  Future<void> playerAttack({Skill? skill}) async {
    if (_status != CombatStatus.playerTurn) return;
    if (_target == null || !_target!.isAlive) {
      _findNewTarget();
    }
    if (_target == null) return;

    final char = game.currentCharacter;
    if (char == null) return;

    if (skill != null) {
      if (game.mp < skill.mpCost) {
        _addLog('❌ MP不足, 无法使用 ${skill.name}');
        notifyListeners();
        return;
      }
      game.restoreHpMp(0, -skill.mpCost);
    }

    final baseDamage = (char.str * 1.2 + char.dex * 0.3).toInt();
    final skillMult = skill?.damageAtCurrentLevel ?? 1.0;
    final isCritical = _random.nextDouble() < (game.luk / 200.0 + 0.05);
    var damage = (baseDamage * skillMult).toInt();

    if (isCritical) {
      damage = (damage * 1.5).toInt();
      _addLog('⚔️ ${skill?.name ?? "普通攻击"} 暴击! 对 ${_target!.name} 造成 $damage 点伤害');
    } else {
      _addLog('⚔️ ${skill?.name ?? "普通攻击"} 对 ${_target!.name} 造成 $damage 点伤害');
    }

    _target!.hp -= damage;
    if (_target!.hp <= 0) {
      _target!.status = MobStatus.dead;
      _addLog('💀 ${_target!.name} 被击败!');
      final exp = _target!.expReward;
      final mesos = _target!.mesoReward;
      await game.gainExperience(exp);
      _addLog('💰 获得 $exp 经验, $mesos 金币');
      _findNewTarget();
    }

    _turnCount++;
    if (_mobs.every((m) => !m.isAlive)) {
      _status = CombatStatus.victory;
      _addLog('🎉 战斗胜利!');
      notifyListeners();
      return;
    }
    _status = CombatStatus.enemyTurn;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    await _enemyTurn();
  }

  Future<int> attackMob(int characterId, int attackerStr, {Skill? skill}) async {
    final char = game.currentCharacter;
    if (char == null) {
      _addLog('⚠️ 尚未选择角色');
      return 0;
    }

    final skillMult = skill?.damageAtCurrentLevel ?? 1.0;
    final isCritical = _random.nextDouble() < (game.luk / 200.0 + 0.05);
    final base = (attackerStr * 1.2 + char.dex * 0.3).toInt();
    final damage = isCritical ? (base * 1.5).toInt() : base;
    final finalDamage = (damage * skillMult).toInt();

    if (skill != null) {
      _addLog('🔮 $skill.name 造成 $finalDamage${isCritical ? ' (暴击!)' : ''} 点伤害');
    } else {
      _addLog('⚔️ 普通攻击造成 $finalDamage${isCritical ? ' (暴击!)' : ''} 点伤害');
    }

    if (_mobs.isNotEmpty) {
      final target = _mobs.firstWhere((m) => m.isAlive, orElse: () => _mobs.first);
      target.hp -= finalDamage;
      if (target.hp <= 0) {
        target.status = MobStatus.dead;
        _addLog('💀 ${target.name} 被击败!');
        await game.gainExperience(target.expReward);
      }
    }

    _turnCount++;
    notifyListeners();
    return finalDamage;
  }

  Future<void> _enemyTurn() async {
    if (_status != CombatStatus.enemyTurn) return;
    if (game.currentCharacter == null) return;
    if (game.hp <= 0) {
      _status = CombatStatus.defeat;
      _addLog('💔 你被击败了...');
      notifyListeners();
      return;
    }

    for (final mob in _mobs) {
      if (!mob.isAlive) continue;
      if (!mob.canAttack()) continue;

      final mobAttack = mob.attack;
      final defense = (game.str * 0.2).toInt();
      final miss = _random.nextDouble() < 0.15;
      if (miss) {
        _addLog('🌀 ${mob.name} 的攻击落空了!');
        continue;
      }
      final damage = (mobAttack - defense).clamp(1, mobAttack * 2).toInt();
      game.restoreHpMp(-damage, 0);
      mob.markAttacked();
      _addLog('🔥 ${mob.name} 对你造成 $damage 点伤害');

      if (game.hp <= 0) {
        _status = CombatStatus.defeat;
        _addLog('💔 你被击败了...');
        notifyListeners();
        return;
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }

    _status = CombatStatus.playerTurn;
    notifyListeners();
  }

  void _findNewTarget() {
    try {
      _target = _mobs.firstWhere((m) => m.isAlive);
    } catch (_) {
      _target = null;
    }
  }

  void _addLog(String message) {
    _combatLog.add('[$_turnCount] $message');
    if (_combatLog.length > 50) {
      _combatLog.removeAt(0);
    }
  }

  Future<CombatResult?> fightMob(Mob mob) async {
    if (game.currentCharacter == null) return null;
    startCombat(initialMob: mob);

    final log = <String>[];
    int round = 0;
    while (game.hp > 0 && _mobs.any((m) => m.isAlive) && round < 100) {
      await playerAttack();
      round++;
      log.add('回合 $round');
      await Future.delayed(const Duration(milliseconds: 200));
    }

    final won = game.hp > 0 && !_mobs.any((m) => m.isAlive);
    return CombatResult(
      playerWon: won,
      expGained: won ? mob.expReward : 0,
      mesosGained: won ? mob.mesoReward : 0,
      log: log,
    );
  }
}
