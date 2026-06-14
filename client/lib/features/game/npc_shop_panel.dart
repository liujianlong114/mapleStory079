import 'package:flutter/material.dart';

import '../../services/api_service.dart';

/// 079 风格 NPC 商店面板（露比等）
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
  final _api = ApiService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  int _mesos = 0;
  String? _status;

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

  Future<void> _buy(int itemId, String name, int price) async {
    setState(() => _status = null);
    try {
      final newMesos = await _api.buyShopItem(
        npcId: widget.npcId,
        characterId: widget.characterId,
        itemId: itemId,
      );
      if (!mounted) return;
      setState(() {
        _mesos = newMesos;
        _status = '购买了 $name';
      });
      widget.onMesosChanged?.call(newMesos);
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
          constraints: const BoxConstraints(maxHeight: 480),
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
                    IconButton(
                      onPressed: widget.onClose,
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
                      final canBuy = _mesos >= price;
                      return ListTile(
                        dense: true,
                        title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: Text(
                          desc.isNotEmpty ? desc : '价格 $price',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        trailing: TextButton(
                          onPressed: canBuy ? () => _buy(itemId, name, price) : null,
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF5c4020),
                            foregroundColor: const Color(0xFFffe08a),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          child: Text('$price G'),
                        ),
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
