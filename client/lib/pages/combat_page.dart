// =============================================================
// DEPRECATED: 此文件已被 `lib/features/combat/combat_page.dart` 替代。
// 保留用于向后兼容，请勿在新代码中引用。
// =============================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mob.dart';
import '../providers/game_provider.dart';

class CombatPage extends StatefulWidget {
  const CombatPage({super.key});

  @override
  State<CombatPage> createState() => _CombatPageState();
}

class _CombatPageState extends State<CombatPage> {
  Mob? _currentMob;
  final List<String> _battleLog = [];
  bool _inCombat = false;
  Timer? _mobAttackTimer;

  final List<Mob> _availableMobs = [
    Mob(
      id: 1,
      mobId: 100100,
      name: '绿蜗牛',
      level: 1,
      hp: 50,
      maxHp: 50,
      attack: 5,
      defense: 2,
      expReward: 15,
      mesoReward: 10,
      posX: 0,
      posY: 0,
    ),
    Mob(
      id: 2,
      mobId: 100101,
      name: '蓝蜗牛',
      level: 3,
      hp: 80,
      maxHp: 80,
      attack: 8,
      defense: 3,
      expReward: 25,
      mesoReward: 20,
      posX: 0,
      posY: 0,
    ),
    Mob(
      id: 3,
      mobId: 110100,
      name: '野猪',
      level: 5,
      hp: 120,
      maxHp: 120,
      attack: 15,
      defense: 5,
      expReward: 50,
      mesoReward: 50,
      posX: 0,
      posY: 0,
    ),
    Mob(
      id: 4,
      mobId: 110200,
      name: '火野猪',
      level: 10,
      hp: 200,
      maxHp: 200,
      attack: 25,
      defense: 8,
      expReward: 100,
      mesoReward: 100,
      posX: 0,
      posY: 0,
    ),
    Mob(
      id: 5,
      mobId: 900100,
      name: '蘑菇王',
      level: 15,
      hp: 500,
      maxHp: 500,
      attack: 40,
      defense: 15,
      expReward: 300,
      mesoReward: 500,
      posX: 0,
      posY: 0,
    ),
  ];

  void _log(String message) {
    setState(() {
      _battleLog.insert(0, '[${_timeString}] $message');
      if (_battleLog.length > 20) _battleLog.removeLast();
    });
  }

