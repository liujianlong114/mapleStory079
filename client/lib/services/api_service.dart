import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../features/character/beginner_creation_catalog.dart';
import '../models/account.dart';
import '../models/character.dart';
import '../models/game_map.dart';
import '../models/mob.dart';
import '../models/skill.dart';
import '../models/item.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  String? get token => _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> _headers({bool authRequired = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (authRequired && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body.isEmpty) return {};
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        return {'data': decoded};
      } catch (_) {
        return {'raw': body};
      }
    }
    throw Exception('API Error (${response.statusCode}): $body');
  }

  Map<String, dynamic> _unwrapMap(Map<String, dynamic> data) {
    final inner = _unwrapData(data);
    if (inner is Map<String, dynamic>) {
      return inner;
    }
    return data;
  }

  /// 解析服务端统一 envelope：{code, data} 或 {success, data}
  dynamic _unwrapData(Map<String, dynamic> data) {
    if (data['code'] == 0 && data['data'] != null) {
      return data['data'];
    }
    if (data['success'] == true && data['data'] != null) {
      return data['data'];
    }
    return data;
  }

  List<Map<String, dynamic>> _unwrapList(
    Map<String, dynamic> data, {
    String key = 'items',
  }) {
    if (data[key] is List) {
      return (data[key] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    if (data['success'] == true && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return [];
  }

  Future<Account> register(String username, String password, String email) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/register'),
      headers: _headers(authRequired: false),
      body: jsonEncode({
        'username': username,
        'password': password,
        'email': email,
      }),
    );

    final data = await _handleResponse(response);
    return Account.fromJson(data);
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
      headers: _headers(authRequired: false),
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    final data = await _handleResponse(response);
    final payload = _unwrapData(data);
    if (payload is Map<String, dynamic>) {
      if (payload['account'] is Map) {
        return Map<String, dynamic>.from(payload);
      }
      if (payload['username'] != null) {
        return {
          'account': payload,
          if (payload['token'] != null) 'token': payload['token'],
        };
      }
    }
    return Map<String, dynamic>.from(data);
  }

  /// 从 login 响应解析 Account 并保存 token
  Account parseLoginAccount(Map<String, dynamic> loginPayload) {
    final accountRaw = loginPayload['account'];
    if (accountRaw is Map<String, dynamic>) {
      final acc = Account.fromJson(accountRaw);
      final token = loginPayload['token'] as String?;
      if (token != null) {
        _token = token;
        return Account(
          id: acc.id,
          username: acc.username,
          email: acc.email,
          gender: acc.gender,
          status: acc.status,
          createdAt: acc.createdAt,
          token: token,
        );
      }
      return acc;
    }
    throw Exception('登录响应缺少 account 字段');
  }

  Future<Account> setGender(int accountId, int gender) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/gender'),
      headers: _headers(),
      body: jsonEncode({'accountId': accountId, 'gender': gender}),
    );
    final data = _unwrapMap(await _handleResponse(response));
    final accRaw = data['account'];
    if (accRaw is Map<String, dynamic>) {
      return Account.fromJson(accRaw);
    }
    return Account(id: accountId, username: '', gender: gender, status: 1);
  }

  Future<Character> createCharacter(
    int accountId,
    String name,
    int characterClass, {
    BeginnerLook? look,
    int jobType = 1,
  }) async {
    final body = <String, dynamic>{
      'accountId': accountId,
      'account_id': accountId,
      'name': name,
      'class': characterClass,
      'jobType': look?.jobType ?? jobType,
      'face': look?.face ?? 0,
      'hair': look?.hair ?? 0,
      'hairColor': 0,
      'skin': 0,
      'top': look?.top ?? 0,
      'bottom': look?.bottom ?? 0,
      'shoes': look?.shoes ?? 0,
      'weapon': look?.weapon ?? 0,
    };
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/characters/'),
      headers: _headers(),
      body: jsonEncode(body),
    );

    final data = _unwrapMap(await _handleResponse(response));
    return Character.fromJson(data);
  }

  /// 079 checkCharName — ms079-main CharLoginHandler.CheckCharName
  Future<bool> checkCharacterName(String name) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/characters/check-name?name=${Uri.encodeComponent(name)}'),
      headers: _headers(),
    );
    final data = _unwrapMap(await _handleResponse(response));
    return data['available'] == true;
  }

  Future<List<Character>> getCharacters(int accountId) async {
    if (accountId <= 0) {
      throw Exception('无效的 accountId: $accountId');
    }
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/characters/?accountId=$accountId'),
      headers: _headers(),
    );

    final data = await _handleResponse(response);
    final list = _unwrapList(data, key: 'characters');
    if (list.isNotEmpty) {
      return list.map((e) => Character.fromJson(e)).toList();
    }
    final inner = _unwrapData(data);
    if (inner is List) {
      return inner
          .map((e) => Character.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  Future<Character> getCharacter(int id) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/characters/$id'),
      headers: _headers(),
    );

    final data = _unwrapMap(await _handleResponse(response));
    return Character.fromJson(data);
  }

  Future<bool> deleteCharacter(int id) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.apiBaseUrl}/characters/$id'),
      headers: _headers(),
    );
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<Map<String, dynamic>> getGameState(int characterId) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/game/state?character_id=$characterId'),
      headers: _headers(),
    );

    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> moveCharacter(int characterId, double x, double y) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/game/move'),
      headers: _headers(),
      body: jsonEncode({
        'character_id': characterId,
        'x': x,
        'y': y,
      }),
    );

    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> changeMap(
    int characterId,
    int mapId, {
    String portalName = '',
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/game/change-map'),
      headers: _headers(),
      body: jsonEncode({
        'character_id': characterId,
        'map_id': mapId,
        'portal_name': portalName,
      }),
    );

    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> gainExp(int characterId, int exp) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/game/gain-exp'),
      headers: _headers(),
      body: jsonEncode({
        'character_id': characterId,
        'exp': exp,
      }),
    );

    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> levelUp(int characterId) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/game/levelup/$characterId'),
      headers: _headers(),
    );

    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> addAbilityPoints(int characterId, String stat, int points) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/game/add-ap'),
      headers: _headers(),
      body: jsonEncode({
        'character_id': characterId,
        'stat': stat,
        'points': points,
      }),
    );

    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> restore(int characterId, int hp, int mp) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/game/restore'),
      headers: _headers(),
      body: jsonEncode({
        'character_id': characterId,
        'hp': hp,
        'mp': mp,
      }),
    );

    return await _handleResponse(response);
  }

  Future<List<GameMap>> getAllMaps() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/maps'),
      headers: _headers(),
    );

    final data = await _handleResponse(response);
    final list = _unwrapList(data, key: 'maps');
    return list.map((e) => GameMap.fromJson(e)).toList();
  }

  Future<GameMap> getMap(int id) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/maps/$id'),
      headers: _headers(),
    );

    final data = _unwrapMap(await _handleResponse(response));
    return GameMap.fromJson(data);
  }

  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.apiBaseUrl.replaceAll('/api/v1', '/health')),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = utf8.decode(response.bodyBytes);
        if (body.isNotEmpty) {
          return jsonDecode(body) as Map<String, dynamic>;
        }
        return {'status': 'ok'};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
    return {'status': 'unknown'};
  }

  // ============= Combat APIs =============
  Future<Map<String, dynamic>> calculateDamage({
    required int attackerStr,
    required int attackerDex,
    required int defenderDef,
    int level = 1,
    bool useSkill = false,
    double skillMultiplier = 1.0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/combat/calculate-damage'),
        headers: _headers(),
        body: jsonEncode({
          'str': attackerStr,
          'dex': attackerDex,
          'def': defenderDef,
          'level': level,
          'use_skill': useSkill,
          'skill_multiplier': skillMultiplier,
        }),
      );
      return await _handleResponse(response);
    } catch (_) {
      final base = (attackerStr * 1.2 + attackerDex * 0.3).toInt();
      return {'damage': base, 'missed': false};
    }
  }

  Future<List<Map<String, dynamic>>> getMapMobInstances(int mapId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/game/map-instances?map_id=$mapId'),
        headers: _headers(),
      );
      final data = await _handleResponse(response);
      return _unwrapList(data, key: 'mob_instances');
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCharacterInventory(int characterId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/inventory?characterId=$characterId&character_id=$characterId'),
        headers: _headers(),
      );
      final data = await _handleResponse(response);
      if (data['inventory'] is List) {
        return (data['inventory'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return _unwrapList(data, key: 'items');
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> playerAttackMob({
    required int characterId,
    required int mobId,
    int? instanceId,
    int? skillId,
    int? mapId,
    double? x,
    double? y,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/combat/player-attack-mob'),
        headers: _headers(),
        body: jsonEncode({
          'character_id': characterId,
          if (instanceId != null) 'instance_id': instanceId,
          if (mobId > 0) 'mob_id': mobId,
          if (skillId != null) 'skill_id': skillId,
          if (mapId != null) 'map_id': mapId,
          if (x != null) 'x': x,
          if (y != null) 'y': y,
        }),
      );
      return await _handleResponse(response);
    } catch (_) {
      return {'damage': 0, 'is_critical': false, 'mob_killed': false};
    }
  }

  Future<Map<String, dynamic>> pickupLoot({
    required int characterId,
    required String dropId,
    double? x,
    double? y,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/combat/pickup-loot'),
        headers: _headers(),
        body: jsonEncode({
          'character_id': characterId,
          'drop_id': dropId,
          if (x != null) 'x': x,
          if (y != null) 'y': y,
        }),
      );
      return await _handleResponse(response);
    } catch (_) {
      return {'success': false};
    }
  }

  Future<List<Map<String, dynamic>>> listGroundLoot(int mapId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/combat/ground-loot?map_id=$mapId'),
        headers: _headers(),
      );
      final data = await _handleResponse(response);
      final raw = data['ground_loots'];
      if (raw is List) {
        return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> mobAttackPlayer({
    required int characterId,
    required int mobId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/combat/mob-attack-player'),
        headers: _headers(),
        body: jsonEncode({
          'character_id': characterId,
          'mob_id': mobId,
        }),
      );
      return await _handleResponse(response);
    } catch (_) {
      return {'damage': 0, 'missed': false};
    }
  }

  Future<Map<String, dynamic>> getCombatStats(int characterId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/combat/stats?character_id=$characterId'),
        headers: _headers(),
      );
      return await _handleResponse(response);
    } catch (_) {
      return {'str': 10, 'dex': 4, 'critical_rate': 5.0};
    }
  }

  Future<Map<String, dynamic>> reviveCharacter(int characterId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/combat/revive'),
        headers: _headers(),
        body: jsonEncode({'character_id': characterId}),
      );
      return await _handleResponse(response);
    } catch (_) {
      return {'revived': true};
    }
  }

  // ============= Mobs APIs =============
  Future<List<Mob>> getAllMobs() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/mobs'),
      headers: _headers(),
    );
    final data = await _handleResponse(response);
    final list = _unwrapList(data, key: 'mobs');
    if (list.isEmpty) {
      // 回退到客户端内置怪物表
      return MobCatalog.templates.map((t) => Mob(
            id: t.mobId,
            mobId: t.mobId,
            name: t.name,
            level: t.level,
            hp: t.maxHp,
            maxHp: t.maxHp,
            attack: t.attack,
            defense: t.defense,
            expReward: t.expReward,
            mesoReward: t.mesoReward,
            posX: 0,
            posY: 0,
          )).toList();
    }
    return list.map((e) => Mob.fromJson(e)).toList();
  }

  Future<Mob> getMob(int id) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/mobs/$id'),
      headers: _headers(),
    );
    return Mob.fromJson(_unwrapMap(await _handleResponse(response)));
  }

  // ============= Skills APIs =============
  Future<List<Skill>> getAllSkills() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/skills'),
      headers: _headers(),
    );
    final data = await _handleResponse(response);
    final list = _unwrapList(data, key: 'skills');
    if (list.isEmpty) {
      return SkillCatalog.allSkills;
    }
    return list.map((e) => Skill.fromJson(e)).toList();
  }

  Future<Skill> getSkill(int id) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/skills/$id'),
      headers: _headers(),
    );
    return Skill.fromJson(_unwrapMap(await _handleResponse(response)));
  }

  // ============= Items APIs =============
  Future<List<Item>> getAllItems() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/items'),
      headers: _headers(),
    );
    final data = await _handleResponse(response);
    final list = _unwrapList(data, key: 'items');
    if (list.isEmpty) {
      return ItemCatalog.defaultItems;
    }
    return list.map((e) => Item.fromJson(e)).toList();
  }

  Future<Item> getItem(int id) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/items/$id'),
      headers: _headers(),
    );
    return Item.fromJson(await _handleResponse(response));
  }

  // ============= NPC APIs =============
  Future<Map<String, dynamic>> interactWithNPC({
    required int npcId,
    int? characterId,
    String action = 'talk',
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/npcs/interact/$npcId'),
      headers: _headers(),
      body: jsonEncode({
        'character_id': characterId,
        'action': action,
      }),
    );
    return await _handleResponse(response);
  }

  Future<List<Map<String, dynamic>>> getNPCsByMap(int mapId) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/npcs/map/$mapId'),
      headers: _headers(),
    );
    final data = await _handleResponse(response);
    final list = data['npcs'] as List? ?? [];
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> startNpcDialogue({
    required int npcId,
    required int characterId,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/npc/dialogue'),
      headers: _headers(),
      body: jsonEncode({
        'npcId': npcId,
        'characterId': characterId,
      }),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> continueNpcDialogue({
    required int npcId,
    required int characterId,
    required String nodeId,
    required int choiceIndex,
    String? nextId,
  }) async {
    final body = <String, dynamic>{
      'npcId': npcId,
      'characterId': characterId,
      'nodeId': nodeId,
      'choiceIndex': choiceIndex,
    };
    if (nextId != null && nextId.isNotEmpty) body['nextId'] = nextId;
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/npc/dialogue/continue'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return await _handleResponse(response);
  }

  Future<List<Map<String, dynamic>>> getShopItems(int npcId) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/shop/npc/$npcId'),
      headers: _headers(),
    );
    final data = await _handleResponse(response);
    if (data['success'] == true && data['items'] is List) {
      return (data['items'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    final list = data['items'] as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<int> buyShopItem({
    required int npcId,
    required int characterId,
    required int itemId,
    int quantity = 1,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/shop/npc/$npcId/buy'),
      headers: _headers(),
      body: jsonEncode({
        'character_id': characterId,
        'item_id': itemId,
        'quantity': quantity,
      }),
    );
    final data = await _handleResponse(response);
    if (data['success'] == true) {
      return (data['mesos'] as num?)?.toInt() ?? 0;
    }
    if (data['error'] != null) {
      throw Exception('${data['error']}');
    }
    return 0;
  }
}
