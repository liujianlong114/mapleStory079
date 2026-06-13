class Item {
  final int id;
  final String name;
  final String description;
  final String type;
  final int slot;
  final int quantity;
  final int maxStack;
  final int price;
  final String icon;
  final Map<String, int> stats;
  final bool usable;
  final bool equippable;
  final bool consumable;

  const Item({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.slot = 0,
    this.quantity = 1,
    this.maxStack = 100,
    this.price = 0,
    this.icon = '',
    this.stats = const {},
    this.usable = false,
    this.equippable = false,
    this.consumable = false,
  });

  String get typeName {
    switch (type) {
      case 'weapon':
        return '武器';
      case 'armor':
        return '防具';
      case 'helmet':
        return '头盔';
      case 'glove':
        return '手套';
      case 'shoes':
        return '鞋子';
      case 'accessory':
        return '饰品';
      case 'potion':
        return '药水';
      case 'scroll':
        return '卷轴';
      case 'etc':
        return '其他';
      default:
        return '道具';
    }
  }

  bool get canStack => maxStack > 1;

  factory Item.fromJson(Map<String, dynamic> json) {
    final statsJson = json['stats'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final stats = <String, int>{};
    statsJson.forEach((k, v) {
      stats[k] = (v as num).toInt();
    });
    return Item(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      type: (json['type'] ?? 'etc') as String,
      slot: (json['slot'] ?? 0) as int,
      quantity: (json['quantity'] ?? 1) as int,
      maxStack: (json['max_stack'] ?? 100) as int,
      price: (json['price'] ?? 0) as int,
      icon: (json['icon'] ?? '') as String,
      stats: stats,
      usable: (json['usable'] ?? false) as bool,
      equippable: (json['equippable'] ?? false) as bool,
      consumable: (json['consumable'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'slot': slot,
      'quantity': quantity,
      'max_stack': maxStack,
      'price': price,
      'stats': stats,
      'usable': usable,
      'equippable': equippable,
      'consumable': consumable,
    };
  }

  Item copyWith({
    int? id,
    String? name,
    String? description,
    String? type,
    int? slot,
    int? quantity,
    int? maxStack,
    int? price,
    String? icon,
    Map<String, int>? stats,
    bool? usable,
    bool? equippable,
    bool? consumable,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      slot: slot ?? this.slot,
      quantity: quantity ?? this.quantity,
      maxStack: maxStack ?? this.maxStack,
      price: price ?? this.price,
      icon: icon ?? this.icon,
      stats: stats ?? this.stats,
      usable: usable ?? this.usable,
      equippable: equippable ?? this.equippable,
      consumable: consumable ?? this.consumable,
    );
  }
}

class Inventory {
  final List<Item?> equip;
  final List<Item> consume;
  final List<Item> etc;

  Inventory({
    List<Item?>? equip,
    List<Item>? consume,
    List<Item>? etc,
  })  : equip = equip ?? List<Item?>.filled(6, null),
        consume = consume ?? [],
        etc = etc ?? [];

  int get totalMesos {
    var total = 0;
    for (final item in consume) {
      total += item.price * item.quantity;
    }
    for (final item in etc) {
      total += item.price * item.quantity;
    }
    return total;
  }

  Inventory copyWith({
    List<Item?>? equip,
    List<Item>? consume,
    List<Item>? etc,
  }) {
    return Inventory(
      equip: equip ?? this.equip,
      consume: consume ?? this.consume,
      etc: etc ?? this.etc,
    );
  }
}

class ItemCatalog {
  static const List<Item> defaultItems = [
    Item(
      id: 100,
      name: '红色药水',
      description: '恢复50点HP',
      type: 'potion',
      quantity: 10,
      maxStack: 100,
      price: 50,
      usable: true,
      consumable: true,
      stats: {'hp': 50},
    ),
    Item(
      id: 101,
      name: '蓝色药水',
      description: '恢复30点MP',
      type: 'potion',
      quantity: 10,
      maxStack: 100,
      price: 80,
      usable: true,
      consumable: true,
      stats: {'mp': 30},
    ),
    Item(
      id: 102,
      name: '大红色药水',
      description: '恢复200点HP',
      type: 'potion',
      quantity: 1,
      maxStack: 100,
      price: 200,
      usable: true,
      consumable: true,
      stats: {'hp': 200},
    ),
    Item(
      id: 200,
      name: '新手之剑',
      description: '新手战士的入门武器',
      type: 'weapon',
      slot: 0,
      quantity: 1,
      maxStack: 1,
      price: 1000,
      usable: false,
      equippable: true,
      stats: {'attack': 5},
    ),
    Item(
      id: 201,
      name: '法师之杖',
      description: '蕴含魔力的法杖',
      type: 'weapon',
      slot: 0,
      quantity: 1,
      maxStack: 1,
      price: 1500,
      equippable: true,
      stats: {'magic_attack': 8, 'int': 3},
    ),
    Item(
      id: 202,
      name: '木弓',
      description: '简单而实用的木弓',
      type: 'weapon',
      slot: 0,
      quantity: 1,
      maxStack: 1,
      price: 1200,
      equippable: true,
      stats: {'attack': 6, 'dex': 3},
    ),
    Item(
      id: 300,
      name: '布衣',
      description: '普通的布衣防具',
      type: 'armor',
      slot: 1,
      quantity: 1,
      maxStack: 1,
      price: 500,
      equippable: true,
      stats: {'defense': 3},
    ),
    Item(
      id: 400,
      name: '蜗牛壳',
      description: '蜗牛掉落的壳',
      type: 'etc',
      quantity: 1,
      maxStack: 200,
      price: 5,
    ),
    Item(
      id: 401,
      name: '蘑菇盖',
      description: '蘑菇怪掉落',
      type: 'etc',
      quantity: 1,
      maxStack: 200,
      price: 10,
    ),
  ];

  static Item? getItem(int id) {
    try {
      return defaultItems.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<Item> getStarterKit(int characterClass) {
    final kit = <Item>[
      const Item(
        id: 100,
        name: '红色药水',
        description: '恢复50点HP',
        type: 'potion',
        quantity: 10,
        maxStack: 100,
        price: 50,
        usable: true,
        consumable: true,
        stats: {'hp': 50},
      ),
      const Item(
        id: 101,
        name: '蓝色药水',
        description: '恢复30点MP',
        type: 'potion',
        quantity: 5,
        maxStack: 100,
        price: 80,
        usable: true,
        consumable: true,
        stats: {'mp': 30},
      ),
    ];
    switch (characterClass) {
      case 1:
        kit.add(const Item(
          id: 200,
          name: '新手之剑',
          description: '新手战士的入门武器',
          type: 'weapon',
          quantity: 1,
          maxStack: 1,
          price: 1000,
          equippable: true,
          stats: {'attack': 5},
        ));
        break;
      case 2:
        kit.add(const Item(
          id: 201,
          name: '法师之杖',
          description: '蕴含魔力的法杖',
          type: 'weapon',
          quantity: 1,
          maxStack: 1,
          price: 1500,
          equippable: true,
          stats: {'magic_attack': 8, 'int': 3},
        ));
        break;
      case 3:
        kit.add(const Item(
          id: 202,
          name: '木弓',
          description: '简单而实用的木弓',
          type: 'weapon',
          quantity: 1,
          maxStack: 1,
          price: 1200,
          equippable: true,
          stats: {'attack': 6, 'dex': 3},
        ));
        break;
    }
    return kit;
  }
}
