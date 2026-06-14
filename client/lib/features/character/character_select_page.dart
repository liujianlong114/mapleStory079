import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/character.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';

class CharacterSelectPage extends StatefulWidget {
  const CharacterSelectPage({super.key});

  @override
  State<CharacterSelectPage> createState() => _CharacterSelectPageState();
}

class _CharacterSelectPageState extends State<CharacterSelectPage> {
  bool _isLoading = true;
  List<Character> _characters = [];
  int? _selectedIndex;

  final _newNameController = TextEditingController();

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
      await Future<void>.delayed(const Duration(milliseconds: 200));
      _characters = List<Character>.from(auth.characters);
      if (_characters.isEmpty) {
        _characters = [
          Character(
            id: 1,
            accountId: auth.accountId,
            name: '小冒险',
            characterClass: 1,
            gender: 0,
            level: 10,
            experience: 500,
            mapId: 1,
            positionX: 0,
            positionY: 0,
            hp: 200,
            maxHp: 200,
            mp: 50,
            maxMp: 50,
            str: 20,
            dex: 10,
            intl: 8,
            luk: 5,
            mesos: 1234,
          ),
          Character(
            id: 2,
            accountId: auth.accountId,
            name: '法师酱',
            characterClass: 2,
            gender: 1,
            level: 25,
            experience: 1500,
            mapId: 2,
            positionX: 0,
            positionY: 0,
            hp: 180,
            maxHp: 180,
            mp: 400,
            maxMp: 400,
            str: 5,
            dex: 12,
            intl: 60,
            luk: 20,
            mesos: 3200,
          ),
        ];
      }
      if (_characters.isNotEmpty) _selectedIndex = 0;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _enterGame() {
    if (_selectedIndex == null) return;
    final character = _characters[_selectedIndex!];
    final game = Provider.of<GameProvider>(context, listen: false);
    game.loadCharacterState(character.id);
    Navigator.of(context).pushReplacementNamed('/game-scene');
  }

