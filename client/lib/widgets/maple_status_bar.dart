import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/resources/assets.dart';
import '../providers/game_provider.dart';
import 'ui/nine_patch_box.dart';

/// 079 底部状态栏 — UI.wz/StatusBar.img（800×71 + EXP 条）。
class MapleStatusBar extends StatelessWidget {
  const MapleStatusBar({
    super.key,
    this.onMenu,
    this.onChat,
    this.onShop,
    this.onInventory,
    this.onSkills,
  });

  final VoidCallback? onMenu;
  final VoidCallback? onChat;
  final VoidCallback? onShop;
  final VoidCallback? onInventory;
  final VoidCallback? onSkills;

  static const double barW = 800;
  static const double barH = 71;
  static const double expH = 31;
  static const double totalH = expH + barH;

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final hpPct = gp.maxHp > 0 ? gp.hp / gp.maxHp : 0.0;
    final mpPct = gp.maxMp > 0 ? gp.mp / gp.maxMp : 0.0;
    final expPct = GameConstants.expPercent(gp.level, gp.state.exp) / 100.0;
    final name = gp.state.characterName;
    final level = gp.level;

    return SizedBox(
      width: barW,
      height: totalH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: 340,
            height: expH,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/ui/hud/exp_graduation.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none,
                ),
                ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: expPct.clamp(0.0, 1.0),
                    child: Image.asset(
                      'assets/images/ui/hud/gauge_temp_exp.png',
                      width: 340,
                      height: expH,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: Text(
              'EXP ${(expPct * 100).toStringAsFixed(2)}%',
              style: const TextStyle(
                color: Color(0xFF2c3e50),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/ui/hud/status_backgrnd.png',
              width: barW,
              height: barH,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/ui/hud/status_backgrnd2.png',
              height: barH,
              fit: BoxFit.fitHeight,
              filterQuality: FilterQuality.none,
            ),
          ),
          Positioned(
            left: 248,
            bottom: 48,
            child: Text(
              name,
              style: const TextStyle(
                color: Color(0xFF3d2817),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            left: 248,
            bottom: 30,
            child: Text(
              'LV. $level',
              style: const TextStyle(
                color: Color(0xFF5c4033),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            right: 248,
            bottom: 38,
            child: Row(
              children: [
                Image.asset('assets/images/ui/hud/icon_red.png', width: 12, height: 12),
                const SizedBox(width: 2),
                WzGaugeBar(
                  fillAsset: 'assets/images/ui/hud/hp_gauge.png',
                  ratio: hpPct,
                ),
              ],
            ),
          ),
          Positioned(
            right: 248,
            bottom: 16,
            child: Row(
              children: [
                Image.asset('assets/images/ui/hud/icon_blue.png', width: 12, height: 12),
                const SizedBox(width: 2),
                WzGaugeBar(
                  fillAsset: 'assets/images/ui/hud/mp_gauge.png',
                  ratio: mpPct,
                ),
              ],
            ),
          ),
          Positioned(
            right: 108,
            bottom: 38,
            child: Text(
              '${gp.hp}',
              style: const TextStyle(
                color: Color(0xFFc0392b),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            right: 108,
            bottom: 16,
            child: Text(
              '${gp.mp}',
              style: const TextStyle(
                color: Color(0xFF2980b9),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 22,
            child: Row(
              children: [
                _keyHint('C', '装备', onInventory),
                const SizedBox(width: 8),
                _keyHint('I', '道具', onInventory),
                const SizedBox(width: 8),
                _keyHint('S', '技能', onSkills),
              ],
            ),
          ),
          Positioned(
            right: 6,
            bottom: 18,
            child: Row(
              children: [
                _iconBtn('assets/images/ui/hud/btn_shop_normal.png', onShop),
                _iconBtn('assets/images/ui/hud/btn_menu_normal.png', onMenu),
                _iconBtn('assets/images/ui/hud/btn_chat_normal.png', onChat),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _keyHint(String key, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFd4c4a8),
              border: Border.all(color: const Color(0xFF8b7355)),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(key, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 2),
          Text(label, style: const TextStyle(color: Color(0xFF4a3728), fontSize: 9)),
        ],
      ),
    );
  }

  Widget _iconBtn(String asset, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(asset, width: 43, height: 34, filterQuality: FilterQuality.none),
    );
  }
}
