import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/resources/assets.dart';

/// 尝试多个 asset 路径；小于阈值的占位 PNG 视为无效并尝试下一候选。
/// 使用 rootBundle + Image.memory，避免 Web 上 Image.asset 对缺失资源的 404 刷屏。
class WzAssetImage extends StatefulWidget {
  final List<String> candidates;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext)? fallback;
  /// 资源加载成功且非占位时回调（用于隐藏叠加文字）
  final void Function(bool isRealAsset)? onAssetResolved;

  const WzAssetImage({
    super.key,
    required this.candidates,
    this.width,
    this.height,
    this.fit = BoxFit.fill,
    this.fallback,
    this.onAssetResolved,
  });

  /// WZ 小图标（台座等）也视为有效；仅过滤 build_login_scene 占位（通常 <600B）
  static const int minRealPngBytes = 512;

  @override
  State<WzAssetImage> createState() => _WzAssetImageState();
}

class _WzAssetImageState extends State<WzAssetImage> {
  Uint8List? _bytes;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WzAssetImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candidates != widget.candidates) {
      _bytes = null;
      _resolved = false;
      _load();
    }
  }

  Future<void> _load() async {
    if (widget.candidates.isEmpty) {
      _notifyResolved(false);
      return;
    }
    for (final path in widget.candidates) {
      try {
        final data = await rootBundle.load(AssetPaths.bundle(path));
        if (data.lengthInBytes >= WzAssetImage.minRealPngBytes) {
          if (!mounted) return;
          setState(() {
            _bytes = data.buffer.asUint8List();
          });
          _notifyResolved(true);
          return;
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _bytes = null;
    });
    _notifyResolved(false);
  }

  void _notifyResolved(bool isReal) {
    if (_resolved) return;
    _resolved = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onAssetResolved?.call(isReal);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes == null) {
      if (_resolved) {
        return widget.fallback?.call(context) ??
            SizedBox(width: widget.width, height: widget.height);
      }
      return SizedBox(width: widget.width, height: widget.height);
    }
    return Image.memory(
      _bytes!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      filterQuality: FilterQuality.none,
      gaplessPlayback: true,
    );
  }
}
