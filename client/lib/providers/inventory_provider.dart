import 'package:flutter/foundation.dart';

import '../models/item.dart';
import '../services/api_service.dart';

class InventoryProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  int _characterId = 0;
  final List<Item?> _equipSlots = List.filled(6, null);
  final List<Item> _consumables = [];
  final List<Item> _etcItems = [];
  int _mesos = 0;
  bool _isLoading = false;
  String? _errorMessage;

  List<Item?> get equipSlots => List.unmodifiable(_equipSlots);
  List<Item> get consumables => List.unmodifiable(_consumables);
  List<Item> get etcItems => List.unmodifiable(_etcItems);
  int get mesos => _mesos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalMesos {
    var total = 0;
    for (final item in _consumables) {
      total += item.price * item.quantity;
    }
    for (final item in _etcItems) {
      total += item.price * item.quantity;
    }
    return total;
  }

  Future<void> loadInventory(int characterId) async {
    _characterId = characterId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rows = await _api.getCharacterInventory(characterId);
      _equipSlots.fillRange(0, _equipSlots.length, null);
      _consumables.clear();
      _etcItems.clear();

      for (final row in rows) {
        final itemId = (row['item_id'] as num?)?.toInt() ?? 0;
        final qty = (row['quantity'] as num?)?.toInt() ?? 1;
        if (itemId <= 0) continue;
        final item = Item(
          id: itemId,
          name: '物品 #$itemId',
          description: '',
          type: 'etc',
          quantity: qty,
          equippable: itemId >= 1000000 && itemId < 2000000,
          usable: itemId >= 2000000 && itemId < 3000000,
          consumable: itemId >= 2000000 && itemId < 3000000,
        );
        addItem(item);
      }

      if (_consumables.isEmpty && _etcItems.isEmpty && rows.isEmpty) {
        _consumables.addAll(ItemCatalog.defaultItems.where((i) => i.usable || i.consumable));
        _etcItems.addAll(ItemCatalog.defaultItems.where((i) => !i.equippable && !i.usable && !i.consumable));
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = '加载背包失败: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void addItem(Item item) {
    if (item.equippable) {
      final emptySlot = _equipSlots.indexWhere((s) => s == null);
      if (emptySlot >= 0) {
        _equipSlots[emptySlot] = item;
      }
    } else if (item.usable || item.consumable) {
      final existing = _consumables.indexWhere((c) => c.id == item.id);
      if (existing >= 0) {
        _consumables[existing] = _consumables[existing].copyWith(
          quantity: _consumables[existing].quantity + item.quantity,
        );
      } else {
        _consumables.add(item);
      }
    } else {
      final existing = _etcItems.indexWhere((c) => c.id == item.id);
      if (existing >= 0) {
        _etcItems[existing] = _etcItems[existing].copyWith(
          quantity: _etcItems[existing].quantity + item.quantity,
        );
      } else {
        _etcItems.add(item);
      }
    }
    notifyListeners();
  }

  void removeItem(Item item, {int quantity = 1}) {
    if (item.equippable) {
      final idx = _equipSlots.indexWhere((s) => s?.id == item.id);
      if (idx >= 0) _equipSlots[idx] = null;
    } else if (item.usable || item.consumable) {
      final idx = _consumables.indexWhere((c) => c.id == item.id);
      if (idx >= 0) {
        final remaining = _consumables[idx].quantity - quantity;
        if (remaining <= 0) {
          _consumables.removeAt(idx);
        } else {
          _consumables[idx] = _consumables[idx].copyWith(quantity: remaining);
        }
      }
    } else {
      final idx = _etcItems.indexWhere((c) => c.id == item.id);
      if (idx >= 0) {
        final remaining = _etcItems[idx].quantity - quantity;
        if (remaining <= 0) {
          _etcItems.removeAt(idx);
        } else {
          _etcItems[idx] = _etcItems[idx].copyWith(quantity: remaining);
        }
      }
    }
    notifyListeners();
  }

  void useItem(Item item) {
    removeItem(item, quantity: 1);
  }

  void equipItem(Item item) {
    final existingIndex = _equipSlots.indexWhere((s) => s?.id == item.id);
    if (existingIndex >= 0) {
      _equipSlots[existingIndex] = null;
    } else {
      final emptySlot = _equipSlots.indexWhere((s) => s == null);
      if (emptySlot >= 0) {
        _equipSlots[emptySlot] = item;
      } else {
        _equipSlots[0] = item;
      }
    }
    notifyListeners();
  }

  void addMesos(int amount) {
    _mesos += amount;
    notifyListeners();
  }

  void removeMesos(int amount) {
    _mesos = (_mesos - amount).clamp(0, 1 << 30);
    notifyListeners();
  }

  void reset() {
    _equipSlots.fillRange(0, _equipSlots.length, null);
    _consumables.clear();
    _etcItems.clear();
    _mesos = 0;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
