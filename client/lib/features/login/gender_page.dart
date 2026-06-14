import 'package:flutter/material.dart';

import '../../core/resources/login_ui_assets.dart';
import '../../providers/auth_provider.dart';
import '../maple/wz_scene.dart';
import '../maple/wz_widgets.dart';
import 'package:provider/provider.dart';

/// ms079 Login.img/Title/Gender — SetGenderRequest
class GenderPage extends StatefulWidget {
  const GenderPage({super.key});

  @override
  State<GenderPage> createState() => _GenderPageState();
}

class _GenderPageState extends State<GenderPage> {
  WzSceneManifest? _scene;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WzSceneManifest.load('assets/scenes/login_gender.json').then((m) {
      if (mounted) setState(() => _scene = m);
    });
  }

  Future<void> _pick(int gender) async {
    setState(() => _busy = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final ok = await auth.setGender(gender);
      if (ok && mounted) {
        Navigator.of(context).pushReplacementNamed('/world-select');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
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
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '选择性别',
                  style: TextStyle(color: Color(0xFFFFE082), fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    WzSpriteButton(
                      normal: LoginUiAssets.buttonStates('btn_yes').first,
                      hover: LoginUiAssets.buttonOverStates('btn_yes').first,
                      width: 100,
                      height: 36,
                      onPressed: _busy ? null : () => _pick(0),
                      fallbackLabel: '男生',
                    ),
                    const SizedBox(width: 32),
                    WzSpriteButton(
                      normal: LoginUiAssets.buttonStates('btn_yes').first,
                      hover: LoginUiAssets.buttonOverStates('btn_yes').first,
                      width: 100,
                      height: 36,
                      onPressed: _busy ? null : () => _pick(1),
                      fallbackLabel: '女生',
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_busy)
            const ColoredBox(
              color: Colors.black38,
              child: Center(child: CircularProgressIndicator(color: Color(0xFFFFB13A))),
            ),
        ],
      ),
    );
  }
}
