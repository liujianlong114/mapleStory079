import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/resources/assets.dart';
import '../models/item.dart';
import '../providers/game_provider.dart';
import '../providers/inventory_provider.dart';

/// 游戏内打开的 UI 面板类型（079 UIWindow.img）
enum GameUiPanel { inventory, equip, stat, skill }

/// 079 风格可拖拽关闭的游戏内 UI 面板基类
class MapleGamePanel extends StatelessWidget {
  const MapleGamePanel({
    super.key,
    required this.backgroundAsset,
    required this.width,
    required this.height,
    required this.onClose,
    this.left = 120,
    this.top = 80,
    required this.child,
  });

  final String backgroundAsset;
  final double width;
  final double height;
  final VoidCallback onClose;
  final double left;
  final double top;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Image.asset(
              backgroundAsset,
              width: width,
              height: height,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
            ),
            child,
            Positioned(
              right: 6,
              top: 4,
              child: GestureDetector(
                onTap: () {
                  AudioManager().playUiClick();
                  onClose();
                },
                child: Image.asset(
                  'assets/images/ui/windows/btn_close_normal.png',
                  width: 85,
                  height: 19,
                  filterQuality: FilterQuality.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 背包（UIWindow.img/Item FullBackgrnd 603×289）
class MapleInventoryPanel extends StatefulWidget {
  const MapleInventoryPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<MapleInventoryPanel> createState() => _MapleInventoryPanelState();
}

class _MapleInventoryPanelState extends State<MapleInventoryPanel> {
  int _tab = 0;

  static const _tabNames = ['装备', '消耗', '其他', '设置', '特殊'];

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();
    final items = _itemsForTab(inv, _tab);

    return MapleGamePanel(
      backgroundAsset: 'assets/images/ui/windows/item_full_backgrnd.png',
      width: 603,
      height: 289,
      left: 100,
      top: 120,
      onClose: widget.onClose,
      child: Stack(
        children: [
          // 页签
          Positioned(
            left: 9,
            top: 26,
            child: Row(
              children: List.generate(5, (i) {
                final asset = _tab == i
                    ? 'assets/images/ui/windows/item_tab_enabled_$i.png'
                    : 'assets/images/ui/windows/item_tab_disabled_$i.png';
                return Padding(
                  padding: const EdgeInsets.only(right: 1),
                  child: GestureDetector(
                    onTap: () {
                      AudioManager().playUiClick();
                      setState(() => _tab = i);
                    },
                    child: Image.asset(asset, filterQuality: FilterQuality.none),
                  ),
                );
              }),
            ),
          ),
          // 金币
          Positioned(
            left: 480,
            top: 32,
            child: Text(
              '${inv.mesos}',
              style: const TextStyle(
                color: Color(0xFF3d2817),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // 物品格 4×6（32px 格，间距 4）
          Positioned(
            left: 11,
            top: 71,
            child: SizedBox(
              width: 580,
              height: 210,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1,
                ),
                itemCount: 24,
                itemBuilder: (_, index) {
                  final item = index < items.length ? items[index] : null;
                  return _itemSlot(item);
                },
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 8,
            child: Text(
              '物品栏 — ${_tabNames[_tab]}',
              style: const TextStyle(
                color: Color(0xFF5c4033),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Item> _itemsForTab(InventoryProvider inv, int tab) {
    switch (tab) {
      case 0:
        return inv.equipSlots.whereType<Item>().toList();
      case 1:
        return inv.consumables;
      case 2:
        return inv.etcItems;
      default:
        return [];
    }
  }

  Widget _itemSlot(Item? item) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/ui/windows/item_slot_disabled.png',
          fit: BoxFit.fill,
          filterQuality: FilterQuality.none,
        ),
        if (item != null)
          Center(
            child: _itemIcon(item),
          ),
        if (item != null && item.quantity > 1)
          Positioned(
            right: 2,
            bottom: 1,
            child: Text(
              '${item.quantity}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                shadows: [Shadow(color: Colors.black, blurRadius: 2)],
              ),
            ),
          ),
      ],
    );
  }

  Widget _itemIcon(Item item) {
    final path = item.icon.isNotEmpty
        ? AssetPaths.bundle(item.icon)
        : AssetPaths.bundle(SpriteDirs.itemPath(item.id));
    return Image.asset(
      path,
      width: 32,
      height: 32,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/ui/windows/item_slot_active.png',
        width: 32,
        height: 32,
        filterQuality: FilterQuality.none,
      ),
    );
  }
}

/// 装备窗（UIWindow.img/Equip 175×304）
class MapleEquipPanel extends StatelessWidget {
  const MapleEquipPanel({super.key, required this.onClose});

  final VoidCallback onClose;


  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();
    final game = context.watch<GameProvider>();

    return MapleGamePanel(
      backgroundAsset: 'assets/images/ui/windows/equip_backgrnd.png',
      width: 175,
      height: 304,
      left: 20,
      top: 100,
      onClose: onClose,
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 8,
            child: Text(
              game.state.characterName,
              style: const TextStyle(
                color: Color(0xFF3d2817),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: 24,
            child: Text(
              'LV.${game.level}',
              style: const TextStyle(color: Color(0xFF5c4033), fontSize: 10),
            ),
          ),
          ...List.generate(inv.equipSlots.length.clamp(0, 12), (i) {
            final col = i < 6 ? 0 : 1;
            final row = i < 6 ? i : i - 6;
            final item = i < inv.equipSlots.length ? inv.equipSlots[i] : null;
            return Positioned(
              left: 8 + col * 82.0,
              top: 48 + row * 38.0,
              child: SizedBox(
                width: 32,
                height: 32,
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/images/ui/windows/item_slot_disabled.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                    ),
                    if (item != null)
                      Center(
                        child: Image.asset(
                          AssetPaths.bundle(
                            item.icon.isNotEmpty
                                ? item.icon
                                : SpriteDirs.itemPath(item.id),
                          ),
                          width: 32,
                          height: 32,
                          filterQuality: FilterQuality.none,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// 属性窗（UIWindow.img/Stat）
class MapleStatPanel extends StatelessWidget {
  const MapleStatPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameProvider>();

    return MapleGamePanel(
      backgroundAsset: 'assets/images/ui/windows/stat_backgrnd.png',
      width: 175,
      height: 337,
      left: 620,
      top: 80,
      onClose: onClose,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 60,
            child: Image.asset(
              'assets/images/ui/windows/stat_basic.png',
              filterQuality: FilterQuality.none,
            ),
          ),
          Positioned(left: 12, top: 72, child: _statRow('STR', g.str, const Color(0xFFc04040))),
          Positioned(left: 12, top: 88, child: _statRow('DEX', g.dex, const Color(0xFF40a040))),
          Positioned(left: 12, top: 104, child: _statRow('INT', g.intl, const Color(0xFF4080c0))),
          Positioned(left: 12, top: 120, child: _statRow('LUK', g.luk, const Color(0xFFa040a0))),
          Positioned(
            left: 12,
            top: 148,
            child: Text(
              'HP ${g.hp}/${g.maxHp}',
              style: const TextStyle(color: Color(0xFF3d2817), fontSize: 10),
            ),
          ),
          Positioned(
            left: 12,
            top: 162,
            child: Text(
              'MP ${g.mp}/${g.maxMp}',
              style: const TextStyle(color: Color(0xFF3d2817), fontSize: 10),
            ),
          ),
          Positioned(
            left: 12,
            top: 180,
            child: Text(
              'AP ${g.ap}',
              style: const TextStyle(color: Color(0xFF3d2817), fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, int value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        Text('$value', style: const TextStyle(color: Color(0xFF3d2817), fontSize: 10)),
      ],
    );
  }
}

/// 技能窗（UIWindow.img/Skill）
class MapleSkillPanel extends StatelessWidget {
  const MapleSkillPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameProvider>();

    return MapleGamePanel(
      backgroundAsset: 'assets/images/ui/windows/skill_backgrnd.png',
      width: 175,
      height: 289,
      left: 300,
      top: 100,
      onClose: onClose,
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 8,
            child: Text(
              '技能 — SP ${g.state.sp}',
              style: const TextStyle(
                color: Color(0xFF3d2817),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 40,
            child: Image.asset(
              'assets/images/ui/windows/skill_row0.png',
              filterQuality: FilterQuality.none,
            ),
          ),
          Positioned(
            left: 10,
            top: 78,
            child: Image.asset(
              'assets/images/ui/windows/skill_row1.png',
              filterQuality: FilterQuality.none,
            ),
          ),
          const Positioned(
            left: 14,
            top: 48,
            child: Text('新手技能', style: TextStyle(color: Color(0xFF5c4033), fontSize: 9)),
          ),
        ],
      ),
    );
  }
}

/// 079 底部快捷道具栏 — 显示消耗品图标，点击使用并恢复 HP/MP。
///
/// 参考 HeavenClient UI/Pot/UseItem 动画，
/// 使用后通过 [onItemUsed] 回调通知外部播放动画和提示。
class MapleQuickSlotBar extends StatelessWidget {
  const MapleQuickSlotBar({
    super.key,
    required this.consumables,
    required this.onItemUsed,
    this.maxSlots = 8,
  });

  /// 当前背包中的消耗品列表
  final List<Item> consumables;

  /// 点击使用道具时的回调：参数为道具ID、HP恢复值、MP恢复值。
  final void Function(int itemId, int hpRecovery, int mpRecovery)? onItemUsed;

  final int maxSlots;

  @override
  Widget build(BuildContext context) {
    final displayItems = consumables.take(maxSlots).toList();

    return SizedBox(
      height: 42,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(maxSlots, (i) {
          final item = i < displayItems.length ? displayItems[i] : null;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _quickSlotItem(item),
          );
        }),
      ),
    );
  }

  Widget _quickSlotItem(Item? item) {
    return GestureDetector(
      onTap: item == null
          ? null
          : () {
              AudioManager().playUiClick();
              final hp = item.stats['hp'] ?? 0;
              final mp = item.stats['mp'] ?? 0;
              onItemUsed?.call(item.id, hp, mp);
            },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(
            color: item != null
                ? const Color(0xFF8B6914)
                : const Color(0xFF4A3728),
            width: 2,
          ),
          color: item != null
              ? const Color(0xFF2C1810).withValues(alpha: 0.85)
              : const Color(0xFF1A0F0A).withValues(alpha: 0.6),
        ),
        child: item == null
            ? null
            : Stack(
                alignment: Alignment.center,
                children: [
                  _itemIcon(item),
                  if (item.quantity > 1)
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 2),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _itemIcon(Item item) {
    final path = item.icon.isNotEmpty
        ? AssetPaths.bundle(item.icon)
        : AssetPaths.bundle(SpriteDirs.itemPath(item.id));
    return Image.asset(
      path,
      width: 32,
      height: 32,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/ui/windows/item_slot_active.png',
        width: 32,
        height: 32,
        filterQuality: FilterQuality.none,
      ),
    );
  }
}
