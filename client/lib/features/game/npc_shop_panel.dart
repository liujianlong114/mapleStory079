import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/resources/assets.dart';
import '../../providers/game_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../services/api_service.dart';

/// 079 风格 NPC 商店面板（希娜 2101 等）
///
/// - 商品列表通过 GET /shop/npc/{npcId} 拉取（服务端走 npcShopCatalog + Item 表）
/// - 购买请求 POST /shop/npc/{npcId}/buy，携带 quantity 与 characterId
/// - 购买成功后立即同步 GameProvider 的 mesos，并将新物品写入 InventoryProvider
class NpcShopPanel extends StatefulWidget {
  final int npcId;
  final String npcName;
  final int characterId;
  final int mesos;
  final VoidCallback onClose;
  final void Function(int newMesos)? onMesosChanged;

  const NpcShopPanel({
    super.key,
    required this.npcId,
    required this.npcName,
    required this.characterId,
    required this.mesos,
    required this.onClose,
    this.onMesosChanged,
  });

  @override
  State<NpcShopPanel> createState() => _NpcShopPanelState();
}

class _NpcShopPanelState extends State<NpcShopPanel> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  late int _mesos;
  String? _status;
  final Map<int, int> _pendingQuantity = <int, int>{};

  @override
  void initState() {
    super.initState();
    _mesos = widget.mesos;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.getShopItems(widget.npcId);
      if (!mounted) return;
      setState(() {
        _items = items;
        for (final row in _items) {
          final id = (row['item_id'] as num?)?.toInt() ?? 0;
          _pendingQuantity.putIfAbsent(id, () => 1);
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _buy(int itemId, String name, int price, int quantity) async {
    setState(() => _status = null);
    if (quantity <= 0) quantity = 1;
    final total = price * quantity;
    if (_mesos < total) {
      if (!mounted) return;
      setState(() => _status = '金币不足（需要 $total G）');
      return;
    }
    try {
      final newMesos = await _api.buyShopItem(
        npcId: widget.npcId,
        characterId: widget.characterId,
        itemId: itemId,
        quantity: quantity,
      );
      if (!mounted) return;
      setState(() {
        _mesos = newMesos;
        _status = '购买了 $name × $quantity';
      });
      widget.onMesosChanged?.call(newMesos);
      if (mounted) {
        Provider.of<GameProvider>(context, listen: false).syncFromGameWorld(mesos: newMesos);
        try {
          await Provider.of<InventoryProvider>(context, listen: false).loadInventory(widget.characterId);
        } catch (_) {}
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 420,
          constraints: const BoxConstraints(maxHeight: 520),
          decoration: BoxDecoration(
            color: const Color(0xFF2a1f14),
            border: Border.all(color: const Color(0xFFc9a227), width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: const Color(0xFF4a3520),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.npcName} 的商店',
                        style: const TextStyle(
                          color: Color(0xFFffe08a),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      '$_mesos 金币',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        AudioManager().playUiClick();
                        widget.onClose();
                      },
                      icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: Color(0xFFffe08a)),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                )
              else if (_items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('此 NPC 没有商品。', style: TextStyle(color: Colors.white70)),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(color: Color(0x33ffffff), height: 8),
                    itemBuilder: (context, i) {
                      final row = _items[i];
                      final itemId = (row['item_id'] as num?)?.toInt() ?? 0;
                      final name = row['name'] as String? ?? '物品';
                      final price = (row['price'] as num?)?.toInt() ?? 0;
                      final desc = row['desc'] as String? ?? '';
                      final qty = _pendingQuantity[itemId] ?? 1;
                      final canBuy = _mesos >= price * qty && qty > 0;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(
                                  desc.isNotEmpty ? '$desc · $price G' : '价格 $price G',
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 48,
                            height: 28,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                border: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Color(0xFFc9a227)),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Color(0xFFc9a227)),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                hintText: '1',
                                hintStyle: const TextStyle(color: Colors.white38),
                              ),
                              controller: TextEditingController(text: '$qty'),
                              onSubmitted: (v) {
                                final parsed = int.tryParse(v) ?? 1;
                                setState(() => _pendingQuantity[itemId] = parsed.clamp(1, 9999));
                              },
                              onChanged: (v) {
                                final parsed = int.tryParse(v) ?? 1;
                                _pendingQuantity[itemId] = parsed.clamp(1, 9999);
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          TextButton(
                            onPressed: canBuy
                                ? () {
                                    AudioManager().playUiClick();
                                    _buy(itemId, name, price, _pendingQuantity[itemId] ?? 1);
                                  }
                                : null,
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF5c4020),
                              foregroundColor: const Color(0xFFffe08a),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            ),
                            child: Text('${price * (_pendingQuantity[itemId] ?? 1)} G'),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              if (_status != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _status!,
                    style: TextStyle(
                      color: _status!.contains('购买') ? Colors.lightGreenAccent : Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
