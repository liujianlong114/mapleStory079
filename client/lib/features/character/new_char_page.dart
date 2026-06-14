import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/resources/assets.dart';
import '../../core/resources/login_ui_assets.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../maple/maple_avatar_view.dart';
import '../maple/wz_scene.dart';
import '../maple/wz_widgets.dart';
import '../maple/wz_asset_image.dart';
import 'beginner_creation_catalog.dart';

/// ms079 Login.img/NewChar — charSet 245×193, charName 199×128, scroll 245×193, avatarSel×6
class NewCharPage extends StatefulWidget {
  final int jobType;

  const NewCharPage({super.key, this.jobType = BeginnerCreationCatalog.jobTypeAdventurer});

  @override
  State<NewCharPage> createState() => _NewCharPageState();
}

class _NewCharPageState extends State<NewCharPage> {
  WzSceneManifest? _scene;
  final _nameController = TextEditingController();
  late BeginnerLook _look;
  late int _gender;
  int _tab = 0;
  bool _scrollOpen = true;
  bool _busy = false;
  String? _error;
  String? _nameHint;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _gender = auth.accountGender == 1 ? 1 : 0;
    _look = BeginnerCreationCatalog.defaults(_gender)
        .copyWith(jobType: widget.jobType);
    WzSceneManifest.load('assets/scenes/login_newchar.json').then((m) {
      if (mounted) setState(() => _scene = m);
    });
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onNameChanged() async {
    final name = _nameController.text.trim();
    if (name.length < 2) {
      if (mounted) setState(() => _nameHint = null);
      return;
    }
    try {
      final ok = await ApiService().checkCharacterName(name);
      if (mounted) {
        setState(() => _nameHint = ok ? '名称可用' : '名称不可用');
      }
    } catch (_) {}
  }

  void _toggleScroll() {
    setState(() => _scrollOpen = !_scrollOpen);
    AudioManager().playSfx(SfxAssets.click);
  }

  void _cycleOption(int delta) {
    final opts = BeginnerCreationCatalog.optionsForTab(_look.gender, _tab);
    if (opts.isEmpty) return;
    final cur = BeginnerCreationCatalog.valueForTab(_look, _tab);
    var idx = opts.indexOf(cur);
    if (idx < 0) idx = 0;
    idx = (idx + delta) % opts.length;
    if (idx < 0) idx += opts.length;
    setState(() {
      _look = BeginnerCreationCatalog.withTabValue(_look, _tab, opts[idx]);
    });
    AudioManager().playSfx(SfxAssets.click);
  }

  void _randomize() {
    setState(() {
      _look = BeginnerCreationCatalog.random(_look.gender)
          .copyWith(name: _nameController.text);
    });
    AudioManager().playSfx(SfxAssets.click);
  }

