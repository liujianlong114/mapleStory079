// =============================================================
// DEPRECATED: 此文件已被 `lib/features/skills/skills_page.dart` 替代。
// 保留用于向后兼容，请勿在新代码中引用。
// =============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/skill.dart';
import '../providers/game_provider.dart';

class SkillsPage extends StatefulWidget {
  const SkillsPage({super.key});

  @override
  State<SkillsPage> createState() => _SkillsPageState();
}

class _SkillsPageState extends State<SkillsPage> {
  List<Skill> _skills = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    setState(() => _loading = true);
    final game = Provider.of<GameProvider>(context, listen: false);
    final charClass = game.currentCharacter?.characterClass ?? 0;
    final classSkills = SkillCatalog.skillsForClass(charClass);
    setState(() {
      _skills = classSkills;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);

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
                    Text('MP: ${game.mp} / ${game.maxMp}',
                        style: const TextStyle(color: Colors.blue, fontSize: 16)),
                    Text('SP: ${game.ap}',
                        style: const TextStyle(color: Colors.yellow, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: game.maxMp > 0 ? game.mp / game.maxMp : 0,
                    backgroundColor: Colors.grey,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    minHeight: 12,
                  ),
                ),
              ],
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_skills.isEmpty)
            const Expanded(
              child: Center(
                child: Text('暂无技能', style: TextStyle(color: Colors.grey, fontSize: 18)),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _skills.length,
                itemBuilder: (context, index) {
                  final skill = _skills[index];
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
                        '${skill.description}\nMP消耗: ${skill.mpCost} | 倍率: ${skill.damageMultiplier}x | 类型: ${skill.type}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[700]),
                        onPressed: game.mp >= skill.mpCost
                            ? () {
                                game.restoreHpMp(0, -skill.mpCost);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('使用了 ${skill.name}!'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            : null,
                        child: const Text('使用'),
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
