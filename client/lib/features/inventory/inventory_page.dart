import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/resources/assets.dart';
import '../../models/item.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/game_provider.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final character = Provider.of<GameProvider>(context, listen: false).currentCharacter;
      if (character != null) {
        Provider.of<InventoryProvider>(context, listen: false).loadInventory(character.id);
      }
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
    final inventory = Provider.of<InventoryProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('🎒 背包'),
        backgroundColor: Colors.brown[700],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2), text: '装备'),
            Tab(icon: Icon(Icons.local_drink), text: '消耗'),
            Tab(icon: Icon(Icons.diamond), text: '其他'),
            Tab(icon: Icon(Icons.monetization_on), text: '金币'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEquipmentTab(game, inventory),
          _buildConsumableTab(game, inventory),
          _buildEtcTab(inventory),
          _buildCashTab(game, inventory),
        ],
      ),
    );
  }

  Widget _buildEquipmentTab(GameProvider game, InventoryProvider inventory) {
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
                '金币: ${inventory.mesos}',
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
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: inventory.equipSlots.length,
            itemBuilder: (context, index) {
              final item = inventory.equipSlots[index];
              return GestureDetector(
                onTap: () {
                  if (item != null) {
                    AudioManager().playUiClick();
                    _showItemDialog(item);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.brown[700],
                    border: Border.all(color: Colors.amber[700]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: item != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield, color: Colors.amber[300], size: 28),
                            const SizedBox(height: 4),
                            Text(
                              item.name,
                              style: TextStyle(color: Colors.amber[100], fontSize: 10),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        )
                      : Center(
                          child: Text(
                            _labelFor(index),
                            style: TextStyle(color: Colors.amber[100], fontSize: 10),
                          ),
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConsumableTab(GameProvider game, InventoryProvider inventory) {
    final consumables = inventory.consumables;
    return inventory.isLoading
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
                              AudioManager().playUiClick();
                              final hp = item.stats['hp'] ?? 0;
                              final mp = item.stats['mp'] ?? 0;
                              inventory.useItem(item);
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

  Widget _buildEtcTab(InventoryProvider inventory) {
    final etc = inventory.etcItems;
    return inventory.isLoading
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

  Widget _buildCashTab(GameProvider game, InventoryProvider inventory) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.savings, size: 64, color: Colors.amber),
          const SizedBox(height: 16),
          Text(
            '当前金币: ${inventory.mesos}',
            style: const TextStyle(color: Colors.amber, fontSize: 20),
          ),
          const SizedBox(height: 12),
          Text(
            '总物品价值: ${inventory.totalMesos}',
            style: TextStyle(color: Colors.amber[200], fontSize: 14),
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

  String _labelFor(int index) {
    const labels = ['头盔', '武器', '铠甲', '手套', '鞋子', '盾牌', '', ''];
    if (index >= labels.length) return '';
    return labels[index];
  }

  void _showItemDialog(Item item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
          title: Text(item.name, style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.description, style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 8),
              Text('类型: ${item.typeName}', style: const TextStyle(color: Colors.amber)),
              const SizedBox(height: 4),
              for (final entry in item.stats.entries)
                Text(
                  '${entry.key}: ${entry.value}',
                  style: TextStyle(color: Colors.grey[300]),
                ),
              const SizedBox(height: 4),
              Text('数量: ${item.quantity}', style: const TextStyle(color: Colors.yellow)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                AudioManager().playUiClick();
                Navigator.pop(context);
              },
              child: const Text('关闭', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
              onPressed: () {
                AudioManager().playUiClick();
                Navigator.pop(context);
                final inventory = Provider.of<InventoryProvider>(context, listen: false);
                inventory.equipItem(item);
              },
              child: const Text('装备', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
