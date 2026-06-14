import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 冒险岛 079 默认键位（与官方客户端一致，可自定义）
class GameControls {
  GameControls._();

  static const _prefix = 'ms079_key_';

  static LogicalKeyboardKey moveLeft = LogicalKeyboardKey.arrowLeft;
  static LogicalKeyboardKey moveRight = LogicalKeyboardKey.arrowRight;
  static LogicalKeyboardKey attack = LogicalKeyboardKey.controlLeft;
  static LogicalKeyboardKey jump = LogicalKeyboardKey.altLeft;
  static LogicalKeyboardKey pickup = LogicalKeyboardKey.keyZ;
  static LogicalKeyboardKey inventory = LogicalKeyboardKey.keyI;
  static LogicalKeyboardKey keyConfig = LogicalKeyboardKey.keyK;

  static bool _loaded = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    moveLeft = _fromId(p.getInt('${_prefix}left')) ?? LogicalKeyboardKey.arrowLeft;
    moveRight = _fromId(p.getInt('${_prefix}right')) ?? LogicalKeyboardKey.arrowRight;
    attack = _fromId(p.getInt('${_prefix}attack')) ?? LogicalKeyboardKey.controlLeft;
    jump = _fromId(p.getInt('${_prefix}jump')) ?? LogicalKeyboardKey.altLeft;
    pickup = _fromId(p.getInt('${_prefix}pickup')) ?? LogicalKeyboardKey.keyZ;
    inventory = _fromId(p.getInt('${_prefix}inventory')) ?? LogicalKeyboardKey.keyI;
    keyConfig = _fromId(p.getInt('${_prefix}keyconfig')) ?? LogicalKeyboardKey.keyK;
    _loaded = true;
  }

  static Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('${_prefix}left', moveLeft.keyId);
    await p.setInt('${_prefix}right', moveRight.keyId);
    await p.setInt('${_prefix}attack', attack.keyId);
    await p.setInt('${_prefix}jump', jump.keyId);
    await p.setInt('${_prefix}pickup', pickup.keyId);
    await p.setInt('${_prefix}inventory', inventory.keyId);
    await p.setInt('${_prefix}keyconfig', keyConfig.keyId);
  }

  static Future<void> resetDefaults() async {
    moveLeft = LogicalKeyboardKey.arrowLeft;
    moveRight = LogicalKeyboardKey.arrowRight;
    attack = LogicalKeyboardKey.controlLeft;
    jump = LogicalKeyboardKey.altLeft;
    pickup = LogicalKeyboardKey.keyZ;
    inventory = LogicalKeyboardKey.keyI;
    keyConfig = LogicalKeyboardKey.keyK;
    await save();
  }

  static LogicalKeyboardKey? _fromId(int? id) {
    if (id == null) return null;
    for (final k in LogicalKeyboardKey.knownLogicalKeys) {
      if (k.keyId == id) return k;
    }
    return null;
  }

  static String labelFor(LogicalKeyboardKey key) {
    final n = key.keyLabel;
    if (n.isNotEmpty) return n.toUpperCase();
    return key.debugName ?? 'Key';
  }

  static bool isMoveLeft(LogicalKeyboardKey key) =>
      key == moveLeft || key == LogicalKeyboardKey.keyA;

  static bool isMoveRight(LogicalKeyboardKey key) =>
      key == moveRight || key == LogicalKeyboardKey.keyD;

  static bool isAttack(LogicalKeyboardKey key) =>
      key == attack || key == LogicalKeyboardKey.controlRight;

  static bool isJump(LogicalKeyboardKey key) =>
      key == jump || key == LogicalKeyboardKey.altRight;

  static bool isPickup(LogicalKeyboardKey key) => key == pickup;

  static bool isInventory(LogicalKeyboardKey key) => key == inventory;

  static bool isKeyConfig(LogicalKeyboardKey key) => key == keyConfig;

  static bool anyMoveLeft(Set<LogicalKeyboardKey> pressed) =>
      pressed.any(isMoveLeft);

  static bool anyMoveRight(Set<LogicalKeyboardKey> pressed) =>
      pressed.any(isMoveRight);

  static bool anyJump(Set<LogicalKeyboardKey> pressed) => pressed.any(isJump);

  static String get hint =>
      '${labelFor(moveLeft)}/${labelFor(moveRight)} 移动  |  '
      '${labelFor(attack)} 攻击  |  ${labelFor(jump)} 跳跃  |  '
      '${labelFor(pickup)} 拾取  |  ${labelFor(keyConfig)} 键位';
}
