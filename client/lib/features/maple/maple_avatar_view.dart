import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/resources/assets.dart';
import '../../core/resources/avatar_assets.dart';
import '../../game/engine/character_part_composer.dart';
import 'wz_asset_image.dart';

/// 079 选角立绘 — WZ 合成 avatars/*.png，放大显示像素风角色
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
  bool _avatarReady = false;
  bool _useParts = false;
  bool _checked = false;

  List<String> get _candidates => AvatarAssets.candidatePaths(
        gender: widget.gender,
        face: widget.face,
        hair: widget.hair,
        top: widget.top,
        bottom: widget.bottom,
        shoes: widget.shoes,
        weapon: widget.weapon,
      );

  @override
  void initState() {
    super.initState();
    _probeAvatar();
  }

  @override
  void didUpdateWidget(covariant MapleAvatarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gender != widget.gender ||
        oldWidget.face != widget.face ||
        oldWidget.hair != widget.hair ||
        oldWidget.top != widget.top ||
        oldWidget.bottom != widget.bottom ||
        oldWidget.shoes != widget.shoes ||
        oldWidget.weapon != widget.weapon) {
      _checked = false;
      _avatarReady = false;
      _useParts = false;
      _probeAvatar();
    }
  }

  Future<void> _probeAvatar() async {
    if (_checked) return;
    var ok = false;
    for (final path in _candidates) {
      try {
        final data = await rootBundle.load(AssetPaths.bundle(path));
        if (data.lengthInBytes >= 400) {
          ok = true;
          break;
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _avatarReady = ok;
        _useParts = !ok;
        _checked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = 96.0 * widget.scale;
    final h = 118.0 * widget.scale;
    if (!_checked) {
      return SizedBox(
        width: w,
        height: h,
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFB13A)),
          ),
        ),
      );
    }
    if (_useParts) {
      return SizedBox(
        width: w,
        height: h,
        child: _PartsAvatar(
          gender: widget.gender,
          face: widget.face,
          hair: widget.hair,
          top: widget.top,
          bottom: widget.bottom,
          shoes: widget.shoes,
          weapon: widget.weapon,
        ),
      );
    }
    return SizedBox(
      width: w,
      height: h,
      child: WzAssetImage(
        candidates: _candidates,
        fit: BoxFit.contain,
        fallback: (_) => _PartsAvatar(
          gender: widget.gender,
          face: widget.face,
          hair: widget.hair,
          top: widget.top,
          bottom: widget.bottom,
          shoes: widget.shoes,
          weapon: widget.weapon,
        ),
      ),
    );
  }
}

class _PartsAvatar extends StatelessWidget {
  final int gender;
  final int face;
  final int hair;
  final int top;
  final int bottom;
  final int shoes;
  final int weapon;

  const _PartsAvatar({
    required this.gender,
    required this.face,
    required this.hair,
    required this.top,
    required this.bottom,
    required this.shoes,
    required this.weapon,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: CharacterPartComposer.composeStand(
        gender: gender,
        face: face,
        hair: hair,
        top: top,
        bottom: bottom,
        shoes: shoes,
        weapon: weapon,
      ),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFB13A)),
            ),
          );
        }
        final sprite = snap.data;
        if (sprite == null) {
          return const Icon(Icons.person, size: 48, color: Colors.white38);
        }
        return RawImage(
          image: sprite.image,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
        );
      },
    );
  }
}
