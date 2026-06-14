import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../game/engine/game_controls.dart';

/// 079 风格键位设置（对应 UIWindow.img KeyConfig）
class KeyConfigDialog extends StatefulWidget {
  const KeyConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const KeyConfigDialog(),
    );
  }

  @override
  State<KeyConfigDialog> createState() => _KeyConfigDialogState();
}

class _KeyConfigDialogState extends State<KeyConfigDialog> {
  String? _waitingFor;

  Future<void> _capture(String action) async {
    setState(() => _waitingFor = action);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (_waitingFor == null || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      setState(() => _waitingFor = null);
      return KeyEventResult.handled;
    }
    switch (_waitingFor) {
      case 'left':
        GameControls.moveLeft = key;
      case 'right':
        GameControls.moveRight = key;
      case 'attack':
        GameControls.attack = key;
      case 'jump':
        GameControls.jump = key;
      case 'pickup':
        GameControls.pickup = key;
      case 'inventory':
        GameControls.inventory = key;
      case 'keyconfig':
        GameControls.keyConfig = key;
    }
    setState(() => _waitingFor = null);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: AlertDialog(
        backgroundColor: const Color(0xFF1a1208),
        title: const Text(
          '键盘设置',
          style: TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '点击按键栏后按下要绑定的键。Esc 取消。',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              _row('向左移动', 'left', GameControls.moveLeft),
              _row('向右移动', 'right', GameControls.moveRight),
              _row('普通攻击', 'attack', GameControls.attack),
              _row('跳跃', 'jump', GameControls.jump),
              _row('拾取物品', 'pickup', GameControls.pickup),
              _row('打开背包', 'inventory', GameControls.inventory),
              _row('键位设置', 'keyconfig', GameControls.keyConfig),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await GameControls.resetDefaults();
              if (mounted) setState(() {});
            },
            child: const Text('恢复默认', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              await GameControls.save();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('确定', style: TextStyle(color: Color(0xFFFFD54F))),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String action, LogicalKeyboardKey key) {
    final waiting = _waitingFor == action;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          OutlinedButton(
            onPressed: () => _capture(action),
            style: OutlinedButton.styleFrom(
              foregroundColor: waiting ? Colors.black : const Color(0xFFFFD54F),
              backgroundColor: waiting ? const Color(0xFFFFD54F) : Colors.transparent,
              side: const BorderSide(color: Color(0xFF8D6E63)),
              minimumSize: const Size(72, 32),
            ),
            child: Text(waiting ? '…' : GameControls.labelFor(key)),
          ),
        ],
      ),
    );
  }
}
