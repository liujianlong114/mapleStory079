import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../models/character.dart';

class CharacterSelectPage extends StatefulWidget {
  const CharacterSelectPage({super.key});

  @override
  State<CharacterSelectPage> createState() => _CharacterSelectPageState();
}

class _CharacterSelectPageState extends State<CharacterSelectPage> {
  bool _isLoading = true;
  List<Character> _characters = [];
  String? _errorMessage;

  int _newClass = 1;
  final _newNameController = TextEditingController();
  bool _creating = false;

  static const _classOptions = <int, String>{
    0: '新手',
    1: '战士',
    2: '法师',
    3: '弓箭手',
    4: '飞侠',
    5: '海盗',
  };
  static const _classColors = <int, Color>{
    0: Colors.grey,
    1: Colors.red,
    2: Colors.blue,
    3: Colors.green,
    4: Colors.purple,
    5: Colors.amber,
  };

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  @override
  void dispose() {
    _newNameController.dispose();
    super.dispose();
  }

  Future<void> _loadCharacters() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final url = Uri.parse(
        '${AppConfig.apiBaseUrl}/characters/?account_id=${auth.accountId}',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['data'] as List?) ?? [];
        _characters = list.map((e) => Character.fromMap(e as Map<String, dynamic>)).toList();
      } else {
        _characters = [];
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createCharacter() async {
    if (_newNameController.text.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('角色名至少 2 个字符')),
      );
      return;
    }
    setState(() => _creating = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final url = Uri.parse('${AppConfig.apiBaseUrl}/characters/');
      final response = await http.post(
        url,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'account_id': auth.accountId,
          'name': _newNameController.text.trim(),
          'class': _newClass,
          'gender': 0,
        }),
      );
      if (response.statusCode == 200) {
        _newNameController.clear();
        await _loadCharacters();
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err['message'] ?? '创建失败')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建失败: $e')),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _selectCharacter(Character character) async {
    final game = Provider.of<GameProvider>(context, listen: false);
    await game.loadCharacterState(character.id);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/game');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择角色'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadCharacters,
            icon: const Icon(Icons.refresh, color: Colors.amber),
          ),
          IconButton(
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            icon: const Icon(Icons.logout, color: Colors.amber),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF16213e), Color(0xFF0f3460)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.amber))
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '我的角色',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      flex: 2,
                      child: _characters.isEmpty
                          ? const Center(
                              child: Text(
                                '还没有角色，快去创建一个吧！',
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _characters.length,
                              itemBuilder: (ctx, i) {
                                final c = _characters[i];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: _CharacterCard(
                                    character: c,
                                    onTap: () => _selectCharacter(c),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '创建新角色',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _newNameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: '角色名',
                              border: OutlineInputBorder(),
                              labelStyle: TextStyle(color: Colors.amber),
                            ),
                            maxLength: 12,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: _classOptions.entries
                                .map((e) => ChoiceChip(
                                      label: Text(e.value),
                                      selected: _newClass == e.key,
                                      selectedColor: _classColors[e.key]?.withOpacity(0.6),
                                      backgroundColor: Colors.black26,
                                      labelStyle: const TextStyle(color: Colors.white),
                                      onSelected: (_) => setState(() => _newClass = e.key),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _creating ? null : _createCharacter,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black87,
                              ),
                              child: _creating
                                  ? const CircularProgressIndicator(color: Colors.black)
                                  : const Text('创建角色'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final Character character;
  final VoidCallback onTap;

  const _CharacterCard({required this.character, required this.onTap});

  static const _classIcons = {
    0: Icons.person_outline,
    1: Icons.sports_martial_arts,
    2: Icons.auto_awesome,
    3: Icons.keyboard_arrow_up,
    4: Icons.dark_mode,
    5: Icons.sailing,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _classIcons[character.characterClass] ?? Icons.person,
              size: 48,
              color: Colors.amber,
            ),
            const SizedBox(height: 8),
            Text(
              character.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Lv.${character.level}  ${character.className}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              '点击进入冒险',
              style: TextStyle(color: Colors.amber.shade200, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
