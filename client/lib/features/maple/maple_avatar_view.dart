import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'maple_ui.dart';
import 'wz_asset_image.dart';

/// 079 新手预览 — 优先 WZ 提取的 stand1 精灵（assets/characters/parts/），否则简易预览
class MapleAvatarView extends StatefulWidget {
  final int gender;
  final int face;
  final int hair;
  final int top;
  final int bottom;
  final int shoes;
  final int weapon;
  final double scale;

  const MapleAvatarView({
    super.key,
    required this.gender,
    required this.face,
    required this.hair,
    required this.top,
    required this.bottom,
    required this.shoes,
    required this.weapon,
    this.scale = 1.0,
  });

  @override
  State<MapleAvatarView> createState() => _MapleAvatarViewState();
}

class _MapleAvatarViewState extends State<MapleAvatarView> {
  bool _spritesAvailable = false;
  bool _checked = false;

  static const _base = 'characters/parts';

  int get _bodyId => widget.gender == 1 ? 2001 : 2000;

  List<int> get _partIds => [
        _bodyId,
        widget.bottom,
        widget.top,
        widget.shoes,
        widget.face,
        widget.hair,
        if (widget.weapon != 0) widget.weapon,
      ];

  @override
  void initState() {
    super.initState();
    _probeSprites();
  }

  @override
  void didUpdateWidget(covariant MapleAvatarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.face != widget.face ||
        oldWidget.hair != widget.hair ||
        oldWidget.top != widget.top ||
        oldWidget.bottom != widget.bottom ||
        oldWidget.shoes != widget.shoes ||
        oldWidget.weapon != widget.weapon ||
        oldWidget.gender != widget.gender) {
      _checked = false;
      _spritesAvailable = false;
      _probeSprites();
    }
  }

  Future<void> _probeSprites() async {
    if (_checked) return;
    var ok = false;
    for (final id in _partIds) {
      try {
        await rootBundle.load('assets/$_base/$id.png');
        ok = true;
        break;
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _spritesAvailable = ok;
        _checked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_spritesAvailable) {
      return MapleCharacterPreview(
        gender: widget.gender,
        faceId: widget.face,
        hairId: widget.hair,
        topId: widget.top,
        bottomId: widget.bottom,
        shoesId: widget.shoes,
        weaponId: widget.weapon,
        scale: widget.scale * 1.15,
      );
    }

    return SizedBox(
      width: 110 * widget.scale,
      height: 130 * widget.scale,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          for (final id in _partIds)
            WzAssetImage(
              candidates: ['$_base/$id.png'],
              width: 100 * widget.scale,
              height: 120 * widget.scale,
              fit: BoxFit.contain,
              fallback: (_) => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}
