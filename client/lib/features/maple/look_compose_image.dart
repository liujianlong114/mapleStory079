import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../models/char_look.dart';

/// Phase 1：从后端 wzpy CharacterRenderer 实时合成完整 CharLook PNG
class LookComposeImage extends StatelessWidget {
  final CharLook look;
  final double? width;
  final double? height;
  final BoxFit fit;

  const LookComposeImage({
    super.key,
    required this.look,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  Uri get _uri {
    final base = Uri.parse('${AppConfig.apiBaseUrl}/look/compose.png');
    final params = look.toQueryParams();
    params['scale'] = '3';
    params['pad'] = '12';
    return base.replace(queryParameters: params);
  }

  @override
  Widget build(BuildContext context) {
    return Image.network(
      _uri.toString(),
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.none,
      gaplessPlayback: true,
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: width,
          height: height,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD700)),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => SizedBox(
        width: width,
        height: height,
        child: const Icon(Icons.person_outline, color: Color(0x66FFFFFF), size: 36),
      ),
    );
  }
}
