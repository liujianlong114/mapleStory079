import 'package:flutter/material.dart';

import '../../core/resources/assets.dart';
import '../../core/resources/login_ui_assets.dart';
import '../character/new_char_page.dart';
import '../maple/wz_scene.dart';
import '../maple/wz_widgets.dart';

/// ms079 Login.img/RaceSelect — 创建前选职业族（JobType 0/1/2）
class RaceSelectPage extends StatefulWidget {
  const RaceSelectPage({super.key});

  @override
  State<RaceSelectPage> createState() => _RaceSelectPageState();
}

class _RaceSelectPageState extends State<RaceSelectPage> {
  WzSceneManifest? _scene;

  @override
  void initState() {
    super.initState();
    WzSceneManifest.load('assets/scenes/login_raceselect.json').then((m) {
      if (mounted) setState(() => _scene = m);
    });
  }

  Future<void> _pick(int jobType, {bool enabled = true}) async {
    if (!enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该职业未开放'), duration: Duration(seconds: 2)),
      );
      return;
    }
    AudioManager().playSfx(SfxAssets.click);
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NewCharPage(jobType: jobType)),
    );
    if (created == true && mounted) {
      Navigator.of(context).pop(true);
    }
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
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _raceBtn('骑士团', () => _pick(0, enabled: false)),
                const SizedBox(width: 16),
                _raceBtn('冒险家', () => _pick(1)),
                const SizedBox(width: 16),
                _raceBtn('战神', () => _pick(2, enabled: false)),
              ],
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: WzSpriteButton(
              normal: LoginUiAssets.buttonStates('btn_no').first,
              width: 85,
              height: 29,
              onPressed: () => Navigator.of(context).pop(false),
              fallbackLabel: '返回',
            ),
          ),
        ],
      ),
    );
  }

  Widget _raceBtn(String label, VoidCallback onTap) {
    return WzSpriteButton(
      normal: LoginUiAssets.buttonStates('btn_new').first,
      hover: LoginUiAssets.buttonOverStates('btn_new').first,
      width: 101,
      height: 35,
      onPressed: onTap,
      fallbackLabel: label,
    );
  }
}
