import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 079 风格星空背景（登录 / 选角共用）
class MapleStarfieldBackground extends StatefulWidget {
  final List<Color> gradientColors;
  final Widget? child;

  const MapleStarfieldBackground({
    super.key,
    this.gradientColors = const [
      Color(0xFF050818),
      Color(0xFF0E1A4A),
      Color(0xFF1B0F3A),
    ],
    this.child,
  });

  @override
  State<MapleStarfieldBackground> createState() =>
      _MapleStarfieldBackgroundState();
}

class _MapleStarfieldBackgroundState extends State<MapleStarfieldBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _StarPainter(_ctrl.value)),
              if (widget.child != null) widget.child!,
            ],
          ),
        );
      },
    );
  }
}

class _StarPainter extends CustomPainter {
  final double t;
  _StarPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    final paint = Paint();
    for (var i = 0; i < 120; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final blink = 0.3 + 0.7 * ((math.sin(t * math.pi * 2 + i) + 1) / 2);
      paint.color = Colors.white.withValues(alpha: 0.15 + blink * 0.55);
      canvas.drawCircle(Offset(x, y), 0.6 + rnd.nextDouble() * 1.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) =>
      oldDelegate.t != t;
}

/// 079 风格木框面板
class MapleWoodPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? width;

  const MapleWoodPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C3A21), Color(0xFF3B2414)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD4A373), width: 3),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// 079 风格按钮
class MapleActionButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color faceColor;
  final Color borderColor;
  final double width;
  final double height;

  const MapleActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.faceColor = const Color(0xFFF4A460),
    this.borderColor = const Color(0xFF3B2414),
    this.width = 140,
    this.height = 42,
  });

  @override
  State<MapleActionButton> createState() => _MapleActionButtonState();
}

class _MapleActionButtonState extends State<MapleActionButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final lift = disabled ? 0.0 : (_pressed ? 1.0 : (_hover ? -2.0 : 0.0));
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = _pressed = false),
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled
            ? null
            : (_) {
                setState(() => _pressed = false);
                widget.onPressed?.call();
              },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          transform: Matrix4.translationValues(0, lift, 0),
          width: widget.width,
          height: widget.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: disabled
                  ? [const Color(0xFF888888), const Color(0xFF666666)]
                  : [
                      Color.lerp(widget.faceColor, Colors.white, 0.15)!,
                      widget.faceColor,
                    ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(color: widget.borderColor, width: 2),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: disabled ? 0.2 : 0.45),
                blurRadius: 6,
                offset: Offset(0, 3 - lift),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.2,
              shadows: [Shadow(color: Colors.black45, offset: Offset(1, 1))],
            ),
          ),
        ),
      ),
    );
  }
}

/// 079 Logo 标题（带呼吸动画）
class MapleTitleLogo extends StatelessWidget {
  final Animation<double> pulse;

