import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/resources/assets.dart';
import '../../models/character.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../services/api_service.dart';
import '../maple/maple_avatar_view.dart';
import '../maple/wz_scene.dart';
import '../login/race_select_page.dart';

/// 079 风格角色选择（MapLogin2 + Login.img CharSelect）
class CharacterSelectPage extends StatefulWidget {
  const CharacterSelectPage({super.key});

  @override
  State<CharacterSelectPage> createState() => _CharacterSelectPageState();
}

class _CharacterSelectPageState extends State<CharacterSelectPage> {
  WzSceneManifest? _scene;
  bool _isLoading = true;
  String? _errorMessage;
  List<Character> _characters = [];
  int? _selectedSlot;
  int _page = 0; // 079 CharSelect pageL/pageR，每页 3 槽共 6 槽

  static const _slotsPerPage = 3;
  static const _maxSlots = 6;

  @override
  void initState() {
    super.initState();
    WzSceneManifest.load('assets/scenes/login_charselect.json').then((m) {
      if (mounted) setState(() => _scene = m);
    });
    _loadCharacters();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadCharacters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.accountId <= 0) throw Exception('账号未登录');
      await auth.loadCharacters();
      _characters = List<Character>.from(auth.characters);
      if (_characters.isNotEmpty && _selectedSlot == null) _selectedSlot = 0;
      if (_selectedSlot != null && _selectedSlot! >= _characters.length) {
        _selectedSlot = _characters.isEmpty ? null : 0;
      }
    } catch (e) {
      _characters = [];
      _errorMessage = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Character? get _selectedCharacter {
    if (_selectedSlot == null) return null;
    if (_selectedSlot! >= _characters.length) return null;
    return _characters[_selectedSlot!];
  }

  int get _pageStart => _page * _slotsPerPage;

  Future<void> _enterGame() async {
    final c = _selectedCharacter;
    if (c == null) return;
    final game = Provider.of<GameProvider>(context, listen: false);
    final ok = await game.loadCharacterState(c.id);
    if (!ok && mounted) {
      setState(() => _errorMessage = game.errorMessage ?? '无法进入游戏');
      return;
    }
    if (mounted) {
      await AudioManager().stopBgm();
      Navigator.of(context).pushReplacementNamed('/game-scene');
    }
  }

  void _onSceneButton(String id) async {
    if (id == 'select') {
      await _enterGame();
    } else if (id == 'new') {
      await _openCreatePage();
    } else if (id == 'delete') {
      await _deleteCharacter();
    } else if (id == 'page_prev' && _page > 0) {
      setState(() {
        _page--;
        if (_selectedSlot != null && _selectedSlot! < _pageStart) {
          _selectedSlot = _pageStart;
        }
      });
    } else if (id == 'page_next' && (_page + 1) * _slotsPerPage < _maxSlots) {
      setState(() {
        _page++;
        if (_selectedSlot != null && _selectedSlot! >= _pageStart + _slotsPerPage) {
          _selectedSlot = _pageStart;
        }
      });
    }
  }

  Future<void> _deleteCharacter() async {
    final c = _selectedCharacter;
    if (c == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除角色'),
        content: Text('确定删除「${c.name}」？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定')),
        ],
      ),
    );
    if (ok != true) return;
    await ApiService().deleteCharacter(c.id);
    await _loadCharacters();
  }

  Future<void> _openCreatePage() async {
    if (_characters.length >= _maxSlots) {
      setState(() => _errorMessage = '角色栏已满（最多 $_maxSlots 个）');
      return;
    }
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const RaceSelectPage()),
    );
    if (created == true) {
      await _loadCharacters();
      if (mounted) {
        setState(() {
          _selectedSlot = _characters.isEmpty ? null : _characters.length - 1;
          _errorMessage = null;
        });
      }
    }
  }

  List<Widget> _slotOverlays() {
    return List.generate(_slotsPerPage, (local) {
      final global = _pageStart + local;
      if (global >= _characters.length) {
        return const Center(
          child: Text('空', style: TextStyle(color: Colors.white54, fontSize: 16)),
        );
      }
      final c = _characters[global];
      return GestureDetector(
        onTap: () {
          AudioManager().playSfx(SfxAssets.click);
          setState(() => _selectedSlot = global);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: MapleAvatarView(
              gender: c.gender,
              face: c.face,
              hair: c.hair,
              top: c.top,
              bottom: c.bottom,
              shoes: c.shoes,
              weapon: c.weapon,
              cap: c.cap,
              cape: c.cape,
              glove: c.glove,
              shield: c.shield,
              faceAcc: c.faceAcc,
              eyeAcc: c.eyeAcc,
              earring: c.earring,
              longcoat: c.longcoat,
              height: 110,
            ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: const Color(0xFF3B2414),
              child: Text(
                c.name,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              'Lv.${c.level} ${c.className}',
              style: const TextStyle(color: Color(0xFFFFD700), fontSize: 10),
            ),
          ],
        ),
      );
    });
  }

  int? get _localSelectedSlot {
    if (_selectedSlot == null) return null;
    final local = _selectedSlot! - _pageStart;
    if (local < 0 || local >= _slotsPerPage) return null;
    return local;
  }

  @override
  Widget build(BuildContext context) {
    if (_scene == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFFB13A))),
      );
    }

    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      body: Stack(
        children: [
          WzSceneScreen(
            manifest: _scene!,
            selectedSlot: _localSelectedSlot,
            slotOverlays: _slotOverlays(),
            onButton: _onSceneButton,
          ),
          if (_isLoading)
            const ColoredBox(
              color: Colors.black45,
              child: Center(child: CircularProgressIndicator(color: Color(0xFFFFB13A))),
            ),
          Positioned(
            top: 8,
            left: 12,
            child: Row(
              children: [
                Text(
                  auth.username,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFFFFD700), size: 20),
                  onPressed: _loadCharacters,
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Color(0xFFFFD700), size: 20),
                  onPressed: () async {
                    await AudioManager().stopBgm();
                    auth.logout();
                    if (mounted) Navigator.of(context).pushReplacementNamed('/login');
                  },
                ),
              ],
            ),
          ),
          if (_errorMessage != null)
            Positioned(
              top: 48,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: Colors.black54,
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
