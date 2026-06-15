import 'dart:async';

import 'package:flutter/material.dart';

/// 单一拾取通知条目（动画向上渐隐）
class _PickupToast {
  _PickupToast({
    required this.text,
    required this.controller,
    this.color = Colors.white,
  });

  final String text;
  final AnimationController controller;
  final Color color;
  late final Animation<double> _fade = Tween<double>(begin: 1.0, end: 0.0)
      .animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0, -1.0),
  ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

  Animation<double> get fade => _fade;
  Animation<Offset> get slide => _slide;
}

/// 拾取得知弹幕（类似官方 MapleStory `MapleSystemMessage`）
///
/// 用法：
///   final key = GlobalKey<MaplePickupNoticeState>();
///   ...
///   MaplePickupNotice(key: key, itemName: '蓝药水')
///   ...
///   key.currentState?.notify('获得 蓝药水×2')
class MaplePickupNotice extends StatefulWidget {
  const MaplePickupNotice({
    super.key,
    this.maxLines = 4,
    this.duration = const Duration(seconds: 2, milliseconds: 400),
  });

  final int maxLines;
  final Duration duration;

  @override
  State<MaplePickupNotice> createState() => MaplePickupNoticeState();
}

class MaplePickupNoticeState extends State<MaplePickupNotice>
    with TickerProviderStateMixin {
  final List<_PickupToast> _toasts = [];

  /// 显示一条拾取信息。信息从下向上移动并渐隐。
  void notify(String text, {Color color = Colors.white}) {
    final controller = AnimationController(vsync: this, duration: widget.duration);
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _toasts.removeWhere((t) => t.controller == controller);
        });
        controller.dispose();
      }
    });
    controller.forward();
    setState(() {
      _toasts.add(_PickupToast(text: text, controller: controller, color: color));
      if (_toasts.length > widget.maxLines) {
        final removed = _toasts.removeAt(0);
        unawaited(Future(() {
          try {
            removed.controller.dispose();
          } catch (_) {}
        }));
      }
    });
  }

  /// 便捷：显示一条物品获得提示（带 item 图标位置——目前仅文字）
  void notifyItem({required int itemId, required int quantity, String? name}) {
    final displayName = name ?? '道具 $itemId';
    notify('获得 $displayName${quantity > 1 ? ' ×$quantity' : ''}');
  }

  /// 便捷：显示金币获得提示
  void notifyMesos(int amount) {
    notify('获得 $amount 金币', color: const Color(0xFFF1C40F));
  }

  @override
  void dispose() {
    for (final t in _toasts) {
      try {
        t.controller.dispose();
      } catch (_) {}
    }
    _toasts.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < _toasts.length; i++)
            _buildToast(_toasts[i]),
        ],
      ),
    );
  }

  Widget _buildToast(_PickupToast toast) {
    return AnimatedBuilder(
      animation: toast.controller,
      builder: (context, child) {
        return Opacity(
          opacity: toast.fade.value,
          child: Transform.translate(
            offset: toast.slide.value * 24,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Text(
          toast.text,
          style: TextStyle(
            fontSize: 14,
            color: toast.color,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            shadows: const [
              Shadow(color: Color(0xAA000000), offset: Offset(1, 1), blurRadius: 1),
            ],
          ),
        ),
      ),
    );
  }
}
