import 'package:flutter/material.dart';

/// 079 WZ 九宫格边框（UIWindow.img/MiniMap 等）。
class NinePatchBox extends StatelessWidget {
  const NinePatchBox({
    super.key,
    required this.assetPrefix,
    required this.width,
    required this.height,
    this.child,
    this.left = 6,
    this.right = 6,
    this.top = 29,
    this.bottom = 14,
  });

  final String assetPrefix;
  final double width;
  final double height;
  final Widget? child;
  final double left;
  final double right;
  final double top;
  final double bottom;

  String _p(String corner) => '$assetPrefix$corner.png';

  Widget _slice(String path, double w, double h) {
    return SizedBox(
      width: w,
      height: h,
      child: Image.asset(path, fit: BoxFit.fill, filterQuality: FilterQuality.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    final midW = (width - left - right).clamp(0.0, width);
    final midH = (height - top - bottom).clamp(0.0, height);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Column(
            children: [
              Row(
                children: [
                  _slice(_p('nw'), left, top),
                  _slice(_p('n'), midW, top),
                  _slice(_p('ne'), right, top),
                ],
              ),
              Row(
                children: [
                  _slice(_p('w'), left, midH),
                  _slice(_p('c'), midW, midH),
                  _slice(_p('e'), right, midH),
                ],
              ),
              Row(
                children: [
                  _slice(_p('sw'), left, bottom),
                  _slice(_p('s'), midW, bottom),
                  _slice(_p('se'), right, bottom),
                ],
              ),
            ],
          ),
          if (child != null)
            Positioned(
              left: left,
              top: top,
              right: right,
              bottom: bottom,
              child: child!,
            ),
        ],
      ),
    );
  }
}

/// 横向 WZ 量表（HP/MP/EXP）：彩色条按百分比裁剪。
class WzGaugeBar extends StatelessWidget {
  const WzGaugeBar({
    super.key,
    required this.fillAsset,
    required this.ratio,
    this.width = 139,
    this.height = 18,
    this.bgAsset,
  });

  final String fillAsset;
  final String? bgAsset;
  final double ratio;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final pct = ratio.clamp(0.0, 1.0);
    final fillW = (width * pct).clamp(0.0, width);
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (bgAsset != null)
            Image.asset(bgAsset!, fit: BoxFit.fill, filterQuality: FilterQuality.none),
          if (fillW > 0)
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: pct,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Image.asset(
                    fillAsset,
                    width: width,
                    height: height,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                    repeat: ImageRepeat.repeatX,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
