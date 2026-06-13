import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
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
        return jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {
        return {'raw': body};
      }
    }
    throw Exception('API Error (${response.statusCode}): $body');
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
    if (data['token'] != null) {
      _token = data['token'] as String;
    }
    return data;
  }

  Future<Character> createCharacter(int accountId, String name, int characterClass,
      {int hair = 0, int skin = 0, int eyes = 0}) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/characters'),
      headers: _headers(),
      body: jsonEncode({
        'account_id': accountId,
        'name': name,
        'class': characterClass,
        'hair': hair,
        'skin': skin,
        'eyes': eyes,
      }),
    );

    final data = await _handleResponse(response);
    return Character.fromJson(data);
  }

  Future<List<Character>> getCharacters(int accountId) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/characters'),
      headers: _headers(),
    );

    final data = await _handleResponse(response);
    final list = data['characters'] as List? ?? [];
    return list.map((e) => Character.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Character> getCharacter(int id) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/characters/$id'),
      headers: _headers(),
    );

    final data = await _handleResponse(response);
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
    final list = data['maps'] as List? ?? [];
    return list.map((e) => GameMap.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<GameMap> getMap(int id) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/maps/$id'),
      headers: _headers(),
    );

    final data = await _handleResponse(response);
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
  }

  Future<Map<String, dynamic>> playerAttackMob({
    required int characterId,
    required int mobId,
    int? skillId,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/combat/player-attack-mob'),
      headers: _headers(),
      body: jsonEncode({
        'character_id': characterId,
        'mob_id': mobId,
        'skill_id': skillId,
      }),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> mobAttackPlayer({
    required int characterId,
    required int mobId,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/combat/mob-attack-player'),
      headers: _headers(),
      body: jsonEncode({
        'character_id': characterId,
        'mob_id': mobId,
      }),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> getCombatStats(int characterId) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/combat/stats?character_id=$characterId'),
      headers: _headers(),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> reviveCharacter(int characterId) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/combat/revive'),
      headers: _headers(),
      body: jsonEncode({'character_id': characterId}),
    );
    return await _handleResponse(response);
  }

  // ============= Mobs APIs =============
  Future<List<Mob>> getAllMobs() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/mobs'),
      headers: _headers(),
    );
    final data = await _handleResponse(response);
    final list = data['mobs'] as List? ?? [];
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
    return list.map((e) => Mob.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Mob> getMob(int id) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/mobs/$id'),
      headers: _headers(),
    );
    return Mob.fromJson(await _handleResponse(response));
  }

  // ============= Skills APIs =============
  Future<List<Skill>> getAllSkills() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/skills'),
      headers: _headers(),
    );
    final data = await _handleResponse(response);
    final list = data['skills'] as List? ?? [];
    if (list.isEmpty) {
      return SkillCatalog.allSkills;
    }
    return list.map((e) => Skill.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Skill> getSkill(int id) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/skills/$id'),
      headers: _headers(),
    );
    return Skill.fromJson(await _handleResponse(response));
  }

  // ============= Items APIs =============
  Future<List<Item>> getAllItems() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/items'),
      headers: _headers(),
    );
    final data = await _handleResponse(response);
    final list = data['items'] as List? ?? [];
    if (list.isEmpty) {
      return ItemCatalog.defaultItems;
    }
    return list.map((e) => Item.fromJson(e as Map<String, dynamic>)).toList();
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
}
