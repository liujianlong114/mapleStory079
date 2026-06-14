import 'package:flutter/material.dart';

/// 079 StatusBar.img/number 位图数字行。
class WzBitmapText extends StatelessWidget {
  const WzBitmapText({
    super.key,
    required this.text,
    this.prefix = 'assets/images/ui/hud/num_',
    this.height = 12,
    this.alignment = Alignment.centerLeft,
  });

  final String text;
  final String prefix;
  final double height;
  final Alignment alignment;

  String? _assetFor(String ch) {
    if (ch == '%') return '${prefix}percent.png';
    if (ch == '/') return '${prefix}slash.png';
    if (ch.codeUnitAt(0) >= 0x30 && ch.codeUnitAt(0) <= 0x39) {
      return '$prefix$ch.png';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final glyphs = <Widget>[];
    for (final ch in text.split('')) {
      final asset = _assetFor(ch);
      if (asset == null) continue;
      glyphs.add(
        Image.asset(
          asset,
          height: height,
          filterQuality: FilterQuality.none,
          fit: BoxFit.contain,
        ),
      );
    }
    return Align(
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: glyphs,
      ),
    );
  }
}
