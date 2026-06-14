import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/resources/assets.dart';

/// 079 登录/选角场景（800×600，按 WZ manifest 布局）
class WzSceneManifest {
  final int width;
  final int height;
  final String bgm;
  final String background;
  final WzSpriteRef? logo;
  final List<WzRect> slots;
  final List<WzButtonDef> buttons;
  final WzRect? loginPanel;

  WzSceneManifest({
    required this.width,
    required this.height,
    required this.bgm,
    required this.background,
    this.logo,
    this.slots = const [],
    this.buttons = const [],
    this.loginPanel,
  });

  factory WzSceneManifest.fromJson(Map<String, dynamic> json) {
    return WzSceneManifest(
      width: (json['width'] as num?)?.toInt() ?? 800,
      height: (json['height'] as num?)?.toInt() ?? 600,
      bgm: json['bgm'] as String? ?? BgmAssets.title,
      background: json['background'] as String? ?? '',
      logo: json['logo'] != null
          ? WzSpriteRef.fromJson(json['logo'] as Map<String, dynamic>)
          : null,
      slots: (json['slots'] as List?)
              ?.map((e) => WzRect.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      buttons: (json['buttons'] as List?)
              ?.map((e) => WzButtonDef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      loginPanel: json['login_panel'] != null
          ? WzRect.fromJson(json['login_panel'] as Map<String, dynamic>)
          : null,
    );
  }

  static Future<WzSceneManifest> load(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return WzSceneManifest.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }
}

class WzRect {
  final double x, y, w, h;
  const WzRect({required this.x, required this.y, required this.w, required this.h});
  factory WzRect.fromJson(Map<String, dynamic> j) => WzRect(
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        w: (j['w'] as num).toDouble(),
        h: (j['h'] as num).toDouble(),
      );
  Rect toRect() => Rect.fromLTWH(x, y, w, h);
}

class WzSpriteRef {
  final String path;
  final double x, y, w, h;
  final List<String> frames;
  final int fadeMs;
  WzSpriteRef({
    required this.path,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.frames = const [],
    this.fadeMs = 8000,
  });
  factory WzSpriteRef.fromJson(Map<String, dynamic> j) => WzSpriteRef(
        path: j['path'] as String? ?? '',
        x: (j['x'] as num?)?.toDouble() ?? 0,
        y: (j['y'] as num?)?.toDouble() ?? 0,
        w: (j['w'] as num?)?.toDouble() ?? 0,
        h: (j['h'] as num?)?.toDouble() ?? 0,
        frames: (j['frames'] as List?)?.cast<String>() ?? [],
        fadeMs: (j['fade_ms'] as num?)?.toInt() ?? 8000,
      );
}

class WzButtonDef {
  final String id;
  final String label;
  final WzRect rect;
  final String normal;
  final String? hover;
  final String? pressed;
  WzButtonDef({
    required this.id,
    required this.label,
    required this.rect,
    required this.normal,
    this.hover,
    this.pressed,
  });
  factory WzButtonDef.fromJson(Map<String, dynamic> j) => WzButtonDef(
        id: j['id'] as String? ?? '',
        label: j['label'] as String? ?? '',
        rect: WzRect.fromJson(j['rect'] as Map<String, dynamic>),
        normal: j['normal'] as String? ?? '',
        hover: j['hover'] as String?,
        pressed: j['pressed'] as String?,
      );
}

/// 800×600 原版比例场景容器（自动 letterbox 缩放）
class WzSceneScreen extends StatefulWidget {
  final WzSceneManifest manifest;
  final Widget? overlay;
  final void Function(String buttonId)? onButton;
  final int? selectedSlot;
  final List<Widget>? slotOverlays;
  final bool playBgm;

  const WzSceneScreen({
    super.key,
    required this.manifest,
    this.overlay,
    this.onButton,
    this.selectedSlot,
    this.slotOverlays,
    this.playBgm = true,
  });

  @override
  State<WzSceneScreen> createState() => _WzSceneScreenState();
}

class _WzSceneScreenState extends State<WzSceneScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _logoCtrl;
  String? _hoverButton;
  String? _pressedButton;

  @override
  void initState() {
    super.initState();
    final logo = widget.manifest.logo;
    if (logo != null && logo.frames.length >= 2) {
      _logoCtrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: logo.fadeMs),
      )..repeat(reverse: true);
    }
    if (widget.playBgm) {
      AudioManager().playBgmAsset(widget.manifest.bgm);
    }
  }

  @override
  void dispose() {
    _logoCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = _fitScale(constraints, widget.manifest.width, widget.manifest.height);
        final w = widget.manifest.width * scale;
        final h = widget.manifest.height * scale;
        return Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: SizedBox(
            width: w,
            height: h,
            child: FittedBox(
              fit: BoxFit.fill,
              child: SizedBox(
                width: widget.manifest.width.toDouble(),
                height: widget.manifest.height.toDouble(),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      widget.manifest.background,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0E1A4A)),
                    ),
                    if (widget.manifest.logo != null) _buildLogo(widget.manifest.logo!),
                    ..._buildSlots(),
                    ..._buildButtons(),
                    if (widget.overlay != null) widget.overlay!,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _fitScale(BoxConstraints c, int refW, int refH) {
    final sx = c.maxWidth / refW;
    final sy = c.maxHeight / refH;
    return sx < sy ? sx : sy;
  }

  Widget _buildLogo(WzSpriteRef logo) {
    final frames = logo.frames.isNotEmpty ? logo.frames : [logo.path];
    if (_logoCtrl == null || frames.length < 2) {
      return Positioned(
        left: logo.x,
        top: logo.y,
        width: logo.w,
        height: logo.h,
        child: Image.asset(frames.first, filterQuality: FilterQuality.none),
      );
    }
    return Positioned(
      left: logo.x,
      top: logo.y,
      width: logo.w,
      height: logo.h,
      child: AnimatedBuilder(
        animation: _logoCtrl!,
        builder: (_, __) {
          final t = _logoCtrl!.value;
          return Stack(
            fit: StackFit.expand,
            children: [
              Opacity(opacity: 1 - t, child: Image.asset(frames[0], filterQuality: FilterQuality.none)),
              Opacity(opacity: t, child: Image.asset(frames[1], filterQuality: FilterQuality.none)),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildSlots() {
    final overlays = widget.slotOverlays;
    final list = <Widget>[];
    for (var i = 0; i < widget.manifest.slots.length; i++) {
      final slot = widget.manifest.slots[i];
      final selected = widget.selectedSlot == i;
      list.add(Positioned.fromRect(
        rect: slot.toRect(),
        child: Container(
          decoration: selected
              ? BoxDecoration(
                  border: Border.all(color: const Color(0xFFFFD700), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                      blurRadius: 12,
                    ),
                  ],
                )
              : null,
          child: overlays != null && i < overlays.length ? overlays[i] : null,
        ),
      ));
    }
    return list;
  }

  List<Widget> _buildButtons() {
    return widget.manifest.buttons.map((btn) {
      final asset = _pressedButton == btn.id
          ? (btn.pressed ?? btn.hover ?? btn.normal)
          : _hoverButton == btn.id
              ? (btn.hover ?? btn.normal)
              : btn.normal;
      return Positioned.fromRect(
        rect: btn.rect.toRect(),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hoverButton = btn.id),
          onExit: (_) => setState(() {
            if (_hoverButton == btn.id) _hoverButton = null;
          }),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressedButton = btn.id),
            onTapUp: (_) {
              setState(() => _pressedButton = null);
              AudioManager().playSfx(SfxAssets.click);
              widget.onButton?.call(btn.id);
            },
            onTapCancel: () => setState(() => _pressedButton = null),
            child: Image.asset(
              asset,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
              errorBuilder: (_, __, ___) => Center(
                child: Text(btn.label, style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

/// 079 登录面板木框（Login.img Title/Gender/Backgrnd 263×179）
class WzLoginPanel extends StatelessWidget {
  final WzRect? panel;
  final Widget child;

  const WzLoginPanel({super.key, this.panel, required this.child});

  @override
  Widget build(BuildContext context) {
    final r = panel ?? const WzRect(x: 268, y: 320, w: 263, h: 179);
    return Positioned.fromRect(
      rect: r.toRect(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6B4E36), Color(0xFF4A3220)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFFD4A373), width: 2),
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: child,
      ),
    );
  }
}
