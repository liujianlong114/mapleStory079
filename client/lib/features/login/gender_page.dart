import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/resources/assets.dart';
import '../../providers/auth_provider.dart';
import '../maple/wz_scene.dart';

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
      AudioManager().playUiClick();
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final ok = await auth.setGender(gender);
      if (ok && mounted) {
        Navigator.of(context).pushReplacementNamed('/world-select');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onButton(String id) {
    if (_busy) return;
    if (id == 'male') _pick(0);
    if (id == 'female') _pick(1);
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
          WzSceneScreen(
            manifest: _scene!,
            onButton: _onButton,
            playBgm: true,
            overlay: WzLoginPanel(
              panel: _scene!.loginPanel,
              panelImage: _scene!.panelImage,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '选择性别',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFFE082),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '请选择角色性别',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
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
