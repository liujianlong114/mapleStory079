import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/game_provider.dart';
import '../../widgets/player_stats.dart';
import '../../widgets/mini_map.dart';
import '../../game/engine/game_world.dart';
import '../../models/mob.dart';
import '../../core/theme/app_theme.dart';

class GameScenePage extends StatefulWidget {
  final int mapId;
  final String mapName;
  final double mapWidth;
  final double mapHeight;

  const GameScenePage({
    super.key,
    required this.mapId,
    required this.mapName,
    this.mapWidth = 1600,
    this.mapHeight = 900,
  });

  @override
  State<GameScenePage> createState() => _GameScenePageState();
}

class _GameScenePageState extends State<GameScenePage> {
  late final GameWorld _gameWorld;
  final _damageNumbers = <_DamageFloat>[];

  @override
  void initState() {
    super.initState();
    _gameWorld = GameWorld(
      mapId: widget.mapId,
      mapName: widget.mapName,
      mapWidth: widget.mapWidth,
      mapHeight: widget.mapHeight,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _spawnDefaultEntities();
      _setupStatSync();
    });
  }

  void _setupStatSync() {
    if (!mounted) return;
    final gp = context.read<GameProvider>();
    _gameWorld.onStatChange = ({
      int? hp,
      int? maxHp,
      int? mp,
      int? maxMp,
      int? level,
      int? exp,
      int? mesos,
    }) {
      gp.syncFromGameWorld(
        hp: hp,
        maxHp: maxHp,
        mp: mp,
        maxMp: maxMp,
        level: level,
        exp: exp,
        mesos: mesos,
      );
    };
    _gameWorld.onLevelUp = (newLevel) {
      gp.syncFromGameWorld(level: newLevel);
    };
    _gameWorld.onPlayerDead = () {
      gp.syncFromGameWorld(hp: 0);
    };
  }

  void _spawnDefaultEntities() {
    for (int i = 0; i < 5; i++) {
      final template = MobCatalog.templates[i % MobCatalog.templates.length];
      final mob = Mob(
        id: 10000 + i,
        mobId: template.mobId,
        name: template.name,
        level: template.level,
        hp: template.maxHp,
        maxHp: template.maxHp,
        attack: template.attack,
        defense: template.defense,
        expReward: template.expReward,
        mesoReward: template.mesoReward,
        posX: (widget.mapWidth / 2) + (i - 2) * 140,
        posY: (widget.mapHeight / 2) + (i % 2 == 0 ? -60 : 60),
      );
      _gameWorld.addMob(mob);
    }
    _gameWorld.addNPC(
      id: 1,
      name: '卡姆伊',
      position: Vector2(widget.mapWidth / 2 - 200, widget.mapHeight / 2),
    );
  }

  void _onAttack() {
    _gameWorld.playerAttack();
    final gp = context.read<GameProvider>();
    final dmg = 10 + gp.state.level * 2;
    setState(() {
      _damageNumbers.add(_DamageFloat(
        MediaQuery.of(context).size.width / 2,
        MediaQuery.of(context).size.height / 2,
        dmg,
      ));
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _damageNumbers.removeAt(0);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: GameWidget(
              game: _gameWorld,
              backgroundBuilder: (_) => Container(
                color: const Color(0xFF1a1a2e),
              ),
            ),
          ),
          const Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: PlayerStatsBar(),
          ),
          Positioned(
            top: 80,
            right: 10,
            child: MiniMapWidget(
              mapWidth: widget.mapWidth.toInt(),
              mapHeight: widget.mapHeight.toInt(),
              playerX: _gameWorld.playerPosition.x,
              playerY: _gameWorld.playerPosition.y,
              mapName: widget.mapName,
            ),
          ),
          ..._damageNumbers.map((d) => Positioned(
                left: d.x - 30,
                top: d.y - 40,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  builder: (_, v, __) => Opacity(
                    opacity: 1 - v,
                    child: Transform.translate(
                      offset: Offset(0, -40 * v),
                      child: Text(
                        '-${d.damage}',
                        style: const TextStyle(
                          color: Colors.yellowAccent,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                        ),
                      ),
                    ),
                  ),
                ),
              )),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: _onAttack,
                    icon: const Icon(Icons.bolt),
                    label: const Text('攻击 [J]'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFe94560),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      _gameWorld.playerUseSkill(1);
                    },
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('技能 1'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFe94560)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 4,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Text(
                  widget.mapName,
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DamageFloat {
  final double x;
  final double y;
  final int damage;

  _DamageFloat(this.x, this.y, this.damage);
}
