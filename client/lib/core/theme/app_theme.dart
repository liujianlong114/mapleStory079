import 'package:flutter/material.dart';

/// 冒险岛风格主题色板
class _AppColors {
  // 暗色主色
  static const Color darkBackground = Color(0xFF1a1a2e);
  static const Color darkSurface = Color(0xFF16213e);
  static const Color darkSurfaceAlt = Color(0xFF0f3460);
  static const Color darkPrimary = Color(0xFFe94560);
  static const Color darkAccent = Color(0xFFf39c12);
  static const Color darkText = Color(0xFFeaeaea);
  static const Color darkTextDim = Color(0xFFa7a9be);

  // 亮色主色
  static const Color lightBackground = Color(0xFFf5f2e9);
  static const Color lightSurface = Color(0xFFffffff);
  static const Color lightSurfaceAlt = Color(0xFFe8e2cf);
  static const Color lightPrimary = Color(0xFF8a2be2);
  static const Color lightAccent = Color(0xFFd2691e);
  static const Color lightText = Color(0xFF2c2c2c);
  static const Color lightTextDim = Color(0xFF555555);
}

/// 冒险岛风格按钮样式 (9-slice 视觉)
class _MapleButtonStyle {
  static ButtonStyle build({
    required Color background,
    required Color foreground,
    Color? borderColor,
    double elevation = 2,
  }) {
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.disabled)) return background.withOpacity(0.5);
        if (states.contains(MaterialState.pressed)) return background.withOpacity(0.85);
        if (states.contains(MaterialState.hovered)) return background.withOpacity(0.95);
        return background;
      }),
      foregroundColor: MaterialStateProperty.all(foreground),
      elevation: MaterialStateProperty.all(elevation),
      padding: MaterialStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: borderColor ?? Colors.black.withOpacity(0.3),
            width: 1.5,
          ),
        ),
      ),
      overlayColor: MaterialStateProperty.all(foreground.withOpacity(0.1)),
      textStyle: MaterialStateProperty.all(
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),
    );
  }
}

class AppTheme {
  AppTheme._();

  // ===================== 暗色调主题 =====================
  static ThemeData get dark {
    const bg = _AppColors.darkBackground;
    const surface = _AppColors.darkSurface;
    const primary = _AppColors.darkPrimary;
    const accent = _AppColors.darkAccent;
    const text = _AppColors.darkText;
    const textDim = _AppColors.darkTextDim;

    return _buildBase(
      brightness: Brightness.dark,
      background: bg,
      surface: surface,
      surfaceAlt: _AppColors.darkSurfaceAlt,
      primary: primary,
      accent: accent,
      text: text,
      textDim: textDim,
    );
  }

  // ===================== 亮色调主题 =====================
  static ThemeData get light {
    const bg = _AppColors.lightBackground;
    const surface = _AppColors.lightSurface;
    const primary = _AppColors.lightPrimary;
    const accent = _AppColors.lightAccent;
    const text = _AppColors.lightText;
    const textDim = _AppColors.lightTextDim;

    return _buildBase(
      brightness: Brightness.light,
      background: bg,
      surface: surface,
      surfaceAlt: _AppColors.lightSurfaceAlt,
      primary: primary,
      accent: accent,
      text: text,
      textDim: textDim,
    );
  }

  static ThemeData _buildBase({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceAlt,
    required Color primary,
    required Color accent,
    required Color text,
    required Color textDim,
  }) {
    final isDark = brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white.withOpacity(0.25) : Colors.black.withOpacity(0.2);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorSchemeSeed: primary,
      scaffoldBackgroundColor: background,
      dialogBackgroundColor: surface,
      canvasColor: surface,
      cardColor: surface,
      dividerColor: borderColor,
      primaryColor: primary,
      hintColor: textDim,
      disabledColor: textDim.withOpacity(0.4),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceAlt,
        foregroundColor: text,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        iconTheme: IconThemeData(color: accent),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(6)),
        ),
      ),

      // 按钮
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _MapleButtonStyle.build(
          background: primary,
          foreground: Colors.white,
          borderColor: borderColor,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _MapleButtonStyle.build(
          background: surfaceAlt,
          foreground: text,
          borderColor: primary,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // 输入框
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: TextStyle(color: textDim, fontSize: 14),
        hintStyle: TextStyle(color: textDim.withOpacity(0.6), fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),

      // 文本主题
      textTheme: TextTheme(
        displayLarge: TextStyle(color: text, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        displayMedium: TextStyle(color: text, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1),
        displaySmall: TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: text, fontSize: 22, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: text, fontSize: 15, height: 1.4),
        bodyMedium: TextStyle(color: text, fontSize: 13, height: 1.4),
        bodySmall: TextStyle(color: textDim, fontSize: 12, height: 1.3),
        labelLarge: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.8),
        labelMedium: TextStyle(color: textDim, fontSize: 12),
      ),

      // 卡片风格（9-slice 效果）
      cardTheme: CardThemeData(
        color: surface,
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),

      // 列表项
      listTileTheme: ListTileThemeData(
        textColor: text,
        iconColor: accent,
        selectedTileColor: primary.withOpacity(0.15),
        selectedColor: primary,
      ),

      // 图标
      iconTheme: IconThemeData(color: accent, size: 22),

      // 分割线
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 16,
      ),

      // 浮动按钮
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceAlt,
        contentTextStyle: TextStyle(color: text, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // TabBar
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textDim,
        indicator: BoxDecoration(
          border: Border(bottom: BorderSide(color: primary, width: 2)),
        ),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: surfaceAlt,
        labelStyle: TextStyle(color: text, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),

      // Progress
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: surfaceAlt,
        circularTrackColor: surfaceAlt,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        titleTextStyle: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold),
        contentTextStyle: TextStyle(color: text, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// 通用的冒险岛风格 9-slice 装饰容器
class MapleBox extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final List<BoxShadow>? shadows;

  const MapleBox({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.borderWidth = 1.5,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.alignment,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.cardColor;
    final border = borderColor ?? theme.dividerColor;

    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: margin,
      alignment: alignment,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: borderWidth),
        borderRadius: BorderRadius.circular(borderRadius ?? 8),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: child,
    );
  }
}
