import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/resources/assets.dart';
import '../providers/game_provider.dart';
import 'ui/nine_patch_box.dart';
import 'ui/wz_bitmap_text.dart';

/// 079 底部状态栏 — UI.wz/StatusBar.img（800×71 + EXP 条）。
class MapleStatusBar extends StatelessWidget {
  const MapleStatusBar({
    super.key,
    this.onMenu,
    this.onChat,
    this.onShop,
    this.onInventory,
    this.onSkills,
    this.onStats,
    this.onKeyConfig,
  });

  final VoidCallback? onMenu;
  final VoidCallback? onChat;
  final VoidCallback? onShop;
  final VoidCallback? onInventory;
  final VoidCallback? onSkills;
  final VoidCallback? onStats;
  final VoidCallback? onKeyConfig;

  static const double barW = 800;
  static const double barH = 71;
  static const double expH = 31;
  static const double totalH = expH + barH;
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
      width: barW,
      height: totalH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // EXP 条（左下，原版 340×31）
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
                    widthFactor: (expPct / 100).clamp(0.0, 1.0),
                    child: Image.asset(
                      'assets/images/ui/hud/gauge_temp_exp.png',
                      width: 340,
                      height: expH,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 8,
                  child: WzBitmapText(
                    text: '${expPct.toStringAsFixed(2)}%',
                    height: 11,
                  ),
                ),
              ],
            ),
          ),
          // 主状态栏底图
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
          // 角色名 / 等级（肖像右侧）
          Positioned(
            left: 198,
            bottom: 44,
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
            left: 198,
            bottom: 28,
            child: Text(
              'LV. $level',
              style: const TextStyle(
                color: Color(0xFF5c4033),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // HP 量表 + 数值
          Positioned(
            left: 412,
            bottom: 40,
            child: Row(
              children: [
                Image.asset('assets/images/ui/hud/icon_red.png', width: 12, height: 12),
                const SizedBox(width: 2),
                WzGaugeBar(
                  fillAsset: 'assets/images/ui/hud/hp_gauge.png',
                  ratio: hpPct,
                  width: gaugeW,
                  height: gaugeH,
                ),
              ],
            ),
          ),
          Positioned(
            left: 530,
            bottom: 42,
            child: WzBitmapText(
              text: '${gp.hp}',
              height: 11,
              alignment: Alignment.centerRight,
            ),
          ),
          // MP 量表 + 数值
          Positioned(
            left: 412,
            bottom: 18,
            child: Row(
              children: [
                Image.asset('assets/images/ui/hud/icon_blue.png', width: 12, height: 12),
                const SizedBox(width: 2),
                WzGaugeBar(
                  fillAsset: 'assets/images/ui/hud/mp_gauge.png',
                  ratio: mpPct,
                  width: gaugeW,
                  height: gaugeH,
                ),
              ],
            ),
          ),
          Positioned(
            left: 528,
            bottom: 20,
            child: WzBitmapText(
              text: '${gp.mp}',
              height: 11,
              alignment: Alignment.centerRight,
            ),
          ),
          // 快捷键（EquipKey / InvenKey / StatKey / SkillKey / KeySet）
          Positioned(
            left: 58,
            bottom: 10,
            child: Row(
              children: [
                _keyBtn('assets/images/ui/hud/key_equip.png', onInventory),
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
          // 右侧菜单按钮
          Positioned(
            right: 8,
            bottom: 16,
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
      onTap: onTap,
      child: Image.asset(asset, height: 20, filterQuality: FilterQuality.none),
    );
  }

  Widget _iconBtn(String asset, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(asset, width: 43, height: 34, filterQuality: FilterQuality.none),
    );
  }
}