  void _deleteCharacter() {
    if (_selectedIndex == null) return;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除角色'),
        content: Text('确定要删除角色「${_characters[_selectedIndex!].name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确定删除'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != true) return;
      setState(() {
        _characters.removeAt(_selectedIndex!);
        _selectedIndex = _characters.isEmpty ? null : 0;
      });
    });
  }

  void _openCreateDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => _CreateCharacterDialog(
        controller: _newNameController,
        onCreate: (name, cls) {
          if (name.trim().length < 2) return;
          final newChar = Character(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            accountId: 0,
            name: name.trim(),
            characterClass: cls,
            gender: 0,
            level: 1,
            experience: 0,
            mapId: 1,
            positionX: 0,
            positionY: 0,
            hp: 100,
            maxHp: 100,
            mp: 30,
            maxMp: 30,
            str: 10,
            dex: 8,
            intl: 6,
            luk: 4,
            mesos: 500,
          );
          setState(() {
            _characters.add(newChar);
            _selectedIndex = _characters.length - 1;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.mapleGradientBackground(),
        child: Center(
          child: SizedBox(
            width: 900,
            height: 600,
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: _buildCharacterGrid()),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: _buildDetailPanel()),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildBottomAction(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF3B2414),
        border: Border.all(color: const Color(0xFFD4A373), width: 3),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '选择角色',
            style: TextStyle(
              color: Color(0xFFFFB13A),
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                  color: Color(0xFF8B0000),
                  blurRadius: 2,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _loadCharacters,
                icon: const Icon(Icons.refresh, color: Color(0xFFFFD700), size: 26),
                tooltip: '刷新',
              ),
              IconButton(
                onPressed: () {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                icon: const Icon(Icons.logout, color: Color(0xFFFFD700), size: 26),
                tooltip: '登出',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterGrid() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF5D3A1A),
        ),
      );
    }

    if (_characters.isEmpty) {
      return _buildEmptyPanel();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF3E0),
        border: Border.all(color: const Color(0xFF5D3A1A), width: 3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 120 / 180,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _characters.length,
        itemBuilder: (ctx, i) {
          final character = _characters[i];
          final selected = _selectedIndex == i;
          return _CharacterCard(
            character: character,
            selected: selected,
            onTap: () => setState(() => _selectedIndex = i),
          );
        },
      ),
    );
  }

  Widget _buildEmptyPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF3E0),
        border: Border.all(color: const Color(0xFF5D3A1A), width: 3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          '还没有角色，点击下方「创建角色」开始冒险！',
          style: TextStyle(
            color: Color(0xFF5D3A1A),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDetailPanel() {
    final character =
        (_selectedIndex != null && _characters.isNotEmpty)
            ? _characters[_selectedIndex!]
            : null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFAF3E0), Color(0xFFE8D9B5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: const Color(0xFF5D3A1A), width: 3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: character == null
          ? const Center(
              child: Text(
                '请选择一个角色',
                style: TextStyle(
                  color: Color(0xFF5D3A1A),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            )
          : _CharacterDetail(character: character),
    );
  }

  Widget _buildBottomAction() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          label: '创建角色',
          gradient: const LinearGradient(
            colors: [Color(0xFF6BBF59), Color(0xFF3C8D2F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          icon: Icons.add_circle,
          onPressed: _openCreateDialog,
        ),
        _ActionButton(
          label: '删除',
          gradient: const LinearGradient(
            colors: [Color(0xFFE57373), Color(0xFFB71C1C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          icon: Icons.delete_forever,
          onPressed: _selectedIndex == null ? null : _deleteCharacter,
        ),
        _ActionButton(
          label: '进入游戏',
          gradient: const LinearGradient(
            colors: [Color(0xFFFFEB3B), Color(0xFFFFB300)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          icon: Icons.play_arrow,
          textColor: const Color(0xFF5D3A1A),
          onPressed: _selectedIndex == null ? null : _enterGame,
        ),
      ],
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final Character character;
  final bool selected;
  final VoidCallback onTap;

  const _CharacterCard({
    required this.character,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _classColor(character.characterClass);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.55), color.withOpacity(0.25)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(
          color: selected ? const Color(0xFFD2691E) : const Color(0xFF5D3A1A),
          width: selected ? 4 : 3,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: const Color(0xFFD2691E).withOpacity(0.45),
              blurRadius: 10,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Column(
            children: [
              if (selected)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD2691E),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                      Text(
                        '已选择',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(height: 4),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 70,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.9), color.withOpacity(0.5)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        border: Border.all(
                          color: const Color(0xFF3B2414),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Icon(
                          _classIcon(character.characterClass),
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF3B2414),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        character.name,
                        style: const TextStyle(
                          color: Color(0xFF1C1C1C),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B2414),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Lv.${character.level}',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
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

  static Color _classColor(int cls) {
    switch (cls) {
      case 1:
        return const Color(0xFFC62828);
      case 2:
        return const Color(0xFF1E88E5);
      case 3:
        return const Color(0xFFFFB300);
      case 4:
        return const Color(0xFF6A1B9A);
      case 5:
        return const Color(0xFF00838F);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  static IconData _classIcon(int cls) {
    switch (cls) {
      case 1:
        return Icons.sports_martial_arts;
      case 2:
        return Icons.auto_awesome;
      case 3:
        return Icons.psychology_alt;
      case 4:
        return Icons.dark_mode;
      case 5:
        return Icons.sailing;
      default:
        return Icons.person;
    }
  }
}

class _CharacterDetail extends StatelessWidget {
  final Character character;

  const _CharacterDetail({required this.character});

  @override
  Widget build(BuildContext context) {
    final className = _CharacterCard._classColor(character.characterClass);
    final classLabel = _jobLabel(character.characterClass);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            character.name,
            style: const TextStyle(
              color: Color(0xFF5D3A1A),
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: className,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF3B2414), width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      '职业',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      classLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 2,
                  height: 30,
                  color: Colors.white54,
                ),
                Column(
                  children: [
                    const Text(
                      '等级',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lv.${character.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              border: Border.all(color: const Color(0xFF5D3A1A), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildStatRow(Icons.favorite, 'HP', '${character.hp} / ${character.maxHp}'),
                const SizedBox(height: 8),
                _buildStatRow(Icons.auto_fix_high, 'MP', '${character.mp} / ${character.maxMp}'),
                const SizedBox(height: 8),
                _buildStatRow(Icons.fitness_center, '力量 STR', character.str.toString()),
                const SizedBox(height: 8),
                _buildStatRow(Icons.bolt, '敏捷 DEX', character.dex.toString()),
                const SizedBox(height: 8),
                _buildStatRow(Icons.lightbulb, '智力 INT', character.intl.toString()),
                const SizedBox(height: 8),
                _buildStatRow(Icons.star, '幸运 LUK', character.luk.toString()),
                const SizedBox(height: 8),
                _buildStatRow(Icons.monetization_on, '金币 Mesos', character.mesos.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF5D3A1A), size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF5D3A1A),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1C1C1C),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  String _jobLabel(int cls) {
    switch (cls) {
      case 1:
        return '战士';
      case 2:
        return '法师';
      case 3:
        return '弓箭手';
      case 4:
        return '飞侠';
      case 5:
        return '海盗';
      default:
        return '新手';
    }
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final Gradient gradient;
  final IconData icon;
  final Color? textColor;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.gradient,
    required this.icon,
    this.textColor,
    this.onPressed,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  double _translateY = 0;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    return MouseRegion(
      onEnter: (_) => setState(() => _translateY = -2),
      onExit: (_) => setState(() => _translateY = 0),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _translateY, 0),
          width: 180,
          height: 48,
          decoration: BoxDecoration(
            gradient: disabled
                ? const LinearGradient(
                    colors: [Color(0xFFA0A0A0), Color(0xFF707070)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : widget.gradient,
            border: Border.all(
              color: const Color(0xFF3B2414),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: disabled ? 2 : 6,
                offset: Offset(0, disabled ? 1 : _translateY.abs() + 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: widget.textColor ?? Colors.white,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.textColor ?? Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(1, 1),
                      blurRadius: 1,
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

class _CreateCharacterDialog extends StatefulWidget {
  final TextEditingController controller;
  final void Function(String name, int cls) onCreate;

  const _CreateCharacterDialog({
    required this.controller,
    required this.onCreate,
  });

  @override
  State<_CreateCharacterDialog> createState() => _CreateCharacterDialogState();
}

class _CreateCharacterDialogState extends State<_CreateCharacterDialog> {
  int _selectedClass = 1;

  static const List<int> _classes = [1, 2, 3, 4, 5];
  static const Map<int, String> _classNames = {
    1: '战士',
    2: '法师',
    3: '弓箭手',
    4: '飞侠',
    5: '海盗',
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFAF3E0),
      title: const Text(
        '创建新角色',
        style: TextStyle(
          color: Color(0xFF5D3A1A),
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.controller,
            maxLength: 12,
            style: const TextStyle(color: Color(0xFF1C1C1C)),
            decoration: AppTheme.mapleInputDecoration('角色名', Icons.person),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '选择职业',
              style: TextStyle(
                color: Color(0xFF5D3A1A),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _classes.map((cls) {
              final selected = _selectedClass == cls;
              final color = _CharacterCard._classColor(cls);
              return GestureDetector(
                onTap: () => setState(() => _selectedClass = cls),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? color : Colors.white,
                    border: Border.all(
                      color: const Color(0xFF5D3A1A),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _classNames[cls]!,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF1C1C1C),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          style: AppTheme.mapleButtonStyle(),
          onPressed: () {
            final name = widget.controller.text.trim();
            if (name.isEmpty) return;
            widget.onCreate(name, _selectedClass);
            widget.controller.clear();
            Navigator.of(context).pop();
          },
          child: const Text('创建'),
        ),
      ],
    );
  }
}
