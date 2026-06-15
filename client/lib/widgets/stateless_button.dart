import 'package:flutter/material.dart';

/// 冒险岛风格通用按钮
///
/// 采用 9-slice 风格视觉：纯色填充 + 深色边框 + 内阴影
/// 支持 title/icon、hover/按下态，以及禁用状态。
class StatelessButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? iconWidget;
  final bool disabled;
  final Color? color;
  final Color? textColor;
  final Color? borderColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final double elevation;
  final TextStyle? textStyle;

  const StatelessButton({
    super.key,
    required this.title,
    this.onPressed,
    this.icon,
    this.iconWidget,
    this.disabled = false,
    this.color,
    this.textColor,
    this.borderColor,
    this.borderRadius,
    this.padding,
    this.width,
    this.height,
    this.elevation = 2,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDisabled = disabled || onPressed == null;
    final bg = color ?? theme.primaryColor;
    final fg = textColor ??
        (theme.brightness == Brightness.dark ? Colors.white : Colors.white);
    final border = borderColor ?? Colors.black.withValues(alpha: 0.35);

    return Container(
      width: width,
      height: height,
      constraints: const BoxConstraints(minHeight: 40, minWidth: 80),
      child: Material(
        color: isDisabled ? bg.withValues(alpha: 0.45) : bg,
        borderRadius: BorderRadius.circular(borderRadius ?? 8),
        elevation: isDisabled ? 0 : elevation,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
          overlayColor: WidgetStateProperty.all(fg.withValues(alpha: 0.18)),
          child: Container(
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius ?? 8),
              border: Border.all(color: border, width: 1.5),
              // 顶部高光 + 底部阴影，形成 9-slice 立体感
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: isDisabled ? 0.05 : 0.18),
                  Colors.transparent,
                  Colors.black.withValues(alpha: isDisabled ? 0.05 : 0.22),
                ],
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null)
                  Icon(icon, color: fg, size: 18)
                else if (iconWidget != null)
                  iconWidget!,
                if (icon != null || iconWidget != null) const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: textStyle ??
                        TextStyle(
                          color: isDisabled ? fg.withValues(alpha: 0.6) : fg,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 次要按钮 - 用于辅助操作
class StatelessButtonSecondary extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool disabled;
  final EdgeInsetsGeometry? padding;

  const StatelessButtonSecondary({
    super.key,
    required this.title,
    this.onPressed,
    this.icon,
    this.disabled = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return StatelessButton(
      title: title,
      onPressed: onPressed,
      icon: icon,
      disabled: disabled,
      padding: padding,
      color: isDark ? const Color(0xFF2a2a4a) : const Color(0xFFe8e2cf),
      textColor: isDark ? const Color(0xFFeaeaea) : const Color(0xFF2c2c2c),
      borderColor: isDark ? Colors.white.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.25),
      elevation: 1,
    );
  }
}

/// 危险/警告按钮
class StatelessButtonDanger extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool disabled;

  const StatelessButtonDanger({
    super.key,
    required this.title,
    this.onPressed,
    this.icon,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return StatelessButton(
      title: title,
      onPressed: onPressed,
      icon: icon,
      disabled: disabled,
      color: const Color(0xFFe94560),
      textColor: Colors.white,
      borderColor: Colors.black.withValues(alpha: 0.35),
      elevation: 3,
    );
  }
}

/// 成功/肯定按钮
class StatelessButtonSuccess extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool disabled;

  const StatelessButtonSuccess({
    super.key,
    required this.title,
    this.onPressed,
    this.icon,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return StatelessButton(
      title: title,
      onPressed: onPressed,
      icon: icon,
      disabled: disabled,
      color: const Color(0xFF27ae60),
      textColor: Colors.white,
      borderColor: Colors.black.withValues(alpha: 0.35),
      elevation: 3,
    );
  }
}
