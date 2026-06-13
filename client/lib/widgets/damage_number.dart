import 'package:flutter/material.dart';

class DamageNumber extends StatefulWidget {
  final int damage;
  final bool isCritical;
  final bool isMiss;
  final Offset startPosition;
  final Duration duration;

  const DamageNumber({
    super.key,
    required this.damage,
    this.isCritical = false,
    this.isMiss = false,
    this.startPosition = Offset.zero,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  State<DamageNumber> createState() => _DamageNumberState();
}

class _DamageNumberState extends State<DamageNumber> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _positionAnimation = Tween<double>(begin: 0, end: -60).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0)),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: widget.isCritical ? 1.8 : 1.2).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3, curve: Curves.elasticOut)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.startPosition.dx,
          top: widget.startPosition.dy + _positionAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Text(
                widget.isMiss ? 'MISS' : '-${widget.damage}',
                style: TextStyle(
                  color: widget.isCritical ? Colors.orangeAccent : (widget.isMiss ? Colors.grey : Colors.red),
                  fontSize: widget.isCritical ? 28 : 20,
                  fontWeight: FontWeight.bold,
                  shadows: const [
                    Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
