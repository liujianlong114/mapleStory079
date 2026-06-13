import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';

/// 横向的玩家状态栏（顶部栏使用）
class PlayerStatsBar extends StatelessWidget {
  const PlayerStatsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final gp = Provider.of<GameProvider>(context);
    final level = gp.level;
    final hp = gp.hp;
    final maxHp = gp.maxHp;
    final mp = gp.mp;
    final maxMp = gp.maxMp;
    final str = gp.str;
    final dex = gp.dex;
    final intl = gp.intl;
    final luk = gp.luk;
    final mesos = gp.mesos;
    final expProgress = gp.expProgress;
    final ap = gp.ap;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${gp.state.characterName}  Lv.$level  ${gp.state.className}',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Icon(Icons.attach_money, color: Colors.amber.shade200, size: 14),
              const SizedBox(width: 4),
              Text(
                '$mesos',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              if (ap > 0) ...[
                const SizedBox(width: 12),
                Text(
                  'AP: $ap',
                  style: const TextStyle(color: Colors.purpleAccent, fontSize: 12),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _HealthBar(label: 'HP', current: hp, max: maxHp, color: Colors.redAccent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HealthBar(label: 'MP', current: mp, max: maxMp, color: Colors.blueAccent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HealthBar(
                  label: 'EXP',
                  current: expProgress.round(),
                  max: 100,
                  color: Colors.yellowAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 10,
            children: [
              _Attribute('STR', str, Colors.red),
              _Attribute('DEX', dex, Colors.green),
              _Attribute('INT', intl, Colors.blue),
              _Attribute('LUK', luk, Colors.yellow),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthBar extends StatelessWidget {
  final String label;
  final int current;
  final int max;
  final Color color;

  const _HealthBar({
    required this.label,
    required this.current,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? current / max : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Text(
              '$current/$max',
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            widthFactor: pct.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
      ],
    );
  }
}

class _Attribute extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _Attribute(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 2),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
