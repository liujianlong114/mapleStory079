import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/skill_provider.dart';
import '../models/skill.dart';

class SkillBarWidget extends StatefulWidget {
  final int characterId;
  final int slotCount;

  const SkillBarWidget({
    super.key,
    required this.characterId,
    this.slotCount = 6,
  });

  @override
  State<SkillBarWidget> createState() => _SkillBarWidgetState();
}

class _SkillBarWidgetState extends State<SkillBarWidget> {
  @override
  Widget build(BuildContext context) {
    final skillProvider = Provider.of<SkillProvider>(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.black.withOpacity(0.4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.slotCount, (index) {
          final slot = index < skillProvider.skillBarSlots.length
              ? skillProvider.skillBarSlots[index]
              : null;
          final skill = slot != null && slot.id >= 0 ? slot : null;
          final onCd = skill != null && skillProvider.isSkillOnCooldown(skill.id);
          final cdRemaining = skill != null ? skillProvider.getCooldownRemaining(skill.id) : null;

          return GestureDetector(
            onTap: skill != null && !onCd
                ? () {
                    if (skillProvider.currentMp >= skill.mpCost) {
                      skillProvider.useSkill(skill);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('使用了 ${skill.name}！'), duration: const Duration(milliseconds: 800)),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('MP不足！'), duration: Duration(milliseconds: 600)),
                      );
                    }
                  }
                : null,
            child: Container(
              width: 56,
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: skill != null ? Colors.purple[800] : Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: skill != null
                      ? Colors.purpleAccent.withOpacity(0.5)
                      : Colors.grey.withOpacity(0.3),
                ),
                boxShadow: skill != null && !onCd
                    ? [
                        BoxShadow(
                          color: Colors.purpleAccent.withOpacity(0.3),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  Center(
                    child: skill != null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _iconFor(skill.type),
                                color: Colors.white,
                                size: 22,
                              ),
                              Text(
                                '${skill.currentLevel > 0 ? 'Lv.${skill.currentLevel}' : ''}',
                                style: const TextStyle(color: Colors.white, fontSize: 9),
                              ),
                            ],
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(color: Colors.grey[500], fontSize: 16),
                          ),
                  ),
                  if (skill != null)
                    Positioned(
                      bottom: 2,
                      right: 4,
                      child: Text(
                        '${skill.mpCost}',
                        style: TextStyle(color: Colors.blue[200], fontSize: 9),
                      ),
                    ),
                  if (onCd && cdRemaining != null)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${(cdRemaining / 1000).toStringAsFixed(1)}s',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'attack':
        return Icons.sports_martial_arts;
      case 'magic':
        return Icons.auto_fix_high;
      case 'aoe':
        return Icons.bolt;
      case 'heal':
        return Icons.healing;
      default:
        return Icons.star;
    }
  }
}
