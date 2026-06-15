import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/resources/assets.dart';
import '../../core/resources/login_ui_assets.dart';
import 'maplogin_parallax.dart';
import 'wz_asset_image.dart';

/// 079 登录/选角场景（800×600，按 WZ manifest 布局）
class WzSceneManifest {
  final int width;
  final int height;
  final String bgm;
  final bool useParallax;
  final double parallaxCameraX;
  final double parallaxCameraY;
  final String background;
  final String? panelImage;
  final WzSpriteRef? logo;
  final List<WzRect> slots;
  final List<WzButtonDef> buttons;
  final List<WzDecoration> decorations;
  final WzRect? loginPanel;

  WzSceneManifest({
    required this.width,
    required this.height,
    required this.bgm,
    this.useParallax = true,
    this.parallaxCameraX = 0,
    this.parallaxCameraY = 0,
    required this.background,
    this.panelImage,
    this.logo,
    this.slots = const [],
    this.buttons = const [],
    this.decorations = const [],
    this.loginPanel,
  });

  factory WzSceneManifest.fromJson(Map<String, dynamic> json) {
    return WzSceneManifest(
      width: (json['width'] as num?)?.toInt() ?? 800,
      height: (json['height'] as num?)?.toInt() ?? 600,
      bgm: json['bgm'] as String? ?? BgmAssets.title,
      useParallax: json['use_parallax'] as bool? ?? true,
      parallaxCameraX: (json['parallax_camera']?['x'] as num?)?.toDouble() ?? 0,
      parallaxCameraY: (json['parallax_camera']?['y'] as num?)?.toDouble() ?? 0,
      background: json['background'] as String? ?? '',
      panelImage: json['panel_image'] as String?,
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
      decorations: (json['decorations'] as List?)
              ?.map((e) => WzDecoration.fromJson(e as Map<String, dynamic>))
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

class WzDecoration {
  final String path;
  final double x, y, w, h;
  const WzDecoration({
    required this.path,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });
  factory WzDecoration.fromJson(Map<String, dynamic> j) => WzDecoration(
        path: j['path'] as String? ?? '',
        x: (j['x'] as num?)?.toDouble() ?? 0,
        y: (j['y'] as num?)?.toDouble() ?? 0,
        w: (j['w'] as num?)?.toDouble() ?? 0,
        h: (j['h'] as num?)?.toDouble() ?? 0,
      );
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
  final bool useMapLoginParallax;
  final Set<String>? selectedButtonIds;
  final Set<String>? disabledButtonIds;

  const WzSceneScreen({
    super.key,
    required this.manifest,
    this.overlay,
    this.onButton,
    this.selectedSlot,
    this.slotOverlays,
    this.playBgm = true,
    this.useMapLoginParallax = true,
    this.selectedButtonIds,
    this.disabledButtonIds,
  });

  @override
  State<WzSceneScreen> createState() => _WzSceneScreenState();
}

class _WzSceneScreenState extends State<WzSceneScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _logoCtrl;
  String? _hoverButton;
  String? _pressedButton;
  final Set<String> _showLabelButtons = {};

  Future<void> _probeButtonAssets() async {
    for (final btn in widget.manifest.buttons) {
      var real = false;
      for (final path in LoginUiAssets.resolve(btn.normal)) {
        try {
          final data = await rootBundle.load(AssetPaths.bundle(path));
          if (data.lengthInBytes >= WzAssetImage.minRealPngBytes) {
            real = true;
            break;
          }
        } catch (_) {}
      }
      if (!real && mounted) {
        setState(() => _showLabelButtons.add(btn.id));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _probeButtonAssets();
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

  bool get _useParallax =>
      widget.manifest.useParallax && widget.useMapLoginParallax;

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
                    _buildBackground(),
                    ..._buildDecorations(),
                    if (widget.manifest.logo != null) _buildLogo(widget.manifest.logo!),
                    ..._buildSlots(),
                    if (widget.overlay != null) widget.overlay!,
                    ..._buildButtons(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackground() {
    if (_useParallax) {
      return MapLoginParallax(
        width: widget.manifest.width,
        height: widget.manifest.height,
        cameraX: widget.manifest.parallaxCameraX,
        cameraY: widget.manifest.parallaxCameraY,
      );
    }
    if (widget.manifest.background.isNotEmpty) {
      return WzAssetImage(
        candidates: [widget.manifest.background],
        fit: BoxFit.fill,
        fallback: (_) => MapLoginParallax(
          width: widget.manifest.width,
          height: widget.manifest.height,
          cameraX: widget.manifest.parallaxCameraX,
          cameraY: widget.manifest.parallaxCameraY,
        ),
      );
    }
    return MapLoginParallax(
      width: widget.manifest.width,
      height: widget.manifest.height,
      cameraX: widget.manifest.parallaxCameraX,
      cameraY: widget.manifest.parallaxCameraY,
    );
  }

  List<Widget> _buildDecorations() {
    return widget.manifest.decorations.map((d) {
      return Positioned(
        left: d.x,
        top: d.y,
        width: d.w,
        height: d.h,
        child: WzAssetImage(
          candidates: LoginUiAssets.resolve(d.path),
          fit: BoxFit.fill,
        ),
      );
    }).toList();
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
        child: WzAssetImage(
          candidates: LoginUiAssets.resolve(frames.first),
          fit: BoxFit.contain,
        ),
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
              Opacity(
                opacity: 1 - t,
                child: WzAssetImage(
                  candidates: LoginUiAssets.resolve(frames[0]),
                  fit: BoxFit.contain,
                ),
              ),
              Opacity(
                opacity: t,
                child: WzAssetImage(
                  candidates: LoginUiAssets.resolve(frames[1]),
                  fit: BoxFit.contain,
                ),
              ),
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

  List<String> _buttonAssetCandidates(WzButtonDef btn) {
    if (_pressedButton == btn.id) {
      return LoginUiAssets.resolve(btn.pressed ?? btn.hover ?? btn.normal);
    }
    if (_hoverButton == btn.id) {
      return LoginUiAssets.resolve(btn.hover ?? btn.normal);
    }
    return LoginUiAssets.resolve(btn.normal);
  }

  List<Widget> _buildButtons() {
    final disabled = widget.disabledButtonIds ?? const {};
    final selected = widget.selectedButtonIds ?? const {};

    return widget.manifest.buttons.map((btn) {
      final isDisabled = disabled.contains(btn.id);
      final isSelected = selected.contains(btn.id);

      return Positioned.fromRect(
        rect: btn.rect.toRect(),
        child: MouseRegion(
          onEnter: isDisabled ? null : (_) => setState(() => _hoverButton = btn.id),
          onExit: isDisabled
              ? null
              : (_) => setState(() {
                    if (_hoverButton == btn.id) _hoverButton = null;
                  }),
          child: GestureDetector(
            onTapDown: isDisabled ? null : (_) => setState(() => _pressedButton = btn.id),
            onTapUp: isDisabled
                ? null
                : (_) {
                    setState(() => _pressedButton = null);
                    AudioManager().playUiClick();
                    widget.onButton?.call(btn.id);
                  },
            onTapCancel: () => setState(() => _pressedButton = null),
            child: Stack(
              fit: StackFit.expand,
              children: [
                WzAssetImage(
                  candidates: _buttonAssetCandidates(btn),
                  fit: BoxFit.fill,
                  fallback: (_) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B6914),
                      border: Border.all(color: const Color(0xFF3B2414)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onAssetResolved: (real) {
                    if (real && _showLabelButtons.contains(btn.id) && mounted) {
                      setState(() => _showLabelButtons.remove(btn.id));
                    }
                  },
                ),
                if (isSelected)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFFFD700), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                Center(
                  child: _showLabelButtons.contains(btn.id)
                      ? Text(
                          btn.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
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
  final String? panelImage;
  final Widget child;

  const WzLoginPanel({
    super.key,
    this.panel,
    this.panelImage,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final r = panel ?? const WzRect(x: 268, y: 320, w: 263, h: 179);
    return Positioned.fromRect(
      rect: r.toRect(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (panelImage != null && panelImage!.isNotEmpty)
            WzAssetImage(
              candidates: LoginUiAssets.resolve(panelImage!),
              fit: BoxFit.fill,
              fallback: (_) => _gradientPanel(),
            )
          else if (panelImage != null && panelImage!.isEmpty)
            _gradientPanel(),
          child,
        ],
      ),
    );
  }

  Widget _gradientPanel() {
    return DecoratedBox(
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
    );
  }
}