  Future<void> _confirm() async {
    final name = _nameController.text.trim();
    if (name.length < 2 || name.length > 12) {
      setState(() => _error = '角色名 2~12 字符');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final accountId = Provider.of<AuthProvider>(context, listen: false).accountId;
    try {
      final available = await ApiService().checkCharacterName(name);
      if (!available) {
        setState(() {
          _error = '角色名不可用';
          _busy = false;
        });
        return;
      }
      await ApiService().createCharacter(
        accountId,
        name,
        0,
        look: _look,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_scene == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A1628),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFFB13A))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = math.min(
            constraints.maxWidth / 800,
            constraints.maxHeight / 600,
          );
          return Center(
            child: SizedBox(
              width: 800 * scale,
              height: 600 * scale,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 800,
                  height: 600,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      WzSceneScreen(
                        manifest: _scene!,
                        slotOverlays: const [],
                        playBgm: true,
                        onButton: (_) {},
                      ),
                      _buildNewCharUi(),
                      if (_error != null) _errorBanner(_error!),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _errorBanner(String msg) {
    return Positioned(
      top: 8,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: Colors.black87,
          child: Text(msg, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildNewCharUi() {
    final tabLabel = BeginnerCreationCatalog.tabLabels[_tab];
    final curVal = BeginnerCreationCatalog.valueForTab(_look, _tab);
    final valLabel = BeginnerCreationCatalog.labelForTabValue(_tab, curVal);

    return Stack(
      children: [
        // Login.img/NewChar/charSet 245×193
        Positioned(
          left: 38,
          top: 198,
          child: WzPanelFrame(
            assetPath: LoginUiAssets.newCharSet,
            width: 245,
            height: 193,
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: MapleAvatarView(
                      gender: _gender,
                      face: _look.face,
                      hair: _look.hair,
                      top: _look.top,
                      bottom: _look.bottom,
                      shoes: _look.shoes,
                      weapon: _look.weapon,
                      height: 100,
                    ),
                  ),
                ),
                Text(
                  'Lv.1 新手',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Login.img/NewChar/charName 199×128
        Positioned(
          left: 553,
          top: 118,
          child: WzPanelFrame(
            assetPath: LoginUiAssets.newCharName,
            width: 199,
            height: 128,
            padding: const EdgeInsets.fromLTRB(14, 36, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameController,
                  maxLength: 12,
                  style: const TextStyle(color: Color(0xFF2E1A0E), fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    counterText: '',
                    hintText: '输入角色名',
                    hintStyle: const TextStyle(color: Color(0xFF8D6E63), fontSize: 11),
                    filled: true,
                    fillColor: const Color(0xFFF5E6C8).withValues(alpha: 0.6),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
                if (_nameHint != null)
                  Text(
                    _nameHint!,
                    style: TextStyle(
                      color: _nameHint == '名称可用'
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFE65100),
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Login.img/NewChar/scroll 245×193
        Positioned(
          left: 303,
          top: _scrollOpen ? 215 : 378,
          child: GestureDetector(
            onTap: _toggleScroll,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 245,
              height: _scrollOpen ? 193 : 28,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  WzAssetImage(
                    candidates: [
                      _scrollOpen ? LoginUiAssets.scrollOpen : LoginUiAssets.scrollClosed,
                    ],
                    width: 245,
                    height: _scrollOpen ? 193 : 28,
                  ),
                  if (_scrollOpen)
                    Positioned(
                      left: 8,
                      top: 36,
                      child: Column(
                        children: [
                          for (var i = 0; i < BeginnerCreationCatalog.tabLabels.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 1),
                              child: WzAvatarTab(
                                label: BeginnerCreationCatalog.tabLabels[i],
                                selected: i == _tab,
                                onTap: () {
                                  AudioManager().playSfx(SfxAssets.click);
                                  setState(() => _tab = i);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (_scrollOpen)
                    Positioned(
                      left: 175,
                      top: 48,
                      width: 60,
                      child: Column(
                        children: [
                          Text(
                            tabLabel,
                            style: const TextStyle(
                              color: Color(0xFF3B2414),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            valLabel,
                            style: const TextStyle(color: Color(0xFF5D4037), fontSize: 10),
                          ),
                        ],
                      ),
                    )
                  else
                    Center(
                      child: Text(
                        tabLabel,
                        style: const TextStyle(
                          color: Color(0xFF3B2414),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // dice 37×26
        Positioned(
          left: 548,
          top: 232,
          child: WzSpriteButton(
            normal: LoginUiAssets.dice,
            width: 37,
            height: 26,
            onPressed: _randomize,
            fallbackLabel: '骰',
          ),
        ),
        // BtLeft / BtRight
        Positioned(left: 318, top: 368, child: WzArrowButton(onPressed: () => _cycleOption(-1))),
        Positioned(
          left: 518,
          top: 368,
          child: WzArrowButton(right: true, onPressed: () => _cycleOption(1)),
        ),
        // BtYes / BtNo 85×29
        Positioned(
          bottom: 38,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              WzSpriteButton(
                normal: LoginUiAssets.buttonStates('btn_no').first,
                hover: LoginUiAssets.buttonOverStates('btn_no').first,
                width: 85,
                height: 29,
                onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                fallbackLabel: '取消',
              ),
              const SizedBox(width: 24),
              WzSpriteButton(
                normal: LoginUiAssets.buttonStates('btn_yes').first,
                hover: LoginUiAssets.buttonOverStates('btn_yes').first,
                width: 85,
                height: 29,
                onPressed: _busy ? null : _confirm,
                fallbackLabel: _busy ? '...' : '确定',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
