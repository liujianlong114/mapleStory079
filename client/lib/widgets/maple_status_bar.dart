import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/resources/assets.dart';
import '../providers/game_provider.dart';
import 'ui/nine_patch_box.dart';
import 'ui/wz_bitmap_text.dart';

/// 079 底部状态栏 — 对齐 HeavenClient UIStatusBar（800×600，position y=480）
class MapleStatusBar extends StatelessWidget {
  const MapleStatusBar({
    super.key,
    this.onMenu,
    this.onChat,
    this.onShop,
    this.onInventory,
    this.onEquip,
    this.onSkills,
    this.onStats,
    this.onKeyConfig,
  });

  final VoidCallback? onMenu;
  final VoidCallback? onChat;
  final VoidCallback? onShop;
  final VoidCallback? onInventory;
  final VoidCallback? onEquip;
  final VoidCallback? onSkills;
  final VoidCallback? onStats;
  final VoidCallback? onKeyConfig;

  static const double panelW = 800;
  static const double panelH = 120;
  static const double barH = 71;
  static const double expY = 87;
  static const double expW = 340;
  static const double expH = 31;
  static const double hpmpX = 412;
  static const double hpmpY = 40;
  static const double gaugeW = 109;
  static const double gaugeH = 18;

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final hpPct = gp.maxHp > 0 ? gp.hp / gp.maxHp : 0.0;
    final mpPct = gp.maxMp > 0 ? gp.mp / gp.maxMp : 0.0;
    final expPct = GameConstants.expPercent(gp.level, gp.state.exp);
    final name = gp.state.characterName;
    final level = gp.level;

    return SizedBox(
      width: panelW,
      height: panelH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 主底栏（71px，贴底）
          Positioned(
            left: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/ui/hud/status_backgrnd.png',
              width: panelW,
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
          // EXP 条（HeavenClient exp_pos = 0,87）
          Positioned(
            left: 0,
            top: expY,
            width: expW,
            height: expH,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/ui/hud/exp_graduation.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none,
                ),
                WzGaugeBar(
                  fillAsset: 'assets/images/ui/hud/gauge_temp_exp.png',
                  bgAsset: 'assets/images/ui/hud/gauge_gray.png',
                  ratio: expPct / 100,
                  width: expW,
                  height: 16,
                ),
                Positioned(
                  left: 8,
                  top: 7,
                  child: WzBitmapText(
                    text: '${expPct.toStringAsFixed(2)}%',
                    height: 11,
                  ),
                ),
              ],
            ),
          ),
          // 角色名 / 等级
          Positioned(
            left: 487,
            top: 40,
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
            left: 461,
            top: 48,
            child: Text(
              'LV. $level',
              style: const TextStyle(
                color: Color(0xFF5c4033),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // HP
          Positioned(
            left: hpmpX,
            top: hpmpY,
            child: Row(
              children: [
                Image.asset('assets/images/ui/hud/icon_red.png', width: 12, height: 12),
                const SizedBox(width: 2),
                WzGaugeBar(
                  fillAsset: 'assets/images/ui/hud/hp_gauge.png',
                  bgAsset: 'assets/images/ui/hud/gauge_gray.png',
                  ratio: hpPct,
                  width: gaugeW,
                  height: gaugeH,
                ),
              ],
            ),
          ),
          Positioned(
            left: 530,
            top: 70,
            child: WzBitmapText(
              text: '${gp.hp}',
              height: 11,
              alignment: Alignment.centerRight,
            ),
          ),
          // MP
          Positioned(
            left: hpmpX,
            top: hpmpY + 22,
            child: Row(
              children: [
                Image.asset('assets/images/ui/hud/icon_blue.png', width: 12, height: 12),
                const SizedBox(width: 2),
                WzGaugeBar(
                  fillAsset: 'assets/images/ui/hud/mp_gauge.png',
                  bgAsset: 'assets/images/ui/hud/gauge_gray.png',
                  ratio: mpPct,
                  width: gaugeW,
                  height: gaugeH,
                ),
              ],
            ),
          ),
          Positioned(
            left: 528,
            top: 86,
            child: WzBitmapText(
              text: '${gp.mp}',
              height: 11,
              alignment: Alignment.centerRight,
            ),
          ),
          // 金币（Mesos）
          Positioned(
            left: 120,
            top: 28,
            child: Text(
              '金币 ${_formatMesos(gp.mesos)}',
              style: const TextStyle(
                color: Color(0xFFc9a227),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // 快捷键
          Positioned(
            left: 58,
            bottom: 10,
            child: Row(
              children: [
                _keyBtn('assets/images/ui/hud/key_equip.png', onEquip),
                const SizedBox(width: 2),
                _keyBtn('assets/images/ui/hud/key_inven.png', onInventory),
                const SizedBox(width: 2),
                _keyBtn('assets/images/ui/hud/key_stat.png', onStats),
                const SizedBox(width: 2),
                _keyBtn('assets/images/ui/hud/key_skill.png', onSkills),
                const SizedBox(width: 2),
                _keyBtn('assets/images/ui/hud/key_keyset.png', onKeyConfig),
              ],
            ),
          ),
          // 右侧菜单
          Positioned(
            left: 591,
            top: 73,
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

  Widget _keyBtn(String asset, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap == null ? null : () {
        AudioManager().playUiClick();
        onTap();
      },
      child: Image.asset(asset, height: 20, filterQuality: FilterQuality.none),
    );
  }

  Widget _iconBtn(String asset, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap == null ? null : () {
        AudioManager().playUiClick();
        onTap();
      },
      child: Image.asset(asset, width: 43, height: 34, filterQuality: FilterQuality.none),
    );
  }

  static String _formatMesos(int mesos) {
    if (mesos < 1000) return mesos.toString();
    if (mesos < 1000000) return '${(mesos / 1000).toStringAsFixed(1)}k';
    return '${(mesos / 1000000).toStringAsFixed(1)}m';
  }
}
