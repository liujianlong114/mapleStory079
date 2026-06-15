import 'package:flutter/material.dart';

import '../../core/resources/assets.dart';
import '../../core/resources/login_ui_assets.dart';
import 'wz_asset_image.dart';

/// 079 WZ 精灵按钮（Login.img 各 Bt* 三态）
class WzSpriteButton extends StatefulWidget {
  final String normal;
  final String? hover;
  final String? pressed;
  final double width;
  final double height;
  final VoidCallback? onPressed;
  final String? fallbackLabel;

  const WzSpriteButton({
    super.key,
    required this.normal,
    this.hover,
    this.pressed,
    required this.width,
    required this.height,
    this.onPressed,
    this.fallbackLabel,
  });

  @override
  State<WzSpriteButton> createState() => _WzSpriteButtonState();
}

class _WzSpriteButtonState extends State<WzSpriteButton> {
  bool _hover = false;
  bool _pressed = false;

  String get _asset {
    if (_pressed && widget.pressed != null) return widget.pressed!;
    if (_hover && widget.hover != null) return widget.hover!;
    return widget.normal;
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    return MouseRegion(
      onEnter: disabled ? null : (_) => setState(() => _hover = true),
      onExit: disabled
          ? null
          : (_) => setState(() {
                _hover = false;
                _pressed = false;
              }),
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled
            ? null
            : (_) {
                setState(() => _pressed = false);
                AudioManager().playUiClick();
                widget.onPressed?.call();
              },
        onTapCancel: () => setState(() => _pressed = false),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
          fit: StackFit.expand,
          children: [
            WzAssetImage(
              candidates: LoginUiAssets.resolve(_asset),
              width: widget.width,
              height: widget.height,
              fallback: (_) => _fallbackBox(),
            ),
            if (widget.fallbackLabel != null && widget.fallbackLabel!.isNotEmpty)
              Center(
                child: Text(
                  widget.fallbackLabel!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _fallbackBox() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF8B6914),
        border: Border.all(color: const Color(0xFF3B2414)),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// WZ 面板背景图（优先 PNG，失败时用木框）
class WzPanelFrame extends StatelessWidget {
  final String? assetPath;
  final double width;
  final double height;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const WzPanelFrame({
    super.key,
    this.assetPath,
    required this.width,
    required this.height,
    required this.child,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (assetPath != null)
            WzAssetImage(
              candidates: LoginUiAssets.resolve(assetPath!),
              fit: BoxFit.fill,
              fallback: (_) => _woodBox(),
            )
          else
            _woodBox(),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }

  Widget _woodBox() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C3A21), Color(0xFF3B2414)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD4A373), width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Login.img/NewChar 左右箭头 BtLeft/BtRight 15×16
class WzArrowButton extends StatelessWidget {
  final bool right;
  final VoidCallback? onPressed;

  const WzArrowButton({super.key, this.right = false, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final prefix = right ? 'btn_right' : 'btn_left';
    return WzSpriteButton(
      normal: LoginUiAssets.buttonStates(prefix).first,
      hover: LoginUiAssets.buttonOverStates(prefix).first,
      pressed: LoginUiAssets.buttonPressedStates(prefix).first,
      width: 15,
      height: 16,
      onPressed: onPressed,
      fallbackLabel: right ? '▶' : '◀',
    );
  }
}

/// Login.img/NewChar/scroll 卷轴条 200×17
class WzAvatarTab extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const WzAvatarTab({
    super.key,
    required this.label,
    this.selected = false,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final asset = enabled
        ? (selected ? LoginUiAssets.tabSel : LoginUiAssets.tabNormal)
        : LoginUiAssets.tabDisabled;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 160,
        height: 17,
        child: Stack(
          alignment: Alignment.center,
          children: [
            WzAssetImage(
              candidates: [asset],
              width: 160,
              height: 17,
              fallback: (_) => Container(
                color: selected ? const Color(0xFF8B6914) : const Color(0xFFBCAAA4),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF3B2414),
                fontSize: 10,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
