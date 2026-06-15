import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/resources/assets.dart';
import '../../providers/game_provider.dart';
import '../../providers/skill_provider.dart';
import '../../models/skill.dart';
import '../../widgets/damage_number.dart';
import '../../widgets/skill_bar_widget.dart';

class CombatPage extends StatefulWidget {
  const CombatPage({super.key});

  @override
  State<CombatPage> createState() => _CombatPageState();
}

class _CombatPageState extends State<CombatPage> {
  int _mobHp = 100;
  final int _mobMaxHp = 100;
  final int _mobAttack = 8;
  int _playerHp = 0;
  bool _inCombat = false;
  final List<Widget> _damageWidgets = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final game = Provider.of<GameProvider>(context, listen: false);
      setState(() {
        _playerHp = game.hp;
      });
    });
  }

  void _startCombat() {
    setState(() {
      _inCombat = true;
      _mobHp = _mobMaxHp;
    });
  }

  void _endCombat() {
    setState(() {
      _inCombat = false;
      _damageWidgets.clear();
    });
  }

  void _addDamageWidget(int damage, {bool isPlayer = false}) {
    final key = UniqueKey();
    setState(() {
      _damageWidgets.add(
        Positioned(
          key: key,
          left: isPlayer ? 60.0 : 220.0,
          top: 150.0,
          child: DamageNumber(
            damage: damage,
            startPosition: Offset.zero,
          ),
        ),
      );
    });
    Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _damageWidgets.removeWhere((w) => w.key == key);
        });
      }
    });
  }

  void _attackMob([Skill? skill]) async {
    final game = Provider.of<GameProvider>(context, listen: false);
    final skillProvider = Provider.of<SkillProvider>(context, listen: false);
    if (skill != null) {
      if (skillProvider.currentMp < skill.mpCost || skillProvider.isSkillOnCooldown(skill.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('技能无法使用！')),
        );
        return;
      }
    }

    final multiplier = skill?.damageMultiplier ?? 1.0;
    final baseDamage = game.str + (game.dex ~/ 2);
    final damage = (baseDamage * multiplier).toInt() - _mobAttack ~/ 3;
    setState(() {
      _mobHp = (_mobHp - damage).clamp(0, _mobMaxHp);
    });
    _addDamageWidget(damage);

    if (skill != null) {
      skillProvider.useSkill(skill);
      game.restoreHpMp(0, -skill.mpCost);
    }

    if (_mobHp <= 0) {
      game.gainExperience(50);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('击败怪物！获得 50 经验')),
      );
      _endCombat();
      return;
    }

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || !_inCombat) return;

    final mobDamage = _mobAttack;
    setState(() {
      _playerHp = (_playerHp - mobDamage).clamp(0, game.maxHp);
    });
    _addDamageWidget(mobDamage, isPlayer: true);

    if (_playerHp <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('你被击败了...')),
      );
      _endCombat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final skillProvider = Provider.of<SkillProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚔️ 战斗'),
        backgroundColor: Colors.red[700],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2a0a0a), Color(0xFF4a1a1a)],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('你的HP: $_playerHp/${game.maxHp}',
                            style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ),
                      Expanded(
                        child: Text('怪物HP: $_mobHp/$_mobMaxHp',
                            style: const TextStyle(color: Colors.white, fontSize: 14), textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _mobMaxHp > 0 ? _mobHp / _mobMaxHp : 0,
                      backgroundColor: Colors.grey,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: _inCombat
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.redAccent.withValues(alpha: 0.6),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.bug_report, size: 40, color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              const Text('野外怪', style: TextStyle(color: Colors.white, fontSize: 16)),
                              Text('Lv.5', style: TextStyle(color: Colors.yellow[400], fontSize: 12)),
                            ],
                          )
                        : const Text(
                            '点击"开始战斗"',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                  ),
                  ..._damageWidgets,
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              child: _inCombat
                  ? Column(
                      children: [
                        SizedBox(
                          height: 64,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: skillProvider.skills.length,
                            itemBuilder: (context, index) {
                              final skill = skillProvider.skills[index];
                              return GestureDetector(
                                onTap: () {
                                  AudioManager().playUiClick();
                                  _attackMob(skill);
                                },
                                child: Container(
                                  width: 64,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.purple[700],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.5)),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.flash_on, color: Colors.white, size: 20),
                                      Text(skill.name,
                                          style: const TextStyle(color: Colors.white, fontSize: 10),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  AudioManager().playUiClick();
                                  _attackMob();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orangeAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('普通攻击', style: TextStyle(fontSize: 16)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  AudioManager().playUiClick();
                                  _endCombat();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('逃跑', style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          AudioManager().playUiClick();
                          _startCombat();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('开始战斗', style: TextStyle(fontSize: 16)),
                      ),
                    ),
            ),
            if (game.currentCharacter != null)
              SkillBarWidget(characterId: game.currentCharacter!.id),
          ],
        ),
      ),
    );
  }
}
