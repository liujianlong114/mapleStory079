import 'package:flutter/material.dart';

import '../maple/wz_scene.dart';

/// ms079 Login.img/WorldSelect — 选区选频道
class WorldSelectPage extends StatefulWidget {
  const WorldSelectPage({super.key});

  @override
  State<WorldSelectPage> createState() => _WorldSelectPageState();
}

class _WorldSelectPageState extends State<WorldSelectPage> {
  WzSceneManifest? _scene;
  int _world = 0;
  int _channel = 1;

  @override
  void initState() {
    super.initState();
    WzSceneManifest.load('assets/scenes/login_worldselect.json').then((m) {
      if (mounted) setState(() => _scene = m);
    });
  }

  void _enter() {
    Navigator.of(context).pushReplacementNamed('/character-select');
  }

  void _onButton(String id) {
    if (id.startsWith('world_')) {
      setState(() => _world = int.tryParse(id.substring(6)) ?? 0);
      return;
    }
    if (id.startsWith('ch_')) {
      setState(() => _channel = int.tryParse(id.substring(3)) ?? 1);
      return;
    }
    switch (id) {
      case 'enter':
        _enter();
      case 'cancel':
        Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Set<String> get _selectedIds => {
        'world_$_world',
        'ch_$_channel',
      };

  @override
  Widget build(BuildContext context) {
    if (_scene == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFFB13A))),
      );
    }
    return Scaffold(
      body: WzSceneScreen(
        manifest: _scene!,
        onButton: _onButton,
        selectedButtonIds: _selectedIds,
        playBgm: true,
      ),
    );
  }
}
