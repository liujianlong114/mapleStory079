import 'package:flutter/material.dart';

/// 尝试多个 asset 路径（procedural: btn_yes.png / WZ 提取: btn_yes_normal.png）
class WzAssetImage extends StatefulWidget {
  final List<String> candidates;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext)? fallback;

  const WzAssetImage({
    super.key,
    required this.candidates,
    this.width,
    this.height,
    this.fit = BoxFit.fill,
    this.fallback,
  });

  @override
  State<WzAssetImage> createState() => _WzAssetImageState();
}

class _WzAssetImageState extends State<WzAssetImage> {
  int _idx = 0;

  @override
  void didUpdateWidget(covariant WzAssetImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candidates != widget.candidates) {
      _idx = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.candidates.isEmpty) {
      return widget.fallback?.call(context) ?? const SizedBox.shrink();
    }
    final path = widget.candidates[_idx.clamp(0, widget.candidates.length - 1)];
    return Image.asset(
      path,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      filterQuality: FilterQuality.none,
      errorBuilder: (ctx, _, __) {
        if (_idx + 1 < widget.candidates.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _idx++);
          });
          return SizedBox(width: widget.width, height: widget.height);
        }
        return widget.fallback?.call(ctx) ??
            SizedBox(width: widget.width, height: widget.height);
      },
    );
  }
}
