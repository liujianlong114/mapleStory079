import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/skill_provider.dart';
import '../../providers/game_provider.dart';

class SkillsPage extends StatefulWidget {
  const SkillsPage({super.key});

  @override
  State<SkillsPage> createState() => _SkillsPageState();
}

class _SkillsPageState extends State<SkillsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final character = Provider.of<GameProvider>(context, listen: false).currentCharacter;
      final skillProvider = Provider.of<SkillProvider>(context, listen: false);
      if (character != null) {
        skillProvider.loadSkills(character.id, character.characterClass);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final skillProvider = Provider.of<SkillProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('⚔️ 技能'),
        backgroundColor: Colors.purple[700],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple[800],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple[400]!),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('MP: ${skillProvider.currentMp}/${skillProvider.maxMp}',
                        style: const TextStyle(color: Colors.blue, fontSize: 16)),
                    Text('SP: ${game.ap}',
                        style: const TextStyle(color: Colors.yellow, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: skillProvider.maxMp > 0
                        ? skillProvider.currentMp / skillProvider.maxMp
                        : 0,
                    backgroundColor: Colors.grey,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    minHeight: 12,
                  ),
                ),
              ],
            ),
          ),
          if (skillProvider.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (skillProvider.skills.isEmpty)
            const Expanded(
              child: Center(
                child: Text('暂无技能',
                    style: TextStyle(color: Colors.grey, fontSize: 18)),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: skillProvider.skills.length,
                itemBuilder: (context, index) {
                  final skill = skillProvider.skills[index];
                  return Card(
                    color: Colors.grey[800],
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple[600],
                        child: Text(
                          '${skill.requiredLevel}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      title: Text(skill.name, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                        '${skill.description}\nMP消耗: ${skill.mpCost} | 倍率: ${skill.damageMultiplier}x | 类型: ${skill.type} | 冷却: ${skill.cooldown}ms',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[700]),
                        onPressed: skillProvider.isSkillOnCooldown(skill.id) || skillProvider.currentMp < skill.mpCost
                            ? null
                            : () {
                                skillProvider.useSkill(skill);
                                game.restoreHpMp(0, -skill.mpCost);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('使用了 ${skill.name}!'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                        child: Text(skillProvider.isSkillOnCooldown(skill.id) ? '冷却中' : '使用'),
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