  const MapleTitleLogo({super.key, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        final scale = 1.0 + pulse.value * 0.04;
        return Transform.scale(
          scale: scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFFFFE082),
                    Color(0xFFFFB13A),
                    Color(0xFFFF6F00),
                  ],
                ).createShader(bounds),
                child: const Text(
                  'MapleStory',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: Color(0xFF8B0000),
                        blurRadius: 2,
                        offset: Offset(3, 3),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '079 复刻版',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 简易角色预览（079 新手外观，按 itemId 着色）
class MapleCharacterPreview extends StatelessWidget {
  final int gender;
  final int faceId;
  final int hairId;
  final int skinTone;
  final int topId;
  final int bottomId;
  final int shoesId;
  final int weaponId;
  final double scale;

  const MapleCharacterPreview({
    super.key,
    required this.gender,
    this.faceId = 20100,
    this.hairId = 30000,
    this.skinTone = 0,
    this.topId = 1040002,
    this.bottomId = 1060002,
    this.shoesId = 1072001,
    this.weaponId = 1302000,
    this.scale = 1.0,
  });

  static const _skins = [
    Color(0xFFFFDBAC),
    Color(0xFFE0AC69),
    Color(0xFF8D5524),
    Color(0xFF5C3317),
  ];

  static Color _hairColor(int hairId) {
    final base = hairId % 10;
    const palette = [
      Color(0xFF3E2723),
      Color(0xFFFFEB3B),
      Color(0xFFE53935),
      Color(0xFF1E88E5),
      Color(0xFF43A047),
      Color(0xFF8E24AA),
    ];
    return palette[base % palette.length];
  }

  static Color _topColor(int topId, int gender) {
    if (topId == 1040006 || topId == 1041006) return const Color(0xFF1565C0);
    if (topId == 1040010 || topId == 1041010) return const Color(0xFF2E7D32);
    if (topId == 1041011) return const Color(0xFFC2185B);
    return gender == 0 ? const Color(0xFF37474F) : const Color(0xFFAD1457);
  }

  static Color _bottomColor(int bottomId) {
    if (bottomId == 1060006 || bottomId == 1061008) {
      return const Color(0xFF263238);
    }
    return const Color(0xFF455A64);
  }

  static Color _shoeColor(int shoesId) {
    if (shoesId == 1072005 || shoesId == 1072038) {
      return const Color(0xFF5D4037);
    }
    return const Color(0xFF3E2723);
  }

  @override
  Widget build(BuildContext context) {
    final skin = _skins[skinTone.clamp(0, _skins.length - 1)];
    final hair = _hairColor(hairId);
    final top = _topColor(topId, gender);
    final bottom = _bottomColor(bottomId);
    final shoes = _shoeColor(shoesId);
    final showWeapon = weaponId != 0;
    final w = 90.0 * scale;
    final h = 120.0 * scale;

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 武器
          if (showWeapon)
            Positioned(
              right: w * 0.05,
              bottom: h * 0.35,
              child: Transform.rotate(
                angle: -0.4,
                child: Container(
                  width: 8 * scale,
                  height: 36 * scale,
                  decoration: BoxDecoration(
                    color: weaponId == 1322005
                        ? const Color(0xFF78909C)
                        : const Color(0xFF8D6E63),
                    border: Border.all(color: const Color(0xFF3B2414), width: 1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          // 鞋子
          Positioned(
            bottom: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _boot(shoes, scale),
                SizedBox(width: 4 * scale),
                _boot(shoes, scale),
              ],
            ),
          ),
          // 裤子
          Positioned(
            bottom: 10 * scale,
            child: Container(
              width: 40 * scale,
              height: 22 * scale,
              decoration: BoxDecoration(
                color: bottom,
                border: Border.all(color: const Color(0xFF3B2414), width: 2),
              ),
            ),
          ),
          // 上衣
          Positioned(
            bottom: 28 * scale,
            child: Container(
              width: 44 * scale,
              height: 26 * scale,
              decoration: BoxDecoration(
                color: top,
                border: Border.all(color: const Color(0xFF3B2414), width: 2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 头
          Positioned(
            bottom: 46 * scale,
            child: Container(
              width: 38 * scale,
              height: 38 * scale,
              decoration: BoxDecoration(
                color: skin,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF3B2414), width: 2),
              ),
            ),
          ),
          // 头发
          Positioned(
            bottom: 68 * scale,
            child: Container(
              width: 46 * scale,
              height: 22 * scale,
              decoration: BoxDecoration(
                color: hair,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20 * scale),
                ),
                border: Border.all(color: const Color(0xFF3B2414), width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _boot(Color c, double scale) => Container(
        width: 14 * scale,
        height: 10 * scale,
        decoration: BoxDecoration(
          color: c,
          border: Border.all(color: const Color(0xFF3B2414), width: 1),
          borderRadius: BorderRadius.circular(2),
        ),
      );
}
