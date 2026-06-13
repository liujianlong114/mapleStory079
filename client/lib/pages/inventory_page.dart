// =============================================================
// DEPRECATED: 此文件已被 `lib/features/inventory/inventory_page.dart` 替代。
// 保留用于向后兼容，请勿在新代码中引用。
// =============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../providers/game_provider.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Item> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final defaultItems = ItemCatalog.defaultItems;
    setState(() {
      _items = defaultItems;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('🎒 背包'),
        backgroundColor: Colors.brown[700],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2), text: '装备'),
            Tab(icon: Icon(Icons.potion), text: '消耗'),
            Tab(icon: Icon(Icons.diamond), text: '其他'),
            Tab(icon: Icon(Icons.monetization_on), text: '金币'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEquipmentTab(game),
          _buildConsumableTab(game),
          _buildEtcTab(game),
          _buildCashTab(game),
        ],
      ),
    );
  }

  Widget _buildEquipmentTab(GameProvider game) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.brown[800],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber[700]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '角色: ${game.state.characterName}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '金币: ${game.mesos}',
                style: const TextStyle(color: Colors.yellow, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildStatRow('STR', game.str, Colors.red),
              _buildStatRow('DEX', game.dex, Colors.green),
              _buildStatRow('INT', game.intl, Colors.blue),
              _buildStatRow('LUK', game.luk, Colors.purple),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: _items.where((i) => i.equippable).length + 4,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.brown[700],
                        border: Border.all(color: Colors.amber[700]!),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_iconFor(index), color: Colors.amber[300], size: 24),
                          const SizedBox(height: 4),
                          Text(
                            _labelFor(index),
                            style: TextStyle(color: Colors.amber[100], fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildConsumableTab(GameProvider game) {
    final consumables = _items.where((i) => i.consumable || i.usable).toList();
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : consumables.isEmpty
            ? const Center(
                child: Text(
                  '没有消耗品',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: consumables.length,
                itemBuilder: (context, index) {
                  final item = consumables[index];
                  return Card(
                    color: Colors.brown[800],
                    child: ListTile(
                      leading: const Icon(Icons.local_drink, color: Colors.amber),
                      title: Text(item.name, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                        item.description,
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      trailing: Column(
                        children: [
                          Text('×${item.quantity}', style: const TextStyle(color: Colors.yellow, fontSize: 12)),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                            ),
                            onPressed: () {
                              final hp = item.stats['hp'] ?? 0;
                              final mp = item.stats['mp'] ?? 0;
                              game.restoreHpMp(hp, mp);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('使用了 ${item.name}, HP+$hp, MP+$mp')),
                              );
                            },
                            child: const Text('使用', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
  }

  Widget _buildEtcTab(GameProvider game) {
    final etc = _items.where((i) => !i.usable && !i.equippable && !i.consumable).toList();
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : etc.isEmpty
            ? const Center(
                child: Text(
                  '其他物品\n暂无',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: etc.length,
                itemBuilder: (context, index) {
                  final item = etc[index];
                  return Card(
                    color: Colors.brown[800],
                    child: ListTile(
                      leading: const Icon(Icons.inventory, color: Colors.amber),
                      title: Text(item.name, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                        '数量: ${item.quantity}, 价值: ${item.price}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                  );
                },
              );
  }

  Widget _buildCashTab(GameProvider game) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.savings, size: 64, color: Colors.amber),
          const SizedBox(height: 16),
          Text(
            '当前金币: ${game.mesos}',
            style: const TextStyle(color: Colors.amber, fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String name, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: TextStyle(color: color)),
          Text('$value', style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  IconData _iconFor(int index) {
    const icons = [
      Icons.shield,
      Icons.sports_martial_arts,
      Icons.checkroom,
      Icons.sports_esports,
      Icons.umbrella,
      Icons.sports_baseball,
    ];
    return icons[index % icons.length];
  }

  String _labelFor(int index) {
    const labels = ['头盔', '武器', '铠甲', '手套', '鞋子', '盾牌'];
    return labels[index % labels.length];
  }
}
