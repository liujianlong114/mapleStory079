import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../models/char_look.dart';
import '../../core/resources/avatar_assets.dart';
import '../../game/engine/local_character_composer.dart';
import 'wz_asset_image.dart';

/// Phase 1+2：后端 wzpy CharacterRenderer 实时合成 → 离线本地锚点合成 → 预烘焙立绘 → 占位符
class LookComposeImage extends StatefulWidget {
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

  @override
  State<LookComposeImage> createState() => _LookComposeImageState();
}

class _LookComposeImageState extends State<LookComposeImage> {
  static const _loadingSize = 20.0;

  // 0=loading, 1=backend, 2=localComposer, 3=prebaked, 4=placeholder
  int _fallbackLevel = 0;
  Sprite? _localSprite;
  bool _backendFailed = false;

  Uri get _backendUri {
    final base = Uri.parse('${AppConfig.apiBaseUrl}/look/compose.png');
    final params = widget.look.toQueryParams();
    params['scale'] = '3';
    params['pad'] = '12';
    return base.replace(queryParameters: params);
  }

  @override
  void initState() {
    super.initState();
    _tryLocalComposer();
  }

  @override
  void didUpdateWidget(LookComposeImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.look != widget.look) {
      _backendFailed = false;
      _fallbackLevel = 0;
      _localSprite = null;
      _tryLocalComposer();
    }
  }

  Future<void> _tryLocalComposer() async {
    final look = widget.look;
    final sprite = await LocalCharacterComposer.composeStand(
      gender: look.gender,
      face: look.face,
      hair: look.hair,
      top: look.top,
      bottom: look.bottom,
      shoes: look.shoes,
      weapon: look.weapon,
      cap: look.cap,
      cape: look.cape,
      glove: look.glove,
      shield: look.shield,
      faceAcc: look.faceAcc,
      eyeAcc: look.eyeAcc,
      earring: look.earring,
      longcoat: look.longcoat,
    );
    if (mounted && sprite != null) {
      setState(() {
        _localSprite = sprite;
        _fallbackLevel = 2;
      });
    }
  }

  void _onBackendError() {
    if (!mounted) return;
    if (!_backendFailed) {
      setState(() {
        _backendFailed = true;
        // localComposer will set _fallbackLevel=2 when it finishes
        // if _localSprite is still null, will try prebaked
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Level 1: backend image (try first if not yet failed)
    if (!_backendFailed || _fallbackLevel < 2) {
      // Show backend if not yet confirmed failed, or still trying
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Image.network(
          _backendUri.toString(),
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          filterQuality: FilterQuality.none,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (frame != null) {
              // Backend loaded
              return child;
            }
            // No frame yet: show loading
            return _loadingWidget();
          },
          loadingBuilder: (context, child, progress) {
            if (progress == null) {
              // Image loaded (child is the loaded image)
              return child;
            }
            return _loadingWidget();
          },
          errorBuilder: (context, error, stackTrace) {
            _onBackendError();
            return _fallbackWidget();
          },
        ),
      );
    }

    return _fallbackWidget();
  }

  Widget _loadingWidget() {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: const Center(
        child: SizedBox(
          width: _loadingSize,
          height: _loadingSize,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD700)),
        ),
      ),
    );
  }

  Widget _fallbackWidget() {
    // Level 2: local composer (sprite from LocalCharacterComposer)
    if (_fallbackLevel >= 2 && _localSprite != null) {
      return _SpriteWidget(sprite: _localSprite!, width: widget.width, height: widget.height, fit: widget.fit);
    }

    // Level 3: pre-baked avatar
    if (_fallbackLevel >= 3) {
      final paths = AvatarAssets.candidatePaths(
        gender: widget.look.gender,
        face: widget.look.face,
        hair: widget.look.hair,
        top: widget.look.top,
        bottom: widget.look.bottom,
        shoes: widget.look.shoes,
        weapon: widget.look.weapon,
      );
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: WzAssetImage(
          candidates: paths,
          fit: widget.fit,
          fallback: (_) => _placeholderWidget(),
        ),
      );
    }

    // Still trying local composer: show loading then fallback to prebaked after timeout
    // Level 0 or 1: try local composer (it might still be running)
    if (_fallbackLevel < 2 && _localSprite == null) {
      // Local composer is still running or hasn't completed
      // Show prebaked as intermediate fallback
      final paths = AvatarAssets.candidatePaths(
        gender: widget.look.gender,
        face: widget.look.face,
        hair: widget.look.hair,
        top: widget.look.top,
        bottom: widget.look.bottom,
        shoes: widget.look.shoes,
        weapon: widget.look.weapon,
      );
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: WzAssetImage(
          candidates: paths,
          fit: widget.fit,
          fallback: (_) => _loadingWidget(),
        ),
      );
    }

    return _placeholderWidget();
  }

  Widget _placeholderWidget() {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: const Icon(Icons.person_outline, color: Color(0x66FFFFFF), size: 36),
    );
  }
}

/// 将 Flame Sprite 渲染为 Flutter Widget
class _SpriteWidget extends StatelessWidget {
  final Sprite sprite;
  final double? width;
  final double? height;
  final BoxFit fit;

  const _SpriteWidget({
    required this.sprite,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return RawImage(
      image: sprite.image,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.none,
    );
  }
}