  String get _timeString {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  void _startCombat(Mob mob) {
    setState(() {
      _currentMob = Mob(
        id: mob.id,
        mobId: mob.mobId,
        name: mob.name,
        level: mob.level,
        hp: mob.hp,
        maxHp: mob.maxHp,
        attack: mob.attack,
        defense: mob.defense,
        expReward: mob.expReward,
        mesoReward: mob.mesoReward,
        posX: mob.posX,
        posY: mob.posY,
      );
      _inCombat = true;
      _battleLog.clear();
    });
    _log('⚔️ 遭遇了 ${mob.name}!');
    _startMobAttacks();
  }

  void _startMobAttacks() {
    _mobAttackTimer?.cancel();
    _mobAttackTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentMob == null || !_currentMob!.isAlive || !_inCombat) {
        timer.cancel();
        return;
      }
      if (mounted) {
        final game = context.read<GameProvider>();
        final damage = (_currentMob!.attack - game.str ~/ 4).clamp(1, 100);
        game.restoreHpMp(-damage, 0);
        _log('💥 ${_currentMob!.name} 对你造成了 $damage 点伤害！');
        if (game.hp <= 0) {
          _log('☠️ 你被击败了！');
          _endCombat();
        }
      }
    });
  }

  void _attackMob() {
    if (_currentMob == null || !_inCombat) return;
    final game = context.read<GameProvider>();
    final playerDamage = (game.str + game.dex ~/ 2) - _currentMob!.defense ~/ 2;
    final critChance = game.luk / 100;
    final isCrit = (DateTime.now().millisecondsSinceEpoch % 100) / 100 < critChance;
    final finalDamage = (isCrit ? playerDamage * 2 : playerDamage).clamp(1, 9999);
    setState(() {
      _currentMob!.hp = (_currentMob!.hp - finalDamage).clamp(0, _currentMob!.maxHp);
    });
    _log('${isCrit ? '💥 暴击!' : '⚔️'} 你对 ${_currentMob!.name} 造成了 $finalDamage 点伤害！');
    if (!_currentMob!.isAlive) {
      _log('🎉 击败了 ${_currentMob!.name}!');
      _log('💰 获得 ${_currentMob!.mesoReward} 金币，获得 ${_currentMob!.expReward} 经验！');
      game.gainExperience(_currentMob!.expReward);
      _endCombat();
    }
  }

  void _useSkill() {
    if (_currentMob == null || !_inCombat) return;
    final game = context.read<GameProvider>();
    if (game.mp < 10) {
      _log('❌ MP不足，无法使用技能！');
      return;
    }
    game.restoreHpMp(0, -10);
    final skillDamage = (game.intl * 3).clamp(1, 9999);
    setState(() {
      _currentMob!.hp = (_currentMob!.hp - skillDamage).clamp(0, _currentMob!.maxHp);
    });
    _log('✨ 释放技能，对 ${_currentMob!.name} 造成 $skillDamage 点伤害！');
    if (!_currentMob!.isAlive) {
      _log('🎉 击败了 ${_currentMob!.name}!');
      game.gainExperience(_currentMob!.expReward);
      _endCombat();
    }
  }

  void _flee() {
    if (!_inCombat) return;
    _log('🏃 你逃跑了...');
    _endCombat();
  }

  void _endCombat() {
    _mobAttackTimer?.cancel();
    setState(() {
      _inCombat = false;
    });
  }

  @override
  void dispose() {
    _mobAttackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('⚔️ 战斗'),
        backgroundColor: Colors.red[700],
      ),
      body: Column(
        children: [
          // 战斗区域
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[600]!),
              ),
              child: _inCombat && _currentMob != null
                  ? Column(
                    children: [
                      Text(
                        '👹 ${_currentMob!.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _currentMob!.hp / _currentMob!.maxHp,
                          backgroundColor: Colors.grey,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                          minHeight: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'HP: ${_currentMob!.hp} / ${_currentMob!.maxHp}',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('攻击: ${_currentMob!.attack}',
                                  style: const TextStyle(color: Colors.orange)),
                              Text('防御: ${_currentMob!.defense}',
                                  style: const TextStyle(color: Colors.blue)),
                            ],
                          ),
                          const SizedBox(width: 32),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('经验: ${_currentMob!.expReward}',
                                  style: const TextStyle(color: Colors.yellow)),
                              Text('金币: ${_currentMob!.mesoReward}',
                                  style: const TextStyle(color: Colors.amber)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  )
                  : const Center(
                      child: Text(
                        '选择一个怪物开始战斗！',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    ),
            ),
          ),
          // 玩家状态
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.blue[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('❤️ HP: ${game.hp}/${game.maxHp}',
                    style: const TextStyle(color: Colors.red)),
                Text('💙 MP: ${game.mp}/${game.maxMp}',
                    style: const TextStyle(color: Colors.blue)),
                Text('⭐ Lv.${game.level}',
                    style: const TextStyle(color: Colors.yellow)),
                Text('💰 ${game.mesos}',
                    style: const TextStyle(color: Colors.amber)),
              ],
            ),
          ),
          // 战斗日志
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                reverse: true,
                itemCount: _battleLog.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      _battleLog[index],
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ),
          // 操作按钮
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.sports_martial_arts),
                    label: const Text('攻击'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      padding: const EdgeInsets.all(16),
                    ),
                    onPressed: _inCombat ? _attackMob : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.bolt),
                    label: const Text('技能'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[700],
                      padding: const EdgeInsets.all(16),
                    ),
                    onPressed: _inCombat ? _useSkill : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.run_circle),
                    label: const Text('逃跑'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      padding: const EdgeInsets.all(16),
                    ),
                    onPressed: _inCombat ? _flee : null,
                  ),
                ),
              ],
            ),
          ),
          // 可选怪物列表
          if (!_inCombat)
            Expanded(
              flex: 2,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                itemCount: _availableMobs.length,
                itemBuilder: (context, index) {
                  final mob = _availableMobs[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[800],
                      ),
                      onPressed: () => _startCombat(mob),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('👹 ${mob.name}',
                              style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('HP:${mob.maxHp} ATK:${mob.attack}',
                              style: const TextStyle(color: Colors.white70, fontSize: 10)),
                          Text('EXP:${mob.expReward} 💰${mob.mesoReward}',
                              style: const TextStyle(color: Colors.yellow, fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
