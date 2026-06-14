import 'package:flutter/material.dart';

import '../../core/resources/assets.dart';
import '../../core/resources/login_ui_assets.dart';
import '../maple/wz_scene.dart';
import '../maple/wz_widgets.dart';

/// ms079 Login.img/WorldSelect — 选区选频道（简化单区）
class WorldSelectPage extends StatefulWidget {
  const WorldSelectPage({super.key});

  @override
  State<WorldSelectPage> createState() => _WorldSelectPageState();
}

class _WorldSelectPageState extends State<WorldSelectPage> {
  WzSceneManifest? _scene;
  int _channel = 1;

  @override
  void initState() {
    super.initState();
    WzSceneManifest.load('assets/scenes/login_worldselect.json').then((m) {
      if (mounted) setState(() => _scene = m);
    });
  }

  void _enter() {
    AudioManager().playSfx(SfxAssets.click);
    Navigator.of(context).pushReplacementNamed('/character-select');
  }

  @override
  Widget build(BuildContext context) {
    if (_scene == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFFB13A))),
      );
    }
    return Scaffold(
      body: Stack(
        children: [
          WzSceneScreen(manifest: _scene!, onButton: (_) {}, playBgm: true),
          Center(
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3B2414).withValues(alpha: 0.92),
                border: Border.all(color: const Color(0xFFD4A373), width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '蓝蜗牛',
                    style: TextStyle(color: Color(0xFFFFE082), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  for (var ch = 1; ch <= 3; ch++)
                    ListTile(
                      dense: true,
                      title: Text('频道 $ch', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      leading: Radio<int>(
                        value: ch,
                        groupValue: _channel,
                        activeColor: const Color(0xFFFFD700),
                        onChanged: (v) => setState(() => _channel = v ?? 1),
                      ),
                    ),
                  const SizedBox(height: 8),
                  WzSpriteButton(
                    normal: LoginUiAssets.buttonStates('btn_yes').first,
                    hover: LoginUiAssets.buttonOverStates('btn_yes').first,
                    width: 85,
                    height: 29,
                    onPressed: _enter,
                    fallbackLabel: '进入',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
